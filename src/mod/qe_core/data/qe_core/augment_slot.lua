-- Five slots per Amendment B S4.3 ("Implant slots follow GDD S3.1 - neuro,
-- limbs, torso/core, spinal, plus the unique RI-703 - not the four-slot
-- variant in the uploads"). The Game Design Bible itself isn't checked into
-- this repo, so `default_unlocked` below carries forward Option A's stated
-- defaults for the four slots it shares names with (Torso locked, the rest
-- unlocked) rather than inventing new ones.
--
-- RI-703 is a placeholder: nothing in the docs available to this session
-- says what it is narratively or what unlocks it. Modeled here as a locked,
-- 1-capacity slot with no augment yet defined for it. Do not invent its
-- identity - flag it to the director instead.
data:add_type {
   name = "augment_slot",
   fields = {
      { name = "capacity", type = types.uint, default = 1 },
      { name = "default_unlocked", type = types.boolean, default = true }
   }
}

data:add { _type = "qe_core.augment_slot", _id = "neuro", default_unlocked = true }
data:add { _type = "qe_core.augment_slot", _id = "limbs", default_unlocked = true }
data:add { _type = "qe_core.augment_slot", _id = "torso_core", default_unlocked = false }
data:add { _type = "qe_core.augment_slot", _id = "spinal", default_unlocked = true }
data:add { _type = "qe_core.augment_slot", _id = "ri_703", default_unlocked = false }
