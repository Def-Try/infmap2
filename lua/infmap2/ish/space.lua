AddCSLuaFile()

function InfMap2.GeneratePlanetVertexMesh(planetinfo, pos)
    assert(InfMap2.Space.HasSpace, "InfMap2 does not use a space generator")
    assert(planetinfo.HeightFunction ~= nil, "planetinfo.HeightFunction is not set up")
    assert(planetinfo.Radius ~= nil, "planetinfo.Radius is not set up")
    assert(planetinfo.SampleSize ~= nil, "planetinfo.SampleSize is not set up")

    if InfMap2.Cache.ChunkMeshes["p"..tostring(pos)] then
        return table.Copy(InfMap2.Cache.ChunkMeshes["p"..tostring(pos)])
    end

    local heightmap = {}
    local radius = planetinfo.Radius
    local radius_squared = radius * radius
    local sample_size = planetinfo.SampleSize

    local x_offset = pos.x
    local y_offset = pos.y

    local samples = (radius / sample_size) * 2

    local height_function = planetinfo.HeightFunction

    local height, rx, ry
    for x = -2, samples+1 do
        height = {}
        heightmap[x] = height
        for y = -2, samples+1 do
            rx, ry = ((x - samples/2) * sample_size + x_offset) * 2, ((y - samples/2) * sample_size + y_offset) * 2
            height[y] = height_function(rx, ry)
        end
    end

    local planet_mesh = {}
    InfMap2.Cache.ChunkMeshes["p"..tostring(pos)] = planet_mesh

    for x = -1, samples do
        for y = -1, samples do
            local v0 = Vector((x - samples/2)     * sample_size, (y - samples/2)     * sample_size, heightmap[x    ][y    ])
            local v1 = Vector((x - samples/2 + 1) * sample_size, (y - samples/2)     * sample_size, heightmap[x + 1][y    ])
            local v2 = Vector((x - samples/2)     * sample_size, (y - samples/2 + 1) * sample_size, heightmap[x    ][y + 1])
            local v3 = Vector((x - samples/2 + 1) * sample_size, (y - samples/2 + 1) * sample_size, heightmap[x + 1][y + 1])
        
            local in_a = v0:LengthSqr() <= radius_squared
            local in_b = v1:LengthSqr() <= radius_squared
            local in_c = v2:LengthSqr() <= radius_squared
            local in_d = v3:LengthSqr() <= radius_squared

            if not (in_a or in_b or in_c or in_d) then
                continue
            end

            if not in_a then
                v0 = v0:GetNormalized() * radius
                v0[3] = height_function((v0[1] + x_offset) * 2, (v0[2] + y_offset) * 2)
            end

            if not in_b then
                v1 = v1:GetNormalized() * radius
                v1[3] = height_function((v1[1] + x_offset) * 2, (v1[2] + y_offset) * 2)
            end

            if not in_c then
                v2 = v2:GetNormalized() * radius
                v2[3] = height_function((v2[1] + x_offset) * 2, (v2[2] + y_offset) * 2)
            end

            if not in_d then
                v3 = v3:GetNormalized() * radius
                v3[3] = height_function((v3[1] + x_offset) * 2, (v3[2] + y_offset) * 2)
            end

            planet_mesh[#planet_mesh + 1] = v0
            planet_mesh[#planet_mesh + 1] = v2
            planet_mesh[#planet_mesh + 1] = v1

            planet_mesh[#planet_mesh + 1] = v2
            planet_mesh[#planet_mesh + 1] = v3
            planet_mesh[#planet_mesh + 1] = v1
        end
    end

    return table.Copy(planet_mesh)
end

function InfMap2.GeneratePlanetVisualMesh(planetinfo, pos)
    --if InfMap2.Cache.ChunkMeshes["pv"..tostring(pos)] then
    --    return table.Copy(InfMap2.Cache.ChunkMeshes["pv"..tostring(pos)])
    --end
    local pvmesh = InfMap2.GeneratePlanetVertexMesh(planetinfo, pos)

    local planet_mesh = {}
    InfMap2.Cache.ChunkMeshes["pv"..tostring(pos)] = planet_mesh

    for i=1,#pvmesh,6 do
        local v0, v1, v2, v3 = pvmesh[i], pvmesh[i+2], pvmesh[i+1], pvmesh[i+4]
        local n1 = -(v0 - v1):Cross(v0 - v2):GetNormalized()
        local n2 = -(v3 - v2):Cross(v3 - v1):GetNormalized()
        planet_mesh[i  ] = {v0, 0,                                   0, n1} -- n0
        planet_mesh[i+1] = {v2, planetinfo.UVScale,                  0, n1} -- n2
        planet_mesh[i+2] = {v1, 0,                  planetinfo.UVScale, n1} -- n1
        planet_mesh[i+3] = {v2, 0,                  planetinfo.UVScale, n2} -- n2
        planet_mesh[i+4] = {v3, planetinfo.UVScale,                  0, n2} -- n3
        planet_mesh[i+5] = {v1, planetinfo.UVScale, planetinfo.UVScale, n2} -- n1
    end

    return table.Copy(planet_mesh)
end