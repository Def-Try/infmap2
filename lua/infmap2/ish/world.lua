AddCSLuaFile()

InfMap2.Cache.ChunkMeshes = InfMap2.Cache.ChunkMeshes or {}
InfMap2.Cache.HeightMap = InfMap2.Cache.HeightMap or {}

---Generates vertex (physics) mesh of a single chunk at megapos.
---Requires UsesGenerator, HeightFunction, ChunkSize and SampleSize to be set up.
---@param megapos Vector Chunk megapos
---@return table<Vector> mesh Chunk vertex mesh
function InfMap2.GenerateChunkVertexMesh(megapos)
    assert(InfMap2.World.HasTerrain, "InfMap2 does not use a generator")
    assert(InfMap2.World.Terrain.HeightFunction ~= nil, "InfMap2.World.Terrain.HeightFunction is not set up")
    assert(InfMap2.ChunkSize ~= nil, "InfMap2.ChunkSize is not set up")
    assert(InfMap2.World.Terrain.SampleSize ~= nil, "InfMap2.World.Terrain.SampleSize is not set up")

    --if InfMap2.Cache.ChunkMeshes["v"..tostring(megapos)] then
    --    return table.Copy(InfMap2.Cache.ChunkMeshes["v"..tostring(megapos)])
    --end

    local heightmap = {}
    local chunk_size = InfMap2.ChunkSize
    local half_chunk_size = chunk_size / 2
    local sample_size = InfMap2.World.Terrain.SampleSize

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
            if not InfMap2.Cache.HeightMap[rx.."x"..ry] then
                InfMap2.Cache.HeightMap[rx.."x"..ry] = height_function(rx, ry)
            end
            height[y] = InfMap2.Cache.HeightMap[rx.."x"..ry] - z_offset
        end
    end

    local chunk_mesh = {}
    InfMap2.Cache.ChunkMeshes["v"..tostring(megapos)] = chunk_mesh

    for x = -1, samples do
        for y = -1, samples do
            local v0 = Vector((x - samples/2)     * sample_size, (y - samples/2)     * sample_size, heightmap[x    ][y    ])
            local v1 = Vector((x - samples/2 + 1) * sample_size, (y - samples/2)     * sample_size, heightmap[x + 1][y    ])
            local v2 = Vector((x - samples/2)     * sample_size, (y - samples/2 + 1) * sample_size, heightmap[x    ][y + 1])
            local v3 = Vector((x - samples/2 + 1) * sample_size, (y - samples/2 + 1) * sample_size, heightmap[x + 1][y + 1])
            if (v0.z < -half_chunk_size or v0.z > half_chunk_size) and
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

    return table.Copy(chunk_mesh)
end
