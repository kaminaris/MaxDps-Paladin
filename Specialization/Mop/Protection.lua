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

local HolyPower
local HolyPowerMax
local HolyPowerDeficit
local Mana
local ManaMax
local ManaDeficit

local seal

local Protection = {}

local function SealofInsightActive()
    local num = GetNumShapeshiftForms()
    if not num or num == 0 then
        return false
    end

    for i = 1, num do
        local _, active, _, spellID = GetShapeshiftFormInfo(i)
        if active and spellID == classtable.SealofInsight then
            return true
        end
    end

    return false
end

function Protection:precombat()
    if (MaxDps:CheckSpellUsable(classtable.BlessingofKings, 'BlessingofKings')) and (not buff[classtable.BlessingofKingsBuff].up) and cooldown[classtable.BlessingofKings].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.BlessingofKings end
    end
    if (MaxDps:CheckSpellUsable(classtable.BlessingofMight, 'BlessingofMight')) and (not buff[classtable.BlessingofMightBuff].up and not buff[classtable.BlessingofKingsBuff].up) and cooldown[classtable.BlessingofMight].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.BlessingofMight end
    end
end

local function ClearCDs()
    MaxDps:GlowCooldown(classtable.AvengerShield, false)
    MaxDps:GlowCooldown(classtable.HammerOfWrath, false)
    MaxDps:GlowCooldown(classtable.EternalFlame, false)
    MaxDps:GlowCooldown(classtable.WordOfGlory, false)
end

function Protection:callaction()
    if (MaxDps:CheckSpellUsable(classtable.SealofInsight, 'SealofInsight')) and (not SealofInsightActive()) and cooldown[classtable.SealofInsight].ready then
        if not setSpell then setSpell = classtable.SealofInsight end
    end
    if (MaxDps:CheckSpellUsable(classtable.AvengerShield, 'AvengerShield')) and cooldown[classtable.AvengerShield].ready then
        if not setSpell then setSpell = classtable.AvengerShield end
    end
    if (MaxDps:CheckSpellUsable(classtable.HammeroftheRighteous, 'HammeroftheRighteous')) and (targets > 1) and cooldown[classtable.HammeroftheRighteous].ready then
        if not setSpell then setSpell = classtable.HammeroftheRighteous end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrusaderStrike, 'CrusaderStrike')) and cooldown[classtable.CrusaderStrike].ready then
        if not setSpell then setSpell = classtable.CrusaderStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Judgment, 'Judgment')) and cooldown[classtable.Judgment].ready then
        if not setSpell then setSpell = classtable.Judgment end
    end
    if (MaxDps:CheckSpellUsable(classtable.EternalFlame, 'EternalFlame')) and (not buff[classtable.EternalFlameBuff].up) and cooldown[classtable.EternalFlame].ready then
        --if not setSpell then setSpell = classtable.EternalFlame end
        MaxDps:GlowCooldown(classtable.EternalFlame, true)
    end
    if (MaxDps:CheckSpellUsable(classtable.ShieldOfTheRighteous, 'ShieldOfTheRighteous')) and (HolyPower >= 3) and cooldown[classtable.ShieldOfTheRighteous].ready then
        if not setSpell then setSpell = classtable.ShieldOfTheRighteous end
    end
    if (MaxDps:CheckSpellUsable(classtable.HammerOfWrath, 'HammerOfWrath')) and (targethealthPerc < 20) and cooldown[classtable.HammerOfWrath].ready then
        if not setSpell then setSpell = classtable.HammerOfWrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.WordOfGlory, 'WordOfGlory')) and cooldown[classtable.WordOfGlory].ready then
        --if not setSpell then setSpell = classtable.WordOfGlory end
        MaxDps:GlowCooldown(classtable.WordOfGlory, true)
    end
    if (MaxDps:CheckSpellUsable(classtable.Consecration, 'Consecration')) and cooldown[classtable.Consecration].ready then
        if not setSpell then setSpell = classtable.Consecration end
    end
    if (MaxDps:CheckSpellUsable(classtable.HolyWrath, 'HolyWrath')) and cooldown[classtable.HolyWrath].ready then
        if not setSpell then setSpell = classtable.HolyWrath end
    end
end

function Paladin:Protection()
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
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP >0 and targetmaxHP >0 and (targetHP / targetmaxHP) * 100) or 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    HolyPower = UnitPower('player', HolyPowerPT)
    HolyPowerMax = 5
    HolyPowerDeficit = HolyPowerMax - HolyPower

    seal = GetShapeshiftForm()

    classtable = MaxDps.SpellTable

    classtable.AvengerShield = 31935
    classtable.CrusaderStrike = 35395
    classtable.Judgment = 20271
    classtable.EternalFlame = 114163
    classtable.ShieldOfTheRighteous = 53600
    classtable.HammerOfWrath = 24275
    classtable.WordOfGlory = 85673
    classtable.Consecration = 26573
    classtable.HolyWrath = 119072
    classtable.BlessingofKingsBuff = 20217
    classtable.BlessingofMightBuff = 19740
    classtable.EternalFlameBuff = 114163
    classtable.SealofInsight = 20165

    setSpell = nil
    ClearCDs()

    Protection:precombat()
    Protection:callaction()
    if setSpell then return setSpell end
end