local last_megachunk

local maxdist = InfMap2.ChunkSize * InfMap2.Visual.RenderDistance / 2
local function frustrum(ent)
    --do return true end
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
    if not InfMap2.RenderingEntitiesOOC then return end
    if not self.INF_InFrustrum then return end
    mtrx:SetTranslation(self.INF_VisualOffset)
    cam.INF_PushModelMatrix(mtrx)
    --render.INF_INTERNAL_SetupClippingOffset(self.INF_VisualOffset)
    cam.INF_Start3D(INF_EyePos() - self.INF_VisualOffset)
        self:INF_RenderOverride(flags, a, b, c, d, e)
    cam.INF_End3D()
    --render.INF_INTERNAL_SetupClippingOffset(nil)
    cam.INF_PopModelMatrix()
end
local function renderoverride_raw(self, flags)
    if not InfMap2.RenderingEntitiesOOC then return end
    if not self.INF_InFrustrum then return end
    mtrx:SetTranslation(self.INF_VisualOffset)
    cam.INF_PushModelMatrix(mtrx)
    --render.INF_INTERNAL_SetupClippingOffset(self.INF_VisualOffset)
    cam.INF_Start3D(INF_EyePos() - self.INF_VisualOffset)
        self:DrawModel(flags)
    cam.INF_End3D()
    --render.INF_INTERNAL_SetupClippingOffset(nil)
    cam.INF_PopModelMatrix()
end

---Updates entity megaposition, moving it between chunks
---@param ent Entity
---@param megapos Vector
---@param attempts number?
function InfMap2.EntityUpdateMegapos(ent, megapos, attempts, reason, critical)
    if InfMap2.UselessEntitiesFilter(ent) then return end
    -- TODO: clean this shit up!!!
    
    local mins, maxs = ent:INF_GetRenderBounds()
    local lp = LocalPlayer()
    local failing = false
    if not failing and (mins == maxs and mins == vector_origin) then failing, critical, reason = true, false, "invalid renderbounds" end
    if not failing and (not IsValid(lp)) then failing, critical, reason = true, true, "localplayer invalid" end
    if failing and (attempts or 0) < (critical and 10 or 3) then
        timer.Simple(0, function()
            InfMap2.EntityUpdateMegapos(ent, megapos, (attempts or 0) + 1, reason, critical)
        end)
        return
    end
    
    if mins == maxs and mins == vector_origin and (attempts or 0) >= (critical and 10 or 3) then
        if InfMap2.Debug then print("[INFMAP] Entity "..tostring(ent).." megapos change failed: "..reason) end
        if critical then return end
    end

    -- make luals happy
    ---@class Entity
    ent = ent
    
    ent:SetMegaPos(megapos)

    if ent:IsWorld() then return end


    if ent == lp then
        for _, ent2 in ents.Iterator() do
            if ent2 == ent then continue end
            
            InfMap2.EntityUpdateMegapos(ent2, ent2:GetMegaPos())
        end

        return
    end

    -- clientside ents support
	for _, child in ipairs(ent:GetChildren()) do
		if child:EntIndex() ~= -1 then continue end
		InfMap2.EntityUpdateMegapos(child, megapos)
	end

    --do return end

    local megaoffset = megapos - lp:GetMegaPos()

    if megaoffset == vector_origin then -- ent:GetClass() == "gmod_hands" or ent:GetClass() == "viewmodel" or 
        ent.RenderOverride = ent.INF_RenderOverride
        ent.INF_VisualOffset = nil
        ent.INF_ValidRenderOverride = nil
        --if not ent.INF_InSkyboxFlag then ent:RemoveEFlags(EFL_IN_SKYBOX) end
        if ent:GetClass() ~= "inf_chunk" then
            ent:INF_SetRenderBounds(ent:GetRenderBounds())
        end
        ent.INF_RenderBounds = nil
        if false and ent:INF_IsEngineEntity() then
            if ent.INF_CurrentMatrixMultiply then ent:EnableMatrix("RenderMultiply", ent.INF_CurrentMatrixMultiply)
            else ent:DisableMatrix("RenderMultiply")
            end
        end
        return
    end

    if ent:GetClass() ~= "inf_chunk" then
        --ent.INF_RenderBounds = ent.INF_RenderBounds
        --ent:INF_SetRenderBoundsWS(-InfMap2.SourceBounds, InfMap2.SourceBounds) -- fucking source
    end
    local visual_offset = Vector(1, 1, 1) * (megaoffset * InfMap2.ChunkSize)
    ent.INF_VisualOffset = visual_offset
    --ent.INF_InSkyboxFlag = ent:IsEFlagSet(EFL_IN_SKYBOX)
    --ent:AddEFlags(EFL_IN_SKYBOX)

    if false and ent:INF_IsEngineEntity() then
        if ent.INF_CurrentMatrixMultiply then ent:EnableMatrix("RenderMultiply", ent.INF_CurrentMatrixMultiply)
        else ent:DisableMatrix("RenderMultiply")
        end
        return
    end

    if ent.INF_ValidRenderOverride == nil then
        ent.INF_RenderOverride = ent.RenderOverride
        ent.INF_ValidRenderOverride = ent.RenderOverride and true or false
    end

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

hook.Add("PostDrawTranslucentRenderables", "InfMap2RenderOOCEntities", function()
    InfMap2.RenderingEntitiesOOC = true
    for _, ent in ents.Iterator() do
        if ent:GetNoDraw() then continue end
        if not ent.INF_VisualOffset then continue end
        local r,g,b = ent:GetColor4Part()
        render.SetColorModulation(r / 255, g / 255, b / 255)
        ent:DrawModel()
    end
    InfMap2.RenderingEntitiesOOC = false
end)