if game.GetMap():lower():Split("_")[2] ~= "inf" then return end
AddCSLuaFile()

InfMap2 = InfMap2 or { Cache = {} }

AddCSLuaFile("infmap2/init.lua")
AddCSLuaFIle("infmap2/simplex.lua")
include("infmap2/init.lua")