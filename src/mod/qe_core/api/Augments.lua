local Event = require("api.Event")
local Core = require("mod.qe_core.api.Core")

local Augments = {}

--- @tparam string slot_id Short slot id, e.g. "neuro" (not "qe_core.neuro").
function Augments.is_slot_unlocked(slot_id)
   return Core.get_state().unlocked[slot_id] == true
end

--- @tparam string slot_id
function Augments.is_slot_occupied(slot_id)
   return Core.get_state().installed[slot_id] ~= nil
end

--- @tparam string slot_id
--- @treturn string|nil The installed augment's full id, or nil if empty.
function Augments.get_installed(slot_id)
   return Core.get_state().installed[slot_id]
end

--- Installs `augment_id` into `slot_id`. Fails loudly (via `assert`) on any
--- invalid request rather than silently no-opping, since a silent failure
--- here is exactly the kind of bug CLAUDE.md S8's message-log rule exists to
--- catch elsewhere - better to crash in dev than let install state and
--- humanity quietly disagree.
---
--- @tparam string slot_id Short slot id, e.g. "neuro".
--- @tparam string augment_id Full augment id, e.g. "qe_core.neuro_basic".
function Augments.install(slot_id, augment_id)
   local state = Core.get_state()
   assert(state.unlocked[slot_id] ~= nil, "unknown slot: " .. tostring(slot_id))
   assert(Augments.is_slot_unlocked(slot_id), "slot is locked: " .. slot_id)
   assert(not Augments.is_slot_occupied(slot_id), "slot is occupied: " .. slot_id)

   local augment = data["qe_core.augment"]:ensure(augment_id)
   local expected_slot = "qe_core." .. slot_id
   assert(augment.slot == expected_slot,
      ("%s belongs in slot %s, not %s"):format(augment_id, augment.slot, expected_slot))

   state.installed[slot_id] = augment._id

   Event.trigger("qe_core.on_augment_installed", { slot_id = slot_id, augment_id = augment._id })
end

--- Removes whatever is installed in `slot_id`, if anything.
---
--- @tparam string slot_id
function Augments.uninstall(slot_id)
   local state = Core.get_state()
   assert(state.unlocked[slot_id] ~= nil, "unknown slot: " .. tostring(slot_id))
   local augment_id = state.installed[slot_id]
   assert(augment_id ~= nil, "slot is already empty: " .. slot_id)

   state.installed[slot_id] = nil

   Event.trigger("qe_core.on_augment_uninstalled", { slot_id = slot_id, augment_id = augment_id })
end

return Augments
