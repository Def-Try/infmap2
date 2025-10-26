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
    self.INF_ReferenceData.Megapos = self.INF_ReferenceData.Parent:GetMegaPos() + chunk
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
        if InfMap2.Debug then
            self:INF_SetRenderBoundsWS(Vector(-32768, -32768, -32768), Vector(32768, 32768, 32768))
            self:SetNoDraw(false)
        else 
            self:SetNoDraw(true)
        end
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
        if InfMap2.Debug then print("[INFMAP] CrossChunkClone", self, "- Reference Data is invalid") end
        SafeRemoveEntity(self)
        return
    end
    
    local parent = data.Parent
    if not IsValid(parent) then
        if InfMap2.Debug then print("[INFMAP] CrossChunkClone", self, "- Parent is no longer valid") end
        SafeRemoveEntity(self)
        return
    end
    if data.Megapos ~= parent:GetMegaPos() + data.Chunk then
        if InfMap2.Debug then print("[INFMAP] CrossChunkClone", self, "- Megapos is wrong") end
        SafeRemoveEntity(self)
        return
    end

    self:INF_SetPos(parent:INF_GetPos() - data.Chunk * InfMap2.ChunkSize)

    InfMap2.EntityUpdateMegapos(self, data.Megapos)
    self:SetAngles(parent:GetAngles())
    
    local phys = self:GetPhysicsObject()
    if phys:IsValid() then phys:EnableMotion(false) end
    self:NextThink(CurTime())
    return true
end

function ENT:DrawTranslucent()
    if not InfMap2.Debug then return end
    render.SetColorMaterialIgnoreZ()
    local mins, maxs = self:GetCollisionBounds()
    render.DrawWireframeBox(self:GetPos(), self:GetAngles(), mins, maxs, Color(255, 255, 255), false)
    render.DrawLine(self:GetPos(), EyePos()-Vector(0, 0, 16), Color(255, 255, 255), false)
    local d2ddata = self:GetPos():ToScreen()
    if d2ddata.visible then
        local megapos = self.INF_ReferenceData.Megapos
        draw.DrawText(string.format("CCC of %s at megapos %d %d %d", self.INF_ReferenceData.Parent, megapos.x, megapos.y, megapos.z), "DermaLarge", d2ddata.x, d2ddata.y, Color(255, 255, 255))
    end
    --render.DrawBeam(self:GetPos(), EyePos()-Vector(0, 0, 16), 5, 0, 1, Color(255, 255, 255))
end

hook.Add("PhysgunPickup", "InfMap2CrossChunkClonePhysgunable", function(ply, ent)
    if ent:GetClass() == "inf_crosschunkclone" then return false end
end)