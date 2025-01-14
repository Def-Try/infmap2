-- included by infmap when api has set up and it wants to start generating the map
-- please note that file included in both SERVER and CLIENT realms, so everything related to world
-- generation should return same values in both realms
--
-- needs to return infmap info:
--   { -- table
--
--     ---- WORLD DATA ----
--     use_generator = true,                                    -- bool, does map use default generator
--     generator = function(x: number, y: number) -> z: number, -- function, height function for generator
--     chunksize = 20000,                                       -- number, chunk size in hammer units (max is 2^15)
--     megachunksize = 20,                                      -- number, megachunk size (how much megachunk extends in each direction, in chunks)
--     samplesize = 5000,                                       -- number, sample size (how far apart we sample height)
--
--     ---- RENDER DATA ----
--     material = "infmap2/grasslit" -- string, material that terrain should use
--     uvscale = 100                 -- number, infmap uv scale
--     perfacenormals = true,        -- bool, whether normals are calculater per-face or per-vertex
--     dolighting = false,           -- bool, whether we should calculate custom lighting
--     renderdistance = 2,           -- number, how much megachunks around player we show
--
--     ---- ENTITY DATA ----
--     spawner = function(ply: Player), -- function, player spawner function (call SetPos/SetAng/etc here)
--
--   }

AddCSLuaFile()
AddCSLuaFile("simplex.lua")

local simplex = include("simplex.lua")

if SERVER then
    local function create_origin_plat()
        local e = ents.Create("prop_physics")
        if not IsValid(e) then return end
        e:INF_SetPos(Vector(0, 0, -10))
        e:SetModel("models/hunter/blocks/cube8x8x025.mdl")
        e:SetMaterial("models/gibs/metalgibs/metal_gibs")
        e:SetName("INF_Bliss_SpawnPlatform")
        e:SetNW2Bool("INF_Bliss_SpawnPlatform", true)
        e:Spawn()
        e:GetPhysicsObject():EnableMotion(false)
        constraint.Weld(e, game.GetWorld(), 0, 0, 0)
        InfMap2.EntityUpdateMegapos(e, Vector())
    end

    hook.Add("InitPostEntity", "InfMap2BlissCreateOrigin", create_origin_plat)
    hook.Add("PostCleanupMap", "InfMap2BlissCreateOrigin", create_origin_plat)
    hook.Add("EntityRemoved",  "InfMap2BlissCreateOrigin", function(ent)
        if ent:GetName() ~= "INF_Bliss_SpawnPlatform" then return end
        create_origin_plat()
    end)
    hook.Add("PhysgunPickup", "InfMap2BlissOriginPropPhysgunable", function(ply, ent)
        if ent:GetName() == "INF_Bliss_SpawnPlatform" then return false end
    end)
else
    hook.Add("PhysgunPickup", "InfMap2BlissOriginPropPhysgunable", function(ply, ent)
        if ent:GetNW2Bool("INF_Bliss_SpawnPlatform") then return false end
    end)
end

local scale = 1

return {
    use_generator = true,
    generator = function(x, y)
        x = x / InfMap2.ChunkSize / 2
        y = y / InfMap2.ChunkSize / 2

        x, y = x / scale, y / scale
        if (x > -0.5 and x < 0.5) or (y > -0.5 and y < 0.5) then return -15 end
        x = x - 3
        local final = simplex.Noise2D(x / 25, y / 25 + 100000) * 75000
        final = final / math.max((simplex.Noise2D(x / 100, y / 100) * 15) ^ 3, 1)
        final = final * scale
        return final / 2
    end,
    chunksize = 10000, -- 20000, -- leaves 12768 units for contraptions and fast passing entities
    megachunksize = 20,
    samplesize = 5000,

    material = "infmap2/grasslit",
    uvscale = 100,
    perfacenormals = true,
    dolighting = false,
    renderdistance = 2,

    spawner = function(ply)
        ply:SetPos(Vector(0, 0, 10))
    end
}