AddCSLuaFile()

local function load_baked_map()
    local pvertex_avail = file.Exists("infbake/"..game.GetMap()..".pvtx.txt", "DATA") and
                          file.Exists("infbake/"..game.GetMap()..".pvidx.txt", "DATA")
    local vvertex_avail = file.Exists("infbake/"..game.GetMap()..".vvtx.txt", "DATA") and
                          file.Exists("infbake/"..game.GetMap()..".vvidx.txt", "DATA")
    local normals_avail = file.Exists("infbake/"..game.GetMap()..".nrm.txt", "DATA") and
                          file.Exists("infbake/"..game.GetMap()..".nidx.txt", "DATA")
    local uvs_avail = file.Exists("infbake/"..game.GetMap()..".uvs.txt", "DATA")

    print("[INFMAP2] PhysVertex available: "..(pvertex_avail and "yes" or "no"))
    if pvertex_avail then
        print("[INFMAP2] Found baked VERTEX data!")
        local verts = {}
        ---@diagnostic disable: undefined-field
        local vtxfile = file.Open("infbake/"..game.GetMap()..".pvtx.txt", 'rb', "DATA")
        while not vtxfile:EndOfFile() do
            verts[#verts+1] = Vector(vtxfile:ReadFloat(),
                                     vtxfile:ReadFloat(),
                                     vtxfile:ReadFloat())
        end
        vtxfile:Close()
        ---@diagnostic enable: undefined-field

        ---@diagnostic disable: undefined-field
        local vidxfile = file.Open("infbake/"..game.GetMap()..".pvidx.txt", 'rb', "DATA")
        while not vidxfile:EndOfFile() do
            local megapos = Vector(vidxfile:ReadShort(),
                                   vidxfile:ReadShort(),
                                   vidxfile:ReadShort())
            local chunkmesh = {}
            InfMap2.Cache.ChunkMeshes['v'..tostring(megapos)] = chunkmesh
            for i=1,vidxfile:ReadULong(),1 do
                chunkmesh[#chunkmesh+1] = verts[vidxfile:ReadULong()]
            end
        end
        vidxfile:Close()
        ---@diagnostic enable: undefined-field
    end
    if SERVER then return end
    print("[INFMAP2] VisVertex available: "..(vvertex_avail and "yes" or "no"))
    print("[INFMAP2] Normals available: "..(normals_avail and "yes" or "no"))
    print("[INFMAP2] UVs available: "..(uvs_avail and "yes" or "no"))
    if not SERVER and vvertex_avail and normals_avail and uvs_avail then
        print("[INFMAP2] Found baked VISUAL data!")
        local verts, vidx, normals = {}, {}, {}
        ---@diagnostic disable: undefined-field
        local vtxfile = file.Open("infbake/"..game.GetMap()..".vvtx.txt", 'rb', "DATA")
        while not vtxfile:EndOfFile() do
            verts[#verts+1] = Vector(vtxfile:ReadFloat(),
                                     vtxfile:ReadFloat(),
                                     vtxfile:ReadFloat())
        end
        vtxfile:Close()
        ---@diagnostic enable: undefined-field

        ---@diagnostic disable: undefined-field
        local vidxfile = file.Open("infbake/"..game.GetMap()..".vvidx.txt", 'rb', "DATA")
        while not vidxfile:EndOfFile() do
            local megapos = Vector(vidxfile:ReadShort(),
                                   vidxfile:ReadShort())
            local chunkmesh = {}
            vidx[tostring(megapos)] = chunkmesh
            for i=1,vidxfile:ReadULong(),1 do
                chunkmesh[#chunkmesh+1] = vidxfile:ReadULong()
            end
        end
        vidxfile:Close()
        ---@diagnostic enable: undefined-field

        ---@diagnostic disable: undefined-field
        local nrmfile = file.Open("infbake/"..game.GetMap()..".nrm.txt", 'rb', "DATA")
        while not nrmfile:EndOfFile() do
            normals[#normals+1] = Vector(nrmfile:ReadFloat(),
                                         nrmfile:ReadFloat(),
                                         nrmfile:ReadFloat())
        end
        nrmfile:Close()
        ---@diagnostic enable: undefined-field

        ---@diagnostic disable: undefined-field
        local nidxfile = file.Open("infbake/"..game.GetMap()..".nidx.txt", 'rb', "DATA")
        while not nidxfile:EndOfFile() do
            local megapos = Vector(nidxfile:ReadShort(),
                                   nidxfile:ReadShort())
            local chunkmesh = {}
            InfMap2.Cache.ChunkMeshes['f'..tostring(megapos * InfMap2.Visual.MegachunkSize)] = chunkmesh
            for i=1,nidxfile:ReadULong(),1 do
                chunkmesh[#chunkmesh+1] = {verts[vidx[tostring(megapos)][i]], 0, 0, normals[nidxfile:ReadULong()]}
            end
        end
        nidxfile:Close()
        ---@diagnostic enable: undefined-field
        
        ---@diagnostic disable: undefined-field
        local uvsfile = file.Open("infbake/"..game.GetMap()..".uvs.txt", 'rb', "DATA")
        while not uvsfile:EndOfFile() do
            local megapos = Vector(uvsfile:ReadShort(),
                                   uvsfile:ReadShort())
            local chunkmesh = InfMap2.Cache.ChunkMeshes['f'..tostring(megapos * InfMap2.Visual.MegachunkSize)]
            for i=1,uvsfile:ReadULong(),1 do
                chunkmesh[i][2] = uvsfile:ReadFloat()
                chunkmesh[i][3] = uvsfile:ReadFloat()
            end
        end
        uvsfile:Close()
        ---@diagnostic enable: undefined-field
    end
end

load_baked_map()

if SERVER then return end

local stage, sprogress, stotal, progress, total = "", 0, 3, 0, 1
local coro

local function genneigbors(dst)
    local neighbors = {}
    for x=-dst,dst,1 do
        for y=-dst,dst,1 do
            for z=-dst,dst,1 do
                neighbors[#neighbors+1] = Vector(x, y, z)
            end
        end
    end
    return neighbors
end

local function genneigbors2d(dst)
    local neighbors = {}
    for x=-dst,dst,1 do
        for y=-dst,dst,1 do
            neighbors[#neighbors+1] = Vector(x, y)
        end
    end
    return neighbors
end

local function bake_geometry()
    local dist = 5
    total = (dist * 2 + 1) ^ 3

    local neighbors = genneigbors(dist)

    progress = 0
    local physmeshes = {}
    for _, xyz in ipairs(neighbors) do
        physmeshes[#physmeshes+1] = {xyz, InfMap2.GenerateChunkVertexMesh(xyz)}
        progress = progress + 1
        coroutine.yield()
    end
    
    progress = 0
    local vertices, indicies, chunks = {}, {}, {}
    for _, xyz_chunk in ipairs(physmeshes) do
        local xyz, chunk = xyz_chunk[1], xyz_chunk[2]
        local chunkidx = {}
        chunks[xyz] = chunkidx
        for _, vert in ipairs(chunk) do
            local vertstr = vert.x.." "..vert.y.." "..vert.z
            if not indicies[vertstr] then
                indicies[vertstr] = #vertices + 1
                vertices[#vertices+1] = vert
            end
            chunkidx[#chunkidx+1] = indicies[vertstr]
        end
        progress = progress + 1
        coroutine.yield()
    end

    file.CreateDir("infbake")

    ---@diagnostic disable: undefined-field
    local vtxfile = file.Open("infbake/"..game.GetMap()..".pvtx.txt", 'wb', "DATA")
    for _, vert in ipairs(vertices) do
        vtxfile:WriteFloat(vert[1])
        vtxfile:WriteFloat(vert[2])
        vtxfile:WriteFloat(vert[3])
    end
    vtxfile:Flush()
    vtxfile:Close()
    ---@diagnostic enable: undefined-field

    ---@diagnostic disable: undefined-field
    local vidxfile = file.Open("infbake/"..game.GetMap()..".pvidx.txt", 'wb', "DATA")
    for xyz, chunk in pairs(chunks) do
        vidxfile:WriteShort(xyz[1])
        vidxfile:WriteShort(xyz[2])
        vidxfile:WriteShort(xyz[3])
        vidxfile:WriteULong(#chunk)
        for _, idx in ipairs(chunk) do
            vidxfile:WriteULong(idx)
        end
    end
    vidxfile:Flush()
    vidxfile:Close()
    ---@diagnostic enable: undefined-field
end

local function bake_visual()
    local dist = 5
    total = (dist * 2 + 1) ^ 2
    progress = 0
    local gen = {}

    local neighbors = genneigbors2d(dist)

    for _, xy in ipairs(neighbors) do
        InfMap2.GenerateChunkVisualMesh(xy * InfMap2.Visual.MegachunkSize,
                                        Vector(1, 1) * InfMap2.Visual.MegachunkSize,
                                        function(cmesh)
                                            gen[xy.x.." "..xy.y] = cmesh
                                            progress = progress + 1
                                        end,
                                        function() return true end)
    end
    while true do 
        coroutine.yield()
        if progress >= total then break end
    end

    local verts, vindex = {}, {}
    local normals, nindex = {}, {}

    local chunkidxvtx = {}
    local chunkidxnrm = {}
    local chunkidxu, chunkidxv = {}, {}

    local chunks = {}

    progress = 0
    for _, xy in ipairs(neighbors) do
        local x, y = xy.x, xy.y
        progress = progress + 1

        chunkidxvtx[x.." "..y] = {}
        chunkidxnrm[x.." "..y] = {}
        chunkidxu[x.." "..y] = {}
        chunkidxv[x.." "..y] = {}

        chunks[xy] = {chunkidxvtx[x.." "..y],
                      chunkidxnrm[x.." "..y],
                      chunkidxu[x.." "..y],
                      chunkidxv[x.." "..y]}

        local chunk = gen[x.." "..y]
        for _,point in ipairs(chunk) do
            local strvtx = tostring(point[1])
            local strnrm = tostring(point[4])
            if not vindex[strvtx] then
                vindex[strvtx] = #verts + 1
                verts[#verts+1] = point[1]
            end
            if not nindex[strnrm] then
                nindex[strnrm] = #normals + 1
                normals[#normals+1] = point[4]
            end
            chunkidxvtx[x.." "..y][_] = vindex[strvtx]
            chunkidxnrm[x.." "..y][_] = nindex[strnrm]

            chunkidxu[x.." "..y][_] = point[2]
            chunkidxv[x.." "..y][_] = point[3]
            if _ % 5000 == 0 then coroutine.yield() end
        end

        coroutine.yield()
    end

    ---@diagnostic disable: undefined-field
    local vtxfile = file.Open("infbake/"..game.GetMap()..".vvtx.txt", 'wb', "DATA")
    for _, vtx in ipairs(verts) do
        vtxfile:WriteFloat(vtx[1])
        vtxfile:WriteFloat(vtx[2])
        vtxfile:WriteFloat(vtx[3])
    end
    vtxfile:Flush()
    vtxfile:Close()
    ---@diagnostic enable: undefined-field
    
    ---@diagnostic disable: undefined-field
    local nrmfile = file.Open("infbake/"..game.GetMap()..".nrm.txt", 'wb', "DATA")
    for _, nrm in ipairs(normals) do
        nrmfile:WriteFloat(nrm[1])
        nrmfile:WriteFloat(nrm[2])
        nrmfile:WriteFloat(nrm[3])
    end
    nrmfile:Flush()
    nrmfile:Close()
    ---@diagnostic enable: undefined-field

    ---@diagnostic disable: undefined-field
    local vidxfile = file.Open("infbake/"..game.GetMap()..".vvidx.txt", 'wb', "DATA")
    for xy, chunk in pairs(chunks) do
        vidxfile:WriteShort(xy[1])
        vidxfile:WriteShort(xy[2])
        vidxfile:WriteULong(#chunk[1])
        for _, idx in ipairs(chunk[1]) do
            vidxfile:WriteULong(idx)
        end
    end
    vidxfile:Flush()
    vidxfile:Close()
    ---@diagnostic enable: undefined-field
    
    ---@diagnostic disable: undefined-field
    local nidxfile = file.Open("infbake/"..game.GetMap()..".nidx.txt", 'wb', "DATA")
    for xy, chunk in pairs(chunks) do
        nidxfile:WriteShort(xy[1])
        nidxfile:WriteShort(xy[2])
        nidxfile:WriteULong(#chunk[2])
        for _, idx in ipairs(chunk[2]) do
            nidxfile:WriteULong(idx)
        end
    end
    nidxfile:Flush()
    nidxfile:Close()
    ---@diagnostic enable: undefined-field

    ---@diagnostic disable: undefined-field
    local uvfile = file.Open("infbake/"..game.GetMap()..".uvs.txt", 'wb', "DATA")
    for xy, chunk in pairs(chunks) do
        uvfile:WriteShort(xy[1])
        uvfile:WriteShort(xy[2])
        uvfile:WriteULong(#chunk[3])
        for idx, u in ipairs(chunk[3]) do
            uvfile:WriteFloat(u)
            uvfile:WriteFloat(chunk[4][idx])
        end
    end
    uvfile:Flush()
    uvfile:Close()
    ---@diagnostic enable: undefined-field
end
local function bakefunc()
    sprogress = 0
    stage = "Geometry baking" sprogress = sprogress + 1
    bake_geometry()
    stage = "Visual baking" sprogress = sprogress + 1
    bake_visual()
end

hook.Add("PostDrawHUD", "InfMap2BakingHUD", function()
    if not coro then return end
    if coroutine.status(coro) ~= "suspended" then coro = nil return end
    local ok, err = coroutine.resume(coro)
    if not ok then ErrorNoHalt(err) end
    if stage == "" then return end
    InfMap2.ProgressPopupDraw(sprogress.."/"..stotal..": "..stage, progress, total, 1)
end)

concommand.Add("inf_bakemap", function(ply, cmd, args, argstr)
    if ply and not ply:IsListenServerHost() then return print("Command has to be ran by listen server host.") end
    print("Infmap baking in progress...")
    coro = coroutine.create(bakefunc)
end, function (cmd, argstr, args)
    return {"inf_bakemap"}
end, "Bakes current InfMap")