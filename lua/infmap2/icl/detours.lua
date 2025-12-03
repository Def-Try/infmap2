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

---@class Entity
local ENTITY = FindMetaTable("Entity")
if ENTITY == nil then return end

ENTITY.INF_SetRenderBoundsWS = ENTITY.INF_SetRenderBoundsWS or ENTITY.SetRenderBoundsWS
function ENTITY:SetRenderBoundsWS(mins, maxs, add)
	if not self.INF_VisualOffset then -- LocalPlayer():GetMegaPos() then
		self:INF_SetRenderBoundsWS(mins, maxs, add)
	end
	add = add or vector_origin
	if isnumber(add) then
		---@diagnostic disable-next-line: param-type-mismatch
		add = Vector(add, add, add)
	end
	self.INF_RenderBounds = {self:WorldToLocal(mins - add), self:WorldToLocal(maxs + add)}
end

ENTITY.INF_SetRenderBounds = ENTITY.INF_SetRenderBounds or ENTITY.SetRenderBounds
function ENTITY:SetRenderBounds(mins, maxs, add)
	if not self.INF_VisualOffset then -- LocalPlayer():GetMegaPos() then
		self:INF_SetRenderBounds(mins, maxs, add)
	end
	add = add or vector_origin
	if isnumber(add) then
		---@diagnostic disable-next-line: param-type-mismatch
		add = Vector(add, add, add)
	end
	self.INF_RenderBounds = {mins - add, maxs + add}
end

ENTITY.INF_GetRenderBounds = ENTITY.INF_GetRenderBounds or ENTITY.GetRenderBounds
function ENTITY:GetRenderBounds()
	if self.INF_RenderBounds then
		return Vector(self.INF_RenderBounds[1]), Vector(self.INF_RenderBounds[2])
	end
	return self:INF_GetRenderBounds()
end

ENTITY.INF_EnableMatrix = ENTITY.INF_EnableMatrix or ENTITY.EnableMatrix
function ENTITY:EnableMatrix(mtype, mtrx)
    if mtype ~= "RenderMultiply" then return self:INF_EnableMatrix(mtype, mtrx) end
    if not self:INF_IsEngineEntity() then return self:INF_EnableMatrix(mtype, mtrx) end 
    if not mtrx then return self:INF_EnableMatrix(mtype, mtrx) end
    if not self.INF_VisualOffset then return self:INF_EnableMatrix(mtype, mtrx) end
    self.INF_CurrentMatrixMultiply = mtrx
    local mat = Matrix(mtrx)
    mat:SetTranslation(mat:GetTranslation() + self.INF_VisualOffset)
    return self:INF_EnableMatrix(mtype, mat)
end

ENTITY.INF_DisableMatrix = ENTITY.INF_DisableMatrix or ENTITY.DisableMatrix
function ENTITY:DisableMatrix(mtype)
    if mtype ~= "RenderMultiply" then return self:INF_DisableMatrix(mtype) end
    if not self:INF_IsEngineEntity() then return self:INF_DisableMatrix(mtype) end 
    self.INF_CurrentMatrixMultiply = nil
    if not self.INF_VisualOffset then return self:INF_DisableMatrix(mtype) end
    local mat = Matrix()
    mat:SetTranslation(self.INF_VisualOffset)
    return self:INF_EnableMatrix(mtype, mat)
end

function ENTITY:INF_IsEngineEntity()
    if not IsValid(self) then error("Tried to use NULL entity!") end
	---@diagnostic disable-next-line undefined-field
	return self.Type == nil
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
	local _, multiply = unpack(table.remove(InfMap2.Cache.CameraMatrixStack)) -- pop
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

InfMap2.Cache.Start3DStack = {}
cam.INF_Start = cam.INF_Start or cam.Start
function cam.Start(camdata)
	if camdata.type ~= "3D" then return cam.INF_Start(camdata) end
	if not camdata.origin then
		camdata.origin = EyePos()
	end
	local _, megapos = InfMap2.LocalizePosition(camdata.origin)
	InfMap2.Cache.Start3DStack[#InfMap2.Cache.Start3DStack+1] = megapos
	return cam.INF_Start(camdata)
end
function cam.INF_Start3D(pos, ang, fov, x, y, w, h, znear, zfar)
	local tab = {}

	tab.type = "3D"
	tab.origin = pos
	tab.angles = ang
	if fov ~= nil then tab.fov = fov end
	if x ~= nil and y ~= nil and w ~= nil and h ~= nil then
		tab.x			= x
		tab.y			= y
		tab.w			= w
		tab.h			= h
		tab.aspect		= w / h
	end
	if znear ~= nil and zfar ~= nil then
		tab.znear	= znear
		tab.zfar	= zfar
	end
	return cam.INF_Start(tab)
end
cam.INF_End3D = cam.INF_End3D or cam.End3D
function cam.End3D()
	InfMap2.Cache.Start3DStack[#InfMap2.Cache.Start3DStack] = nil
	return cam.INF_End3D()
end
hook.Add("PreRender", "InfMap2ClearStart3DStack", function()
	InfMap2.Cache.Start3DStack = {}
end)

cam.INF_Start3D2D = cam.INF_Start3D2D or cam.Start3D2D
function cam.Start3D2D(pos, ang, scale)
	local localpos, megapos = InfMap2.LocalizePosition(pos)
	local mpos = (InfMap2.Cache.Start3DStack[#InfMap2.Cache.Start3DStack] or (megapos - LocalPlayer():GetMegaPos()))
	local realpos = InfMap2.UnlocalizePosition(localpos, mpos)
	return cam.INF_Start3D2D(realpos, ang, scale)
end

local mtrx = Matrix()
local offset = nil
render.INF_PushCustomClipPlane = render.INF_PushCustomClipPlane or render.PushCustomClipPlane
function render.PushCustomClipPlane(norm, dist)
	--local top = InfMap2.Cache.CameraMatrixStack[#InfMap2.Cache.CameraMatrixStack]
	--if not top then top = mtrx else top = top[1] end
	--top = top * cam.GetModelMatrix()
	--local trans = top:GetTranslation()
	--print(offset)
	local dot = 0
	if offset then dot = norm:Dot(offset) end
	local distance = dist + dot - norm:Dot(LocalPlayer():GetMegaPos() * InfMap2.ChunkSize) -- norm:Dot(trans)
	return render.INF_PushCustomClipPlane(norm, distance)
end

function render.INF_INTERNAL_SetupClippingOffset(voffset)
	--print("called", voffset and tostring(voffset) or "nil")
	offset = voffset
end

local VECTOR = FindMetaTable("Vector")
if not VECTOR then return end
VECTOR.INF_ToScreen = VECTOR.INF_ToScreen or VECTOR.ToScreen
function VECTOR:ToScreen()
	return VECTOR.INF_ToScreen(localize(self))
end