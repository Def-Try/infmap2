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

function ENT:Initialize(ready)
    self:SetModel("models/props_lab/reciever01b.mdl")

    self:PhysicsInit(SOLID_VPHYSICS)
end

local minichunk = Vector(40, 40, 40)
local minichunk_half = minichunk / 2

local wireframe = Material("models/wireframe")
function ENT:DrawChunk(drawpos, megapos, color)
    local angle = Angle(angle_zero)
    render.DrawWireframeBox(drawpos, angle_zero, -minichunk_half, minichunk_half, color, true)
    angle:RotateAroundAxis(angle:Right(), 90)
    angle:RotateAroundAxis(angle:Up(), -90)
    angle:RotateAroundAxis(angle:Right(), (RealTime() * 10) % 360)
    drawpos.z = drawpos.z + minichunk_half.z + 2
    cam.Start3D2D(drawpos, angle, 0.1)
        local megapostext = megapos.x.." "..megapos.y.." "..megapos.z
		draw.SimpleText(megapostext, "DermaLarge", 0, 0, color, TEXT_ALIGN_CENTER)
	cam.End3D2D()
    -- and the other side
    angle:RotateAroundAxis(angle:Right(), 180)
    cam.Start3D2D(drawpos, angle, 0.1)
        local megapostext = megapos.x.." "..megapos.y.." "..megapos.z
		draw.SimpleText(megapostext, "DermaLarge", 0, 0, color, TEXT_ALIGN_CENTER)
	cam.End3D2D()
    drawpos.z = drawpos.z - minichunk_half.z - 2

    local ratio = InfMap2.ChunkSize / minichunk.z

    local chunkent = nil

    for _,ent in ents.Iterator() do
        if ent:GetMegaPos() ~= megapos then continue end
        if ent:GetClass() == "inf_chunk" then chunkent = ent continue end
        local c = math.random(107, 127)
        local r = 0.3
        local color = Color(c,c,c)
        local drawpos2 = drawpos + ent:INF_GetPos() / ratio
        if ent:IsPlayer() then color.r = color.r + 127 r = r + 0.7 end
        render.DrawWireframeSphere(drawpos2, r, 4, 4, color, true)
        if ent:IsPlayer() then
            drawpos2.z = drawpos2.z + r*2
            cam.Start3D2D(drawpos2, angle, 0.05)
                draw.SimpleText(ent:Name(), "DermaLarge", 0, 0, color, TEXT_ALIGN_CENTER)
            cam.End3D2D()
            -- and the other side
            angle:RotateAroundAxis(angle:Right(), 180)
            cam.Start3D2D(drawpos2, angle, 0.05)
                draw.SimpleText(ent:Name(), "DermaLarge", 0, 0, color, TEXT_ALIGN_CENTER)
            cam.End3D2D()
        end
    end

    if not chunkent then return end
    if not chunkent.INF_ChunkMesh then return end

    render.SetMaterial(wireframe)
    local chunkmesh = chunkent.INF_ChunkMesh
    for i=1,#chunkmesh,6 do
        if not InfMap2.PositionInChunkSpace(chunkmesh[i  ]) and
           not InfMap2.PositionInChunkSpace(chunkmesh[i+1]) and
           not InfMap2.PositionInChunkSpace(chunkmesh[i+4]) and
           not InfMap2.PositionInChunkSpace(chunkmesh[i+2]) then continue end
        render.DrawQuad(drawpos + chunkmesh[i] / ratio,
                        drawpos + chunkmesh[i+1] / ratio,
                        drawpos + chunkmesh[i+4] / ratio,
                        drawpos + chunkmesh[i+2] / ratio,
                        color)
        -- break
    end
end

function ENT:Draw(flags) self:DrawTranslucent(flags) end
function ENT:DrawTranslucent(flags)
    self:DrawModel(flags)
    local drawpos = self:GetPos() + self:GetUp() * minichunk.z
    local c = math.random(225, 255)
    local color = Color(c,c,c)
    self:DrawChunk(drawpos, self:GetMegaPos(), color)
    local chunks = {}
    for _,ply in player.Iterator() do
        chunks[ply:GetMegaPos()] = _
    end
    chunks = table.Flip(chunks)
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
        local drawpos = self:GetPos() + self:GetUp() * minichunk.z + (offset * minichunk.z)
        self:DrawChunk(drawpos, chunk, color)
    end
    self:INF_SetRenderBoundsWS(vector_origin, vector_origin, InfMap2.SourceBounds)
end
