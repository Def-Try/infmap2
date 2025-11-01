local shader = InfMap2.Shaders.Grass or {}
InfMap2.Shaders.Grass = shader
InfMap2.Shaders.Grass.Scale = 5

local simplex = include("infmap2/simplex.lua")

function shader.Init()
    if shader.Mesh then shader.Mesh:Destroy() end
    shader.Material = Material("infmap2/shaders/grass")
    shader.Mesh = Mesh()
    shader.TransformMatrix = Matrix()
    shader.DummyModel = ClientsideModel("models/shadertest/vertexlit.mdl")
    shader.DummyModel:SetModelScale(0)
    local blades = 3600
    
    local blades_sqrt = math.floor(math.sqrt(blades))
    local blades = blades_sqrt*blades_sqrt
    assert(6+(blades*3) <= 32768, "Too many vertices ("..(6+(blades*3)).." > 32768), decrease blades count!")

    mesh.Begin(shader.Mesh, MATERIAL_TRIANGLES, 6+(blades*3))
    local v0, v1, v2, v3 = InfMap2.GetTerrainSample(0, 0)
    local sample_size = math.abs(v0[1] - v1[1]) / 2
    local s = sample_size / blades_sqrt
    shader.Scale = s
    local mincol, maxcol = 0.1, 1
    -- now vertices for grass leafs
    for x=0,blades_sqrt-1 do
        for y=0,blades_sqrt-1 do
            local v1 = Vector(x*s, y*s, 0)
            local v2 = Vector(x*s+s, y*s, 0)
            local v3 = Vector(x*s+s, y*s+s, 25)

            local edge1 = v2 - v1
            local edge2 = v3 - v1

            local norm = (edge1:Cross(edge2)):GetNormalized()

            mesh.Position(x*s, y*s, 0)
            mesh.UserData(0, 0, 0, 0)
            mesh.TexCoord(0, 0, 0)
            mesh.Color(77, 96, 0, 255)
            mesh.Normal(norm)
            mesh.AdvanceVertex()

            mesh.Position(x*s+s, y*s, 0)
            mesh.UserData(0, 0, 0, 0)
            mesh.TexCoord(0, 0, 0)
            mesh.Color(77, 96, 0, 255)
            mesh.Normal(norm)
            mesh.AdvanceVertex()

            mesh.Position(x*s+s, y*s+s, 0)
            mesh.UserData(1, x * 0.1, y * 0.1, 0)
            mesh.TexCoord(0, 0, 0)
            mesh.Color(134, 200, 0, 255)
            mesh.Normal(norm)
            mesh.AdvanceVertex()
        end
    end
    mesh.End()
end

function shader.Think()
    do return end
    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    local s = shader.Scale
    local pos = lp:GetPos()
    pos[1] = math.floor(pos[1] / s) * s
    pos[2] = math.floor(pos[2] / s) * s
    pos[3] = InfMap2.GetTerrainHeightAt(pos[1], pos[2]) + 0.01
    shader.TransformMatrix:SetTranslation(pos)
end
function shader.RenderMesh(vert, posv)
    -- pass data into shader
    shader.TransformMatrix:SetTranslation(Vector(vert[1], vert[2], -14.9))
    render.SuppressEngineLighting(true)
    render.SetModelLighting(0, vert[1], vert[2], CurTime() * 0.2)
    render.SetModelLighting(1, posv[1], posv[2], 0)
    shader.DummyModel:DrawModel()
    render.SuppressEngineLighting(false)

    -- render shader
    cam.PushModelMatrix(shader.TransformMatrix)
    render.SetMaterial(shader.Material)
    render.OverrideDepthEnable(true, true)
        render.CullMode(MATERIAL_CULLMODE_NONE)
        shader.Mesh:Draw()
        render.CullMode(MATERIAL_CULLMODE_CCW)
    render.OverrideDepthEnable(false, false)
    cam.PopModelMatrix()
end
function shader.RenderChunkGrass(chunkvert, plyposv, half_sample_size)
    local vert = {chunkvert[1], chunkvert[2]}
    local posv = {plyposv[1], plyposv[2]}
    shader.RenderMesh(vert, posv)
    vert[1] = vert[1] + half_sample_size
    shader.RenderMesh(vert, posv)
    vert[2] = vert[2] + half_sample_size
    shader.RenderMesh(vert, posv)
    vert[1] = vert[1] - half_sample_size
    shader.RenderMesh(vert, posv)
end
function shader.Render()
	render.DrawLine(Vector(), Vector(110, 0, 0), Color(255, 0, 0, 255), true)
	render.DrawLine(Vector(), Vector(0, 110, 0), Color(0, 255, 0, 255), true)
	render.DrawLine(Vector(), Vector(0, 0, 110), Color(0, 0, 255, 255), true)

    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    local pos = lp:GetPos()
    local posv = {pos[1], pos[2], pos[3]}
    local v0, v1, v2, v3 = InfMap2.GetTerrainSample(pos.x, pos.y)
    local sample_size = math.abs(v0[1] - v1[1])
    local v4 = {v0[1] - sample_size, v0[2]}
    local v5 = {v0[1] - sample_size, v0[2] - sample_size}
    local v6 = {v0[1], v0[2] - sample_size}
    local v7 = {v0[1] + sample_size, v0[2] - sample_size}
    local v8 = {v0[1] - sample_size, v0[2] + sample_size}
    local half_sample_size = sample_size * 0.5

    shader.RenderChunkGrass(v0, posv, half_sample_size)
    shader.RenderChunkGrass(v1, posv, half_sample_size)
    shader.RenderChunkGrass(v2, posv, half_sample_size)
    shader.RenderChunkGrass(v3, posv, half_sample_size)
    shader.RenderChunkGrass(v4, posv, half_sample_size)
    shader.RenderChunkGrass(v5, posv, half_sample_size)
    shader.RenderChunkGrass(v6, posv, half_sample_size)
    shader.RenderChunkGrass(v7, posv, half_sample_size)
    shader.RenderChunkGrass(v8, posv, half_sample_size)
end