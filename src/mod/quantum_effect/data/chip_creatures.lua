-- Bestiary creature chips, sliced from the packed Phase 0.5 atlas
-- (tools/quantum-effect/out/pipeline/creatures_48.png, copied in as
-- graphic/chara/creatures_48.png). Grid math mirrors elona.data.chip's
-- make_chip_group: 33 cols x 48px cells, atlas index = running count in
-- biome-alphabetical, then-slot-number order, matching
-- creatures_48.png.manifest.json's entry order exactly.
--
-- forest_07 (atlas index 41) is intentionally skipped: its badge is still
-- baked into the art (see tools/quantum-effect/README.md, Phase 0.5 known
-- issues), so no chip is registered for that atlas cell.

local SOURCE = "mod/quantum_effect/graphic/chara/creatures_48.png"
local COLUMNS = 33

local biomes = {
   "arctic", "cavern", "coastal", "desert", "flying", "forest",
   "insectoid", "mineral_construct", "mountain", "plains", "plant_fungi", "swamp",
}

local SKIP_IDS = { forest_07 = true }

local chips = {}
local index = 0
for _, biome in ipairs(biomes) do
   for slot = 1, 7 do
      local id = string.format("%s_%02d", biome, slot)
      if not SKIP_IDS[id] then
         local x = (index % COLUMNS) * 48
         local y = math.floor(index / COLUMNS) * 48
         chips[#chips + 1] = {
            _id = id,
            _type = "base.chip",
            image = { source = SOURCE, x = x, y = y, width = 48, height = 48, count_x = 1, count_y = 1 },
         }
      end
      index = index + 1
   end
end

data:add_multi("base.chip", chips)
