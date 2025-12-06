local ENTITY = FindMetaTable("Entity")
local CLUALOCOMOTION = FindMetaTable("CLuaLocomotion")
if not ENTITY then return end
if not CLUALOCOMOTION then return end

----- Entity detours -----

-- get setentity data since theres no GetEntity
ENTITY.INF_SetEntity = ENTITY.INF_SetEntity or ENTITY.SetEntity
function ENTITY:SetEntity(str, ent)
    self.INF_SET_ENTITIES = self.INF_SET_ENTITIES or {}
    self.INF_SET_ENTITIES[str] = ent
    self:INF_SetEntity(str, ent)
end

ENTITY.INF_SetPhysConstraintObjects = ENTITY.INF_SetPhysConstraintObjects or ENTITY.SetPhysConstraintObjects
function ENTITY:SetPhysConstraintObjects(pent1, pent2)
    if InfMap2.ContraptionSystem.IsConstraint(self) then
        InfMap2.ContraptionSystem.Constraint_SetPhysConstrainedObjects(self, pent1:GetEntity(), pent2:GetEntity())
    end
    return self:INF_SetPhysConstraintObjects(pent1, pent2)
end

local function unfuck_keyvalue(self, value)
    if not self:GetKeyValues()[value] then return end
    self:SetKeyValue(value, tostring(InfMap2.UnlocalizePosition(Vector(self:GetKeyValues()[value]), -self:GetMegaPos()--[[@as Vector]])))
end
ENTITY.INF_Spawn = ENTITY.INF_Spawn or ENTITY.Spawn
function ENTITY:Spawn()
    if IsValid(self) and InfMap2.ContraptionSystem.IsConstraint(self) then
        unfuck_keyvalue(self, "attachpoint")
        unfuck_keyvalue(self, "springaxis")
        unfuck_keyvalue(self, "slideaxis")
        unfuck_keyvalue(self, "hingeaxis")
        unfuck_keyvalue(self, "axis")
        unfuck_keyvalue(self, "position2")
        if self.INF_SET_ENTITIES and self.INF_SET_ENTITIES.EndEntity == game.GetWorld() then 
            unfuck_keyvalue(self, "EndOffset") 
        end
        self:SetPos(self:INF_GetPos())
        InfMap2.ContraptionSystem.Constraint_Spawn(self)
    end
    return self:INF_Spawn()
end
ENTITY.INF_Remove = ENTITY.INF_Remove or ENTITY.Remove
function ENTITY:Remove()
    local cback
    if IsValid(self) and InfMap2.ContraptionSystem.IsConstraint(self) then
        InfMap2.ContraptionSystem.Constraint_Remove(constraint)
    else
        --InfMap2.Constraints.RemoveCallbackNonconstraint(self)
    end
    return self:INF_Remove()
end

----- CLuaLocomotion detours -----

CLUALOCOMOTION.INF_Approach = CLUALOCOMOTION.INF_Approach or CLUALOCOMOTION.Approach
function CLUALOCOMOTION:Approach(goal, goalweight)
    local nb = self:GetNextBot()
    local dir = (goal - nb:GetPos()):GetNormalized()
    local pos = InfMap2.LocalizePosition(nb:GetPos() + dir)
    return CLUALOCOMOTION.INF_Approach(self, pos, goalweight)
end

CLUALOCOMOTION.INF_FaceTowards = CLUALOCOMOTION.INF_FaceTowards or CLUALOCOMOTION.FaceTowards
function CLUALOCOMOTION:FaceTowards(goal)
    local nb = self:GetNextBot()
    local dir = (goal - nb:GetPos()):GetNormalized()
    local pos = InfMap2.LocalizePosition(nb:GetPos() + dir)
    return CLUALOCOMOTION.INF_FaceTowards(self, pos)
end


----- random detours -----

-- map is infinite, everything is in world!
function util.IsInWorld(pos) return true end