local Event = require("api.Event")
local Assert = require("api.test.Assert")
local Augments = require("mod.qe_core.api.Augments")

local function fresh_state()
   Event.trigger("base.on_init_save")
end

function test_Augments__default_slot_lock_state()
   fresh_state()

   Assert.is_truthy(Augments.is_slot_unlocked("neuro"))
   Assert.is_truthy(Augments.is_slot_unlocked("limbs"))
   Assert.is_truthy(Augments.is_slot_unlocked("spinal"))
   Assert.is_falsy(Augments.is_slot_unlocked("torso_core"))
   Assert.is_falsy(Augments.is_slot_unlocked("ri_703"))
end

function test_Augments__install_and_uninstall_round_trip()
   fresh_state()

   Assert.is_falsy(Augments.is_slot_occupied("neuro"))

   Augments.install("neuro", "qe_core.neuro_basic")
   Assert.is_truthy(Augments.is_slot_occupied("neuro"))
   Assert.eq("qe_core.neuro_basic", Augments.get_installed("neuro"))

   Augments.uninstall("neuro")
   Assert.is_falsy(Augments.is_slot_occupied("neuro"))
   Assert.eq(nil, Augments.get_installed("neuro"))
end

function test_Augments__rejects_install_into_locked_slot()
   fresh_state()

   Assert.throws_error(function()
      Augments.install("torso_core", "qe_core.neuro_basic")
   end, "locked")
end

function test_Augments__rejects_install_into_occupied_slot()
   fresh_state()

   Augments.install("neuro", "qe_core.neuro_basic")
   Assert.throws_error(function()
      Augments.install("neuro", "qe_core.neuro_basic")
   end, "occupied")
end

function test_Augments__rejects_augment_in_wrong_slot()
   fresh_state()

   -- neuro_basic belongs in "neuro", not "limbs"
   Assert.throws_error(function()
      Augments.install("limbs", "qe_core.neuro_basic")
   end, "belongs in slot")
end

function test_Augments__rejects_uninstall_of_empty_slot()
   fresh_state()

   Assert.throws_error(function()
      Augments.uninstall("neuro")
   end, "already empty")
end
