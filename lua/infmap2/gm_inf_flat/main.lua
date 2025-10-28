-- direct port of gm_infmap from infmap1
-- do NOT touch except for fixing

AddCSLuaFile()
AddCSLuaFile("simplex.lua")

local simplex = include("simplex.lua")

if SERVER then
    local function create_origin_plat()
        ---@class Entity
        local e = ents.Create("prop_physics")
        if not IsValid(e) then return end
        e:INF_SetPos(Vector(0, 0, -10))
        e:SetModel("models/hunter/blocks/cube8x8x025.mdl")
        e:SetMaterial("models/gibs/metalgibs/metal_gibs")
        e:SetName("INF_Flat_SpawnPlatform")
        e:SetNWBool("INF_Flat_SpawnPlatform", true)
        e:SetOwner(game.GetWorld())
        function e:CreatedByMap() return true end
        function e:CanProperty(ply, prop) return false end
        e:Spawn()
        e:GetPhysicsObject():EnableMotion(false)
        constraint.Weld(e, game.GetWorld(), 0, 0, 0)
        InfMap2.EntityUpdateMegapos(e, Vector())
    end

    hook.Add("InitPostEntity", "InfMap2FlatCreateOrigin", create_origin_plat)
    hook.Add("PostCleanupMap", "InfMap2FlatCreateOrigin", create_origin_plat)
    hook.Add("EntityRemoved",  "InfMap2FlatCreateOrigin", function(ent)
        if ent:GetName() ~= "INF_Flat_SpawnPlatform" then return end
        timer.Simple(0, function()
            -- run in next tick because
            -- 1. old ent won't be in the way and
            -- 2. we won't overflow if server is shutting down
            create_origin_plat()
        end)
    end)
    hook.Add("PhysgunPickup", "InfMap2FlatOriginPropPhysgunable", function(ply, ent)
        if ent:GetName() == "INF_Flat_SpawnPlatform" then return false end
    end)
else
    hook.Add("PhysgunPickup", "InfMap2FlatOriginPropPhysgunable", function(ply, ent)
        if ent:GetNWBool("INF_Flat_SpawnPlatform") then return false end
    end)
end

resource.AddSingleFile("materials/infmap2/grasslit.vmt")

local noise2d = simplex.Noise2D
return {
    chunksize = 20000, -- leaves 12768 units for contraptions and fast passing entities
    world = {
        terrain = {
            has_terrain = true,
            height_function = function(x, y)
                return -15
            end,
            samples = {3},
        }
    },
    visual = {
        renderdistance = 30,
        terrain = {
            material = "infmap2/grasslit", -- "models/wireframe",
            uvscale = 100,
        },
        clouds = {
            has_clouds = true,
            height = 200000,
            layers = 10,
            size = 512,
            scale = 1,
            direction = Vector(0, 1, 0),
            speed = 500,
            color = Color(255, 255, 255),
            accentcolor = Color(200, 200, 200),
            density_function = function(x, y, layer)
                return ((simplex.Noise3D(x / 30, y / 30, layer / 50) - layer * 0.015) * 1024
                         + (simplex.Noise2D(x / 7, y / 7) + 1) * 128) / 256
            end,
        },
        fog = {
            has_fog = true,
            color = Color(180, 190, 200),
            fogstart = 500000,
            fogend = 1000000,
            maxdensity = 0.5
        },
        skybox = {
            has_skybox = true,
            material = "infmap2/grasslit",
            size = 2000000000,
            uvscale = 2000000000 * 100,
            height = -100000
        }
    },

    spawner = function(ply)
        ply:SetPos(Vector(0, 0, 10))
    end
}