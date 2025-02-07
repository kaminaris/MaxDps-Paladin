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
local next_armament

local Protection = {}

local time_to_die


local function hammer_of_light_free()
	if buff[classtable.LightsDeliverance].count == 60 then
		return true
	else
		return false
	end
end

local function hammer_of_light_free_remains()
    return buff[classtable.LightsDeliverance].count == 60 and buff[classtable.LightsDeliverance].up and buff[classtable.LightsDeliverance].remains or 0
end

local holy_power_generators_used = 0
local hpg_used = 0
local hpg_to_2dawn = 0
function Paladin:CLEU()
    local  _, subtype, _,  sourceGUID, sourceName, _, _, destGUID, destName, destFlags, _, spellID, spellName, _, amount, overEnergize, powerType = CombatLogGetCurrentEventInfo()
    if sourceGUID ~= UnitGUID( 'player' ) then return end
    if subtype == 'SPELL_ENERGIZE' and powerType == Enum.PowerType.HolyPower and ( amount + overEnergize ) > 0 then
        local ability = classtable[ spellName ]
        if ability and C_Spell.GetSpellName(ability) ~= 'Arcane Torrent' and C_Spell.GetSpellName(ability) ~= 'Divine Toll' then
            holy_power_generators_used = ( holy_power_generators_used + 1 ) % 3
            return
        end
    elseif spellID == 385127 and ( subtype == 'SPELL_AURA_APPLIED' or subtype == 'SPELL_AURA_REFRESH' or subtype == 'SPELL_AURA_APPLIED_DOSE' ) then
        holy_power_generators_used = max( 0, holy_power_generators_used - 3 )
        return
    end
end

function Protection:precombat()
    if (MaxDps:CheckSpellUsable(classtable.RighteousFury, 'RighteousFury')) and (not buff[classtable.RighteousFuryBuff].up) and cooldown[classtable.RighteousFury].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.RighteousFury end
    end
    --if (MaxDps:CheckSpellUsable(classtable.RetributionAura, 'RetributionAura')) and (not buff[classtable.AuraBuff].up and false and false) and cooldown[classtable.RetributionAura].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.RetributionAura end
    --end
    --if (MaxDps:CheckSpellUsable(classtable.ConcentrationAura, 'ConcentrationAura')) and (not buff[classtable.AuraBuff].up and false and false) and cooldown[classtable.ConcentrationAura].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.ConcentrationAura end
    --end
    --if (MaxDps:CheckSpellUsable(classtable.CrusaderAura, 'CrusaderAura')) and (not buff[classtable.AuraBuff].up and false and false) and cooldown[classtable.CrusaderAura].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.CrusaderAura end
    --end
    --if (MaxDps:CheckSpellUsable(classtable.DevotionAura, 'DevotionAura')) and (not buff[classtable.AuraBuff].up and false and false) and cooldown[classtable.DevotionAura].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.DevotionAura end
    --end
    --if (MaxDps:CheckSpellUsable(classtable.ResistanceAura, 'ResistanceAura')) and (not buff[classtable.AuraBuff].up and false and false) and cooldown[classtable.ResistanceAura].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.ResistanceAura end
    --end
    --if (MaxDps:CheckSpellUsable(classtable.BlessingofKings, 'BlessingofKings')) and (not buff[classtable.BlessingBuff].up and false and false) and cooldown[classtable.BlessingofKings].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.BlessingofKings end
    --end
    --if (MaxDps:CheckSpellUsable(classtable.BlessingofMight, 'BlessingofMight')) and (not buff[classtable.BlessingBuff].up and false and false) and cooldown[classtable.BlessingofMight].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.BlessingofMight end
    --end
    if (MaxDps:CheckSpellUsable(classtable.SealofTruth, 'SealofTruth')) and (buff[classtable.SealofTruth].remains <360 or not buff[classtable.SealofTruth].up) and cooldown[classtable.SealofTruth].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.SealofTruth end
    end
    if (MaxDps:CheckSpellUsable(classtable.DivinePlea, 'DivinePlea')) and (( HolyPower <3 or ManaPerc <75 ) and false) and cooldown[classtable.DivinePlea].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.DivinePlea end
    end
    if (MaxDps:CheckSpellUsable(classtable.Inquisition, 'Inquisition')) and (( not buff[classtable.InquisitionBuff].up or buff[classtable.InquisitionBuff].remains <6 ) and HolyPower == 3 and false) and cooldown[classtable.Inquisition].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Inquisition end
    end
    if (MaxDps:CheckSpellUsable(classtable.AvengingWrath, 'AvengingWrath')) and (false) and cooldown[classtable.AvengingWrath].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.AvengingWrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Exorcism, 'Exorcism')) and (false) and cooldown[classtable.Exorcism].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Exorcism end
    end
    if (MaxDps:CheckSpellUsable(classtable.AvengersShield, 'AvengersShield')) and (false) and cooldown[classtable.AvengersShield].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.AvengersShield end
    end
    if (MaxDps:CheckSpellUsable(classtable.Judgement, 'Judgement')) and (false) and cooldown[classtable.Judgement].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Judgement end
    end
end
function Protection:init()
    time_to_die = ( debuff[classtable.TrainingDummyDeBuff].up and 300 ) or ttd
end
function Protection:cleave()
    if (MaxDps:CheckSpellUsable(classtable.LayOnHands, 'LayOnHands')) and (curentHP <20) and cooldown[classtable.LayOnHands].ready then
        if not setSpell then setSpell = classtable.LayOnHands end
    end
    if (MaxDps:CheckSpellUsable(classtable.GuardianofAncientKings, 'GuardianofAncientKings')) and (curentHP <20 and not buff[classtable.ArdentDefenderBuff].up) and cooldown[classtable.GuardianofAncientKings].ready then
        if not setSpell then setSpell = classtable.GuardianofAncientKings end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArdentDefender, 'ArdentDefender')) and (curentHP <20 and not buff[classtable.GuardianofAncientKingsBuff].up) and cooldown[classtable.ArdentDefender].ready then
        if not setSpell then setSpell = classtable.ArdentDefender end
    end
    if (MaxDps:CheckSpellUsable(classtable.HolyShield, 'HolyShield')) and (curentHP <60 and not buff[classtable.DefensiveBuff].up) and cooldown[classtable.HolyShield].ready then
        if not setSpell then setSpell = classtable.HolyShield end
    end
    if (MaxDps:CheckSpellUsable(classtable.DivineProtection, 'DivineProtection')) and (curentHP <60 and not buff[classtable.DefensiveBuff].up) and cooldown[classtable.DivineProtection].ready then
        if not setSpell then setSpell = classtable.DivineProtection end
    end
    if (MaxDps:CheckSpellUsable(classtable.DivineGuardian, 'DivineGuardian')) and (curentHP <60 and not buff[classtable.DefensiveBuff].up and false) and cooldown[classtable.DivineGuardian].ready then
        if not setSpell then setSpell = classtable.DivineGuardian end
    end
    if (MaxDps:CheckSpellUsable(classtable.LayOnHands, 'LayOnHands')) and (curentHP <20) and cooldown[classtable.LayOnHands].ready then
        if not setSpell then setSpell = classtable.LayOnHands end
    end
    if (MaxDps:CheckSpellUsable(classtable.SealofTruth, 'SealofTruth')) and (not buff[classtable.SealofTruth].up) and cooldown[classtable.SealofTruth].ready then
        if not setSpell then setSpell = classtable.SealofTruth end
    end
    if (MaxDps:CheckSpellUsable(classtable.AvengingWrath, 'AvengingWrath')) and cooldown[classtable.AvengingWrath].ready then
        if not setSpell then setSpell = classtable.AvengingWrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.DivinePlea, 'DivinePlea')) and (HolyPower == 0 or ManaPerc <75) and cooldown[classtable.DivinePlea].ready then
        if not setSpell then setSpell = classtable.DivinePlea end
    end
    if (MaxDps:CheckSpellUsable(classtable.WordofGlory, 'WordofGlory')) and (HolyPower == 3 and curentHP <90) and cooldown[classtable.WordofGlory].ready then
        if not setSpell then setSpell = classtable.WordofGlory end
    end
    if (MaxDps:CheckSpellUsable(classtable.Inquisition, 'Inquisition')) and (HolyPower == 3) and cooldown[classtable.Inquisition].ready then
        if not setSpell then setSpell = classtable.Inquisition end
    end
    if (MaxDps:CheckSpellUsable(classtable.HammeroftheRighteous, 'HammeroftheRighteous')) and cooldown[classtable.HammeroftheRighteous].ready then
        if not setSpell then setSpell = classtable.HammeroftheRighteous end
    end
    if (MaxDps:CheckSpellUsable(classtable.AvengersShield, 'AvengersShield')) and cooldown[classtable.AvengersShield].ready then
        if not setSpell then setSpell = classtable.AvengersShield end
    end
    if (MaxDps:CheckSpellUsable(classtable.Consecration, 'Consecration')) and cooldown[classtable.Consecration].ready then
        if not setSpell then setSpell = classtable.Consecration end
    end
    if (MaxDps:CheckSpellUsable(classtable.HolyWrath, 'HolyWrath')) and cooldown[classtable.HolyWrath].ready then
        if not setSpell then setSpell = classtable.HolyWrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Judgement, 'Judgement')) and cooldown[classtable.Judgement].ready then
        if not setSpell then setSpell = classtable.Judgement end
    end
end
function Protection:single()
    if (MaxDps:CheckSpellUsable(classtable.LayOnHands, 'LayOnHands')) and (curentHP <20) and cooldown[classtable.LayOnHands].ready then
        if not setSpell then setSpell = classtable.LayOnHands end
    end
    if (MaxDps:CheckSpellUsable(classtable.GuardianofAncientKings, 'GuardianofAncientKings')) and (curentHP <20 and not buff[classtable.ArdentDefenderBuff].up) and cooldown[classtable.GuardianofAncientKings].ready then
        if not setSpell then setSpell = classtable.GuardianofAncientKings end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArdentDefender, 'ArdentDefender')) and (curentHP <20 and not buff[classtable.GuardianofAncientKingsBuff].up) and cooldown[classtable.ArdentDefender].ready then
        if not setSpell then setSpell = classtable.ArdentDefender end
    end
    if (MaxDps:CheckSpellUsable(classtable.HolyShield, 'HolyShield')) and (curentHP <60 and not buff[classtable.DefensiveBuff].up) and cooldown[classtable.HolyShield].ready then
        if not setSpell then setSpell = classtable.HolyShield end
    end
    if (MaxDps:CheckSpellUsable(classtable.DivineProtection, 'DivineProtection')) and (curentHP <60 and not buff[classtable.DefensiveBuff].up) and cooldown[classtable.DivineProtection].ready then
        if not setSpell then setSpell = classtable.DivineProtection end
    end
    if (MaxDps:CheckSpellUsable(classtable.DivineGuardian, 'DivineGuardian')) and (curentHP <60 and not buff[classtable.DefensiveBuff].up and false) and cooldown[classtable.DivineGuardian].ready then
        if not setSpell then setSpell = classtable.DivineGuardian end
    end
    if (MaxDps:CheckSpellUsable(classtable.SealofTruth, 'SealofTruth')) and (not buff[classtable.SealofTruth].up) and cooldown[classtable.SealofTruth].ready then
        if not setSpell then setSpell = classtable.SealofTruth end
    end
    if (MaxDps:CheckSpellUsable(classtable.AvengingWrath, 'AvengingWrath')) and cooldown[classtable.AvengingWrath].ready then
        if not setSpell then setSpell = classtable.AvengingWrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.AvengersShield, 'AvengersShield')) and (false) and cooldown[classtable.AvengersShield].ready then
        if not setSpell then setSpell = classtable.AvengersShield end
    end
    if (MaxDps:CheckSpellUsable(classtable.DivinePlea, 'DivinePlea')) and (HolyPower == 0 or ManaPerc <75) and cooldown[classtable.DivinePlea].ready then
        if not setSpell then setSpell = classtable.DivinePlea end
    end
    if (MaxDps:CheckSpellUsable(classtable.WordofGlory, 'WordofGlory')) and (HolyPower == 3 and curentHP <90) and cooldown[classtable.WordofGlory].ready then
        if not setSpell then setSpell = classtable.WordofGlory end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShieldoftheRighteous, 'ShieldoftheRighteous')) and (HolyPower == 3) and cooldown[classtable.ShieldoftheRighteous].ready then
        if not setSpell then setSpell = classtable.ShieldoftheRighteous end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrusaderStrike, 'CrusaderStrike')) and (HolyPower <3) and cooldown[classtable.CrusaderStrike].ready then
        if not setSpell then setSpell = classtable.CrusaderStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.AvengersShield, 'AvengersShield')) and cooldown[classtable.AvengersShield].ready then
        if not setSpell then setSpell = classtable.AvengersShield end
    end
    if (MaxDps:CheckSpellUsable(classtable.HammerofWrath, 'HammerofWrath')) and (targethealthPerc <20) and cooldown[classtable.HammerofWrath].ready then
        if not setSpell then setSpell = classtable.HammerofWrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Judgement, 'Judgement')) and cooldown[classtable.Judgement].ready then
        if not setSpell then setSpell = classtable.Judgement end
    end
    if (MaxDps:CheckSpellUsable(classtable.Consecration, 'Consecration')) and cooldown[classtable.Consecration].ready then
        if not setSpell then setSpell = classtable.Consecration end
    end
    if (MaxDps:CheckSpellUsable(classtable.HolyWrath, 'HolyWrath')) and cooldown[classtable.HolyWrath].ready then
        if not setSpell then setSpell = classtable.HolyWrath end
    end
end


local function ClearCDs()
end

function Protection:callaction()
    Protection:init()
    if (targets >1) then
        Protection:cleave()
    end
    if (targets <=1) then
        Protection:single()
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
    classtable = MaxDps.SpellTable
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
    HolyPower = UnitPower('player', HolyPowerPT)
    HolyPowerMax = 5
    HolyPowerDeficit = HolyPowerMax - HolyPower
    ManaPerc = (Mana / ManaMax) * 100
    next_armament = function()
        local firstSpell = GetSpellInfo(classtable.HolyArmaments)
        local spellinfo = firstSpell and GetSpellInfo(firstSpell.spellID)
        return spellinfo and spellinfo.spellID or 0
    end
    classtable.HammerofLight = 427453
    classtable.HolyArmaments = 432459
    hpg_used = holy_power_generators_used
    classtable.BlessingofDawnBuff = 385127
    hpg_to_2dawn = max( -1, 6 - hpg_used - ( buff[classtable.BlessingofDawnBuff].count * 3 ) )
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.RighteousFuryBuff = 25780
    classtable.InquisitionBuff = 84963
    classtable.ArdentDefenderBuff = 31850
    classtable.GuardianofAncientKingsBuff = 86669
    classtable.RighteousFury = 25780
    classtable.RetributionAura = 7294
    classtable.ConcentrationAura = 19746
    classtable.CrusaderAura = 32223
    classtable.DevotionAura = 465
    classtable.ResistanceAura = 19891
    classtable.BlessingofKings = 20217
    classtable.BlessingofMight = 19740
    classtable.SealofTruth = 31801
    classtable.DivinePlea = 54428
    classtable.Inquisition = 84963
    classtable.AvengingWrath = 31884
    classtable.Exorcism = 879
    classtable.AvengersShield = 31935
    classtable.Judgement = 20271
    classtable.LayOnHands = 633
    classtable.GuardianofAncientKings = 86150
    classtable.ArdentDefender = 31850
    classtable.HolyShield = 20925
    classtable.DivineProtection = 498
    classtable.DivineGuardian = 70940
    classtable.WordofGlory = 85673
    classtable.HammeroftheRighteous = 53595
    classtable.Consecration = 26573
    classtable.HolyWrath = 2812
    classtable.ShieldoftheRighteous = 53600
    classtable.CrusaderStrike = 35395
    classtable.HammerofWrath = 24275

    local function debugg()
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Protection:precombat()

    Protection:callaction()
    if setSpell then return setSpell end
end
