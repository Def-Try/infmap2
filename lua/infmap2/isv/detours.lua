local ENTITY = FindMetaTable("Entity")

ENTITY.INF_GetPos = ENTITY.INF_GetPos or ENTITY.GetPos
function ENTITY:GetPos()
	return InfMap2.UnlocalizePosition(self:INF_GetPos(), self.INF_MegaPos or Vector())
end

ENTITY.INF_SetPos = ENTITY.INF_SetPos or ENTITY.SetPos
function ENTITY:SetPos(pos)
	local pos, megapos = InfMap2.LocalizePosition(pos)
    if megapos ~= self.INF_MegaPos then
        InfMap2.EntityUpdateMegapos(self, megapos)
    end
	return self:INF_SetPos(pos)
end

ENTITY.INF_WorldSpaceAABB = ENTITY.INF_WorldSpaceAABB or ENTITY.WorldSpaceAABB
function ENTITY:WorldSpaceAABB()
    local aa, bb = self:INF_WorldSpaceAABB()
    return InfMap2.UnlocalizePosition(aa, self.INF_MegaPos), InfMap2.UnlocalizePosition(bb, self.INF_MegaPos)
end