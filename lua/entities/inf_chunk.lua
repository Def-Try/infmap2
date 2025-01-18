AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.Category		= "InfMap2"
ENT.PrintName		= "Chunk Entity"
ENT.Author			= "googer_"
ENT.Purpose			= "Chunk entity, handling terrain colliders"
ENT.Instructions	= "no."
ENT.Spawnable		= false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

if not InfMap2 then return end

function ENT:Initialize()
    if CLIENT and not self.INF_MegaPos then return end
    self:INF_SetPos(Vector(0, 0, 0))
    
    --self:SetNW2Vector("INF_MegaPos", self.INF_MegaPos)

    local chunk_mesh = InfMap2.GenerateChunkVertexMesh(self.INF_MegaPos)
    self:PhysicsDestroy()
    if #chunk_mesh == 0 then -- no vertices, no colliders
        self:PhysicsInitBox(Vector(), Vector())
        self:SetCollisionGroup(COLLISION_GROUP_WORLD)
    else
        self:PhysicsFromMesh(chunk_mesh)
    end
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
    --self:SetCustomCollisionCheck(true) -- required for ShouldCollide hook

    --self:SetCollisionBoundsWS(Vector(-InfMap2.ChunkSize, -InfMap2.ChunkSize, -InfMap2.ChunkSize),
    --                          Vector( InfMap2.ChunkSize,  InfMap2.ChunkSize,  InfMap2.ChunkSize))

    self.INF_ChunkMesh = chunk_mesh
end

function ENT:Think()
    if CLIENT then
        self.INF_MegaPos = self:GetNW2Vector("INF_MegaPos")
    end
    if not IsValid(self:GetPhysicsObject()) and self.INF_MegaPos then
        if InfMap2.Debug then print("[INFMAP] Rebuilding Collisions for chunk ", self.INF_MegaPos) end
        self:Initialize()
    end
end

function ENT:Draw()
    if not InfMap2.Debug then return end
    if not self.INF_ChunkMesh then return end
    local cmesh = self.INF_ChunkMesh
    local color = Color(255, 255, 255)
    color.r = math.Round(util.SharedRandom("INF_ChunkMeshDraw_"..tostring(self.INF_MegaPos), 0, 1, 0)) * 255
    color.g = math.Round(util.SharedRandom("INF_ChunkMeshDraw_"..tostring(self.INF_MegaPos), 0, 1, 1)) * 255
    color.b = math.Round(util.SharedRandom("INF_ChunkMeshDraw_"..tostring(self.INF_MegaPos), 0, 1, 2)) * 255
    local ignorez = false

    local off = self.INF_MegaPos * InfMap2.ChunkSize
    if off - LocalPlayer().INF_MegaPos * InfMap2.ChunkSize ~= Vector() then return end
    if ignorez then render.SetColorMaterialIgnoreZ() else render.SetColorMaterial() end
    for i=1,#cmesh,3 do
        render.DrawLine(cmesh[i+0] + off, cmesh[i+1] + off, color, not ignorez)
        render.DrawLine(cmesh[i+1] + off, cmesh[i+2] + off, color, not ignorez)
        render.DrawLine(cmesh[i+0] + off, cmesh[i+2] + off, color, not ignorez)
    end
end

hook.Add("PhysgunPickup", "InfMap2ChunkPhysgunable", function(ply, ent)
    if ent:GetClass() == "inf_chunk" then return false end
end)