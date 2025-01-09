AddCSLuaFile()

InfMap2.Cache.ChunkMeshes = InfMap2.Cache.ChunkMeshes or {}
InfMap2.Cache.HeightMap = InfMap2.Cache.HeightMap or {}

local coroutines = {}
timer.Create("InfMap2ChunkGeneratorThink", 0, 0, function()
    for i=0,50 do
        local coro = table.Random(coroutines)
        if not coro then return end
        coroutine.resume(coro)
        if coroutine.status(coro) ~= "suspended" then coroutines[table.KeyFromValue(coroutines, coro)] = nil end
    end
end)

local genvismeshone = function(megapos)
    if InfMap2.Cache.ChunkMeshes["m"..tostring(megapos)] then
        return table.Copy(InfMap2.Cache.ChunkMeshes["m"..tostring(megapos)])
    end

    assert(megapos.z == 0, "genvismeshone: megapos.z is not 0")

    local heightmap = {}
    local normals = {}
    local chunk_size = InfMap2.ChunkSize
    local sample_size = InfMap2.SampleSize
    local uvs = InfMap2.UVScale

    local x_offset = megapos.x * InfMap2.ChunkSize
    local y_offset = megapos.y * InfMap2.ChunkSize

    local samples = chunk_size / sample_size

    local height_function = InfMap2.HeightFunction

    local height, rx, ry
    for x = -1, samples do
        height = {}
        heightmap[x] = height
        for y = -1, samples do
            rx, ry = ((x - samples/2) * sample_size + x_offset) * 2, ((y - samples/2) * sample_size + y_offset) * 2
            if not InfMap2.Cache.HeightMap[rx.."x"..ry] then
                InfMap2.Cache.HeightMap[rx.."x"..ry] = height_function(rx, ry)
            end
            height[y] = InfMap2.Cache.HeightMap[rx.."x"..ry]
        end
    end

    local chunk_mesh = {}
    InfMap2.Cache.ChunkMeshes["m"..tostring(megapos)] = chunk_mesh

    for x = 0, samples-1 do
        for y = 0, samples-1 do
            local v0 = Vector((x - samples/2)     * sample_size, (y - samples/2)     * sample_size, heightmap[x    ][y    ])
            local v1 = Vector((x - samples/2 + 1) * sample_size, (y - samples/2)     * sample_size, heightmap[x + 1][y    ])
            local v2 = Vector((x - samples/2)     * sample_size, (y - samples/2 + 1) * sample_size, heightmap[x    ][y + 1])
            local v3 = Vector((x - samples/2 + 1) * sample_size, (y - samples/2 + 1) * sample_size, heightmap[x + 1][y + 1])

            local n1 = -(v0 - v1):Cross(v0 - v2):GetNormalized()
            local n2 = -(v3 - v2):Cross(v3 - v1):GetNormalized()
            chunk_mesh[#chunk_mesh + 1] = {v0,   0,   0, n1}
            chunk_mesh[#chunk_mesh + 1] = {v2, uvs,   0, n1}
            chunk_mesh[#chunk_mesh + 1] = {v1,   0, uvs, n1}

            chunk_mesh[#chunk_mesh + 1] = {v2,   0, uvs, n2}
            chunk_mesh[#chunk_mesh + 1] = {v3, uvs,   0, n2}
            chunk_mesh[#chunk_mesh + 1] = {v1, uvs, uvs, n2}

            if not InfMap2.PerFaceNormals then
                local norms0 = normals[tostring(v0)] or {}
                local norms1 = normals[tostring(v1)] or {}
                local norms2 = normals[tostring(v2)] or {}
                local norms3 = normals[tostring(v3)] or {}
                normals[tostring(v0)] = norms0
                normals[tostring(v1)] = norms1
                normals[tostring(v2)] = norms2
                normals[tostring(v3)] = norms3
                
                norms0[#norms0 + 1] = n1
                norms2[#norms1 + 1] = n1 norms2[#norms1 + 1] = n2
                norms2[#norms2 + 1] = n2 norms2[#norms2 + 1] = n1
                norms3[#norms3 + 1] = n2
            end
        end
    end

    if not InfMap2.PerFaceNormals then
        local donenormals = {}
        for _,vert in ipairs(chunk_mesh) do
            if not donenormals[vert[1]] then
                donenormals[tostring(vert[1])] = Vector()
                for _,norm in ipairs(normals[tostring(vert[1])]) do
                    donenormals[tostring(vert[1])] = donenormals[tostring(vert[1])] + norm
                end
                donenormals[tostring(vert[1])] = donenormals[tostring(vert[1])] / #normals[tostring(vert[1])]
            end
            vert[4] = donenormals[tostring(vert[1])]
        end
    end

    return table.Copy(chunk_mesh)
end

local genvismeshcoro = function()
    local megapos, megasize, callback, docontinue = coroutine.yield()

    local megamegaoffset = megapos * InfMap2.ChunkSize

    local vismesh = {}

    for x = -(megasize.x / 2), (megasize.x / 2) do
        for y = -(megasize.y / 2), (megasize.y / 2) do
            local megaoffset = Vector(x, y, 0)
            local chunkmesh = genvismeshone(megapos + megaoffset)
            megaoffset = megaoffset * InfMap2.ChunkSize
            for i=1,#chunkmesh do
                chunkmesh[i][1] = chunkmesh[i][1] + megaoffset + megamegaoffset
            end
            table.Add(vismesh, chunkmesh)
            --if InfMap2.Debug then print("[INFMAP] Chunk "..x.." "..y.." generated") end
            coroutine.yield()
            if docontinue and not docontinue() then return end
        end
    end
    
    callback(vismesh)
end

---Asynchronously generates visual mesh of a single megachunk of certain size at megapos.
---Requires UsesGenerator, HeightFunction, ChunkSize and SampleSize to be set up.
---@param megapos Vector Megachunk origin chunk megapos
---@param megasize Vector Megachunk size
---@param callback function Callback when mesh has been generated. The argument is megachunk mesh data (table<pos, u, v, norm>).
---@param docontinue? function Function to check if mesh should continue generating
function InfMap2.GenerateChunkVisualMesh(megapos, megasize, callback, docontinue)
    assert(InfMap2.UsesGenerator, "InfMap2 does not use a generator")
    assert(InfMap2.HeightFunction ~= nil, "InfMap2.HeightFunction is not set up")
    assert(InfMap2.ChunkSize ~= nil, "InfMap2.ChunkSize is not set up")
    assert(InfMap2.SampleSize ~= nil, "InfMap2.SampleSize is not set up")

    local coro = coroutine.create(genvismeshcoro)
    coroutine.resume(coro) -- start
    coroutine.resume(coro, megapos, megasize, callback, docontinue) -- first yield, requested params
    coroutines[#coroutines+1] = coro
end

---Generates vertex (physics) mesh of a single chunk at megapos.
---Requires UsesGenerator, HeightFunction, ChunkSize and SampleSize to be set up.
---@param megapos Vector Chunk megapos
---@return table<Vector> mesh Chunk vertex mesh
function InfMap2.GenerateChunkVertexMesh(megapos)
    assert(InfMap2.UsesGenerator, "InfMap2 does not use a generator")
    assert(InfMap2.HeightFunction ~= nil, "InfMap2.HeightFunction is not set up")
    assert(InfMap2.ChunkSize ~= nil, "InfMap2.ChunkSize is not set up")
    assert(InfMap2.SampleSize ~= nil, "InfMap2.SampleSize is not set up")

    --if InfMap2.Cache.ChunkMeshes["v"..tostring(megapos)] then
    --    return table.Copy(InfMap2.Cache.ChunkMeshes["v"..tostring(megapos)])
    --end

    local heightmap = {}
    local chunk_size = InfMap2.ChunkSize
    local half_chunk_size = chunk_size / 2
    local sample_size = InfMap2.SampleSize

    local x_offset = megapos.x * chunk_size
    local y_offset = megapos.y * chunk_size
    local z_offset = megapos.z * chunk_size

    local samples = chunk_size / sample_size

    local height_function = InfMap2.HeightFunction

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
