local _, addonTable = ...
local Paladin = addonTable.Paladin
local MaxDps = _G.MaxDps
if not MaxDps then return end

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

local Holy = {}

function Holy:precombat()
    if (MaxDps:CheckSpellUsable(classtable.DevotionAura, 'DevotionAura')) and (not buff[classtable.PaladinAuraBuff].up) and cooldown[classtable.DevotionAura].ready then
        MaxDps:GlowCooldown(classtable.DevotionAura, cooldown[classtable.DevotionAura].ready)
    end
    --if (MaxDps:CheckSpellUsable(classtable.BeaconofLight, 'BeaconofLight')) and (debuff[classtable.BeaconofLightDebuff].count  == 0) and cooldown[classtable.BeaconofLight].ready then
    --    return classtable.BeaconofLight
    --end
    --if (MaxDps:CheckSpellUsable(classtable.BeaconofFaith, 'BeaconofFaith')) and ( debuff[classtable.BeaconofFaithDebuff].count  == 0) and cooldown[classtable.BeaconofFaith].ready then
    --    return classtable.BeaconofFaith
    --end
end
function Holy:spenders()
    --if (MaxDps:CheckSpellUsable(classtable.WordofGlory, 'WordofGlory')) and ( ( curentHP <70 or not MaxDps:CheckEquipped('Shield') ) and buff[classtable.ShiningRighteousnessReadyBuff].up or buff[classtable.EmpyreanLegacyBuff].up) and cooldown[classtable.WordofGlory].ready then
    --    return classtable.WordofGlory
    --end
    --if (MaxDps:CheckSpellUsable(classtable.LightofDawn, 'LightofDawn')) and ( buff[classtable.ShiningRighteousnessReadyBuff].up) and cooldown[classtable.LightofDawn].ready then
    --    return classtable.LightofDawn
    --end
    if (MaxDps:CheckSpellUsable(classtable.ShieldoftheRighteous, 'ShieldoftheRighteous')) and cooldown[classtable.ShieldoftheRighteous].ready then
        return classtable.ShieldoftheRighteous
    end
end

function Holy:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Rebuke, 'Rebuke')) and cooldown[classtable.Rebuke].ready then
        MaxDps:GlowCooldown(classtable.Rebuke, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (MaxDps:CheckSpellUsable(classtable.AvengingWrath, 'AvengingWrath')) and cooldown[classtable.AvengingWrath].ready then
        MaxDps:GlowCooldown(classtable.AvengingWrath, cooldown[classtable.AvengingWrath].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.AvengingCrusader, 'AvengingCrusader')) and cooldown[classtable.AvengingCrusader].ready then
        MaxDps:GlowCooldown(classtable.AvengingCrusader, cooldown[classtable.AvengingCrusader].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.BlessingofSummer, 'BlessingofSummer')) and cooldown[classtable.BlessingofSummer].ready then
        return classtable.BlessingofSummer
    end
    if (MaxDps:CheckSpellUsable(classtable.BlessingofAutumn, 'BlessingofAutumn')) and cooldown[classtable.BlessingofAutumn].ready then
        return classtable.BlessingofAutumn
    end
    if (MaxDps:CheckSpellUsable(classtable.BlessingofWinter, 'BlessingofWinter')) and cooldown[classtable.BlessingofWinter].ready then
        return classtable.BlessingofWinter
    end
    if (MaxDps:CheckSpellUsable(classtable.BlessingofSpring, 'BlessingofSpring')) and cooldown[classtable.BlessingofSpring].ready then
        return classtable.BlessingofSpring
    end
    if (not talents[classtable.AvengingCrusader] or cooldown[classtable.AvengingCrusader].remains >gcd or HolyPowerDeficit == 0) then
        local spendersCheck = Holy:spenders()
        if spendersCheck then
            return Holy:spenders()
        end
    end
    if (MaxDps:CheckSpellUsable(classtable.DivineToll, 'DivineToll')) and cooldown[classtable.DivineToll].ready then
        MaxDps:GlowCooldown(classtable.DivineToll, cooldown[classtable.DivineToll].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.HolyPrism, 'HolyPrism')) and cooldown[classtable.HolyPrism].ready then
        return classtable.HolyPrism
    end
    --if (MaxDps:CheckSpellUsable(classtable.BeaconofVirtue, 'BeaconofVirtue')) and cooldown[classtable.BeaconofVirtue].ready then
    --    return classtable.BeaconofVirtue
    --end
    if (MaxDps:CheckSpellUsable(classtable.Consecration, 'Consecration')) and (not buff[classtable.Consecration].up and C_Spell.IsSpellInRange(classtable.CrusaderStrike, 'target')) and cooldown[classtable.Consecration].ready then
        return classtable.Consecration
    end
    if (MaxDps:CheckSpellUsable(classtable.HammerofWrath, 'HammerofWrath')) and cooldown[classtable.HammerofWrath].ready then
        return classtable.HammerofWrath
    end
    if (MaxDps:CheckSpellUsable(classtable.Judgment, 'Judgment')) and cooldown[classtable.Judgment].ready then
        return classtable.Judgment
    end
    if (MaxDps:CheckSpellUsable(classtable.HolyShock, 'HolyShock')) and cooldown[classtable.HolyShock].ready then
        return classtable.HolyShock
    end
    if (MaxDps:CheckSpellUsable(classtable.CrusaderStrike, 'CrusaderStrike')) and (cooldown[classtable.HolyShock].remains >gcd) and cooldown[classtable.CrusaderStrike].ready then
        return classtable.CrusaderStrike
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
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP / targetmaxHP) * 100
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
    classtable.HolyArmaments = classtable.HolyBulwark
    classtable.BlessingofSummer = 388007
    classtable.BlessingofAutumn = 388010
    classtable.BlessingofWinter = 388011
    classtable.BlessingofSpring = 388013
    for spellId in pairs(MaxDps.Flags) do
        self.Flags[spellId] = false
        self:ClearGlowIndependent(spellId, spellId)
    end
    classtable.PaladinAuraBuff = classtable.DevotionAura
    classtable.BeaconofLightDeBuff = 53563
    classtable.BeaconofFaithDeBuff = 156910
    classtable.ShiningRighteousnessReadyBuff = 0
    classtable.EmpyreanLegacyBuff = 0

    local precombatCheck = Holy:precombat()
    if precombatCheck then
        return Holy:precombat()
    end

    local callactionCheck = Holy:callaction()
    if callactionCheck then
        return Holy:callaction()
    end
end
