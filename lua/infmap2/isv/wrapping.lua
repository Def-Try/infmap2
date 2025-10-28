InfMap2.GeneratedChunks = InfMap2.GeneratedChunks or {}

InfMap2.Cache.carries = InfMap2.Cache.carries or {}

do
    local function pickup(ply, ent, meth)
        InfMap2.Cache.carries[ply:SteamID()] = {ent, meth}
        InfMap2.Cache.carries[ent:EntIndex()] = {ply, meth}
    end
    local function drop(ply) 
        InfMap2.Cache.carries[InfMap2.Cache.carries[ply:SteamID()][1]:EntIndex()] = nil
        InfMap2.Cache.carries[ply:SteamID()] = nil
    end

    hook.Add("OnPhysgunPickup",       "InfMap2EntityCarry", function(ply, ent) pickup(ply, ent, "physgun") end)
    hook.Add("PhysgunDrop",           "InfMap2EntityCarry", drop)
    hook.Add("GravGunOnPickedUp",     "InfMap2EntityCarry", function(ply, ent) pickup(ply, ent, "gravgun") end)
    hook.Add("GravGunOnDropped",      "InfMap2EntityCarry", drop)
    hook.Add("OnPlayerPhysicsPickup", "InfMap2EntityCarry", function(ply, ent) pickup(ply, ent, "physics") end)
    hook.Add("OnPlayerPhysicsDrop",   "InfMap2EntityCarry", drop)
    hook.Add("EntityRemoved",         "InfMap2EntityCarry", function(ent)
        if not InfMap2.Cache.carries[ent:EntIndex()] then return end
        drop(InfMap2.Cache.carries[ent:EntIndex()][1])
    end)
end

local function ent_SetPos_proper(ent, pos)
    -- parents are local... don't set pos
    if ent:GetParent():IsValid() then return end

    -- clamp to source bounds in case contraption is VERY massive
    -- helps with stuff like simfphys cars to not die
    pos = InfMap2.ClampVector(pos, InfMap2.SourceBounds[1] - 64)

    if ent:IsRagdoll() then
		for i = 0, ent:GetPhysicsObjectCount() - 1 do
			local phys = ent:GetPhysicsObjectNum(i)
			local vel = phys:GetVelocity()
			local ang_vel = phys:GetAngleVelocity()
			local diff = phys:INF_GetPos() - ent:INF_GetPos()
		
			phys:INF_SetPos(pos + diff, true)
			phys:SetVelocity(vel)
			phys:SetAngleVelocity(ang_vel)
		end
	end

    -- teleport entity
    ent:INF_SetPos(pos)
end

local function ent_SetVelAng_proper(ent, vel, ang)
    local phys = ent:GetPhysicsObject()
	
	if phys:IsValid() then 
		phys:SetAngles(ang)
		phys:SetVelocity(vel)
	else
		ent:SetAngles(ang)
		ent:SetVelocity(vel)
	end
end

local function update_entity(ent, pos, megapos)
    if not IsValid(ent) then return end

    if ent:IsPlayer() and InfMap2.Cache.carries[ent:SteamID()] and IsValid(InfMap2.Cache.carries[ent:SteamID()][1]) then
        local carrydata = InfMap2.Cache.carries[ent:SteamID()]
        local carry, carrymeth = nil, nil
        if carrydata then carry, carrymeth = carrydata[1], carrydata[2] end
        local entities = InfMap2.FindAllConnected(carry)
        if carry:IsPlayer() then entities[#entities+1] = carry:GetHands() end
        local ent_pos = ent:INF_GetPos()
        for _,cent in pairs(entities) do
            --if InfMap2.UselessEntitiesFilter(cent) then continue end
            cent:ForcePlayerDrop()
            local vel, ang = cent:GetVelocity(), cent:GetAngles()
            InfMap2.EntityUpdateMegapos(cent, megapos)
            ent_SetPos_proper(cent, pos + (cent:INF_GetPos() - ent_pos))
            ent_SetVelAng_proper(cent, vel, ang)
            cent.INF_ConstraintMain = ent
            if carrymeth == "physics" then
                ent:PickupObject(cent)
            end
            if carrymeth == "physgun" then end -- no action needed :)
            if carrymeth == "gravgun" then
                -- TODO: simulate +attack2
            end
        end
    end

    InfMap2.EntityUpdateMegapos(ent, megapos)
    ent_SetPos_proper(ent, pos)
    ent.INF_ConstraintMain = ent
end

local neighbors = {}
for x=-1,1 do for y=-1,1 do for z=-1,1 do
    neighbors[#neighbors+1] = Vector(x, y, z)
end end end

local ents_to_wrap = {}

timer.Create("InfMap2WorldWrapping", 0.1, 0, function()
    table.Empty(ents_to_wrap)
    for _, ent in ents.Iterator() do
        if InfMap2.UselessEntitiesFilter(ent) then continue end -- useless entity
        -- if not ent:GetMegaPos() then continue end -- no megapos, something is wrong
        if ent:GetVelocity() == vector_origin then continue end -- no velocity, no possible reason to teleport
        if IsValid(ent:GetParent()) then continue end -- parent is valid, teleport is handled by it
        if ent:IsPlayer() and not ent:Alive() then continue end -- player is dead, don't teleport
        if not InfMap2.IsMainContraptionEntity(ent) then continue end -- not main contraption entity, teleporting *will* break stuff
        ents_to_wrap[#ents_to_wrap+1] = ent
    end
end)

function InfMap2.Teleport(ent, newpos)
    -- we need to do three passes over entities to teleport them properly
    local pos, megapos = InfMap2.LocalizePosition(newpos)
    local entities = InfMap2.FindAllConnected(ent)
    -- first: collect entities velocities and angles
    local mainvel, mainang = ent:GetVelocity(), ent:GetAngles()
    local velocities, angles = {}, {}
    for _, cent in pairs(entities) do
        if ent == cent then continue end
        velocities[cent] = cent:GetVelocity()
        angles[cent] = cent:GetAngles()
    end

    -- second: update entities positions
    local mainpos = ent:INF_GetPos()
    for _, cent in pairs(entities) do
        if ent == cent then continue end
        --cent:ForcePlayerDrop()
        update_entity(cent, pos + (cent:INF_GetPos() - mainpos), megapos)
    end
    update_entity(ent, pos, megapos)

    -- third: restore velocities and angles
    for _, cent in pairs(entities) do
        if ent == cent then continue end
        ent_SetVelAng_proper(cent, velocities[cent], angles[cent])
    end
    ent_SetVelAng_proper(ent, mainvel, mainang)

    -- additionally create chunks around current one
    if InfMap2.World.HasTerrain then
        InfMap2.CreateChunksAround(megapos)
    end
end

hook.Add("Think", "InfMap2WorldWrapping", function() for _, ent in ipairs(ents_to_wrap) do
    if not IsValid(ent) then continue end -- ent died
    if InfMap2.PositionInChunkSpace(ent:INF_GetPos(), InfMap2.ChunkSize - 1) then
        ent.INF_ConstraintMain = nil
        continue
    end -- still in chunk, just clear constraint main
    if IsValid(ent.INF_ConstraintMain) and ent.INF_ConstraintMain ~= ent then continue end -- has a "master" constraint entity
    if ent:IsPlayerHolding() then continue end -- being held by player

    if ent:GetClass() == "inf_crosschunkclone" then continue end -- crosschunk clone, we dont touch those

    local pos, megapos_offset = InfMap2.LocalizePosition(ent:INF_GetPos())
    local megapos = ent:GetMegaPos() + megapos_offset

    if InfMap2.Debug then print("[INFMAP] Updating entity "..tostring(ent)) end

    InfMap2.Teleport(ent, ent:GetPos())
end end)