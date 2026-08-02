_DEBUG = false
_CONSOLE = _CONSOLE or false

_IS_LOVEJS = jit == nil

package.path = package.path .. ";./thirdparty/?.lua;./?/init.lua"

local dir_sep = package.config:sub(1,1)
local is_windows = dir_sep == "\\"

if is_windows then
   package.path = package.path .. ";..\\lib\\luasocket\\?.lua;..\\lib\\lua-vips\\?.lua"
   package.cpath = package.cpath .. ";..\\lib\\luautf8\\?.dll;..\\lib\\luasocket\\?.dll;..\\lib\\luafilesystem\\?.dll;..\\lib\\lua-zlib\\?.dll"
else
   package.cpath = package.cpath .. ";../lib/?.so"
end

if love == nil then
   _CONSOLE = true

   love = require("util.lovemock")
end

-- On Android, love-android mounts the packaged game (game.love) as a
-- packed archive via PhysFS rather than extracting it to a real folder
-- on disk. That's fine for LÖVE's own PhysFS-aware APIs
-- (love.filesystem.load/read/write/getInfo), but this codebase's own
-- module system (internal.env's hooked `require`, installed further
-- down, which almost everything past boot.lua goes through) resolves
-- paths with vanilla `loadfile`/`io.open`, which only understands real
-- OS files. That can never read into a packed archive on any platform,
-- so on Android nothing past the first few requires below could load.
--
-- Fix: extract the whole mounted source tree to a real, writable
-- directory (love.filesystem.getSaveDirectory(), which LÖVE guarantees
-- is a real OS folder on every platform, used elsewhere in this
-- codebase for the same reason - see util/fs.lua) on first launch, then
-- point package.path/package.cpath at that real directory instead of
-- the relative "./" patterns. Everything downstream - the hooked
-- require, mod loading, the deps/elona asset copy in game/startup.lua -
-- then works exactly as it does on desktop, because it's reading real
-- files instead of a mounted archive.
if love.system.getOS() == "Android" then
   local EXTRACTED_MARKER = ".extracted_to_save_dir"

   if not love.filesystem.getInfo(EXTRACTED_MARKER) then
      local function extract_dir(dir)
         for _, name in ipairs(love.filesystem.getDirectoryItems(dir)) do
            local path = dir == "" and name or (dir .. "/" .. name)
            local info = love.filesystem.getInfo(path)
            if info ~= nil and info.type == "directory" then
               love.filesystem.createDirectory(path)
               extract_dir(path)
            elseif info ~= nil and info.type == "file" then
               local data = love.filesystem.read(path)
               if data ~= nil then
                  love.filesystem.write(path, data)
               end
            end
         end
      end

      extract_dir("")
      love.filesystem.write(EXTRACTED_MARKER, "1")
   end

   -- Only package.path is rewritten here, not package.cpath: its one
   -- non-Windows entry is "../lib/?.so" (no "./" prefix, so a "./"-based
   -- gsub would mangle it), and native libraries aren't loaded through
   -- it on Android regardless - see internal/env.lua's NATIVE_REQUIRES/
   -- LOVE2D_REQUIRES handling.
   local save_dir = love.filesystem.getSaveDirectory() .. "/"
   package.path = package.path:gsub('%./', save_dir)

   -- package.path above only fixes require() (Lua's own module loaders).
   -- Plenty of code elsewhere reads assets via raw io.open() on paths
   -- like "graphic/map1.bmp" (see internal/binary_reader.lua, used by
   -- internal/bmp_convert.lua for BMP loading) with no directory prefix
   -- at all, relying on the OS process's actual current working
   -- directory already being the game's source root - true on desktop
   -- because it's launched from inside that directory, but not
   -- something love-android sets up for us. Lua has no built-in chdir,
   -- so reach for libc's directly via LuaJIT FFI (bionic on
   -- Android/Linux always provides it).
   local ffi = require("ffi")
   ffi.cdef("int chdir(const char *path);")
   ffi.C.chdir(save_dir)
end

-- We have to update LÖVE's require path which is completely separate
-- from package.path in order to make love.filesystem.load work
-- properly.
--
-- LÖVE's own loader resolves this path against its virtual filesystem
-- via PhysFS, which (unlike a real OS directory) does not treat a
-- leading "./" as a no-op: love.filesystem.getInfo("./ext/init.lua")
-- returns nil even though getInfo("ext/init.lua") finds the file. Every
-- entry we add to package.path above is "./"-prefixed, which is
-- harmless for the OS-based vanilla Lua loader but silently breaks
-- LÖVE's loader, so strip it per-entry before handing the path over.
local love_require_path = {}
for entry in package.path:gmatch("[^;]+") do
   love_require_path[#love_require_path+1] = entry:gsub("^%./", "")
end
love.filesystem.setRequirePath(table.concat(love_require_path, ";"))

-- globals that will be used very often.

if _DEBUG then
   _CONSOLE = true
end

require("ext")

class = require("util.class")
types = require("util.types")

inspect = require("thirdparty.inspect")
fun = require("thirdparty.fun")

if is_windows then
   -- Do not buffer stdout for Emacs compatibility.
   -- Requires LOVE's source to be modified to use stdin/stdout pipes
   -- on Windows.
   io.stdout:setvbuf("no")
   io.stderr:setvbuf("no")
end

-- prevent new globals from here on out.
require("thirdparty.strict")

if _IS_LOVEJS then
   -- hack to satisfy strict.lua
   jit = nil

   require("api.Log").set_level("debug")
end

-- Hook the global `require` to support hotloading.
require("internal.env").hook_global_require()
