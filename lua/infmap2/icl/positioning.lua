local last_megachunk

local maxdist = InfMap2.ChunkSize * InfMap2.Visual.MegachunkSize / 2
local function frustrum(ent)
    do return true end
    if ent:EntIndex() == -1 then return true end
    local mins, maxs = ent:GetRenderBounds()
    local hash = tostring(mins)..tostring(maxs)
    if hash ~= ent.INF_RenderBoundsHash then
        ent.INF_Diagonal = (mins - maxs):Length()
        ent.INF_RenderBoundsHash = hash
    end

    local eyepos = EyePos()

    local real_pos = ent:INF_GetPos() + ent:OBBCenter()
    local pos = real_pos + ent:GetMegaPos() * InfMap2.ChunkSize
    local disttoeye = pos:Distance(eyepos)
    if disttoeye < 10 then
        return true -- very close
    elseif disttoeye > maxdist then
        return false -- too far, don't bother
    end
    
    local direction = (pos - eyepos)
    direction:Normalize()

    if direction:Dot(EyeAngles():Forward()) <= 0 then
        return false
    end

    local toscreenpos = pos:ToScreen()
    local sphererad = render.ComputePixelDiameterOfSphere(pos, ent.INF_Diagonal) / 2

    if toscreenpos.x < -sphererad or
       toscreenpos.x > ScrW()+sphererad or
       toscreenpos.y < -sphererad or
       toscreenpos.y > ScrH()+sphererad then
        return false
    end
    return true
end

local mtrx = Matrix()

local function renderoverride_nest(self, flags, a, b, c, d, e)
    if not self.INF_InFrustrum then return end
    mtrx:SetTranslation(self.INF_VisualOffset)
    cam.PushModelMatrix(mtrx)
    cam.Start3D(INF_EyePos() - self.INF_VisualOffset)
        self:INF_RenderOverride(flags, a, b, c, d, e)
    cam.End3D()
    cam.PopModelMatrix()
end
local function renderoverride_raw(self, flags)
    if not self.INF_InFrustrum then return end
    mtrx:SetTranslation(self.INF_VisualOffset)
    cam.PushModelMatrix(mtrx)
    cam.Start3D(INF_EyePos() - self.INF_VisualOffset)
        self:DrawModel(flags)
    cam.End3D()
    cam.PopModelMatrix()
end

---Updates entity megaposition, moving it between chunks
---@param ent Entity
---@param megapos Vector
---@param attempts number?
function InfMap2.EntityUpdateMegapos(ent, megapos, attempts)
    if ent:GetClass() == "viewmodel" then return end -- TODO: use useless table?
    local mins, maxs = ent:INF_GetRenderBounds()
    if mins == maxs and mins == vector_origin and (attempts or 0) < 3 then
        timer.Simple(0, function()
            InfMap2.EntityUpdateMegapos(ent, megapos, (attempts or 0) + 1)
        end)
        return
    end
    if mins == maxs and mins == vector_origin and (attempts or 0) >= 3 then
        if InfMap2.Debug then print("[INFMAP] Entity "..tostring(ent).." did not get valid renderbounds!") end
    end

    -- make luals happy
    ---@class Entity
    ent = ent
    
    ent:SetMegaPos(megapos)

    if ent:IsWorld() then return end

    local lp = LocalPlayer()

    if ent == lp then
        for _, ent2 in ents.Iterator() do
            if ent2 == ent then continue end
            
            InfMap2.EntityUpdateMegapos(ent2, ent2:GetMegaPos())
        end

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
        return
    end

    -- clientside ents support
	for _, child in ipairs(ent:GetChildren()) do
		if child:EntIndex() ~= -1 then continue end
		InfMap2.EntityUpdateMegapos(child, megapos)
	end

    local megaoffset = megapos - lp:GetMegaPos()

    if megaoffset == vector_origin then -- ent:GetClass() == "gmod_hands" or ent:GetClass() == "viewmodel" or 
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

    if ent.INF_ValidRenderOverride then
        ent.RenderOverride = renderoverride_nest
    else
        ent.RenderOverride = renderoverride_raw
    end
end

hook.Add("PreDrawTranslucentRenderables", "InfMap2FrustrumCalc", function()
    --do return end
    local megapos = LocalPlayer():GetMegaPos()
    for _,ent in ents.Iterator() do
        if not ent.INF_VisualOffset then continue end
        --if ent:GetMegaPos() == megapos then continue end
        if ent:GetClass() == "inf_chunk" then continue end
        ent.INF_InFrustrum = frustrum(ent)
    end
end)