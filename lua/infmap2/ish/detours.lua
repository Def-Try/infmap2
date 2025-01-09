AddCSLuaFile()

local planes = {
    Vector(0, 0, -1), Vector(0, 0, 1),
    Vector(-1, 0, 0), Vector(1, 0, 0),
    Vector(0, -1, 0), Vector(0, 1, 0)
}

InfMap2.TraceLine = InfMap2.TraceLine or util.TraceLine
function util.TraceLine(tracedata)
    local data = table.Copy(tracedata)

    local real_start_pos, real_start_offset = InfMap2.LocalizePosition(tracedata.start)
    local real_end_pos, real_end_offset = InfMap2.LocalizePosition(tracedata.endpos)

    --print(real_start_offset, real_end_offset)

    data.start = real_start_pos
    --data.endpos = real_end_pos
    local filter = data.filter
    data.filter = function(e)
        local filtered = false
        if e:GetClass() == "inf_chunk" then return false end
        if isfunction(filter) then filtered = not filter(e) end
        if istable(filter) then filtered = table.HasValue(filter, e) end
        if isentity(filter) then filtered = e == filter end
        return e.INF_MegaPos == real_start_offset and not filtered
    end

	local hit_data = InfMap2.TraceLine(data)

    if (not hit_data.Hit or hit_data.HitWorld) and real_start_offset ~= real_end_offset then
        -- cross chunk trace
        local length = (tracedata.start - tracedata.endpos):Length()

        local direction = (tracedata.endpos - tracedata.start):GetNormalized()

        local mindist = math.huge
        local endpos = Vector()

        for _,plane in ipairs(planes) do
            local hitpos = util.IntersectRayWithPlane(real_start_pos, direction, plane*InfMap2.ChunkSize/2, plane)
            if not hitpos then continue end
            if (hitpos - real_start_pos):Length() >= mindist then continue end
            endpos = hitpos
            mindist = (hitpos - real_start_pos):Length()
        end

        --if mindist > length then
        --    return emptytrace
        --end

        --debugoverlay.Cross(endpos, 10, 1, Color(255, 0, 0), true)
        mindist = mindist + 1
        local newdata = table.Copy(tracedata)
        newdata.start = InfMap2.UnlocalizePosition(endpos, real_start_offset) + direction
        hit_data = util.TraceLine(newdata)
    end

    --debugoverlay.Cross(data.start, 10, 1, Color(255, 0, 0), false)
    --debugoverlay.Sphere(data.endpos, 10, 1, Color(255, 0, 0), false)
    --debugoverlay.Line(data.start, data.endpos, 1, Color(255, 0, 0), false)

    if IsValid(hit_data.Entity) then
        local ent = hit_data.Entity
        if ent then end
    end

	return hit_data
end