-- Item icons: each clones a full elona.* item template (value, weight,
-- rarity, categories, drink/equip behavior) rather than being a bare
-- image stand-in, mirroring data/chara_creatures.lua's approach for
-- monsters. Only 18 of the 32 packed icons map to a real inventory item;
-- the rest (elem_*, faction_*, skill_*) have no existing OpenNefia data
-- type to attach to and are left as chip-only art for now (see
-- data/chip_icons.lua).
--
-- Two cloning paths are needed, not one, because base.item has a second
-- indexed/unique-ish hazard beyond `elona_id`:
--
-- 1. Plain items (containers, currency, ore/gems) carry no `_ext` table at
--    all, so a straight `table.deepcopy` + `_id`/`image` override +
--    `elona_id = nil` is exactly as safe as it was for base.chara.
-- 2. Weapons and potions store their actual mechanical behavior in
--    `_ext[IItemEquipment]`/`_ext[IItemMeleeWeapon]`/`_ext[IItemRangedWeapon]`/
--    `_ext[IItemPotion]`, where the *keys* are the literal aspect-interface
--    module tables (see api/Aspect.lua, api/aspect/IItem*.lua).
--    `table.deepcopy` recurses into table keys too, so it would replace
--    each interface key with a same-shape-but-different-identity copy;
--    `class.is_interface()` (util/class.lua) checks identity against a
--    registry keyed by the *original* table reference, so the copied key
--    silently fails that check and the whole aspect gets dropped - no
--    error, the item just spawns unequippable / undrinkable. Fix: shallow
--    copy the item table, then rebuild `_ext` by keeping the real
--    interface tables as keys and deep-copying only their (plain-data)
--    per-aspect config values.
--
-- Every clone (both paths) also clears `color` and `random_color`: several
-- templates use these to tint/randomize a *shared* vanilla sprite
-- (palette-swapped chests, `random_color = "Random"` on potions for the
-- classic "unidentified potion has a random colour" mechanic). Our chip
-- art is unique and pre-coloured per item already, so leaving either set
-- would recolour it unpredictably instead of just showing the art as-is.

local IItemEquipment = require("mod.elona.api.aspect.IItemEquipment")
local IItemMeleeWeapon = require("mod.elona.api.aspect.IItemMeleeWeapon")
local IItemRangedWeapon = require("mod.elona.api.aspect.IItemRangedWeapon")
local IItemPotion = require("mod.elona.api.aspect.IItemPotion")

local function finalize(clone, id)
   clone._id = id
   clone._type = "base.item"
   clone.image = "quantum_effect." .. id
   clone.elona_id = nil
   clone.color = nil
   clone.random_color = nil
   data:add(clone)
end

-- Plain items: no `_ext`, so a full deepcopy is safe.
local function add_plain_item(id, template_id)
   local clone = table.deepcopy(data["base.item"]:ensure(template_id))
   finalize(clone, id)
end

-- Weapons/potions: shallow copy the item, then rebuild `_ext` keeping the
-- real interface tables as keys (see the file header comment for why).
local function add_aspect_item(id, template_id)
   local template = data["base.item"]:ensure(template_id)
   local clone = table.shallow_copy(template)

   clone.categories = table.deepcopy(template.categories)
   if template.enchantments then
      clone.enchantments = table.deepcopy(template.enchantments)
   end

   clone._ext = {}
   for iface, cfg in pairs(template._ext) do
      clone._ext[iface] = table.deepcopy(cfg)
   end

   finalize(clone, id)
end

-- Containers
add_plain_item("chest_wooden", "elona.chest")
add_plain_item("chest_golden", "elona.bejeweled_chest")
add_plain_item("chest_epic", "elona.treasure_ball")
add_plain_item("chest_legendary", "elona.rare_treasure_ball")

-- Currency
add_plain_item("coin_gold", "elona.gold_piece")

-- Crystal / gems (ore.lua)
add_plain_item("crystal_essence", "elona.mana_crystal")
add_plain_item("gem_blue", "elona.raw_ore_of_diamond")
add_plain_item("gem_green", "elona.raw_ore_of_emerald")
-- No vanilla purple gem exists; closest raw-gem-ore template, recoloured
-- by our own chip art (color is cleared on every clone regardless).
add_plain_item("gem_purple", "elona.raw_ore_of_rubynus")

-- Potions
add_aspect_item("potion_health", "elona.potion_of_cure_critical_wound")
-- No vanilla MP-restore potion exists (Elona regens MP via rest/eating,
-- not potions). Closest analog is a stat-restoration potion, not a true
-- MP refill - flagged here in case gameplay later wants a custom
-- on_drink/effect instead of this template.
add_aspect_item("potion_mana", "elona.potion_of_restore_spirit")
add_aspect_item("potion_epic", "elona.bottle_of_hermes_blood")

-- Weapons
add_aspect_item("weapon_bow", "elona.long_bow")
add_aspect_item("weapon_spear", "elona.spear")
add_aspect_item("weapon_staff", "elona.staff")
add_aspect_item("weapon_sword", "elona.long_sword")
add_aspect_item("weapon_sword_rare", "elona.lightsabre")
add_aspect_item("weapon_sword_legendary", "elona.zantetsu")
