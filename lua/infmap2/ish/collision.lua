AddCSLuaFile()

hook.Add("ShouldCollide", "InfMap2ShouldCollide", function(e1, e2)
    if e1:IsWorld() or e2:IsWorld() then return end
    if e1.INF_MegaPos ~= e2.INF_MegaPos then return false end
end)