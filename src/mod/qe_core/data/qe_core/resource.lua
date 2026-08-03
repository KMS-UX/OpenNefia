-- A directly-mutable, persisted QE resource: min/max/default live in data so
-- the director can retune them without touching Lua. Humanity is deliberately
-- NOT one of these - CLAUDE.md is explicit that "humanity is a key, not a
-- meter": it's always computed from contamination + installed augments (see
-- api/Resources.lua), never stored on its own, so it can't drift out of sync
-- with what created it.
--
-- Pattern: data:add_type + data:add, same as
-- src/mod/simple_indicators/data/simple_indicators/indicator.lua.
data:add_type {
   name = "resource",
   fields = {
      { name = "min", type = types.int },
      { name = "max", type = types.int },
      { name = "default", type = types.int }
   }
}

data:add {
   _type = "qe_core.resource",
   _id = "contamination",
   min = 0,
   max = 100,
   default = 0
}
