AddCSLuaFile()

local infmap_debug = function(_, _, val) InfMap2.Debug = tonumber(val) == 1 end
if SERVER then
    CreateConVar("infmap_debug_sv", "0", nil, "", 0, 1)
    cvars.RemoveChangeCallback("infmap_debug_sv", "infmap_debug_sv")
    cvars.AddChangeCallback("infmap_debug_sv", infmap_debug, "infmap_debug_sv")
end
if CLIENT then
    CreateConVar("infmap_debug_cl", "0", nil, "", 0, 1)
    cvars.RemoveChangeCallback("infmap_debug_cl", "infmap_debug_cl")
    cvars.AddChangeCallback("infmap_debug_cl", infmap_debug, "infmap_debug_cl")
end

CreateConVar("infmap_debug", "0", nil, "", 0, 1)
cvars.RemoveChangeCallback("infmap_debug", "infmap_debug")
cvars.AddChangeCallback("infmap_debug", function(_, _, val)
    if SERVER then
        for _, ply in ipairs(player.GetAll()) do
            ply:ConCommand("infmap_debug_cl "..val)
        end
    RunConsoleCommand("infmap_debug_sv", val)
    end
end, "infmap_debug")

local infmap_show_ents = function(ply, _, args)
    local function format_gmodent(ent)
        if not IsValid(ent) then return "GMOD NULL ENTITY" end
        local megapos = ent:GetMegaPos()
        return string.format("GMOD %s EIdx=%d Megapos=(%d %d %d)", ent:GetClass(), ent:EntIndex(), megapos.x, megapos.y, megapos.z)
    end
    for _, ent in ipairs(ents.GetAll()) do
        local klass = ent:GetClass()
        local str = ""
        if klass == "inf_chunk" then
            local megapos = ent:GetMegaPos()
            str = string.format("INFMAP Chunk for megapos (%d %d %d)", megapos.x, megapos.y, megapos.z)
        elseif klass == "inf_crosschunkclone" then
            ---@diagnostic disable-next-line: undefined-field
            local refparent = ent:GetReferenceParent()
            local megapos = ent:GetMegaPos()
            str = string.format("INFMAP CCC of [%s] at megapos (%d %d %d)", format_gmodent(refparent), megapos.x, megapos.y, megapos.z)
        else
            str = string.format("  %s", format_gmodent(ent))
        end
        print(string.format("[%4d] %s", _, str))
    end
end
if SERVER then concommand.Add("infmap_show_ents_sv", infmap_show_ents) end
if CLIENT then concommand.Add("infmap_show_ents_cl", infmap_show_ents) end

if CLIENT then
    concommand.Add("infmap_reload_cl", function()
        InfMap2.Gilb()
        InfMap2.Caleb()
        local render_idx = InfMap2.ChunkMeshes.Index
        for xy, chunk in pairs(render_idx) do
            if chunk.mesh then chunk.mesh:Destroy() end
            render_idx[xy] = nil
        end
    end, nil, nil, {FCVAR_UNREGISTERED, FCVAR_SERVER_CAN_EXECUTE})
end
if SERVER then
    concommand.Add("infmap_reload_sv", function()
        InfMap2.Gilb()
        InfMap2.Caleb()
        for pos, ent in pairs(InfMap2.GeneratedChunks) do
            local megapos = Vector(pos)
            ent:Remove()
            InfMap2.GeneratedChunks[pos] = InfMap2.CreateWorldChunk(megapos)
        end
    end, nil, nil, {FCVAR_UNREGISTERED, FCVAR_SERVER_CAN_EXECUTE})

    concommand.Add("infmap_reload", function()
        for _, ply in ipairs(player.GetAll()) do
            ply:ConCommand("infmap_reload_cl")
        end
        RunConsoleCommand("infmap_reload_sv")
    end)
end