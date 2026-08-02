local Enum = require("api.Enum")

-- Minimal chara definitions, deliberately copying the shape of
-- mod/content/init.lua's "player" entry (the smallest known-valid base.chara
-- in this codebase) rather than the fuller elona.* templates - this is a
-- reskin spike, not new game content, so it only needs to be valid, not rich.
local charas = {
   {
      _id = "player",
      race = "elona.norland",
      class = "elona.tourist",
      relation = Enum.Relation.Neutral,
      image = "quantum_effect.player",
      level = 1,
      rarity = 0,
      coefficient = 400,
   },
   {
      _id = "kira",
      race = "elona.norland",
      class = "elona.tourist",
      relation = Enum.Relation.Ally,
      image = "quantum_effect.kira",
      level = 1,
      rarity = 0,
      coefficient = 400,
   },
   {
      _id = "trooper",
      race = "elona.norland",
      class = "elona.tourist",
      relation = Enum.Relation.Neutral,
      image = "quantum_effect.trooper",
      level = 1,
      rarity = 0,
      coefficient = 400,
   },
   {
      _id = "colossus",
      race = "elona.norland",
      class = "elona.tourist",
      relation = Enum.Relation.Enemy,
      image = "quantum_effect.colossus",
      level = 1,
      rarity = 0,
      coefficient = 400,
   },
}

for _, chara in ipairs(charas) do
   chara._type = "base.chara"
end

data:add_multi("base.chara", charas)
