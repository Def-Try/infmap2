local last_megachunk

function InfMap2.EntityUpdateMegapos(ent, megapos)
    ent.INF_MegaPos = megapos

    if ent:IsWorld() then return end

    local lp = LocalPlayer()

    if ent == lp then
        for _, ent2 in ipairs(ents.GetAll()) do
            if ent2 == ent then continue end
            if not ent2.INF_MegaPos then continue end
            InfMap2.EntityUpdateMegapos(ent2, ent2.INF_MegaPos)
        end
        InfMap2.ViewMatrix:SetTranslation(-megapos * InfMap2.ChunkSize--[[@as Vector]])

        local _, megachunk = InfMap2.LocalizePosition(megapos, InfMap2.MegachunkSize)

        if InfMap2.UsesGenerator and (not last_megachunk or (megachunk - (last_megachunk or megachunk)):LengthSqr() > 0) then
            if InfMap2.Debug then print("[INFMAP] Update Megachunks") end
            local megamegapos = ent.INF_MegaPos / InfMap2.MegachunkSize
            megamegapos.z = 0
            megamegapos.x = math.Round(megamegapos.x)
            megamegapos.y = math.Round(megamegapos.y)
            local dist = InfMap2.RenderDistance
    
            local used = {}

            for x=-dist,dist,1 do
                for y=-dist,dist,1 do
                    local pos = megamegapos + Vector(x, y, 0)
                    used[tostring(pos)] = true
                    if InfMap2.GeneratedChunks[tostring(pos)] then continue end
                    InfMap2.CreateWorldMegaChunk(pos)
                end
            end

            for pos in pairs(InfMap2.GeneratedChunks) do
                if used[pos] then continue end
                InfMap2.RemoveWorldMegaChunk(Vector(pos))
            end
        end
        last_megachunk = megachunk
    end

	for _, child in ipairs(ent:GetChildren()) do
		if child:EntIndex() ~= -1 then continue end
		InfMap2.EntityUpdateMegapos(child, megapos)
	end

    ---@diagnostic disable-next-line: undefined-field
    local megaoffset = megapos - (lp.INF_MegaPos or Vector())

    if megaoffset == Vector() then
        ent.RenderOverride = ent.INF_RenderOverride
        if not ent.INF_InSkyboxFlag then ent:RemoveEFlags(EFL_IN_SKYBOX) end
        if ent:GetClass() ~= "inf_chunk" and ent.INF_OriginalRenderBounds then
            ent:INF_SetRenderBounds(unpack(ent.INF_OriginalRenderBounds))
            ent.INF_OriginalRenderBounds = nil
        end
        return
    end

    if ent:GetClass() ~= "inf_chunk" and not ent.INF_OriginalRenderBounds then
        ent.INF_OriginalRenderBounds = {ent:INF_GetRenderBounds()}
        ent.INF_RenderBounds = ent.INF_RenderBounds or ent.INF_OriginalRenderBounds
        ent:INF_SetRenderBoundsWS(Vector(-InfMap2.ChunkSize, -InfMap2.ChunkSize, -InfMap2.ChunkSize),
                                Vector( InfMap2.ChunkSize,  InfMap2.ChunkSize,  InfMap2.ChunkSize))
    end
    local visual_offset = Vector(1, 1, 1) * (megaoffset * InfMap2.ChunkSize)

    if ent.INF_ValidRenderOverride == nil then
        ent.INF_RenderOverride = ent.RenderOverride
        ent.INF_ValidRenderOverride = ent.RenderOverride and true or false
    end
    ent.INF_InSkyboxFlag = ent:IsEFlagSet(EFL_IN_SKYBOX)
    ent:AddEFlags(EFL_IN_SKYBOX)
    if ent.INF_ValidRenderOverride then
        function ent:RenderOverride()
            cam.Start3D(EyePos() - visual_offset)
                self:INF_RenderOverride()
            cam.End3D()
        end
    else
        function ent:RenderOverride()
            cam.Start3D(EyePos() - visual_offset)
                self:DrawModel()
            cam.End3D()
        end
    end
end

hook.Add("EntityNetworkedVarChanged", "InfMap2EntityMegaposUpdate", function(ent, name, _, val)
    if name ~= "INF_MegaPos" then return end
    InfMap2.EntityUpdateMegapos(ent, val)
end)