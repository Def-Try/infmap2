AddCSLuaFile()

require("thorium")
if not thorium then
    print("[INFMAP2] Thorium not installed. Map baking and bake loading will not work!")
    return
end

local function load_baked_map()
    print("[INFMAP2] todo: implement")
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

    local phys_buf = thorium.gbuffer.New()

    phys_buf:WriteUInt(#vertices)
    for _,vert in ipairs(vertices) do
        phys_buf:WriteFloat(vert.x)
        phys_buf:WriteFloat(vert.y)
        phys_buf:WriteFloat(vert.z)
    end

    phys_buf:WriteUInt(#table.GetKeys(chunks))
    for xyz,chunk in pairs(chunks) do
        phys_buf:WriteShort(xyz.x)
        phys_buf:WriteShort(xyz.y)
        phys_buf:WriteShort(xyz.z)
        phys_buf:WriteUInt(#chunk)
        for _,idx in ipairs(chunk) do
            phys_buf:WriteUShort(idx)
        end
    end

    file.CreateDir("infbake")
    phys_buf:WriteToFile("infbake/"..game.GetMap()..".phys.dat")
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
                                            gen[#gen+1] = {xy, cmesh}
                                            progress = progress + 1
                                        end,
                                        function() return true end)
    end
    while true do 
        coroutine.yield()
        if progress >= total then break end
    end

    local vertices, vertidx, uvs, uvidx, normals, normidx, chunks = {}, {}, {}, {}, {}, {}, {}

    progress = 0
    for _, xy_megachunk in ipairs(gen) do
        local xy, megachunk = xy_megachunk[1], xy_megachunk[2]
        local chunk_idx = {}
        chunks[xy] = chunk_idx

        for _,dt in ipairs(megachunk) do
            local vertstr = dt[1].x.." "..dt[1].y.." "..dt[1].z
            local normstr = dt[4].x.." "..dt[4].y.." "..dt[4].z
            if not vertidx[vertstr] then
                vertidx[vertstr] = #vertices + 1
                vertices[#vertices+1] = dt[1]
            end
            if not uvidx[dt[2]] then uvidx[dt[2]] = #uvs + 1 uvs[#uvs+1] = dt[2] end
            if not uvidx[dt[3]] then uvidx[dt[3]] = #uvs + 1 uvs[#uvs+1] = dt[3] end
            if not normidx[normstr] then
                normidx[normstr] = #normals + 1
                normals[#normals+1] = dt[4]
            end

            chunk_idx[#chunk_idx+1] = {vertidx[vertstr],
                                       uvidx[dt[2]], uvidx[dt[3]],
                                       normidx[normstr]}
            if _ % 5000 == 0 then coroutine.yield() end
        end
        progress = progress + 1
        coroutine.yield()
    end

    local vis_buf = thorium.gbuffer.New()

    vis_buf:WriteUInt(#vertices)
    for _,vert in ipairs(vertices) do
        vis_buf:WriteFloat(vert.x)
        vis_buf:WriteFloat(vert.y)
        vis_buf:WriteFloat(vert.z)
    end
    vis_buf:WriteUInt(#normals)
    for _,norm in ipairs(normals) do
        vis_buf:WriteFloat(norm.x)
        vis_buf:WriteFloat(norm.y)
        vis_buf:WriteFloat(norm.z)
    end
    vis_buf:WriteUInt(#uvs)
    for _,u_or_v in ipairs(uvs) do
        vis_buf:WriteFloat(u_or_v)
    end

    vis_buf:WriteUInt(#table.GetKeys(chunks))
    for xy,chunk in pairs(chunks) do
        vis_buf:WriteShort(xy.x)
        vis_buf:WriteShort(xy.y)
        vis_buf:WriteUInt(#chunk)
        for _,idx in ipairs(chunk) do
            vis_buf:WriteUInt(idx[1])
            vis_buf:WriteUShort(idx[2])
            vis_buf:WriteUShort(idx[3])
            vis_buf:WriteUInt(idx[4])
        end
    end

    file.CreateDir("infbake")
    vis_buf:WriteToFile("infbake/"..game.GetMap()..".vis.dat")
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
    if not ok then error(err.."\n\n"..debug.traceback(coro)) end
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