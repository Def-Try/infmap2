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
    include("infmap2/icl/positioning.lua")
    include("infmap2/icl/detours.lua")
    include("infmap2/icl/sound.lua")
end

InfMap2.MaxVelocity = 13503.95 * 20 -- mach 20 in hammer units
InfMap2.SourceBounds = Vector(2^14, 2^14, 2^14)

local main = include("infmap2/"..game.GetMap().."/main.lua")
if not main then
    ErrorNoHalt("InfMap2 main file did not return infmap data. Falling back to gm_inf_bliss")
    main = include("infmap2/gm_inf_bliss/main.lua")
end
main.world = main.world or {}
main.visual = main.visual or {}
main.visual.terrain = main.visual.terrain or {}
InfMap2.UsesGenerator = main.world.use_generator
if InfMap2.UsesGenerator then
    InfMap2.HeightFunction = main.world.generator
    InfMap2.SampleSize = main.world.samplesize
    InfMap2.GenPerTick = main.world.genpertick

    InfMap2.RenderDistance = main.visual.renderdistance
    InfMap2.MegachunkSize = main.visual.megachunksize
    
    InfMap2.PerFaceNormals = main.visual.terrain.perfacenormals
    InfMap2.DoLighting = main.visual.terrain.dolighting
    InfMap2.Material = main.visual.terrain.material
    InfMap2.UVScale = main.visual.terrain.uvscale
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