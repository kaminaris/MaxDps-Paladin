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
local GetSpellCooldown = GetSpellCooldown
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
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local HolyPower
local Mana
local ManaMax
local ManaDeficit
local HolyPowerDeficit
local ManaPerc

local Retribution = {}



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
    if (MaxDps:CheckSpellUsable(classtable.SealofCommand, 'SealofCommand')) and (not MaxDps:FindBuffAuraData ( 20154 ) .up and (not MaxDps:FindBuffAuraData ( 20920 ) .up or MaxDps:FindBuffAuraData ( 20920 ) .remains < 2)) and cooldown[classtable.SealofCommand].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.SealofCommand end
    end
    if (MaxDps:CheckSpellUsable(classtable.SealofRighteousness, 'SealofRighteousness')) and (not MaxDps:FindBuffAuraData ( 20920 ) .up and MaxDps:FindBuffAuraData ( 20154 ) .remains < 2) and cooldown[classtable.SealofRighteousness].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.SealofRighteousness end
    end
end
function Retribution:priorityList()
    if (MaxDps:CheckSpellUsable(classtable.HammerofWrath, 'HammerofWrath')) and (targethealthPerc <= 20) and cooldown[classtable.HammerofWrath].ready then
        if not setSpell then setSpell = classtable.HammerofWrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.SealofCommand, 'SealofCommand')) and (not MaxDps:FindBuffAuraData ( 20154 ) .up and (not MaxDps:FindBuffAuraData ( 20920 ) .up or MaxDps:FindBuffAuraData ( 20920 ) .remains < 2)) and cooldown[classtable.SealofCommand].ready then
        if not setSpell then setSpell = classtable.SealofCommand end
    end
    if (MaxDps:CheckSpellUsable(classtable.SealofRighteousness, 'SealofRighteousness')) and (not MaxDps:FindBuffAuraData ( 20920 ) .up and MaxDps:FindBuffAuraData ( 20154 ) .remains < 2) and cooldown[classtable.SealofRighteousness].ready then
        if not setSpell then setSpell = classtable.SealofRighteousness end
    end
    if (MaxDps:CheckSpellUsable(classtable.Exorcism, 'Exorcism')) and (select(2,UnitCreatureType("target")) == 6) and cooldown[classtable.Exorcism].ready then
        if not setSpell then setSpell = classtable.Exorcism end
    end
    if (MaxDps:CheckSpellUsable(classtable.HolyWrath, 'HolyWrath')) and (select(2,UnitCreatureType("target")) == 6) and cooldown[classtable.HolyWrath].ready then
        if not setSpell then setSpell = classtable.HolyWrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Judgement, 'Judgement')) and cooldown[classtable.Judgement].ready then
        if not setSpell then setSpell = classtable.Judgement end
    end
    if (MaxDps:CheckSpellUsable(classtable.Consecration, 'Consecration')) and (MaxDps:FindBuffAuraData ( 20049 ) .up) and cooldown[classtable.Consecration].ready then
        if not setSpell then setSpell = classtable.Consecration end
    end
end


local function ClearCDs()
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

    classtable.SealofCommand=20920
    classtable.SealofRighteousness=20154
    classtable.SealofMartyrdom=407798
    classtable.HammerofWrath=24239
    classtable.DivineStorm=407778
    classtable.CrusaderStrike=407676
    classtable.Exorcism=415073
    classtable.HolyWrath=2812
    classtable.Judgement=20271
    classtable.Consecration=26573

    local function debugg()
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Retribution:precombat()
    Retribution:priorityList()
    if setSpell then return setSpell end
end
