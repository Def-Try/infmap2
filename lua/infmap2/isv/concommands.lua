concommand.Add("infmap_set_megapos", function(ply, _, args)
    if not #args == 3 then return end
    local megapos = Vector(
        math.Round(tonumber(args[1]) or 0),
        math.Round(tonumber(args[2]) or 0),
        math.Round(tonumber(args[3]) or 0)
    )
    InfMap2.EntityUpdateMegapos(ply, megapos)
    ply:PrintMessage(HUD_PRINTCONSOLE, "[INFMAP] Set megapos to "..megapos.x.." "..megapos.y.." "..megapos.z)
end)

concommand.Add("infmap_set_pos", function(ply, _, args)
    if not #args == 3 then return end
    local pos = Vector(
        tonumber(args[1]) or 0,
        tonumber(args[2]) or 0,
        tonumber(args[3]) or 0
    )
    ply:SetPos(pos)
    ply:PrintMessage(HUD_PRINTCONSOLE, "[INFMAP] Set pos to "..pos.x.." "..pos.y.." "..pos.z)
end, function(_, argstr, args)
    return {"infmap_set_pos"..argstr..(argstr:sub(-1, -1) ~= " " and " " or "")..table.concat(string.Explode("", string.rep("0", 3-#args)), " ")}
end)