InfMap2.ChunkMeshes = InfMap2.ChunkMeshes or {Index = {}, Draw = {}}
InfMap2.ViewMatrix = InfMap2.ViewMatrix or Matrix()
InfMap2.GeneratedChunks = InfMap2.GeneratedChunks or {}

---Asynchronously generates visual mesh of a single megachunk of certain size at megapos.
---Requires UsesGenerator, HeightFunction, ChunkSize and SampleSize to be set up.
---@param megapos Vector Megachunk origin chunk megapos
---@param megasize Vector Megachunk size
---@param callback function Callback when mesh has been generated. The argument is megachunk mesh data (table<pos, u, v, norm>).
---@param docontinue? function Function to check if mesh should continue generating
function InfMap2.GenerateChunkVisualMesh(megapos, megasize, callback, docontinue)
    print("[INFMAP] InfMap2.GenerateChunkVisualMesh stub called")
    debug.Trace()
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
    print("[INFMAP] InfMap2.CreateWorldMegaChunk stub called")
    debug.Trace()
end

---Removes megachunk
---@param megapos Vector megachunk megapos (megamegapos)
function InfMap2.RemoveWorldMegaChunk(megapos)
    print("[INFMAP] InfMap2.RemoveWorldMegaChunk stub called")
    debug.Trace()
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
    csent:INF_SetPos(vector_origin) -- (megaoffset)
    csent:SetAngles(EyeAngles())
    csent:SetupBones()

    csent:SetModel("models/shadertest/vertexlit.mdl")
    csent:DrawModel()

    csent:SetModel("models/shadertest/envballs.mdl")
    csent:DrawModel()

    render.OverrideDepthEnable(false, false)
    render.OverrideColorWriteEnable(false, false)

    render.SetMaterial(InfMap2.Cache.material)
    --render.CullMode(MATERIAL_CULLMODE_NONE)
    local draw_ = InfMap2.ChunkMeshes.Draw
    for i=1,#draw_ do draw_[i]:Draw() end
end)

hook.Add("ShutDown", "InfMap2RenderWorld", function()
    local draw_ = InfMap2.ChunkMeshes.Draw
    for i=1,#draw_ do draw_[i]:Destroy() end
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
        --render.OverrideDepthEnable(true, false)
        render.SetMaterial(InfMap2.Cache.skyboxmaterial)
        -- fullbright
        render.ResetModelLighting(2, 2, 2)
        render.SetLocalModelLights()

        local offset = LocalPlayer():GetMegaPos()
        offset[1] = offset[1] % 1000
        offset[2] = offset[2] % 1000
        --plane_matrix:SetTranslation(offset)
        --cam.PushModelMatrix(plane_matrix)
        --big_plane:Draw()
        --cam.PopModelMatrix()
        render.OverrideDepthEnable(false, false)
    end)
end

hook.Add("RenderScreenspaceEffects", "InfMap2UnderTerrain", function()
    do return end
    local pos = LocalPlayer():EyePos()
    if pos.z >= InfMap2.GetTerrainHeightAt(pos.x, pos.y) then
        return
    end
    render.SetMaterial(InfMap2.Cache.material)
    render.DrawScreenQuad()
end)

local function generate_chunk(chunk, lodlvl, megapos)
    if chunk.lodlvl == lodlvl and chunk.megapos == megapos then return end
    chunk.lodlvl = lodlvl
    if IsValid(chunk.mesh) then
        chunk.mesh:Destroy()
    end
    chunk.megapos = megapos
    chunk.mesh = Mesh()
    local mesh_ = InfMap2.GenerateChunkVertexMesh(megapos, lodlvl)
    if #mesh_ / 6 > 8192 then
        error("Too many tris! ("..(#mesh_ / 6).." > 8192)! Decrease samples count!")
    end
    local megaoff = megapos * InfMap2.ChunkSize
    local uvs = InfMap2.Visual.Terrain.UVScale
    mesh.Begin(chunk.mesh, MATERIAL_QUADS, #mesh_ / 6)
        local v0, v1, v2, v3, norm
        for i=1, #mesh_, 6 do
            v0, v1, v2, v3 = mesh_[i+0], mesh_[i+2], mesh_[i+1], mesh_[i+4]
            norm = -(v3 - v2):Cross(v3 - v1)
            norm:Normalize()
            norm:Negate()
            --[[
            chunk_mesh[#chunk_mesh + 1] = v0,
            chunk_mesh[#chunk_mesh + 1] = v2,
            chunk_mesh[#chunk_mesh + 1] = v1,

            chunk_mesh[#chunk_mesh + 1] = v2,
            chunk_mesh[#chunk_mesh + 1] = v3,
            chunk_mesh[#chunk_mesh + 1] = v1,
            ]]

            mesh.Position(v2 + megaoff)
            mesh.Normal(norm)
            mesh.TexCoord(0, uvs, 0) mesh.Color(255, 255, 255, 255)
            mesh.AdvanceVertex()

            mesh.Position(v3 + megaoff)
            mesh.Normal(norm)
            mesh.TexCoord(0, uvs, uvs) mesh.Color(255, 255, 255, 255)
            mesh.AdvanceVertex()

            mesh.Position(v1 + megaoff)
            mesh.Normal(norm)
            mesh.TexCoord(0, 0, uvs) mesh.Color(255, 255, 255, 255) 
            mesh.AdvanceVertex()

            mesh.Position(v0 + megaoff)
            mesh.Normal(norm)
            mesh.TexCoord(0, 0, 0) mesh.Color(255, 255, 255, 255)
            mesh.AdvanceVertex()
        end
    mesh.End()
end
local function process_chunk(chunk, plypos, megapos)
    local diff = plypos - megapos
    local dist = math.max(math.abs(diff.x), math.abs(diff.y), math.abs(plypos.z))
    local chunk_megapos = chunk.megapos
    local rebuild = false
    if not rebuild and chunk_megapos == nil then rebuild = true end
    if not rebuild and chunk_megapos.x ~= megapos.x then rebuild = true end
    if not rebuild and chunk_megapos.y ~= megapos.y then rebuild = true end
    if not rebuild and chunk_megapos.z ~= megapos.z then rebuild = true end
    if not rebuild then return false end
    generate_chunk(chunk, dist, megapos)
    return true
end
local function get_chunk(index, x, y)
    local idx = x.."x"..y
    local chunk = index[idx]
    if chunk == nil then
        chunk = {}
        index[idx] = chunk
    end
    return chunk
end
hook.Add("PreRender", "InfMap2BuildWorldVisual", function()
    local megapos = LocalPlayer():GetMegaPos()
    local index = InfMap2.ChunkMeshes.Index
    local ms = InfMap2.Visual.RenderDistance
    local rebuilt = 0
    for x = -ms, ms do
        for y = -ms, ms do
            rebuilt = rebuilt + (process_chunk(get_chunk(index, x, y), megapos, megapos+Vector(x, y)) and 1 or 0)
            if rebuilt > 2 then break end
        end
        if rebuilt > 2 then break end
    end
    if rebuilt == 0 then return end
    table.Empty(InfMap2.ChunkMeshes.Draw)
    InfMap2.ChunkMeshes.Draw = {}
    for x = -ms, ms do
        for y = -ms, ms do
            InfMap2.ChunkMeshes.Draw[#InfMap2.ChunkMeshes.Draw+1] = get_chunk(index, x, y).mesh
        end
    end
end)