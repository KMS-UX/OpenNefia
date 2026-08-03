-- Three placeholder augments, one per non-locked slot, to prove installation,
-- removal and the humanity formula work - not balance. Per Option A S1
-- ("Their purpose is not balance... Slots work. Installation works. Removal
-- works.").
--
-- `invasiveness` is the only formula input implants carry today (feeds
-- api/Resources.lua's humanity calculation). Stat modifiers (Milestone 9 in
-- Option A) are deliberately not wired to a real engine stat hook yet - no
-- combat/stat system exists in qe_* mods to hook into. Milestone 9's own
-- fallback applies: "Augment modifiers exist in QE state and are exposed
-- through API... acceptable, as long as it is documented."
data:add_type {
   name = "augment",
   fields = {
      { name = "slot", type = types.data_id("qe_core.augment_slot") },
      { name = "invasiveness", type = types.int }
   }
}

data:add {
   _type = "qe_core.augment",
   _id = "neuro_basic",
   slot = "qe_core.neuro",
   invasiveness = 5
}

data:add {
   _type = "qe_core.augment",
   _id = "limb_servo",
   slot = "qe_core.limbs",
   invasiveness = 8
}

data:add {
   _type = "qe_core.augment",
   _id = "spinal_reflex_booster",
   slot = "qe_core.spinal",
   invasiveness = 6
}
