local neighbors = {}
for x=-1,1 do for y=-1,1 do for z=-1,1 do
    neighbors[#neighbors+1] = Vector(x, y, z)
end end end

hook.Add("PostDrawOpaqueRenderables", "InfMap2DebugRender", function()
    if not InfMap2.Debug then return end

    local megaoffset = ((LocalPlayer().INF_MegaPos or Vector()) * InfMap2.ChunkSize)

    --[[
    for _,neighbor in ipairs(neighbors) do
        render.DrawWireframeBox(megaoffset+neighbor*InfMap2.ChunkSize, Angle(0, 0, 0),
                                -InfMap2.ChunkSize/2*Vector(1,1,1), InfMap2.ChunkSize/2*Vector(1,1,1),
                                Color(255, 0, 0), false)
    end
    ]]

    render.DrawWireframeSphere(megaoffset, 10, 10, 10, Color(255, 0, 0), false)
    render.DrawWireframeBox(megaoffset, Angle(0, 0, 0),
                            -InfMap2.ChunkSize/2*Vector(1,1,1), InfMap2.ChunkSize/2*Vector(1,1,1),
                            Color(0, 0, 0), false)

    render.DrawWireframeBox(megaoffset, Angle(0, 0, 0),
                            -InfMap2.SourceBounds, InfMap2.SourceBounds,
                            Color(0, 0, 0), false)

    if megaoffset ~= Vector() then
        render.DrawWireframeSphere(Vector(0, 0, 0), megaoffset:Length()/100, 10, 10, Color(0, 255, 0), false)
    end

    render.DrawWireframeBox(Vector(0, 0, 0), Angle(0, 0, 0),
                            -InfMap2.ChunkSize/2*Vector(1,1,1), InfMap2.ChunkSize/2*Vector(1,1,1),
                            Color(0, 0, 255), false)

    --print("    ", traceresult.Entity, traceresult.HitPos)

    local tracedata = {
        start = LocalPlayer():EyePos(),
        endpos= LocalPlayer():EyePos()+LocalPlayer():EyeAngles():Forward() * InfMap2.ChunkSize * 2,
        filter= LocalPlayer(),
        --INF_DoNotHandleEntities=true
    }
    local traceresult = util.TraceLine(tracedata)

    render.DrawLine(tracedata.start, traceresult.HitPos, Color(255, 255, 255))
    render.DrawWireframeSphere(traceresult.HitPos, 1000 * traceresult.Fraction, 10, 10, Color(255, 255, 255), false)
end)

hook.Add("HUDPaint", "InfMap2DebugRender", function() local function _(c, x, y)
    draw.DrawText("    MAP: "..game.GetMap(),                         "TargetID", x+ScrW()-5, y+5+16*0, c, TEXT_ALIGN_RIGHT)
    draw.DrawText("    POS: "..tostring(LocalPlayer():GetPos()),      "TargetID", x+ScrW()-5, y+5+16*1, c, TEXT_ALIGN_RIGHT)
    draw.DrawText("REALPOS: "..tostring(LocalPlayer():INF_GetPos()),  "TargetID", x+ScrW()-5, y+5+16*2, c, TEXT_ALIGN_RIGHT)
    draw.DrawText("MEGAPOS: "..tostring(LocalPlayer().INF_MegaPos),   "TargetID", x+ScrW()-5, y+5+16*3, c, TEXT_ALIGN_RIGHT)
    draw.DrawText("    VEL: "..tostring(LocalPlayer():GetVelocity()), "TargetID", x+ScrW()-5, y+5+16*4, c, TEXT_ALIGN_RIGHT)

    local tracedata = {
        start = LocalPlayer():EyePos(),
        endpos= LocalPlayer():EyePos()+LocalPlayer():EyeAngles():Forward() * InfMap2.ChunkSize * 2,
        filter= LocalPlayer(),
        --INF_DoNotHandleEntities=true
    }
    local traceresult = util.TraceLine(tracedata)

    draw.DrawText(traceresult.Entity, "DermaLarge", ScrW()/2, ScrH()/2 - 48, Color(255, 255, 255), TEXT_ALIGN_CENTER)
    draw.DrawText(math.Round((traceresult.Fraction) * InfMap2.ChunkSize * 2, 2) .. " units away", "DermaLarge", ScrW()/2, ScrH()/2 + 12, Color(255, 255, 255), TEXT_ALIGN_CENTER)
    draw.DrawText("at megapos "..tostring(traceresult.Entity.INF_MegaPos or "<UNK>"), "DermaLarge", ScrW()/2, ScrH()/2 + 36, Color(255, 255, 255), TEXT_ALIGN_CENTER)


end _(color_black, -1, -1) _(color_black, 1, 1) _(color_black, 1, -1) _(color_black, -1, 1) _(color_white, 0, 0) end)