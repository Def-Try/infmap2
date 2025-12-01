local shader = InfMap2.Shaders.Grass or {}
InfMap2.Shaders.Grass = shader
InfMap2.Shaders.Grass.Scale = 5

local simplex = include("simplex.lua")

local blades = 3600

local blades_sqrt = math.floor(math.sqrt(blades))
local blades = blades_sqrt*blades_sqrt

function shader.Init()
    if shader.Mesh then shader.Mesh:Destroy() end
    shader.Material = Material("infmap2/shaders/grass")
    shader.Mesh = Mesh()
    shader.TransformMatrix = Matrix()
    shader.DummyModel = ClientsideModel("models/shadertest/vertexlit.mdl")
    shader.DummyModel:SetModelScale(0)
    assert(6+(blades*3) <= 32768, "Too many vertices ("..(6+(blades*3)).." > 32768), decrease blades count!")

    mesh.Begin(shader.Mesh, MATERIAL_TRIANGLES, 6+(blades*3))
    local v0, v1, _, _ = InfMap2.GetTerrainSample(0, 0)
    local sample_size = math.abs(v0[1] - v1[1]) / 2
    local s = sample_size / blades_sqrt
    shader.Scale = s

    local top_rgb = InfMap2.Visual.Shaders.Grass.Colors.Top
    local bot_rgb = InfMap2.Visual.Shaders.Grass.Colors.Bottom
    local wind_base = InfMap2.Visual.Shaders.Grass.Wind.Base
    local wind_burst = InfMap2.Visual.Shaders.Grass.Wind.Burst
    local length = InfMap2.Visual.Shaders.Grass.Length

    -- now vertices for grass leafs
    for x=0,blades_sqrt-1 do
        for y=0,blades_sqrt-1 do
            local v1 = Vector(x*s, y*s, 0)
            local v2 = Vector(x*s+s, y*s, 0)
            local v3 = Vector(x*s+s, y*s+s, 25)

            local edge1 = v2 - v1
            local edge2 = v3 - v1

            local norm = (edge1:Cross(edge2)):GetNormalized()

            mesh.Position(x*s + (math.random() * 20), y*s + (math.random() * 20), 0)
            mesh.UserData(0, x, y, blades_sqrt)
            mesh.TexCoord(0, wind_base, wind_burst)
            mesh.Color(bot_rgb.r, bot_rgb.g, bot_rgb.b, 255)
            mesh.Normal(norm)
            mesh.AdvanceVertex()

            mesh.Position(x*s+s + (math.random() * 20), y*s + (math.random() * 20), 0)
            mesh.UserData(0, x, y, blades_sqrt)
            mesh.TexCoord(0, wind_base, wind_burst)
            mesh.Color(bot_rgb.r, bot_rgb.g, bot_rgb.b, 255)
            mesh.Normal(norm)
            mesh.AdvanceVertex()

            mesh.Position(x*s+s*0.5 + (math.random() * 20), y*s + (math.random() * 20), length)
            mesh.UserData(1, x, y, blades_sqrt)
            mesh.TexCoord(0, wind_base, wind_burst)
            mesh.Color(top_rgb.r, top_rgb.g, top_rgb.b, 255)
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
function shader.RenderMesh(vert, posv, localposv, half_sample_size)
    local v00 = InfMap2.GetTerrainHeightAt(vert[1], vert[2])
    local v01 = InfMap2.GetTerrainHeightAt(vert[1], vert[2]+half_sample_size)
    local v10 = InfMap2.GetTerrainHeightAt(vert[1]+half_sample_size, vert[2])
    local v11 = InfMap2.GetTerrainHeightAt(vert[1]+half_sample_size, vert[2]+half_sample_size)
    --render.DrawWireframeSphere(Vector(vert[1], vert[2], v00), 10, 8, 8, Color(0, 0, 0), false)
    --render.DrawWireframeSphere(Vector(vert[1], vert[2]+half_sample_size, v01), 10, 8, 8, Color(0, 255, 0), false)
    --render.DrawWireframeSphere(Vector(vert[1]+half_sample_size, vert[2], v10), 10, 8, 8, Color(255, 0, 0), false)
    --render.DrawWireframeSphere(Vector(vert[1]+half_sample_size, vert[2]+half_sample_size, v11), 10, 8, 8, Color(255, 255, 0), false)

    --do return end

    -- pass data into shader
    shader.TransformMatrix:SetTranslation(Vector(vert[1], vert[2], -(posv[3] - localposv[3])))
    render.SuppressEngineLighting(true)
    render.SetModelLighting(0, vert[1] / (half_sample_size) * blades_sqrt, vert[2] / (half_sample_size) * blades_sqrt, CurTime() * 0.3)
    render.SetModelLighting(1, localposv[1], localposv[2], v00)
    render.SetModelLighting(2, v01, v10, v11)
    shader.DummyModel:DrawModel()
    render.SuppressEngineLighting(false)

    -- render shader
    cam.PushModelMatrix(shader.TransformMatrix)
    render.SetMaterial(shader.Material)
    render.OverrideDepthEnable(true, true)
        ---@diagnostic disable-next-line: undefined-global
        render.CullMode(MATERIAL_CULLMODE_NONE)
        shader.Mesh:Draw()
        render.CullMode(MATERIAL_CULLMODE_CCW)
    render.OverrideDepthEnable(false, false)
    cam.PopModelMatrix()

    --do error(1) end
end
function shader.RenderChunkGrass(chunkvert, plyposv, localposv, half_sample_size)
    local vert = {chunkvert[1], chunkvert[2]}
    local posv = {plyposv[1], plyposv[2], plyposv[3]}
    shader.RenderMesh(vert, posv, localposv, half_sample_size)
    vert[1] = vert[1] + half_sample_size
    shader.RenderMesh(vert, posv, localposv, half_sample_size)
    vert[2] = vert[2] + half_sample_size
    shader.RenderMesh(vert, posv, localposv, half_sample_size)
    vert[1] = vert[1] - half_sample_size
    shader.RenderMesh(vert, posv, localposv, half_sample_size)
end
function shader.Render()
	local pos = EyePos()
    local lpos = INF_EyePos()
    local posv = {pos[1], pos[2], pos[3]}
    local localposv = {lpos[1], lpos[2], lpos[3]}
    local v0, v1, v2, v3 = InfMap2.GetTerrainSample(pos.x, pos.y)
    local sample_size = math.abs(v0[1] - v1[1])
    local v4 = {v0[1] - sample_size, v0[2]}
    local v5 = {v0[1] - sample_size, v0[2] - sample_size}
    local v6 = {v0[1], v0[2] - sample_size}
    local v7 = {v0[1] + sample_size, v0[2] - sample_size}
    local v8 = {v0[1] - sample_size, v0[2] + sample_size}
    local half_sample_size = sample_size * 0.5

    shader.RenderChunkGrass(v0, posv, localposv, half_sample_size)
    shader.RenderChunkGrass(v1, posv, localposv, half_sample_size)
    shader.RenderChunkGrass(v2, posv, localposv, half_sample_size)
    shader.RenderChunkGrass(v3, posv, localposv, half_sample_size)
    shader.RenderChunkGrass(v4, posv, localposv, half_sample_size)
    shader.RenderChunkGrass(v5, posv, localposv, half_sample_size)
    shader.RenderChunkGrass(v6, posv, localposv, half_sample_size)
    shader.RenderChunkGrass(v7, posv, localposv, half_sample_size)
    shader.RenderChunkGrass(v8, posv, localposv, half_sample_size)
end