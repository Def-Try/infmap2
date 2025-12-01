AddCSLuaFile()

InfMap2.Cache.TerrainHeightCache = setmetatable({}, {__mode = "kv"})
InfMap2.Cache.OriginChunkCache = nil

function InfMap2.GetTerrainSample(x, y)
    local full_chunk_size = InfMap2.ChunkSize
    local samples = InfMap2.World.Terrain.Samples[1]
    local sample_size = full_chunk_size / samples
    local height_function = InfMap2.World.Terrain.HeightFunction

    local sample_x = math.floor(x / sample_size) * sample_size
    local sample_y = math.floor(y / sample_size) * sample_size

    local v0, v1, v2, v3 = {sample_x, sample_y}, {sample_x + sample_size, sample_y},
                           {sample_x, sample_y + sample_size}, {sample_x + sample_size, sample_y + sample_size}
    v0[3] = height_function(v0[1] * 2, v0[2] * 2)
    v1[3] = height_function(v1[1] * 2, v1[2] * 2)
    v2[3] = height_function(v2[1] * 2, v2[2] * 2)
    v3[3] = height_function(v3[1] * 2, v3[2] * 2)
    return v0, v1, v2, v3
end

---Gets proper terrain height (according to SampleSize) at a position
---@param x number
---@param y number
---@return number
function InfMap2.GetTerrainHeightAt(x, y)
    if not InfMap2.World.HasTerrain then error("InfMap2 doesn't have terrain") end
    local full_chunk_size = InfMap2.ChunkSize
    local samples = InfMap2.World.Terrain.Samples[1]
    local sample_size = full_chunk_size / samples

    local sample_x = math.floor(x / sample_size) * sample_size
    local sample_y = math.floor(y / sample_size) * sample_size

    local v0, v1, v2, v3 = InfMap2.GetTerrainSample(x, y)

    local local_x, local_y = (x - sample_x) / sample_size, (y - sample_y) / sample_size
    local tri = (local_x + local_y) > 1 and true or false
    local height 

    if tri then
        -- we are in triangle out of v3, v2, v1
        height = (1 - local_y) * v1[3] + (1 - local_x) * v2[3] + (local_x + local_y - 1) * v3[3]
    else
        -- we are in triangle out of v0, v1, v2
        height = (1 - local_x - local_y) * v0[3] + local_x * v1[3] + local_y * v2[3]
    end
    
    if InfMap2.Debug and CLIENT then
        local vv0, vv1, vv2, vv3 = Vector(unpack(v0)), Vector(unpack(v1)), Vector(unpack(v2)), Vector(unpack(v3))
        render.SetMaterial(Material("models/wireframe"))
        render.DrawQuad(vv1, vv0, vv2, vv3)
        render.DrawWireframeSphere(vv0, 10, 8, 8, Color(255, 0, 0), false)
        render.DrawWireframeSphere(vv1, 10, 8, 8, Color(0, 255, 0), false)
        render.DrawWireframeSphere(vv2, 10, 8, 8, Color(0, 0, 255), false)
        render.DrawWireframeSphere(vv3, 10, 8, 8, Color(0, 0, 0), false)
        local vh = Vector(local_x * sample_size + sample_x, local_y * sample_size + sample_y, height)
        render.DrawWireframeSphere(vh, 15, 8, 8, tri and Color(0, 255, 0) or Color(0, 0, 255), false)
    end

    return height
end

function InfMap2.GenerateChunkVertexMesh(megapos, lodlevel, limit_height)
    assert(InfMap2.World.HasTerrain, "InfMap2 does not use a generator")
    assert(InfMap2.World.Terrain.HeightFunction ~= nil, "InfMap2.World.Terrain.HeightFunction is not set up")
    assert(InfMap2.ChunkSize ~= nil, "InfMap2.ChunkSize is not set up")
    assert(InfMap2.World.Terrain.Samples ~= nil, "InfMap2.World.Terrain.Samples is not set up")

    if megapos.x == 0 and megapos.y == 0 and megapos.z == 0 and InfMap2.Cache.OriginChunkMesh ~= nil then
        return table.Copy(InfMap2.Cache.OriginChunkMesh)
    end

    local heightmap = {}
    local chunk_size = InfMap2.ChunkSize
    local half_chunk_size = chunk_size / 2
    local sample_size = chunk_size / InfMap2.World.Terrain.LODLevels[math.max(1, math.min(lodlevel, #InfMap2.World.Terrain.LODLevels))]

    local x_offset = megapos.x * chunk_size
    local y_offset = megapos.y * chunk_size
    local z_offset = megapos.z * chunk_size

    local samples = chunk_size / sample_size

    local height_function = InfMap2.World.Terrain.HeightFunction

    local height, rx, ry
    for x = -2, samples+1 do
        height = {}
        heightmap[x] = height
        for y = -2, samples+1 do
            rx, ry = ((x - samples/2) * sample_size + x_offset) * 2, ((y - samples/2) * sample_size + y_offset) * 2
            height[y] = height_function(rx, ry) - z_offset
        end
    end

    local chunk_mesh = {}
    --InfMap2.Cache.ChunkMeshes["v"..tostring(megapos)] = chunk_mesh

    for x = -1, samples do
        for y = -1, samples do
            local v0 = Vector((x - samples/2)     * sample_size, (y - samples/2)     * sample_size, heightmap[x    ][y    ])
            local v1 = Vector((x - samples/2 + 1) * sample_size, (y - samples/2)     * sample_size, heightmap[x + 1][y    ])
            local v2 = Vector((x - samples/2)     * sample_size, (y - samples/2 + 1) * sample_size, heightmap[x    ][y + 1])
            local v3 = Vector((x - samples/2 + 1) * sample_size, (y - samples/2 + 1) * sample_size, heightmap[x + 1][y + 1])
            if limit_height and
               (v0.z < -half_chunk_size or v0.z > half_chunk_size) and
               (v1.z < -half_chunk_size or v1.z > half_chunk_size) and
               (v2.z < -half_chunk_size or v2.z > half_chunk_size) and
               (v3.z < -half_chunk_size or v0.z > half_chunk_size) then continue end

            chunk_mesh[#chunk_mesh + 1] = v0
            chunk_mesh[#chunk_mesh + 1] = v2
            chunk_mesh[#chunk_mesh + 1] = v1

            chunk_mesh[#chunk_mesh + 1] = v2
            chunk_mesh[#chunk_mesh + 1] = v3
            chunk_mesh[#chunk_mesh + 1] = v1
        end
    end

    if megapos.x == 0 and megapos.y == 0 and megapos.z == 0 and InfMap2.Cache.OriginChunkMesh == nil then
        InfMap2.Cache.OriginChunkMesh = chunk_mesh
    end

    return table.Copy(chunk_mesh)
end