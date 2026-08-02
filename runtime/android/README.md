# Android build path (prototype)

**Status: boots all the way to the title screen, confirmed on a real
emulator** (API 34, x86_64) — a clean install now gets past `require`, mod
loading, game-data validation, and config init, and lands on a stable,
rendering "Starting Menu" screen that just sits there waiting for input
(see next paragraph for the caveat on that last part). This is further
than this prototype has ever reached before. Getting here past the
previous known-good point (reaching game-data validation) took two more
Android-specific bugs, both now fixed — see the first two Known-gaps
items for the full story:

1. Asset loads via raw `io.open()` (e.g. BMP loading in
   `internal/binary_reader.lua`) used paths relative to the OS process's
   working directory, which love-android never sets to the extracted
   source tree the way desktop launches implicitly do. Fixed by having
   `boot.lua` `chdir()` there directly via LuaJIT FFI.
2. `build_apk.bat`/`build_apk` packaged *any* local desktop save/config
   state sitting under `src/save`, `src/temp`, `src/global` straight into
   `game.love` along with real source, since they just zip all of `src/`
   as-is. A stray `global/config` left over from a desktop console run
   crashed the game on first Android launch — it was written uncompressed
   (the console runner has no `love.data`), but real LÖVE's `SaveFs`
   unconditionally gzip-decompresses on read. Fixed by excluding those
   three directories from packaging (and gitignoring them).

Tapping the screen has no effect - see the touch-input Known-gaps item;
this hasn't changed. Menu navigation past the title screen has not yet
been confirmed on-device (needs either touch or a hooked-up hardware/soft
keyboard to test further).

A debug-signed, installable APK builds successfully from this repo's
`src/` (`aapt2 dump badging` + `apksigner verify` both pass — package
`com.quantumeffect.prototype`, label "Quantum Effect"). Real Elona 1.22
assets are in place under `src/deps/elona` and flow into
`src/graphic/`/`src/mod/elona/sound/` automatically. `runtime/android/build_apk.bat`
had its own bug (`call gradlew.bat` doesn't resolve the cwd on systems
where `NoDefaultCurrentDirectoryInExePath` is set — fixed to
`call .\gradlew.bat`).

This is a first working path to an installable Android build of OpenNefia,
using LÖVE's official Android port ([love2d/love-android](https://github.com/love2d/love-android))
rather than a rewrite. It packages `src/` into a `.love` file and embeds it
into a love-android build, same as any other LÖVE-for-Android game.

The engine already has some Android-specific handling in place
(`src/boot.lua`, `src/api/Draw.lua`), so this is closer to "finish wiring up
an existing target" than "add mobile support from scratch."

## One-time setup

1. Install **Android Studio**.
2. In Android Studio → SDK Manager → SDK Tools, tick "Show Package Details"
   and install **NDK (Side by Side) 25.2.9519653**, and SDK Platform **34**.
   (Alternatively use the `cmdline-tools`' `sdkmanager` to install
   `ndk;25.2.9519653` and `platforms;android-34` non-interactively.)
3. Set the `ANDROID_SDK_ROOT` environment variable to your SDK location
   (Android Studio shows this under SDK Manager → Android SDK Location).
4. **Get a standalone JDK 17.** love-android's pinned Gradle wrapper (8.1)
   cannot run under newer JDKs — as of writing, current Android Studio
   releases bundle JDK 25 in their JBR, which fails the build with `BUG!
   exception in phase 'semantic analysis' ... Unsupported class file major
   version 69`. The bundled-JDK-17 assumption in love-android's own README is
   out of date; download a JDK 17 build yourself, e.g.
   [Eclipse Temurin 17](https://adoptium.net/temurin/releases/?version=17)
   for Windows x64, and set `JAVA_HOME_17` to its extracted path — the build
   scripts here pick it up automatically (see below).
5. Clone love-android next to this repo (or anywhere; point `LOVE_ANDROID_DIR`
   at it):

   ```
   git clone --recurse-submodules -b 11.5a https://github.com/love2d/love-android
   ```

   The `-b 11.5a` pins the version that matches what this project has been
   tested against. `conf.lua` currently declares `t.version = "11.3"`, but
   11.5 boots the game fine — no need to hunt for an older tag.

## Building

From this repo's root:

```
set LOVE_ANDROID_DIR=C:\path\to\love-android
set JAVA_HOME_17=C:\path\to\jdk-17
runtime\android\build_apk.bat
```

(or `runtime/android/build_apk` on macOS/Linux, if `LOVE_ANDROID_DIR` isn't
a sibling directory named `love-android`. `JAVA_HOME_17` is only needed if
your default `JAVA_HOME`/Android Studio JBR is newer than 17 — see setup
step 4 above.)

This packages `src/` into a `.love`, drops it into
`app/src/embed/assets/game.love` inside the love-android checkout, and runs
`gradlew assembleEmbedNoRecordDebug`. The debug variant is auto-signed with
a debug key by Gradle, so the resulting APK installs directly — no manual
`jarsigner`/`zipalign` step needed for this prototype stage.

Output APK:

```
<LOVE_ANDROID_DIR>\app\build\outputs\apk\embedNoRecord\debug\app-embed-noRecord-debug.apk
```

Install to a connected device/emulator with `adb install -r <path to apk>`.

## App identity

`<LOVE_ANDROID_DIR>/gradle.properties` has been pre-filled with placeholder
Quantum Effect identity:

```
app.name=Quantum Effect
app.application_id=com.quantumeffect.prototype   # placeholder — change before any real release
app.version_code=1
app.version_name=0.1.0-prototype
```

`app.application_id` is permanent once published to an app store — replace
it with a real reverse-domain id you control before distributing this
anywhere beyond your own devices.

## Known gaps (not addressed by this prototype)

- **Lua module loading crash on boot — fixed and confirmed on-device.**
  This was actually three separate, stacked bugs, all in `src/boot.lua`,
  found by rebuilding and re-testing on an emulator (API 34, x86_64) after
  each fix:

  1. **Wrong absolute path fed to the wrong loader.** The original code
     had an Android-only block that rewrote `package.path` entries like
     `./?.lua` into OS-absolute paths via `love.filesystem.getSource()`,
     on the theory that LÖVE's require machinery needs real filesystem
     paths on Android. Reading love-android 11.5a's own source
     (`love/src/jni/love/src/modules/filesystem/wrap_Filesystem.cpp`,
     `loader()`) shows this premise is backwards: LÖVE's own `require`
     support is a PhysFS-based loader that takes patterns from
     `love.filesystem.getRequirePath()` and resolves them **relative to
     the mounted virtual filesystem root** — the same root whether that's
     an extracted folder (desktop) or a packed `.love` archive (Android).
     It never touches the real OS filesystem or `getSource()`'s path to
     the archive file itself. Feeding it OS-absolute strings like
     `.../cache/game.love/ext/init.lua` makes it look for that entire
     string as a *virtual* path, which doesn't exist (the archive's
     virtual root just has `ext/init.lua` at the top). Desktop never hit
     this because it never entered the Android branch. **Fix:** deleted
     the whole rewrite block; Android now passes the plain relative
     `package.path` through to `setRequirePath`, like every other
     platform.
  2. **PhysFS doesn't treat a leading `./` as a no-op.** With bug 1 fixed,
     `require("ext")` *still* failed. Debug logging
     (`love.filesystem.getInfo("ext/init.lua")` → found;
     `getInfo("./ext/init.lua")` → `nil`) showed that PhysFS-backed
     `getInfo` — unlike a real OS filesystem — does not normalize a
     leading `./`. Every entry this project adds to `package.path` is
     `./`-prefixed, which is harmless for the OS-based vanilla Lua loader
     but silently broke every pattern handed to LÖVE's own loader.
     **Fix:** strip a leading `./` per `;`-separated entry before calling
     `setRequirePath`.
  3. **The deeper one: this codebase's own module system never used
     LÖVE's loader at all.** With 1 and 2 fixed, boot got past
     `require("ext")` and the other early requires — but crashed again on
     `require("api.Draw")` from `main.lua`, this time via
     `internal/env.lua`'s hooked `require` (installed at the end of
     `boot.lua`, and used for almost every `require()` call in the game
     from that point on, including all of mod loading). That hook's
     `env_dofile`/`get_require_path` resolve modules with
     `package.searchpath` + vanilla `loadfile` — real OS file I/O, same
     as `game/startup.lua`'s asset copy (see next item) — which can never
     read into a packed archive on *any* platform, PhysFS quirks aside.
     **Fix:** rather than rewrite this codebase's whole module-loading
     path to be PhysFS-aware, `boot.lua` now extracts the entire mounted
     source tree to `love.filesystem.getSaveDirectory()` (a real,
     writable OS folder on every platform — already relied on elsewhere,
     see `util/fs.lua`) on first launch, gated by a marker file so it only
     happens once, and points `package.path` at that real directory
     instead of relative `./` patterns. Everything downstream — the
     hooked require, mod loading, the asset copy — then works exactly as
     it does on desktop, because it's reading real files instead of a
     mounted archive.

  Confirmed working end to end: a clean install (`pm clear`, so no
  leftover state) now boots through `require`, extracts ~2350 files to
  `/data/data/<package>/files/save/OpenNefia/`, loads all ~50 mods
  ("Loaded mods in 124.58ms"), and reaches real game-data validation — see
  the next item, which was also fixed.

- **Fixed: a fresh install enables ~50 mods by default, and mod-data
  validation was silently broken project-wide.** With the boot crash out
  of the way, a clean-install run originally hit a fatal error in
  `game/startup.lua:126`: `elona_sys.map_tileset:elona.jail: ... Table is
  missing required field 'tiles'`, preceded by dozens of similar
  validation errors. Investigating turned up something bigger than a
  single bad tileset: `fields_strict_checker:check`
  (`src/util/types.lua`) determined whether a data entry was missing a
  required field via `local missing = next(remaining)` — which only ever
  inspects **one arbitrary key** from the set of missing fields (Lua's
  `next()` order depends on string hashing, which isn't guaranteed
  stable across platforms/architectures) and returns success without
  checking the rest. This let the vast majority of missing-required-field
  errors pass silently, on this platform, indefinitely — Android's
  different hash order is what caused `next()` to land on `tiles` and
  actually catch the `elona.jail` case, while desktop `luajit` builds
  happened to land on an already-optional field first and let it through.
  Fixing the loop to check every missing field (not just one) surfaced
  ~1500 previously-hidden validation errors across nearly every core data
  type (items, characters, chips, spells, quests, weather, etc.) once all
  ~50 mods were loaded together. Auditing all of them (see git history for
  the full breakdown) found they fell into three buckets: the large
  majority were schema fields that were never actually wired up as
  required — sibling/duplicate fields on shadow data entries, fields with
  runtime code that already null-checks them, or fields with an explicit
  `default` that was never exempting them from strict validation — all
  now correctly marked `types.optional(...)`; two were genuine content
  gaps (`elona.home`'s `cozy_house`/`estate` entries and the debug
  `elona.slug` race lacked realistic values, now optional too since
  nothing in-engine crashes on their absence); none were unconditionally
  dereferenced live code paths that would have crashed on `nil`. A clean
  install now loads all ~50 mods and passes `verify --load-all-mods` with
  zero errors, and the full test suite (316 tests) still passes.

- **Fixed: asset loads via raw `io.open()` failed after mod loading
  succeeded.** With the two bugs above fixed, a clean install got past mod
  loading and validation but then crashed with `graphic/map1.bmp: No such
  file or directory` the moment it tried to load its first image. The
  module-loading fix above only rewrites `package.path` (used by
  `require`); it doesn't touch the OS process's actual working directory.
  Most asset loading goes through `love.filesystem` (PhysFS-backed, and
  fine), but BMP loading (`internal/bmp_convert.lua` →
  `internal/binary_reader.lua`, used because LÖVE doesn't read BMP
  natively) opens files with plain `io.open()` on paths like
  `"graphic/map1.bmp"` with no directory prefix at all — this only ever
  worked because desktop launches happen to already have the OS working
  directory set to the game's source root. love-android doesn't do that
  for us. **Fix:** `boot.lua`'s Android branch now also points the real
  OS working directory at the extracted save directory, via LuaJIT FFI
  straight into libc's `chdir()` (Lua itself has no working-directory API,
  and this only needs to work on Android/Linux's bionic libc, which always
  provides it).

- **Fixed: local desktop save/config state was getting packaged into the
  APK and crashing first launch.** `build_apk.bat`/`build_apk` zip up all
  of `src/` as-is to build `game.love`, with no exclusions. Both `save/`
  and `global/` (via `api/SaveFs.lua`'s `"save"` and `"global"` kinds) are
  real directories under `src/` used by desktop play/dev sessions to store
  game and config state, and neither was gitignored — so a leftover
  `src/global/config` from a prior desktop console-runner session ended up
  bundled into `game.love`. On a fresh Android install, `boot.lua`'s
  extraction step copies it straight into the app's save directory,
  where the game reads it as if it were real prior state on the very
  first launch, and crashes: `Could not decompress zlib/gzip-compressed
  data`. The root cause is a format mismatch, not corruption — the
  desktop console runner has no `love.data`, so `api/SaveFs.lua`'s
  `compress()` silently no-ops and writes plaintext, while real LÖVE
  always has `love.data` and unconditionally gzip-decompresses on read.
  **Fix:** `build_apk.bat`/`build_apk` now exclude `save/`, `temp/`, and
  `global/` at the `src/` root from packaging, and `.gitignore` now
  covers them too so they don't reappear.

- **Game assets — confirmed working on both desktop and Android.**
  `src/game/startup.lua` copies sprite/sound assets from `src/deps/elona`
  (the original Elona 1.22 freeware) into the game's own asset folders
  (`graphic/`, `mod/elona/sound/`) on first run via raw `io.open()` — this
  only ever worked running unpacked from a real folder, since it can't
  reach into a packaged `.love`/APK on any platform. Fixed the copy step
  itself to skip silently when `deps/elona/...` isn't present
  (`game/startup.lua`'s `copy_files()`), instead of erroring, on the
  assumption that a packaged build ships assets already placed directly
  into `graphic/`/`mod/elona/sound/` rather than expecting to copy them at
  runtime.

  On Android specifically, this now works *because* of the module-loading
  fix above: once `boot.lua` extracts the source tree to a real directory,
  `copy_files()`'s `io.open()` calls work exactly as they do on desktop.
  The emulator run described above reached game-data validation, which
  only happens after `check_dependencies()` runs — confirming the asset
  copy step completed without error on-device, not just on desktop.

  A real Elona 1.22 copy (`elona122.zip`, matching the layout
  `runtime/setup.bat` expects) has since been sourced and extracted into
  `src/deps/elona`. Verified end-to-end on desktop via the console runner
  (no LÖVE/GUI install needed for this): `lib/luajit-2.0/luajit.exe
  opennefia.lua --working-dir . verify` and `... test` both run clean
  (272 graphic files + 165 sound files copied into `src/graphic/` and
  `src/mod/elona/sound/`, full test suite passes). `src/deps`,
  `src/graphic/*`, and `src/mod/elona/sound/*` are already gitignored, so
  none of this lands in version control.

  One thing to remember for future builds: the assets need to be present
  under `src/graphic/`/`src/mod/elona/sound/` (or `src/deps/elona`)
  *before* `src/` gets packaged into `game.love` by `build_apk.bat`/`build_apk`
  — those scripts package `src/` as-is, so whichever of these folders
  exist at build time is what ships in the APK.
- **Touch input / mobile UI.** The UI layer stack was built for keyboard
  and mouse. No touch controls have been added — confirmed on-device:
  once boot reaches the title screen, tapping anywhere on the emulator
  screen (via `adb shell input tap`) has no effect at all on the menu
  cursor, so nothing already translates touch into usable input for this
  codebase's UI stack.
- **Release signing.** This build path produces a debug-signed APK only.
  A real release needs a proper keystore and the `assembleEmbedNoRecordRelease`
  / `bundleEmbedNoRecordRelease` targets (see love-android's
  [Game Packaging wiki](https://github.com/love2d/love-android/wiki/Game-Packaging)).
