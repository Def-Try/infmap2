AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.Category		= "InfMap2"
ENT.PrintName		= "Cross Chunk Entity Clone"
ENT.Author			= "googer_"
ENT.Purpose			= "Used for cross chunk entity collisions."
ENT.Instructions	= "no."
ENT.Spawnable		= false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

if not InfMap2 then return end

ENT.INF_ReferenceData = {Parent = NULL, Chunk = Vector(), Megapos = Vector()}

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "ReferenceParent")
end

function ENT:SetReferenceEntity(ent)
    ---@diagnostic disable-next-line: undefined-field
    self:SetReferenceParent(ent)
    self.INF_ReferenceData.Parent = ent
    ---@diagnostic disable-next-line: undefined-field
    self.INF_ReferenceData.Megapos = ent:GetMegaPos()
end
function ENT:SetReferenceChunk(chunk)
    self.INF_ReferenceData.Chunk = chunk
    self.INF_ReferenceData.Megapos = self.INF_ReferenceData.Megapos + chunk
    InfMap2.EntityUpdateMegapos(self, self.INF_ReferenceData.Megapos)
end

function ENT:InitializePhysics(convexes)
    self:EnableCustomCollisions()
    self:PhysicsFromMesh(convexes)

    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:EnableMotion(false)
    end
end

function ENT:InitializeClient(parent)
    if not IsValid(parent) then
        ErrorNoHalt("CrossChunkClone: Failed to initialize", self)
        return
    end

    local phys = parent:GetPhysicsObject()
    if !phys:IsValid() then -- no custom physmesh, bail
        self:PhysicsInit(SOLID_VPHYSICS)
        return 
    end
    
    local convexes = phys:GetMesh()
    if !convexes then -- no convexes, bail
        self:PhysicsInit(SOLID_VPHYSICS)
        return
    end
    
    self:InitializePhysics(convexes)
end

function ENT:Initialize()
    ---@diagnostic disable-next-line: undefined-field
    local parent = self:GetReferenceParent()
    if CLIENT then
        self:InitializeClient(parent)
        return
    end
    
    self:SetModel(parent:GetModel())
    self:SetCollisionGroup(parent:GetCollisionGroup())
    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)

    local phys = parent:GetPhysicsObject()
    if not phys:IsValid() then
        SafeRemoveEntity(self)
        return 
    end
    
    local convexes = phys:GetMesh()
    if not convexes then
        SafeRemoveEntity(self)
        return
    end

    self:InitializePhysics(convexes)

    InfMap2.EntityUpdateMegapos(self, self.INF_ReferenceData.Megapos)
end

function ENT:Think()
    if CLIENT then 
        self:SetNoDraw(true)
        local phys = self:GetPhysicsObject()
        if phys:IsValid() then
            phys:EnableMotion(false)
            --phys:SetPos(self:GetPos())
            --phys:SetAngles(self:GetAngles())
        else
            if InfMap2.Debug then print("[INFMAP] Regenerating physics for CrossChunkClone", self) end
            self:Initialize()
        end
        return 
    end

    local data = self.INF_ReferenceData
    if not data then 
        SafeRemoveEntity(self)
        return
    end
    
    local parent = data.Parent
    if not IsValid(parent) or data.Megapos ~= parent:GetMegaPos() + data.Chunk then
        SafeRemoveEntity(self)
        return
    end

    self:INF_SetPos(parent:INF_GetPos() - data.Chunk * InfMap2.ChunkSize)

    InfMap2.EntityUpdateMegapos(self, self.INF_ReferenceData.Megapos)
    self:SetAngles(parent:GetAngles())
    
    local phys = self:GetPhysicsObject()
    if phys:IsValid() then phys:EnableMotion(false) end
end

hook.Add("PhysgunPickup", "InfMap2CrossChunkClonePhysgunable", function(ply, ent)
    if ent:GetClass() == "inf_crosschunkclone" then return false end
end)