function InfMap2.ProgressPopupDraw(text, progress, total, yoff)
    yoff = (yoff or 0)*150
    surface.SetDrawColor(0, 0, 0, 190)

    surface.DrawRect(ScrW()/4, ScrH()/2-48+yoff, ScrW()/2, 100)
    surface.DrawRect(ScrW()/4, ScrH()/2+56+yoff, ScrW()/2, 24)

    surface.SetDrawColor(255, 255, 255, 255)
    surface.DrawOutlinedRect(ScrW()/4, ScrH()/2-48+yoff, ScrW()/2, 100, 2)
    surface.DrawOutlinedRect(ScrW()/4, ScrH()/2+56+yoff, ScrW()/2, 24, 2)
    surface.DrawRect(ScrW()/4+4, ScrH()/2+60+yoff, (ScrW()/2-8)*(progress/total), 16)

    draw.DrawText("InfMap2 "..InfMap2.Version, "DermaDefault",
                    ScrW()/4, ScrH()/2-62+yoff, Color(255, 255, 255), TEXT_ALIGN_LEFT)

    draw.DrawText("Please wait\n"..text.."\n"..
                    math.Round((progress/total)*100).."% ("..progress.."/"..total..") samples done",
                    "DermaLarge",
                    ScrW()/2, ScrH()/2-48+yoff, Color(255, 255, 255), TEXT_ALIGN_CENTER)

    local delta = (RealTime() % 5) / 2.5
    if delta > 1 then
        delta = 0.5-(delta-1)
        for x=0,2,1 do
            for y=-1,1,1 do
                local d = (2-x) * 3 + y
                local delta = math.ease.OutCirc(math.min(1, delta * 10 - 0.3 * d))
                surface.SetDrawColor(255, 255, 255, 255*delta)
                surface.DrawRect(ScrW()/4+15+22*x, ScrH()/2-10-22*y-math.min(15, 15*(1-delta))+yoff, 20, 20)
            end
        end
        return
    end
    for x=0,2,1 do
        for y=-1,1,1 do
            local d = (2-x) * 3 + (1-y)
            local delta = math.ease.OutCirc(math.min(1, delta * 10 - 0.3 * d))
            surface.SetDrawColor(255, 255, 255, 255*delta)
            surface.DrawRect(ScrW()/4+math.min(15, 15*delta)+22*x, ScrH()/2-10-22*y+yoff, 20, 20)
        end
    end
end