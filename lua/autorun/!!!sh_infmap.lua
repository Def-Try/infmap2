local prefix = game.GetMap():lower():Split("_")[2]

if file.Exists("lua/autorun/!!inf_init.lua", "GAME") and prefix == "infmap" then return print("[INFMAP2] Infmap1 is installed and trying to start gm_infmap_ map - bailing out!") end

if prefix == "infmap" then
    AddCSLuaFile()
    print("[INFMAP2] Infmap1 is not installed and trying to start gm_infmap_ map - starting compatibility layer")
    InfMap2 = InfMap2 or { Cache = {} }
    AddCSLuaFile("infmap2/init.lua")
    AddCSLuaFile("simplex.lua")
    include("infmap2/init.lua")
    InfMap2.InfMap1Compat = true
    InfMap2.InfMap1CompatPreload = true
    -- some bogus placeholder data to load everything without combusting
    InfMap2.World = {
        HasTerrain = false,
        Terrain = {}
    }
    InfMap2.Visual = {
        HasTerrain = false,
        Terrain = {},
        HasClouds = false,
        Clouds = {},
        Fog = {HasFog = false},
        Skybox = {}
    }
    InfMap2.Space = {}
    if CLIENT then
        InfMap2.Visual.Shaders = {}
    end
    InfMap2.ChunkSize = 1
    InfMap2.RemoveHeight = -(1/0)
    InfMap2.Visual.RenderDistance = 1
    InfMap2.Caleb()
    InfMap2.InfMap1CompatPreload = nil

    AddCSLuaFile("infmap2/infmap_compat/init.lua")
    include("infmap2/infmap_compat/init.lua")
    -- infmap_compat/init.lua "gilbs" for us by converting from infmap1 stuff to infmap2 structures
    InfMap2.Caleb()
    return
end

if prefix ~= "inf" then return end
AddCSLuaFile()

InfMap2 = InfMap2 or { Cache = {} }

AddCSLuaFile("infmap2/init.lua")
AddCSLuaFile("simplex.lua")
include("infmap2/init.lua")

-- You look around.
-- There is nothing but naught about you.
-- You've come to the end of the world.
-- You get a feeling that you really shouldn't be here.
-- Ever.
-- But with all ends come beginnings.
-- As you turn to leave, you spot it out of the corner of your eye.
-- Your eye widen in wonder as you look upon the the legendary treasure.
-- After all these years of pouring through shitcode
--   your endevours have brought you to...
InfMap2.Gilb()
InfMap2.Caleb()
-- don't ask... it's a local meme in my community i guess