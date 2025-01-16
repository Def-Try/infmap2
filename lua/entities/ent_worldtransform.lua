AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.Category		= "World Transform"
ENT.PrintName		= "World Transform"
ENT.Author			= "googerlabs Simulation Software Developers"
ENT.Purpose			= "Transforms the world. duh."
ENT.Instructions	= "Place it. Stare at it. Dare to move it."
ENT.Spawnable		= true
ENT.RenderGroup = RENDERGROUP_OPAQUE

ENT.WorldOffset = nil
ENT.AngleOffset = nil

function ENT:Initialize()
    --if SERVER and IsValid(ents.FindByClass("ent_worldtransform")[1]) then ents.FindByClass("ent_worldtransform")[1]:Remove() end

    self:SetModel("models/editor/axis_helper.mdl")
    self:ManipulateBoneScale(0, Vector(4, 4, 4))

    self:PhysicsInitBox(Vector(-20, -20, -20), Vector(20, 20, 20))
    local phys = self:GetPhysicsObject()
    phys:EnableMotion(false)
    phys:EnableGravity(false)
    phys:SetDragCoefficient(1000)
    phys:SetDamping(1000, 1000)
    phys:SetMass(50000)
    phys:SetMaterial("Computer")
end

function ENT:Think()
    if SERVER and self:IsPlayerHolding() then return end

    if not self.WorldOffset then
        self.WorldOffset = self:GetPos()
        self.AngleOffset = self:GetAngles()
    end
        
    if CLIENT then return end

    local phys = self:GetPhysicsObject()
    local deviation = (self:GetPos() - self.WorldOffset)
    if deviation:Length() > 0.1 then
        phys:SetVelocity(phys:GetVelocity() * 0.9 + -deviation:GetNormalized() * deviation:Length())
    else
        phys:SetVelocity(Vector(0, 0, 0))
        local a = self:GetAngles()
        self:SetPos(self.WorldOffset)
        self:SetAngles(a)
        phys:EnableMotion(false)
    end
    
    local dang = self:WorldToLocalAngles(self.AngleOffset)
    phys:SetAngleVelocity(phys:GetAngleVelocity() * 0.9 + Vector(dang.r, dang.p, dang.y))

    self:NextThink(CurTime())
    return true
end

function ENT:Draw()
    self:DrawModel()
end

local pushed = false
local mtrx = Matrix()
hook.Add("RenderScene", "!!!WorldTransform", function()
    local transform = ents.FindByClass("ent_worldtransform")[1]
    if not IsValid(transform) then return end
    if not transform.WorldOffset then return end

    pushed = true

    mtrx:SetTranslation(transform:GetPos() - transform.WorldOffset)
    mtrx:SetAngles(transform:GetAngles() - transform.AngleOffset)

    cam.PushModelMatrix(mtrx, true)
end)

hook.Add("PostRender", "!!!WorldTransform", function()
    if not pushed then return end
    pushed = false
    cam.PopModelMatrix()
end)