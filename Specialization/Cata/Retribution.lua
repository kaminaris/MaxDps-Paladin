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
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local HolyPower
local Mana
local ManaMax
local ManaDeficit
local HolyPowerDeficit
local ManaPerc

local Retribution = {}



local function time_to_generate_holy_power()
    local needed_holy_power = function()
        if HolyPower > 0 then
            return 3 + 3 - HolyPower
        else
            return 3
        end
    end
    return needed_holy_power() * cooldown[classtable.CrusaderStrike].duration
end

local function time_until_zealotry()
    local time_until_zealotryc = cooldown[classtable.Zealotry].remains
    if buff[classtable.GuardianofAncientKingsBuff].up and not buff[classtable.ZealotryBuff].up then
        time_until_zealotryc = buff[classtable.GuardianofAncientKingsBuff].remains - 20
    end
    return time_until_zealotryc
end

local function can_spend_holy_power()
    if time_to_generate_holy_power() <= time_until_zealotry() then
        return true
    else
        return false
    end
end


function Retribution:precombat()
    if (MaxDps:CheckSpellUsable(classtable.RetributionAura, 'RetributionAura')) and (not buff[classtable.AuraBuff].up and false and false) and cooldown[classtable.RetributionAura].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.RetributionAura end
    end
    if (MaxDps:CheckSpellUsable(classtable.ConcentrationAura, 'ConcentrationAura')) and (not buff[classtable.AuraBuff].up and false and false) and cooldown[classtable.ConcentrationAura].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.ConcentrationAura end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrusaderAura, 'CrusaderAura')) and (not buff[classtable.AuraBuff].up and false and false) and cooldown[classtable.CrusaderAura].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.CrusaderAura end
    end
    if (MaxDps:CheckSpellUsable(classtable.DevotionAura, 'DevotionAura')) and (not buff[classtable.AuraBuff].up and false and false) and cooldown[classtable.DevotionAura].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.DevotionAura end
    end
    if (MaxDps:CheckSpellUsable(classtable.ResistanceAura, 'ResistanceAura')) and (not buff[classtable.AuraBuff].up and false and false) and cooldown[classtable.ResistanceAura].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.ResistanceAura end
    end
    if (MaxDps:CheckSpellUsable(classtable.BlessingofKings, 'BlessingofKings')) and (not buff[classtable.BlessingBuff].up and false and false) and cooldown[classtable.BlessingofKings].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.BlessingofKings end
    end
    if (MaxDps:CheckSpellUsable(classtable.BlessingofMight, 'BlessingofMight')) and (not buff[classtable.BlessingBuff].up and false and false) and cooldown[classtable.BlessingofMight].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.BlessingofMight end
    end
    if (MaxDps:CheckSpellUsable(classtable.SealofTruth, 'SealofTruth')) and (buff[classtable.SealBuff].remains <300) and cooldown[classtable.SealofTruth].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.SealofTruth end
    end
    if (MaxDps:CheckSpellUsable(classtable.DivinePlea, 'DivinePlea')) and (ManaPerc <90) and cooldown[classtable.DivinePlea].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.DivinePlea end
    end
    if (MaxDps:CheckSpellUsable(classtable.GuardianofAncientKings, 'GuardianofAncientKings')) and (cooldown[classtable.Zealotry].remains <= 10 or cooldown[classtable.Zealotry].remains >= ttd) and cooldown[classtable.GuardianofAncientKings].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.GuardianofAncientKings end
    end
    if (MaxDps:CheckSpellUsable(classtable.Judgement, 'Judgement')) and cooldown[classtable.Judgement].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Judgement end
    end
end
function Retribution:single()
    if (MaxDps:CheckSpellUsable(classtable.Rebuke, 'Rebuke')) and cooldown[classtable.Rebuke].ready then
        MaxDps:GlowCooldown(classtable.Rebuke, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (MaxDps:CheckSpellUsable(classtable.SealofTruth, 'SealofTruth')) and (not buff[classtable.SealBuff].up or ( buff[classtable.SealofRighteousnessBuff].up and targets == 1 )) and cooldown[classtable.SealofTruth].ready then
        if not setSpell then setSpell = classtable.SealofTruth end
    end
    if (MaxDps:CheckSpellUsable(classtable.Judgement, 'Judgement')) and (not buff[classtable.JudgementsofthePureBuff].up) and cooldown[classtable.Judgement].ready then
        if not setSpell then setSpell = classtable.Judgement end
    end
    if (MaxDps:CheckSpellUsable(classtable.GuardianofAncientKings, 'GuardianofAncientKings')) and (cooldown[classtable.Zealotry].remains <= 10 or cooldown[classtable.Zealotry].remains >= ttd) and cooldown[classtable.GuardianofAncientKings].ready then
        if not setSpell then setSpell = classtable.GuardianofAncientKings end
    end
    if (MaxDps:CheckSpellUsable(classtable.AvengingWrath, 'AvengingWrath')) and (( ( buff[classtable.ZealotryBuff].up and not false ) or not (talents[classtable.Zealotry] and true or false) ) and buff[classtable.InquisitionBuff].up) and cooldown[classtable.AvengingWrath].ready then
        if not setSpell then setSpell = classtable.AvengingWrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Zealotry, 'Zealotry') and talents[classtable.Zealotry]) and cooldown[classtable.Zealotry].ready then
        if not setSpell then setSpell = classtable.Zealotry end
    end
    if (MaxDps:CheckSpellUsable(classtable.Inquisition, 'Inquisition')) and (buff[classtable.InquisitionBuff].remains <= 3.5 and not cooldown[classtable.Zealotry].ready and cooldown[classtable.Zealotry].remains and ttd >6) and cooldown[classtable.Inquisition].ready then
        if not setSpell then setSpell = classtable.Inquisition end
    end
    if (MaxDps:CheckSpellUsable(classtable.WordofGlory, 'WordofGlory')) and (not buff[classtable.SelflessBuff].up and ( HolyPower == 3 or buff[classtable.DivinePurposeBuff].up ) and false and ( can_spend_holy_power() or not false )) and cooldown[classtable.WordofGlory].ready then
        if not setSpell then setSpell = classtable.WordofGlory end
    end
    if (MaxDps:CheckSpellUsable(classtable.TemplarsVerdict, 'TemplarsVerdict')) and (HolyPower >= 3 or buff[classtable.DivinePurposeBuff].up and cooldown[classtable.CrusaderStrike].remains) and cooldown[classtable.TemplarsVerdict].ready then
        if not setSpell then setSpell = classtable.TemplarsVerdict end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrusaderStrike, 'CrusaderStrike')) and (HolyPower <3) and cooldown[classtable.CrusaderStrike].ready then
        if not setSpell then setSpell = classtable.CrusaderStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Judgement, 'Judgement')) and ((MaxDps.tier and MaxDps.tier[13].count >= 2) and not buff[classtable.ZealotryBuff].up and HolyPower <3) and cooldown[classtable.Judgement].ready then
        if not setSpell then setSpell = classtable.Judgement end
    end
    if (MaxDps:CheckSpellUsable(classtable.Exorcism, 'Exorcism')) and (( cooldown[classtable.CrusaderStrike].remains >= 1 or not MaxDps:Bloodlust(1) ) and buff[classtable.TheArtofWarBuff].up) and cooldown[classtable.Exorcism].ready then
        if not setSpell then setSpell = classtable.Exorcism end
    end
    if (MaxDps:CheckSpellUsable(classtable.HammerofWrath, 'HammerofWrath')) and cooldown[classtable.HammerofWrath].ready then
        if not setSpell then setSpell = classtable.HammerofWrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Judgement, 'Judgement')) and (cooldown[classtable.CrusaderStrike].remains >= 1 or not MaxDps:Bloodlust(1)) and cooldown[classtable.Judgement].ready then
        if not setSpell then setSpell = classtable.Judgement end
    end
    if (MaxDps:CheckSpellUsable(classtable.HolyWrath, 'HolyWrath')) and (cooldown[classtable.CrusaderStrike].remains >= 1 or not MaxDps:Bloodlust(1)) and cooldown[classtable.HolyWrath].ready then
        if not setSpell then setSpell = classtable.HolyWrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Consecration, 'Consecration')) and (( false or not (GetUnitSpeed('player') >0) ) and false and ( cooldown[classtable.CrusaderStrike].remains >= 1 or not MaxDps:Bloodlust(1) ) and Mana >= 16000) and cooldown[classtable.Consecration].ready then
        if not setSpell then setSpell = classtable.Consecration end
    end
    if (MaxDps:CheckSpellUsable(classtable.DivinePlea, 'DivinePlea')) and (ManaPerc <75) and cooldown[classtable.DivinePlea].ready then
        if not setSpell then setSpell = classtable.DivinePlea end
    end
end
function Retribution:cleave()
    if (MaxDps:CheckSpellUsable(classtable.Rebuke, 'Rebuke')) and cooldown[classtable.Rebuke].ready then
        MaxDps:GlowCooldown(classtable.Rebuke, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (MaxDps:CheckSpellUsable(classtable.SealofRighteousness, 'SealofRighteousness')) and (not buff[classtable.SealofRighteousnessBuff].up and targets >= 4) and cooldown[classtable.SealofRighteousness].ready then
        if not setSpell then setSpell = classtable.SealofRighteousness end
    end
    if (MaxDps:CheckSpellUsable(classtable.Judgement, 'Judgement')) and (( ManaPerc <50 ) and not buff[classtable.JudgementsoftheBoldBuff].up) and cooldown[classtable.Judgement].ready then
        if not setSpell then setSpell = classtable.Judgement end
    end
    if (MaxDps:CheckSpellUsable(classtable.GuardianofAncientKings, 'GuardianofAncientKings')) and (cooldown[classtable.Zealotry].remains <10) and cooldown[classtable.GuardianofAncientKings].ready then
        if not setSpell then setSpell = classtable.GuardianofAncientKings end
    end
    if (MaxDps:CheckSpellUsable(classtable.Zealotry, 'Zealotry') and talents[classtable.Zealotry]) and (buff[classtable.GuardianofAncientKingsBuff].remains <21 and ( HolyPower == 3 or buff[classtable.DivinePurposeBuff].up ) and UnitLevel('player') == 85) and cooldown[classtable.Zealotry].ready then
        if not setSpell then setSpell = classtable.Zealotry end
    end
    if (MaxDps:CheckSpellUsable(classtable.Zealotry, 'Zealotry') and talents[classtable.Zealotry]) and (( HolyPower == 3 or buff[classtable.DivinePurposeBuff].up ) and UnitLevel('player') <85) and cooldown[classtable.Zealotry].ready then
        if not setSpell then setSpell = classtable.Zealotry end
    end
    if (MaxDps:CheckSpellUsable(classtable.AvengingWrath, 'AvengingWrath')) and (( buff[classtable.ZealotryBuff].up and not false ) or not (talents[classtable.Zealotry] and true or false)) and cooldown[classtable.AvengingWrath].ready then
        if not setSpell then setSpell = classtable.AvengingWrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Judgement, 'Judgement')) and (ManaPerc <50 and not buff[classtable.JudgementsoftheBoldBuff].up) and cooldown[classtable.Judgement].ready then
        if not setSpell then setSpell = classtable.Judgement end
    end
    if (MaxDps:CheckSpellUsable(classtable.DivineStorm, 'DivineStorm')) and (targets >= 8) and cooldown[classtable.DivineStorm].ready then
        if not setSpell then setSpell = classtable.DivineStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.Inquisition, 'Inquisition')) and (( not buff[classtable.InquisitionBuff].up or ( 3 * cooldown[classtable.CrusaderStrike].duration * 0.66 ) >buff[classtable.InquisitionBuff].remains ) and ( HolyPower == 3 or buff[classtable.DivinePurposeBuff].up ) and ( can_spend_holy_power() or not false )) and cooldown[classtable.Inquisition].ready then
        if not setSpell then setSpell = classtable.Inquisition end
    end
    if (MaxDps:CheckSpellUsable(classtable.WordofGlory, 'WordofGlory')) and (not buff[classtable.SelflessBuff].up and ( HolyPower == 3 or buff[classtable.DivinePurposeBuff].up ) and false and ( can_spend_holy_power() or not false )) and cooldown[classtable.WordofGlory].ready then
        if not setSpell then setSpell = classtable.WordofGlory end
    end
    if (MaxDps:CheckSpellUsable(classtable.DivineStorm, 'DivineStorm')) and (HolyPower <3 and targets >= 4) and cooldown[classtable.DivineStorm].ready then
        if not setSpell then setSpell = classtable.DivineStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.Consecration, 'Consecration')) and (( false or not (GetUnitSpeed('player') >0) ) and not buff[classtable.ActiveConsecrationBuff].up and targets >4) and cooldown[classtable.Consecration].ready then
        if not setSpell then setSpell = classtable.Consecration end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrusaderStrike, 'CrusaderStrike')) and (HolyPower <3 and targets <4) and cooldown[classtable.CrusaderStrike].ready then
        if not setSpell then setSpell = classtable.CrusaderStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.TemplarsVerdict, 'TemplarsVerdict')) and (( buff[classtable.DivinePurposeBuff].up or HolyPower == 3 ) and ( can_spend_holy_power() or not false )) and cooldown[classtable.TemplarsVerdict].ready then
        if not setSpell then setSpell = classtable.TemplarsVerdict end
    end
    if (MaxDps:CheckSpellUsable(classtable.Consecration, 'Consecration')) and (( false or not (GetUnitSpeed('player') >0) ) and not buff[classtable.ActiveConsecrationBuff].up and targets >2) and cooldown[classtable.Consecration].ready then
        if not setSpell then setSpell = classtable.Consecration end
    end
    if (MaxDps:CheckSpellUsable(classtable.Judgement, 'Judgement')) and (not buff[classtable.ZealotryBuff].up and HolyPower <3) and cooldown[classtable.Judgement].ready then
        if not setSpell then setSpell = classtable.Judgement end
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
    if (MaxDps:CheckSpellUsable(classtable.CrusaderStrike, 'CrusaderStrike')) and cooldown[classtable.CrusaderStrike].ready then
        if not setSpell then setSpell = classtable.CrusaderStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.HolyWrath, 'HolyWrath')) and cooldown[classtable.HolyWrath].ready then
        if not setSpell then setSpell = classtable.HolyWrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.DivinePlea, 'DivinePlea')) and (ManaPerc <75) and cooldown[classtable.DivinePlea].ready then
        if not setSpell then setSpell = classtable.DivinePlea end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Rebuke, false)
end

function Retribution:callaction()
    if (targets >1) then
        Retribution:cleave()
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
    classtable.TemplarSlash = 406647
    classtable.TemplarStrike = 407480
    classtable.FinalVerdictBuff = 383329
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.Zealotry = 85696
    classtable.RetributionAura = 7294
    classtable.ConcentrationAura = 19746
    classtable.CrusaderAura = 32223
    classtable.DevotionAura = 465
    classtable.ResistanceAura = 19891
    classtable.BlessingofKings = 20217
    classtable.BlessingofMight = 19740
    classtable.SealofTruth = 31801
    classtable.DivinePlea = 54428
    classtable.GuardianofAncientKings = 86150
    classtable.Judgement = 20271
    classtable.Rebuke = 96231
    classtable.AvengingWrath = 31884
    classtable.Inquisition = 84963
    classtable.WordofGlory = 85673
    classtable.TemplarsVerdict = 85256
    classtable.CrusaderStrike = 35395
    classtable.Exorcism = 879
    classtable.HammerofWrath = 24275
    classtable.HolyWrath = 2812
    classtable.Consecration = 26573
    classtable.SealofRighteousness = 20154
    classtable.DivineStorm = 53385

    local function debugg()
        talents[classtable.Zealotry] = 1
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Retribution:precombat()

    Retribution:callaction()
    if setSpell then return setSpell end
end
