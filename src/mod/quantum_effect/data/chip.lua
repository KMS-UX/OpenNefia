-- Standalone chip images (not atlas sub-rects) - each is its own full PNG,
-- one character per file, produced by tools/quantum-effect/pack_sprites.ps1.
-- A plain string `image` (rather than the {source=,x=,y=,...} table form
-- used for atlas sheets like elona.chara_rabbit) is enough here; see
-- mod/ceri_items/data/chip.lua for the same pattern with item chips.
local chips = {
   {
      _id = "player",
      image = "mod/quantum_effect/graphic/chara/player.png",
   },
   {
      _id = "kira",
      image = "mod/quantum_effect/graphic/chara/kira.png",
   },
   {
      _id = "trooper",
      image = "mod/quantum_effect/graphic/chara/trooper.png",
   },
   {
      _id = "colossus",
      image = "mod/quantum_effect/graphic/chara/colossus.png",
      is_tall = true,
   },
}

for _, chip in ipairs(chips) do
   chip._type = "base.chip"
end

data:add_multi("base.chip", chips)
