AddCSLuaFile()

InfMap2.EnableDevBanner = true

--if InfMap2.Debug == nil then InfMap2.Debug = true end
if InfMap2.Debug == nil then InfMap2.Debug = false end

InfMap2.Version = "0.32b"
print("[INFMAP2] Running InfMap2 version "..InfMap2.Version)

InfMap2.MaxVelocity = 13503.95 * 20 -- mach 20 in hammer units
InfMap2.SourceBounds = Vector(2^14, 2^14, 2^14)

InfMap2.World = {}
InfMap2.World.Terrain = {}
InfMap2.Visual = {}
InfMap2.Visual.Terrain = {}
InfMap2.Visual.Clouds = {}
InfMap2.Visual.Fog = {}
InfMap2.Visual.Skybox = {}
InfMap2.Space = {}

function InfMap2.Gilb()
    local mapfile = "infmap2/"..game.GetMap().."/main.lua"
    print("[INFMAP2] Loading map file `"..mapfile.."`")
    local main = include(mapfile)
    if not main then
        ErrorNoHalt("InfMap2 main file did not return infmap data. Falling back to gm_inf_bliss")
        print("[INFMAP2] Loading fallback map file. Check above for errors!")
        main = include("infmap2/gm_inf_bliss/main.lua")
    else
        AddCSLuaFile(mapfile)
    end
    main.world = main.world or {}
    main.world.terrain = main.world.terrain or {}
    main.visual = main.visual or {}
    main.visual.terrain = main.visual.terrain or {}
    main.visual.clouds = main.visual.clouds or {}
    main.visual.fog = main.visual.fog or {}
    main.visual.skybox = main.visual.skybox or {}
    main.space = main.space or {}

    InfMap2.ChunkSize = main.chunksize or 20000
    InfMap2.World.HasTerrain = main.world.terrain.has_terrain or false
    InfMap2.Visual.HasTerrain = InfMap2.World.HasTerrain -- alias
    InfMap2.RemoveHeight = main.removeheight or -100000
    if InfMap2.World.HasTerrain then
        if not main.world.terrain.height_function then
            ErrorNoHalt("InfMap doesn't have height function!")
            main.world.terrain.height_function = function() return -15 end
        end
        if not main.visual.terrain.material then
            ErrorNoHalt("InfMap doesn't have material!")
            main.visual.terrain.material = "models/wireframe"
        end
        InfMap2.World.Terrain.HeightFunction = main.world.terrain.height_function
        InfMap2.World.Terrain.Samples = main.world.terrain.samples or {3}

        InfMap2.Visual.RenderDistance = main.visual.renderdistance or 20
        InfMap2.Visual.RealRenderDistance = InfMap2.Visual.RenderDistance

        InfMap2.Visual.Terrain.Material = main.visual.terrain.material
        InfMap2.Visual.Terrain.UVScale = main.visual.terrain.uvscale or 100
        InfMap2.World.Terrain.LODLevels = table.Copy(InfMap2.World.Terrain.Samples)
    end

    InfMap2.Visual.HasClouds = main.visual.clouds.has_clouds or false
    if InfMap2.Visual.HasClouds then
        if not main.visual.clouds.density_function then
            ErrorNoHalt("InfMap doesn't have clouds density function!")
            main.visual.clouds.density_function = function() return 0.5 end
        end
        InfMap2.Visual.Clouds.DensityFunction = main.visual.clouds.density_function
        InfMap2.Visual.Clouds.Height = main.visual.clouds.height or 200000
        InfMap2.Visual.Clouds.Color = main.visual.clouds.color or color_white
        InfMap2.Visual.Clouds.AccentColor = main.visual.clouds.accentcolor or color_black
        InfMap2.Visual.Clouds.Layers = main.visual.clouds.layers or 1
        InfMap2.Visual.Clouds.Size = main.visual.clouds.size or 256
        InfMap2.Visual.Clouds.Scale = main.visual.clouds.scale or 1
        InfMap2.Visual.Clouds.Direction = main.visual.clouds.direction or vector_origin
        InfMap2.Visual.Clouds.Speed = main.visual.clouds.speed or 0
    end

    InfMap2.Visual.Fog.HasFog = main.visual.fog.has_fog or false
    if InfMap2.Visual.Fog.HasFog then
        InfMap2.Visual.Fog.Color = main.visual.fog.color or color_white
        InfMap2.Visual.Fog.Start = main.visual.fog.fogstart or 500000
        InfMap2.Visual.Fog.End = main.visual.fog.fogend or 1000000
        InfMap2.Visual.Fog.MaxDensity = main.visual.fog.maxdensity or 1
    end

    InfMap2.Visual.HasSkybox = main.visual.skybox.has_skybox or false
    if InfMap2.Visual.HasSkybox then
        InfMap2.Visual.Skybox.Material = main.visual.skybox.material or InfMap2.Visual.Terrain.Material
        InfMap2.Visual.Skybox.Size = main.visual.skybox.size or 2000000000
        InfMap2.Visual.Skybox.UVScale = main.visual.skybox.uvscale or 1000000
        InfMap2.Visual.Skybox.Height = main.visual.skybox.height or -100000
    end

    InfMap2.Space.HasSpace = main.space.has_space or false
    if InfMap2.Space.HasSpace then
        InfMap2.Space.PlanetDistance = main.space.planet_distance or 400000
        InfMap2.Space.Height = main.space.height or 500000
        InfMap2.Space.Planets = {}
        for name, data in pairs(main.space.planets) do
            local idata = {}
            InfMap2.Space.Planets[name] = idata
            if not data.height_function then
                ErrorNoHalt("InfMap planet "..name.." doesn't have height function!")
                data.height_function = function() return 0 end
            end
            idata.HeightFunction = data.height_function
            idata.Atmosphere = data.atmosphere
            if idata.Atmosphere then
                local r, g, b, a = idata.Atmosphere:Unpack()
                idata.Atmosphere = {Vector(r / 255, g / 255, b / 255), a / 255}
            end
            idata.Clouds = data.clouds
            idata.Radius = data.radius or 5000
            idata.Samples = data.samples or (idata.Radius * 2) / 10
            idata.UVScale = data.uvscale or 10
            idata.MaterialOverrides = {}
            for n, material in pairs(data.material_overrides) do
                idata.MaterialOverrides[n] = Material(material)
            end
            idata.MaterialOverrides["outside"] = idata.MaterialOverrides["outside"] or Material("infmap2/planets/"..name.."_outside")
            idata.MaterialOverrides["inside"] = idata.MaterialOverrides["inside"] or Material("infmap2/planets/"..name.."_inside")
            idata.MaterialOverrides["clouds"] = idata.MaterialOverrides["clouds"] or Material("infmap2/planets/"..name.."_clouds")
        end
    end
end

function InfMap2.Caleb()
    local shared_files, _ = file.Find("infmap2/ish/*", "LUA")
    local client_files, _ = file.Find("infmap2/icl/*", "LUA")
    local client_shader_files, _ = file.Find("infmap2/icl/shaders/*", "LUA")
    local server_files, _ = file.Find("infmap2/isv/*", "LUA")
    for _, file_ in ipairs(shared_files) do
        print("[INFMAP2] Loading shared file `"..file_.."`")
        AddCSLuaFile("infmap2/ish/"..file_)
        include("infmap2/ish/"..file_)
    end
    for _, file_ in ipairs(client_files) do
        if CLIENT then
            print("[INFMAP2] Loading client file `"..file_.."`")
            include("infmap2/icl/"..file_)
        end
        if SERVER then
            print("[INFMAP2] Adding client file `"..file_.."`")
            AddCSLuaFile("infmap2/icl/"..file_)
        end
    end
    for _, file_ in ipairs(client_shader_files) do
        if SERVER then
            print("[INFMAP2] Adding client file `"..file_.."`")
            AddCSLuaFile("infmap2/icl/shaders/"..file_)
        end
    end
    if SERVER then
        for _, file_ in ipairs(server_files) do 
            print("[INFMAP2] Loading server file `"..file_.."`")
            include("infmap2/isv/"..file_)
        end
    end
end

resource.AddFile("infmap2/space/sky.vmt")

hook.Add("InitPostEntity", "InfMap2Init", function() timer.Simple(0, function()
    RunConsoleCommand("sv_maxvelocity", InfMap2.MaxVelocity)
    if CLIENT then
        LocalPlayer():ConCommand("cl_drawspawneffect 0")
        InfMap2.EntityUpdateMegapos(LocalPlayer(), Vector())
    end
end) end)

--[[
if CLIENT then
    if InfMap2.ConVars.vis_chunklods_tbl then
        InfMap2.World.Terrain.LODLevels = {InfMap2.World.Terrain.Samples[1], unpack(InfMap2.ConVars.vis_chunklods_tbl)}
    end
end
--]]

print("[INFMAP2] Initialisations complete!")