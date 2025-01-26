util.AddNetworkString("InfMap2_SoundEmit")
hook.Add("EntityEmitSound", "InfMap2SoundEmit", function(data)
    local list = data.Entity:IsWorld() and player.GetAll() or {}
    if not data.Entity:IsWorld() then
        for _,ply in player.Iterator() do
            if InfMap2.ChebyshevDistance(ply:GetMegaPos(), data.Entity:GetMegaPos()) > 1 then continue end
            list[#list+1] = ply
        end
    end

    net.Start("InfMap2_SoundEmit")
        net.WriteEntity(data.Entity)
        net.WriteString(data.OriginalSoundName)
        net.WriteString(data.SoundName)
        net.WriteUInt(data.Channel, 8)
        net.WriteUInt(data.SoundLevel, 16)
        net.WriteUInt(data.Pitch, 8)
        net.WriteUInt(data.Flags, 8)
        net.WriteUInt(data.DSP, 8)
        net.WriteFloat(data.Volume)
    net.Send(list)
    return false
end)