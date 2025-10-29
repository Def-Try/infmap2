InfMap2.ConVars = InfMap2.ConVars or {}
if InfMap2.World.HasTerrain then
    InfMap2.ConVars.vis_rebuildperframe = CreateClientConVar("infmap_vis_rebuildperframe", "2", true, false, "How many visual chunks can be rebuilt per every frame (int).", 1, 64)

    InfMap2.ConVars.vis_chunklods = CreateClientConVar("infmap_vis_chunklods", "0", true, false, "Force custom chunk resolution (list of ints, separated by space). 0 to use infmap defaults. Requires chunk reload.")
    InfMap2.ConVars.vis_chunklods_tbl = nil
    cvars.RemoveChangeCallback("infmap_vis_chunklods", "infmap_vis_chunklods")
    cvars.AddChangeCallback("infmap_vis_chunklods", function(_, old, new)
        if tonumber(new) == 0 then
            InfMap2.ConVars.vis_chunklods_tbl = nil
            return
        end
        local tbl = string.Split(new, " ")

        local num, failed, min = nil, false, 1/0
        for i=1,#tbl do
            num = tonumber(tbl[i])
            if not num then print("Failed to parse \""..tbl[i].."\" (at LOD #"..i..") as number") failed = true break end
            if num < 2 then print("Number \""..tbl[i].."\" (at LOD #"..i..") is less than 2") failed = true break end
            if num % 1 ~= 0 then print("\""..tbl[i].."\" (at LOD #"..i..") is not a whole number") failed = true break end
            if num > min then print("\""..tbl[i].."\" (at LOD #"..i..") is higher than last minimum LOD ("..min..")") end
            min = math.min(num, min)
            tbl[i] = num
        end
        if failed then
            print("Resetting to old value, see report above for more info.")
            return InfMap2.ConVars.vis_chunklods:SetString(old)
        end
        InfMap2.ConVars.vis_chunklods_tbl = tbl
        InfMap2.World.Terrain.LODLevels = {InfMap2.World.Terrain.Samples[1], unpack(InfMap2.ConVars.vis_chunklods_tbl)}
    end, "infmap_vis_chunklods")
    local temp = InfMap2.ConVars.vis_chunklods:GetString()
    InfMap2.ConVars.vis_chunklods:SetString("0")
    InfMap2.ConVars.vis_chunklods:SetString(temp)

    InfMap2.ConVars.vis_renderdistance = CreateClientConVar("infmap_vis_renderdistance", "0", true, false, "Force custom render distance (int). 0 to use infmap default. Requires chunk reload.", 0, 100)
    cvars.RemoveChangeCallback("infmap_vis_renderdistance", "infmap_vis_renderdistance")
    cvars.AddChangeCallback("infmap_vis_renderdistance", function(_, old, new)
        local num = tonumber(new)
        if num == 0 then
            InfMap2.Visual.RenderDistance = InfMap2.Visual.RealRenderDistance
            return
        end
        if not num then
            print("Failed to parse \""..new.."\" as number")
            return InfMap2.ConVars.vis_renderdistance:SetString(old)
        end
        if num < 1 then
            print("\""..new.."\" is less than 1")
            return InfMap2.ConVars.vis_renderdistance:SetString(old)
        end
        if num % 1 ~= 0 then
            print("\""..new.."\" is not a whole number")
            return InfMap2.ConVars.vis_renderdistance:SetString(old)
        end
        InfMap2.Visual.RenderDistance = num
    end, "infmap_vis_renderdistance")
    local temp = InfMap2.ConVars.vis_renderdistance:GetString()
    InfMap2.ConVars.vis_renderdistance:SetString("0")
    InfMap2.ConVars.vis_renderdistance:SetString(temp)
end