return {
   id = "quantum_effect",
   description = [[
First reskin spike for the Quantum Effect initiative: wires four Quantum
Effect character sprites (player, kira, trooper, colossus) into OpenNefia as
real base.chip/base.chara entries, and points quickstart at the QE player
sprite so it's visible immediately on boot without navigating menus.

Source art: VisualAssets/QuantumEffectDesignSystem/assets/characters/sprites/
(not tracked in this repo). Packed to 48x48 (96 tall for colossus) via
tools/quantum-effect/pack_sprites.ps1 - see that folder's README for the
packing pipeline and known source-art caveats.
]],
   version = "0.1.0",
   dependencies = {
      elona = ">= 0"
   }
}
