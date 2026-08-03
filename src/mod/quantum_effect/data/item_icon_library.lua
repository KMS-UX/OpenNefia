-- Wires 40 of the 184 icon-library chips (see data/chip_icon_library.lua)
-- into real base.item data: 33 weapons + 7 containers. Same two cloning
-- paths as data/item_icons.lua (read that file's header first if this is
-- unfamiliar) - weapons need the _ext-identity-preserving clone because
-- their real behavior lives in `_ext[IItemEquipment]`/
-- `_ext[IItemMeleeWeapon]`/`_ext[IItemRangedWeapon]`, while containers have
-- no `_ext` at all and are safe with a plain deepcopy.
--
-- Template selection: Elona's actual weapon roster is much deeper than the
-- ~6 items data/item_icons.lua drew from - each subtype below (sword/
-- blade/spear/staff/bow) has its own family of real, distinct vanilla
-- items, verified individually against mod/elona/data/item/equip/
-- {melee,ranged}.lua (not guessed): none of the chosen templates carry
-- quest-tied `events` (the failure mode that ruled out chara templates
-- like elona.little_sister in data/chara_creatures.lua) - these are all
-- plain stat/equipment items, safe to reuse under a new _id. Several
-- vanilla uniques (elona.diablo, elona.mournblade, elona.hiryu_to, ...)
-- are used deliberately: a Unique base.item just means vanilla's own world
-- generation won't spawn more than one of THAT _id - cloning it under our
-- own new _id is a fully independent item type and doesn't touch that
-- constraint (unlike unique base.chara, which often carry save-state-
-- tracking events - the actual hazard there, not the Unique flag itself).
--
-- Where a subtype's real template pool is smaller than the icon count
-- (spears has 5 distinct polearms for 7 icons, staves has 4 for 6), the
-- shortfall is covered by reusing a template with an explicit level
-- override - same convention as data/chara_creatures.lua's biome ladders.
--
-- Containers: Elona has no 7-tier "treasure chest" item family (unlike its
-- golem line), so all 7 chest icons clone the one generic opening
-- container (elona.chest - a real on_open loot-generating container, not
-- a flavor prop) varying only `value` per named tier.

local IItemEquipment = require("mod.elona.api.aspect.IItemEquipment")
local IItemMeleeWeapon = require("mod.elona.api.aspect.IItemMeleeWeapon")
local IItemRangedWeapon = require("mod.elona.api.aspect.IItemRangedWeapon")

local function finalize(clone, id)
   clone._id = id
   clone._type = "base.item"
   clone.image = "quantum_effect." .. id
   clone.elona_id = nil
   clone.color = nil
   clone.random_color = nil
   data:add(clone)
end

-- Containers: no `_ext`, so a full deepcopy is safe.
local function add_container(id, template_id, value)
   local clone = table.deepcopy(data["base.item"]:ensure(template_id))
   clone.value = value
   finalize(clone, id)
end

-- Weapons: shallow copy, then rebuild `_ext` keeping the real interface
-- tables as keys (see data/item_icons.lua's header for why this is
-- required instead of a plain deepcopy).
local function add_weapon(id, template_id, level)
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

   if level then
      clone.level = level
   end

   finalize(clone, id)
end

-- Swords (broadsword/longsword family) - 7 distinct templates, no reuse needed.
add_weapon("il_sword_01", "elona.long_sword")
add_weapon("il_sword_02", "elona.claymore")
add_weapon("il_sword_03", "elona.claymore_unique")
add_weapon("il_sword_04", "elona.diablo")
add_weapon("il_sword_05", "elona.mournblade")
add_weapon("il_sword_06", "elona.ragnarok")
add_weapon("il_sword_07", "elona.dragon_slayer")

-- Blades (short-blade family) - 7 distinct templates, no reuse needed.
add_weapon("il_blades_1", "elona.dagger")
add_weapon("il_blades_2", "elona.kitchen_knife")
add_weapon("il_blades_3", "elona.ether_dagger")
add_weapon("il_blades_4", "elona.lucky_dagger")
add_weapon("il_blades_5", "elona.scimitar")
add_weapon("il_blades_6", "elona.wakizashi")
add_weapon("il_blades_7", "elona.hiryu_to")

-- Bows - 6 distinct templates (bows-5.png was dropped, see chip_icon_library.lua).
add_weapon("il_bows_1", "elona.long_bow")
add_weapon("il_bows_2", "elona.short_bow")
add_weapon("il_bows_3", "elona.wind_bow")
add_weapon("il_bows_4", "elona.skull_bow")
add_weapon("il_bows_6", "elona.crossbow")
add_weapon("il_bows_7", "elona.bow_of_vindale")

-- Spears/polearms - only 5 distinct templates exist for 7 icons; spear and
-- trident are reused with a level bump for the last two slots.
add_weapon("il_spears_1", "elona.spear")
add_weapon("il_spears_2", "elona.trident")
add_weapon("il_spears_3", "elona.halberd")
add_weapon("il_spears_4", "elona.rankis")
add_weapon("il_spears_5", "elona.holy_lance")
add_weapon("il_spears_6", "elona.spear", 20)
add_weapon("il_spears_7", "elona.trident", 25)

-- Staves - only 4 distinct templates exist for 6 icons (staves-6.png was
-- dropped); staff and long_staff are reused with a level bump.
add_weapon("il_staves_1", "elona.staff")
add_weapon("il_staves_2", "elona.long_staff")
add_weapon("il_staves_3", "elona.staff_of_insanity")
add_weapon("il_staves_4", "elona.elemental_staff")
add_weapon("il_staves_5", "elona.staff", 15)
add_weapon("il_staves_7", "elona.long_staff", 20)

-- Containers - one generic opening chest, value scaled per named tier.
add_container("il_chest_wooden", "elona.chest", 200)
add_container("il_chest_iron", "elona.chest", 800)
add_container("il_chest_golden", "elona.chest", 2500)
add_container("il_chest_rare", "elona.chest", 6000)
add_container("il_chest_epic", "elona.chest", 15000)
add_container("il_chest_mythic", "elona.chest", 35000)
add_container("il_chest_legendary", "elona.chest", 90000)
