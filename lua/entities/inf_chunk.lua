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
    --if SERVER and not self.INF_Ready then return end
    if CLIENT and not self:GetMegaPos() then return end
    self:INF_SetPos(Vector(0, 0, 0))
    
    --self:SetMegaPos(self:GetMegaPos())

    local starttime = SysTime()
    local chunk_mesh = InfMap2.GenerateChunkVertexMesh(self:GetMegaPos(), 1)
    local endtime = SysTime()
    if InfMap2.Debug then
        print("[INFMAP] took "..(endtime-starttime).."s to build physics mesh @ LOD 1 (highest) at megapos "..tostring(self:GetMegaPos()))
    end
    self.INF_ChunkMesh = chunk_mesh
    --do return self:PhysicsInitBox(Vector(), Vector()) end
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
end

function ENT:Think()
    if not IsValid(self:GetPhysicsObject()) and self:GetMegaPos() then
        if InfMap2.Debug then print("[INFMAP] Rebuilding Collisions for chunk ", self:GetMegaPos()) end
        self:Initialize()
    end
    if CLIENT then
        if InfMap2.Debug then
            self:INF_SetRenderBoundsWS(Vector(-32768, -32768, -32768), Vector(32768, 32768, 32768))
            self:SetNoDraw(false)
        else 
            self:SetNoDraw(true)
        end
    end
end

function ENT:Draw()
    do return end
    if not InfMap2.Debug then return end
    if not self.INF_ChunkMesh then return end
    local megamegapos = self:GetMegaPos() / InfMap2.Visual.MegachunkSize
    megamegapos.z = 0
    megamegapos.x = math.Round(megamegapos.x)
    megamegapos.y = math.Round(megamegapos.y)
    local cmesh = self.INF_ChunkMesh
    local color = Color(255, 0, 0)
    --color.r = math.Round(util.SharedRandom("INF_ChunkMeshDraw_"..tostring(self:GetMegaPos()), 0, 1, 0)) * 255
    --color.g = math.Round(util.SharedRandom("INF_ChunkMeshDraw_"..tostring(self:GetMegaPos()), 0, 1, 1)) * 255
    --color.b = math.Round(util.SharedRandom("INF_ChunkMeshDraw_"..tostring(self:GetMegaPos()), 0, 1, 2)) * 255
    local ignorez = false

    local off = self:GetMegaPos() * InfMap2.ChunkSize
    --if off - LocalPlayer():GetMegaPos() * InfMap2.ChunkSize ~= Vector() then return end
    if ignorez then render.SetColorMaterialIgnoreZ() else render.SetColorMaterial() end
    for i=1,#cmesh,3 do
        render.DrawLine(cmesh[i+0], cmesh[i+1], color, not ignorez)
        render.DrawLine(cmesh[i+1], cmesh[i+2], color, not ignorez)
        render.DrawLine(cmesh[i+0], cmesh[i+2], color, not ignorez)
    end
end

hook.Add("PhysgunPickup", "InfMap2ChunkPhysgunable", function(ply, ent)
    if ent:GetClass() == "inf_chunk" then return false end
end)