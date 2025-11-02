local ENTITY = FindMetaTable("Entity")
local CLUALOCOMOTION = FindMetaTable("CLuaLocomotion")
if not ENTITY then return end
if not CLUALOCOMOTION then return end

----- Entity detours -----

-- get setentity data since theres no GetEntity
ENTITY.INF_SetEntity = ENTITY.INF_SetEntity or ENTITY.SetEntity
function ENTITY:SetEntity(str, ent)
    self.SET_ENTITIES = self.SET_ENTITIES or {}
    self.SET_ENTITIES[str] = ent
    self:INF_SetEntity(str, ent)
end

local function unfuck_keyvalue(self, value)
    if not self:GetKeyValues()[value] then return end
    self:SetKeyValue(value, tostring(InfMap2.UnlocalizePosition(Vector(self:GetKeyValues()[value]), -self:GetMegaPos()--[[@as Vector]])))
end
ENTITY.INF_Spawn = ENTITY.INF_Spawn or ENTITY.Spawn
function ENTITY:Spawn()
    if IsValid(self) and (self:IsConstraint() or self:GetClass() == "phys_spring" or self:GetClass() == "keyframe_rope") then -- elastic isnt considered a constraint..?
        unfuck_keyvalue(self, "attachpoint")
        unfuck_keyvalue(self, "springaxis")
        unfuck_keyvalue(self, "slideaxis")
        unfuck_keyvalue(self, "hingeaxis")
        unfuck_keyvalue(self, "axis")
        unfuck_keyvalue(self, "position2")
        if self.SET_ENTITIES and self.SET_ENTITIES.EndEntity == game.GetWorld() then 
            unfuck_keyvalue(self, "EndOffset") 
        end
        self:SetPos(self:INF_GetPos())
    end
    return self:INF_Spawn()
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