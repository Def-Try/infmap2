---@meta

---@class Entity
Entity = Entity

---Entity Megaposition (chunk offset)
Entity.INF_MegaPos = Vector()

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