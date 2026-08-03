require("mod.qe_core.data.init")
require("mod.qe_core.event.init")

local Gui = require("api.Gui")
local Log = require("api.Log")
local Core = require("mod.qe_core.api.Core")
local Resources = require("mod.qe_core.api.Resources")

-- Debug command (F11): prints the mod's save state to the tools log
-- widget/console via Log.info. There is no dedicated "debug command"
-- registry anywhere in the engine (confirmed by searching src/ for one) -
-- the established pattern is a base.keybind wired through Gui.bind_keys,
-- same mechanism src/mod/tools/init.lua uses for its own F12 debug menu.
Gui.bind_keys {
   ["qe_core.print_state"] = function()
      local state = Core.get_state()
      Log.info(
         "[qe_core] version=%d contamination=%d humanity=%d installed={neuro=%s, limbs=%s, torso_core=%s, spinal=%s, ri_703=%s}",
         state.version,
         state.contamination,
         Resources.get_humanity(),
         tostring(state.installed.neuro),
         tostring(state.installed.limbs),
         tostring(state.installed.torso_core),
         tostring(state.installed.spinal),
         tostring(state.installed.ri_703)
      )
   end
}
