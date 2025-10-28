AddCSLuaFile()

local floor = math.floor
local clamp = math.Clamp
local round = math.Round

--==== POSITIONING ====--
-- functions related to positioning of entities in world

---Clamps vector coordinates
---@param vec Vector
---@param max number
---@return Vector
function InfMap2.ClampVector(vec, max)
	return Vector(clamp(vec[1], -max, max), clamp(vec[2], -max, max), clamp(vec[3], -max, max))
end

---Rounds vector coordinates
---@param vec Vector
---@param decimals integer
---@return Vector
function InfMap2.RoundVector(vec, decimals)
    return Vector(round(vec[1], decimals), round(vec[2], decimals), round(vec[3], decimals))
end

---Returns chebyshev (chess-like) distance between vectors
---@param pos1 Vector
---@param pos2 Vector
---@return number
function InfMap2.ChebyshevDistance(pos1, pos2)
    local difference = (pos1 - pos2)
    local chebyshev = math.abs(difference.x) + math.abs(difference.y) + math.abs(difference.z)
    return chebyshev
end

---Checks if vector is in chunk space
---@param pos Vector
---@param size number?
---@return boolean
function InfMap2.PositionInChunkSpace(pos, size)
    local halfsize = ((size or InfMap2.ChunkSize) / 2)
    if pos.x <= -halfsize or pos.x >= halfsize then return false end
    if pos.y <= -halfsize or pos.y >= halfsize then return false end
    if pos.z <= -halfsize or pos.z >= halfsize then return false end
    return true
end

---Localizes position
---@param pos Vector
---@param size number?
---@return Vector localpos
---@return Vector megapos
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

---Delocalizes position
---@param localpos Vector
---@param megapos Vector?
---@param size number?
---@return Vector
function InfMap2.UnlocalizePosition(localpos, megapos, size)
    return (megapos or Vector()) * (size or InfMap2.ChunkSize) + localpos
end

---Checks AABB intersection
---@param min_a Vector
---@param max_a Vector
---@param min_b Vector
---@param max_b Vector
---@return boolean
function InfMap2.IntersectBox(min_a, max_a, min_b, max_b) 
	local x_check = max_b[1] < min_a[1] or min_b[1] > max_a[1]
	local y_check = max_b[2] < min_a[2] or min_b[2] > max_a[2]
	local z_check = max_b[3] < min_a[3] or min_b[3] > max_a[3]
	return not (x_check or y_check or z_check)
end

--==== Useless Entity Filter ====--
-- filters useless entities (that are not movable between chunks or ignored by player)

InfMap2.UselessEntities = InfMap2.UselessEntities or {
	physgun_beam = true,
	worldspawn = true,
	gmod_hands = true,
	info_particle_system = true,
	phys_spring = true,
	predicted_viewmodel = true,
    viewmodel = true,
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

---Checks if entity is useless to the infmap.
---@param ent Entity
---@return boolean
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

---Checks if entity is the main contraption entity
---@param ent Entity
---@return boolean
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

---Recursively finds all connected entities
---@param mainent Entity
---@param children table<Entity>
---@param seen table<boolean>
---@return table<Entity> children
function InfMap2.FindAllConnected_Recurse(mainent, children, seen)
    -- have we already checked that ent?
    if seen[mainent] then return children end
    seen[mainent] = true
    if not mainent:IsValid() then return children end
    children[#children+1] = mainent

    ---@class Entity
    mainent = mainent

    -- find constrained
    if SERVER then
        local constraints = constraint.GetTable(mainent)
        for _, v in pairs(constraints) do
            if seen[v.Constraint] then continue end
            if v.Ent1 then InfMap2.FindAllConnected_Recurse(v.Ent1, children, seen) end
            if v.Ent2 then InfMap2.FindAllConnected_Recurse(v.Ent2, children, seen) end
            seen[v.Constraint] = true
            children[#children+1] = v.Constraint
        end
    end

    -- find parented...
    for _,ent in ents.Iterator() do
        if ent:GetParent() ~= mainent then continue end
        if seen[ent] then continue end
        if not ent:IsValid() then seen[ent] = true continue end
        InfMap2.FindAllConnected_Recurse(ent, children, seen)
    end

    -- if vehicle add driver
    if mainent:IsVehicle() then
        ---@cast mainent Vehicle
        if mainent.GetDriver and not seen[mainent:GetDriver()] then
            if IsValid(mainent:GetDriver()) then
                InfMap2.FindAllConnected_Recurse(mainent:GetDriver(), children, seen)
            end
            seen[mainent:GetDriver()] = true
        end
    end

    -- if player add hands
    if mainent:IsPlayer() then
        ---@cast mainent Player
        if mainent.GetHands and not seen[mainent:GetHands()] then
            if IsValid(mainent:GetHands()) then
                InfMap2.FindAllConnected_Recurse(mainent:GetHands(), children, seen)
            end
            seen[mainent:GetHands()] = true
        end
    end

    return children
end

---Finds all connected entities
---@param ent Entity
---@return table<Entity>
function InfMap2.FindAllConnected(ent)
    local children, seen = {}, {}
    local children = InfMap2.FindAllConnected_Recurse(ent, children, seen)
    -- hate this
    -- for _,child in ipairs(children) do
    --     if child:IsVehicle() then
    --         ---@cast child Vehicle
    --         if child.GetDriver and not seen[child:GetDriver()] then
    --             if IsValid(child:GetDriver()) then
    --                 InfMap2.FindAllConnected_Recurse(child:GetDriver(), children, seen)
    --             end
    --             seen[child:GetDriver()] = true
    --         end
    --     end
    -- end
    return children
end

--==== NETWORK STUFF ====--

local ENTITY = FindMetaTable("Entity")
if SERVER then
    util.AddNetworkString("InfMap2_ChangeMegaPos")
end
-- MEGAPOS STUFF

function ENTITY:SetMegaPos(vec)
    self.INF_MegaPos = Vector(vec)
    if not IsValid(self) then return end
    if not SERVER then return end
    self:SetNW2Vector("INF_MegaPos", vec)
    net.Start("InfMap2_ChangeMegaPos")
        net.WriteEntity(self)
        net.WriteVector(vec)
    net.Broadcast()
end

function ENTITY:GetMegaPos()
    if not IsValid(self) then return Vector(self.INF_MegaPos) end
    return Vector(self.INF_MegaPos) or self:GetNW2Vector("INF_MegaPos", Vector())
end

if CLIENT then
    local queue = {}
    hook.Add("EntityNetworkedVarChanged", "InfMap2EntityMegaposUpdate", function(ent, name, _, val)
        if name ~= "INF_MegaPos" then return end
        if InfMap2.Debug and ent:GetClass() ~= "inf_chunk" then print("[INFMAP] "..tostring(ent).." -> "..tostring(val)) end
        ent.INF_MegaPos = val
        InfMap2.EntityUpdateMegapos(ent, val)
    end)
    net.Receive("InfMap2_ChangeMegaPos", function()
        ---@class Entity
        local entindex = net.ReadUInt(MAX_EDICT_BITS)
        local ent = Entity(entindex)
        if not IsValid(ent) then
            queue[entindex] = net.ReadVector()
            return
        end
        ent.INF_MegaPos = net.ReadVector()
    end)
    hook.Add("OnEntityCreated", "InfMap2ClientLateArrival", function(ent) timer.Simple(0, function()
        if not IsValid(ent) then return end
        local qpos = queue[ent:EntIndex()]
        if not qpos then return end
        queue[ent:EntIndex()] = nil
        ent.INF_MegaPos = qpos
    end) end)
end