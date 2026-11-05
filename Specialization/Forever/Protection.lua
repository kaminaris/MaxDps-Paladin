local _, addonTable = ...
local Paladin = addonTable.Paladin
local MaxDps = _G.MaxDps
if not MaxDps then return end

local Protection = {}

function Paladin:Protection()
    if (not MaxDps.IsTrackedAuraActive(20154)) and not MaxDps.IsSpellOnCooldown(20154, true) then return 20154 end --  Seal of Righteousness
    if not MaxDps.IsSpellOnCooldown(20271, true) then return 20271 end --  Judgement
    if not MaxDps.IsSpellOnCooldown(26573, true) then return 26573 end --  Consecration
    if not MaxDps.IsSpellOnCooldown(679, true) then return 679 end --  Holy Strike
    if (MaxDps.IsTrackedAuraActive(20128)) and not MaxDps.IsSpellOnCooldown(20925, true) then return 20925 end --  Holy Shield
end
