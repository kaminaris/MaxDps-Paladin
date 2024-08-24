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

local Retribution = {}

local trinket_one_buffs
local trinket_two_buffs
local trinket_one_sync
local trinket_two_sync
local trinket_priority
local ds_castable

local function CheckSpellCosts(spell,spellstring)
    if not IsSpellKnown(spell) then return false end
    if not C_Spell.IsSpellUsable(spell) then return false end
    if spellstring == 'TouchofDeath' then
        if targethealthPerc > 15 then
            return false
        end
    end
    if spellstring == 'KillShot' then
        if (classtable.SicEmBuff and not buff[classtable.SicEmBuff].up) or (classtable.HuntersPreyBuff and not buff[classtable.HuntersPreyBuff].up) and targethealthPerc > 15 then
            return false
        end
    end
    if spellstring == 'HammerofWrath' then
        if ( (classtable.AvengingWrathBuff and not buff[classtable.AvengingWrathBuff].up) or (classtable.FinalVerdictBuff and not buff[classtable.FinalVerdictBuff].up) ) and targethealthPerc > 20 then
            return false
        end
    end
    if spellstring == 'Execute' then
        if (classtable.SuddenDeathBuff and not buff[classtable.SuddenDeathBuff].up) and targethealthPerc > 35 then
            return false
        end
    end
    local costs = C_Spell.GetSpellPowerCost(spell)
    if type(costs) ~= 'table' and spellstring then return true end
    for i,costtable in pairs(costs) do
        if UnitPower('player', costtable.type) < costtable.cost then
            return false
        end
    end
    return true
end
local function MaxGetSpellCost(spell,power)
    local costs = C_Spell.GetSpellPowerCost(spell)
    if type(costs) ~= 'table' then return 0 end
    for i,costtable in pairs(costs) do
        if costtable.name == power then
            return costtable.cost
        end
    end
    return 0
end



local function CheckTrinketNames(checkName)
    --if slot == 1 then
    --    slot = 13
    --end
    --if slot == 2 then
    --    slot = 14
    --end
    for i=13,14 do
        local itemID = GetInventoryItemID('player', i)
        local itemName = C_Item.GetItemInfo(itemID)
        if checkName == itemName then
            return true
        end
    end
    return false
end


local function CheckTrinketCooldown(slot)
    if slot == 1 then
        slot = 13
    end
    if slot == 2 then
        slot = 14
    end
    if slot == 13 or slot == 14 then
        local itemID = GetInventoryItemID('player', slot)
        local _, duration, _ = C_Item.GetItemCooldown(itemID)
        if duration == 0 then return true else return false end
    else
        local tOneitemID = GetInventoryItemID('player', 13)
        local tTwoitemID = GetInventoryItemID('player', 14)
        local tOneitemName = C_Item.GetItemInfo(tOneitemID)
        local tTwoitemName = C_Item.GetItemInfo(tTwoitemID)
        if tOneitemName == slot then
            local _, duration, _ = C_Item.GetItemCooldown(tOneitemID)
            if duration == 0 then return true else return false end
        end
        if tTwoitemName == slot then
            local _, duration, _ = C_Item.GetItemCooldown(tTwoitemID)
            if duration == 0 then return true else return false end
        end
    end
end




local function CheckPrevSpell(spell)
    if MaxDps and MaxDps.spellHistory then
        if MaxDps.spellHistory[1] then
            if MaxDps.spellHistory[1] == spell then
                return true
            end
            if MaxDps.spellHistory[1] ~= spell then
                return false
            end
        end
    end
    return true
end


local function boss()
    if UnitExists('boss1')
    or UnitExists('boss2')
    or UnitExists('boss3')
    or UnitExists('boss4')
    or UnitExists('boss5')
    or UnitExists('boss6')
    or UnitExists('boss7')
    or UnitExists('boss8')
    or UnitExists('boss9')
    or UnitExists('boss10') then
        return true
    end
    return false
end


function Retribution:precombat()
    if (CheckSpellCosts(classtable.ShieldofVengeance, 'ShieldofVengeance')) and cooldown[classtable.ShieldofVengeance].ready then
        return classtable.ShieldofVengeance
    end
end
function Retribution:cooldowns()
    if (CheckSpellCosts(classtable.ShieldofVengeance, 'ShieldofVengeance')) and (ttd >15 and ( not talents[classtable.ExecutionSentence] or not debuff[classtable.ExecutionSentenceDeBuff].up )) and cooldown[classtable.ShieldofVengeance].ready then
        return classtable.ShieldofVengeance
    end
    if (CheckSpellCosts(classtable.ExecutionSentence, 'ExecutionSentence')) and (( not buff[classtable.CrusadeBuff].up and cooldown[classtable.Crusade].remains >15 or buff[classtable.CrusadeBuff].count == 10 or cooldown[classtable.AvengingWrath].remains <0.75 or cooldown[classtable.AvengingWrath].remains >15 or talents[classtable.RadiantGlory] ) and ( HolyPower >= 4 and timeInCombat <5 or HolyPower >= 3 and timeInCombat >5 or HolyPower >= 2 and talents[classtable.DivineAuxiliary] ) and ( ttd >8 and not talents[classtable.ExecutionersWill] or ttd >12 )) and cooldown[classtable.ExecutionSentence].ready then
        return classtable.ExecutionSentence
    end
    if (CheckSpellCosts(classtable.AvengingWrath, 'AvengingWrath')) and (( HolyPower >= 4 and timeInCombat <5 or HolyPower >= 3 and timeInCombat >5 or HolyPower >= 2 and talents[classtable.DivineAuxiliary] and ( cooldown[classtable.ExecutionSentence].remains == 0 or cooldown[classtable.FinalReckoning].remains == 0 ) ) and ( not (targets >1) or ttd >10 )) and cooldown[classtable.AvengingWrath].ready then
        MaxDps:GlowCooldown(classtable.AvengingWrath, cooldown[classtable.AvengingWrath].ready)
    end
    if (CheckSpellCosts(classtable.Crusade, 'Crusade')) and (HolyPower >= 5 and timeInCombat <5 or HolyPower >= 3 and timeInCombat >5) and cooldown[classtable.Crusade].ready then
        return classtable.Crusade
    end
    if (CheckSpellCosts(classtable.FinalReckoning, 'FinalReckoning')) and (( HolyPower >= 4 and timeInCombat <8 or HolyPower >= 3 and timeInCombat >= 8 or HolyPower >= 2 and talents[classtable.DivineAuxiliary] ) and ( cooldown[classtable.AvengingWrath].remains >10 or cooldown[classtable.Crusade].ready==false and ( not buff[classtable.CrusadeBuff].up or buff[classtable.CrusadeBuff].count >= 10 ) or talents[classtable.RadiantGlory] and ( buff[classtable.AvengingWrathBuff].up or buff[classtable.CrusadeBuff].up ) ) and ( (targets <2) or (targets >1) or math.huge >40 )) and cooldown[classtable.FinalReckoning].ready then
        return classtable.FinalReckoning
    end
end
function Retribution:finishers()
    ds_castable = ( targets >= 3 or targets >= 2 and not talents[classtable.DivineArbiter] or buff[classtable.EmpyreanPowerBuff].up ) and not buff[classtable.EmpyreanLegacyBuff].up and not ( buff[classtable.DivineArbiterBuff].up and buff[classtable.DivineArbiterBuff].count >24 )
    if (CheckSpellCosts(classtable.DivineHammer, 'DivineHammer')) and cooldown[classtable.DivineHammer].ready then
        return classtable.DivineHammer
    end
    if (CheckSpellCosts(classtable.DivineStorm, 'DivineStorm')) and (ds_castable and ( not talents[classtable.Crusade] or cooldown[classtable.Crusade].remains >gcd * 3 or buff[classtable.CrusadeBuff].up and buff[classtable.CrusadeBuff].count <10 or talents[classtable.RadiantGlory] )) and cooldown[classtable.DivineStorm].ready then
        return classtable.DivineStorm
    end
    if (CheckSpellCosts(classtable.JusticarsVengeance, 'JusticarsVengeance')) and (not talents[classtable.Crusade] or cooldown[classtable.Crusade].remains >gcd * 3 or buff[classtable.CrusadeBuff].up and buff[classtable.CrusadeBuff].count <10 or talents[classtable.RadiantGlory]) and cooldown[classtable.JusticarsVengeance].ready then
        return classtable.JusticarsVengeance
    end
    if (CheckSpellCosts(classtable.TemplarsVerdict, 'TemplarsVerdict')) and (not talents[classtable.Crusade] or cooldown[classtable.Crusade].remains >gcd * 3 or buff[classtable.CrusadeBuff].up and buff[classtable.CrusadeBuff].count <10 or talents[classtable.RadiantGlory]) and cooldown[classtable.TemplarsVerdict].ready then
        return classtable.TemplarsVerdict
    end
    if (CheckSpellCosts(classtable.FinalVerdict, 'TemplarsVerdict')) and (not talents[classtable.Crusade] or cooldown[classtable.Crusade].remains >gcd * 3 or buff[classtable.CrusadeBuff].up and buff[classtable.CrusadeBuff].count <10 or talents[classtable.RadiantGlory]) and cooldown[classtable.FinalVerdict].ready then
        return classtable.FinalVerdict
    end
end
function Retribution:generators()
    if (HolyPower == 5 or buff[classtable.EchoesofWrathBuff].up and (MaxDps.tier and MaxDps.tier[31].count >= 4) and talents[classtable.CrusadingStrikes] or ( debuff[classtable.JudgmentDeBuff].up or HolyPower == 4 ) and buff[classtable.DivineResonanceBuff].up and not (MaxDps.tier and MaxDps.tier[31].count >= 2)) then
        local finishersCheck = Retribution:finishers()
        if finishersCheck then
            return Retribution:finishers()
        end
    end
    if (CheckSpellCosts(classtable.WakeofAshes, 'WakeofAshes')) and (HolyPower <= 2 and ( cooldown[classtable.AvengingWrath].remains >6 or cooldown[classtable.Crusade].remains >6 or talents[classtable.RadiantGlory] ) and ( not talents[classtable.ExecutionSentence] or cooldown[classtable.ExecutionSentence].remains >4 or ttd <8 ) and ( (targets <2) or math.huge >20 or (targets >1) )) and cooldown[classtable.WakeofAshes].ready then
        return classtable.WakeofAshes
    end
    if (CheckSpellCosts(classtable.BladeofJustice, 'BladeofJustice')) and (not debuff[classtable.ExpurgationDeBuff].up and (MaxDps.tier and MaxDps.tier[31].count >= 2)) and cooldown[classtable.BladeofJustice].ready then
        return classtable.BladeofJustice
    end
    if (CheckSpellCosts(classtable.DivineToll, 'DivineToll')) and (HolyPower <= 2 and ( (targets <2) or math.huge >30 or (targets >1) ) and ( cooldown[classtable.AvengingWrath].remains >15 or cooldown[classtable.Crusade].remains >15 or talents[classtable.RadiantGlory] or boss and ttd <8 )) and cooldown[classtable.DivineToll].ready then
        MaxDps:GlowCooldown(classtable.DivineToll, cooldown[classtable.DivineToll].ready)
    end
    if (CheckSpellCosts(classtable.Judgment, 'Judgment')) and (debuff[classtable.ExpurgationDeBuff].up and not buff[classtable.EchoesofWrathBuff].up and (MaxDps.tier and MaxDps.tier[31].count >= 2)) and cooldown[classtable.Judgment].ready then
        return classtable.Judgment
    end
    if (HolyPower >= 3 and buff[classtable.CrusadeBuff].up and buff[classtable.CrusadeBuff].count <10) then
        local finishersCheck = Retribution:finishers()
        if finishersCheck then
            return Retribution:finishers()
        end
    end
    if (CheckSpellCosts(classtable.TemplarSlash, 'TemplarSlash')) and (buff[classtable.TemplarStrikesBuff].remains <gcd and targets >= 2) and cooldown[classtable.TemplarSlash].ready then
        return classtable.TemplarSlash
    end
    if (CheckSpellCosts(classtable.BladeofJustice, 'BladeofJustice')) and (( HolyPower <= 3 or not talents[classtable.HolyBlade] ) and ( targets >= 2 and not talents[classtable.CrusadingStrikes] or targets >= 4 )) and cooldown[classtable.BladeofJustice].ready then
        return classtable.BladeofJustice
    end
    if (CheckSpellCosts(classtable.HammerofWrath, 'HammerofWrath')) and (( targets <2 or not talents[classtable.BlessedChampion] ) and ( HolyPower <= 3 or targetHP >20 or not talents[classtable.VanguardsMomentum] )) and cooldown[classtable.HammerofWrath].ready then
        return classtable.HammerofWrath
    end
    if (CheckSpellCosts(classtable.TemplarSlash, 'TemplarSlash')) and (buff[classtable.TemplarStrikesBuff].remains <gcd) and cooldown[classtable.TemplarSlash].ready then
        return classtable.TemplarSlash
    end
    if (CheckSpellCosts(classtable.Judgment, 'Judgment')) and (not debuff[classtable.JudgmentDeBuff].up and ( HolyPower <= 3 or not talents[classtable.BoundlessJudgment] )) and cooldown[classtable.Judgment].ready then
        return classtable.Judgment
    end
    if (CheckSpellCosts(classtable.BladeofJustice, 'BladeofJustice')) and (HolyPower <= 3 or not talents[classtable.HolyBlade]) and cooldown[classtable.BladeofJustice].ready then
        return classtable.BladeofJustice
    end
    if (CheckSpellCosts(classtable.Judgment, 'Judgment')) and (HolyPower <= 3 or not talents[classtable.BoundlessJudgment]) and cooldown[classtable.Judgment].ready then
        return classtable.Judgment
    end
    if (( targetHP <= 20 or buff[classtable.AvengingWrathBuff].up or buff[classtable.CrusadeBuff].up or buff[classtable.EmpyreanPowerBuff].up )) then
        local finishersCheck = Retribution:finishers()
        if finishersCheck then
            return Retribution:finishers()
        end
    end
    if (CheckSpellCosts(classtable.CrusaderStrike, 'CrusaderStrike')) and (cooldown[classtable.CrusaderStrike].charges >= 1.75 and ( HolyPower <= 2 or HolyPower <= 3 and cooldown[classtable.BladeofJustice].remains >gcd * 2 or HolyPower == 4 and cooldown[classtable.BladeofJustice].remains >gcd * 2 and cooldown[classtable.Judgment].remains >gcd * 2 )) and cooldown[classtable.CrusaderStrike].ready then
        return classtable.CrusaderStrike
    end
    local finishersCheck = Retribution:finishers()
    if finishersCheck then
        return finishersCheck
    end
    if (CheckSpellCosts(classtable.TemplarSlash, 'TemplarSlash')) and cooldown[classtable.TemplarSlash].ready then
        return classtable.TemplarSlash
    end
    if (CheckSpellCosts(classtable.TemplarStrike, 'TemplarStrike')) and cooldown[classtable.TemplarStrike].ready then
        return classtable.TemplarStrike
    end
    if (CheckSpellCosts(classtable.HammerofWrath, 'HammerofWrath')) and (HolyPower <= 3 or targetHP >20 or not talents[classtable.VanguardsMomentum]) and cooldown[classtable.HammerofWrath].ready then
        return classtable.HammerofWrath
    end
    if (CheckSpellCosts(classtable.CrusaderStrike, 'CrusaderStrike')) and cooldown[classtable.CrusaderStrike].ready then
        return classtable.CrusaderStrike
    end
end

function Retribution:callaction()
    if (CheckSpellCosts(classtable.Rebuke, 'Rebuke')) and cooldown[classtable.Rebuke].ready then
        MaxDps:GlowCooldown(classtable.Rebuke, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    local cooldownsCheck = Retribution:cooldowns()
    if cooldownsCheck then
        return cooldownsCheck
    end
    local generatorsCheck = Retribution:generators()
    if generatorsCheck then
        return generatorsCheck
    end
    if (HolyPower == 5 or buff[classtable.EchoesofWrathBuff].up and (MaxDps.tier and MaxDps.tier[31].count >= 4) and talents[classtable.CrusadingStrikes] or ( debuff[classtable.JudgmentDeBuff].up or HolyPower == 4 ) and buff[classtable.DivineResonanceBuff].up and not (MaxDps.tier and MaxDps.tier[31].count >= 2)) then
        local finishersCheck = Retribution:finishers()
        if finishersCheck then
            return Retribution:finishers()
        end
    end
    if (HolyPower >= 3 and buff[classtable.CrusadeBuff].up and buff[classtable.CrusadeBuff].count <10) then
        local finishersCheck = Retribution:finishers()
        if finishersCheck then
            return Retribution:finishers()
        end
    end
    if (( targetHP <= 20 or buff[classtable.AvengingWrathBuff].up or buff[classtable.CrusadeBuff].up or buff[classtable.EmpyreanPowerBuff].up )) then
        local finishersCheck = Retribution:finishers()
        if finishersCheck then
            return Retribution:finishers()
        end
    end
    local finishersCheck = Retribution:finishers()
    if finishersCheck then
        return finishersCheck
    end
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
    classtable.TemplarSlash = 406647
    classtable.TemplarStrike = 407480
    for spellId in pairs(MaxDps.Flags) do
        self.Flags[spellId] = false
        self:ClearGlowIndependent(spellId, spellId)
    end
    classtable.ExecutionSentenceDeBuff = 343527
    classtable.CrusadeBuff = 231895
    classtable.AvengingWrathBuff = 31884
    classtable.EmpyreanPowerBuff = 326733
    classtable.EmpyreanLegacyBuff = 387178
    classtable.DivineArbiterBuff = 406975
    classtable.EchoesofWrathBuff = 0
    classtable.JudgmentDeBuff = 197277
    classtable.DivineResonanceBuff = 384029
    classtable.ExpurgationDeBuff = 383346
    classtable.TemplarStrikesBuff = 406648

    local precombatCheck = Retribution:precombat()
    if precombatCheck then
        return Retribution:precombat()
    end

    local callactionCheck = Retribution:callaction()
    if callactionCheck then
        return Retribution:callaction()
    end
end
