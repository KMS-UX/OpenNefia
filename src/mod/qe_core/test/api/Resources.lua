local Event = require("api.Event")
local Assert = require("api.test.Assert")
local Core = require("mod.qe_core.api.Core")
local Resources = require("mod.qe_core.api.Resources")
local Augments = require("mod.qe_core.api.Augments")

-- Each test triggers "base.on_init_save" itself rather than relying on a
-- full game boot, since field_layer:init_global_data (which normally fires
-- it) isn't part of the mod test harness. Per docs/ARCHITECTURE.md,
-- "Testing", the engine resets global state before each mod's test suite.
local function fresh_state()
   Event.trigger("base.on_init_save")
end

function test_Resources__starts_at_full_humanity_no_contamination()
   fresh_state()

   Assert.eq(100, Resources.get_humanity())
   Assert.eq(0, Resources.get_contamination())
end

function test_Resources__contamination_lowers_humanity_and_clamps()
   fresh_state()

   Resources.add_contamination(30)
   Assert.eq(30, Resources.get_contamination())
   Assert.eq(70, Resources.get_humanity())

   -- clamps at the data-defined max (100), not below/above it
   Resources.add_contamination(1000)
   Assert.eq(100, Resources.get_contamination())
   Assert.eq(0, Resources.get_humanity())

   Resources.add_contamination(-1000)
   Assert.eq(0, Resources.get_contamination())
   Assert.eq(100, Resources.get_humanity())
end

function test_Resources__installed_augments_lower_humanity_by_invasiveness()
   fresh_state()

   Augments.install("neuro", "qe_core.neuro_basic")
   Assert.eq(100 - 5, Resources.get_humanity())

   Augments.install("limbs", "qe_core.limb_servo")
   Assert.eq(100 - 5 - 8, Resources.get_humanity())

   Augments.uninstall("neuro")
   Assert.eq(100 - 8, Resources.get_humanity())
end

function test_Resources__humanity_is_never_stored()
   fresh_state()

   Augments.install("spinal", "qe_core.spinal_reflex_booster")
   Resources.add_contamination(10)

   -- Resources.get_humanity() is a pure function of state, not a field on
   -- it - CLAUDE.md S8: "humanity is a key, not a meter".
   Assert.eq(nil, Core.get_state().humanity)
   Assert.eq(100 - 6 - 10, Resources.get_humanity())
end
