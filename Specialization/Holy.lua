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

local Holy = {}

function Holy:precombat()
    if (MaxDps:CheckSpellUsable(classtable.DevotionAura, 'DevotionAura')) and (not buff[classtable.PaladinAuraBuff].up) and cooldown[classtable.DevotionAura].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.DevotionAura end
    end
    --if (MaxDps:CheckSpellUsable(classtable.BeaconofLight, 'BeaconofLight')) and (MaxDps:DebuffCounter(classtable.BeaconofLightDeBuff) == 0) and cooldown[classtable.BeaconofLight].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.BeaconofLight end
    --end
    --if (MaxDps:CheckSpellUsable(classtable.BeaconofFaith, 'BeaconofFaith')) and (MaxDps:NumGroupFriends() >1 and MaxDps:DebuffCounter(classtable.BeaconofFaithDeBuff) == 0) and cooldown[classtable.BeaconofFaith].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.BeaconofFaith end
    --end
end
function Holy:spenders()
    --if (MaxDps:CheckSpellUsable(classtable.WordofGlory, 'WordofGlory')) and (MaxDps:NumGroupFriends() <= 1 and (healthPerc <70 or not MaxDps:CheckEquipped('Shield')) and buff[classtable.ShiningRighteousnessReadyBuff].up or buff[classtable.EmpyreanLegacyBuff].up) and cooldown[classtable.WordofGlory].ready then
    --    if not setSpell then setSpell = classtable.WordofGlory end
    --end
    --if (MaxDps:CheckSpellUsable(classtable.LightofDawn, 'LightofDawn')) and (MaxDps:NumGroupFriends() >1 and buff[classtable.ShiningRighteousnessReadyBuff].up) and cooldown[classtable.LightofDawn].ready then
    --    if not setSpell then setSpell = classtable.LightofDawn end
    --end
    if (MaxDps:CheckSpellUsable(classtable.ShieldoftheRighteous, 'ShieldoftheRighteous')) and cooldown[classtable.ShieldoftheRighteous].ready then
        if not setSpell then setSpell = classtable.ShieldoftheRighteous end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Rebuke, false)
    MaxDps:GlowCooldown(classtable.AvengingWrath, false)
    MaxDps:GlowCooldown(classtable.AvengingCrusader, false)
    MaxDps:GlowCooldown(classtable.DivineToll, false)
end

function Holy:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Rebuke, 'Rebuke')) and cooldown[classtable.Rebuke].ready then
        MaxDps:GlowCooldown(classtable.Rebuke, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (MaxDps:CheckSpellUsable(classtable.AvengingWrath, 'AvengingWrath')) and cooldown[classtable.AvengingWrath].ready then
        MaxDps:GlowCooldown(classtable.AvengingWrath, cooldown[classtable.AvengingWrath].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.AvengingCrusader, 'AvengingCrusader') and talents[classtable.AvengingCrusader]) and cooldown[classtable.AvengingCrusader].ready then
        MaxDps:GlowCooldown(classtable.AvengingCrusader, cooldown[classtable.AvengingCrusader].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.HolyArmament, 'HolyArmament')) and cooldown[classtable.HolyArmament].ready then
        if not setSpell then setSpell = classtable.HolyArmament end
    end
    if (MaxDps:CheckSpellUsable(classtable.BlessingofSummer, 'BlessingofSummer')) and cooldown[classtable.BlessingofSummer].ready then
        if not setSpell then setSpell = classtable.BlessingofSummer end
    end
    if (MaxDps:CheckSpellUsable(classtable.BlessingofAutumn, 'BlessingofAutumn')) and cooldown[classtable.BlessingofAutumn].ready then
        if not setSpell then setSpell = classtable.BlessingofAutumn end
    end
    if (MaxDps:CheckSpellUsable(classtable.BlessingofWinter, 'BlessingofWinter')) and cooldown[classtable.BlessingofWinter].ready then
        if not setSpell then setSpell = classtable.BlessingofWinter end
    end
    if (MaxDps:CheckSpellUsable(classtable.BlessingofSpring, 'BlessingofSpring')) and cooldown[classtable.BlessingofSpring].ready then
        if not setSpell then setSpell = classtable.BlessingofSpring end
    end
    if (not talents[classtable.AvengingCrusader] or cooldown[classtable.AvengingCrusader].remains >gcd or HolyPowerDeficit == 0) then
        Holy:spenders()
    end
    if (MaxDps:CheckSpellUsable(classtable.DivineToll, 'DivineToll')) and cooldown[classtable.DivineToll].ready then
        MaxDps:GlowCooldown(classtable.DivineToll, cooldown[classtable.DivineToll].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.HolyPrism, 'HolyPrism')) and cooldown[classtable.HolyPrism].ready then
        if not setSpell then setSpell = classtable.HolyPrism end
    end
    if (MaxDps:CheckSpellUsable(classtable.BeaconofVirtue, 'BeaconofVirtue')) and (MaxDps:NumGroupFriends() >1) and cooldown[classtable.BeaconofVirtue].ready then
        if not setSpell then setSpell = classtable.BeaconofVirtue end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrusaderStrike, 'CrusaderStrike')) and (talents[classtable.AvengingCrusader] and cooldown[classtable.CrusaderStrike].fullRecharge <gcd) and cooldown[classtable.CrusaderStrike].ready then
        if not setSpell then setSpell = classtable.CrusaderStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Judgment, 'Judgment')) and (talents[classtable.AvengingCrusader] and cooldown[classtable.Judgment].fullRecharge <gcd) and cooldown[classtable.Judgment].ready then
        if not setSpell then setSpell = classtable.Judgment end
    end
    if (MaxDps:CheckSpellUsable(classtable.Consecration, 'Consecration')) and (not buff[classtable.Consecration].up and C_Spell.IsSpellInRange(classtable.CrusaderStrike, 'target')) and cooldown[classtable.Consecration].ready then
        if not setSpell then setSpell = classtable.Consecration end
    end
    if (MaxDps:CheckSpellUsable(classtable.HammerofWrath, 'HammerofWrath')) and cooldown[classtable.HammerofWrath].ready then
        if not setSpell then setSpell = classtable.HammerofWrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Judgment, 'Judgment')) and cooldown[classtable.Judgment].ready then
        if not setSpell then setSpell = classtable.Judgment end
    end
    if (MaxDps:CheckSpellUsable(classtable.HolyShock, 'HolyShock')) and cooldown[classtable.HolyShock].ready then
        if not setSpell then setSpell = classtable.HolyShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrusaderStrike, 'CrusaderStrike')) and (cooldown[classtable.HolyShock].remains >gcd) and cooldown[classtable.CrusaderStrike].ready then
        if not setSpell then setSpell = classtable.CrusaderStrike end
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
    classtable.HolyArmament = GetSpellInfo(432459) and GetSpellInfo(432459).name and GetSpellInfo(GetSpellInfo(432459).name) and GetSpellInfo(GetSpellInfo(432459).name).spellID or 432459
    classtable.HolyArmaments = classtable.HolyArmament
    classtable.BlessingofSummer = 388007
    classtable.BlessingofAutumn = 388010
    classtable.BlessingofWinter = 388011
    classtable.BlessingofSpring = 388013
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.PaladinAuraBuff = classtable.DevotionAura
    classtable.BloodlustBuff = 2825
    classtable.AvengingWrathBuff = 31884
    classtable.AvengingCrusaderBuff = 216331
    classtable.ShiningRighteousnessReadyBuff = 414445
    classtable.EmpyreanLegacyBuff = 387178
    classtable.BlessingofAutumn = 388010
    classtable.BlessingofWinter = 388011
    classtable.BlessingofSpring = 388013

    local function debugg()
        talents[classtable.AvengingCrusader] = 1
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Holy:precombat()

    Holy:callaction()
    if setSpell then return setSpell end
end
