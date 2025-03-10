AddCSLuaFile()

InfMap2.EnableDevBanner = true

AddCSLuaFile("infmap2/icl/popups.lua")
if CLIENT then include("infmap2/icl/popups.lua") end

--if InfMap2.Debug == nil then InfMap2.Debug = true end
if InfMap2.Debug == nil then InfMap2.Debug = false end

InfMap2.Version = "0.2b"

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

local main = include("infmap2/"..game.GetMap().."/main.lua")
if not main then
    ErrorNoHalt("InfMap2 main file did not return infmap data. Falling back to gm_inf_bliss")
    main = include("infmap2/gm_inf_bliss/main.lua")
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
    InfMap2.World.Terrain.SampleSize = main.world.terrain.samplesize or InfMap2.ChunkSize / 3
    InfMap2.World.GenPerTick = main.world.genpertick or 400

    InfMap2.Visual.RenderDistance = main.visual.renderdistance or 2
    InfMap2.Visual.MegachunkSize = main.visual.megachunksize or 30

    InfMap2.Visual.Terrain.PerFaceNormals = main.visual.terrain.perfacenormals or false
    InfMap2.Visual.Terrain.DoLighting = main.visual.terrain.dolighting or false
    InfMap2.Visual.Terrain.Material = main.visual.terrain.material
    InfMap2.Visual.Terrain.UVScale = main.visual.terrain.uvscale or 100
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

InfMap2.Visual.HasFog = main.visual.fog.has_fog or false
if InfMap2.Visual.HasFog then
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
        idata.SampleSize = data.samplesize or idata.Radius / 10
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

include("infmap2/ish/world.lua")
include("infmap2/ish/space.lua")
include("infmap2/ish/collision.lua")
include("infmap2/ish/functions.lua")
include("infmap2/ish/detours.lua")

if SERVER then
    AddCSLuaFile("infmap2/icl/world.lua")
    AddCSLuaFile("infmap2/icl/clouds.lua")
    AddCSLuaFile("infmap2/icl/space.lua")
    AddCSLuaFile("infmap2/icl/fog.lua")
    AddCSLuaFile("infmap2/icl/positioning.lua")
    AddCSLuaFile("infmap2/icl/detours.lua")
    AddCSLuaFile("infmap2/icl/debug.lua")
    AddCSLuaFile("infmap2/icl/sound.lua")
    AddCSLuaFile("infmap2/icl/misc.lua")

    include("infmap2/isv/world.lua")
    include("infmap2/isv/space.lua")
    include("infmap2/isv/positioning.lua")
    include("infmap2/isv/detours.lua")
    include("infmap2/isv/wrapping.lua")
    include("infmap2/isv/crosschunkcollision.lua")
    include("infmap2/isv/concommands.lua")
    include("infmap2/isv/sound.lua")
end

if CLIENT then
    include("infmap2/icl/world.lua")
    include("infmap2/icl/clouds.lua")
    include("infmap2/icl/space.lua")
    include("infmap2/icl/fog.lua")
    include("infmap2/icl/positioning.lua")
    include("infmap2/icl/detours.lua")
    include("infmap2/icl/sound.lua")
    include("infmap2/icl/misc.lua")
end
resource.AddFile("infmap2/space/sky.vmt")

hook.Add("InitPostEntity", "InfMap2Init", function() timer.Simple(0, function()
    RunConsoleCommand("sv_maxvelocity", InfMap2.MaxVelocity)
    if CLIENT then
        LocalPlayer():ConCommand("cl_drawspawneffect 0")
        include("infmap2/icl/debug.lua")
        InfMap2.EntityUpdateMegapos(LocalPlayer(), Vector())
    end
end) end)

hook.Add("PlayerSpawn", "InfMap2ResetSpawnPos", function(ply)
    if main.spawner then -- allow main file to define how players spawn
        return main.spawner(ply) 
    end
    ply:SetPos(Vector())
end)