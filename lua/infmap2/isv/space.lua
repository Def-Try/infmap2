InfMap2.Cache.SpawnedPlanets = InfMap2.Cache.SpawnedPlanets or {}

local function find_closest_planet_distance(ply)
    local closest = math.huge
    local pos = ply:GetPos()
    for _,planet in ipairs(InfMap2.Cache.SpawnedPlanets) do
        closest = math.min(planet:GetPos():Distance(pos), closest)
    end
    return closest
end

local function find_closest_player_distance(pos)
    local closest = math.huge
    for _, ply in player.Iterator() do
        closest = math.min(ply:GetPos():Distance(pos), closest)
    end
    return closest
end

timer.Create("InfMap2SpaceGenerator", 0, 0, function()
    for _, ply in player.Iterator() do
        if ply:GetPos().z < InfMap2.Space.Height + InfMap2.Space.PlanetDistance then continue end
        local closest = find_closest_planet_distance(ply)
        if closest < InfMap2.Space.PlanetDistance * 2 then continue end
        local pos = nil
        for _=1,5 do
            pos = ply:GetPos() + AngleRand():Forward() * InfMap2.Space.PlanetDistance
            local closest = find_closest_player_distance(pos)
            if closest < InfMap2.Space.PlanetDistance then pos = nil continue end
        end
        if not pos then continue end
        local planettypes = table.GetKeys(InfMap2.Space.Planets)
        local planet = ents.Create("inf_planet")
        planet:Spawn()
        -- not sure why megapos isn't able to be set up right there. oh well.
        timer.Simple(0, function()
            planet:SetPos(pos)
            planet:SetNW2String("INF_PlanetType", planettypes[math.random(1, #planettypes)])
        end)
        table.insert(InfMap2.Cache.SpawnedPlanets, planet)
        break -- one planet per tick
    end
end)