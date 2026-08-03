local Event = require("api.Event")
local Core = require("mod.qe_core.api.Core")

local Resources = {}

function Resources.get_contamination()
   return Core.get_state().contamination
end

--- Adds `delta` to contamination, clamped to qe_core.resource.contamination's
--- data-defined min/max, and fires "qe_core.on_contamination_changed".
---
--- @tparam int delta
--- @treturn int The new contamination value.
function Resources.add_contamination(delta)
   local state = Core.get_state()
   local res = data["qe_core.resource"]:ensure("qe_core.contamination")
   local prev = state.contamination
   state.contamination = math.clamp(prev + delta, res.min, res.max)

   if state.contamination ~= prev then
      Event.trigger("qe_core.on_contamination_changed", { previous = prev, current = state.contamination })
   end

   return state.contamination
end

--- Total humanity cost of every augment currently installed, i.e.
--- S(implant invasiveness) in the CLAUDE.md S8 formula.
---
--- @treturn int
local function installed_invasiveness()
   local state = Core.get_state()
   local total = 0
   for _, augment_id in pairs(state.installed) do
      if augment_id ~= nil then
         total = total + data["qe_core.augment"]:ensure(augment_id).invasiveness
      end
   end
   return total
end

--- Humanity per CLAUDE.md S8 / Amendment B D-22:
---   humanity = 100 - S(implant invasiveness) - S(skill humanity_delta)
---              - contamination + S(narrative overrides)
---
--- Deliberately not stored (see data/qe_core/resource.lua) - always
--- recomputed so it can never drift from what produced it.
---
--- The "S(skill humanity_delta)" term is always 0 today: no skill system
--- exists yet in any qe_* mod for it to sum over. Add it here, not as a
--- literal skipped step, once qe_* skills exist.
---
--- @treturn int Clamped to [0, 100].
function Resources.get_humanity()
   local state = Core.get_state()
   local skill_humanity_delta = 0
   local humanity = 100 - installed_invasiveness() - skill_humanity_delta
      - state.contamination + state.narrative_overrides
   return math.clamp(humanity, 0, 100)
end

return Resources
