-- Registers on "base.on_init_save", triggered once per new game by
-- src/game/field_layer.lua:84-90 (field_layer:init_global_data). Save data
-- lives mod-level (`save.qe_core`), not keyed to the player character - this
-- answers the open question in PROGRESS.md S6: there is exactly one Quantum
-- Baby protagonist, so a per-character key would just be indirection.
--
-- Pattern: src/mod/weight_graph/event/save.lua.
local Event = require("api.Event")

local VERSION = 1

local function init_save()
   local s = save.qe_core
   s.version = VERSION
   s.contamination = data["qe_core.resource"]:ensure("qe_core.contamination").default
   -- narrative_overrides is the "+ S(narrative overrides)" term in the
   -- humanity formula (CLAUDE.md S8). No narrative/story system exists yet
   -- to write to it; it stays 0 until one does.
   s.narrative_overrides = 0
   s.installed = {
      neuro = nil,
      limbs = nil,
      torso_core = nil,
      spinal = nil,
      ri_703 = nil
   }
   s.unlocked = {
      neuro = data["qe_core.augment_slot"]:ensure("qe_core.neuro").default_unlocked,
      limbs = data["qe_core.augment_slot"]:ensure("qe_core.limbs").default_unlocked,
      torso_core = data["qe_core.augment_slot"]:ensure("qe_core.torso_core").default_unlocked,
      spinal = data["qe_core.augment_slot"]:ensure("qe_core.spinal").default_unlocked,
      ri_703 = data["qe_core.augment_slot"]:ensure("qe_core.ri_703").default_unlocked
   }
end

Event.register("base.on_init_save", "Init save (qe_core)", init_save)
