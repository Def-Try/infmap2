local last_megachunk

local function frustrum(ent)
    -- for some reason frustrum dies on linux?
    if not system.IsWindows() then return true end
    
    if ent:EntIndex() == -1 then return true end
    local mins, maxs = ent:GetRenderBounds()
    local hash = tostring(mins)..tostring(maxs)
    if hash ~= ent.INF_RenderBoundsHash then
        ent.INF_Diagonal = (mins - maxs):Length()
        ent.INF_RenderBoundsHash = hash
    end

    local pos = ent:GetPos() + ent:OBBCenter() - LocalPlayer():GetMegaPos() * InfMap2.ChunkSize
    local show = false
    if pos:Distance(EyePos()) < 10 then
        show = true -- very close
    elseif pos:Distance(EyePos()) > InfMap2.ChunkSize * InfMap2.Visual.MegachunkSize / 2 then
        show = false -- too far, don't bother
    else
        show = util.PixelVisible(pos, ent.INF_Diagonal, ent.INF_PixVisHandle) > 0
    end

    -- we don't do this above because we need to use util.PixelVisible
    -- to update PixVisHandle data or something, otherwise in first frame
    -- after changing chunks every entity will be "invisible" from last point of view
    if ent.INF_ForceFrustrum then
        ent.INF_ForceFrustrum = nil
        show = true
    end

    return show
end

local mtrx = Matrix()

local function renderoverride_nest(self)
    if not frustrum(self) then return end
    --mtrx:SetTranslation(INF_EyePos() - self.INF_VisualOffset)
    --cam.PushModelMatrix(mtrx)
    local mtrx = cam.GetModelMatrix()
    cam.INF_PopModelMatrix()
    cam.Start3D(INF_EyePos() - self.INF_VisualOffset)
        self:INF_RenderOverride()
    cam.End3D()
    cam.INF_PushModelMatrix(mtrx)
    --cam.PopModelMatrix()
end
local function renderoverride_raw(self)
    if not frustrum(self) then return end
    mtrx:SetTranslation(self.INF_VisualOffset)
    cam.PushModelMatrix(mtrx)
    cam.Start3D(EyePos())
        self:DrawModel()
    cam.End3D()
    cam.PopModelMatrix()
end

function InfMap2.EntityUpdateMegapos(ent, megapos)
    ent:SetMegaPos(megapos)

    if ent:IsWorld() then return end

    local lp = LocalPlayer()

    if ent == lp then
        for _, ent2 in ipairs(ents.GetAll()) do
            if ent2 == ent then continue end
            if not ent2:GetMegaPos() then continue end
            InfMap2.EntityUpdateMegapos(ent2, ent2:GetMegaPos())
        end
        --InfMap2.ViewMatrix:SetTranslation(-megapos * InfMap2.ChunkSize--[[@as Vector]])

        local _, megachunk = InfMap2.LocalizePosition(megapos, InfMap2.Visual.MegachunkSize)

        if InfMap2.World.HasTerrain and (not last_megachunk or (megachunk - (last_megachunk or megachunk)):LengthSqr() > 0) then
            if InfMap2.Debug then print("[INFMAP] Update Megachunks") end
            local megamegapos = ent:GetMegaPos() / InfMap2.Visual.MegachunkSize
            megamegapos.z = 0
            megamegapos.x = math.Round(megamegapos.x)
            megamegapos.y = math.Round(megamegapos.y)
            local dist = InfMap2.Visual.RenderDistance
    
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
    local megaoffset = megapos - (lp:GetMegaPos() or Vector())

    if megaoffset == Vector() then
        ent.RenderOverride = ent.INF_RenderOverride
        if not ent.INF_InSkyboxFlag then ent:RemoveEFlags(EFL_IN_SKYBOX) end
        if ent:GetClass() ~= "inf_chunk" and ent.INF_OriginalRenderBounds then
            ent:INF_SetRenderBounds(unpack(ent.INF_OriginalRenderBounds))
            ent.INF_OriginalRenderBounds = nil
        end
        ent.INF_ValidRenderOverride = nil
        return
    end

    if ent:GetClass() ~= "inf_chunk" and not ent.INF_OriginalRenderBounds then
        ent.INF_OriginalRenderBounds = {ent:INF_GetRenderBounds()}
        ent.INF_RenderBounds = ent.INF_RenderBounds or ent.INF_OriginalRenderBounds
        ent:INF_SetRenderBoundsWS(-InfMap2.SourceBounds * 2, InfMap2.SourceBounds * 2) -- fucking source
    end
    local visual_offset = Vector(1, 1, 1) * (megaoffset * InfMap2.ChunkSize)

    if ent.INF_ValidRenderOverride == nil then
        ent.INF_RenderOverride = ent.RenderOverride
        ent.INF_ValidRenderOverride = ent.RenderOverride and true or false
    end
    ent.INF_InSkyboxFlag = ent:IsEFlagSet(EFL_IN_SKYBOX)
    ent:AddEFlags(EFL_IN_SKYBOX)

    ent.INF_VisualOffset = visual_offset
    ent.INF_PixVisHandle = ent.INF_PixVisHandle or util.GetPixelVisibleHandle()
    ent.INF_ForceFrustrum = true

    if ent.INF_ValidRenderOverride then
        ent.RenderOverride = renderoverride_nest
    else
        ent.RenderOverride = renderoverride_raw
    end
end