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

local trinket_1_buffs
local trinket_2_buffs
local trinket_1_sync
local trinket_2_sync
local trinket_priority
local ds_castable
local finished
function Retribution:precombat()
    if (MaxDps:CheckSpellUsable(classtable.ShieldofVengeance, 'ShieldofVengeance')) and cooldown[classtable.ShieldofVengeance].ready and not UnitAffectingCombat('player') then
        MaxDps:GlowCooldown(classtable.ShieldofVengeance, cooldown[classtable.ShieldofVengeance].ready)
        --if not setSpell then setSpell = classtable.ShieldofVengeance end
    end
end
function Retribution:cooldowns()
    if (MaxDps:CheckSpellUsable(classtable.ShieldofVengeance, 'ShieldofVengeance')) and (ttd >15 and ( not talents[classtable.ExecutionSentence] or not debuff[classtable.ExecutionSentenceDeBuff].up )) and cooldown[classtable.ShieldofVengeance].ready then
        MaxDps:GlowCooldown(classtable.ShieldofVengeance, cooldown[classtable.ShieldofVengeance].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ExecutionSentence, 'ExecutionSentence') and talents[classtable.ExecutionSentence]) and (( not buff[classtable.CrusadeBuff].up and cooldown[classtable.Crusade].remains >15 or buff[classtable.CrusadeBuff].count == 10 or cooldown[classtable.AvengingWrath].remains <0.75 or cooldown[classtable.AvengingWrath].remains >15 or talents[classtable.RadiantGlory] ) and ( HolyPower >= 4 and timeInCombat <5 or HolyPower >= 3 and timeInCombat >5 or HolyPower >= 2 and ( talents[classtable.DivineAuxiliary] or talents[classtable.RadiantGlory] ) ) and ( ttd >8 and not talents[classtable.ExecutionersWill] or ttd >12 ) and cooldown[classtable.WakeofAshes].remains <gcd) and cooldown[classtable.ExecutionSentence].ready then
        if not setSpell then setSpell = classtable.ExecutionSentence end
    end
    if (MaxDps:CheckSpellUsable(classtable.AvengingWrath, 'AvengingWrath') and talents[classtable.AvengingWrath] and not talents[classtable.RadiantGlory]) and (( HolyPower >= 4 and timeInCombat <5 or HolyPower >= 3 and timeInCombat >5 or HolyPower >= 2 and talents[classtable.DivineAuxiliary] and ( cooldown[classtable.ExecutionSentence].remains == 0 or cooldown[classtable.FinalReckoning].remains == 0 ) ) and ( not (targets >1) or ttd >10 )) and cooldown[classtable.AvengingWrath].ready then
        MaxDps:GlowCooldown(classtable.AvengingWrath, cooldown[classtable.AvengingWrath].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Crusade, 'Crusade') and talents[classtable.Crusade] and not talents[classtable.RadiantGlory]) and (HolyPower >= 5 and timeInCombat <5 or HolyPower >= 3 and timeInCombat >5) and cooldown[classtable.Crusade].ready then
        MaxDps:GlowCooldown(classtable.Crusade, cooldown[classtable.Crusade].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FinalReckoning, 'FinalReckoning')) and (( HolyPower >= 4 and timeInCombat <8 or HolyPower >= 3 and timeInCombat >= 8 or HolyPower >= 2 and ( talents[classtable.DivineAuxiliary] or talents[classtable.RadiantGlory] ) ) and ( cooldown[classtable.AvengingWrath].remains >10 or cooldown[classtable.Crusade].ready==false and ( not buff[classtable.CrusadeBuff].up or buff[classtable.CrusadeBuff].count >= 10 ) or talents[classtable.RadiantGlory] and ( buff[classtable.AvengingWrathBuff].up or talents[classtable.Crusade] and cooldown[classtable.WakeofAshes].remains <gcd ) ) and ( (targets <2) or (targets >1) or math.huge >40 )) and cooldown[classtable.FinalReckoning].ready then
        MaxDps:GlowCooldown(classtable.FinalReckoning, cooldown[classtable.FinalReckoning].ready)
    end
end
function Retribution:finishers()
    ds_castable = ( targets >= 2 or buff[classtable.EmpyreanPowerBuff].up or not talents[classtable.FinalVerdict] and talents[classtable.TempestoftheLightbringer] ) and not buff[classtable.EmpyreanLegacyBuff].up and not ( buff[classtable.DivineArbiterBuff].up and buff[classtable.DivineArbiterBuff].count >24 )
    if (MaxDps:CheckSpellUsable(classtable.HammerofLight, 'HammerofLight')) and cooldown[classtable.HammerofLight].ready then
        if not setSpell then setSpell = classtable.HammerofLight end
    end
    if (MaxDps:CheckSpellUsable(classtable.DivineHammer, 'DivineHammer')) and (HolyPower == 5) and cooldown[classtable.DivineHammer].ready then
        if not setSpell then setSpell = classtable.DivineHammer end
    end
    if (MaxDps:CheckSpellUsable(classtable.DivineStorm, 'DivineStorm')) and (ds_castable and not buff[classtable.HammerofLightReadyBuff].up and ( not talents[classtable.Crusade] or cooldown[classtable.Crusade].remains >gcd * 3 or buff[classtable.CrusadeBuff].up and buff[classtable.CrusadeBuff].count <10 or talents[classtable.RadiantGlory] ) and ( not buff[classtable.DivineHammerBuff].up or cooldown[classtable.DivineHammer].remains >110 and HolyPower >= 4 )) and cooldown[classtable.DivineStorm].ready then
        if not setSpell then setSpell = classtable.DivineStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.JusticarsVengeance, 'JusticarsVengeance')) and (( not talents[classtable.Crusade] or cooldown[classtable.Crusade].remains >gcd * 3 or buff[classtable.CrusadeBuff].up and buff[classtable.CrusadeBuff].count <10 or talents[classtable.RadiantGlory] ) and not buff[classtable.HammerofLightReadyBuff].up and ( not buff[classtable.DivineHammerBuff].up or cooldown[classtable.DivineHammer].remains >110 and HolyPower >= 4 )) and cooldown[classtable.JusticarsVengeance].ready then
        if not setSpell then setSpell = classtable.JusticarsVengeance end
    end
    if (MaxDps:CheckSpellUsable(classtable.TemplarsVerdict, 'TemplarsVerdict')) and (( not talents[classtable.Crusade] or cooldown[classtable.Crusade].remains >gcd * 3 or buff[classtable.CrusadeBuff].up and buff[classtable.CrusadeBuff].count <10 or talents[classtable.RadiantGlory] ) and not buff[classtable.HammerofLightReadyBuff].up and ( not buff[classtable.DivineHammerBuff].up or cooldown[classtable.DivineHammer].remains >110 and HolyPower >= 4 )) and cooldown[classtable.TemplarsVerdict].ready then
        if not setSpell then setSpell = classtable.TemplarsVerdict end
    end
    finished = true
end
function Retribution:generators()
    if (MaxDps:CheckSpellUsable(classtable.HammerofLight, 'HammerofLight')) and (buff[classtable.HammerofLightFreeBuff].up) and cooldown[classtable.HammerofLight].ready then
        if not setSpell then setSpell = classtable.HammerofLight end
    end
    finished = false
    if (HolyPower == 5 or HolyPower == 4 and buff[classtable.DivineResonanceBuff].up) then
        Retribution:finishers()
    end
    if (MaxDps:CheckSpellUsable(classtable.TemplarSlash, 'TemplarSlash') and talents[classtable.TemplarStrikes]) and (buff[classtable.TemplarStrikesBuff].remains <gcd * 2) and cooldown[classtable.TemplarSlash].ready then
        if not setSpell then setSpell = classtable.TemplarSlash end
    end
    if (MaxDps:CheckSpellUsable(classtable.BladeofJustice, 'BladeofJustice')) and (not debuff[classtable.ExpurgationDeBuff].up and talents[classtable.HolyFlames]) and cooldown[classtable.BladeofJustice].ready then
        if not setSpell then setSpell = classtable.BladeofJustice end
    end
    if (MaxDps:CheckSpellUsable(classtable.WakeofAshes, 'WakeofAshes')) and (( not talents[classtable.LightsGuidance] or HolyPower >= 2 and talents[classtable.LightsGuidance] ) and ( cooldown[classtable.AvengingWrath].remains >6 or cooldown[classtable.Crusade].remains >6 or talents[classtable.RadiantGlory] ) and ( not talents[classtable.ExecutionSentence] or cooldown[classtable.ExecutionSentence].remains >4 or ttd <8 ) and ( (targets <2) or math.huge >10 or (targets >1) )) and cooldown[classtable.WakeofAshes].ready then
        if not setSpell then setSpell = classtable.WakeofAshes end
    end
    if (MaxDps:CheckSpellUsable(classtable.DivineToll, 'DivineToll')) and (HolyPower <= 2 and ( (targets <2) or math.huge >10 or (targets >1) ) and ( cooldown[classtable.AvengingWrath].remains >15 or cooldown[classtable.Crusade].remains >15 or talents[classtable.RadiantGlory] or ttd <8 )) and cooldown[classtable.DivineToll].ready then
        MaxDps:GlowCooldown(classtable.DivineToll, cooldown[classtable.DivineToll].ready)
    end
    if (HolyPower >= 3 and buff[classtable.CrusadeBuff].up and buff[classtable.CrusadeBuff].count <10 and not finished) then
        Retribution:finishers()
    end
    if (MaxDps:CheckSpellUsable(classtable.TemplarSlash, 'TemplarSlash') and talents[classtable.TemplarStrikes]) and (buff[classtable.TemplarStrikesBuff].remains <gcd and targets >= 2) and cooldown[classtable.TemplarSlash].ready then
        if not setSpell then setSpell = classtable.TemplarSlash end
    end
    if (MaxDps:CheckSpellUsable(classtable.BladeofJustice, 'BladeofJustice')) and (( HolyPower <= 3 or not talents[classtable.HolyBlade] ) and ( targets >= 2 and talents[classtable.BladeofVengeance] )) and cooldown[classtable.BladeofJustice].ready then
        if not setSpell then setSpell = classtable.BladeofJustice end
    end
    if (MaxDps:CheckSpellUsable(classtable.HammerofWrath, 'HammerofWrath')) and (( targets <2 or not talents[classtable.BlessedChampion] ) and ( HolyPower <= 3 or targetHP >20 or not talents[classtable.VanguardsMomentum] ) and ( targetHP <35 and talents[classtable.VengefulWrath] or buff[classtable.BlessingofAnsheBuff].up )) and cooldown[classtable.HammerofWrath].ready then
        if not setSpell then setSpell = classtable.HammerofWrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.TemplarStrike, 'TemplarStrike') and talents[classtable.TemplarStrikes]) and cooldown[classtable.TemplarStrike].ready then
        if not setSpell then setSpell = classtable.TemplarStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Judgment, 'Judgment')) and (HolyPower <= 3 or not talents[classtable.BoundlessJudgment]) and cooldown[classtable.Judgment].ready then
        if not setSpell then setSpell = classtable.Judgment end
    end
    if (MaxDps:CheckSpellUsable(classtable.BladeofJustice, 'BladeofJustice')) and (HolyPower <= 3 or not talents[classtable.HolyBlade]) and cooldown[classtable.BladeofJustice].ready then
        if not setSpell then setSpell = classtable.BladeofJustice end
    end
    if (MaxDps:CheckSpellUsable(classtable.HammerofWrath, 'HammerofWrath')) and (( targets <2 or not talents[classtable.BlessedChampion] ) and ( HolyPower <= 3 or targetHP >20 or not talents[classtable.VanguardsMomentum] )) and cooldown[classtable.HammerofWrath].ready then
        if not setSpell then setSpell = classtable.HammerofWrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.TemplarSlash, 'TemplarSlash')) and cooldown[classtable.TemplarSlash].ready then
        if not setSpell then setSpell = classtable.TemplarSlash end
    end
    if (( targetHP <= 20 or buff[classtable.AvengingWrathBuff].up or buff[classtable.CrusadeBuff].up or buff[classtable.EmpyreanPowerBuff].up ) and not finished) then
        Retribution:finishers()
    end
    if (MaxDps:CheckSpellUsable(classtable.CrusaderStrike, 'CrusaderStrike') and not talents[classtable.CrusadingStrikes]) and (cooldown[classtable.CrusaderStrike].charges >= 1.75 and ( HolyPower <= 2 or HolyPower <= 3 and cooldown[classtable.BladeofJustice].remains >gcd * 2 or HolyPower == 4 and cooldown[classtable.BladeofJustice].remains >gcd * 2 and cooldown[classtable.Judgment].remains >gcd * 2 )) and cooldown[classtable.CrusaderStrike].ready then
        if not setSpell then setSpell = classtable.CrusaderStrike end
    end
    if (not finished) then
        Retribution:finishers()
    end
    if (MaxDps:CheckSpellUsable(classtable.HammerofWrath, 'HammerofWrath')) and (HolyPower <= 3 or targetHP >20 or not talents[classtable.VanguardsMomentum]) and cooldown[classtable.HammerofWrath].ready then
        if not setSpell then setSpell = classtable.HammerofWrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrusaderStrike, 'CrusaderStrike') and not talents[classtable.CrusadingStrikes]) and cooldown[classtable.CrusaderStrike].ready then
        if not setSpell then setSpell = classtable.CrusaderStrike end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Rebuke, false)
    MaxDps:GlowCooldown(classtable.AvengingWrath, false)
    MaxDps:GlowCooldown(classtable.DivineToll, false)
    MaxDps:GlowCooldown(classtable.ShieldofVengeance, false)
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
    classtable.TemplarSlash = 406647
    classtable.TemplarStrike = 407480
    classtable.FinalVerdictBuff = 383329
    classtable.HammerofLight = 427453
    classtable.HolyFlames = 406545
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.ExecutionSentenceDeBuff = 343527
    classtable.CrusadeBuff = 231895
    classtable.AvengingWrathBuff = 31884
    classtable.EmpyreanPowerBuff = 326733
    classtable.EmpyreanLegacyBuff = 387178
    classtable.DivineArbiterBuff = 406975
    classtable.HammerofLightReadyBuff = 427453
    classtable.DivineHammerBuff = 198034
    classtable.HammerofLightFreeBuff = 408458
    classtable.DivineResonanceBuff = 384029
    classtable.TemplarStrikesBuff = 406648
    classtable.ExpurgationDeBuff = 383346
    classtable.BlessingofAnsheBuff = 445206

    local function debugg()
        talents[classtable.RadiantGlory] = 1
        talents[classtable.ExecutionSentence] = 1
        talents[classtable.DivineAuxiliary] = 1
        talents[classtable.ExecutionersWill] = 1
        talents[classtable.Crusade] = 1
        talents[classtable.HolyFlames] = 1
        talents[classtable.LightsGuidance] = 1
        talents[classtable.HolyBlade] = 1
        talents[classtable.BladeofVengeance] = 1
        talents[classtable.BlessedChampion] = 1
        talents[classtable.VanguardsMomentum] = 1
        talents[classtable.VengefulWrath] = 1
        talents[classtable.BoundlessJudgment] = 1
    end


    if MaxDps.db.global.debugMode then
        debugg()
    end

    setSpell = nil
    ClearCDs()

    Retribution:precombat()

    Retribution:callaction()
    if setSpell then return setSpell end
end
