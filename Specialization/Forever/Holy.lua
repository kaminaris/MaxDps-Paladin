local _, addonTable = ...
local Paladin = addonTable.Paladin
local MaxDps = _G.MaxDps
if not MaxDps then return end

local Holy = {}

function Paladin:Holy()
    if MaxDps:SmartAoe() <= 1 then
        if not MaxDps.IsSpellOnCooldown(20271, true) then return 20271 end --  Judgement
        if not MaxDps.IsSpellOnCooldown(679, true) then return 679 end --  Holy Strike
        if not MaxDps.IsSpellOnCooldown(879, true) then return 879 end --  Exorcism
        if not MaxDps.IsSpellOnCooldown(1311606, true) then return 1311606 end --  Holy Shock
    end

    if MaxDps:SmartAoe() >= 2 then
        if not MaxDps.IsSpellOnCooldown(20271, true) then return 20271 end --  Judgement
        if not MaxDps.IsSpellOnCooldown(679, true) then return 679 end --  Holy Strike
        if not MaxDps.IsSpellOnCooldown(879, true) then return 879 end --  Exorcism
        if not MaxDps.IsSpellOnCooldown(1311606, true) then return 1311606 end --  Holy Shock
        if not MaxDps.IsSpellOnCooldown(26573, true) then return 26573 end --  Consecration
    end
end
