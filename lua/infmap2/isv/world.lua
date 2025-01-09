InfMap2.Cache.ChunkMeshes = InfMap2.Cache.ChunkMeshes or {}

function InfMap2.CreateWorldChunk(megapos)
    if InfMap2.Debug then print("[INFMAP] Creating world chunk "..tostring(megapos)) end
    assert(InfMap2.UsesGenerator, "InfMap2 does not use a generator")
    local chunk = ents.Create("inf_chunk")
    chunk.INF_MegaPos = megapos
    chunk:Spawn()
    InfMap2.EntityUpdateMegapos(chunk, chunk.INF_MegaPos)
    return chunk
end

hook.Add("PlayerSpawnedEffect", "InfMap2SpawnEffectCorrect", function(ply, model, ent)
    InfMap2.EntityUpdateMegapos(ent, ply.INF_MegaPos)
end)

hook.Add("PlayerSpawnedNPC", "InfMap2SpawnNPCCorrect", function(ply, ent)
    InfMap2.EntityUpdateMegapos(ent, ply.INF_MegaPos)
end)

hook.Add("PlayerSpawnedProp", "InfMap2SpawnPropCorrect", function(ply, model, ent)
    InfMap2.EntityUpdateMegapos(ent, ply.INF_MegaPos)
end)

hook.Add("PlayerSpawnedRagdoll", "InfMap2SpawnRagdollCorrect", function(ply, model, ent)
    InfMap2.EntityUpdateMegapos(ent, ply.INF_MegaPos)
end)

hook.Add("PlayerSpawnedSENT", "InfMap2SpawnSENTCorrect", function(ply, ent)
    InfMap2.EntityUpdateMegapos(ent, ply.INF_MegaPos)
end)

hook.Add("PlayerSpawnedSWEP", "InfMap2SpawnSWEPCorrect", function(ply, ent)
    InfMap2.EntityUpdateMegapos(ent, ply.INF_MegaPos)
end)

hook.Add("PlayerSpawnedVehicle", "InfMap2SpawnVehicleCorrect", function(ply, ent)
    InfMap2.EntityUpdateMegapos(ent, ply.INF_MegaPos)
end)

timer.Create("InfMap2RemoveUnusedChunks", 0.5, 0, function()
    for megapos, chunkent in pairs(InfMap2.GeneratedChunks) do
        megapos = Vector(megapos)
        if not IsValid(chunkent) then continue end
        local valid = false
        for _, ent in ents.Iterator() do
            if ent:GetClass() == "inf_chunk" then continue end
            if not ent.INF_MegaPos then continue end
            local chebyshev = (ent.INF_MegaPos - megapos)
            chebyshev = math.abs(chebyshev.x) + math.abs(chebyshev.y) + math.abs(chebyshev.z)
            if chebyshev <= 1 then
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