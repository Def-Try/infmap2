AddCSLuaFile()

local floor = math.floor
local clamp = math.Clamp
local round = math.Round

--==== POSITIONING ====--
-- functions related to positioning of entities in world

function InfMap2.ClampVector(pos, max)
	return Vector(clamp(pos[1], -max, max), clamp(pos[2], -max, max), clamp(pos[3], -max, max))
end

function InfMap2.RoundVector(pos, decimals)
    return Vector(round(pos[1], decimals), round(pos[2], decimals), round(pos[3], decimals))
end

function InfMap2.PositionInChunkSpace(pos, size)
    -- +1 to avoid reocurring teleport when entity is perfectly at chunk boundary
    local halfsize = ((size or InfMap2.ChunkSize) / 2)
    if pos.x <= -halfsize or pos.x >= halfsize then return false end
    if pos.y <= -halfsize or pos.y >= halfsize then return false end
    if pos.z <= -halfsize or pos.z >= halfsize then return false end
    return true
end

function InfMap2.LocalizePosition(pos, size)
    local size = size or InfMap2.ChunkSize
    local offset = Vector(
        floor((pos.x + (size / 2)) / size),
        floor((pos.y + (size / 2)) / size),
        floor((pos.z + (size / 2)) / size)
    )
    local halfsizevec = Vector(1, 1, 1) * (size / 2)

    pos = pos + halfsizevec
    pos.x = pos.x % size
    pos.y = pos.y % size
    pos.z = pos.z % size
    pos = pos - halfsizevec
    
    return pos, offset
end

function InfMap2.UnlocalizePosition(pos, megapos, size)
    return (megapos or Vector()) * (size or InfMap2.ChunkSize) + pos
end

function InfMap2.IntersectBox(min_a, max_a, min_b, max_b) 
	local x_check = max_b[1] < min_a[1] or min_b[1] > max_a[1]
	local y_check = max_b[2] < min_a[2] or min_b[2] > max_a[2]
	local z_check = max_b[3] < min_a[3] or min_b[3] > max_a[3]
	return !(x_check or y_check or z_check)
end

--==== Useless Entity Filter ====--
-- filters useless entities (that are not movable between chunks or ignored by player)

InfMap2.UselessEntities = InfMap2.UselessEntities or {
	-- physgun_beam = true,
	worldspawn = true,
	-- gmod_hands = true,
	info_particle_system = true,
	phys_spring = true,
	predicted_viewmodel = true,
	env_projectedtexture = true,
	keyframe_rope = true,
	hl2mp_ragdoll = true,
	env_skypaint = true,
	shadow_control = true,
	player_pickup = true,
	env_sun = true,
	info_player_start = true,
	scene_manager = true,
	ai_network = true,
	network = true,
	bodyque = true,
	gmod_gamerules = true,
	player_manager = true,
	soundent = true,
	env_flare = true,
	_firesmoke = true,
	func_brush = true,
	logic_auto = true,
	light_environment = true,
	env_laserdot = true,
	env_smokestack = true,
	env_rockettrail = true,
	rpg_missile = true,
	gmod_safespace_interior = true,
	env_fog_controller = true,
	sizehandler = true,
	crossbow_bolt = true,

    inf_chunk = true,
    inf_crosschunkclone = true
}

InfMap2.DisablePickup = InfMap2.DisablePickup or {
    inf_chunk = true,
    inf_crosschunkclone = true
}

function InfMap2.UselessEntitiesFilter(ent)
    if not IsValid(ent) then return true end
    if InfMap2.UselessEntities[ent:GetClass()] then return true end
    if ent:EntIndex() == 0 then return true end
    if SERVER and ent:IsConstraint() then return true end
    return false
end

--==== CONSTRAINTS ====--
-- functions related to constraints data

local function constrained_invalid_filter(ent)
    local valid = true
    if valid and ent:IsPlayerHolding() then valid = false end
    if valid and ent:GetPhysicsObject():IsValid() and not ent:GetPhysicsObject():IsMoveable() then valid = false end
    if valid and not ent:IsSolid() and ent:GetNoDraw() then valid = false end
    if valid and ent:GetParent():IsValid() then valid = false end
    if valid and InfMap2.UselessEntitiesFilter(ent) then valid = false end
    return not valid
end

function InfMap2.IsMainContraptionEntity(ent)
    if constrained_invalid_filter(ent) then return false end
    local idx = ent:EntIndex()

    for _, const_ent in pairs(InfMap2.FindAllConnected(ent)) do
        if const_ent:IsPlayerHolding() then
            return const_ent == ent
        end
        
        if const_ent:EntIndex() < idx and not constrained_invalid_filter(const_ent) then
            return false
        end
    end

    return true
end

function InfMap2.FindAllConnected(mainent, children, seen)
    children = children or {}
    seen = seen or {}

    -- have we already checked that ent?
    if seen[mainent] then return children end
    seen[mainent] = true
    if not mainent:IsValid() then return children end

    -- find constrained
    children[#children+1] = mainent
    local constraints = constraint.GetTable(mainent)
    for _, v in pairs(constraints) do
        if v.Ent1 then InfMap2.FindAllConnected(v.Ent1, children, seen) end
        if v.Ent2 then InfMap2.FindAllConnected(v.Ent2, children, seen) end
    end

    -- find parented...
    for _,ent in ents.Iterator() do
        if ent:GetParent() ~= mainent then continue end
        if seen[ent] then continue end
        seen[ent] = true
        if not ent:IsValid() then continue end
        children[#children+1] = ent
        InfMap2.FindAllConnected(ent, children, seen)
    end

    -- add driver
    if mainent:IsVehicle() and mainent.GetDriver and not seen[mainent:GetDriver()] then
        seen[mainent:GetDriver()] = true
        children[#children+1] = mainent:GetDriver()
    end

    return children
end