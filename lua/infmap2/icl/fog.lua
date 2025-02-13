hook.Add("SetupWorldFog", "InfMap2WorldFog", function()
	if not InfMap2.Visual.Fog.HasFog then return end
    local color = InfMap2.Visual.Fog.Color
	render.FogStart(InfMap2.Visual.Fog.Start)
	render.FogMaxDensity(InfMap2.Visual.Fog.MaxDensity)
	render.FogColor(color.r, color.g, color.b)
	render.FogEnd(InfMap2.Visual.Fog.End)
	render.FogMode(MATERIAL_FOG_LINEAR)
	return true
end)