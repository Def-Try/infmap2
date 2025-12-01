InfMap = InfMap or {}

-- setup INF_ -> InfMap_ passthrough
for _,mtn in ipairs({"Entity", "PhysObj", "Vehicle"}) do
    local mt = FindMetaTable(mtn)
    if not mt then continue end
    for nam, val in pairs(mt) do
        if not string.StartsWith(nam, "INF_") then continue end
        mt["InfMap_"..nam:sub(5)] = val
    end
end

InfMap.filter = InfMap.filter or {
	infmap_clone = true,
	infmap_obj_collider = true,
	physgun_beam = true,
	worldspawn = true,
	gmod_hands = true,
	info_particle_system = true,
	predicted_viewmodel = true,
	env_projectedtexture = true,
	keyframe_rope = true,
	hl2mp_ragdoll = true,
	env_skypaint = true,
	shadow_control = true,
	env_sun = true,
	info_player_start = true,
	scene_manager = true,
	ai_network = true,
	network = true,
	bodyque = true,
	gmod_gamerules = true,
	player_manager = true,
	soundent = true,
	env_flare = true,
	_firesmoke = true,
	func_brush = true,
	logic_auto = true,
	light_environment = true,
	env_laserdot = true,
	env_smokestack = true,
	env_rockettrail = true,
	rpg_missile = true,
	gmod_safespace_interior = true,
	env_fog_controller = true,
	sizehandler = true,
	player_pickup = true,
	phys_spring = true,
	crossbow_bolt = true,
}

InfMap.disable_pickup = InfMap.disable_pickup or {
	infmap_clone = true,
	infmap_obj_collider = true,
}

function InfMap.filter_entities(e)
	if InfMap.filter[e:GetClass()] then return true end
	if e:EntIndex() == 0 then return true end
	if SERVER and e:IsConstraint() then return true end

	return false
end

InfMap.unlocalize_vector = InfMap2.UnlocalizePosition
InfMap.localize_vector = InfMap2.LocalizePosition
InfMap.prop_update_chunk = function(ent, chunk) return InfMap2.EntityUpdateMegapos(ent, chunk) end
InfMap.ezcoord = function(chunk) return chunk[1] .. "," .. chunk[2] .. "," .. chunk[3] end
InfMap.megachunk_size = 10
InfMap.chunk_size = 10000
InfMap.source_bounds = Vector(1, 1, 1) * math.pow(2, 14)

---@diagnostic disable: undefined-field, need-check-nil, inject-field
local ENTITY = FindMetaTable("Entity")
function ENTITY:SetMegaPos(vec)
    self.CHUNK_OFFSET = Vector(vec)
    if self.INF_MegaPos == vec then return end
    self.INF_MegaPos = Vector(vec)
    self:SetNW2Vector("INF_MegaPos", vec)
end
hook.Add("OnEntityCreated", "InfMap2IM1Compat__SETCHUNKOFFSET", function(ent)
	timer.Simple(0, function()
		if not IsValid(ent) then return end
		if ent.CHUNK_OFFSET then return end
		-- if InfMap.filter_entities(ent) and !ent_unfilter[ent:GetClass()] then return end

        local pos = Vector()
        local owner = ent:GetOwner()
        if !IsValid(owner) then owner = ent:GetParent() end
        if IsValid(owner) and owner.CHUNK_OFFSET then
            pos = owner.CHUNK_OFFSET
        end
        ent.CHUNK_OFFSET = pos
	end)
end)
---@diagnostic enable: undefined-field, need-check-nil, inject-field

local map_files, _ = file.Find("infmap/"..string.lower(game.GetMap()).."/*","LUA")
for _, f in ipairs(map_files) do
    local prefix = string.lower(string.sub(f, 1, 2))
    if prefix == "cl" then
        if SERVER then
            AddCSLuaFile("infmap/"..string.lower(game.GetMap()).."/"..f)
        else
            include("infmap/"..string.lower(game.GetMap()).."/"..f)
        end
    elseif prefix == "sv" then
        include("infmap/"..string.lower(game.GetMap()).."/"..f)
    elseif prefix == "sh" then
        if SERVER then
            AddCSLuaFile("infmap/"..string.lower(game.GetMap()).."/"..f)
        end
        include("infmap/"..string.lower(game.GetMap()).."/"..f)
    end
end

InfMap2.ChunkSize = (InfMap.chunk_size or 10000) * 2
InfMap2.World.HasTerrain = InfMap.height_function ~= nil
InfMap2.Visual.HasTerrain = InfMap2.World.HasTerrain
InfMap2.RemoveHeight = -(1/0) -- infmap1 doesn't remove any ents
if InfMap2.World.HasTerrain then
    InfMap2.World.Terrain.HeightFunction = function(x, y) return InfMap.height_function(x / InfMap2.ChunkSize / 2, y / InfMap2.ChunkSize / 2) end
    InfMap2.World.Terrain.Samples = {InfMap.chunk_resolution or 3}

    InfMap2.Visual.RenderDistance = (InfMap.megachunk_size or 10) * (InfMap.render_distance or 2) * 2
    InfMap2.Visual.RealRenderDistance = InfMap2.Visual.RenderDistance

    InfMap2.Visual.Terrain.Material = InfMap.terrain_material or "infmap2/grasslit"
    InfMap2.Visual.Terrain.UVScale = 100
    InfMap2.World.Terrain.LODLevels = table.Copy(InfMap2.World.Terrain.Samples)
end

-- in infmap1 map handles the clouds, not base
-- see: https://github.com/meetric1/gmod-infinite-map/blob/8dac2c760b758a28d9fd099a3294e1f014dc6e7d/lua/infmap/gm_infmap/cl_terrain_visual.lua#L116
InfMap2.Visual.HasClouds = false

-- ^^^ same with fog
-- see: https://github.com/meetric1/gmod-infinite-map/blob/8dac2c760b758a28d9fd099a3294e1f014dc6e7d/lua/infmap/gm_infmap/cl_terrain_visual.lua#L172
InfMap2.Visual.Fog.HasFog = false

--[[
    InfMap2.Space.HasSpace = main.space.has_space or false
    if InfMap2.Space.HasSpace then
        InfMap2.Space.PlanetDistance = main.space.planet_distance or 400000
        InfMap2.Space.Height = main.space.height or 500000
        InfMap2.Space.Planets = {}
        for name, data in pairs(main.space.planets) do
            local idata = {}
            InfMap2.Space.Planets[name] = idata
            if not data.height_function then
                ErrorNoHalt("InfMap planet "..name.." doesn't have height function!")
                data.height_function = function() return 0 end
            end
            idata.HeightFunction = data.height_function
            idata.Atmosphere = data.atmosphere
            if idata.Atmosphere then
                local r, g, b, a = idata.Atmosphere:Unpack()
                idata.Atmosphere = {Vector(r / 255, g / 255, b / 255), a / 255}
            end
            idata.Clouds = data.clouds
            idata.Radius = data.radius or 5000
            idata.Samples = data.samples or (idata.Radius * 2) / 10
            idata.UVScale = data.uvscale or 10
            idata.MaterialOverrides = {}
            for n, material in pairs(data.material_overrides) do
                idata.MaterialOverrides[n] = Material(material)
            end
            idata.MaterialOverrides["outside"] = idata.MaterialOverrides["outside"] or Material("infmap2/planets/"..name.."_outside")
            idata.MaterialOverrides["inside"] = idata.MaterialOverrides["inside"] or Material("infmap2/planets/"..name.."_inside")
            idata.MaterialOverrides["clouds"] = idata.MaterialOverrides["clouds"] or Material("infmap2/planets/"..name.."_clouds")
        end
    end
--]]
if CLIENT then
    InfMap2.Visual.Shaders.Enabled = false
end