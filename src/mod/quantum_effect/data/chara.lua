local Enum = require("api.Enum")

-- "player" is NOT cloned from a monster template like the rows below - it's
-- the literal chara passed to `Chara.create()` by field_logic.quickstart()
-- (via config.base.quickstart_chara_id, see mod/quantum_effect/init.lua),
-- which then runs Skill.apply_race_params/apply_class_params on the result.
-- race/class here already match vanilla's own mod/content/init.lua "player"
-- entry exactly, so this already *is* real player data, not a placeholder;
-- cloning a monster's ai_actions/loot_type/tone onto it would just add
-- nonsensical fields to the actual playable character.
data:add {
   _type = "base.chara",
   _id = "player",

   race = "elona.norland",
   class = "elona.tourist",
   relation = Enum.Relation.Neutral,
   image = "quantum_effect.player",
   level = 1,
   rarity = 0,
   coefficient = 400,
}

-- kira/trooper/colossus are ordinary NPCs (never passed through
-- Chara.create() specially), so - like data/chara_creatures.lua - each
-- clones a full elona.* base.chara template rather than being a bare
-- stand-in. Template choice was screened for narrative fit, not just
-- stats: a chara's `tone` field drives its base.aggro/base.dead combat
-- barks, so e.g. elona.guard was rejected for kira despite otherwise
-- fitting (a friendly companion should not shout "Stop there criminal!").
--
-- - kira: elona.warrior - plain humanoid ally, no tone/dialogue baggage to
--   clash with being a friendly named companion.
-- - trooper: elona.palmian_elite_soldier - its own tone
--   ("Fire fire fire!", "Man down!") is exactly rank-and-file-soldier
--   flavor, matching the "Elite Trooper" security-profession naming in the
--   design system (VisualAssets/.../assets/data/manifest.json).
-- - colossus: elona.iron_maiden - machine race, no dialogue at all (can't
--   clash), and thematically fits a mechanical superboss; level bumped to
--   match the "void-colossus"/"null-colossus" high-threat boss framing in
--   VisualAssets/.../assets/bestiary/{bosses,highthreat}/.
--
-- { _id, template elona.* id, relation override (nil = keep template's
--   own), level override (nil = keep template's own) }
local rows = {
   { "kira", "elona.warrior", Enum.Relation.Ally },
   { "trooper", "elona.palmian_elite_soldier" },
   { "colossus", "elona.iron_maiden", nil, 45 },
}

for _, row in ipairs(rows) do
   local id, template_id, relation, level = row[1], row[2], row[3], row[4]

   local template = data["base.chara"]:ensure(template_id)
   local clone = table.deepcopy(template)

   clone._id = id
   clone._type = "base.chara"
   clone.image = "quantum_effect." .. id
   clone.elona_id = nil
   -- See data/chara_creatures.lua: several templates palette-tint a shared
   -- vanilla sprite via `color`, or pick art by gender via
   -- male_image/female_image. Irrelevant here since our chip art is unique
   -- and ungendered, but cleared anyway so neither field is left stale and
   -- misleading for a future reader.
   clone.color = nil
   clone.random_color = nil
   clone.male_image = nil
   clone.female_image = nil
   if relation then
      clone.relation = relation
   end
   if level then
      clone.level = level
   end

   data:add(clone)
end
