local _, addonTable = ...
local Paladin = addonTable.Paladin
local MaxDps = _G.MaxDps
if not MaxDps then return end

local Retribution = {}

function Paladin:Retribution()
    if not MaxDps.IsTrackedAuraActive(20375) then return 20375 end --  Seal of Command
    if not MaxDps.IsSpellOnCooldown(20271, true) then return 20271 end --  Judgement
    if (MaxDps.Power("mana") >= 15) and not MaxDps.IsSpellOnCooldown(61304, false) and MaxDps.IsTrackedAuraActive(20375) then return 20154 end --  Seal of Righteousness
    if (MaxDps.Power("mana") >= 15) and not MaxDps.IsSpellOnCooldown(61304, false) and MaxDps.IsTrackedAuraActive(20154) then return 20375 end --  Seal of Command
    if not MaxDps.IsTrackedAuraActive(20375) and not MaxDps.IsTrackedAuraActive(20154) then return 20154 end --  Seal of Righteousness
    if not MaxDps.IsSpellOnCooldown(24275, true) then return 24275 end --  Hammer of Wrath
    if not MaxDps.IsSpellOnCooldown(679, true) then return 679 end --  Holy Strike
    if (MaxDps.Power("mana") >= 70) then return 26573 end --  Consecration
end
