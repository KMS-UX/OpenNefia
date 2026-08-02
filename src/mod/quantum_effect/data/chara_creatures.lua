-- Bestiary creatures: each clones a full elona.* template (stats, ai, loot,
-- resistances, tags, etc.) rather than being a bare stand-in, so they're
-- functioning monsters, just reskinned with quantum_effect chip art.
--
-- Template choices are grouped by the biome each cleaned sprite sheet came
-- from (see tools/quantum-effect/README.md, Phase 0.5); where a biome's
-- vanilla template pool is smaller than 7, a template is reused across two
-- slots with an explicit `level` bump so they aren't literal stat-for-stat
-- duplicates. `elona_id` is always cleared on the clone: it's an
-- indexed+unique field in the schema (schemas.lua), and leaving the
-- template's own value in place makes data:add hard-error on ID collision
-- during data loading. `color` is also always cleared: several templates
-- use it to palette-swap-tint a *shared* vanilla sprite (the golem family,
-- red_wasp, chaos_mushroom, ...), and our chip art is unique per creature
-- already, so a leftover tint would multiply an unwanted colour cast over
-- unrelated art.
--
-- forest only has 6 rows: forest_07's chip is skipped (see
-- data/chip_creatures.lua), so there is no forest_07 chara either.

-- { _id, template elona.* id, level override (nil = keep template's own) }
local rows = {
   -- arctic
   { "arctic_01", "elona.ice_hound" },
   { "arctic_02", "elona.ice_hound", 15 },
   { "arctic_03", "elona.ice_ent" },
   { "arctic_04", "elona.ice_drake" },
   { "arctic_05", "elona.ice_drake", 22 },
   { "arctic_06", "elona.white_dragon" },
   { "arctic_07", "elona.white_dragon", 50 },

   -- cavern
   { "cavern_01", "elona.rat" },
   { "cavern_02", "elona.bat" },
   { "cavern_03", "elona.centipede" },
   { "cavern_04", "elona.vampire_bat" },
   { "cavern_05", "elona.vampire_bat", 14 },
   { "cavern_06", "elona.mine_dog" },
   { "cavern_07", "elona.mine_dog", 20 },

   -- coastal
   { "coastal_01", "elona.hermit_crab" },
   { "coastal_02", "elona.hedgehog" },
   { "coastal_03", "elona.hungry_sea_lion" },
   { "coastal_04", "elona.shining_hedgehog" },
   { "coastal_05", "elona.fire_crab" },
   { "coastal_06", "elona.super_hungry_sea_lion" },
   { "coastal_07", "elona.fire_crab", 22 },

   -- desert
   { "desert_01", "elona.scorpion" },
   { "desert_02", "elona.lesser_mummy" },
   { "desert_03", "elona.cobra" },
   { "desert_04", "elona.mummy" },
   { "desert_05", "elona.king_cobra" },
   { "desert_06", "elona.greater_mummy" },
   { "desert_07", "elona.king_scorpion" },

   -- flying
   { "flying_01", "elona.wasp" },
   { "flying_02", "elona.deformed_eye" },
   { "flying_03", "elona.red_wasp" },
   { "flying_04", "elona.harpy" },
   { "flying_05", "elona.impure_eye" },
   { "flying_06", "elona.wyvern" },
   { "flying_07", "elona.wyvern", 30 },

   -- forest (only 6: forest_07's chip was skipped, see chip_creatures.lua)
   { "forest_01", "elona.giant_squirrel" },
   { "forest_02", "elona.hound" },
   { "forest_03", "elona.killer_squirrel" },
   { "forest_04", "elona.grizzly" },
   { "forest_05", "elona.beetle", 12 },
   { "forest_06", "elona.fire_ent" },

   -- insectoid
   { "insectoid_01", "elona.spider" },
   { "insectoid_02", "elona.mandrake" },
   { "insectoid_03", "elona.beetle" },
   { "insectoid_04", "elona.centipede", 8 },
   { "insectoid_05", "elona.black_widow" },
   { "insectoid_06", "elona.tarantula" },
   { "insectoid_07", "elona.paralyzer" },

   -- mineral_construct (the vanilla golem family is already a 7-tier ladder)
   { "mineral_construct_01", "elona.wooden_golem" },
   { "mineral_construct_02", "elona.stone_golem" },
   { "mineral_construct_03", "elona.steel_golem" },
   { "mineral_construct_04", "elona.golden_golem" },
   { "mineral_construct_05", "elona.mithril_golem" },
   { "mineral_construct_06", "elona.sky_golem" },
   { "mineral_construct_07", "elona.adamantium_golem" },

   -- mountain
   { "mountain_01", "elona.lion" },
   { "mountain_02", "elona.cyclops" },
   { "mountain_03", "elona.mammoth" },
   { "mountain_04", "elona.lion", 30 },
   { "mountain_05", "elona.cyclops", 35 },
   { "mountain_06", "elona.titan" },
   { "mountain_07", "elona.titan", 50 },

   -- plains
   { "plains_01", "elona.rabbit" },
   { "plains_02", "elona.wild_sheep" },
   { "plains_03", "elona.chicken" },
   { "plains_04", "elona.hound", 8 },
   { "plains_05", "elona.grizzly", 16 },
   { "plains_06", "elona.lion", 20 },
   { "plains_07", "elona.mammoth", 30 },

   -- plant_fungi
   { "plant_fungi_01", "elona.mushroom" },
   { "plant_fungi_02", "elona.pumpkin" },
   { "plant_fungi_03", "elona.spore_mushroom" },
   { "plant_fungi_04", "elona.man_eater_flower" },
   { "plant_fungi_05", "elona.greater_pumpkin" },
   { "plant_fungi_06", "elona.chaos_flower" },
   { "plant_fungi_07", "elona.chaos_mushroom" },

   -- swamp
   { "swamp_01", "elona.snail" },
   { "swamp_02", "elona.flying_frog" },
   { "swamp_03", "elona.mushroom", 7 },
   { "swamp_04", "elona.zombie" },
   { "swamp_05", "elona.cobra" },
   { "swamp_06", "elona.zombie", 18 },
   { "swamp_07", "elona.king_cobra", 22 },
}

for _, row in ipairs(rows) do
   local id, template_id, level = row[1], row[2], row[3]

   local template = data["base.chara"]:ensure(template_id)
   local clone = table.deepcopy(template)

   clone._id = id
   clone._type = "base.chara"
   clone.image = "quantum_effect." .. id
   clone.elona_id = nil
   -- Several templates (the golem family, red_wasp, chaos_mushroom, etc.)
   -- set `color` to palette-swap-tint a *shared* vanilla sprite. Our chip
   -- art is unique per creature already, so a leftover tint would just
   -- multiply an unwanted colour cast over unrelated art.
   clone.color = nil
   if level then
      clone.level = level
   end

   data:add(clone)
end
