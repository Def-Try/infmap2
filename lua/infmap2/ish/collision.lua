AddCSLuaFile()

hook.Add("ShouldCollide", "InfMap2ShouldCollide", function(e1, e2)
    -- if e1:IsWorld() or e2:IsWorld() then return end
    if e1:GetMegaPos() ~= e2:GetMegaPos() then return false end
---@diagnostic disable-next-line: undefined-field
    if e1:GetClass() == "inf_crosschunkclone" and e1.INF_ReferenceData ~= nil and e1.INF_ReferenceData.Parent == e2 then return false end
---@diagnostic disable-next-line: undefined-field
    if e2:GetClass() == "inf_crosschunkclone" and e2.INF_ReferenceData ~= nil and e2.INF_ReferenceData.Parent == e1 then return false end
end)