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
local ManaPerc

local Retribution = {}

local trinket_1_buffs = false
local trinket_2_buffs = false
local trinket_1_sync = false
local trinket_2_sync = false
local trinket_priority = false
local ds_castable = false
local finished = false


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

function Retribution:precombat()
    if (MaxDps:CheckSpellUsable(classtable.ShieldofVengeance, 'ShieldofVengeance')) and cooldown[classtable.ShieldofVengeance].ready and not UnitAffectingCombat('player') then
        MaxDps:GlowCooldown(classtable.ShieldofVengeance, cooldown[classtable.ShieldofVengeance].ready)
    end
end
function Retribution:cooldowns()
    if (MaxDps:CheckSpellUsable(classtable.ShieldofVengeance, 'ShieldofVengeance')) and (ttd >15 and ( not talents[classtable.ExecutionSentence] or not debuff[classtable.ExecutionSentenceDeBuff].up ) and not buff[classtable.DivineHammerBuff].up) and cooldown[classtable.ShieldofVengeance].ready then
        MaxDps:GlowCooldown(classtable.ShieldofVengeance, cooldown[classtable.ShieldofVengeance].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ExecutionSentence, 'ExecutionSentence') and talents[classtable.ExecutionSentence]) and (( not buff[classtable.CrusadeBuff].up and cooldown[classtable.Crusade].remains >15 or buff[classtable.CrusadeBuff].count == 10 or cooldown[classtable.AvengingWrath].remains <0.75 or cooldown[classtable.AvengingWrath].remains >15 or talents[classtable.RadiantGlory] ) and ( HolyPower >= 4 and timeInCombat <5 or HolyPower >= 3 and timeInCombat >5 or ( HolyPower >= 2 or timeInCombat <5 ) and ( talents[classtable.DivineAuxiliary] or talents[classtable.RadiantGlory] ) ) and ( cooldown[classtable.DivineHammer].remains >5 or buff[classtable.DivineHammerBuff].up or not talents[classtable.DivineHammer] ) and ( ttd >8 and not talents[classtable.ExecutionersWill] or ttd >12 ) and cooldown[classtable.WakeofAshes].remains <gcd) and cooldown[classtable.ExecutionSentence].ready then
        MaxDps:GlowCooldown(classtable.ExecutionSentence, cooldown[classtable.ExecutionSentence].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.AvengingWrath, 'AvengingWrath') and talents[classtable.AvengingWrath] and not talents[classtable.RadiantGlory]) and (( HolyPower >= 4 and timeInCombat <5 or HolyPower >= 3 and timeInCombat >5 or HolyPower >= 2 and talents[classtable.DivineAuxiliary] and ( cooldown[classtable.ExecutionSentence].remains == 0 or cooldown[classtable.FinalReckoning].remains == 0 ) ) and ( not (targets >1) or ttd >10 )) and cooldown[classtable.AvengingWrath].ready then
        MaxDps:GlowCooldown(classtable.AvengingWrath, cooldown[classtable.AvengingWrath].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Crusade, 'Crusade') and talents[classtable.Crusade]) and (HolyPower >= 5 and timeInCombat <5 or HolyPower >= 3 and timeInCombat >5) and cooldown[classtable.Crusade].ready then
        MaxDps:GlowCooldown(classtable.Crusade, cooldown[classtable.Crusade].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FinalReckoning, 'FinalReckoning')) and (( HolyPower >= 4 and timeInCombat <8 or HolyPower >= 3 and timeInCombat >= 8 or HolyPower >= 2 and ( talents[classtable.DivineAuxiliary] or talents[classtable.RadiantGlory] ) ) and ( cooldown[classtable.AvengingWrath].remains >10 or not cooldown[classtable.Crusade].ready and ( not buff[classtable.CrusadeBuff].up or buff[classtable.CrusadeBuff].count >= 10 ) or talents[classtable.RadiantGlory] and ( buff[classtable.AvengingWrathBuff].up or talents[classtable.Crusade] and cooldown[classtable.WakeofAshes].remains <gcd ) ) and ( (targets <2) or (targets >1) or math.huge >40 )) and cooldown[classtable.FinalReckoning].ready then
        MaxDps:GlowCooldown(classtable.FinalReckoning, cooldown[classtable.FinalReckoning].ready)
    end
end
function Retribution:finishers()
    ds_castable = ( targets >= 2 or buff[classtable.EmpyreanPowerBuff].up or not talents[classtable.FinalVerdict] and talents[classtable.TempestoftheLightbringer] ) and not buff[classtable.EmpyreanLegacyBuff].up and not ( buff[classtable.DivineArbiterBuff].up and buff[classtable.DivineArbiterBuff].count >24 )
    if (MaxDps:CheckSpellUsable(classtable.HammerofLight, 'HammerofLight')) and (buff[classtable.HammerofLightReadyBuff].up or not talents[classtable.DivineHammer] or buff[classtable.DivineHammerBuff].up or cooldown[classtable.DivineHammer].remains >10) and cooldown[classtable.HammerofLight].ready then
        if not setSpell then setSpell = classtable.HammerofLight end
    end
    if (MaxDps:CheckSpellUsable(classtable.DivineHammer, 'DivineHammer') and talents[classtable.DivineHammer]) and (not buff[classtable.DivineHammerBuff].up) and cooldown[classtable.DivineHammer].ready then
        if not setSpell then setSpell = classtable.DivineHammer end
    end
    if (MaxDps:CheckSpellUsable(classtable.DivineStorm, 'DivineStorm')) and (ds_castable and not buff[classtable.HammerofLightReadyBuff].up and ( not cooldown[classtable.DivineHammer].ready or buff[classtable.DivineHammerBuff].up or not talents[classtable.DivineHammer] ) and ( not talents[classtable.Crusade] or cooldown[classtable.Crusade].remains >gcd * 3 or buff[classtable.CrusadeBuff].up and buff[classtable.CrusadeBuff].count <10 or talents[classtable.RadiantGlory] )) and cooldown[classtable.DivineStorm].ready then
        if not setSpell then setSpell = classtable.DivineStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.JusticarsVengeance, 'JusticarsVengeance') and talents[classtable.JusticarsVengeance]) and (( not talents[classtable.Crusade] or cooldown[classtable.Crusade].remains >gcd * 3 or buff[classtable.CrusadeBuff].up and buff[classtable.CrusadeBuff].count <10 or talents[classtable.RadiantGlory] ) and not buff[classtable.HammerofLightReadyBuff].up and ( not cooldown[classtable.DivineHammer].ready or buff[classtable.DivineHammerBuff].up or not talents[classtable.DivineHammer] )) and cooldown[classtable.JusticarsVengeance].ready then
        if not setSpell then setSpell = classtable.JusticarsVengeance end
    end
    if (MaxDps:CheckSpellUsable(classtable.TemplarsVerdict, 'TemplarsVerdict')) and (( not talents[classtable.Crusade] or cooldown[classtable.Crusade].remains >gcd * 3 or buff[classtable.CrusadeBuff].up and buff[classtable.CrusadeBuff].count <10 or talents[classtable.RadiantGlory] ) and not buff[classtable.HammerofLightReadyBuff].up and ( not cooldown[classtable.DivineHammer].ready or buff[classtable.DivineHammerBuff].up or not talents[classtable.DivineHammer] )) and cooldown[classtable.TemplarsVerdict].ready then
        if not setSpell then setSpell = classtable.TemplarsVerdict end
    end
    finished = true
end
function Retribution:generators()
    finished = false
    if (( HolyPower == 5 or HolyPower == 4 and buff[classtable.DivineResonanceBuff].up or buff[classtable.AllInBuff].up ) and not cooldown[classtable.WakeofAshes].ready) then
        Retribution:finishers()
    end
    if (MaxDps:CheckSpellUsable(classtable.TemplarSlash, 'TemplarSlash') and talents[classtable.TemplarStrikes]) and (buff[classtable.TemplarStrikesBuff].remains <gcd * 2) and cooldown[classtable.TemplarSlash].ready then
        if not setSpell then setSpell = classtable.TemplarSlash end
    end
    if (MaxDps:CheckSpellUsable(classtable.BladeofJustice, 'BladeofJustice')) and (not debuff[classtable.ExpurgationDeBuff].up and talents[classtable.HolyFlames] and not cooldown[classtable.DivineToll].ready) and cooldown[classtable.BladeofJustice].ready then
        if not setSpell then setSpell = classtable.BladeofJustice end
    end
    if (MaxDps:CheckSpellUsable(classtable.WakeofAshes, 'WakeofAshes')) and (( not talents[classtable.LightsGuidance] or HolyPower >= 2 and talents[classtable.LightsGuidance] ) and ( cooldown[classtable.AvengingWrath].remains >6 or cooldown[classtable.Crusade].remains >6 or talents[classtable.RadiantGlory] ) and ( not talents[classtable.ExecutionSentence] or cooldown[classtable.ExecutionSentence].remains >4 or ttd <8 ) and ( (targets <2) or math.huge >10 or (targets >1) )) and cooldown[classtable.WakeofAshes].ready then
        if not setSpell then setSpell = classtable.WakeofAshes end
    end
    if (MaxDps:CheckSpellUsable(classtable.DivineToll, 'DivineToll')) and (HolyPower <= 2 and ( (targets <2) or math.huge >10 or (targets >1) ) and ( cooldown[classtable.AvengingWrath].remains >15 or cooldown[classtable.Crusade].remains >15 or talents[classtable.RadiantGlory] or ttd <8 )) and cooldown[classtable.DivineToll].ready then
        MaxDps:GlowCooldown(classtable.DivineToll, cooldown[classtable.DivineToll].ready)
    end
    if (not finished) then
        Retribution:finishers()
    end
    if (MaxDps:CheckSpellUsable(classtable.TemplarSlash, 'TemplarSlash') and talents[classtable.TemplarStrikes]) and (buff[classtable.TemplarStrikesBuff].remains <gcd and targets >= 2) and cooldown[classtable.TemplarSlash].ready then
        if not setSpell then setSpell = classtable.TemplarSlash end
    end
    if (MaxDps:CheckSpellUsable(classtable.BladeofJustice, 'BladeofJustice')) and (targets >= 2 and talents[classtable.BladeofVengeance]) and cooldown[classtable.BladeofJustice].ready then
        if not setSpell then setSpell = classtable.BladeofJustice end
    end
    if (MaxDps:CheckSpellUsable(classtable.HammerofWrath, 'HammerofWrath')) and (( targets <2 or not talents[classtable.BlessedChampion] ) and buff[classtable.BlessingofAnsheBuff].up) and cooldown[classtable.HammerofWrath].ready then
        if not setSpell then setSpell = classtable.HammerofWrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.TemplarStrike, 'TemplarStrike') and talents[classtable.TemplarStrikes]) and cooldown[classtable.TemplarStrike].ready then
        if not setSpell then setSpell = classtable.TemplarStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Judgment, 'Judgment')) and cooldown[classtable.Judgment].ready then
        if not setSpell then setSpell = classtable.Judgment end
    end
    if (MaxDps:CheckSpellUsable(classtable.BladeofJustice, 'BladeofJustice')) and cooldown[classtable.BladeofJustice].ready then
        if not setSpell then setSpell = classtable.BladeofJustice end
    end
    if (MaxDps:CheckSpellUsable(classtable.HammerofWrath, 'HammerofWrath')) and (( targets <2 or not talents[classtable.BlessedChampion] )) and cooldown[classtable.HammerofWrath].ready then
        if not setSpell then setSpell = classtable.HammerofWrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.TemplarSlash, 'TemplarSlash') and talents[classtable.TemplarStrikes]) and cooldown[classtable.TemplarSlash].ready then
        if not setSpell then setSpell = classtable.TemplarSlash end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrusaderStrike, 'CrusaderStrike') and not talents[classtable.CrusadingStrikes]) and cooldown[classtable.CrusaderStrike].ready then
        if not setSpell then setSpell = classtable.CrusaderStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.HammerofWrath, 'HammerofWrath')) and cooldown[classtable.HammerofWrath].ready then
        if not setSpell then setSpell = classtable.HammerofWrath end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.ShieldofVengeance, false)
    MaxDps:GlowCooldown(classtable.Rebuke, false)
    MaxDps:GlowCooldown(classtable.ExecutionSentence, false)
    MaxDps:GlowCooldown(classtable.AvengingWrath, false)
    MaxDps:GlowCooldown(classtable.Crusade, false)
    MaxDps:GlowCooldown(classtable.FinalReckoning, false)
    MaxDps:GlowCooldown(classtable.DivineToll, false)
end

function Retribution:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Rebuke, 'Rebuke')) and cooldown[classtable.Rebuke].ready then
        MaxDps:GlowCooldown(classtable.Rebuke, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    Retribution:cooldowns()
    Retribution:generators()
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
    classtable.AvengingWrathBuff = 31884
    classtable.CrusadeBuff = 405289
    classtable.DivineHammerBuff = 198034
    classtable.EmpyreanPowerBuff = 326733
    classtable.EmpyreanLegacyBuff = 387178
    classtable.DivineArbiterBuff = 406975
    classtable.HammerofLightReadyBuff = 427453
    classtable.DivineResonanceBuff = 387895
    classtable.AllInBuff = 1216837
    classtable.TemplarStrikesBuff = 406646
    classtable.BlessingofAnsheBuff = 445206
    classtable.ExecutionSentenceDeBuff = 343527
    classtable.ExpurgationDeBuff = 383346
    classtable.HammerofLight = 427453
    classtable.TemplarSlash = 406647
    classtable.TemplarStrike = 407480

    local function debugg()
        talents[classtable.RadiantGlory] = 1
        talents[classtable.ExecutionSentence] = 1
        talents[classtable.DivineAuxiliary] = 1
        talents[classtable.DivineHammer] = 1
        talents[classtable.ExecutionersWill] = 1
        talents[classtable.Crusade] = 1
        talents[classtable.HolyFlames] = 1
        talents[classtable.LightsGuidance] = 1
        talents[classtable.BladeofVengeance] = 1
        talents[classtable.BlessedChampion] = 1
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
