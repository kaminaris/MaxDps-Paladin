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
local HolyPowerMax
local Mana
local ManaMax
local ManaDeficit
local HolyPowerDeficit
local ManaPerc

local Protection = {}

local function ClearCDs()
end

function Protection:AoE()
    if (MaxDps:CheckSpellUsable(classtable.SealofWisdom, 'SealofWisdom')) and MaxDps:FindBuffAuraData(classtable.SealofWisdom).refreshable and cooldown[classtable.SealofWisdom].ready then
        --if not setSpell then setSpell = classtable.SealofWisdom end
        MaxDps:GlowCooldown(classtable.SealofWisdom, 'SealofWisdom')
    end
    if (MaxDps:CheckSpellUsable(classtable.BlessingofSanctuary, 'Consecration')) and cooldown[classtable.Consecration].ready then
        if not setSpell then setSpell = classtable.Consecration end
        --MaxDps:GlowCooldown(classtable.Consecration, 'Consecration')
    end
    if (MaxDps:CheckSpellUsable(classtable.BlessingofSanctuary, 'BlessingofSanctuary')) and cooldown[classtable.BlessingofSanctuary].ready then
        if not setSpell then setSpell = classtable.BlessingofSanctuary end
        --MaxDps:GlowCooldown(classtable.BlessingofSanctuary, 'BlessingofSanctuary')
    end
    if (MaxDps:CheckSpellUsable(classtable.HolyShield, 'HolyShield')) and cooldown[classtable.HolyShield].ready then
        --if not setSpell then setSpell = classtable.HolyShield end
        MaxDps:GlowCooldown(classtable.HolyShield, 'HolyShield')
    end
    if (MaxDps:CheckSpellUsable(classtable.AvengersShield, 'AvengersShield')) and cooldown[classtable.AvengersShield].ready then
        --if not setSpell then setSpell = classtable.AvengersShield end
        MaxDps:GlowCooldown(classtable.AvengersShield, 'AvengersShield')
    end
    if (MaxDps:CheckSpellUsable(classtable.Judgement, 'Judgement')) and cooldown[classtable.Judgement].ready then
        if not setSpell then setSpell = classtable.Judgement end
        --MaxDps:GlowCooldown(classtable.Judgement, 'Judgement')
    end
end

function Protection:single()
    if (MaxDps:CheckSpellUsable(classtable.AvengingWrath, 'AvengingWrath')) and cooldown[classtable.AvengingWrath].ready then
        --if not setSpell then setSpell = classtable.AvengingWrath end
        MaxDps:GlowCooldown(classtable.AvengingWrath, 'AvengingWrath')
    end
    if (MaxDps:CheckSpellUsable(classtable.SealoftheCrusader, 'SealoftheCrusader')) and MaxDps:FindBuffAuraData(classtable.SealoftheCrusader).refreshable and cooldown[classtable.SealoftheCrusader].ready then
        --if not setSpell then setSpell = classtable.SealoftheCrusader end
        MaxDps:GlowCooldown(classtable.SealoftheCrusader, 'SealoftheCrusader')
    end
    if (MaxDps:CheckSpellUsable(classtable.SealofRighteousness, 'SealofRighteousness')) and MaxDps:FindBuffAuraData(classtable.SealofRighteousness).refreshable and cooldown[classtable.SealofRighteousness].ready then
        --if not setSpell then setSpell = classtable.SealofRighteousness end
        MaxDps:GlowCooldown(classtable.SealofRighteousness, 'SealofRighteousness')
    end
    if (MaxDps:CheckSpellUsable(classtable.Consecration, 'Consecration')) and cooldown[classtable.Consecration].ready then
        if not setSpell then setSpell = classtable.Consecration end
        --MaxDps:GlowCooldown(classtable.Consecration, 'Consecration')
    end
    if (MaxDps:CheckSpellUsable(classtable.Judgement, 'Judgement')) and cooldown[classtable.Judgement].ready then
        if not setSpell then setSpell = classtable.Judgement end
        --MaxDps:GlowCooldown(classtable.Judgement, 'Judgement')
    end
    if (MaxDps:CheckSpellUsable(classtable.HolyShield, 'HolyShield')) and cooldown[classtable.HolyShield].ready then
        --if not setSpell then setSpell = classtable.HolyShield end
        MaxDps:GlowCooldown(classtable.HolyShield, 'HolyShield')
    end
    if (MaxDps:CheckSpellUsable(classtable.AvengersShield, 'AvengersShield')) and cooldown[classtable.AvengersShield].ready then
        --if not setSpell then setSpell = classtable.AvengersShield end
        MaxDps:GlowCooldown(classtable.AvengersShield, 'AvengersShield')
    end
end

function Protection:callaction()
    if (targets >1) then
        Protection:AoE()
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

    classtable.AvengersShield = 31987
    classtable.HolyShield = 20925
    classtable.Judgement = 20271
    classtable.Consecration = 26573
    classtable.SealofRighteousness = 20154
    classtable.SealoftheCrusader = 21082
    classtable.SealofWisdom = 20165
    classtable.BlessingofSanctuary = 20911
    classtable.AvengingWrath = 31884
    classtable.HolyShield = 20925

    setSpell = nil
    ClearCDs()

    Protection:callaction()
    if setSpell then return setSpell end
end
