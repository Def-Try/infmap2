InfMap2.Cache.ChunkMeshes = InfMap2.Cache.ChunkMeshes or {}

---Creates world chunk
---@param megapos Vector
---@return Entity chunk
function InfMap2.CreateWorldChunk(megapos)
    if InfMap2.Debug then print("[INFMAP] Creating world chunk "..tostring(megapos)) end
    assert(InfMap2.World.HasTerrain, "InfMap2 does not use a generator")
    local chunk = ents.Create("inf_chunk")
    chunk:SetMegaPos(megapos)
    chunk:Spawn()
    InfMap2.EntityUpdateMegapos(chunk, megapos)
    return chunk
end
--[[
-- not needed anymore (?)
hook.Add("PlayerSpawnedEffect", "InfMap2SpawnEffectCorrect", function(ply, model, ent)
    timer.Simple(0, function() if not IsValid(ent) then return end InfMap2.EntityUpdateMegapos(ent, ply:GetMegaPos()) end)
end)

hook.Add("PlayerSpawnedNPC", "InfMap2SpawnNPCCorrect", function(ply, ent)
    timer.Simple(0, function() if not IsValid(ent) then return end InfMap2.EntityUpdateMegapos(ent, ply:GetMegaPos()) end)
end)

hook.Add("PlayerSpawnedProp", "InfMap2SpawnPropCorrect", function(ply, model, ent)
    timer.Simple(0, function() if not IsValid(ent) then return end InfMap2.EntityUpdateMegapos(ent, ply:GetMegaPos()) end)
end)

hook.Add("PlayerSpawnedRagdoll", "InfMap2SpawnRagdollCorrect", function(ply, model, ent)
    timer.Simple(0, function() if not IsValid(ent) then return end InfMap2.EntityUpdateMegapos(ent, ply:GetMegaPos()) end)
end)

hook.Add("PlayerSpawnedSENT", "InfMap2SpawnSENTCorrect", function(ply, ent)
    timer.Simple(0, function() if not IsValid(ent) then return end InfMap2.EntityUpdateMegapos(ent, ply:GetMegaPos()) end)
end)

hook.Add("PlayerSpawnedSWEP", "InfMap2SpawnSWEPCorrect", function(ply, ent)
    timer.Simple(0, function() if not IsValid(ent) then return end InfMap2.EntityUpdateMegapos(ent, ply:GetMegaPos()) end)
end)

hook.Add("PlayerSpawnedVehicle", "InfMap2SpawnVehicleCorrect", function(ply, ent)
    timer.Simple(0, function() if not IsValid(ent) then return end InfMap2.EntityUpdateMegapos(ent, ply:GetMegaPos()) end)
end)
]]
timer.Create("InfMap2RemoveUnusedChunks", 5, 0, function()
    local chunks_to_remove = {}
    for megapos, chunkent in pairs(InfMap2.GeneratedChunks) do
        chunks_to_remove[#chunks_to_remove+1] = {Vector(megapos), chunkent}
    end

    for _, ent in ents.Iterator() do
        if ent:GetClass() == "inf_chunk" then continue end
        local chunks_to_remove2 = table.Copy(chunks_to_remove)
        local removed = 0
        for _, chunkd in ipairs(chunks_to_remove2) do
            if InfMap2.ChebyshevDistance(ent:GetMegaPos(), chunkd[1]) > 1 then continue end
            table.remove(chunks_to_remove, _ - removed)
            removed = removed + 1
        end
    end

    for _, chunkd in ipairs(chunks_to_remove) do
        if InfMap2.Debug then print("[INFMAP] Removing world chunk "..tostring(chunkd[1])) end
        InfMap2.GeneratedChunks[tostring(chunkd[1])] = nil
        chunkd[2]:Remove()
    end
end)