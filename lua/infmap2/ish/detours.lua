AddCSLuaFile()

local planes = {
    Vector(0, 0, -1), Vector(0, 0, 1),
    Vector(-1, 0, 0), Vector(1, 0, 0),
    Vector(0, -1, 0), Vector(0, 1, 0)
}

InfMap2.TraceLine = InfMap2.TraceLine or util.TraceLine
function util.TraceLine(tracedata, a)
    local direction = (tracedata.endpos - tracedata.start):GetNormalized()
    local length = (tracedata.start - tracedata.endpos):Length()
    local real_start_pos, real_start_offset = InfMap2.LocalizePosition(tracedata.start)
    local real_end_pos, real_end_offset = InfMap2.LocalizePosition(tracedata.endpos)
    local filter = tracedata.filter
    tracedata.filter = function(e)
        local filtered = false
        print(e.INF_MegaPos, real_start_offset)
        --if e:GetClass() == "inf_chunk" then return false end
        if isfunction(filter) then filtered = not filter(e) end
        if istable(filter) then filtered = table.HasValue(filter, e) end
        if isentity(filter) then filtered = e == filter end
        return e.INF_MegaPos == real_start_offset and not filtered
    end
    local data = table.Copy(tracedata)

    --print(real_start_offset, real_end_offset)

    data.start = real_start_pos
    data.endpos = data.start + direction * length

	local hit_data = InfMap2.TraceLine(data)

    if (hit_data.Hit and not hit_data.HitWorld) then
        hit_data.HitPos = InfMap2.UnlocalizePosition(hit_data.HitPos, real_start_offset)
    end

    --do return hit_data end

    if (not hit_data.Hit or hit_data.HitWorld) and real_start_offset ~= real_end_offset then
        -- cross chunk trace

        local mindist = math.huge
        local endplane = Vector()
        local endpos = Vector()

        for _,plane in ipairs(planes) do
            local hitpos = util.IntersectRayWithPlane(real_start_pos, direction, plane*InfMap2.ChunkSize/2, plane)
            if not hitpos then continue end
            if (hitpos - real_start_pos):Length() >= mindist then continue end
            endpos = hitpos
            mindist = (hitpos - real_start_pos):Length()
            endplane = plane
        end

        debugoverlay.Sphere(endpos, 10, 0.1)
        debugoverlay.Line(real_start_pos, endpos, 0.1)

        --if mindist > length then
        --    return emptytrace
        --end

        --debugoverlay.Cross(endpos, 10, 1, Color(255, 0, 0), true)
        mindist = mindist + 1
        local newdata = table.Copy(tracedata)
        newdata.start = InfMap2.UnlocalizePosition(endpos, real_start_offset) + direction
        newdata.endpos = newdata.start + direction * math.max(0, length - mindist)
        hit_data = util.TraceLine(newdata)
        --PrintTable(hit_data)
        -- hit_data.HitPos = InfMap2.UnlocalizePosition()
        local hit_pos, hit_mega = InfMap2.LocalizePosition(hit_data.HitPos)

        debugoverlay.Line(newdata.start, newdata.endpos, 0.1, Color(255, 0, 0))

        ---print(real_start_offset)

        hit_data.HitPos = InfMap2.UnlocalizePosition(hit_pos, real_start_offset + hit_mega + endplane)
    end

    if IsValid(hit_data.Entity) then
        local ent = hit_data.Entity
        if ent then end
    end

	return hit_data
end