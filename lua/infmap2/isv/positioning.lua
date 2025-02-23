InfMap2.GeneratedChunks = InfMap2.GeneratedChunks or {}

---Updates entity megaposition, moving it between chunks
---@param ent Entity
---@param megapos Vector
function InfMap2.EntityUpdateMegapos(ent, megapos)
    ---@class Entity
    ent = ent
    ent:SetMegaPos(megapos)
    ent:SetCustomCollisionCheck(true)

    -- remove crosschunkclones, we need to rebuild them
    if ent:GetClass() ~= "inf_crosschunkclone" and ent.INF_Clones then
        for i=1,table.maxn(ent.INF_Clones) do SafeRemoveEntity(ent.INF_Clones[i]) end
        ent.INF_Clones = nil
    end

    if ent:IsEFlagSet(EFL_SERVER_ONLY) or ent:IsConstraint() then return end
    ent:SetMegaPos(megapos)

    if ent:IsPlayer() or ent:IsNPC() then
        ---@cast ent Player|NPC
        for _, weapon in ipairs(ent:GetWeapons()) do
            weapon:SetCustomCollisionCheck(true)

            weapon:SetMegaPos(megapos)
        end
    end
end

local neighbors = {}
for x=-1,1 do for y=-1,1 do for z=-1,1 do
    neighbors[#neighbors+1] = Vector(x, y, z)
end end end

local unfilter = {
	rpg_missile = true,
	crossbow_bolt = true,
}
hook.Add("OnEntityCreated", "InfMap2EntityCreated", function(ent) timer.Simple(0, function()
    if not IsValid(ent) then return end
    if ent:GetClass() == "inf_chunk" then return end
    if InfMap2.UselessEntitiesFilter(ent) and not unfilter[ent:GetClass()] then return end

    local megapos = ent:GetMegaPos()
    InfMap2.EntityUpdateMegapos(ent, megapos)
    if InfMap2.Debug then print("[INFMAP] Entity "..tostring(ent).." created at megapos "..tostring(megapos)) end

    if InfMap2.World.HasTerrain and ent:GetClass() ~= "inf_crosschunkclone" then
        for i=1,#neighbors do
            local pos = megapos + neighbors[i]
            if InfMap2.GeneratedChunks[tostring(pos)] then continue end
            InfMap2.GeneratedChunks[tostring(pos)] = InfMap2.CreateWorldChunk(pos)
        end
    end
end) end)