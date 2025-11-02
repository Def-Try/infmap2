AddCSLuaFile()

local ENTITY = FindMetaTable("Entity")
local VEHICLE = FindMetaTable("Vehicle")
local PHYSOBJ = FindMetaTable("PhysObj")
local PLAYER = FindMetaTable("Player")
local NEXTBOT = FindMetaTable("NextBot")
local CTAKEDAMAGEINFO = FindMetaTable("CTakeDamageInfo")
if not ENTITY then return end
if not VEHICLE then return end
if not PHYSOBJ then return end
if not PLAYER then return end
if not NEXTBOT then return end
if not CTAKEDAMAGEINFO then return end

util.INF_TraceLine = util.INF_TraceLine or util.TraceLine
util.INF_TraceHull = util.INF_TraceHull or util.TraceHull
util.INF_TraceEntity = util.INF_TraceEntity or util.TraceEntity
util.INF_TraceEntityHull = util.INF_TraceEntityHull or util.TraceEntityHull

local planes = {
    Vector(0, 0, -1), Vector(0, 0, 1),
    Vector(-1, 0, 0), Vector(1, 0, 0),
    Vector(0, -1, 0), Vector(0, 1, 0)
}

local function generate_filter_function(offset, filter)
    local world = game.GetWorld()
    if isfunction(filter) then return function(e)
        if e:GetMegaPos() ~= offset then return false end
        local klass = e:GetClass()
        if klass == "inf_chunk" then e = world end
        if klass == "inf_crosschunkclone" then e = e.INF_ReferenceData.Parent if not e or not e:IsValid() then return false end end
        return filter(e)
    end end
    if istable(filter) then return function(e)
        if e:GetMegaPos() ~= offset then return false end
        local klass = e:GetClass()
        if klass == "inf_chunk" then e = world end
        if klass == "inf_crosschunkclone" then e = e.INF_ReferenceData.Parent if not e or not e:IsValid() then return false end end
        return not (table.HasValue(filter, e) or table.HasValue(filter, e:GetClass()))
    end end
    if isentity(filter) then return function(e)
        if e:GetMegaPos() ~= offset then return false end
        local klass = e:GetClass()
        if klass == "inf_chunk" then e = world end
        if klass == "inf_crosschunkclone" then e = e.INF_ReferenceData.Parent if not e or not e:IsValid() then return false end end
        return e ~= filter
    end end
    if isstring(filter) then return function(e)
        if e:GetMegaPos() ~= offset then return false end
        local klass = e:GetClass()
        if klass == "inf_chunk" then e = world end
        if klass == "inf_crosschunkclone" then e = e.INF_ReferenceData.Parent if not e or not e:IsValid() then return false end end
        return e:GetClass() == filter
    end end
    return function(e)
        return e:GetMegaPos() == offset
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
    local length = math.min((tracedata.start - tracedata.endpos):Length(),
                            InfMap2.ChunkSize * 6)
                            -- limit incase someone tries to trace 10 BAJILLION UNITS
                            -- (looking at you wiremod)
    local real_start_pos, real_start_offset = InfMap2.LocalizePosition(tracedata.start)
    local _, real_end_offset = InfMap2.LocalizePosition(tracedata.endpos)
    local filter = tracedata.filter
    local data = {
        start = Vector(tracedata.start),
        endpos = Vector(tracedata.endpos),
        maxs = tracedata.maxs and Vector(tracedata.maxs),
        mins = tracedata.mins and Vector(tracedata.mins),
        filter = generate_filter_function(real_start_offset, filter),
        mask = tracedata.mask,
        collisiongroup = tracedata.collisiongroup,
        ignoreworld = tracedata.ignoreworld,
        output = tracedata.output,
        whitelist = tracedata.whitelist,
        hitclientonly = tracedata.hitclientonly,
        INF_TraceInfo = tracedata.INF_TraceInfo,
        INF_DoNotHandleEntities = tracedata.INF_DoNotHandleEntities,
    }

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

        local newdata = {
            start = endpos + -endplane*InfMap2.ChunkSize + direction, -- in another chunk
            endpos = endpos + -endplane*InfMap2.ChunkSize + direction * math.max(0, length - mindist - 1),
            filter = tracedata.filter, -- we're calling recursively, provide original filter
            mask = tracedata.mask,
            collisiongroup = tracedata.collisiongroup,
            ignoreworld = tracedata.ignoreworld,
            whitelist = tracedata.whitelist,
            hitclientonly = tracedata.hitclientonly,
            INF_TraceInfo = tracedata.INF_TraceInfo,
            INF_DoNotHandleEntities = true,
            INF_RealStartPos = (tracedata.INF_RealStartPos or tracedata.start)
        }
        newdata.start = InfMap2.UnlocalizePosition(newdata.start, real_start_offset + endplane)
        newdata.endpos = InfMap2.UnlocalizePosition(newdata.endpos, real_start_offset + endplane)

        --debugoverlay.Line(data.start, report.crosschunk.endpos, 0.1, Color(255, 255, 255), true)
        --debugoverlay.Cross(report.crosschunk.endpos, 50, 0.1, Color(255, 0, 0), true)
        --debugoverlay.Line(newdata.start, newdata.endpos, 0.1, Color(0, 255, 0), true)

        -- max crosstrace 6 chunks
        -- otherwise we can end up with SOMEONE (*ahem* wiremod *ahem*) tracing two bajillion units far and crashing us
        if (newdata.endpos - newdata.INF_RealStartPos):Length() < InfMap2.ChunkSize * 6 then
            hit_data = fake(newdata)
            hit_data.Fraction = (tracedata.start - hit_data.HitPos):Length() / length
            report.crosschunk.hit_data = hit_data
            report.crosschunk.dist = (tracedata.start - hit_data.HitPos):Length()
        end
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

    if hit_data then
        hit_data.StartPos = tracedata.start
        if hit_data.Hit then
            hit_data.Fraction = (hit_data.StartPos - hit_data.HitPos):Length() / length
            hit_data.Normal = (hit_data.HitPos - hit_data.StartPos):GetNormalized()

            --hit_data.HitPos = hit_data.HitPos + hit_data.HitNormal * 20
        end
    end

    hit_data = hit_data or {
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

    if tracedata.output then
        table.Add(tracedata.output, hit_data)
        return nil
    end

	return hit_data
end

local function generate_trace_function(real)
    local func
    func = function(tracedata)
        return tracefunc(func, real, tracedata)
    end
    return func
end

----- Trace detours -----

util.TraceLine = generate_trace_function(util.INF_TraceLine)
util.TraceHull = generate_trace_function(util.INF_TraceHull)
util.TraceEntity = generate_trace_function(util.INF_TraceEntity)
util.TraceEntityHull = generate_trace_function(util.INF_TraceEntityHull)

----- Entity detours -----

-- moved to positioning
--function ENTITY:SetMegaPos(vec) return IsValid(self) and self:SetDTVector(31, vec) end
--function ENTITY:GetMegaPos() return IsValid(self) and self:GetDTVector(31) or Vector() end

ENTITY.INF_GetPos = ENTITY.INF_GetPos or ENTITY.GetPos
function ENTITY:GetPos()
	return InfMap2.UnlocalizePosition(self:INF_GetPos(), self:GetMegaPos() or Vector())
end

ENTITY.INF_SetPos = ENTITY.INF_SetPos or ENTITY.SetPos
function ENTITY:SetPos(pos)
	local pos, megapos = InfMap2.LocalizePosition(pos)
    if megapos ~= self:GetMegaPos() then
        InfMap2.EntityUpdateMegapos(self, megapos)
        -- teleport parented entities. genuiely hate this
        for _, ent in ents.Iterator() do
            if ent:GetParent() ~= self then continue end
            InfMap2.EntityUpdateMegapos(ent, megapos)
        end
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
function ENTITY:LocalToWorld(position)
    return InfMap2.UnlocalizePosition(self:INF_LocalToWorld(position), self:GetMegaPos())
end

ENTITY.INF_WorldToLocal = ENTITY.INF_WorldToLocal or ENTITY.WorldToLocal
function ENTITY:WorldToLocal(position)
    local main = self:GetPos()
    local offset = position - main
    local pos, _ = InfMap2.LocalizePosition(main)
    return self:INF_WorldToLocal(pos + offset)
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

ENTITY.INF_SetParent = ENTITY.INF_SetParent or ENTITY.SetParent
function ENTITY:SetParent(parent, attachmentOrBoneId)
    if not IsValid(parent) then
        return self:INF_SetParent(parent, attachmentOrBoneId)
    end
    if InfMap2.UselessEntitiesFilter(self) then
        return self:INF_SetParent(parent, attachmentOrBoneId)
    end
    local localpos = InfMap2.UnlocalizePosition(self:INF_GetPos(), self:GetMegaPos() - parent:GetMegaPos())
    self:INF_SetPos(localpos)
    self:SetMegaPos(parent:GetMegaPos())
    return self:INF_SetParent(parent, attachmentOrBoneId)
end

ENTITY.INF_GetBoneMatrix = ENTITY.INF_GetBoneMatrix or ENTITY.GetBoneMatrix
function ENTITY:GetBoneMatrix(boneId)
    local mtrx = self:INF_GetBoneMatrix(boneId)
    if not mtrx then mtrx = Matrix() end
    mtrx:SetTranslation(mtrx:GetTranslation() + self:GetMegaPos() * InfMap2.ChunkSize)
    return mtrx
end

ENTITY.INF_GetBonePosition = ENTITY.INF_GetBonePosition or ENTITY.GetBonePosition
function ENTITY:GetBonePosition(boneId)
    local pos, ang = self:INF_GetBonePosition(boneId)
    pos = pos + self:GetMegaPos() * InfMap2.ChunkSize
    return pos, ang
end

----- Vehicle detours -----

-- GetPos, LocalToWorld, WorldToLocal are derived from ENTITY
VEHICLE.INF_SetPos = VEHICLE.INF_SetPos or VEHICLE.SetPos
function VEHICLE:SetPos(pos)
	local pos, megapos = InfMap2.LocalizePosition(pos)
    if megapos ~= self:GetMegaPos() then
        InfMap2.EntityUpdateMegapos(self, megapos)
    end
	return self:INF_SetPos(pos)
end

----- PhysObj detours -----

PHYSOBJ.INF_GetPos = PHYSOBJ.INF_GetPos or PHYSOBJ.GetPos
function PHYSOBJ:GetPos()
	return InfMap2.UnlocalizePosition(self:INF_GetPos(), self:GetEntity():GetMegaPos() or Vector())
end

PHYSOBJ.INF_SetPos = PHYSOBJ.INF_SetPos or PHYSOBJ.SetPos
function PHYSOBJ:SetPos(pos, teleport)
	local pos, megapos = InfMap2.LocalizePosition(pos)
    if megapos ~= self:GetEntity():GetMegaPos() then
        InfMap2.EntityUpdateMegapos(self:GetEntity(), megapos)
    end
	return self:INF_SetPos(pos, teleport)
end

PHYSOBJ.INF_ApplyForceOffset = PHYSOBJ.INF_ApplyForceOffset or PHYSOBJ.ApplyForceOffset
function PHYSOBJ:ApplyForceOffset(impulse, position)
    local main = self:GetEntity():GetPos()
    local offset = position - main
    local pos, _ = InfMap2.LocalizePosition(main)
    return self:INF_ApplyForceOffset(impulse, pos + offset)
end

PHYSOBJ.INF_LocalToWorld = PHYSOBJ.INF_LocalToWorld or PHYSOBJ.LocalToWorld
function PHYSOBJ:LocalToWorld(position)
    return InfMap2.UnlocalizePosition(self:INF_LocalToWorld(position), self:GetEntity():GetMegaPos())
end

PHYSOBJ.INF_CalculateVelocityOffset = PHYSOBJ.INF_CalculateVelocityOffset or PHYSOBJ.CalculateVelocityOffset
function PHYSOBJ:CalculateVelocityOffset(impulse, position)
    local main = self:GetEntity():GetPos()
    local offset = position - main
    local pos, _ = InfMap2.LocalizePosition(main)
    return self:INF_CalculateVelocityOffset(impulse, pos + offset)
end

PHYSOBJ.INF_WorldToLocal = PHYSOBJ.INF_WorldToLocal or PHYSOBJ.WorldToLocal
function PHYSOBJ:WorldToLocal(position)
    local main = self:GetEntity():GetPos()
    local offset = position - main
    local pos, _ = InfMap2.LocalizePosition(main)
    return self:INF_WorldToLocal(pos + offset)
end

PHYSOBJ.INF_GetVelocityAtPoint = PHYSOBJ.INF_GetVelocityAtPoint or PHYSOBJ.GetVelocityAtPoint
function PHYSOBJ:GetVelocityAtPoint(position)
    local main = self:GetEntity():GetPos()
    local offset = position - main
    local pos, _ = InfMap2.LocalizePosition(main)

    return self:INF_GetVelocityAtPoint(pos + offset)
end

PHYSOBJ.INF_CalculateForceOffset = PHYSOBJ.INF_CalculateForceOffset or PHYSOBJ.CalculateForceOffset
function PHYSOBJ:CalculateForceOffset(impulse, position)
    local main = self:GetEntity():GetPos()
    local offset = position - main
    local pos, _ = InfMap2.LocalizePosition(main)
    return self:INF_CalculateForceOffset(impulse, pos + offset)
end

PHYSOBJ.INF_SetMaterial = PHYSOBJ.INF_SetMaterial or PHYSOBJ.SetMaterial
function PHYSOBJ:SetMaterial(mat) -- if mat is set it will seperate qphysics and vphysics on chunk entities, disable it
	if not IsValid(self:GetEntity()) then return end
    if InfMap2.DisablePickup[self:GetEntity():GetClass()] then return end
	return self:INF_SetMaterial(mat)
end

----- Player detours -----

PLAYER.INF_GetShootPos = PLAYER.INF_GetShootPos or PLAYER.GetShootPos
function PLAYER:GetShootPos()
	return InfMap2.UnlocalizePosition(self:INF_GetShootPos(), self:GetMegaPos())
end

----- Nextbot detours -----

NEXTBOT.INF_GetRangeSquaredTo = NEXTBOT.INF_GetRangeSquaredTo or NEXTBOT.GetRangeSquaredTo
function NEXTBOT:GetRangeSquaredTo(to)
	if isentity(to) then to = to:GetPos() end
	return self:GetPos():DistToSqr(to)
end

NEXTBOT.INF_GetRangeTo = NEXTBOT.INF_GetRangeTo or NEXTBOT.GetRangeTo
function NEXTBOT:GetRangeTo(to)
	return math.sqrt(self:GetRangeSquaredTo(to))
end

----- CTakeDamageInfo detours -----

CTAKEDAMAGEINFO.INF_GetDamagePosition = CTAKEDAMAGEINFO.INF_GetDamagePosition or CTAKEDAMAGEINFO.GetDamagePosition
function CTAKEDAMAGEINFO:GetDamagePosition()
	local inflictor = self:GetInflictor()
	if not IsValid(inflictor) then 
		inflictor = game.GetWorld()
	end
	return InfMap2.UnlocalizePosition(self:INF_GetDamagePosition(), inflictor:GetMegaPos())
end


----- WireMod detours -----
timer.Simple(0, function() -- delay by one tick because we run before wirelib initialized
    WireLib = WireLib or nil -- make luals happy
    if WireLib and WireLib.clampPos then
        function WireLib.clampPos(pos) return Vector(pos) end
    end
end)

----- GarrysMod detours -----
timer.Simple(0, function()
    local GM = GM or GAMEMODE or gmod.GetGamemode()
    function GM:FindUseEntity(ply, ent)
        if not IsValid(ent) or ent:GetClass() == "inf_chunk" then
            local traceEnt = util.TraceLine({
                start = ply:GetShootPos(),
                endpos = ply:GetShootPos() + ply:GetAimVector() * 72,
                filter = ply
            }).Entity
            if IsValid(traceEnt) then ent = traceEnt end
        end

        return ent
    end
end)

timer.Simple(1, function()
    -- we want our hooks to run last, so we wait a second before adding them (assuming every other addon adds them after that)
    hook.Add("AllowPlayerPickup", "INFMAP_InitPickup", function(ply, ent)
        local pos, megapos = InfMap2.LocalizePosition(ent:GetPos())
        local localpos = InfMap2.UnlocalizePosition(pos, megapos - ply:GetMegaPos())
        ent:INF_SetPos(localpos)
        ent:SetMegaPos(ply:GetMegaPos())
    end)
    -- if i somehow make it work later...
    hook.Add("GravGunPickupAllowed", "INFMAP_InitPickup", function(ply, ent)
        -- gmod calls this hook every frame... i think 300 units is sane pickup distance /shrug
        if ply:GetShootPos():DistToSqr(ent:GetPos()) > 90000 then return end
        local pos, megapos = InfMap2.LocalizePosition(ent:GetPos())
        local localpos = InfMap2.UnlocalizePosition(pos, megapos - ply:GetMegaPos())
        ent:INF_SetPos(localpos)
        ent:SetMegaPos(ply:GetMegaPos())
    end)
    hook.Add("PhysgunPickup", "INFMAP_InitPickup", function(ply, ent)
        local pos, megapos = InfMap2.LocalizePosition(ent:GetPos())
        local localpos = InfMap2.UnlocalizePosition(pos, megapos - ply:GetMegaPos())
        ent:INF_SetPos(localpos)
        ent:SetMegaPos(ply:GetMegaPos())
    end)
end)