InfMap2.ChunkMeshes = InfMap2.ChunkMeshes or {Index = {}, Draw = {}}
InfMap2.ViewMatrix = InfMap2.ViewMatrix or Matrix()
InfMap2.GeneratedChunks = InfMap2.GeneratedChunks or {}

local coroutines = {}

local samples_need = 1
local samples_done = 1

hook.Add("PostDrawHUD", "InfMap2GeneratorThink", function()
    if false and #coroutines == 0 then
        samples_need = 1
        samples_done = 1
        return
    end
    for i=0,InfMap2.World.GenPerTick do
        local coro = table.Random(coroutines)
        if not coro then continue end
        if coroutine.status(coro) ~= "suspended" then coroutines[table.KeyFromValue(coroutines, coro)] = nil continue end
        local ok, err = coroutine.resume(coro)
        if not ok then ErrorNoHalt(err) end
    end
    if #coroutines > 0 then
        InfMap2.ProgressPopupDraw(#coroutines.." megachunk"..(#coroutines > 1 and "s" or "").." generating", samples_done, samples_need)
    end
end)

local genvismeshone = function(megapos)
    assert(megapos.z == 0, "genvismeshone: megapos.z is not 0")

    if InfMap2.Cache.ChunkMeshes["m"..tostring(megapos)] then
        return table.Copy(InfMap2.Cache.ChunkMeshes["m"..tostring(megapos)])
    end

    local heightmap = {}
    local normals = {}
    local chunk_size = InfMap2.ChunkSize
    local sample_size = InfMap2.World.Terrain.SampleSize
    local uvs = InfMap2.Visual.Terrain.UVScale

    local x_offset = megapos.x * InfMap2.ChunkSize
    local y_offset = megapos.y * InfMap2.ChunkSize

    local samples = chunk_size / sample_size

    local height_function = InfMap2.World.Terrain.HeightFunction

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
        samples_done = samples_done + samples+2
        coroutine.yield()
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

            if not InfMap2.Visual.Terrain.PerFaceNormals then
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
        samples_done = samples_done + samples
        coroutine.yield()
    end

    if not InfMap2.Visual.Terrain.PerFaceNormals then
        samples_need = samples_need + #chunk_mesh
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
            samples_done = samples_done + 1
            if _ % 100 == 0 then coroutine.yield() end
        end
    end

    return table.Copy(chunk_mesh)
end

local genvismeshcoro = function()
    local megapos, megasize, callback, docontinue = coroutine.yield()

    if InfMap2.Cache.ChunkMeshes["f"..tostring(megapos)] then
        return callback(table.Copy(InfMap2.Cache.ChunkMeshes["f"..tostring(megapos)]))
    end

    local samples = InfMap2.ChunkSize / InfMap2.World.Terrain.SampleSize
    for x = -(megasize.x / 2), (megasize.x / 2)-1 do
        for y = -(megasize.y / 2), (megasize.y / 2)-1 do
            samples_need = samples_need + ((samples+2) * (samples+2))
            samples_need = samples_need + (samples * samples)
        end
    end

    local megamegaoffset = megapos * InfMap2.ChunkSize

    local vismesh = {}

    for x = -(megasize.x / 2), (megasize.x / 2)-1 do
        for y = -(megasize.y / 2), (megasize.y / 2)-1 do
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
    
    InfMap2.Cache.ChunkMeshes["f"..tostring(megapos)] = vismesh

    callback(vismesh)
end

---Asynchronously generates visual mesh of a single megachunk of certain size at megapos.
---Requires UsesGenerator, HeightFunction, ChunkSize and SampleSize to be set up.
---@param megapos Vector Megachunk origin chunk megapos
---@param megasize Vector Megachunk size
---@param callback function Callback when mesh has been generated. The argument is megachunk mesh data (table<pos, u, v, norm>).
---@param docontinue? function Function to check if mesh should continue generating
function InfMap2.GenerateChunkVisualMesh(megapos, megasize, callback, docontinue)
    assert(InfMap2.World.HasTerrain, "InfMap2 does not use a generator")
    assert(InfMap2.World.Terrain.HeightFunction ~= nil, "InfMap2.World.Terrain.HeightFunction is not set up")
    assert(InfMap2.ChunkSize ~= nil, "InfMap2.ChunkSize is not set up")
    assert(InfMap2.World.Terrain.SampleSize ~= nil, "InfMap2.World.Terrain.SampleSize is not set up")

    local coro = coroutine.create(genvismeshcoro)
    coroutine.resume(coro)
    local ok, err = coroutine.resume(coro, megapos, megasize, callback, docontinue) -- first yield, requested params
    if not ok then ErrorNoHalt(err) end
    coroutines[#coroutines+1] = coro
end


---Build table of IMesh objects out of mesh table.
---@param mesh_ table
---@return table
function InfMap2.BuildMeshObjects(mesh_)
    local meshes = {Mesh()}

    local light = {}
    light.sun = util.GetSunInfo() or {direction=-vector_up, obstruction=0}
    local skypaint = ents.FindByClass("edit_sky")[1] or ents.FindByClass("env_skypaint")[1]
    local sunpaint = ents.FindByClass("edit_sun")[1] or ents.FindByClass("env_sun")[1]
    if IsValid(sunpaint) then
        light.sun.color = sunpaint:GetSunColor()
    else
        light.sun.color = Vector(1, 1, 1)
    end
    if IsValid(skypaint) then
        light.ambient = skypaint:GetTopColor() * 0.1 + skypaint:GetDuskColor() * 0.1
    else
        light.ambient = render.GetAmbientLightColor()
    end

    local count = #mesh_

    mesh.Begin(meshes[#meshes], MATERIAL_TRIANGLES, math.min(10922, count / 3))
    for _,vtx in ipairs(mesh_) do
        mesh.Position(vtx[1])
        mesh.TexCoord(0, vtx[2], vtx[3])
        
        mesh.Normal(-vtx[4] --[[@as Vector]])
        mesh.UserData(1, 1, 1, 1)
        if InfMap2.Visual.Terrain.DoLighting then
            local sunlight = math.max(0, vtx[4]:Dot(-light.sun.direction)) * (1-light.sun.obstruction)
            mesh.Color(
                math.min(1, light.ambient[1] + light.sun.color[1] * sunlight) * 255,
                math.min(1, light.ambient[2] + light.sun.color[2] * sunlight) * 255,
                math.min(1, light.ambient[3] + light.sun.color[3] * sunlight) * 255,
                255
            )
        else
            mesh.Color(255, 255, 255, 255)
        end
        mesh.AdvanceVertex()
        count = count - 1
        if _ % 32766 == 0 then
            mesh.End()
            meshes[#meshes + 1] = Mesh()
            mesh.Begin(meshes[#meshes], MATERIAL_TRIANGLES, math.min(10922, count / 3))
        end
    end
    mesh.End()

    return meshes
end

---Generates a megachunk.
---@param megapos Vector megachunk megapos (megamegapos)
function InfMap2.CreateWorldMegaChunk(megapos)
    if InfMap2.Debug then print("[INFMAP] World megachunk creation requested at "..tostring(megapos)) end
    InfMap2.GenerateChunkVisualMesh(megapos * InfMap2.Visual.MegachunkSize, Vector(InfMap2.Visual.MegachunkSize, InfMap2.Visual.MegachunkSize), function(vismesh)
        local meshes = InfMap2.BuildMeshObjects(vismesh)
        local idx = table.insert(InfMap2.ChunkMeshes.Draw, meshes)
        InfMap2.ChunkMeshes.Index[tostring(megapos)] = idx
        InfMap2.ChunkMeshes.Index[idx] = megapos
    end, function() return InfMap2.GeneratedChunks[tostring(megapos)] or false end)
    InfMap2.GeneratedChunks[tostring(megapos)] = true
end

---Removes megachunk
---@param megapos Vector megachunk megapos (megamegapos)
function InfMap2.RemoveWorldMegaChunk(megapos)
    if InfMap2.Debug then print("[INFMAP] World megachunk removal requested at "..tostring(megapos)) end
    local idx = InfMap2.ChunkMeshes.Index[tostring(megapos)]
    if not idx then return end
    local meshes = InfMap2.ChunkMeshes.Draw[idx]
    for i=1,#meshes do
        meshes[i]:Destroy()
    end
    InfMap2.ChunkMeshes.Draw[idx] = nil
    InfMap2.ChunkMeshes.Index[idx] = nil
    InfMap2.ChunkMeshes.Index[tostring(megapos)] = nil
    InfMap2.GeneratedChunks[tostring(megapos)] = nil
end

local predicted_teleport = false
hook.Add("Tick", "InfMap2LPWrappingPrediction", function()
    predicted_teleport = false
end)
hook.Add("PostRender", "InfMap2LPWrappingPrediction", function()
    do return end
    if predicted_teleport then return end
    local lp = LocalPlayer()
    local rawpos = lp:INF_GetPos()
    local real, mega = InfMap2.LocalizePosition(rawpos)
    if mega ~= vector_origin then
        lp:INF_SetPos(real)
        InfMap2.EntityUpdateMegapos(lp, lp:GetMegaPos() + mega)
        predicted_teleport = true
    end
end)

-- This is bad, but I haven't found any other *RELIABLE* way of localizing calcview.
-- (Honestly, like, hooks are so bad.)
-- This works by moving every CalcView hook added by any other addon to INF_CalcView hook
--  that we have control over. When trying to CalcView, we'll call INF_CalcView hooks and
--  localize data from there, just so that thirdperson / vehicle / etc mods don't explode.
-- Also, we detour hook.Add *just* in case if any addon for some ungodly reason wants to
--  add CalcView hooks after the game has started.
hook.Add("Think", "InfMap2FixF***ingCalcView", function()
    --do return end
    local override = false
    local calcviewing = false
    local calcvmviewing = false
    local relativeorigin = Vector()
    hook.Remove("Think", "InfMap2FixF***ingCalcView")
    override = true
    for k,v in pairs(hook.GetTable()["CalcView"] or {}) do
        if k == "InfMap2CalcView" then continue end
        hook.Remove("CalcView", k)
        hook.Add("INF_CalcView", k, v)
    end
    for k,v in pairs(hook.GetTable()["CalcViewModelView"] or {}) do
        if k == "InfMap2CalcViewModelView" then continue end
        hook.Remove("CalcViewModelView", k)
        hook.Add("INF_CalcViewModelView", k, v)
    end
    override = false
    hook.Add("Tick", "InfMap2UpdateCalcViewRelativeOrigin", function()
        relativeorigin = LocalPlayer():EyePos()
    end)
    hook.Add("CalcView", "InfMap2CalcView", function(ply, pos, angles, fov, znear, zfar)
        --do return end
        calcviewing = true
        local view = hook.Run("INF_CalcView", ply, pos + ply:GetMegaPos() * InfMap2.ChunkSize, angles, fov, znear, zfar)
        calcviewing = false

        local view_fallback = {
            ["origin"] = pos + ply:GetMegaPos() * InfMap2.ChunkSize,
            ["angles"] = angles,
            ["fov"] = fov,
            ["znear"] = znear,
            ["zfar"] = zfar,
            ["drawviewer"] = false,
        }

        if not view then
            view = gmod.GetGamemode():CalcView(ply, pos + ply:GetMegaPos() * InfMap2.ChunkSize, angles, fov, znear, zfar)
        end
        if not view then
            view = view_fallback
        end
        view.origin = view.origin or view_fallback.origin

        local offset = (view.origin - relativeorigin)
        -- TODO: needs to account for megapos too?
        local pos, megapos = InfMap2.LocalizePosition(view.origin - offset)
        view.origin = pos + offset

        InfMap2.ViewMatrix:SetTranslation(-megapos * InfMap2.ChunkSize)
        return view
    end)
    hook.Add("CalcViewModelView", "InfMap2CalcViewModelView", function(wep, vm, oldpos, oldang, pos, ang)
        calcvmviewing = true
        local newpos, newang = hook.Run("INF_CalcViewModelView", wep, vm,
                                        oldpos + wep:GetOwner():GetMegaPos()* InfMap2.ChunkSize, oldang,
                                        pos + wep:GetOwner():GetMegaPos()* InfMap2.ChunkSize, ang)
        calcvmviewing = false

        if not newpos then
            newpos, newang = gmod.GetGamemode():CalcViewModelView(wep, vm,
                                                                  oldpos + wep:GetOwner():GetMegaPos()* InfMap2.ChunkSize, oldang,
                                                                  pos + wep:GetOwner():GetMegaPos()* InfMap2.ChunkSize, ang)
        end
        if not newpos then
            newpos = pos + wep:GetOwner():GetMegaPos() * InfMap2.ChunkSize
        end
    
        local offset = (newpos - relativeorigin)
        -- TODO: needs to account for megapos too?
        local pos, megapos = InfMap2.LocalizePosition(newpos - offset)
        newpos = pos + offset -- InfMap2.UnlocalizePosition(pos, megapos - LocalPlayer():GetMegaPos())
        return newpos, newang
    end)

    -- Detour hook.Add for stupid addons with stupid things
    hook.INF_Add = hook.INF_Add or hook.Add
    function hook.Add(ename, name, func, a, b, c)
        -- STUPID CALCVIEW AND IT'S NOT OURS HOLY SHIT
        if not override and ename == "CalcView" and name ~= "InfMap2CalcView" then
            ename = "INF_CalcView"
        end
        if not override and ename == "CalcViewModelView" and name ~= "InfMap2CalcViewModelView" then
            ename = "INF_CalcViewModelView"
        end

        return hook.INF_Add(ename, name, func, a, b, c)
    end

    -- Detour hook.Remove for stupid addons with stupid things
    hook.INF_Remove = hook.INF_Remove or hook.Remove
    function hook.Remove(ename, name, func, a, b, c)
        -- guh??
        if not override and ename == "CalcView" and name ~= "InfMap2CalcView" then
            ename = "INF_CalcView"
        end
        if not override and ename == "CalcViewModelView" and name ~= "InfMap2CalcViewModelView" then
            ename = "INF_CalcViewModelView"
        end
        return hook.INF_Remove(ename, name, func, a, b, c)
    end

    -- Detour hook.Call for addons that want calcview output
    hook.INF_Call = hook.INF_Call or hook.Call
    function hook.Call(ename, gm, a, b, c, d, e, f)
        -- we're calcviewing and something tries to get result of CalcView
        -- honestly i respect that, something is trying to fix that stupid shit
        if not override and calcviewing and ename == "CalcView" then
            ename = "INF_CalcView"
        end
        if not override and calcvmviewing and ename == "CalcViewModelView" then
            ename = "INF_CalcViewModelView"
        end
        return hook.INF_Call(ename, gm, a, b, c, d, e, f)
    end
end)

local csent = InfMap2.Cache.CSEnt or ClientsideModel("error.mdl")
InfMap2.Cache.CSEnt = csent

local pushed = false
hook.Add("RenderScene", "InfMap2RenderWorld", function() -- RenderScene
    if pushed then cam.INF_PopModelMatrix() end
    cam.INF_PushModelMatrix(InfMap2.ViewMatrix, false)
    pushed = true
end)
hook.Add("PostRenderTranslucentRenderables", "InfMap2RenderWorld", function(depth, skybox, skybox3d)
    if depth or skybox or skybox3d then return end
    if not pushed then return end
    cam.INF_PopModelMatrix()
    pushed = false
end)
hook.Add("PostRender", "InfMap2RenderWorld", function()
    if not pushed then return end
    cam.INF_PopModelMatrix()
    pushed = false
end)

hook.Add("PostDraw2DSkyBox", "InfMap2RenderWorld", function()
    --if depth or skybox or skybox3d then return end
    --do return end
    if not InfMap2.World.HasTerrain then return end
    if not InfMap2.Cache.material then
        InfMap2.Cache.material = Material(InfMap2.Visual.Terrain.Material)
    end

    if InfMap2.Space.HasSpace then
	    local eyepos = EyePos()
	    local color = math.max(0, math.min(1, 1-((eyepos.z - InfMap2.Space.Height / 2) / InfMap2.Space.Height)))
        if color == 0 then return end
        InfMap2.Cache.material:SetFloat("$alpha", color)
    end

    -- unfuck_lighting, thanks gwater 2 !
    if not IsValid(csent) then
        csent = ClientsideModel("error.mdl")
        InfMap2.Cache.CSEnt = csent
        csent:SetNoDraw(true)
    end
    
    local megaoffset = LocalPlayer():GetMegaPos() * InfMap2.ChunkSize
    render.OverrideColorWriteEnable(true, false)
    render.OverrideDepthEnable(true, false)
    csent:INF_SetPos(megaoffset)
    csent:SetAngles(EyeAngles())
    csent:SetupBones()

    csent:SetModel("models/shadertest/vertexlit.mdl")
    csent:DrawModel()

    csent:SetModel("models/shadertest/envballs.mdl")
    csent:DrawModel()

    render.OverrideDepthEnable(false, false)
    render.OverrideColorWriteEnable(false, false)

    local models = {
        "models/props_foliage/bramble001a.mdl",
        "models/props_foliage/cattails.mdl",
        "models/props_foliage/shrub_01a.mdl",
        "models/props_foliage/tree_deciduous_card_01_skybox.mdl",
        -- "models/props_foliage/tree_deciduous_card_01.mdl"
    }
    for i=0,100,1 do
        local pos = Vector(
            util.SharedRandom("InfMap_DetailX_"..i, -InfMap2.ChunkSize/2,
                                                     InfMap2.ChunkSize/2,
                                                     megaoffset.x),
            util.SharedRandom("InfMap_DetailY_"..i, -InfMap2.ChunkSize/2,
                                                     InfMap2.ChunkSize/2,
                                                     megaoffset.y)
        ) + megaoffset
        pos.z = InfMap2.GetTerrainHeightAt(pos.x, pos.y)

        csent:SetPos(pos)
        csent:SetModel(models[math.Round(util.SharedRandom("InfMap_DetailMDL_"..i, 1, #models, megaoffset.x + megaoffset.y))])
        csent:SetAngles(Angle(0, 
            util.SharedRandom("InfMap_DetailPitch_"..i, 0, 360,
                                megaoffset.x), 0))
        csent:SetupBones()
        csent:DrawModel()
    end


    render.SetMaterial(InfMap2.Cache.material)
    for _,meshes in pairs(InfMap2.ChunkMeshes.Draw) do
        for i=1,#meshes do meshes[i]:Draw() end
    end
end)

hook.Add("ShutDown", "InfMap2RenderWorld", function()
    for _,meshes in pairs(InfMap2.ChunkMeshes.Draw) do
        for i=1,#meshes do meshes[i]:Destroy() end
    end
end)

if InfMap2.Visual.HasSkybox then
    -- skybox bigass plane
    local size = InfMap2.Visual.Skybox.Size
    local uvsize = InfMap2.Visual.Skybox.UVScale
    local min = InfMap2.Visual.Skybox.Height
    local big_plane = Mesh()
    big_plane:BuildFromTriangles({
        {pos = Vector(size, size, min), normal = Vector(0, 0, 1), u = uvsize, v = 0, tangent = Vector(1, 0, 0), userdata = {1, 0, 0, -1}},
        {pos = Vector(size, -size, min), normal = Vector(0, 0, 1), u = uvsize, v = uvsize, tangent = Vector(1, 0, 0), userdata = {1, 0, 0, -1}},
        {pos = Vector(-size, -size, min), normal = Vector(0, 0, 1), u = 0, v = uvsize, tangent = Vector(1, 0, 0), userdata = {1, 0, 0, -1}},
        {pos = Vector(size, size, min), normal = Vector(0, 0, 1), u = uvsize, v = 0, tangent = Vector(1, 0, 0), userdata = {1, 0, 0, -1}},
        {pos = Vector(-size, -size, min), normal = Vector(0, 0, 1), u = 0, v = uvsize, tangent = Vector(1, 0, 0), userdata = {1, 0, 0, -1}},
        {pos = Vector(-size, size, min), normal = Vector(0, 0, 1), u = 0, v = 0, tangent = Vector(1, 0, 0), userdata = {1, 0, 0, -1}},
    })
    local plane_matrix = Matrix()

    hook.Add("PreDrawOpaqueRenderables", "InfMap2TerrainSkybox", function() -- draw skybox
        if not InfMap2.Cache.skyboxmaterial then InfMap2.Cache.skyboxmaterial = Material(InfMap2.Visual.Skybox.Material) end
        InfMap2.Cache.skyboxmaterial:SetFloat("$alpha", 1)
        -- dont draw to z buffer, this is skybox
        render.OverrideDepthEnable(true, false)
        render.SetMaterial(InfMap2.Cache.skyboxmaterial)
        -- fullbright
        render.ResetModelLighting(2, 2, 2)
        render.SetLocalModelLights()

        local offset = LocalPlayer():GetMegaPos()
        offset[1] = offset[1] % 1000
        offset[2] = offset[2] % 1000
        --plane_matrix:SetTranslation(offset)
        --cam.PushModelMatrix(plane_matrix)
        big_plane:Draw()
        --cam.PopModelMatrix()
        render.OverrideDepthEnable(false, false)
    end)
end

hook.Add("RenderScreenspaceEffects", "InfMap2UnderTerrain", function()
    local pos = LocalPlayer():EyePos()
    if pos.z >= InfMap2.GetTerrainHeightAt(pos.x, pos.y) then
        return
    end
    render.SetMaterial(InfMap2.Cache.material)
    render.DrawScreenQuad()
end)