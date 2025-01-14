AddCSLuaFile()

local planes = {
    Vector(0, 0, -1), Vector(0, 0, 1),
    Vector(-1, 0, 0), Vector(1, 0, 0),
    Vector(0, -1, 0), Vector(0, 1, 0)
}

InfMap2.TraceLine = InfMap2.TraceLine or util.TraceLine
function util.TraceLine(tracedata)
    --debugoverlay.Line(tracedata.start, tracedata.endpos, 0.1, Color(255, 0, 0), false)
    local direction = (tracedata.endpos - tracedata.start):GetNormalized()
    local length = (tracedata.start - tracedata.endpos):Length()
    local real_start_pos, real_start_offset = InfMap2.LocalizePosition(tracedata.start)
    local real_end_pos, real_end_offset = InfMap2.LocalizePosition(tracedata.endpos)
    local filter = tracedata.filter
    local data = table.Copy(tracedata)

    data.filter = function(e)
        if e.INF_MegaPos ~= real_start_offset then return false end
        local filtered = false
        if isfunction(filter) then filtered = not filter(e) end
        if istable(filter) then filtered = table.HasValue(filter, e) end
        if isentity(filter) then filtered = e == filter end
        return not filtered
    end

    data.start = real_start_pos
    data.endpos = data.start + direction * length

	local hit_data

    if real_start_offset ~= real_end_offset then

        local mindist = math.huge
        local endplane = Vector()
        local endpos = Vector()

        for _,plane in ipairs(planes) do
            if plane:Dot(direction) < 0 then continue end
            local hitpos = util.IntersectRayWithPlane(real_start_pos, direction, plane*InfMap2.ChunkSize/2, plane)
            if not hitpos then continue end
            if (hitpos - real_start_pos):Length() >= mindist then continue end
            endpos = hitpos
            mindist = (hitpos - real_start_pos):Length()
            endplane = plane
        end

        local newdata = table.Copy(tracedata)
        newdata.INF_DoNotHandleEntities = true
        newdata.start = endpos + -endplane*InfMap2.ChunkSize + direction -- in another chunk
        newdata.endpos = newdata.start + direction * math.max(0, length - mindist)

        newdata.start = InfMap2.UnlocalizePosition(newdata.start, real_start_offset + endplane)
        newdata.endpos = InfMap2.UnlocalizePosition(newdata.endpos, real_start_offset + endplane)

        --debugoverlay.Sphere(newdata.start, 100, 0.1, Color(255, 0, 0), false)

        hit_data = util.TraceLine(newdata)

        --hit_data.HitPos = InfMap2.UnlocalizePosition(hit_data.HitPos, real_start_offset)
    end

    local hit_data2 = InfMap2.TraceLine(data)
    if hit_data2.Hit and (not hit_data or hit_data2.Fraction < hit_data.Fraction) then
        hit_data = hit_data2
        hit_data.HitPos = InfMap2.UnlocalizePosition(hit_data.HitPos, real_start_offset)
    end

    if hit_data and hit_data.Hit then
        hit_data.Fraction = (tracedata.start - hit_data.HitPos):Length() / length
    end

    if hit_data and (IsValid(hit_data.Entity) or hit_data.Entity:IsWorld()) and not tracedata.INF_DoNotHandleEntities then
        local ent = hit_data.Entity
        if ent:GetClass() == "inf_chunk" then -- hit the inf_chunk, the world terrain
            hit_data.Entity = game.GetWorld()
            hit_data.HitWorld = true
            hit_data.HitNonWorld = false -- wtf garry
            hit_data.HitPos = hit_data.HitPos + hit_data.HitNormal -- spawning props sometimes clip through
        end
        if ent:GetClass() == "inf_crosschunkclone" then -- hit crosschunk clone, lie about hitting some entity
            hit_data.Entity = hit_data.Entity.INF_ReferenceData.Parent
        end
        if ent:IsWorld() then -- directly hit the world, meaning that something is really far away
            hit_data.Entity = NULL
            hit_data.Hit = false
            hit_data.HitWorld = false
            hit_data.HitNonWorld = false -- wtf garry
            hit_data.HitPos = tracedata.endpos
            hit_data.Fraction = 1
        end
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