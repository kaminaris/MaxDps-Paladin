local _, addonTable = ...
local Paladin = addonTable.Paladin
local MaxDps = _G.MaxDps
if not MaxDps then return end
local LibStub = LibStub
local setSpell

local ceil = ceil
local floor = floor
local fmod = fmod
local format = format
local max = max
local min = min
local pairs = pairs
local select = select
local strsplit = strsplit
local GetTime = GetTime

local UnitAffectingCombat = UnitAffectingCombat
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitName = UnitName
local UnitSpellHaste = UnitSpellHaste
local UnitThreatSituation = UnitThreatSituation
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
local GetSpellCastCount = C_Spell.GetSpellCastCount
local GetUnitSpeed = GetUnitSpeed
local GetCritChance = GetCritChance
local GetInventoryItemLink = GetInventoryItemLink
local GetItemInfo = C_Item.GetItemInfo
local GetItemSpell = C_Item.GetItemSpell
local GetNamePlates = C_NamePlate.GetNamePlates and C_NamePlate.GetNamePlates or GetNamePlates
local GetPowerRegenForPowerType = GetPowerRegenForPowerType
local GetSpellName = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName or GetSpellInfo
local GetTotemInfo = GetTotemInfo
local IsStealthed = IsStealthed
local IsCurrentSpell = C_Spell and C_Spell.IsCurrentSpell
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo

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

local Mana
local ManaMax
local ManaDeficit
local ManaPerc
local ManaRegen
local ManaRegenCombined
local ManaTimeToMax
local HolyPower
local HolyPowerMax
local HolyPowerDeficit
local HolyPowerPerc
local HolyPowerRegen
local HolyPowerRegenCombined
local HolyPowerTimeToMax
local next_armament
local wog_health
local loh_health
local judgment_holy_power
local ad_damage
local ds_damage
local goak_damage

local Protection = {}

local trinket_sync_slot = false


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
    if (MaxDps:CheckSpellUsable(classtable.DevotionAura, 'DevotionAura')) and cooldown[classtable.DevotionAura].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.DevotionAura end
    end
    if (MaxDps:CheckSpellUsable(classtable.Consecration, 'Consecration')) and cooldown[classtable.Consecration].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Consecration end
    end
    if MaxDps:HasOnUseEffect('13') and true and (not true or MaxDps:CheckTrinketCooldownDuration('13') >= MaxDps:CheckTrinketCooldownDuration('14')) or not MaxDps:HasOnUseEffect('14') then
        trinket_sync_slot = 1
    end
    if MaxDps:HasOnUseEffect('14') and true and (not true or MaxDps:CheckTrinketCooldownDuration('14') >MaxDps:CheckTrinketCooldownDuration('13')) or not MaxDps:HasOnUseEffect('13') then
        trinket_sync_slot = 2
    end
end
function Protection:cooldowns()
    if (MaxDps:CheckSpellUsable(classtable.AvengingWrath, 'AvengingWrath')) and cooldown[classtable.AvengingWrath].ready then
        MaxDps:GlowCooldown(classtable.AvengingWrath, cooldown[classtable.AvengingWrath].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.MomentofGlory, 'MomentofGlory')) and ((buff[classtable.AvengingWrathBuff].remains <15 or (timeInCombat >10))) and cooldown[classtable.MomentofGlory].ready then
        MaxDps:GlowCooldown(classtable.MomentofGlory, cooldown[classtable.MomentofGlory].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.DivineToll, 'DivineToll')) and (targets >= 3) and cooldown[classtable.DivineToll].ready then
        MaxDps:GlowCooldown(classtable.DivineToll, cooldown[classtable.DivineToll].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.BastionofLight, 'BastionofLight')) and (buff[classtable.AvengingWrathBuff].up or cooldown[classtable.AvengingWrath].remains <= 30) and cooldown[classtable.BastionofLight].ready then
        MaxDps:GlowCooldown(classtable.BastionofLight, cooldown[classtable.BastionofLight].ready)
    end
end
function Protection:mitigation()
    if (MaxDps:CheckSpellUsable(classtable.ShieldoftheRighteous, 'ShieldoftheRighteous')) and ((UnitThreatSituation('player') == 2 or UnitThreatSituation('player') == 3) and not buff[classtable.ShieldoftheRighteousBuff].up and (HolyPowerDeficit == 0 or buff[classtable.DivinePurposeBuff].up)) and cooldown[classtable.ShieldoftheRighteous].ready then
        if not setSpell then setSpell = classtable.ShieldoftheRighteous end
    end
    if (MaxDps:CheckSpellUsable(classtable.BlessingofSpellwarding, 'BlessingofSpellwarding')) and (false) and cooldown[classtable.BlessingofSpellwarding].ready then
        if not setSpell then setSpell = classtable.BlessingofSpellwarding end
    end
    if (MaxDps:CheckSpellUsable(classtable.WordofGlory, 'WordofGlory')) and (healthPerc <wog_health and (HolyPowerDeficit == 0 or buff[classtable.DivinePurposeBuff].up or buff[classtable.ShiningLightFreeBuff].up)) and cooldown[classtable.WordofGlory].ready then
        if not setSpell then setSpell = classtable.WordofGlory end
    end
    if (MaxDps:CheckSpellUsable(classtable.DivineShield, 'DivineShield')) and ((talents[classtable.FinalStand] and true or false) and (UnitThreatSituation('player') == 2 or UnitThreatSituation('player') == 3) and MaxDps.incoming_damage_5 >ds_damage and not (buff[classtable.ArdentDefenderBuff].up or buff[classtable.GuardianofAncientKingsBuff].up or buff[classtable.DivineShieldBuff].up or buff[classtable.PotionBuff].up)) and cooldown[classtable.DivineShield].ready then
        if not setSpell then setSpell = classtable.DivineShield end
    end
    if (MaxDps:CheckSpellUsable(classtable.GuardianofAncientKings, 'GuardianofAncientKings')) and ((UnitThreatSituation('player') == 2 or UnitThreatSituation('player') == 3) and MaxDps.incoming_damage_5 >goak_damage and not (buff[classtable.ArdentDefenderBuff].up or buff[classtable.GuardianofAncientKingsBuff].up or buff[classtable.DivineShieldBuff].up or buff[classtable.PotionBuff].up)) and cooldown[classtable.GuardianofAncientKings].ready then
        if not setSpell then setSpell = classtable.GuardianofAncientKings end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sentinel, 'Sentinel')) and (false and (UnitThreatSituation('player') == 2 or UnitThreatSituation('player') == 3) and MaxDps.incoming_damage_5 >goak_damage and not (buff[classtable.ArdentDefenderBuff].up or buff[classtable.GuardianofAncientKingsBuff].up or buff[classtable.DivineShieldBuff].up or buff[classtable.PotionBuff].up)) and cooldown[classtable.Sentinel].ready then
        if not setSpell then setSpell = classtable.Sentinel end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArdentDefender, 'ArdentDefender')) and ((UnitThreatSituation('player') == 2 or UnitThreatSituation('player') == 3) and MaxDps.incoming_damage_5 >ad_damage and not (buff[classtable.ArdentDefenderBuff].up or buff[classtable.GuardianofAncientKingsBuff].up or buff[classtable.DivineShieldBuff].up or buff[classtable.PotionBuff].up)) and cooldown[classtable.ArdentDefender].ready then
        if not setSpell then setSpell = classtable.ArdentDefender end
    end
    if (MaxDps:CheckSpellUsable(classtable.LayOnHands, 'LayOnHands')) and (healthPerc <loh_health) and cooldown[classtable.LayOnHands].ready then
        if not setSpell then setSpell = classtable.LayOnHands end
    end
end
function Protection:standard()
    if (MaxDps:CheckSpellUsable(classtable.Judgment, 'Judgment')) and (cooldown[classtable.Judgment].charges >= 2 or cooldown[classtable.Judgment].fullRecharge <= gcd) and cooldown[classtable.Judgment].ready then
        if not setSpell then setSpell = classtable.Judgment end
    end
    if (MaxDps:CheckSpellUsable(classtable.HammerofLight, 'HammerofLight')) and (hammer_of_light_free_remains() <2 or buff[classtable.ShaketheHeavensBuff].remains <1 or not buff[classtable.ShaketheHeavensBuff].up or cooldown[classtable.EyeofTyr].remains <1.5 or ttd <2) and cooldown[classtable.HammerofLight].ready then
        if not setSpell then setSpell = classtable.HammerofLight end
    end
    if (MaxDps:CheckSpellUsable(classtable.EyeofTyr, 'EyeofTyr')) and ((hpg_to_2dawn == 5 or not (talents[classtable.OfDuskandDawn] and true or false)) and (talents[classtable.LightsGuidance] and true or false)) and cooldown[classtable.EyeofTyr].ready then
        MaxDps:GlowCooldown(classtable.EyeofTyr, cooldown[classtable.EyeofTyr].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.EyeofTyr, 'EyeofTyr')) and ((hpg_to_2dawn == 1 or buff[classtable.BlessingofDawnBuff].count >0) and (talents[classtable.LightsGuidance] and true or false)) and cooldown[classtable.EyeofTyr].ready then
        MaxDps:GlowCooldown(classtable.EyeofTyr, cooldown[classtable.EyeofTyr].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ShieldoftheRighteous, 'ShieldoftheRighteous')) and ((not (talents[classtable.RighteousProtector] and true or false) or cooldown[classtable.RighteousProtectorIcd].remains == 0) and not buff[classtable.HammerofLightReadyBuff].up) and cooldown[classtable.ShieldoftheRighteous].ready then
        if not setSpell then setSpell = classtable.ShieldoftheRighteous end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShieldoftheRighteous, 'ShieldoftheRighteous')) and (not buff[classtable.HammerofLightReadyBuff].up and (buff[classtable.LuckoftheDrawBuff].up and ((HolyPower + judgment_holy_power>=5) or (not (talents[classtable.RighteousProtector] and true or false) or cooldown[classtable.RighteousProtectorIcd].remains == 0)))) and cooldown[classtable.ShieldoftheRighteous].ready then
        if not setSpell then setSpell = classtable.ShieldoftheRighteous end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShieldoftheRighteous, 'ShieldoftheRighteous')) and (not buff[classtable.HammerofLightReadyBuff].up and (MaxDps.tier and MaxDps.tier[33].count >= 4) and ((HolyPower + judgment_holy_power>5) or (HolyPower + judgment_holy_power>=5 and cooldown[classtable.RighteousProtectorIcd].remains == 0))) and cooldown[classtable.ShieldoftheRighteous].ready then
        if not setSpell then setSpell = classtable.ShieldoftheRighteous end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShieldoftheRighteous, 'ShieldoftheRighteous')) and (not (MaxDps.tier and MaxDps.tier[33].count >= 4) and (not (talents[classtable.RighteousProtector] and true or false) or cooldown[classtable.RighteousProtectorIcd].remains == 0) and not buff[classtable.HammerofLightReadyBuff].up) and cooldown[classtable.ShieldoftheRighteous].ready then
        if not setSpell then setSpell = classtable.ShieldoftheRighteous end
    end
    if (MaxDps:CheckSpellUsable(classtable.Judgment, 'Judgment')) and (targets >3 and buff[classtable.BulwarkofRighteousFuryBuff].count >= 3 and HolyPower <3) and cooldown[classtable.Judgment].ready then
        if not setSpell then setSpell = classtable.Judgment end
    end
    if (MaxDps:CheckSpellUsable(classtable.AvengersShield, 'AvengersShield')) and (not buff[classtable.BulwarkofRighteousFuryBuff].up and (talents[classtable.BulwarkofRighteousFury] and true or false) and targets >= 3) and cooldown[classtable.AvengersShield].ready then
        if not setSpell then setSpell = classtable.AvengersShield end
    end
    if (MaxDps:CheckSpellUsable(classtable.HammeroftheRighteous, 'HammeroftheRighteous')) and (buff[classtable.BlessedAssuranceBuff].up and targets <3 and not buff[classtable.AvengingWrathBuff].up) and cooldown[classtable.HammeroftheRighteous].ready then
        if not setSpell then setSpell = classtable.HammeroftheRighteous end
    end
    if (MaxDps:CheckSpellUsable(classtable.BlessedHammer, 'BlessedHammer')) and (buff[classtable.BlessedAssuranceBuff].up and targets <3 and not buff[classtable.AvengingWrathBuff].up) and cooldown[classtable.BlessedHammer].ready then
        if not setSpell then setSpell = classtable.BlessedHammer end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrusaderStrike, 'CrusaderStrike')) and (buff[classtable.BlessedAssuranceBuff].up and targets <2 and not buff[classtable.AvengingWrathBuff].up) and cooldown[classtable.CrusaderStrike].ready then
        if not setSpell then setSpell = classtable.CrusaderStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Consecration, 'Consecration')) and (buff[classtable.DivineGuidanceBuff].count == 5) and cooldown[classtable.Consecration].ready then
        if not setSpell then setSpell = classtable.Consecration end
    end
    if (MaxDps:CheckSpellUsable(classtable.HolyArmaments, 'HolyArmaments')) and (next_armament == classtable.SacredWeapon and (not buff[classtable.SacredWeaponBuff].up or (buff[classtable.SacredWeaponBuff].remains <6 and not buff[classtable.AvengingWrathBuff].up and cooldown[classtable.AvengingWrath].remains <= 30))) and cooldown[classtable.HolyArmaments].ready then
        if not setSpell then setSpell = classtable.HolyArmaments end
    end
    if (MaxDps:CheckSpellUsable(classtable.HammerofWrath, 'HammerofWrath')) and cooldown[classtable.HammerofWrath].ready then
        if not setSpell then setSpell = classtable.HammerofWrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.DivineToll, 'DivineToll')) and cooldown[classtable.DivineToll].ready then
        MaxDps:GlowCooldown(classtable.DivineToll, cooldown[classtable.DivineToll].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.AvengersShield, 'AvengersShield')) and ((talents[classtable.RefiningFire] and true or false)) and cooldown[classtable.AvengersShield].ready then
        if not setSpell then setSpell = classtable.AvengersShield end
    end
    if (MaxDps:CheckSpellUsable(classtable.Judgment, 'Judgment')) and (buff[classtable.AvengingWrathBuff].up and (talents[classtable.HammerandAnvil] and true or false)) and cooldown[classtable.Judgment].ready then
        if not setSpell then setSpell = classtable.Judgment end
    end
    if (MaxDps:CheckSpellUsable(classtable.HolyArmaments, 'HolyArmaments')) and (next_armament == classtable.HolyBulwark and cooldown[classtable.HolyArmaments].charges == 2) and cooldown[classtable.HolyArmaments].ready then
        if not setSpell then setSpell = classtable.HolyArmaments end
    end
    if (MaxDps:CheckSpellUsable(classtable.Judgment, 'Judgment')) and cooldown[classtable.Judgment].ready then
        if not setSpell then setSpell = classtable.Judgment end
    end
    if (MaxDps:CheckSpellUsable(classtable.AvengersShield, 'AvengersShield')) and (not buff[classtable.ShaketheHeavensBuff].up and (talents[classtable.ShaketheHeavens] and true or false)) and cooldown[classtable.AvengersShield].ready then
        if not setSpell then setSpell = classtable.AvengersShield end
    end
    if (MaxDps:CheckSpellUsable(classtable.HammeroftheRighteous, 'HammeroftheRighteous')) and ((buff[classtable.BlessedAssuranceBuff].up and targets <3) or buff[classtable.ShaketheHeavensBuff].up) and cooldown[classtable.HammeroftheRighteous].ready then
        if not setSpell then setSpell = classtable.HammeroftheRighteous end
    end
    if (MaxDps:CheckSpellUsable(classtable.BlessedHammer, 'BlessedHammer')) and ((buff[classtable.BlessedAssuranceBuff].up and targets <3) or buff[classtable.ShaketheHeavensBuff].up) and cooldown[classtable.BlessedHammer].ready then
        if not setSpell then setSpell = classtable.BlessedHammer end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrusaderStrike, 'CrusaderStrike')) and ((buff[classtable.BlessedAssuranceBuff].up and targets <2) or buff[classtable.ShaketheHeavensBuff].up) and cooldown[classtable.CrusaderStrike].ready then
        if not setSpell then setSpell = classtable.CrusaderStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.AvengersShield, 'AvengersShield')) and (not (talents[classtable.LightsGuidance] and true or false)) and cooldown[classtable.AvengersShield].ready then
        if not setSpell then setSpell = classtable.AvengersShield end
    end
    if (MaxDps:CheckSpellUsable(classtable.Consecration, 'Consecration')) and (not buff[classtable.Consecration].up) and cooldown[classtable.Consecration].ready then
        if not setSpell then setSpell = classtable.Consecration end
    end
    if (MaxDps:CheckSpellUsable(classtable.EyeofTyr, 'EyeofTyr')) and (((talents[classtable.InmostLight] and true or false) and math.huge >= 45 or targets >= 3) and not (talents[classtable.LightsDeliverance] and true or false)) and cooldown[classtable.EyeofTyr].ready then
        MaxDps:GlowCooldown(classtable.EyeofTyr, cooldown[classtable.EyeofTyr].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.HolyArmaments, 'HolyArmaments')) and (next_armament == classtable.HolyBulwark) and cooldown[classtable.HolyArmaments].ready then
        if not setSpell then setSpell = classtable.HolyArmaments end
    end
    if (MaxDps:CheckSpellUsable(classtable.BlessedHammer, 'BlessedHammer')) and cooldown[classtable.BlessedHammer].ready then
        if not setSpell then setSpell = classtable.BlessedHammer end
    end
    if (MaxDps:CheckSpellUsable(classtable.HammeroftheRighteous, 'HammeroftheRighteous')) and cooldown[classtable.HammeroftheRighteous].ready then
        if not setSpell then setSpell = classtable.HammeroftheRighteous end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrusaderStrike, 'CrusaderStrike')) and cooldown[classtable.CrusaderStrike].ready then
        if not setSpell then setSpell = classtable.CrusaderStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.WordofGlory, 'WordofGlory')) and (buff[classtable.ShiningLightFreeBuff].up and ((talents[classtable.BlessedAssurance] and true or false) or ((talents[classtable.LightsGuidance] and true or false) and cooldown[classtable.HammerfallIcd].remains == 0))) and cooldown[classtable.WordofGlory].ready then
        if not setSpell then setSpell = classtable.WordofGlory end
    end
    if (MaxDps:CheckSpellUsable(classtable.AvengersShield, 'AvengersShield')) and cooldown[classtable.AvengersShield].ready then
        if not setSpell then setSpell = classtable.AvengersShield end
    end
    if (MaxDps:CheckSpellUsable(classtable.EyeofTyr, 'EyeofTyr')) and (not (talents[classtable.LightsDeliverance] and true or false)) and cooldown[classtable.EyeofTyr].ready then
        MaxDps:GlowCooldown(classtable.EyeofTyr, cooldown[classtable.EyeofTyr].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.WordofGlory, 'WordofGlory')) and (buff[classtable.ShiningLightFreeBuff].up) and cooldown[classtable.WordofGlory].ready then
        if not setSpell then setSpell = classtable.WordofGlory end
    end
    if (MaxDps:CheckSpellUsable(classtable.Consecration, 'Consecration')) and cooldown[classtable.Consecration].ready then
        if not setSpell then setSpell = classtable.Consecration end
    end
end
function Protection:trinkets()
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Rebuke, false)
    MaxDps:GlowCooldown(classtable.AvengingWrath, false)
    MaxDps:GlowCooldown(classtable.MomentofGlory, false)
    MaxDps:GlowCooldown(classtable.DivineToll, false)
    MaxDps:GlowCooldown(classtable.BastionofLight, false)
    MaxDps:GlowCooldown(classtable.EyeofTyr, false)
    MaxDps:GlowCooldown(classtable.tome_of_lights_devotion, false)
    MaxDps:GlowCooldown(classtable.trinket1, false)
    MaxDps:GlowCooldown(classtable.trinket2, false)
end

function Protection:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Rebuke, 'Rebuke')) and cooldown[classtable.Rebuke].ready then
        MaxDps:GlowCooldown(classtable.Rebuke, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    Protection:mitigation()
    Protection:cooldowns()
    Protection:trinkets()
    Protection:standard()
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
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP >0 and targetmaxHP >0 and (targetHP / targetmaxHP) * 100) or 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    local trinket1ID = GetInventoryItemID('player', 13)
    local trinket2ID = GetInventoryItemID('player', 14)
    local MHID = GetInventoryItemID('player', 16)
    classtable.trinket1 = (trinket1ID and select(2,GetItemSpell(trinket1ID)) ) or 0
    classtable.trinket2 = (trinket2ID and select(2,GetItemSpell(trinket2ID)) ) or 0
    classtable.main_hand = (MHID and select(2,GetItemSpell(MHID)) ) or 0
    Mana = UnitPower('player', ManaPT)
    ManaMax = UnitPowerMax('player', ManaPT)
    ManaDeficit = ManaMax - Mana
    ManaPerc = (Mana / ManaMax) * 100
    ManaRegen = GetPowerRegenForPowerType(ManaPT)
    ManaTimeToMax = ManaDeficit / ManaRegen
    HolyPower = UnitPower('player', HolyPowerPT)
    HolyPowerMax = UnitPowerMax('player', HolyPowerPT)
    HolyPowerDeficit = HolyPowerMax - HolyPower
    HolyPowerPerc = (HolyPower / HolyPowerMax) * 100
    HolyPowerRegen = GetPowerRegenForPowerType(HolyPowerPT)
    HolyPowerTimeToMax = HolyPowerDeficit / HolyPowerRegen
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
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
    wog_health = 40
    loh_health = 30
    judgment_holy_power = 1
    ad_damage = 40 * maxHP * 0.01
    ds_damage = 60 * maxHP * 0.01
    goak_damage = 40 * maxHP * 0.01
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.AvengingWrathBuff = 31884
    classtable.ShieldoftheRighteousBuff = 132403
    classtable.DivinePurposeBuff = 223819
    classtable.ShiningLightFreeBuff = 327510
    classtable.ArdentDefenderBuff = 31850
    classtable.GuardianofAncientKingsBuff = 86659
    classtable.DivineShieldBuff = 642
    classtable.PotionBuff = 0
    classtable.HammerofLightFreeBuff = 0
    classtable.ShaketheHeavensBuff = 431536
    classtable.BlessingofDawnBuff = 385127
    classtable.HammerofLightReadyBuff = 427453
    classtable.LuckoftheDrawBuff = 0
    classtable.BulwarkofRighteousFuryBuff = 386652
    classtable.BlessedAssuranceBuff = 433019
    classtable.DivineGuidanceBuff = 460822
    classtable.SacredWeaponBuff = 432502
    classtable.InnerResilienceBuff = 0
    classtable.LayOnHands = 633
    classtable.HammerofLight = 427453
    classtable.HolyArmaments = 432459

    local function debugg()
        talents[classtable.FinalStand] = 1
        talents[classtable.OfDuskandDawn] = 1
        talents[classtable.LightsGuidance] = 1
        talents[classtable.RighteousProtector] = 1
        talents[classtable.BulwarkofRighteousFury] = 1
        talents[classtable.RefiningFire] = 1
        talents[classtable.HammerandAnvil] = 1
        talents[classtable.ShaketheHeavens] = 1
        talents[classtable.InmostLight] = 1
        talents[classtable.LightsDeliverance] = 1
        talents[classtable.BlessedAssurance] = 1
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
