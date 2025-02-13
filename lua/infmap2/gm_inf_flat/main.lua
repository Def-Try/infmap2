AddCSLuaFile()

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

return {
    world = {
        chunksize = 20000,
        terrain = {
            has_terrain = true,
            height_function = function(x, y)
                return -15
            end,
            samplesize = 20000
        },
    },
    visual = {
        terrain = {
            material = "infmap2/grasslit",
            uvscale = 1000
        }
    }
}