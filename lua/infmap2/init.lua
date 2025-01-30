AddCSLuaFile()

--if InfMap2.Debug == nil then InfMap2.Debug = true end
if InfMap2.Debug == nil then InfMap2.Debug = false end

InfMap2.Version = "0.1b"

include("infmap2/ish/world.lua")
include("infmap2/ish/collision.lua")
include("infmap2/ish/functions.lua")
include("infmap2/ish/detours.lua")

if SERVER then
    include     ("infmap2/isv/world.lua")
    include     ("infmap2/isv/positioning.lua")
    include     ("infmap2/isv/detours.lua")
    AddCSLuaFile("infmap2/icl/world.lua")
    AddCSLuaFile("infmap2/icl/clouds.lua")
    AddCSLuaFile("infmap2/icl/fog.lua")
    AddCSLuaFile("infmap2/icl/positioning.lua")
    AddCSLuaFile("infmap2/icl/detours.lua")
    AddCSLuaFile("infmap2/icl/debug.lua")
    AddCSLuaFile("infmap2/icl/sound.lua")

    include("infmap2/isv/wrapping.lua")
    include("infmap2/isv/crosschunkcollision.lua")
    include("infmap2/isv/concommands.lua")
    include("infmap2/isv/sound.lua")

    resource.AddSingleFile("materials/infmap2/grasslit.vmt")
    resource.AddSingleFile("materials/infmap2/grassunlit.vmt")
end

if CLIENT then
    include("infmap2/icl/world.lua")
    include("infmap2/icl/clouds.lua")
    include("infmap2/icl/fog.lua")
    include("infmap2/icl/positioning.lua")
    include("infmap2/icl/detours.lua")
    include("infmap2/icl/sound.lua")
end

InfMap2.MaxVelocity = 13503.95 * 20 -- mach 20 in hammer units
InfMap2.SourceBounds = Vector(2^14, 2^14, 2^14)

InfMap2.World = {}
InfMap2.World.Terrain = {}
InfMap2.Visual = {}
InfMap2.Visual.Terrain = {}
InfMap2.Visual.Clouds = {}
InfMap2.Visual.Fog = {}

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
end

InfMap2.Visual.HasFog = main.visual.clouds.has_fog or false
if InfMap2.Visual.HasFog then
    InfMap2.Visual.Fog.Color = main.visual.fog.color
    InfMap2.Visual.Fog.Start = main.visual.fog.fogstart
    InfMap2.Visual.Fog.End = main.visual.fog.fogend
    InfMap2.Visual.Fog.MaxDensity = main.visual.fog.maxdensity
end

InfMap2.ChunkSize = main.chunksize

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