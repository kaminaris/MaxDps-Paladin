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
local RagePT = Enum.PowerType.Rage
local FocusPT = Enum.PowerType.Focus
local EnergyPT = Enum.PowerType.Energy
local ComboPointsPT = Enum.PowerType.ComboPoints
local RunesPT = Enum.PowerType.Runes
local RunicPowerPT = Enum.PowerType.RunicPower
local SoulShardsPT = Enum.PowerType.SoulShards
local DemonicFuryPT = Enum.PowerType.DemonicFury
local BurningEmbersPT = Enum.PowerType.BurningEmbers
local LunarPowerPT = Enum.PowerType.LunarPower
local HolyPowerPT = Enum.PowerType.HolyPower
local MaelstromPT = Enum.PowerType.Maelstrom
local ChiPT = Enum.PowerType.Chi
local InsanityPT = Enum.PowerType.Insanity
local ArcaneChargesPT = Enum.PowerType.ArcaneCharges
local FuryPT = Enum.PowerType.Fury
local PainPT = Enum.PowerType.Pain
local EssencePT = Enum.PowerType.Essence
local RuneBloodPT = Enum.PowerType.RuneBlood
local RuneFrostPT = Enum.PowerType.RuneFrost
local RuneUnholyPT = Enum.PowerType.RuneUnholy

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
local Mana
local ManaMax
local ManaDeficit
local HolyPowerDeficit
local ManaPerc
local seal

local Retribution = {}

-- List of seal IDs
local seals = {
    [1] = "Seal of Righteousness", -- Stance ID for Seal of Righteousness
    [2] = "Seal of Truth",         -- Stance ID for Seal of Truth
    [3] = "Seal of Insight",       -- Stance ID for Seal of Insight
    [4] = "Seal of Justice",       -- Stance ID for Seal of Justice
 }

function Retribution:precombat()
    if (MaxDps:CheckSpellUsable(classtable.BlessingofKings, 'BlessingofKings')) and (not buff[classtable.BlessingofKingsBuff].up) and cooldown[classtable.BlessingofKings].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.BlessingofKings end
    end
    if (MaxDps:CheckSpellUsable(classtable.BlessingofMight, 'BlessingofMight')) and (not buff[classtable.BlessingofMightBuff].up and not buff[classtable.BlessingofKingsBuff].up) and cooldown[classtable.BlessingofMight].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.BlessingofMight end
    end
    --if (MaxDps:CheckSpellUsable(classtable.SealofTruth, 'SealofTruth')) and (not seal == 2) and cooldown[classtable.SealofTruth].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.SealofTruth end
    --end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Rebuke, false)
    MaxDps:GlowCooldown(classtable.AvengingWrath, false)
    MaxDps:GlowCooldown(classtable.ExecutionSentence, false)
end

function Retribution:single()
    --if (MaxDps:CheckSpellUsable(classtable.SealofTruth, 'SealofTruth')) and (seal ~= 1) and cooldown[classtable.SealofTruth].ready then
    --    if not setSpell then setSpell = classtable.SealofTruth end
    --end
    if (MaxDps:CheckSpellUsable(classtable.Inquisition, 'Inquisition')) and (( not buff[classtable.InquisitionBuff].up or buff[classtable.InquisitionBuff].remains <= 2 ) and ( HolyPower >= 3 )) and cooldown[classtable.Inquisition].ready then
        if not setSpell then setSpell = classtable.Inquisition end
    end
    if (MaxDps:CheckSpellUsable(classtable.AvengingWrath, 'AvengingWrath')) and (buff[classtable.InquisitionBuff].up) and cooldown[classtable.AvengingWrath].ready then
        MaxDps:GlowCooldown(classtable.AvengingWrath, cooldown[classtable.AvengingWrath].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.GuardianofAncientKings, 'GuardianofAncientKings')) and (buff[classtable.InquisitionBuff].up and buff[classtable.AvengingWrathBuff].up) and cooldown[classtable.GuardianofAncientKings].ready then
        if not setSpell then setSpell = classtable.GuardianofAncientKings end
    end
    if (MaxDps:CheckSpellUsable(classtable.TemplarsVerdict, 'TemplarsVerdict')) and (HolyPower == 5) and cooldown[classtable.TemplarsVerdict].ready then
        if not setSpell then setSpell = classtable.TemplarsVerdict end
    end
    if (MaxDps:CheckSpellUsable(classtable.ExecutionSentence, 'ExecutionSentence')) and (buff[classtable.InquisitionBuff].up) and cooldown[classtable.ExecutionSentence].ready then
        MaxDps:GlowCooldown(classtable.ExecutionSentence, cooldown[classtable.ExecutionSentence].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.HammerofWrath, 'HammerofWrath')) and cooldown[classtable.HammerofWrath].ready then
        if not setSpell then setSpell = classtable.HammerofWrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Exorcism, 'Exorcism')) and cooldown[classtable.Exorcism].ready then
        if not setSpell then setSpell = classtable.Exorcism end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrusaderStrike, 'CrusaderStrike')) and cooldown[classtable.CrusaderStrike].ready then
        if not setSpell then setSpell = classtable.CrusaderStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Judgment, 'Judgment')) and cooldown[classtable.Judgment].ready then
        if not setSpell then setSpell = classtable.Judgment end
    end
    if (MaxDps:CheckSpellUsable(classtable.TemplarsVerdict, 'TemplarsVerdict')) and (HolyPower >= 3) and cooldown[classtable.TemplarsVerdict].ready then
        if not setSpell then setSpell = classtable.TemplarsVerdict end
    end
end

function Retribution:aoe()
    --if (MaxDps:CheckSpellUsable(classtable.SealofRighteousness, 'SealofRighteousness')) and (targets >= 4 and seal ~= 2) and cooldown[classtable.SealofRighteousness].ready then
    --    if not setSpell then setSpell = classtable.SealofRighteousness end
    --end
    --if (MaxDps:CheckSpellUsable(classtable.SealofTruth, 'SealofTruth')) and (targets < 4 and seal ~= 1) and cooldown[classtable.SealofTruth].ready then
    --    if not setSpell then setSpell = classtable.SealofTruth end
    --end
    if (MaxDps:CheckSpellUsable(classtable.Inquisition, 'Inquisition')) and ((not buff[classtable.InquisitionBuff].up or buff[classtable.InquisitionBuff].remains <= 2) and (HolyPower >= 3)) and cooldown[classtable.Inquisition].ready then
        if not setSpell then setSpell = classtable.Inquisition end
    end
    if (MaxDps:CheckSpellUsable(classtable.DivineStorm, 'DivineStorm')) and (HolyPower == 5 or (buff[classtable.AvengingWrathBuff].up and HolyPower >= 3)) and cooldown[classtable.DivineStorm].ready then
        if not setSpell then setSpell = classtable.DivineStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.HammerofWrath, 'HammerofWrath')) and cooldown[classtable.HammerofWrath].ready then
        if not setSpell then setSpell = classtable.HammerofWrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.HammeroftheRighteous, 'HammeroftheRighteous')) and (targets >= 4) and cooldown[classtable.HammeroftheRighteous].ready then
        if not setSpell then setSpell = classtable.HammeroftheRighteous end
    end
    if (MaxDps:CheckSpellUsable(classtable.Judgment, 'Judgment')) and cooldown[classtable.Judgment].ready then
        if not setSpell then setSpell = classtable.Judgment end
    end
    if (MaxDps:CheckSpellUsable(classtable.Exorcism, 'Exorcism')) and cooldown[classtable.Exorcism].ready then
        if not setSpell then setSpell = classtable.Exorcism end
    end
    if (MaxDps:CheckSpellUsable(classtable.DivineStorm, 'DivineStorm')) and (HolyPower >= 3) and cooldown[classtable.DivineStorm].ready then
        if not setSpell then setSpell = classtable.DivineStorm end
    end
end

function Retribution:callaction()
    if (MaxDps:CheckSpellUsable(classtable.SealofRighteousness, 'SealofRighteousness')) and (targets >= 4 and seal ~= 2) and cooldown[classtable.SealofRighteousness].ready then
        if not setSpell then setSpell = classtable.SealofRighteousness end
    end
    if (MaxDps:CheckSpellUsable(classtable.SealofTruth, 'SealofTruth')) and (targets < 4 and seal ~= 1) and cooldown[classtable.SealofTruth].ready then
        if not setSpell then setSpell = classtable.SealofTruth end
    end
    if targets > 1 then
        Retribution:aoe()
    end
    Retribution:single()
end

function Paladin:Retribution()
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
    classtable = MaxDps.SpellTable
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
    HolyPower = UnitPower('player', HolyPowerPT)
    HolyPowerMax = 5
    HolyPowerDeficit = HolyPowerMax - HolyPower
    ManaPerc = (Mana / ManaMax) * 100
    seal = GetShapeshiftForm()

    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end

    local function debugg()
    end

    classtable.BlessingofKingsBuff = 20217
    classtable.BlessingofMightBuff = 19740
    classtable.InquisitionBuff = 84963
    classtable.AvengingWrathBuff = 31884

    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Retribution:precombat()

    Retribution:callaction()
    if setSpell then return setSpell end
end
