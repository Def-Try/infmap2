local sky = Material("infmap2/sky")

hook.Add("PostDraw2DSkyBox", "InfMap2SpaceSkybox", function()
	local eyepos = EyePos()
	local color = eyepos.z / InfMap2.Space.Height

	render.OverrideDepthEnable(true, false)
	sky:SetFloat("$alpha", color)
	render.SetMaterial(sky)
	render.DrawSphere(EyePos(), -180, 50, 50)
	render.OverrideDepthEnable(false, false)
end)