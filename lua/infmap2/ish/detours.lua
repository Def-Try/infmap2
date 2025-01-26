AddCSLuaFile()

local ENTITY = FindMetaTable("Entity")
local VEHICLE = FindMetaTable("Vehicle")
local PHYSOBJ = FindMetaTable("PhysObj")

InfMap2.TraceLine = InfMap2.TraceLine or util.TraceLine
InfMap2.TraceHull = InfMap2.TraceHull or util.TraceHull
InfMap2.TraceEntity = InfMap2.TraceEntity or util.TraceEntity
InfMap2.TraceEntityHull = InfMap2.TraceEntityHull or util.TraceEntityHull

local planes = {
    Vector(0, 0, -1), Vector(0, 0, 1),
    Vector(-1, 0, 0), Vector(1, 0, 0),
    Vector(0, -1, 0), Vector(0, 1, 0)
}

local function generate_filter_function(offset, filter)
    if isfunction(filter) then return function(e)
        if e:GetMegaPos()~= offset then return false end
        if e:GetClass() == "inf_chunk" then e = game.GetWorld() end
        return filter(e)
    end end
    if istable(filter) then return function(e)
        if e:GetMegaPos()~= offset then return false end
        if e:GetClass() == "inf_chunk" then e = game.GetWorld() end
        return not (table.HasValue(filter, e) or table.HasValue(filter, e:GetClass()))
    end end
    if isentity(filter) then return function(e)
        if e:GetMegaPos()~= offset then return false end
        if e:GetClass() == "inf_chunk" then e = game.GetWorld() end
        return e ~= filter
    end end
    if isstring(filter) then return function(e)
        if e:GetMegaPos()~= offset then return false end
        if e:GetClass() == "inf_chunk" then e = game.GetWorld() end
        return e:GetClass() == filter
    end end
    return function(e)
        return e:GetMegaPos()== offset
    end
end

local function find_chunk_hit_plane(direction, startpos)
    local mindist = math.huge
    local endplane = Vector()
    local endpos = Vector()

    for _,plane in ipairs(planes) do
        if plane:Dot(direction) < 0 then continue end
        local hitpos = util.IntersectRayWithPlane(startpos, direction, plane*InfMap2.ChunkSize/2, plane)
        if not hitpos then continue end
        if (hitpos - startpos):Length() >= mindist then continue end
        endpos = hitpos
        mindist = (hitpos - startpos):Length()
        endplane = plane
    end

    return mindist, endpos, endplane
end

local function tracefunc(fake, real, tracedata)
    tracedata.INF_TraceInfo = tracedata.INF_TraceInfo or {}
    local direction = (tracedata.endpos - tracedata.start):GetNormalized()
    local length = (tracedata.start - tracedata.endpos):Length()
    local real_start_pos, real_start_offset = InfMap2.LocalizePosition(tracedata.start)
    local _, real_end_offset = InfMap2.LocalizePosition(tracedata.endpos)
    local filter = tracedata.filter
    local data = table.Copy(tracedata)

    data.filter = generate_filter_function(real_start_offset, filter)

    data.start = real_start_pos
    data.endpos = data.start + direction * length

    local report = {}
    tracedata.INF_TraceInfo[#tracedata.INF_TraceInfo+1] = report

	local hit_data

    if real_start_offset ~= real_end_offset then
        -- cross chunk trace, possible hit canditates from other chunks
        local mindist, endpos, endplane = find_chunk_hit_plane(direction, real_start_pos)
        report.crosschunk = {
            mindist=mindist,
            endpos=endpos,
            endplane=endplane,
        }

        local newdata = table.Copy(tracedata)
        newdata.INF_TraceInfo = tracedata.INF_TraceInfo
        newdata.INF_DoNotHandleEntities = true
        newdata.start = endpos + -endplane*InfMap2.ChunkSize + direction -- in another chunk
        newdata.endpos = newdata.start + direction * math.max(0, length - mindist - 1)

        newdata.start = InfMap2.UnlocalizePosition(newdata.start, real_start_offset + endplane)
        newdata.endpos = InfMap2.UnlocalizePosition(newdata.endpos, real_start_offset + endplane)

        hit_data = fake(newdata)
        hit_data.Fraction = (tracedata.start - hit_data.HitPos):Length() / length
        report.crosschunk.hit_data = hit_data
        report.crosschunk.dist = (tracedata.start - hit_data.HitPos):Length()
    end
    report.real = {}

    local hit_data2 = real(data)
    if hit_data2.Hit and (not hit_data or hit_data2.Fraction <= hit_data.Fraction) then
        hit_data = hit_data2
        hit_data.HitPos = InfMap2.UnlocalizePosition(hit_data.HitPos, real_start_offset)
    end
    report.real.hit_data = hit_data2

    report.real.dist = (tracedata.start - hit_data2.HitPos):Length()

    if hit_data and (IsValid(hit_data.Entity) or hit_data.Entity:IsWorld()) and not tracedata.INF_DoNotHandleEntities then
        local ent = hit_data.Entity
        if ent:GetClass() == "inf_chunk" then -- hit the inf_chunk, the world terrain
            hit_data.Entity = game.GetWorld()
            hit_data.HitWorld = true
            hit_data.HitNonWorld = false -- wtf garry
        end
        if ent:GetClass() == "inf_crosschunkclone" then -- hit crosschunk clone, lie about hitting some entity
            ---@diagnostic disable-next-line: undefined-field
            hit_data.Entity = hit_data.Entity.INF_ReferenceData.Parent
        end
        if ent:IsWorld() then -- directly hit the world, meaning that something is really far away
            hit_data = nil
        end
    end

    --if hit_data then
    --    hit_data.HitPos = hit_data.HitPos + hit_data.HitNormal * 20 -- spawning props sometimes clip through
    --end

    if hit_data and hit_data.Hit then
        hit_data.Fraction = (tracedata.start - hit_data.HitPos):Length() / length
    end

	return hit_data or {
        Entity = NULL,
        Fraction = 1,
        FractionLeftSolid = 0,
        Hit = false,
        HitBox = 0,
        HitGroup = 0,
        HitNoDraw = false,
        HitNonWorld = false,
        HitNormal = Vector(0, 0, 0),
        HitPos = tracedata.endpos,
        HitSky = false,
        HitTexture = "** empty **",
        HitWorld = false,
        MatType = 0,
        Normal = direction,
        PhysicsBone = 0,
        StartPos = tracedata.start,
        SurfaceProps = 0,
        StartSolid = false,
        AllSolid = false,
        SurfaceFlags = 0,
        DispFlags = 0,
        Contents = CONTENTS_EMPTY
    }
end

local function generate_trace_function(real)
    local func
    func = function(tracedata)
        return tracefunc(func, real, tracedata)
    end
    return func
end

----- Trace detours -----

util.TraceLine = generate_trace_function(InfMap2.TraceLine)
util.TraceHull = generate_trace_function(InfMap2.TraceHull)
util.TraceEntity = generate_trace_function(InfMap2.TraceEntity)
util.TraceEntityHull = generate_trace_function(InfMap2.TraceEntityHull)

----- Entity detours -----

--function ENTITY:SetMegaPos(vec) return IsValid(self) and self:SetDTVector(31, vec) end
--function ENTITY:GetMegaPos() return IsValid(self) and self:GetDTVector(31) or Vector() end\

ENTITY.INF_GetPos = ENTITY.INF_GetPos or ENTITY.GetPos
function ENTITY:GetPos()
	return InfMap2.UnlocalizePosition(self:INF_GetPos(), self:GetMegaPos() or Vector())
end

ENTITY.INF_SetPos = ENTITY.INF_SetPos or ENTITY.SetPos
function ENTITY:SetPos(pos)
	local pos, megapos = InfMap2.LocalizePosition(pos)
    if megapos ~= self:GetMegaPos()then
        InfMap2.EntityUpdateMegapos(self, megapos)
    end
	return self:INF_SetPos(pos)
end

ENTITY.INF_WorldSpaceAABB = ENTITY.INF_WorldSpaceAABB or ENTITY.WorldSpaceAABB
function ENTITY:WorldSpaceAABB()
    local aa, bb = self:INF_WorldSpaceAABB()
    return InfMap2.UnlocalizePosition(aa, self:GetMegaPos()), InfMap2.UnlocalizePosition(bb, self:GetMegaPos())
end

ENTITY.INF_EyePos = ENTITY.INF_EyePos or ENTITY.EyePos
function ENTITY:EyePos()
    return InfMap2.UnlocalizePosition(self:INF_EyePos(), self:GetMegaPos())
end

ENTITY.INF_LocalToWorld = ENTITY.INF_LocalToWorld or ENTITY.LocalToWorld
function ENTITY:LocalToWorld(pos)
	return InfMap2.UnlocalizePosition(self:INF_LocalToWorld(pos), self:GetMegaPos())
end

ENTITY.INF_WorldToLocal = ENTITY.INF_WorldToLocal or ENTITY.WorldToLocal
function ENTITY:WorldToLocal(pos)
	return self:INF_WorldToLocal(-InfMap2.UnlocalizePosition(-pos, self:GetMegaPos()))
end

ENTITY.INF_NearestPoint = ENTITY.INF_NearestPoint or ENTITY.NearestPoint
function ENTITY:NearestPoint(pos)
	local chunk_pos, chunk_offset = InfMap2.LocalizePosition(pos)
	return InfMap2.UnlocalizePosition(self:INF_NearestPoint(chunk_pos), chunk_offset)
end

ENTITY.INF_GetAttachment = ENTITY.INF_GetAttachment or ENTITY.GetAttachment
function ENTITY:GetAttachment(num)
	local data = self:INF_GetAttachment(num)
	if !data or !data.Pos then return data end
	data.Pos = InfMap2.UnlocalizePosition(data.Pos, self:GetMegaPos())
	return data
end

ENTITY.INF_GetBonePosition = ENTITY.INF_GetBonePosition or ENTITY.GetBonePosition
function ENTITY:GetBonePosition(index)
	local pos, ang = self:INF_GetBonePosition(index)
	pos = InfMap2.UnlocalizePosition(pos, self:GetMegaPos())
	return pos, ang
end

----- Vehicle detours -----

-- GetPos, LocalToWorld, WorldToLocal are derived from ENTITY
VEHICLE.INF_SetPos = VEHICLE.INF_SetPos or VEHICLE.SetPos
function VEHICLE:SetPos(pos)
	local pos, megapos = InfMap2.LocalizePosition(pos)
    if megapos ~= self:GetMegaPos()then
        InfMap2.EntityUpdateMegapos(self, megapos)
    end
	return self:INF_SetPos(pos)
end

----- PhysObj detours -----

PHYSOBJ.INF_SetPos = PHYSOBJ.INF_SetPos or PHYSOBJ.SetPos
PHYSOBJ.INF_GetPos = PHYSOBJ.INF_GetPos or PHYSOBJ.GetPos