InfMap2.Constraints = InfMap2.Constraints or {}
InfMap2.Constraints.Contraptions = InfMap2.Constraints.Contraptions or {}
InfMap2.Constraints.PrimaryEntities = InfMap2.Constraints.PrimaryEntities or {}

local phys_constraint_objects_queue = {}
function InfMap2.Constraints.SetPhysConstraintObjects(ent, pc1, pc2)
    phys_constraint_objects_queue[ent] = {pc1, pc2}
end
function InfMap2.Constraints.GetPhysConstraintObjects(ent, pop)
    local objs = phys_constraint_objects_queue[ent]
    if pop then
        phys_constraint_objects_queue[ent] = nil
    end
    return objs or {nil, nil}
end
function InfMap2.Constraints.IsConstraint(ent)
    return (ent:IsConstraint() or ent:GetClass() == "phys_spring" or ent:GetClass() == "keyframe_rope")
end

---should be called when a constraint entity is about to be spawned
---@param ent Entity
function InfMap2.Constraints.SpawnCallback(ent)
    local ent1, ent2 = unpack(InfMap2.Constraints.GetPhysConstraintObjects(ent, false))
    local contraption_1 = InfMap2.Constraints.FindContraptionOfEntity(ent1, false)
    local contraption_2 = InfMap2.Constraints.FindContraptionOfEntity(ent2, false)
    if not contraption_1 and not contraption_2 then
        contraption_1 = InfMap2.Constraints.CreateContraptionForEntity(ent1)
    end
    if contraption_1 and not contraption_2 then
        return InfMap2.Constraints.AddEntityToContraptionForEntity(ent1, ent2)
    end
    if contraption_2 and not contraption_1 then
        return InfMap2.Constraints.AddEntityToContraptionForEntity(ent2, ent1)
    end
    return InfMap2.Constraints.MergeContraptionsOfEntities(ent1, ent2)
end
---should be called when a constraint entity is about to be removed
---should return a function that will be called after calling Remove
---@param ent Entity
function InfMap2.Constraints.RemoveCallback(ent)
    local ent1, ent2 = unpack(InfMap2.Constraints.GetPhysConstraintObjects(ent, false))
    -- TODO: make it more efficientt!!!
    InfMap2.Constraints.DestroyContraptionForEntity(ent1)
    return function()
        hook.GetTable()["EntityRemoved"]["Constraint Library - ConstraintRemoved"](ent) -- update constraint lib stuff
        InfMap2.Constraints.TryCreateContraptionFromEntities(ent1)
        InfMap2.Constraints.TryCreateContraptionFromEntities(ent2)
    end
end
---should be called when a normal entity is about to be removed (to "unconstraint" it)
---@param ent Entity
function InfMap2.Constraints.RemoveCallbackNonconstraint(ent)
    InfMap2.Constraints.RemoveEntityFromContraptionForEntity(ent)
end
function InfMap2.Constraints.TryCreateContraptionFromEntities(ent_primary)
    local connected = InfMap2.FindAllConnected(ent_primary)
    if #connected <= 1 then return false end
    for _, ent in ipairs(connected) do 
        if InfMap2.Constraints.IsConstraint(ent) then continue end
        InfMap2.Constraints.AddEntityToContraptionForEntity(ent_primary, ent)
    end
end

function InfMap2.Constraints.FindContraptionOfConstraint(ent, do_create)
    if do_create == nil then do_create = true end
    local ent1, ent2 = InfMap2.Constraints.GetPhysConstraintObjects(ent, false)
    local contraption = InfMap2.Constraints.FindContraptionOfEntity(ent1, do_create) or InfMap2.Constraints.FindContraptionOfEntity(ent2, do_create)
    return contraption
end
function InfMap2.Constraints.FindContraptionOfEntity(ent, do_create)
    local primary_entity = InfMap2.Constraints.PrimaryEntities[ent]
    if primary_entity then
        return InfMap2.Constraints.Contraptions[primary_entity]
    end
    if not do_create then return nil end
    return InfMap2.Constraints.CreateContraptionForEntity(ent)
end

function InfMap2.Constraints.CreateContraptionForEntity(ent) 
    local contraption = {ent}
    InfMap2.Constraints.Contraptions[ent] = contraption
    InfMap2.Constraints.PrimaryEntities[ent] = ent
    return ent
end
function InfMap2.Constraints.DestroyContraptionForEntity(ent)
    local pent = InfMap2.Constraints.PrimaryEntities[ent]
    if not InfMap2.Constraints.Contraptions[pent] then return end
    for _, cent in ipairs(InfMap2.Constraints.Contraptions[pent]) do
        InfMap2.Constraints.PrimaryEntities[cent] = nil
    end
    InfMap2.Constraints.Contraptions[pent] = nil
end
function InfMap2.Constraints.AddEntityToContraptionForEntity(ent_contraption, ent_add)
    local contraption = InfMap2.Constraints.FindContraptionOfEntity(ent_contraption, false)
    if not contraption then return false end
    if table.HasValue(contraption, ent_add) then return true end
    if InfMap2.Constraints.PrimaryEntities[ent_add] then -- and InfMap2.Constraints.PrimaryEntities[ent_add] ~= ent_contraption then
        -- InfMap2.Constraints.RemoveEntityFromContraptionForEntity(InfMap2.Constraints.PrimaryEntities[ent_add], ent_add)
        return false
    end
    InfMap2.Constraints.PrimaryEntities[ent_add] = contraption[1]
    table.insert(contraption, ent_add)
    return true
end
function InfMap2.Constraints.RemoveEntityFromContraptionForEntity(ent_contraption, ent_remove)
    local contraption = InfMap2.Constraints.FindContraptionOfEntity(ent_contraption, false)
    if not contraption then return false end
    if InfMap2.Constraints.PrimaryEntities[ent_remove] ~= ent_contraption then return false end
    if InfMap2.Constraints.PrimaryEntities[ent_remove] == ent_remove then
        InfMap2.Constraints.PickNewContraptionPrimaryEntityForEntity(ent_contraption)
    end
    table.RemoveByValue(contraption, ent_remove)
    InfMap2.Constraints.PrimaryEntities[ent_remove] = nil
    return true
end
function InfMap2.Constraints.PickNewContraptionPrimaryEntityForEntity(ent)
    local contraption = InfMap2.Constraints.FindContraptionOfEntity(ent, false)
    if not contraption then return false end
    local new_primary = contraption[2]
    if not new_primary then
        InfMap2.Constraints.DestroyContraptionForEntity(ent)
        return false
    end
    for _, ent in ipairs(contraption) do
        InfMap2.Constraints.PrimaryEntities[ent] = new_primary
    end
end
function InfMap2.Constraints.MergeContraptionsOfEntities(ent_primary, ent_merge)
    local contraption_primary = InfMap2.Constraints.FindContraptionOfEntity(ent_primary, false)
    if not contraption_primary then return false end
    local contraption_merge = InfMap2.Constraints.FindContraptionOfEntity(ent_merge, false)
    if not contraption_merge then return false end
    if contraption_primary == contraption_merge then return true end
    InfMap2.Constraints.Contraptions[contraption_merge[1]] = nil
    for _, ent in ipairs(contraption_merge) do
        InfMap2.Constraints.PrimaryEntities[ent] = contraption_primary[1]
        table.insert(contraption_primary, ent)
        contraption_merge[_] = nil
    end
    return true
end