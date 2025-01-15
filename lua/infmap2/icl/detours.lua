local function localize(pos) return pos - (LocalPlayer().INF_MegaPos or Vector()) * InfMap2.ChunkSize end

render.INF_ComputeDynamicLighting = render.INF_ComputeDynamicLighting or render.ComputeDynamicLighting
function render.ComputeDynamicLighting(pos, normal) return render.INF_ComputeDynamicLighting(localize(pos), normal) end
render.INF_ComputeLighting = render.INF_ComputeLighting or render.ComputeLighting
function render.ComputeLighting(pos, normal) return render.INF_ComputeLighting(localize(pos), normal) end

render.INF_ComputePixelDiameterOfSphere = render.INF_ComputePixelDiameterOfSphere or render.ComputePixelDiameterOfSphere
function render.ComputePixelDiameterOfSphere(pos, radius) return render.INF_ComputePixelDiameterOfSphere(localize(pos), radius) end

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

cam.INF_Start3D2D = cam.INF_Start3D2D or cam.Start3D2D
function cam.Start3D2D(pos, ang, scale) return cam.INF_Start3D2D(localize(pos), ang, scale) end

render.INF_DrawBeam = render.INF_DrawBeam or render.DrawBeam
function render.DrawBeam(start, endpos, width, texstart, texend, color) return render.INF_DrawBeam(localize(start), localize(endpos), width, texstart, texend, color) end
render.INF_AddBeam = render.INF_AddBeam or render.AddBeam
function render.AddBeam(start, width, texend, color) return render.INF_AddBeam(localize(start), width, texend, color) end

render.INF_Model = render.INF_Model or render.Model
function render.Model(settings, csent)
	settings.pos = localize(settings.pos)
	return render.INF_Model(settings, csent)
end
render.INF_RenderView = render.INF_RenderView or render.RenderView
function render.RenderView(view)
	view.origin = localize(view.origin)
	return render.INF_RenderView(view)
end

