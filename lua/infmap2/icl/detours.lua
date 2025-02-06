local function localize(pos) return pos - (LocalPlayer():GetMegaPos() or Vector()) * InfMap2.ChunkSize end

render.INF_ComputeDynamicLighting = render.INF_ComputeDynamicLighting or render.ComputeDynamicLighting
function render.ComputeDynamicLighting(pos, normal) return render.INF_ComputeDynamicLighting(localize(pos), normal) end
render.INF_ComputeLighting = render.INF_ComputeLighting or render.ComputeLighting
function render.ComputeLighting(pos, normal) return render.INF_ComputeLighting(localize(pos), normal) end

render.INF_ComputePixelDiameterOfSphere = render.INF_ComputePixelDiameterOfSphere or render.ComputePixelDiameterOfSphere
function render.ComputePixelDiameterOfSphere(pos, radius) return render.INF_ComputePixelDiameterOfSphere(localize(pos), radius) end

-- handled by world transform matrix
--[[
render.INF_DrawBeam = render.INF_DrawBeam or render.DrawBeam
function render.DrawBeam(start, endpos, width, texstart, texend, color) return render.INF_DrawBeam(localize(start), localize(endpos), width, texstart, texend, color) end
render.INF_DrawBox = render.INF_DrawBox or render.DrawBox
function render.DrawBox(pos, ang, mins, maxs, color) return render.INF_DrawBox(localize(pos), ang, mins, maxs, color) end
render.INF_DrawLine = render.INF_DrawLine or render.DrawLine
function render.DrawLine(start, endpos, color, writez) return render.INF_DrawLine(localize(start), localize(endpos), color, writez) end
render.INF_DrawQuad = render.INF_DrawQuad or render.DrawQuad
function render.DrawQuad(v1, v2, v3, v4, color) return render.INF_DrawQuad(localize(v1), localize(v2), localize(v3), localize(v4), color) end
render.INF_DrawQuadEasy = render.INF_DrawQuadEasy or render.DrawQuadEasy
function render.DrawQuadEasy(pos, normal, width, height, color, rotation) return render.INF_DrawQuadEasy(localize(pos), normal, width, height, color, rotation) end
render.INF_DrawSphere = render.INF_DrawSphere or render.DrawSphere
function render.DrawSphere(pos, radius, long, lat, color) return render.INF_DrawSphere(localize(pos), radius, long, lat, color) end
render.INF_DrawSprite = render.INF_DrawSprite or render.DrawSprite
function render.DrawSprite(pos, width, height, color) return render.INF_DrawSprite(localize(pos), width, height, color) end

render.INF_DrawWireframeBox = render.INF_DrawWireframeBox or render.DrawWireframeBox
function render.DrawWireframeBox(pos, ang, mins, maxs, color, writez) return render.INF_DrawWireframeBox(localize(pos), ang, mins, maxs, color, writez) end
render.INF_DrawWireframeSphere = render.INF_DrawWireframeSphere or render.DrawWireframeSphere
function render.DrawWireframeSphere(pos, radius, long, lat, color, writez) return render.INF_DrawWireframeSphere(localize(pos), radius, long, lat, color, writez) end

render.INF_DrawBeam = render.INF_DrawBeam or render.DrawBeam
function render.DrawBeam(start, endpos, width, texstart, texend, color) return render.INF_DrawBeam(localize(start), localize(endpos), width, texstart, texend, color) end
render.INF_AddBeam = render.INF_AddBeam or render.AddBeam
function render.AddBeam(start, width, texend, color) return render.INF_AddBeam(localize(start), width, texend, color) end

render.INF_Model = render.INF_Model or render.Model
function render.Model(settings, csent)
	settings.pos = localize(settings.pos)
	return render.INF_Model(settings, csent)
end
--]]

render.INF_RenderView = render.INF_RenderView or render.RenderView
function render.RenderView(view)
	view.origin = localize(view.origin)
	return render.INF_RenderView(view)
end

local ENTITY = FindMetaTable("Entity")
ENTITY.INF_SetRenderBoundsWS = ENTITY.INF_SetRenderBoundsWS or ENTITY.SetRenderBoundsWS
function ENTITY:SetRenderBoundsWS(mins, maxs)
	self.INF_RenderBounds = {self:WorldToLocal(mins), self:WorldToLocal(maxs)}
end

ENTITY.INF_SetRenderBounds = ENTITY.INF_SetRenderBounds or ENTITY.SetRenderBounds
function ENTITY:SetRenderBounds(mins, maxs, add)
	if self:GetMegaPos() == LocalPlayer():GetMegaPos() then
		self:INF_SetRenderBounds(mins, maxs, add)
	end
	add = add or vector_origin
	self.INF_RenderBounds = {mins - add, maxs + add}
end

ENTITY.INF_GetRenderBounds = ENTITY.INF_GetRenderBounds or ENTITY.GetRenderBounds
function ENTITY:GetRenderBounds()
	if self.INF_RenderBounds then
		return unpack(self.INF_RenderBounds)
	end
	return self:INF_GetRenderBounds()
end

INF_EyePos = INF_EyePos or EyePos
function EyePos()
	return InfMap2.UnlocalizePosition(INF_EyePos(), LocalPlayer():GetMegaPos())
end

InfMap2.Cache.CameraMatrixStack = InfMap2.Cache.CameraMatrixStack or {}
InfMap2.Cache.CameraMatrixPointer = InfMap2.Cache.CameraMatrixPointer or 0

cam.INF_PushModelMatrix = cam.INF_PushModelMatrix or cam.PushModelMatrix
function cam.PushModelMatrix(matrix, multiply)
	table.insert(InfMap2.Cache.CameraMatrixStack, {matrix, multiply}) -- push
	InfMap2.Cache.CameraMatrixPointer = InfMap2.Cache.CameraMatrixPointer + 1
	if not multiply then
		for i=1, InfMap2.Cache.CameraMatrixPointer do
			if InfMap2.Cache.CameraMatrixPointer == 1 then break end
			cam.INF_PopModelMatrix()
		end
		InfMap2.Cache.CameraMatrixPointer = 1
	end
	cam.INF_PushModelMatrix(matrix, true)
end

cam.INF_PopModelMatrix = cam.INF_PopModelMatrix or cam.PopModelMatrix
function cam.PopModelMatrix()
	local matrix, multiply = unpack(table.remove(InfMap2.Cache.CameraMatrixStack)) -- pop
	cam.INF_PopModelMatrix()
	InfMap2.Cache.CameraMatrixPointer = InfMap2.Cache.CameraMatrixPointer - 1
	if multiply then return end
	InfMap2.Cache.CameraMatrixPointer = 0
	if #InfMap2.Cache.CameraMatrixStack == 0 then return end
	local backtrack = 0
	for i=#InfMap2.Cache.CameraMatrixStack, 1, -1 do
		local data = InfMap2.Cache.CameraMatrixStack[i]
		if not data[2] then backtrack = -1 end
		backtrack = backtrack + 1
	end
	for i=#InfMap2.Cache.CameraMatrixStack - backtrack, #InfMap2.Cache.CameraMatrixStack do
		InfMap2.Cache.CameraMatrixPointer = InfMap2.Cache.CameraMatrixPointer + 1
		cam.INF_PushModelMatrix(InfMap2.Cache.CameraMatrixStack[i][1], true)
	end
end