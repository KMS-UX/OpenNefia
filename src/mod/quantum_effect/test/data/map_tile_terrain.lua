local Assert = require("api.test.Assert")
local InstancedMap = require("api.InstancedMap")

function test_map_tile_terrain__entries_exist_with_real_image()
   local ids = {
      "quantum_effect.terrain_cracked_ground",
      "quantum_effect.terrain_dirt",
      "quantum_effect.terrain_cracked_stone",
   }

   for _, id in ipairs(ids) do
      local tile = data["base.map_tile"]:ensure(id)
      Assert.eq("mod/quantum_effect/graphic/tiles/terrain_48.png", tile.image.source)
      Assert.eq(48, tile.image.width)
      Assert.eq(48, tile.image.height)
      Assert.is_falsy(tile.is_solid)
   end
end

function test_map_tile_terrain__usable_as_a_real_map_floor()
   -- Same shape as src/test/location.lua's map:clear("elona.cobble") - proves
   -- these aren't just data entries, but actually load and paint a real map.
   local map = InstancedMap:new(5, 5)
   map:clear("quantum_effect.terrain_dirt")

   Assert.eq("quantum_effect.terrain_dirt", map:tile(2, 2)._id)
end
