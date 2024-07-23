local _, addonTable = ...
local Paladin = addonTable.Paladin
local MaxDps = _G.MaxDps
if not MaxDps then return end

local UnitPower = UnitPower
local UnitHealth = UnitHealth
local UnitAura = C_UnitAuras.GetAuraDataByIndex
local UnitAuraByName = C_UnitAuras.GetAuraDataBySpellName
local GetSpellDescription = GetSpellDescription
local GetSpellPowerCost = C_Spell.GetSpellPowerCost
local UnitHealthMax = UnitHealthMax
local UnitPowerMax = UnitPowerMax
local SpellHaste
local SpellCrit

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

local Protection = {}

local trinket_sync_slot

local function CheckSpellCosts(spell,spellstring)
    if not IsSpellKnownOrOverridesKnown(spell) then return false end
    if spellstring == 'TouchofDeath' or spellstring == 'TouchofDeath' then
        if targethealthPerc < 15 then
            return true
        else
            return false
        end
    end
    if spellstring == 'HammerofWrath' then
        if targethealthPerc < 15 then
            return true
        else
            return false
        end
    end
    local costs = GetSpellPowerCost(spell)
    if type(costs) ~= 'table' and spellstring then return true end
    for i,costtable in pairs(costs) do
        if UnitPower('player', costtable.type) < costtable.cost then
            return false
        end
    end
    return true
end
local function MaxGetSpellCost(spell,power)
    local costs = GetSpellPowerCost(spell)
    if type(costs) ~= 'table' then return 0 end
    for i,costtable in pairs(costs) do
        if costtable.name == power then
            return costtable.cost
        end
    end
    return 0
end



local function CheckEquipped(checkName)
    for i=1,14 do
        local itemID = GetInventoryItemID('player', i)
        local itemName = itemID and C_Item.GetItemInfo(itemID) or ''
        if checkName == itemName then
            return true
        end
    end
    return false
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

function Protection:cooldowns()
    if (MaxDps:FindSpell(classtable.AvengersShield) and CheckSpellCosts(classtable.AvengersShield, 'AvengersShield')) and (timeInCombat == 0 and ( (MaxDps.tier and MaxDps.tier[29].count >= 2) )) and cooldown[classtable.AvengersShield].ready then
        return classtable.AvengersShield
    end
    if (MaxDps:FindSpell(classtable.AvengingWrath) and CheckSpellCosts(classtable.AvengingWrath, 'AvengingWrath')) and cooldown[classtable.AvengingWrath].ready then
        return classtable.AvengingWrath
    end
    if (MaxDps:FindSpell(classtable.Potion) and CheckSpellCosts(classtable.Potion, 'Potion')) and (buff[classtable.AvengingWrathBuff].up) and cooldown[classtable.Potion].ready then
        return classtable.Potion
    end
    if (MaxDps:FindSpell(classtable.MomentofGlory) and CheckSpellCosts(classtable.MomentofGlory, 'MomentofGlory')) and (( buff[classtable.AvengingWrathBuff].remains <15 or ( timeInCombat >10 or ( cooldown[classtable.AvengingWrath].remains >15 ) ) and ( cooldown[classtable.AvengersShield].remains and cooldown[classtable.Judgment].remains and cooldown[classtable.HammerofWrath].remains ) )) and cooldown[classtable.MomentofGlory].ready then
        return classtable.MomentofGlory
    end
    if (MaxDps:FindSpell(classtable.DivineToll) and CheckSpellCosts(classtable.DivineToll, 'DivineToll')) and (targets >= 3) and cooldown[classtable.DivineToll].ready then
        return classtable.DivineToll
    end
    if (MaxDps:FindSpell(classtable.BastionofLight) and CheckSpellCosts(classtable.BastionofLight, 'BastionofLight')) and (buff[classtable.AvengingWrathBuff].up or cooldown[classtable.AvengingWrath].remains <= 30) and cooldown[classtable.BastionofLight].ready then
        return classtable.BastionofLight
    end
end
function Protection:standard()
    if (MaxDps:FindSpell(classtable.Consecration) and CheckSpellCosts(classtable.Consecration, 'Consecration')) and (buff[classtable.SanctificationBuff].count == buff[classtable.SanctificationBuff].maxStacks) and cooldown[classtable.Consecration].ready then
        return classtable.Consecration
    end
    if (MaxDps:FindSpell(classtable.ShieldoftheRighteous) and CheckSpellCosts(classtable.ShieldoftheRighteous, 'ShieldoftheRighteous')) and (( ( ( not talents[classtable.RighteousProtector] or cooldown[classtable.RighteousProtectorIcd].remains == 0 ) and HolyPower >2 ) or buff[classtable.BastionofLightBuff].up or buff[classtable.DivinePurposeBuff].up ) and ( not buff[classtable.SanctificationBuff].up or buff[classtable.SanctificationBuff].count <buff[classtable.SanctificationBuff].maxStacks )) and cooldown[classtable.ShieldoftheRighteous].ready then
        return classtable.ShieldoftheRighteous
    end
    if (MaxDps:FindSpell(classtable.AvengersShield) and CheckSpellCosts(classtable.AvengersShield, 'AvengersShield')) and (( (MaxDps.tier and MaxDps.tier[29].count >= 2) ) and ( not buff[classtable.AllyoftheLightBuff].up or buff[classtable.AllyoftheLightBuff].remains <gcd )) and cooldown[classtable.AvengersShield].ready then
        return classtable.AvengersShield
    end
    if (MaxDps:FindSpell(classtable.Judgment) and CheckSpellCosts(classtable.Judgment, 'Judgment')) and (targets >3 and buff[classtable.BulwarkofRighteousFuryBuff].count >= 3 and HolyPower <3) and cooldown[classtable.Judgment].ready then
        return classtable.Judgment
    end
    if (MaxDps:FindSpell(classtable.Judgment) and CheckSpellCosts(classtable.Judgment, 'Judgment')) and (not buff[classtable.SanctificationEmpowerBuff].up and (MaxDps.tier and MaxDps.tier[31].count >= 2)) and cooldown[classtable.Judgment].ready then
        return classtable.Judgment
    end
    if (MaxDps:FindSpell(classtable.HammerofWrath) and CheckSpellCosts(classtable.HammerofWrath, 'HammerofWrath')) and cooldown[classtable.HammerofWrath].ready then
        return classtable.HammerofWrath
    end
    if (MaxDps:FindSpell(classtable.Judgment) and CheckSpellCosts(classtable.Judgment, 'Judgment')) and (cooldown[classtable.Judgment].charges >= 2 ) and cooldown[classtable.Judgment].ready then
        return classtable.Judgment
    end
    if (MaxDps:FindSpell(classtable.AvengersShield) and CheckSpellCosts(classtable.AvengersShield, 'AvengersShield')) and (targets >2 or buff[classtable.MomentofGloryBuff].up) and cooldown[classtable.AvengersShield].ready then
        return classtable.AvengersShield
    end
    if (MaxDps:FindSpell(classtable.DivineToll) and CheckSpellCosts(classtable.DivineToll, 'DivineToll')) and (( targets <2 )) and cooldown[classtable.DivineToll].ready then
        return classtable.DivineToll
    end
    if (MaxDps:FindSpell(classtable.AvengersShield) and CheckSpellCosts(classtable.AvengersShield, 'AvengersShield')) and cooldown[classtable.AvengersShield].ready then
        return classtable.AvengersShield
    end
    if (MaxDps:FindSpell(classtable.Judgment) and CheckSpellCosts(classtable.Judgment, 'Judgment')) and (debuff[classtable.JudgmentDeBuff].remains) and cooldown[classtable.Judgment].ready then
        return classtable.Judgment
    end
    if (MaxDps:FindSpell(classtable.Consecration) and CheckSpellCosts(classtable.Consecration, 'Consecration')) and (not buff[classtable.Consecration].up and ( not buff[classtable.SanctificationBuff].up == buff[classtable.SanctificationBuff].maxStacks or not (MaxDps.tier and MaxDps.tier[31].count >= 2) )) and cooldown[classtable.Consecration].ready then
        return classtable.Consecration
    end
    if (MaxDps:FindSpell(classtable.EyeofTyr) and CheckSpellCosts(classtable.EyeofTyr, 'EyeofTyr')) and (talents[classtable.InmostLight] or targets >= 3) and cooldown[classtable.EyeofTyr].ready then
        return classtable.EyeofTyr
    end
    if (MaxDps:FindSpell(classtable.BlessedHammer) and CheckSpellCosts(classtable.BlessedHammer, 'BlessedHammer')) and cooldown[classtable.BlessedHammer].ready then
        return classtable.BlessedHammer
    end
    if (MaxDps:FindSpell(classtable.HammeroftheRighteous) and CheckSpellCosts(classtable.HammeroftheRighteous, 'HammeroftheRighteous')) and cooldown[classtable.HammeroftheRighteous].ready then
        return classtable.HammeroftheRighteous
    end
    if (MaxDps:FindSpell(classtable.CrusaderStrike) and CheckSpellCosts(classtable.CrusaderStrike, 'CrusaderStrike')) and cooldown[classtable.CrusaderStrike].ready then
        return classtable.CrusaderStrike
    end
    if (MaxDps:FindSpell(classtable.EyeofTyr) and CheckSpellCosts(classtable.EyeofTyr, 'EyeofTyr')) and (not talents[classtable.InmostLight] or targets >= 3) and cooldown[classtable.EyeofTyr].ready then
        return classtable.EyeofTyr
    end
    if (MaxDps:FindSpell(classtable.WordofGlory) and CheckSpellCosts(classtable.WordofGlory, 'WordofGlory')) and (buff[classtable.ShiningLightFreeBuff].up) and cooldown[classtable.WordofGlory].ready then
        return classtable.WordofGlory
    end
    if (MaxDps:FindSpell(classtable.Consecration) and CheckSpellCosts(classtable.Consecration, 'Consecration')) and (not buff[classtable.SanctificationEmpowerBuff].up) and cooldown[classtable.Consecration].ready then
        return classtable.Consecration
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
    targethealthPerc = (targetHP / targetmaxHP) * 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    SpellHaste = UnitSpellHaste('target')
    SpellCrit = GetCritChance()
    HolyPower = UnitPower('player', HolyPowerPT)
    classtable.AvengingWrathBuff = 31884
    classtable.SanctificationBuff = 424616
    classtable.BastionofLightBuff = 378974
    classtable.DivinePurposeBuff = 223819
    classtable.AllyoftheLightBuff = 394714
    classtable.BulwarkofRighteousFuryBuff = 386652
    classtable.SanctificationEmpowerBuff = 424616
    classtable.MomentofGloryBuff = 327193
    classtable.JudgmentDeBuff = 197277
    classtable.ShiningLightFreeBuff = 0

    if (MaxDps:FindSpell(classtable.AutoAttack) and CheckSpellCosts(classtable.AutoAttack, 'AutoAttack')) and cooldown[classtable.AutoAttack].ready then
        return classtable.AutoAttack
    end
    local cooldownsCheck = Protection:cooldowns()
    if cooldownsCheck then
        return cooldownsCheck
    end
    local standardCheck = Protection:standard()
    if standardCheck then
        return standardCheck
    end

end
