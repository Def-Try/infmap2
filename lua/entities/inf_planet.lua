AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.Category		= "InfMap2"
ENT.PrintName		= "Planet Entity"
ENT.Author			= "googer_"
ENT.Purpose			= "Planet entity"
ENT.Instructions	= "no."
ENT.Spawnable		= false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

if not InfMap2 then return end

local atmosphere = Material("infmap2/space/atmosphere")

function ENT:Initialize(ready)
    if not ready then return end
    if not self.INF_PlanetData then return end
    if CLIENT then
        self.INF_PlanetVisMesh = InfMap2.GeneratePlanetVisualMesh(self.INF_PlanetData, self:GetPos())
        self.INF_RenderMesh = Mesh()
        self.INF_RenderMatrix = Matrix()
        self.INF_RenderMatrix:SetTranslation(self:GetPos())
        mesh.Begin(self.INF_RenderMesh, MATERIAL_TRIANGLES, math.min(#self.INF_PlanetVisMesh / 3, 2^13))
        for _, tri in ipairs(self.INF_PlanetVisMesh) do
            mesh.Position(tri[1])
            mesh.TexCoord(0, tri[2], tri[3])
            mesh.Normal(tri[4])
            mesh.UserData(1, 1, 1, 1)
            mesh.AdvanceVertex()
        end
        mesh.End()
        self:SetRenderBounds(-Vector(1, 1, 1) * self.INF_PlanetData.Radius * 2, Vector(1, 1, 1) * self.INF_PlanetData.Radius * 2)
    end

    self.INF_PlanetMesh = InfMap2.GeneratePlanetVertexMesh(self.INF_PlanetData, self:GetPos())
    self:PhysicsDestroy()
    self:PhysicsFromMesh(self.INF_PlanetMesh)

    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
    self:EnableCustomCollisions()

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
        phys:SetMass(50000)
        phys:AddGameFlag(FVPHYSICS_CONSTRAINT_STATIC)
        phys:AddGameFlag(FVPHYSICS_NO_SELF_COLLISIONS)
    else
        if SERVER then
            self:Remove()
        end
    end

    self:DrawShadow(false)
    self:AddSolidFlags(FSOLID_FORCE_WORLD_ALIGNED)
    self:AddFlags(FL_STATICPROP)
    self:AddEFlags(EFL_KEEP_ON_RECREATE_ENTITIES)
    self:SetRenderMode(RENDERMODE_NORMAL)
end

function ENT:Think()
    -- not sure why, but for some reason planettype arrives BEFORE position was set?
    -- reinitialize that b*tch
    if self.INF_LastPos ~= self:GetPos() and self.INF_PlanetData then
        self.INF_LastPos = self:GetPos()
        self:Initialize(true)
        return
    end
    if self.INF_PlanetType and self.INF_PlanetType ~= "" then return end
    self.INF_PlanetType = self:GetNW2String("INF_PlanetType", nil)
    if not self.INF_PlanetType or self.INF_PlanetType == "" then return end
    self.INF_PlanetData = InfMap2.Space.Planets[self.INF_PlanetType]
    self:Initialize(true)
end

function ENT:Draw()
    if not self.INF_PlanetType then return end
    if not self.INF_PlanetData then return end
    local data = self.INF_PlanetData

    local col = Color(255, 255, 255, EyePos().z / InfMap2.Space.Height * 255)
    local dst = LocalPlayer():GetPos():Distance(self:GetPos())

    local detail = (11 - math.Round(math.min(10, math.max(1, dst / 70000)))) * 5

    render.SetMaterial(data.MaterialOverrides["outside"])
    render.DrawSphere(self:GetPos(), (data.Radius + 7), detail, detail, col)

    -- don't draw inside if too far
    if dst > self.INF_PlanetData.Radius * 2 then return end

    if data.Atmosphere then
        local atmos = data.Atmosphere
		atmosphere:SetVector("$color", atmos[1])
		atmosphere:SetFloat("$alpha", atmos[2])
        render.SetMaterial(atmosphere)
        render.DrawSphere(self:GetPos(), -(data.Radius + 7), 50, 50)
    end

    render.SetMaterial(self.INF_PlanetData.MaterialOverrides["inside"])
    self:SetRenderBounds(Vector(), Vector(), Vector(1, 1, 1) * self.INF_PlanetData.Radius)

    render.ResetModelLighting(1, 1, 1)
    
    self.INF_RenderMatrix:SetTranslation(self:GetPos())
    cam.PushModelMatrix(self.INF_RenderMatrix)
    self.INF_RenderMesh:Draw()
    cam.PopModelMatrix()
end

hook.Add("PhysgunPickup", "InfMap2PlanetPhysgunable", function(ply, ent)
    if ent:GetClass() == "inf_planet" then return false end
end)