---@meta

---@class Entity
Entity = Entity
---@class PhysObj
PhysObj = PhysObj
---@class Player
Player = Player
---@class NextBot
NextBot = NextBot
---@class CTakeDamageInfo
CTakeDamageInfo = CTakeDamageInfo
---@class CLuaLocomotion
CLuaLocomotion = CLuaLocomotion

---Returns entity megaposition (chunk offset)
---@return Vector megapos
function Entity:GetMegaPos() end
---Sets entity megaposition (chunk offset)
---@param megapos Vector
function Entity:SetMegaPos(megapos) end

Entity.INF_SetPos = Entity.SetPos
Entity.INF_GetPos = Entity.GetPos
Entity.INF_Spawn = Entity.Spawn
Entity.INF_WorldSpaceAABB = Entity.WorldSpaceAABB
Entity.INF_EyePos = Entity.EyePos
Entity.INF_LocalToWorld = Entity.LocalToWorld
Entity.INF_WorldToLocal = Entity.WorldToLocal
Entity.INF_NearestPoint = Entity.NearestPoint
Entity.INF_GetAttachment = Entity.GetAttachment
Entity.INF_GetBonePosition = Entity.GetBonePosition
Entity.INF_SetEntity = Entity.SetEntity
Entity.INF_SetRenderBoundsWS = Entity.SetRenderBoundsWS
Entity.INF_SetRenderBounds = Entity.SetRenderBounds
Entity.INF_GetRenderBounds = Entity.GetRenderBounds

PhysObj.INF_SetPos = PhysObj.SetPos
PhysObj.INF_GetPos = PhysObj.GetPos
PhysObj.INF_ApplyForceOffset = PhysObj.ApplyForceOffset
PhysObj.INF_LocalToWorld = PhysObj.LocalToWorld
PhysObj.INF_CalculateVelocityOffset = PhysObj.CalculateVelocityOffset
PhysObj.INF_WorldToLocal = PhysObj.WorldToLocal
PhysObj.INF_GetVelocityAtPoint = PhysObj.GetVelocityAtPoint
PhysObj.INF_CalculateForceOffset = PhysObj.CalculateForceOffset
PhysObj.INF_SetMaterial = PhysObj.SetMaterial

Player.INF_GetShootPos = Player.GetShootPos

NextBot.INF_GetRangeSquaredTo = NextBot.GetRangeSquaredTo
NextBot.INF_GetRangeTo = NextBot.GetRangeTo

CTakeDamageInfo.INF_GetDamagePosition = CTakeDamageInfo.GetDamagePosition

CLuaLocomotion.INF_Approach = CLuaLocomotion.Approach
CLuaLocomotion.INF_FaceTowards = CLuaLocomotion.FaceTowards

render.INF_ComputeDynamicLighting = render.ComputeDynamicLighting
render.INF_ComputeLighting = render.ComputeLighting
render.INF_ComputePixelDiameterOfSphere = render.ComputePixelDiameterOfSphere
render.INF_Model = render.Model
render.INF_RenderView = render.RenderView

INF_EyePos = EyePos

cam.INF_PushModelMatrix = cam.PushModelMatrix
cam.INF_PopModelMatrix = cam.PopModelMatrix
cam.INF_Start3D2D = cam.Start3D2D