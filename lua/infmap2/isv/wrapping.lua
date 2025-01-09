InfMap2.GeneratedChunks = InfMap2.GeneratedChunks or {}

InfMap2.Cache.carries = InfMap2.Cache.carries or {}

do
    local function pickup(ply, ent) InfMap2.Cache.carries[ply] = ent end
    local function drop  (ply     ) InfMap2.Cache.carries[ply] = nil end

    hook.Add("OnPhysgunPickup",       "InfMap2EntityCarry", pickup)
    hook.Add("PhysgunDrop",           "InfMap2EntityCarry", drop  )
    hook.Add("GravGunOnPickedUp",     "InfMap2EntityCarry", pickup)
    hook.Add("GravGunOnDropped",      "InfMap2EntityCarry", drop  )
    hook.Add("OnPlayerPhysicsPickup", "InfMap2EntityCarry", pickup)
    hook.Add("OnPlayerPhysicsDrop",   "InfMap2EntityCarry", drop  )
end

local function ent_SetPos_proper(ent, pos)
    if ent:GetParent():IsValid() then return end

    pos = InfMap2.ClampVector(pos, InfMap2.SourceBounds[1] - 64)

    if ent:IsRagdoll() then
        ErrorNoHalt("implement ragdoll teleportation")
    end

    ent:INF_SetPos(pos)
end

local function ent_SetVelAng_proper(ent, vel, ang)
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetVelocity(vel)
        phys:SetAngles(ang)
    else
        ent:SetVelocity(vel)
        ent:SetAngles(ang)
    end
end

local function update_entity(ent, pos, megapos)
    if not IsValid(ent) then return end

    if ent:IsPlayer() and IsValid(InfMap2.Cache.carries[ent]) then
        local carry = InfMap2.Cache.carries[ent]
        InfMap2.EntityUpdateMegapos(carry, megapos)
        ent_SetPos_proper(carry, pos + (carry:INF_GetPos() - ent:INF_GetPos()))
    end

    InfMap2.EntityUpdateMegapos(ent, megapos)
    ent_SetPos_proper(ent, pos)
end

local neighbors = {}
for x=-1,1 do for y=-1,1 do for z=-1,1 do
    neighbors[#neighbors+1] = Vector(x, y, z)
end end end

hook.Add("Think", "InfMap2WorldWrapping", function()
    for _, ent in ents.Iterator() do
        -- if not IsValid(ent) then continue end -- ent is invalid, something is wrong
        if InfMap2.UselessEntitiesFilter(ent) then continue end -- useless entity
        if not ent.INF_MegaPos then continue end -- no megapos, something is wrong
        if ent:GetVelocity() == Vector() then continue end -- no velocity, no possible reason to teleport
        if IsValid(ent:GetParent()) then continue end -- parent is valid, teleport is handled by it
        if ent:IsPlayer() and not ent:Alive() then continue end -- player is dead, don't teleport

        if InfMap2.PositionInChunkSpace(ent:INF_GetPos()) then continue end -- still in chunk, don't do anything
        if ent:IsPlayerHolding() then continue end -- being held by player

        local pos, megapos_offset = InfMap2.LocalizePosition(ent:INF_GetPos())
        local megapos = ent.INF_MegaPos + megapos_offset

        local vel = ent:GetVelocity()
        local ang = ent:GetAngles()

        update_entity(ent, pos, megapos)
        ent_SetVelAng_proper(ent, vel, ang)

        print("[INFMAP] Entity "..tostring(ent).." teleported to "..megapos.x.." "..megapos.y.." "..megapos.z)

        if InfMap2.UsesGenerator then
            for i=1,#neighbors do
                local pos = megapos + neighbors[i]
                if InfMap2.GeneratedChunks[tostring(pos)] then continue end
                InfMap2.GeneratedChunks[tostring(pos)] = InfMap2.CreateWorldChunk(pos)
            end
        end
    end
end)