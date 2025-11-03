if game.GetMap():lower():Split("_")[2] ~= "inf" then return end
AddCSLuaFile()

InfMap2 = InfMap2 or { Cache = {} }

AddCSLuaFile("infmap2/init.lua")
AddCSLuaFile("infmap2/simplex.lua")
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