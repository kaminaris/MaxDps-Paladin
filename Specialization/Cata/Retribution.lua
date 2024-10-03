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
local currentSpec = GetSpecialization()
local currentSpecName = currentSpec and select(2, GetSpecializationInfo(currentSpec)) or 'None'
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local HolyPower
local Mana
local ManaMax
local ManaDeficit
local HolyPowerDeficit

local Retribution = {}



local function ClearCDs()
    MaxDps:GlowCooldown(classtable.AvengingWrath, false)
end

function Retribution:callaction()
    if (MaxDps:CheckSpellUsable(classtable.SealofTruth, 'SealofTruth')) and cooldown[classtable.SealofTruth].ready then
        if not setSpell then setSpell = classtable.SealofTruth end
    end
    if (MaxDps:CheckSpellUsable(classtable.Judgement, 'Judgement')) and (not buff[classtable.JudgementsofthePureBuff].up) and cooldown[classtable.Judgement].ready then
        if not setSpell then setSpell = classtable.Judgement end
    end
    if (MaxDps:CheckSpellUsable(classtable.GuardianofAncientKings, 'GuardianofAncientKings')) and (cooldown[classtable.Zealotry].remains <10) and cooldown[classtable.GuardianofAncientKings].ready then
        if not setSpell then setSpell = classtable.GuardianofAncientKings end
    end
    if (MaxDps:CheckSpellUsable(classtable.Zealotry, 'Zealotry')) and (cooldown[classtable.GuardianofAncientKings].remains >0 and cooldown[classtable.GuardianofAncientKings].remains <292) and cooldown[classtable.Zealotry].ready then
        if not setSpell then setSpell = classtable.Zealotry end
    end
    if (MaxDps:CheckSpellUsable(classtable.AvengingWrath, 'AvengingWrath')) and (buff[classtable.ZealotryBuff].up) and cooldown[classtable.AvengingWrath].ready then
        MaxDps:GlowCooldown(classtable.AvengingWrath, cooldown[classtable.AvengingWrath].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.CrusaderStrike, 'CrusaderStrike')) and (HolyPower <3) and cooldown[classtable.CrusaderStrike].ready then
        if not setSpell then setSpell = classtable.CrusaderStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Judgement, 'Judgement')) and (not buff[classtable.ZealotryBuff].up and HolyPower <3) and cooldown[classtable.Judgement].ready then
        if not setSpell then setSpell = classtable.Judgement end
    end
    if (MaxDps:CheckSpellUsable(classtable.Inquisition, 'Inquisition')) and (( not buff[classtable.InquisitionBuff].up or buff[classtable.InquisitionBuff].remains <= 2 ) and ( HolyPower >= 3 or buff[classtable.DivinePurposeBuff].up )) and cooldown[classtable.Inquisition].ready then
        if not setSpell then setSpell = classtable.Inquisition end
    end
    if (MaxDps:CheckSpellUsable(classtable.TemplarsVerdict, 'TemplarsVerdict')) and (buff[classtable.DivinePurposeBuff].up) and cooldown[classtable.TemplarsVerdict].ready then
        if not setSpell then setSpell = classtable.TemplarsVerdict end
    end
    if (MaxDps:CheckSpellUsable(classtable.TemplarsVerdict, 'TemplarsVerdict')) and (HolyPower == 3) and cooldown[classtable.TemplarsVerdict].ready then
        if not setSpell then setSpell = classtable.TemplarsVerdict end
    end
    if (MaxDps:CheckSpellUsable(classtable.Exorcism, 'Exorcism')) and (buff[classtable.TheArtofWarBuff].up) and cooldown[classtable.Exorcism].ready then
        if not setSpell then setSpell = classtable.Exorcism end
    end
    if (MaxDps:CheckSpellUsable(classtable.HammerofWrath, 'HammerofWrath')) and cooldown[classtable.HammerofWrath].ready then
        if not setSpell then setSpell = classtable.HammerofWrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Judgement, 'Judgement')) and ((MaxDps.tier and MaxDps.tier[13].count >= 2) and buff[classtable.ZealotryBuff].up and HolyPower <3) and cooldown[classtable.Judgement].ready then
        if not setSpell then setSpell = classtable.Judgement end
    end
    if (MaxDps:CheckSpellUsable(classtable.HolyWrath, 'HolyWrath')) and cooldown[classtable.HolyWrath].ready then
        if not setSpell then setSpell = classtable.HolyWrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Consecration, 'Consecration')) and (mana >16000) and cooldown[classtable.Consecration].ready then
        if not setSpell then setSpell = classtable.Consecration end
    end
    if (MaxDps:CheckSpellUsable(classtable.DivinePlea, 'DivinePlea')) and cooldown[classtable.DivinePlea].ready then
        if not setSpell then setSpell = classtable.DivinePlea end
    end
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
    classtable.TemplarSlash = 406647
    classtable.TemplarStrike = 407480
    classtable.FinalVerdictBuff = 383329
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.bloodlust = 0
    classtable.JudgementsofthePureBuff = 0
    classtable.ZealotryBuff = 0
    classtable.InquisitionBuff = 0
    classtable.DivinePurposeBuff = 0
    classtable.TheArtofWarBuff = 0
    setSpell = nil
    ClearCDs()

    Retribution:callaction()
    if setSpell then return setSpell end
end
