function InfMap2.EntityUpdateMegapos(ent, megapos)
    ent.INF_MegaPos = megapos
    ent:SetCustomCollisionCheck(true)

    -- remove crosschunkclones, we need to rebuild them
    if SERVER and ent.INF_Clones then
        for i=1,table.maxn(ent.INF_Clones) do SafeRemoveEntity(ent.INF_Clones[i]) end
        ent.INF_Clones = nil
    end

    if ent:IsEFlagSet(EFL_SERVER_ONLY) or ent:IsConstraint() then return end
    ent:SetNW2Vector("INF_MegaPos", megapos)
end

local neighbors = {}
for x=-1,1 do for y=-1,1 do for z=-1,1 do
    neighbors[#neighbors+1] = Vector(x, y, z)
end end end

hook.Add("OnEntityCreated", "InfMap2EntityCreated", function(ent) timer.Simple(0, function()
    if not IsValid(ent) then return end
    if ent.INF_MegaPos then return end

    local megapos = Vector()
    local owner = ent:GetOwner()
    if not IsValid(owner) then owner = ent:GetParent() end
    if IsValid(owner) and owner.INF_MegaPos then
        megapos = owner.INF_MegaPos
    end
    InfMap2.EntityUpdateMegapos(ent, megapos)

    print("[INFMAP] Entity "..tostring(ent).." created at megapos "..tostring(megapos))

    if InfMap2.UsesGenerator then
        for i=1,#neighbors do
            local pos = megapos + neighbors[i]
            if InfMap2.GeneratedChunks[tostring(pos)] then continue end
            InfMap2.GeneratedChunks[tostring(pos)] = InfMap2.CreateWorldChunk(pos)
        end
    end
end) end)