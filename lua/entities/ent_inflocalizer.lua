---@diagnostic disable: undefined-field
AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.Category		= "InfMap2"
ENT.PrintName		= "Localizer"
ENT.Author			= "googer_"
ENT.Purpose			= "Entity to localize players or other entities on an infmap."
ENT.Spawnable		= false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

if not InfMap2 then return end
ENT.Spawnable		= true
ENT.Editable        = true

function ENT:Initialize(ready)
    self:SetModel("models/props_lab/reciever01b.mdl")

    if SERVER then self:PhysicsInit(SOLID_VPHYSICS) end
    self:SetScale(1)
    self:SetCullTerrain(true)
    self:SetDrawTerrain(true)
    self:SetOffsetY(0)
end

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "Scale",         {KeyName="Scale",       Edit={type="Float",   order=1, min=0.1, max=10}})
    self:NetworkVar("Bool",  0, "DrawTerrain",   {KeyName="DrawTerrain", Edit={type="Boolean", order=2}})
	self:NetworkVar("Bool",  1, "CullTerrain",   {KeyName="CullTerrain", Edit={type="Boolean", order=3}})
	self:NetworkVar("Float", 1, "OffsetY",       {KeyName="OffsetY",     Edit={type="Float",   order=4, min=-1000, max=1000}})
end

local scale
local minichunk
local minichunk_half
local ratio

local ents_blocked = {
    ["class C_BaseFlex"]=true,
    ["class C_PlayerResource"]=true,
    ["class C_GMODGameRulesProxy"]=true,
    ["class C_Sun"]=true,
    ["class C_ShadowControl"]=true,
    ["class C_FogController"]=true,
    env_skypaint=true,
    viewmodel=true,
    gmod_hands=true,
    physgun_beam=true,
    worldspawn=true
}

function ENT:DrawTerrain(drawpos, mesh_, checkpos, color)
    for i=1,#mesh_,6 do
        if checkpos and
           not InfMap2.PositionInChunkSpace(mesh_[i  ]) and
           not InfMap2.PositionInChunkSpace(mesh_[i+1]) and
           not InfMap2.PositionInChunkSpace(mesh_[i+4]) and
           not InfMap2.PositionInChunkSpace(mesh_[i+2]) then continue end
        render.DrawQuad(drawpos + mesh_[i+2] / ratio,
                        drawpos + mesh_[i] / ratio,
                        drawpos + mesh_[i+1] / ratio,
                        drawpos + mesh_[i+4] / ratio,
                        color)
    end
    if self:GetCullTerrain() then return end
    for i=1,#mesh_,6 do
        if checkpos and
           not InfMap2.PositionInChunkSpace(mesh_[i  ]) and
           not InfMap2.PositionInChunkSpace(mesh_[i+1]) and
           not InfMap2.PositionInChunkSpace(mesh_[i+4]) and
           not InfMap2.PositionInChunkSpace(mesh_[i+2]) then continue end
        render.DrawQuad(drawpos + mesh_[i+2] / ratio,
                        drawpos + mesh_[i+4] / ratio,
                        drawpos + mesh_[i+1] / ratio,
                        drawpos + mesh_[i] / ratio,
                        color)
    end
end

local wireframe = Material("models/wireframe")
function ENT:DrawChunk(drawpos, megapos, chunkent, angle, color, entstodraw)
    drawpos.z = drawpos.z + self:GetOffsetY()
    ---@diagnostic disable-next-line: param-type-mismatch
    render.DrawWireframeBox(drawpos, angle_zero, -minichunk_half, minichunk_half, color, true)
    drawpos.z = drawpos.z + minichunk_half.z + 2
    cam.Start3D2D(drawpos, angle, 0.1 * scale)
        local megapostext = megapos.x.." "..megapos.y.." "..megapos.z
		draw.SimpleText(megapostext, "DermaLarge", 0, 0, color, TEXT_ALIGN_CENTER)
	cam.End3D2D()
    -- and the other side
    angle:RotateAroundAxis(angle:Right(), 180)
    cam.Start3D2D(drawpos, angle, 0.1 * scale)
        local megapostext = megapos.x.." "..megapos.y.." "..megapos.z
		draw.SimpleText(megapostext, "DermaLarge", 0, 0, color, TEXT_ALIGN_CENTER)
	cam.End3D2D()
    drawpos.z = drawpos.z - minichunk_half.z - 2

    local c, r, color
    for _, ent in ipairs(entstodraw) do
        if not ent:IsPlayer() and (ents_blocked[ent:GetClass()] or ent:EntIndex() == -1 or IsValid(ent:GetParent())) then continue end
        angle:RotateAroundAxis(angle:Right(), ent:EntIndex() * 10)
        c = math.random(157, 177)
        r = 0.5 * scale
        color = Color(c,c,c)
        local drawpos2 = drawpos + ent:INF_GetPos() / ratio
        if ent:IsPlayer() then color.r = color.r + 78 r = r + 0.7 * scale end
        render.DrawWireframeSphere(drawpos2, r, 4, 4, color, true)
        drawpos2.z = drawpos2.z + (math.sin(RealTime()+ent:EntIndex()*5)+1)/2
        if ent:IsPlayer() then
            render.DrawLine(drawpos2, drawpos2 + ent:EyeAngles():Forward() * 5 * scale, Color(255, 0, 0), true)
            render.DrawLine(drawpos2, drawpos2 + ent:GetVelocity() / 100 * scale, Color(0, 0, 255), true)
            drawpos2.z = drawpos2.z + r*2
            cam.Start3D2D(drawpos2, angle, 0.05 * scale)
                draw.SimpleText(ent:Name(), "DermaLarge", 0, 0, color, TEXT_ALIGN_CENTER)
            cam.End3D2D()
            -- and the other side
            angle:RotateAroundAxis(angle:Right(), 180)
            cam.Start3D2D(drawpos2, angle, 0.05 * scale)
                draw.SimpleText(ent:Name(), "DermaLarge", 0, 0, color, TEXT_ALIGN_CENTER)
            cam.End3D2D()
        elseif ent:GetClass() == "inf_planet" then
            c = math.random(200, 255)
            color = Color(c, c, c)
            local e = (RealTime()*2+ent:EntIndex()*5) % 8
            render.DrawWireframeSphere(drawpos, ent.INF_PlanetData.Radius / ratio * scale, 8 + e, 8 + e, color)
            if ent.INF_PlanetMesh then
                render.SetMaterial(wireframe)
                self:DrawTerrain(drawpos, ent.INF_PlanetMesh, false, color)
            end
        else
            drawpos2.z = drawpos2.z + r*2
            cam.Start3D2D(drawpos2, angle, 0.05 * scale)
                draw.SimpleText("["..ent:GetClass().." "..ent:EntIndex().."]", "DermaLarge", 0, 0, color, TEXT_ALIGN_CENTER)
            cam.End3D2D()
            -- and the other side
            angle:RotateAroundAxis(angle:Right(), 180)
            cam.Start3D2D(drawpos2, angle, 0.05 * scale)
                draw.SimpleText("["..ent:GetClass().." "..ent:EntIndex().."]", "DermaLarge", 0, 0, color, TEXT_ALIGN_CENTER)
            cam.End3D2D()
        end
        angle:RotateAroundAxis(angle:Right(), -ent:EntIndex() * 10)
    end
    c = math.random(200, 255)
    color = Color(c,c,c)

    if not chunkent then return end
    if not chunkent.INF_ChunkMesh then return end

    if not self:GetDrawTerrain() then return end
    render.SetMaterial(wireframe)
    
    self:DrawTerrain(drawpos, chunkent.INF_ChunkMesh, true, color)
end

local color_red   = Color(255, 0, 0)
local color_green = Color(0, 255, 0)
local color_blue  = Color(0, 0, 255)
local vector_forward = Vector(0, 1, 0)
local vector_right = Vector(1, 0, 0)

function ENT:DrawTranslucent(flags)
    self:DrawModel(flags)
    if self:GetPos():Distance(LocalPlayer():GetPos()) > InfMap2.ChunkSize then return end
    --do return self:DrawModel(flags) end
    if scale ~= self:GetScale() then
        scale = self:GetScale()

        minichunk = Vector(40, 40, 40) * scale
        minichunk_half = minichunk / 2

        ratio = InfMap2.ChunkSize / minichunk.z
    end

    local angle = Angle(angle_zero)
    angle:RotateAroundAxis(angle:Right(), 90)
    angle:RotateAroundAxis(angle:Up(), -90)
    angle:RotateAroundAxis(angle:Right(), (RealTime() * 10) % 360)
    local drawpos = self:GetPos() + self:GetUp() * minichunk_half.z

    render.DrawLine(drawpos, drawpos + vector_right   * 8 * scale, color_red,   true) -- positive x
    render.DrawLine(drawpos, drawpos + vector_forward * 8 * scale, color_green, true) -- positive y
    render.DrawLine(drawpos, drawpos + vector_up      * 8 * scale, color_blue,  true) -- positive z

    local c = math.random(225, 255)
    local color = Color(c,c,c)
    local chunks, exists, chunkents, entstodraw = {}, {}, {}, {}
    local i = 0
    for _,ent in ents.Iterator() do
        if ent:GetClass() == "inf_chunk" then chunkents[tostring(ent:GetMegaPos())] = ent continue end
        if not exists[tostring(ent:GetMegaPos())] then
            i = i + 1
            chunks[ent:GetMegaPos()] = i
        end
        exists[tostring(ent:GetMegaPos())] = true
        local etd = entstodraw[tostring(ent:GetMegaPos())] or {}
        entstodraw[tostring(ent:GetMegaPos())] = etd

        etd[#etd+1] = ent
    end

    self:DrawChunk(drawpos, self:GetMegaPos(), chunkents[tostring(self:GetMegaPos())], angle, color, entstodraw[tostring(self:GetMegaPos())])

    chunks = table.Flip(chunks)
    table.sort(chunks, function(a, b)
        if not a then return false end
        return a:Length() < b:Length()
    end)
    local usedoffsets = {[tostring(vector_origin)]=true}
    for _,chunk in ipairs(chunks) do
        local realoffset = chunk - self:GetMegaPos()
        local offset = Vector()
        while realoffset ~= vector_origin and usedoffsets[tostring(offset)] do
            if realoffset.x < 0 then
                offset.x = offset.x - 1
                realoffset.x = realoffset.x + 1
            elseif realoffset.x > 0 then
                offset.x = offset.x + 1
                realoffset.x = realoffset.x - 1
            end
            if realoffset.y < 0 then
                offset.y = offset.y - 1
                realoffset.y = realoffset.y + 1
            elseif realoffset.y > 0 then
                offset.y = offset.y + 1
                realoffset.y = realoffset.y - 1
            end
            if realoffset.z < 0 then
                offset.z = offset.z - 1
                realoffset.z = realoffset.z + 1
            elseif realoffset.z > 0 then
                offset.z = offset.z + 1
                realoffset.z = realoffset.z - 1
            end
        end
        if chunk == self:GetMegaPos() then continue end
        usedoffsets[tostring(offset)] = true
        local drawpos = self:GetPos() + self:GetUp() * minichunk_half.z + (offset * minichunk.z)
        self:DrawChunk(drawpos, chunk, chunkents[tostring(chunk)], angle, color, entstodraw[tostring(chunk)])
    end
    self:INF_SetRenderBoundsWS(vector_origin, vector_origin, InfMap2.SourceBounds)
end