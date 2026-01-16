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

local Retribution = {}

local function ClearCDs()
end

function Retribution:AoE()
end

function Retribution:single()
    if (MaxDps:CheckSpellUsable(classtable.AvengingWrath, 'AvengingWrath')) and cooldown[classtable.AvengingWrath].ready then
        --if not setSpell then setSpell = classtable.AvengingWrath end
        MaxDps:GlowCooldown(classtable.AvengingWrath, 'AvengingWrath')
    end
    if (MaxDps:CheckSpellUsable(classtable.SealoftheCrusader, 'SealoftheCrusader')) and MaxDps:FindBuffAuraData(classtable.SealoftheCrusader).refreshable and cooldown[classtable.SealoftheCrusader].ready then
        --if not setSpell then setSpell = classtable.SealoftheCrusader end
        MaxDps:GlowCooldown(classtable.SealoftheCrusader, 'SealoftheCrusader')
    end
    if (MaxDps:CheckSpellUsable(classtable.SealofBlood, 'SealofBlood')) and MaxDps:FindBuffAuraData(classtable.SealofBlood).refreshable and cooldown[classtable.SealofBlood].ready then
        --if not setSpell then setSpell = classtable.SealofBlood end
        MaxDps:GlowCooldown(classtable.SealofBlood, 'SealofBlood')
    end
    if (MaxDps:CheckSpellUsable(classtable.CrusaderStrike, 'CrusaderStrike')) and cooldown[classtable.CrusaderStrike].ready then
        if not setSpell then setSpell = classtable.CrusaderStrike end
        --MaxDps:GlowCooldown(classtable.CrusaderStrike, 'CrusaderStrike')
    end
    if (MaxDps:CheckSpellUsable(classtable.HammerofWrath, 'HammerofWrath')) and targethealthPerc <= 20 and cooldown[classtable.HammerofWrath].ready then
        if not setSpell then setSpell = classtable.HammerofWrath end
        --MaxDps:GlowCooldown(classtable.HammerofWrath, 'HammerofWrath')
    end
    if (MaxDps:CheckSpellUsable(classtable.Judgement, 'Judgement')) and cooldown[classtable.Judgement].ready then
        if not setSpell then setSpell = classtable.Judgement end
        --MaxDps:GlowCooldown(classtable.Judgement, 'Judgement')
    end
    if (MaxDps:CheckSpellUsable(classtable.Consecration, 'Consecration')) and targets > 5 and cooldown[classtable.Consecration].ready then
        if not setSpell then setSpell = classtable.Consecration end
        --MaxDps:GlowCooldown(classtable.Consecration, 'Consecration')
    end
    --if (MaxDps:CheckSpellUsable(classtable.Exorcism, 'Exorcism')) and cooldown[classtable.Exorcism].ready then
    --    if not setSpell then setSpell = classtable.Exorcism end
    --    --MaxDps:GlowCooldown(classtable.Exorcism, 'Exorcism')
    --end
end

function Retribution:callaction()
    --if (targets >1) then
    --    Retribution:AoE()
    --end
    --if (targets <=1) then
    --    Retribution:single()
    --end
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

    classtable.AvengingWrath = 31884
    classtable.SealoftheCrusader = 21082
    classtable.SealofBlood = 31801
    classtable.CrusaderStrike = 35395
    classtable.HammerofWrath = 24275
    classtable.Judgement = 20271
    classtable.Consecration = 26573
    classtable.Exorcism = 879

    setSpell = nil
    ClearCDs()

    Retribution:callaction()
    if setSpell then return setSpell end
end
