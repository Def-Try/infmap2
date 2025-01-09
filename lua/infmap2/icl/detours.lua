local ENTITY = FindMetaTable("Entity")

local function invalid_chunk(e1, e2)
	return not e1.INF_MegaPos or not e2.INF_MegaPos
end

ENTITY.INF_GetPos = ENTITY.INF_GetPos or ENTITY.GetPos
function ENTITY:GetPos()
	if invalid_chunk(self, LocalPlayer()) then return self:INF_GetPos() end
	---@diagnostic disable-next-line: undefined-field
	return InfMap2.UnlocalizePosition(self:INF_GetPos(), self.INF_MegaPos)
end

ENTITY.INF_SetPos = ENTITY.INF_SetPos or ENTITY.SetPos
function ENTITY:SetPos(pos)
	local pos = InfMap2.ClampVector(pos, InfMap2.SourceBounds[1])
	return self:INF_SetPos(pos)
end