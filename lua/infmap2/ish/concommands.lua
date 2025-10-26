AddCSLuaFile()


if SERVER then
    CreateConVar("infmap_debug_sv", "0", FCVAR_NONE, "", 0, 1)
    cvars.RemoveChangeCallback("infmap_debug_sv", "infmap_debug_sv")
    cvars.AddChangeCallback("infmap_debug_sv", function(_, _, val)
        InfMap2.Debug = tonumber(val) == 1
    end, "infmap_debug_sv")
end
if CLIENT then
    CreateConVar("infmap_debug_cl", "0", FCVAR_NONE, "", 0, 1)
    cvars.RemoveChangeCallback("infmap_debug_cl", "infmap_debug_cl")
    cvars.AddChangeCallback("infmap_debug_cl", function(_, _, val)
        InfMap2.Debug = tonumber(val) == 1
    end, "infmap_debug_cl")
end


CreateConVar("infmap_debug", "0", FCVAR_NONE, "", 0, 1)
cvars.RemoveChangeCallback("infmap_debug", "infmap_debug")
cvars.AddChangeCallback("infmap_debug", function(_, _, val)
    if SERVER then
        for _, ply in ipairs(player.GetAll()) do
            ply:ConCommand("infmap_debug_cl "..val)
        end
    RunConsoleCommand("infmap_debug_sv", val)
    end
end, "infmap_debug")