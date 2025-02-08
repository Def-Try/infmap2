AddCSLuaFile()

InfMap2.EnableDevBanner = true

hook.Add("HUDPaint", "INFMAP2WIPBANNERREMOVEMELATER", function()
    if not InfMap2.EnableDevBanner then return end
    local h = 52+26
    surface.SetDrawColor(0, 0, 0, 190)

    surface.DrawRect(ScrW() / 4, 5, ScrW() / 2, h)

    surface.SetDrawColor(255, 255, 255, 255)
    surface.DrawOutlinedRect(ScrW() / 4, 5, ScrW() / 2, h, 2)

    draw.DrawText("InfMap2 "..InfMap2.Version, "DermaDefault",
        ScrW() / 2, 9, color_white, TEXT_ALIGN_CENTER)

    draw.DrawText("THIS IS A BETA VERSION\nEVERYTHING YOU SEE IS SUBJECT TO CHANGE",
    "DermaLarge", ScrW() / 2, 19, color_white, TEXT_ALIGN_CENTER)
end)

--if InfMap2.Debug == nil then InfMap2.Debug = true end
if InfMap2.Debug == nil then InfMap2.Debug = false end

InfMap2.Version = "0.1b"

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

InfMap2.MaxVelocity = 13503.95 * 20 -- mach 20 in hammer units
InfMap2.SourceBounds = Vector(2^14, 2^14, 2^14)

InfMap2.World = {}
InfMap2.World.Terrain = {}
InfMap2.Visual = {}
InfMap2.Visual.Terrain = {}
InfMap2.Visual.Clouds = {}
InfMap2.Visual.Fog = {}
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

InfMap2.ChunkSize = main.chunksize
InfMap2.World.HasTerrain = main.world.terrain.has_terrain or false
InfMap2.Visual.HasTerrain = InfMap2.World.HasTerrain -- alias
if InfMap2.World.HasTerrain then
    InfMap2.World.Terrain.HeightFunction = main.world.terrain.height_function
    InfMap2.World.Terrain.SampleSize = main.world.terrain.samplesize
    InfMap2.World.GenPerTick = main.world.genpertick

    InfMap2.Visual.RenderDistance = main.visual.renderdistance
    InfMap2.Visual.MegachunkSize = main.visual.megachunksize

    InfMap2.Visual.Terrain.PerFaceNormals = main.visual.terrain.perfacenormals
    InfMap2.Visual.Terrain.DoLighting = main.visual.terrain.dolighting
    InfMap2.Visual.Terrain.Material = main.visual.terrain.material
    InfMap2.Visual.Terrain.UVScale = main.visual.terrain.uvscale
end

InfMap2.Visual.HasClouds = main.visual.clouds.has_clouds or false
if InfMap2.Visual.HasClouds then
    InfMap2.Visual.Clouds.Height = main.visual.clouds.height
    InfMap2.Visual.Clouds.Color = main.visual.clouds.color
    InfMap2.Visual.Clouds.AccentColor = main.visual.clouds.accentcolor
    InfMap2.Visual.Clouds.Layers = main.visual.clouds.layers
    InfMap2.Visual.Clouds.Size = main.visual.clouds.size
    InfMap2.Visual.Clouds.Scale = main.visual.clouds.scale
    InfMap2.Visual.Clouds.DensityFunction = main.visual.clouds.density_function
    InfMap2.Visual.Clouds.Direction = main.visual.clouds.direction
    InfMap2.Visual.Clouds.Speed = main.visual.clouds.speed
end

InfMap2.Visual.HasFog = main.visual.fog.has_fog or false
if InfMap2.Visual.HasFog then
    InfMap2.Visual.Fog.Color = main.visual.fog.color
    InfMap2.Visual.Fog.Start = main.visual.fog.fogstart
    InfMap2.Visual.Fog.End = main.visual.fog.fogend
    InfMap2.Visual.Fog.MaxDensity = main.visual.fog.maxdensity
end

InfMap2.Space.HasSpace = main.space.has_space or false
if InfMap2.Space.HasSpace then
    InfMap2.Space.PlanetDistance = main.space.planet_distance
    InfMap2.Space.Height = main.space.height
    InfMap2.Space.Planets = {}
    for name, data in pairs(main.space.planets) do
        local idata = {}
        InfMap2.Space.Planets[name] = idata
        idata.HeightFunction = data.height_function
        idata.Atmosphere = data.atmosphere
        if idata.Atmosphere then
            local r, g, b, a = idata.Atmosphere:Unpack()
            idata.Atmosphere = {Vector(r / 255, g / 255, b / 255), a / 255}
        end
        idata.Clouds = data.clouds
        idata.Radius = data.radius
        idata.SampleSize = data.samplesize
        idata.UVScale = data.uvscale
        idata.MaterialOverrides = {}
        for n, material in pairs(data.material_overrides) do
            idata.MaterialOverrides[n] = Material(material)
        end
        idata.MaterialOverrides["outside"] = idata.MaterialOverrides["outside"] or Material("infmap2/planets/"..name.."_outside")
        idata.MaterialOverrides["inside"] = idata.MaterialOverrides["inside"] or Material("infmap2/planets/"..name.."_inside")
        idata.MaterialOverrides["clouds"] = idata.MaterialOverrides["clouds"] or Material("infmap2/planets/"..name.."_clouds")
    end
end

include("infmap2/ish/baking.lua")

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