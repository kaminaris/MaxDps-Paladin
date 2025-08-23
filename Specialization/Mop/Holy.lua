local _, addonTable = ...
local Paladin = addonTable.Paladin
local MaxDps = _G.MaxDps
if not MaxDps then return end
local setSpell

local UnitPower = UnitPower
local UnitHealth = UnitHealth
local UnitAura = C_UnitAuras.GetAuraDataByIndex
local UnitAuraByName = C_UnitAuras.GetAuraDataBySpellName
local UnitHealthMax = UnitHealthMax
local UnitPowerMax = UnitPowerMax
local SpellHaste
local SpellCrit
local GetSpellInfo = C_Spell.GetSpellInfo
local GetSpellCooldown = C_Spell.GetSpellCooldown
local GetSpellCount = C_Spell.GetSpellCastCount

local ManaPT = Enum.PowerType.Mana
local HolyPowerPT = Enum.PowerType.HolyPower

local fd
local ttd
local timeShift
local gcd
local cooldown
local buff
local debuff
local talents
local targets
local targetHP
local targetmaxHP
local targethealthPerc
local curentHP
local maxHP
local healthPerc
local timeInCombat
local className, classFilename, classId = UnitClass('player')
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local Mana
local ManaMax
local ManaDeficit
local ManaPerc
local HolyPower
local HolyPowerMax
local HolyPowerDeficit

local Holy = {}

function Holy:precombat()
end

local function ClearCDs()
end

function Holy:callaction()
    if targets >= 3 then
        if (MaxDps:CheckSpellUsable(classtable.LightHammer, 'LightHammer')) and cooldown[classtable.LightHammer].ready then
            if not setSpell then setSpell = classtable.LightHammer end
        end
        if (MaxDps:CheckSpellUsable(classtable.HolyShock, 'HolyShock')) and cooldown[classtable.HolyShock].ready then
            if not setSpell then setSpell = classtable.HolyShock end
        end
    else
        if (MaxDps:CheckSpellUsable(classtable.Denounce, 'Denounce')) and cooldown[classtable.Denounce].ready then
            if not setSpell then setSpell = classtable.Denounce end
        end
        if (MaxDps:CheckSpellUsable(classtable.Judgment, 'Judgment')) and cooldown[classtable.Judgment].ready then
            if not setSpell then setSpell = classtable.Judgment end
        end
        if (MaxDps:CheckSpellUsable(classtable.HolyShock, 'HolyShock')) and cooldown[classtable.HolyShock].ready then
            if not setSpell then setSpell = classtable.HolyShock end
        end
    end
end

function Paladin:Holy()
    fd = MaxDps.FrameData
    ttd = (fd.timeToDie and fd.timeToDie) or 500
    timeShift = fd.timeShift
    gcd = fd.gcd
    cooldown = fd.cooldown
    buff = fd.buff
    debuff = fd.debuff
    talents = fd.talents
    targets = MaxDps:SmartAoe()
    Mana = UnitPower('player', ManaPT)
    ManaMax = UnitPowerMax('player', ManaPT)
    ManaDeficit = ManaMax - Mana
    HolyPower = UnitPower('player', HolyPowerPT)
    HolyPowerMax = UnitPowerMax('player', HolyPowerPT)
    HolyPowerDeficit = HolyPowerMax - HolyPower
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP > 0 and targetmaxHP > 0 and (targetHP / targetmaxHP) * 100) or 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
    ManaPerc = (Mana / ManaMax) * 100

    setSpell = nil
    ClearCDs()

    Holy:precombat()
    Holy:callaction()

    if setSpell then return setSpell end
end