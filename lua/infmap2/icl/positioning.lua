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

    ent:SetRenderBoundsWS(Vector(-InfMap2.ChunkSize, -InfMap2.ChunkSize, -InfMap2.ChunkSize),
                          Vector( InfMap2.ChunkSize,  InfMap2.ChunkSize,  InfMap2.ChunkSize))

	for _, child in ipairs(ent:GetChildren()) do
		if child:EntIndex() ~= -1 then continue end
		InfMap2.EntityUpdateMegapos(child, megapos)
	end

    ---@diagnostic disable-next-line: undefined-field
    local megaoffset = megapos - (lp.INF_MegaPos or Vector())

    if megaoffset == Vector() then
        ent.RenderOverride = ent.INF_RenderOverride
        return
    end

    local visual_offset = Vector(1, 1, 1) * (megaoffset * InfMap2.ChunkSize)

    --ent.INF_RenderOverride = ent.RenderOverride
    function ent:RenderOverride()
        cam.Start3D(EyePos() - visual_offset)
        if not self.INF_RenderOverride then
            self:DrawModel()
        else
            self:INF_RenderOverride()
        end
        cam.End3D()
    end

end

hook.Add("EntityNetworkedVarChanged", "InfMap2EntityMegaposUpdate", function(ent, name, _, val)
    if name ~= "INF_MegaPos" then return end
    InfMap2.EntityUpdateMegapos(ent, val)
end)