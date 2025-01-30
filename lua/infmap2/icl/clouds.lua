InfMap2.Cache.cloud_rts = InfMap2.Cache.cloud_rts or {}
InfMap2.Cache.cloud_mats = InfMap2.Cache.cloud_mats or {}

local cloud_coro = coroutine.create(function()
    if not InfMap2.Visual.HasClouds then return end
     
    local scale = InfMap2.Visual.Clouds.Scale
    local size = InfMap2.Visual.Clouds.Size * scale
    local half_size = size / 2

    local col = InfMap2.Visual.Clouds.Color
    local acol = InfMap2.Visual.Clouds.AccentColor

	for i = 1, InfMap2.Visual.Clouds.Layers do
		InfMap2.Cache.cloud_rts[i] = GetRenderTarget("infmap_clouds" .. i .. "_" .. size, size, size)
		InfMap2.Cache.cloud_mats[i] = CreateMaterial("infmap_clouds" .. i .. "_" .. size, "UnlitGeneric", {
			["$basetexture"] = InfMap2.Cache.cloud_rts[i]:GetName(),
			["$model"] = "1",
			["$nocull"] = "1",
			["$translucent"] = "1",
		})
		render.ClearRenderTarget(InfMap2.Cache.cloud_rts[i], Color(acol.r, acol.g, acol.b, 0)) -- make gray so clouds have nice gray sides
	end

    local density_function = InfMap2.Visual.Clouds.DensityFunction

    for y = -half_size, half_size, scale do
        for layer = 1, InfMap2.Visual.Clouds.Layers do
            render.PushRenderTarget(InfMap2.Cache.cloud_rts[layer]) cam.Start2D()
            for x = -half_size, half_size, scale do
				surface.SetDrawColor(col.r, col.g, col.b, density_function(x, y, layer) * 256)
				surface.DrawRect(x+half_size, y+half_size, scale, scale)
            end
            cam.End2D() render.PopRenderTarget()
        end
        coroutine.yield()
    end

    render.SetColorMaterialIgnoreZ()
    if scale > 1 then
        for layer = 1, InfMap2.Visual.Clouds.Layers do
            --BlurRenderTarget(InfMap2.Cache.cloud_rts[layer], 100, 100, scale*2)
            -- TODO: blur? maybe?
        end
    end
end)

hook.Add("PreDrawTranslucentRenderables", "infmap_clouds", function(_, sky)
    if not InfMap2.Visual.HasClouds then return end
	if sky then return end -- dont render in skybox
	local offset = LocalPlayer():GetMegaPos()
	--offset[1] = ((offset[1] + 250 + CurTime() * 0.1) % 500) - 250
	--offset[2] = ((offset[2] + 250 + CurTime() * 0.1) % 500) - 250
	offset[3] = offset[3] - (InfMap2.Visual.Clouds.Height / InfMap2.ChunkSize)

	if coroutine.status(cloud_coro) == "suspended" then
		coroutine.resume(cloud_coro)
	end

    local speed = InfMap2.Visual.Clouds.Speed
    local direction = InfMap2.Visual.Clouds.Direction * 10000
    local move = (((CurTime()) % speed) - speed / 2)

	-- render cloud planes
	for i = 1, InfMap2.Visual.Clouds.Layers do -- overlay planes to give amazing 3d look
		render.SetMaterial(InfMap2.Cache.cloud_mats[i])
		render.DrawQuadEasy(
            Vector(direction[1] * move + offset[1] * InfMap2.ChunkSize,
                   direction[2] * move + offset[2] * InfMap2.ChunkSize,
                   (i - 1) * 10000 + InfMap2.Visual.Clouds.Height
            ), Vector(0, 0, 1), 20000000, 20000000)
	end
end)