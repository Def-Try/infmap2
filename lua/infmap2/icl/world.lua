InfMap2.ChunkMeshes = InfMap2.ChunkMeshes or {Index = {}, Draw = {}}
InfMap2.ViewMatrix = InfMap2.ViewMatrix or Matrix()
InfMap2.GeneratedChunks = InfMap2.GeneratedChunks or {}

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
        if InfMap2.DoLighting then
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

InfMap2.Cache.ChunkQueue = InfMap2.Cache.ChunkQueue or {
    Remove = {},
    Create = {}
}

---Generates a megachunk.
---@param megapos Vector megachunk megapos (megamegapos)
function InfMap2.CreateWorldMegaChunk(megapos)
    if InfMap2.Debug then print("[INFMAP] World megachunk creation requested at "..tostring(megapos)) end
    InfMap2.GenerateChunkVisualMesh(megapos * InfMap2.MegachunkSize, Vector(InfMap2.MegachunkSize, InfMap2.MegachunkSize), function(vismesh)
        local meshes = InfMap2.BuildMeshObjects(vismesh)
        local idx = table.insert(InfMap2.ChunkMeshes.Draw, meshes)
        InfMap2.ChunkMeshes.Index[tostring(megapos)] = idx
        InfMap2.ChunkMeshes.Index[idx] = megapos
    end, function() return InfMap2.GeneratedChunks[tostring(megapos)] or false end)
    InfMap2.GeneratedChunks[tostring(megapos)] = true
end

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

local csent = ClientsideModel("error.mdl")
local lighting_table = {model = "models/shadertest/vertexlit.mdl", pos = Vector()}
local cubemap_table  = {model = "models/shadertest/envballs.mdl",  pos = Vector()}

hook.Add("PreDrawOpaqueRenderables", "InfMap2RenderWorld", function()
    if not InfMap2.UsesGenerator then return end
    if not InfMap2.Cache.material then InfMap2.Cache.material = Material(InfMap2.Material) end

    -- unfuck_lighting, thanks gwater 2 !
    if not IsValid(csent) then csent = ClientsideModel("error.mdl") end
    render.OverrideColorWriteEnable(true, false)
    render.OverrideDepthEnable(true, false)
    cubemap_table.angle = EyeAngles()
    render.Model(cubemap_table, csent)
    lighting_table.angle = EyeAngles()
    render.Model(lighting_table, csent)
    render.OverrideDepthEnable(false, false)
    render.OverrideColorWriteEnable(false, false)

    cam.PushModelMatrix(InfMap2.ViewMatrix, true)
    render.SetMaterial(InfMap2.Cache.material)
    for _,meshes in pairs(InfMap2.ChunkMeshes.Draw) do
        for i=1,#meshes do meshes[i]:Draw() end
    end
    cam.PopModelMatrix()
end)

hook.Add("ShutDown", "InfMap2RenderWorld", function()
    for _,meshes in pairs(InfMap2.ChunkMeshes.Draw) do
        for i=1,#meshes do meshes[i]:Destroy() end
    end
end)

-- skybox bigass plane
local scale = 10000
local size = 200000 * scale
local uvsize = 100 * scale
local min = -100000
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

hook.Add("PostDraw2DSkyBox", "infmap_terrain_skybox", function() -- draw skybox
    if not InfMap2.UsesGenerator then return end
    if not InfMap2.Cache.material then InfMap2.Cache.material = Material(InfMap2.Material) end

    -- dont draw to z buffer, this is skybox
	render.OverrideDepthEnable(true, false)
	render.SetMaterial(InfMap2.Cache.material)
    -- fullbright
	render.ResetModelLighting(2, 2, 2)
	render.SetLocalModelLights()

	local offset = Vector(LocalPlayer().INF_MegaPos)
	offset[1] = offset[1] % 1000
	offset[2] = offset[2] % 1000

	InfMap2.Cache.material:SetFloat("$alpha", 1)
	plane_matrix:SetTranslation(InfMap2.UnlocalizePosition(Vector(), -offset))
	cam.PushModelMatrix(plane_matrix)
	big_plane:Draw()
	cam.PopModelMatrix()
	render.OverrideDepthEnable(false, false)
end)