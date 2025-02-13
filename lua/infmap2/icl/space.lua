local sky = Material("infmap2/space/sky")

hook.Add("PostDraw2DSkyBox", "InfMap2SpaceSkybox", function()
	if not InfMap2.Space.HasSpace then return end
	local eyepos = EyePos()
	local color = eyepos.z / InfMap2.Space.Height

	render.OverrideDepthEnable(true, false)
	sky:SetFloat("$alpha", color)
	render.SetMaterial(sky)
	render.DrawSphere(eyepos, -180, 50, 50)
	render.OverrideDepthEnable(false, false)
end)