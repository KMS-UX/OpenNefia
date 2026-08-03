-- First real base.map_tile entries for Quantum Effect - proves the pack_sprites.ps1
-- pipeline (tools/quantum-effect/README.md) works for map tiles, not just
-- chip/chara/item sprites. Same `image` field, same ty_image table shape
-- (source/x/y/width/height) as elona.*'s legacy atlas tiles use
-- (src/mod/elona/data/map_tile.lua) - see src/internal/data/schemas.lua's
-- "map_tile" type; `elona_id`/`elona_atlas` are optional, so a modern tile
-- can skip them and just point at a real image, same pattern as the
-- `mod/base/graphic/floor.png` fallback tile (src/internal/data/fallbacks.lua).
--
-- Deliberately 48x48, not the 48x96 cell the rest of this mod's tiles/
-- work uses: src/internal/layer/tile_layer.lua draws every tile into one
-- fixed cell size taken from the active theme's coords (tile_width/height,
-- effectively 48x48 - confirmed by every base.map_tile entry across the
-- engine, elona's included, always using width=48/height=48), so a taller
-- image would misalign. This is a SEPARATE, dedicated pack
-- (tools/quantum-effect/out/terrain_sample_48.png) of only 3 of the 41
-- `assets/tiles/terrain/` sprites, chosen because they're unambiguous
-- square ground textures with no baked-in text.
--
-- Only these 3 are wired. The other 38 terrain sprites, and all of
-- building/objects/decor/interior/vehicles (packed at 48x96 in
-- tools/quantum-effect/out/, not yet copied into this mod), have 2-4
-- baked-in section-header label images per subfolder (e.g.
-- "ROCKS / STONES", "DECORATION", "WALLS", "DOORS / GATES") mixed in among
-- the real art, confirmed by eye - triaging which of the ~278 files are
-- real content vs. labels is unstarted follow-up work. See
-- tools/quantum-effect/README.md for the full account.
local SOURCE = "mod/quantum_effect/graphic/tiles/terrain_48.png"

local tiles = {
   { _id = "terrain_cracked_ground", index = 0 },
   { _id = "terrain_dirt", index = 1 },
   { _id = "terrain_cracked_stone", index = 2 },
}

local entries = {}
for _, t in ipairs(tiles) do
   entries[#entries + 1] = {
      _type = "base.map_tile",
      _id = t._id,
      image = {
         source = SOURCE,
         x = (t.index % 33) * 48,
         y = math.floor(t.index / 33) * 48,
         width = 48,
         height = 48,
      },
      is_solid = false,
      is_opaque = false,
   }
end

data:add_multi("base.map_tile", entries)
