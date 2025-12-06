InfMap2.ContraptionSystem = InfMap2.ContraptionSystem or {}
InfMap2.ContraptionSystem.Contraptions = InfMap2.ContraptionSystem.Contraptions or {}
InfMap2.ContraptionSystem.Primaries = InfMap2.ContraptionSystem.Primaries or {}

InfMap2.ContraptionSystem.PhysConstrainedObjects = {}
function InfMap2.ContraptionSystem.Constraint_SetPhysConstrainedObjects(constraint, ent1, ent2)
    InfMap2.ContraptionSystem.PhysConstrainedObjects[constraint] = {ent1, ent2}
end
function InfMap2.ContraptionSystem.Constraint_GetPhysConstrainedObjects(constraint)
    local pair = InfMap2.ContraptionSystem.PhysConstrainedObjects[constraint]
    if not pair then return nil, nil end
    return pair[1], pair[2]
end
function InfMap2.ContraptionSystem.Constraint_Spawn(constraint)
    local ent1, ent2 = InfMap2.ContraptionSystem.Constraint_GetPhysConstrainedObjects(constraint)
    if not ent1 or not ent2 then return end
    local contraption_1 = InfMap2.ContraptionSystem.FindContraption(ent1)
    local contraption_2 = InfMap2.ContraptionSystem.FindContraption(ent2)
    if not contraption_1 and not contraption_2 then
        contraption_1 = InfMap2.ContraptionSystem.MakeContraption(ent1)
    end
    if contraption_2 and not contraption_1 then
        ent1, ent2 = ent2, ent1
        contraption_1, contraption_2 = contraption_2, contraption_1
    end

    if contraption_2 then
        table.insert(contraption_1.constraints, constraint)
        InfMap2.ContraptionSystem.MergeContraptions(contraption_1, contraption_2)
        return
    end
    table.insert(contraption_1.constraints, constraint)
    InfMap2.ContraptionSystem.AddEntity(contraption_1, ent2)
end
function InfMap2.ContraptionSystem.Constraint_Remove(constraint)
    error('not implemented!')
end

function InfMap2.ContraptionSystem.IsConstraint(ent)
    return (ent:IsConstraint() or ent:GetClass() == "phys_spring" or ent:GetClass() == "keyframe_rope")
end

function InfMap2.ContraptionSystem.AddEntity(contraption, ent)
    if InfMap2.Debug then print("[INFMAP2] Adding entity "..tostring(ent).." to contraption of master "..tostring(contraption.master)) end
    table.insert(contraption.entities, ent)
    InfMap2.ContraptionSystem.Primaries[ent] = contraption.master
    InfMap2.ContraptionSystem.InvalidateContraption(contraption)
end
function InfMap2.ContraptionSystem.RemoveEntity(contraption, ent)
    if InfMap2.Debug then print("[INFMAP2] Removing entity "..tostring(ent).." from contraption of master "..tostring(contraption.master)) end
    table.RemoveByValue(contraption.entities, ent)
    InfMap2.ContraptionSystem.Primaries[ent] = nil
    InfMap2.ContraptionSystem.InvalidateContraption(contraption)
end
function InfMap2.ContraptionSystem.ForgetContraption(contraption)
    if InfMap2.Debug then print("[INFMAP2] Forgetting contraption of master "..tostring(contraption.master)) end
    InfMap2.ContraptionSystem.Contraptions[contraption.master] = nil
end
function InfMap2.ContraptionSystem.MergeContraptions(contraption_1, contraption_2)
    if InfMap2.Debug then print("[INFMAP2] Merging contraptions of masters "..tostring(contraption_1.master).." and "..tostring(contraption_2.master)) end
    InfMap2.ContraptionSystem.ForgetContraption(contraption_2)
    for _, ent in ipairs(contraption_2.entities) do
        table.insert(contraption_1.entities, ent)
        InfMap2.ContraptionSystem.Primaries[ent] = contraption_1.master
    end
    for _, ent in ipairs(contraption_2.constraints) do
        table.insert(contraption_1.constraints, ent)
    end
    InfMap2.ContraptionSystem.InvalidateContraption(contraption_1)
    --InfMap2.ContraptionSystem.ValidateContraption(contraption_1)
end
function InfMap2.ContraptionSystem.ValidateContraption(contraption)
    if not contraption.dirty then return end
    for _, ent in ipairs(contraption.entities) do

    end
end
function InfMap2.ContraptionSystem.InvalidateContraption(contraption)
    if contraption.dirty then return end
    contraption.dirty = true
    local offset = 0
    for n, ent in ipairs(contraption.entities) do
        if not IsValid(ent:GetParent()) then continue end
        table.remove(contraption.entities, n - offset)
        offset = offset + 1
    end
end

function InfMap2.ContraptionSystem.GetContraption(master)
    return InfMap2.ContraptionSystem.Contraptions[master]
end
function InfMap2.ContraptionSystem.FindContraption(ent)
    if ent:GetParent():IsValid() then return InfMap2.ContraptionSystem.FindContraption(ent:GetParent()) end
    return InfMap2.ContraptionSystem.Contraptions[ent] or InfMap2.ContraptionSystem.Contraptions[InfMap2.ContraptionSystem.Primaries[ent]]
end
function InfMap2.ContraptionSystem.MakeContraption(master)
    if InfMap2.Debug then print("[INFMAP2] Making contraption for master "..tostring(master)) end
    local contraption = {master=master, entities={master}, constraints={}, dirty=true}
    InfMap2.ContraptionSystem.Contraptions[master] = contraption
    InfMap2.ContraptionSystem.Primaries[master] = master
    return contraption
end

function InfMap2.ContraptionSystem.IsMainContraptionEntity(ent)
    if ent:GetParent():IsValid() then return false end
    local contraption = InfMap2.ContraptionSystem.FindContraption(ent)
    if not contraption then return true end
    if contraption.master == ent then return true end
    return false
end

function InfMap2.ContraptionSystem.ContraptionHeldByPlayer(master)
    local contraption = InfMap2.ContraptionSystem.GetContraption(master)
    if not contraption then return master:IsPlayerHolding() end
    for _, ent in ipairs(contraption.entities) do
        if ent:IsPlayerHolding() then return true end
    end
    return false
end