-- chatgpt code start !!!

local function estimateErrorMargin(value)
    -- Machine epsilon for single-precision (approximately)
    local epsilon = 1.19209290e-07

    return math.abs(value) * epsilon
end


local function emulateSinglePrecision(value)
    --Emulates a single precision float by rounding to 24 bits of mantissa
    --This is not perfect, but close enough

    local mantissaBits = 23
    local scalingFactor = 2 ^ mantissaBits
    return math.floor(value * scalingFactor + 0.5) / scalingFactor
end

-- local largeFloat = emulateSinglePrecision(2^48)
-- local errorMargin = estimateErrorMargin(largeFloat)
-- print("Float value:", largeFloat)
-- print("Estimated error margin:", errorMargin)
-- print("Possible range: [" .. (largeFloat - errorMargin) .. ", " .. (largeFloat + errorMargin) .. "]")

-- chatgpt code end

hook.Add("HUDPaint", "INFMAP2WIPBANNERREMOVEMELATER", function()
    if not InfMap2.EnableDevBanner then return end
    local h = 52+26
    surface.SetDrawColor(0, 0, 0, 190)

    surface.DrawRect(ScrW() / 4, 5, ScrW() / 2, h)

    surface.SetDrawColor(255, 255, 255, 255)
    surface.DrawOutlinedRect(ScrW() / 4, 5, ScrW() / 2, h, 2)

    draw.DrawText("InfMap2 "..InfMap2.Version, "DermaDefault",
        ScrW() / 2, 9, color_white, TEXT_ALIGN_CENTER)

    draw.DrawText("THIS IS A BETA VERSION\nEVERYTHING YOU SEE IS SUBJECT TO CHANGE",
    "DermaLarge", ScrW() / 2, 19, color_white, TEXT_ALIGN_CENTER)
end)

local last_farlands_warning_time = -math.huge
local last_farlands_warning_error = 0
local last_farlands_warning_factor = 0
hook.Add("Think", "InfMap2FarlandsWarning", function()
    local pos = LocalPlayer():GetPos()
    local xerror = estimateErrorMargin(pos.x)
    local yerror = estimateErrorMargin(pos.y)
    local zerror = estimateErrorMargin(pos.z)

    local totalerror = xerror + yerror + zerror
    if totalerror < 2 then return end
    if totalerror - last_farlands_warning_error < 0 then return end -- nan
    local error_factor = math.sqrt(totalerror - last_farlands_warning_error)
    if error_factor < last_farlands_warning_factor * 2 then return end
    last_farlands_warning_factor = error_factor
    last_farlands_warning_error = math.Round(totalerror)
    last_farlands_warning_time = CurTime()
end)
hook.Add("HUDPaint", "InfMap2FarlandsWarning", function()
    local time = CurTime() - last_farlands_warning_time
    --print(last_farlands_warning_error)
    if time > 15 or time < 0 then return end

    local wfrac = time < (15 - 1) and math.min(1, time / 1) or math.max(0, (15 - time) / 1)

    surface.SetDrawColor(0, 0, 0, 190)

    surface.DrawRect(ScrW() / 4 + ScrW() / 4 * (1-wfrac), ScrH() / 4 - 82/2, ScrW() / 2 * wfrac, 82)

    surface.SetDrawColor(255, 255, 255, 255)
    surface.DrawOutlinedRect(ScrW() / 4 + ScrW() / 4 * (1-wfrac), ScrH() / 4 - 82/2, ScrW() / 2 * wfrac, 82, 2)

    draw.DrawText("InfMap2 "..InfMap2.Version, "DermaDefault",
        ScrW() / 2, ScrH() / 4 - 82/2-15, ColorAlpha(color_white, 255 * wfrac), TEXT_ALIGN_CENTER)

    local text = "You are getting pretty far away from the origin (map center)!\n"..
                  "Please note that, even though this base can support any map sizes, Source and\n"..
                  "by extension Garry's Mod do not. Expect jagged movement and\n"..
                  "weird terrain.\n"..
                  "Current floating point error is ~"..last_farlands_warning_error.."hU"
    text = text:sub(1, time < (15 - 2) and #text * (time / 2) or #text * ((15 - time) / 2))

    draw.DrawText(text, "DermaDefault", ScrW() / 2, ScrH() / 4 - 82/2 + 7, color_white, TEXT_ALIGN_CENTER)
end)