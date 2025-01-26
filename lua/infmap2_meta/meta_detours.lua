---@meta

---@class Entity
Entity = Entity

---Sets localized position in chunk on infmap
---@param pos any
function Entity:INF_SetPos(pos) end
---Returns localized position in chunk on infmap
---@return Vector pos
function Entity:INF_GetPos() end

---Sets unlocalised position on infmap
---@param pos Vector
function Entity:SetPos(pos) end
---Returns unlocalised position on infmap
---@return Vector pos
function Entity:GetPos() end

---Returns entity megaposition (chunk offset)
---@return Vector megapos
function Entity:GetMegaPos() end
---Sets entity megaposition (chunk offset)
---@param megapos Vector
function Entity:SetMegaPos(megapos) end