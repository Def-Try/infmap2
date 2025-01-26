local debug_traceline = false
local debug_tracehull = false

local neighbors = {}
for x=-1,1 do for y=-1,1 do for z=-1,1 do
    neighbors[#neighbors+1] = Vector(x, y, z)
end end end

local planes = {
    Vector(0, 0, -1), Vector(0, 0, 1),
    Vector(-1, 0, 0), Vector(1, 0, 0),
    Vector(0, -1, 0), Vector(0, 1, 0)
}

local function find_closest_plane(startpos)
    local mindist = math.huge
    local endplane = Vector()
    local endpos = Vector()

    for _,plane in ipairs(planes) do
        local hitpos = util.IntersectRayWithPlane(startpos, plane, plane*InfMap2.ChunkSize/2, plane)
        if not hitpos then continue end
        if (hitpos - startpos):Length() >= mindist then continue end
        endpos = hitpos
        mindist = (hitpos - startpos):Length()
        endplane = plane
    end

    return mindist, endpos, endplane
end

hook.Add("PostDrawTranslucentRenderables", "InfMap2DebugRender", function(depth, skybox, skybox3d)
    if depth or skybox or skybox3d then return end
    if not InfMap2.Debug then return end

    local megaoffset = ((LocalPlayer():GetMegaPos() or Vector()) * InfMap2.ChunkSize)

    --[[
    for _,neighbor in ipairs(neighbors) do
        render.DrawWireframeBox(megaoffset+neighbor*InfMap2.ChunkSize, Angle(0, 0, 0),
                                -InfMap2.ChunkSize/2*Vector(1,1,1), InfMap2.ChunkSize/2*Vector(1,1,1),
                                Color(255, 0, 0), false)
    end
    ]]

    render.DrawWireframeSphere(megaoffset, 10, 10, 10, Color(255, 0, 0), false)
    render.DrawWireframeBox(Vector(), Angle(0, 0, 0),
                            -InfMap2.ChunkSize/2*Vector(1,1,1), InfMap2.ChunkSize/2*Vector(1,1,1),
                            Color(0, 0, 0), false)

    render.DrawWireframeBox(Vector(), Angle(0, 0, 0),
                            -InfMap2.SourceBounds, InfMap2.SourceBounds,
                            Color(0, 0, 0), false)

    if megaoffset ~= Vector() then
        render.DrawWireframeSphere(Vector(), megaoffset:Length()/100, 10, 10, Color(0, 255, 0), false)
    end

    render.DrawWireframeBox(megaoffset, Angle(0, 0, 0),
                            -InfMap2.ChunkSize/2*Vector(1,1,1), InfMap2.ChunkSize/2*Vector(1,1,1),
                            Color(0, 0, 255), false)

    local mindist, endpos, endplane = find_closest_plane(INF_EyePos())
    ---@diagnostic disable-next-line: cast-local-type
    endplane = endplane:Angle()
    local s = 512

    render.SetColorMaterialIgnoreZ()
    local clr = Color(0, TimedSin(0.5, 63, 127, 0), TimedSin(0.5, 127, 255, 0), math.max(0, 255-255*(mindist/1000)))
    render.DrawBox(endpos+megaoffset, Angle(0, 0, 0),
        endplane:Right()* s+endplane:Up()* s,
        endplane:Right()*-s+endplane:Up()*-s, clr)
end)

hook.Add("HUDPaint", "InfMap2DebugRender", function() local function _(c, x, y)
    if not InfMap2.Debug then return end
    draw.DrawText("    MAP: "..game.GetMap(),                         "TargetID", x+ScrW()-5, y+5+16*0, c, TEXT_ALIGN_RIGHT)
    draw.DrawText("    POS: "..tostring(LocalPlayer():GetPos()),      "TargetID", x+ScrW()-5, y+5+16*1, c, TEXT_ALIGN_RIGHT)
    draw.DrawText("REALPOS: "..tostring(LocalPlayer():INF_GetPos()),  "TargetID", x+ScrW()-5, y+5+16*2, c, TEXT_ALIGN_RIGHT)
    draw.DrawText("MEGAPOS: "..tostring(LocalPlayer():GetMegaPos()),   "TargetID", x+ScrW()-5, y+5+16*3, c, TEXT_ALIGN_RIGHT)
    draw.DrawText("    VEL: "..tostring(LocalPlayer():GetVelocity()), "TargetID", x+ScrW()-5, y+5+16*4, c, TEXT_ALIGN_RIGHT)

    if debug_traceline then
        local len = InfMap2.ChunkSize * 2
        local tracedata = {
            start = LocalPlayer():EyePos(),
            endpos= LocalPlayer():EyePos()+LocalPlayer():EyeAngles():Forward() * len,
            filter= {LocalPlayer(), IsValid(LocalPlayer():GetVehicle()) and LocalPlayer():GetVehicle():GetParent() or nil},
            --INF_DoNotHandleEntities=true
        }
        local traceresult = util.TraceLine(tracedata)

        draw.DrawText(traceresult.Entity, "DermaLarge", ScrW()/2, ScrH()/2 - 48, Color(255, 255, 255), TEXT_ALIGN_CENTER)
        draw.DrawText(math.Round((traceresult.Fraction) * len, 2) .. " units away", "DermaLarge", ScrW()/2, ScrH()/2 + 12, Color(255, 255, 255), TEXT_ALIGN_CENTER)
        draw.DrawText("at "..tostring(traceresult.HitPos).." megapos "..tostring(traceresult.Entity:GetMegaPos() or "<UNK>"), "DermaLarge", ScrW()/2, ScrH()/2 + 36, Color(255, 255, 255), TEXT_ALIGN_CENTER)
        cam.Start3D()
            render.DrawLine(tracedata.start, traceresult.HitPos, Color(255, 255, 255))
            render.DrawWireframeSphere(traceresult.HitPos, 1000 * traceresult.Fraction, 10, 10, Color(255, 255, 255), false)
        cam.End3D()
    end

    if debug_tracehull then
        local mins, maxs = Vector(-16, -16, -16) * 10, Vector(16, 16, 16) * 10
        local tracedata = {
            start = LocalPlayer():EyePos(),
            endpos= LocalPlayer():EyePos()+LocalPlayer():EyeAngles():Forward() * InfMap2.ChunkSize / 2,
            filter= LocalPlayer(),
            mins = mins, maxs = maxs,
            --INF_DoNotHandleEntities=true
        }

        local tr = util.TraceHull(tracedata)

        cam.Start3D()
            render.DrawLine(tr.HitPos, tracedata.endpos, color_white, true)
            render.DrawLine(tracedata.start, tr.HitPos, Color(0, 0, 255), true)

            local clr = color_white
            if tr.Hit then
                clr = Color( 255, 0, 0 )
            end

            render.DrawWireframeBox(tracedata.start, Angle(0, 0, 0), mins, maxs, color_white, true)
            render.DrawWireframeBox(tr.HitPos, Angle(0, 0, 0), mins, maxs, clr, true)
        cam.End3D()
    end
end _(color_black, -1, -1) _(color_black, 1, 1) _(color_black, 1, -1) _(color_black, -1, 1) _(color_white, 0, 0) end)