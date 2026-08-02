-- Icon chips, sliced from the packed Phase 0.5 icons atlas
-- (tools/quantum-effect/out/pipeline/icons_48.png, copied in as
-- graphic/item/icons_48.png). Same grid-math convention as
-- data/chip_creatures.lua: 33 cols x 48px cells, atlas index = running
-- count in alphabetical-then-manifest order, matching
-- icons_48.png.manifest.json's entry order exactly.
--
-- All 32 successfully-packed icons get a chip here (not just the 18 wired
-- to base.item in data/item_icons.lua below) - the other 14 (elem_*,
-- faction_*, skill_*) don't have an existing OpenNefia data type to attach
-- to yet (no base.element/base.skill icon field, no faction system), so
-- they're registered as chips for future use but nothing references them
-- as game data yet. potion_stamina, elem_lightning, and elem_nature are
-- excluded entirely: all three failed keying (see
-- tools/quantum-effect/README.md, Phase 0.5) and were never packed.

local SOURCE = "mod/quantum_effect/graphic/item/icons_48.png"
local COLUMNS = 33

local icon_ids = {
   "chest_epic", "chest_golden", "chest_legendary", "chest_wooden",
   "coin_gold", "crystal_essence",
   "elem_fire", "elem_ice", "elem_quantum", "elem_void",
   "faction_arclight", "faction_ironaccord", "faction_mechanicum",
   "faction_mystics", "faction_outlaws", "faction_voidsentinels",
   "gem_blue", "gem_green", "gem_purple",
   "potion_epic", "potion_health", "potion_mana",
   "skill_fire", "skill_frost", "skill_nova", "skill_slash",
   "weapon_bow", "weapon_spear", "weapon_staff",
   "weapon_sword", "weapon_sword_legendary", "weapon_sword_rare",
}

local chips = {}
for index, id in ipairs(icon_ids) do
   local x = ((index - 1) % COLUMNS) * 48
   local y = math.floor((index - 1) / COLUMNS) * 48
   chips[#chips + 1] = {
      _id = id,
      _type = "base.chip",
      image = { source = SOURCE, x = x, y = y, width = 48, height = 48, count_x = 1, count_y = 1 },
   }
end

data:add_multi("base.chip", chips)
