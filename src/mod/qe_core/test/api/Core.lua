local Event = require("api.Event")
local Assert = require("api.test.Assert")
local TestUtil = require("api.test.TestUtil")
local InstancedMap = require("api.InstancedMap")
local Chara = require("api.Chara")
local Core = require("mod.qe_core.api.Core")
local Resources = require("mod.qe_core.api.Resources")
local Augments = require("mod.qe_core.api.Augments")

-- Real save -> quit -> reload round trip, per the Stage 0 acceptance test
-- in docs/Quantum_Effect_Amendment_B_Engine_Pivot.md's appendix (adapted
-- here from qe_test to qe_core, since Stage 0's qe_test mod was skipped -
-- see PROGRESS.md). Pattern: src/test/location.lua.
function test_Core__save_round_trip()
   local map = InstancedMap:new(10, 10)
   map:clear("elona.cobble")

   local player = Chara.create("base.player", 5, 5, {}, map)
   Chara.set_player(player)
   TestUtil.register_map(map)

   Event.trigger("base.on_init_save")
   Resources.add_contamination(15)
   Augments.install("limbs", "qe_core.limb_servo")

   TestUtil.save_cycle()

   local state = Core.get_state()
   Assert.eq(1, state.version)
   Assert.eq(15, state.contamination)
   Assert.eq("qe_core.limb_servo", state.installed.limbs)
   Assert.eq(100 - 15 - 8, Resources.get_humanity())
end
