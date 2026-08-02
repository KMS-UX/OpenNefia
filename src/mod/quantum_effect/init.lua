require("mod.quantum_effect.data.init")

-- Point Quickstart at the QE player sprite so it's visible immediately on
-- boot, with no menu/keyboard navigation needed - useful for this spike's
-- purpose (visual on-device verification) and harmless afterward since it's
-- just a config default, still changeable in Options.
--
-- This has to be a `:edit()` on the option's *default*, not a plain
-- `config.base.x = y` assignment (tried first, didn't work): every real game
-- boot runs game/startup.lua, which unconditionally calls
-- config_store.clear() then config_store.load() before anything reads
-- config - clear() wipes any in-memory value a mod's init.lua set earlier,
-- and load() only restores values from a save file, which doesn't exist yet
-- on a fresh install. So a runtime assignment here is always discarded by
-- the time gameplay starts. Editing the option's `default` field survives
-- that reset, because it's what gets computed fresh after the clear.
--
-- Pattern copied from mod/base/init.lua's `data["base.effect"]:edit(...)`.
data["base.config_option"]:edit("quantum_effect: default quickstart to QE player", function(dat)
   if dat._id == "base.quickstart_chara_id" then
      dat.default = "quantum_effect.player"
   elseif dat._id == "base.quickstart_on_startup" then
      dat.default = true
   end
   return dat
end)
