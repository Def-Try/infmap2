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

hook.Add("PlayerSpawnedEffect", "InfMap2SpawnEffectCorrect", function(ply, model, ent)
    timer.Simple(0, function() InfMap2.EntityUpdateMegapos(ent, ply:GetMegaPos()) end)
end)

hook.Add("PlayerSpawnedNPC", "InfMap2SpawnNPCCorrect", function(ply, ent)
    timer.Simple(0, function() InfMap2.EntityUpdateMegapos(ent, ply:GetMegaPos()) end)
end)

hook.Add("PlayerSpawnedProp", "InfMap2SpawnPropCorrect", function(ply, model, ent)
    timer.Simple(0, function() InfMap2.EntityUpdateMegapos(ent, ply:GetMegaPos()) end)
end)

hook.Add("PlayerSpawnedRagdoll", "InfMap2SpawnRagdollCorrect", function(ply, model, ent)
    timer.Simple(0, function() InfMap2.EntityUpdateMegapos(ent, ply:GetMegaPos()) end)
end)

hook.Add("PlayerSpawnedSENT", "InfMap2SpawnSENTCorrect", function(ply, ent)
    timer.Simple(0, function() InfMap2.EntityUpdateMegapos(ent, ply:GetMegaPos()) end)
end)

hook.Add("PlayerSpawnedSWEP", "InfMap2SpawnSWEPCorrect", function(ply, ent)
    timer.Simple(0, function() InfMap2.EntityUpdateMegapos(ent, ply:GetMegaPos()) end)
end)

hook.Add("PlayerSpawnedVehicle", "InfMap2SpawnVehicleCorrect", function(ply, ent)
    timer.Simple(0, function() InfMap2.EntityUpdateMegapos(ent, ply:GetMegaPos()) end)
end)

timer.Create("InfMap2RemoveUnusedChunks", 0.5, 0, function()
    for megapos, chunkent in pairs(InfMap2.GeneratedChunks) do
        megapos = Vector(megapos)
        if not IsValid(chunkent) then continue end
        local valid = false
        for _, ent in ents.Iterator() do
            if ent:GetClass() == "inf_chunk" then continue end
            if not ent:GetMegaPos() then continue end
            if InfMap2.ChebyshevDistance(ent:GetMegaPos(), megapos) <= 1 then
                valid = true
                break
            end
        end
        if not valid then
            if InfMap2.Debug then print("[INFMAP] Removing world chunk "..tostring(megapos)) end
            InfMap2.GeneratedChunks[tostring(megapos)] = nil
            chunkent:Remove()
        end
    end
end)