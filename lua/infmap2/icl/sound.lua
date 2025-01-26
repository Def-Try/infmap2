local valid_sounds = {
    ["Weapon_Crossbow.BoltElectrify"] = true,
    ["Weapon_PhysCannon.TooHeavy"] = true,
    ["weapons/physcannon/hold_loop.wav"] = true,
    ["Weapon_PhysCannon.Pickup"] = true,
    ["Weapon_PhysCannon.Drop"] = true,
    ["Weapon_PhysCannon.OpenClaws"] = true,
    ["Weapon_PhysCannon.CloseClaws"] = true,
    ["Player.FallDamage"] = true,
    ["Player.Death"] = true,
    ["Grenade.Blip"] = true,
    ["HL2Player.FlashlightOn"] = true,
    ["HL2Player.FlashlightOff"] = true
}

net.Receive("InfMap2_SoundEmit", function()
    local data = {}
    data.Entity = net.ReadEntity()
    data.OriginalSoundName = net.ReadString()
    if not IsValid(data.Entity) and valid_sounds[data.OriginalSoundName] then data.Entity = LocalPlayer() end
    if not IsValid(data.Entity) then return end
    data.SoundName = net.ReadString()
    data.Channel = net.ReadUInt(8)
    data.SoundLevel = net.ReadUInt(16)
    data.Pitch = net.ReadUInt(8)
    data.Flags = net.ReadUInt(8)
    data.DSP = net.ReadUInt(8)
    data.Volume = net.ReadFloat()

    EmitSound(data.OriginalSoundName,
              LocalPlayer():GetPos() - data.Entity:GetPos(),
              data.Entity:EntIndex(), data.Channel, data.Volume,
              data.SoundLevel, data.Flags, data.Pitch, data.DSP)
end)