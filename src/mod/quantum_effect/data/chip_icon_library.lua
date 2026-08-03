-- Chips for the icon-library atlas, sliced from Quantum Effect's much
-- larger `assets/icon-library/` design-system folder (381 files across 20
-- categories - weapons/armor/consumables/currencies/chests/materials/
-- quest-key-items/skills/ui-system/etc, sourced from uploads/IconSprites1.png).
-- This is a completely separate, much bigger set than the original 35-file
-- `assets/icons/` folder data/chip_icons.lua already wired - this file is
-- for the newer/larger one specifically, hence the `il_` ("icon library")
-- id prefix throughout, so ids never collide with chip_icons.lua's (e.g.
-- both folders independently have a "chest-wooden"-shaped icon).
--
-- Same grid-math convention as data/chip_creatures.lua: 33 cols x 48px
-- cells, atlas index = running count in manifest order, matching
-- icon_library_48.png.manifest.json's entry order exactly.
--
-- Only the 7 item-shaped categories actually usable for base.item were run
-- through the pipeline (weapons, armor, consumables, currencies, chests,
-- materials, quest-key-items = 187 source files); 3 failed keying/turned out
-- to be mismatched-crop errors from the source sheet and were dropped before
-- packing (bows-5.png and staves-6.png show the wrong weapon type entirely -
-- a slicing-boundary error in the source, not our tooling; consumables-25.png
-- is a merged gem+ring crop) - 184 made it into the atlas. The other 13
-- icon-library categories (achievements, buffs-debuffs, direction-markers,
-- elements, emotes, factions, interface-actions, inventory-categories, map,
-- portrait-frames, rarity-frames, skills, ui-system) are UI/meta icons with
-- no corresponding OpenNefia data type (no achievement system, no faction
-- system, base.skill/base.buff have no icon field) - same situation as the
-- 14 orphaned icons in chip_icons.lua, left for a future session.
--
-- All 184 get a chip here; data/item_icon_library.lua wires the 40 that
-- map to real base.item weapons/containers (33 weapons + 7 chests) - the
-- rest (armor, consumables, currencies-besides-coins/gems, materials,
-- quest-key-items) are registered as chips only for now, same reasoning as
-- above: mapping 45 armor pieces to real equip-slot templates, or 24 quest
-- items to Elona's quest-specific item system, needs its own design pass
-- rather than a mechanical clone, and is flagged as follow-up work.

local SOURCE = "mod/quantum_effect/graphic/item/icon_library_48.png"
local COLUMNS = 33

-- Manifest order (icon_library_48.png.manifest.json) - do not resort.
local filenames = {
   "armor-01","armor-02","armor-03","armor-04","armor-05","armor-06","armor-07","armor-08","armor-09","armor-10",
   "armor-11","armor-12","armor-13","armor-14","armor-15","armor-16","armor-17","armor-18","armor-19","armor-20",
   "armor-21","armor-22","armor-23","armor-24","armor-25","armor-26","armor-27","armor-28","armor-29","armor-30",
   "armor-31","armor-32","armor-33","armor-34","armor-35","armor-36","armor-37","armor-38","armor-39","armor-40",
   "armor-41","armor-42","armor-43","armor-44","armor-45",
   "blades-1","blades-2","blades-3","blades-4","blades-5","blades-6","blades-7",
   "bows-1","bows-2","bows-3","bows-4","bows-6","bows-7",
   "chest-epic","chest-golden","chest-iron","chest-legendary","chest-mythic","chest-rare","chest-wooden",
   "coin-1","coin-2","coin-3",
   "consumables-01","consumables-02","consumables-03","consumables-04","consumables-05","consumables-06",
   "consumables-07","consumables-08","consumables-09","consumables-10","consumables-11","consumables-12",
   "consumables-13","consumables-14","consumables-15","consumables-16","consumables-17","consumables-18",
   "consumables-19","consumables-20","consumables-21","consumables-22","consumables-23","consumables-24",
   "energy-1","energy-2","energy-3",
   "gem-1","gem-2","gem-3","gem-4","gem-5","gem-6",
   "materials-01","materials-02","materials-03","materials-04","materials-05","materials-06","materials-07",
   "materials-08","materials-09","materials-10","materials-11","materials-12","materials-13","materials-14",
   "materials-15","materials-16","materials-17","materials-18","materials-19","materials-20","materials-21",
   "materials-22","materials-23","materials-24","materials-25","materials-26","materials-27","materials-28",
   "materials-29","materials-30",
   "quest-key-items-01","quest-key-items-02","quest-key-items-03","quest-key-items-04","quest-key-items-05",
   "quest-key-items-06","quest-key-items-07","quest-key-items-08","quest-key-items-09","quest-key-items-10",
   "quest-key-items-11","quest-key-items-12","quest-key-items-13","quest-key-items-14","quest-key-items-15",
   "quest-key-items-16","quest-key-items-17","quest-key-items-18","quest-key-items-19","quest-key-items-20",
   "quest-key-items-21","quest-key-items-22","quest-key-items-23","quest-key-items-24",
   "reputation-1","reputation-2","reputation-3",
   "spears-1","spears-2","spears-3","spears-4","spears-5","spears-6","spears-7",
   "staves-1","staves-2","staves-3","staves-4","staves-5","staves-7",
   "swords-1","swords-2","swords-3","swords-4","swords-5","swords-6","swords-7",
   "token-1","token-2","token-3",
   "voucher-1","voucher-2","voucher-3",
}

local chips = {}
for index, name in ipairs(filenames) do
   local id = "il_" .. name:gsub("-", "_")
   local x = ((index - 1) % COLUMNS) * 48
   local y = math.floor((index - 1) / COLUMNS) * 48
   chips[#chips + 1] = {
      _id = id,
      _type = "base.chip",
      image = { source = SOURCE, x = x, y = y, width = 48, height = 48, count_x = 1, count_y = 1 },
   }
end

data:add_multi("base.chip", chips)
