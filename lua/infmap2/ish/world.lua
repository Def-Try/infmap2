AddCSLuaFile()

InfMap2.Cache.TerrainHeightCache = {}
InfMap2.Cache.OriginChunkCache = nil

---Gets proper terrain height (according to SampleSize) at a position
---@param x number
---@param y number
---@return number
function InfMap2.GetTerrainHeightAt(x, y)
    if InfMap2.Cache.TerrainHeightCache[x.." "..y] then 
        return InfMap2.Cache.TerrainHeightCache[x.." "..y]
    end

    local localpos, megapos = InfMap2.LocalizePosition(Vector(x, y, 0))

    local full_chunk_size = InfMap2.ChunkSize
    local half_chunk_size = full_chunk_size / 2  -- Use full_chunk_size / 2 here
    local sample_size = full_chunk_size / InfMap2.World.Terrain.Samples[1]
    local chunk_resolution = (full_chunk_size / sample_size) -- This is the number of samples per full chunk side
    local half_chunk_resolution = half_chunk_size / sample_size
    local height_function = InfMap2.World.Terrain.HeightFunction

    -- Convert world coordinates to chunk coordinates
    local chunkX = megapos.x
    local chunkY = megapos.y

    -- Calculate local coordinates within the chunk (-1 to 1)
    local localX = localpos.x / sample_size
    local localY = localpos.y / sample_size

    local cellX = math.Round(localX * (chunk_resolution - 1) / 2) * 2
    local cellY = math.Round(localY * (chunk_resolution - 1) / 2) * 2

    local center = Vector(cellX, cellY, 0) * (sample_size / 2) +
    Vector(chunkX, chunkY, 0) * full_chunk_size
    local v0 = center + Vector( 1, -1, 0) * sample_size / 2
    v0.z = height_function(v0.x * 2, v0.y * 2)
    local v1 = center + Vector(-1,  1, 0) * sample_size / 2
    v1.z = height_function(v1.x * 2, v1.y * 2)
    local v2 = center + Vector( 1,  1, 0) * sample_size / 2
    v2.z = height_function(v2.x * 2, v2.y * 2)
    local v3 = center + Vector(-1, -1, 0) * sample_size / 2
    v3.z = height_function(v3.x * 2, v3.y * 2)

    local cellLocalX = localX * (chunk_resolution - 1) - cellX
    local cellLocalY = localY * (chunk_resolution - 1) - cellY

    local height
    if cellLocalX + cellLocalY < 0 then
        height = v3.z + (v0.z - v3.z) * ((cellLocalX + 1) / 2) + (v1.z - v3.z) * ((cellLocalY + 1) / 2)
    else
        height = v2.z + (v1.z - v2.z) * (1 - ((cellLocalX + 1) / 2)) + (v0.z - v2.z) * (1 - ((cellLocalY + 1) / 2))
    end

    InfMap2.Cache.TerrainHeightCache[x.." "..y] = height
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