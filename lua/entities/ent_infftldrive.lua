---@diagnostic disable: undefined-field
AddCSLuaFile()

ENT.Type        = "anim"
ENT.Base        = "base_gmodentity"

ENT.Category    = "InfMap2"
ENT.PrintName   = "FTL Drive"
ENT.Author      = "googer_"
ENT.Purpose     = "Faster-Than-Light drive"
ENT.Spawnable   = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

if not InfMap2 then return end
ENT.Spawnable = true
ENT.Editable  = true

function ENT:Initialize(ready)
    self:SetModel("models/props_lab/reciever01b.mdl")

    if SERVER then self:PhysicsInit(SOLID_VPHYSICS) end
    self:SetScale(1)
    self:SetCullTerrain(true)
    self:SetDrawTerrain(true)
    self:SetOffsetY(0)
    self:SetChunk(Vector())
    self:SetLocked(-1)
end

function ENT:SetupDataTables()
    self:NetworkVar("Float", 0, "Scale", { KeyName = "Scale", Edit = { type = "Float", order = 1, min = 0.1, max = 10 } })
    self:NetworkVar("Bool", 0, "DrawTerrain", { KeyName = "DrawTerrain", Edit = { type = "Boolean", order = 2 } })
    self:NetworkVar("Bool", 1, "CullTerrain", { KeyName = "CullTerrain", Edit = { type = "Boolean", order = 3 } })
    self:NetworkVar("Float", 1, "OffsetY", { KeyName = "OffsetY", Edit = { type = "Float", order = 4, min = -1000, max = 1000 } })
    self:NetworkVar("Vector", 0, "Chunk")
    self:NetworkVar("Float", 2, "Locked")
end

local minichunk = Vector(40, 40, 40)
local minichunk_half = minichunk / 2
local ratio = InfMap2.ChunkSize / minichunk.z

local wireframe = Material("models/wireframe")
function ENT:DrawChunkTerrain(color, angle)
    if not self:GetDrawTerrain() then return end
    local chunkent
    for _, ent in ipairs(ents.FindByClass("inf_chunk")) do
        if ent:GetMegaPos() == self:GetChunk() then
            chunkent = ent
            break
        end
    end
    if not IsValid(chunkent) then
        render.DrawWireframeBox(vector_origin, Angle(0, 0, 0), -minichunk_half / 2, minichunk_half / 2, Color(255, 0, 0),
            true)
        for i = 1, 3, 1 do
            render.DrawWireframeBox(vector_origin, Angle(RealTime() * (10 * i), RealTime() * (15 * i), RealTime() *
            (20 * i)), -minichunk_half / 4, minichunk_half / 4, Color(255, 0, 0), true)
        end
        return
    end
    render.SetMaterial(wireframe)
    local chunkmesh = chunkent.INF_ChunkMesh
    for i = 1, #chunkmesh, 6 do
        if not InfMap2.PositionInChunkSpace(chunkmesh[i]) and
            not InfMap2.PositionInChunkSpace(chunkmesh[i + 1]) and
            not InfMap2.PositionInChunkSpace(chunkmesh[i + 4]) and
            not InfMap2.PositionInChunkSpace(chunkmesh[i + 2]) then
            continue
        end
        render.DrawQuad(chunkmesh[i + 2] / ratio,
            chunkmesh[i] / ratio,
            chunkmesh[i + 1] / ratio,
            chunkmesh[i + 4] / ratio,
            color)
    end
    if self:GetCullTerrain() then return end
    for i = 1, #chunkmesh, 6 do
        if not InfMap2.PositionInChunkSpace(chunkmesh[i]) and
            not InfMap2.PositionInChunkSpace(chunkmesh[i + 1]) and
            not InfMap2.PositionInChunkSpace(chunkmesh[i + 4]) and
            not InfMap2.PositionInChunkSpace(chunkmesh[i + 2]) then
            continue
        end
        render.DrawQuad(chunkmesh[i + 2] / ratio,
            chunkmesh[i + 4] / ratio,
            chunkmesh[i + 1] / ratio,
            chunkmesh[i] / ratio,
            color)
    end
end

local color_red      = Color(255, 0, 0)
local color_green    = Color(0, 255, 0)
local color_blue     = Color(0, 0, 255)
local vector_forward = Vector(0, 1, 0)
local vector_right   = Vector(1, 0, 0)

local mtrx           = Matrix()
function ENT:DrawTranslucent(flags)
    self:DrawModel(flags)
    if self:GetPos():Distance(LocalPlayer():GetPos()) > InfMap2.ChunkSize then return end

    local c = math.random(225, 255)
    local color = Color(c, c, c)

    local center = self:GetUp() * (self:GetOffsetY() + (minichunk_half.z + 10) * self:GetScale())

    mtrx:SetAngles(self:GetAngles())
    mtrx:SetTranslation(self:GetPos() + center)
    if math.Round(util.SharedRandom("", 0, 200, RealTime() * 100)) == 0 then
        mtrx:Translate(
            Vector(
                util.SharedRandom("x", -100, 100, RealTime() * 100),
                util.SharedRandom("y", -100, 100, RealTime() * 100),
                util.SharedRandom("z", -100, 100, RealTime() * 100)
            )
        )
    end
    mtrx:SetScale(Vector(1, 1, 1) * self:GetScale())

    local downscale = 1

    if self:GetLocked() ~= -1 then
        downscale = math.max(0.8, 1 - (CurTime() - self:GetLocked()))
        mtrx:SetScale(mtrx:GetScale() * downscale)
    end
    cam.PushModelMatrix(mtrx, true)

    ---@diagnostic disable-next-line: param-type-mismatch
    render.DrawWireframeBox(vector_origin, angle_zero, -minichunk_half, minichunk_half, color, true)

    render.DrawWireframeBox(vector_origin, angle_zero, -minichunk_half / downscale, minichunk_half / downscale, color,
        true)

    render.DrawLine(vector_origin, vector_right * 8, color_red, true)     -- positive x
    render.DrawLine(vector_origin, vector_forward * 8, color_green, true) -- positive y
    render.DrawLine(vector_origin, vector_up * 8, color_blue, true)       -- positive z


    local angle = self:GetAngles()
    angle:RotateAroundAxis(angle:Forward(), 90)
    angle:RotateAroundAxis(angle:Right(), 90)

    local top = self:GetPos() + center + self:GetUp() * (self:GetOffsetY() + minichunk_half.z + 5)

    local megapos = self:GetChunk()
    local megapostext = megapos.x .. " " .. megapos.y .. " " .. megapos.z

    cam.Start3D2D(top, angle, 0.1 * self:GetScale())
        draw.SimpleText(megapostext, "DermaLarge", 0, 0, color, TEXT_ALIGN_CENTER)
    cam.End3D2D()
    -- and the other side
    angle:RotateAroundAxis(angle:Right(), 180)
    cam.Start3D2D(top, angle, 0.1 * self:GetScale())
        draw.SimpleText(megapostext, "DermaLarge", 0, 0, color, TEXT_ALIGN_CENTER)
    cam.End3D2D()

    self:DrawChunkTerrain(color, angle)

    render.DrawWireframeBox(Vector(1, 0, 0)*minichunk_half.x / downscale, angle_zero,
        Vector(0, -10, -5) / downscale, Vector(1, 10, 5) / downscale, Color(color.r, color.g-127, color.b-127, color.a),
        true)

    cam.PopModelMatrix()
end

function ENT:Think()
    if CLIENT then return end
    self:NextThink(CurTime())

    if self:GetLocked() == -1 then
    elseif CurTime() - self:GetLocked() > 6.05 then
        local selfpos = self:GetPos()
        local elevation = selfpos.z - InfMap2.World.Terrain.HeightFunction(selfpos.x, selfpos.y)
        local tppos = self:GetChunk() * InfMap2.ChunkSize
        local tpele = InfMap2.World.Terrain.HeightFunction(tppos.x, tppos.y)
        if ((tpele - tppos.z) - InfMap2.ChunkSize / 2) <= InfMap2.ChunkSize then
            tppos.z = tpele + elevation
        end
        InfMap2.Teleport(self, tppos)
        self:SetLocked(-1)
        self:EmitSound("npc/turret_floor/die.wav", 450, 70)
        self.playedsend = nil
        self.playedcharge = nil
        return true
    elseif CurTime() - self:GetLocked() > 6 and not self.playedsend then
        if self.playedsend then return true end
        self:EmitSound("ambient/levels/citadel/weapon_disintegrate2.wav")
        self.playedsend = true
        return true
    elseif CurTime() - self:GetLocked() > 5 then
        if self.playedcharge then return true end
        self:EmitSound("npc/strider/charging.wav")
        self.playedcharge = true
        return true
    end

    local closest, mindist = nil, math.huge
    local pos = self:GetPos()
    for _, ply in player.Iterator() do
        local dist = ply:GetPos():Distance(pos)
        if dist < mindist then
            closest = ply
            mindist = dist
        end
    end
    if not closest then return true end
    local frac = mindist / self:GetScale() / 100
    if frac > 1 then return true end

    local jumphitpos, jumphitnorm, jumphitfrac = util.IntersectRayWithOBB(
        closest:EyePos(), closest:GetAimVector() * 100 * self:GetScale(),
        self:GetPos() + self:GetUp() * (self:GetOffsetY() + (minichunk_half.z + 10) * self:GetScale())
        + self:GetForward()*minichunk_half.x * self:GetScale(), self:GetAngles(),
        Vector(0, -10, -5) * self:GetScale(), Vector(1, 10, 5) * self:GetScale())

    local hitpos, hitnorm, hitfrac = util.IntersectRayWithOBB(
        closest:EyePos(), closest:GetAimVector() * 100 * self:GetScale(),
        self:GetPos() + self:GetUp() * (self:GetOffsetY() + (minichunk_half.z + 10) * self:GetScale()),
        self:GetAngles(), -minichunk_half * self:GetScale(), minichunk_half * self:GetScale())
    if not closest:KeyDown(IN_USE) then return true end
    if self.cooldown and self.cooldown >= CurTime() then return true end
    self.cooldown = CurTime() + 0.25

    if not hitpos and jumphitpos or jumphitfrac and jumphitfrac < hitfrac then
        -- if closest:GetEyeTrace().Entity ~= self then return true end
        if self:GetLocked() ~= -1 then
            self:SetLocked(-1)
            self:EmitSound("buttons/button18.wav")
            return true
        end
        self:SetLocked(CurTime())
        self:EmitSound("buttons/button24.wav")
        return true
    end
    if not hitnorm then return true end
    if self:GetLocked() ~= -1 then return true end
    self:SetChunk(self:GetChunk() - hitnorm)
    self:EmitSound("buttons/button17.wav")
    return true
end
