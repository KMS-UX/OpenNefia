-- The QE event bus other qe_* mods hook into (CLAUDE.md S7 assigns this to
-- qe_core). Event.register refuses an event_id that isn't a registered
-- base.event entry (src/api/EventHolder.lua check_event, line 34-40), so
-- these must be declared before api/Resources.lua and api/Augments.lua can
-- trigger them.
data:add { _type = "base.event", _id = "on_contamination_changed" }
data:add { _type = "base.event", _id = "on_augment_installed" }
data:add { _type = "base.event", _id = "on_augment_uninstalled" }
