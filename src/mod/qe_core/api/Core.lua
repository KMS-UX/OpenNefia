local Core = {}

--- Returns this session's persisted qe_core state table. Always populated
--- once a game is loaded, since event/save.lua fills it in on
--- "base.on_init_save" (src/game/field_layer.lua:84-90, once per new game).
--- Save data is mod-level, not player-keyed - see event/save.lua for why.
---
--- @treturn table
function Core.get_state()
   assert(save.qe_core and save.qe_core.version, "qe_core save data not initialized - is a game loaded?")
   return save.qe_core
end

return Core
