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
local next_armament

local Protection = {}

local trinket_sync_slot

local function CheckSpellCosts(spell,spellstring)
    if not IsSpellKnown(spell) then return false end
    if not C_Spell.IsSpellUsable(spell) then return false end
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


function Protection:precombat()
    if (CheckSpellCosts(classtable.DevotionAura, 'DevotionAura')) and not buff[classtable.DevotionAura].up and cooldown[classtable.DevotionAura].ready then
        MaxDps:GlowCooldown(classtable.DevotionAura, cooldown[classtable.DevotionAura].ready)
    end
    if (CheckSpellCosts(classtable.Consecration, 'Consecration')) and cooldown[classtable.Consecration].ready then
        return classtable.Consecration
    end
end
function Protection:cooldowns()
    if (CheckSpellCosts(classtable.AvengingWrath, 'AvengingWrath')) and cooldown[classtable.AvengingWrath].ready then
        MaxDps:GlowCooldown(classtable.AvengingWrath, cooldown[classtable.AvengingWrath].ready)
    end
    if (CheckSpellCosts(classtable.MomentofGlory, 'MomentofGlory')) and (( buff[classtable.AvengingWrathBuff].remains <15 or ( timeInCombat >10 ) )) and cooldown[classtable.MomentofGlory].ready then
        MaxDps:GlowCooldown(classtable.MomentofGlory, cooldown[classtable.MomentofGlory].ready)
    end
    if (CheckSpellCosts(classtable.DivineToll, 'DivineToll')) and (targets >= 3) and cooldown[classtable.DivineToll].ready then
        MaxDps:GlowCooldown(classtable.DivineToll, cooldown[classtable.DivineToll].ready)
    end
    if (CheckSpellCosts(classtable.BastionofLight, 'BastionofLight')) and (buff[classtable.AvengingWrathBuff].up or cooldown[classtable.AvengingWrath].remains <= 30) and cooldown[classtable.BastionofLight].ready then
        MaxDps:GlowCooldown(classtable.BastionofLight, cooldown[classtable.BastionofLight].ready)
    end
end
function Protection:standard()
    if (talents[classtable.LightsGuidance] and ( cooldown[classtable.EyeofTyr].remains <2 or buff[classtable.HammerofLightReadyBuff].up ) and ( not talents[classtable.Redoubt] or buff[classtable.RedoubtBuff].count >= 2 or not talents[classtable.BastionofLight] ) and talents[classtable.OfDuskandDawn]) then
        local hammer_of_lightCheck = Protection:hammer_of_light()
        if hammer_of_lightCheck then
            return Protection:hammer_of_light()
        end
    end
    if (CheckSpellCosts(classtable.HammerofLight, 'HammerofLight')) and (( not talents[classtable.Redoubt] or buff[classtable.RedoubtBuff].count == 3 ) and ( buff[classtable.BlessingofDawnBuff].count >= 1 or not talents[classtable.OfDuskandDawn] )) and cooldown[classtable.HammerofLight].ready then
        return classtable.HammerofLight
    end
    if (CheckSpellCosts(classtable.ShieldoftheRighteous, 'ShieldoftheRighteous')) and (( ( HolyPower >2 ) or buff[classtable.BastionofLightBuff].up or buff[classtable.DivinePurposeBuff].up ) and not buff[classtable.HammerofLightReadyBuff].up) and cooldown[classtable.ShieldoftheRighteous].ready then
        return classtable.ShieldoftheRighteous
    end
    if (CheckSpellCosts(classtable.HolyArmaments, 'HolyArmaments')) and (next_armament == classtable.SacredWeapon and ( not buff[classtable.SacredWeaponBuff].up or ( buff[classtable.SacredWeaponBuff].remains <6 and not buff[classtable.AvengingWrathBuff].up and cooldown[classtable.AvengingWrath].remains <= 30 ) )) and cooldown[classtable.HolyArmaments].ready then
        return classtable.HolyArmaments
    end
    if (CheckSpellCosts(classtable.Judgment, 'Judgment')) and (targets >3 and buff[classtable.BulwarkofRighteousFuryBuff].count >= 3 and HolyPower <3) and cooldown[classtable.Judgment].ready then
        return classtable.Judgment
    end
    if (CheckSpellCosts(classtable.AvengersShield, 'AvengersShield')) and (not buff[classtable.BulwarkofRighteousFuryBuff].up and talents[classtable.BulwarkofRighteousFury] and targets >= 3) and cooldown[classtable.AvengersShield].ready then
        return classtable.AvengersShield
    end
    if (CheckSpellCosts(classtable.HammerofWrath, 'HammerofWrath')) and cooldown[classtable.HammerofWrath].ready then
        return classtable.HammerofWrath
    end
    if (CheckSpellCosts(classtable.Judgment, 'Judgment')) and (cooldown[classtable.Judgment].charges >= 2 or cooldown[classtable.Judgment].fullRecharge <= gcd) and cooldown[classtable.Judgment].ready then
        return classtable.Judgment
    end
    if (CheckSpellCosts(classtable.HolyArmaments, 'HolyArmaments')) and (next_armament == classtable.HolyBulwark and cooldown[classtable.HolyArmaments].charges == 2) and cooldown[classtable.HolyArmaments].ready then
        return classtable.HolyArmaments
    end
    if (CheckSpellCosts(classtable.DivineToll, 'DivineToll')) and (( (targets <2) or math.huge >10 )) and cooldown[classtable.DivineToll].ready then
        MaxDps:GlowCooldown(classtable.DivineToll, cooldown[classtable.DivineToll].ready)
    end
    if (CheckSpellCosts(classtable.Judgment, 'Judgment')) and cooldown[classtable.Judgment].ready then
        return classtable.Judgment
    end
    if (CheckSpellCosts(classtable.AvengersShield, 'AvengersShield')) and (not talents[classtable.LightsGuidance]) and cooldown[classtable.AvengersShield].ready then
        return classtable.AvengersShield
    end
    if (CheckSpellCosts(classtable.Consecration, 'Consecration')) and (not buff[classtable.Consecration].up) and cooldown[classtable.Consecration].ready then
        return classtable.Consecration
    end
    if (CheckSpellCosts(classtable.EyeofTyr, 'EyeofTyr')) and (( talents[classtable.InmostLight] and math.huge >= 45 or targets >= 3 ) and not talents[classtable.LightsDeliverance]) and cooldown[classtable.EyeofTyr].ready then
        MaxDps:GlowCooldown(classtable.EyeofTyr, cooldown[classtable.EyeofTyr].ready)
    end
    if (CheckSpellCosts(classtable.HolyArmaments, 'HolyArmaments')) and (next_armament == classtable.HolyBulwark) and cooldown[classtable.HolyArmaments].ready then
        return classtable.HolyArmaments
    end
    if (CheckSpellCosts(classtable.BlessedHammer, 'BlessedHammer')) and cooldown[classtable.BlessedHammer].ready then
        return classtable.BlessedHammer
    end
    if (CheckSpellCosts(classtable.HammeroftheRighteous, 'HammeroftheRighteous')) and cooldown[classtable.HammeroftheRighteous].ready then
        return classtable.HammeroftheRighteous
    end
    if (CheckSpellCosts(classtable.CrusaderStrike, 'CrusaderStrike')) and cooldown[classtable.CrusaderStrike].ready then
        return classtable.CrusaderStrike
    end
    --if (CheckSpellCosts(classtable.WordofGlory, 'WordofGlory')) and (buff[classtable.ShiningLightFreeBuff].up and talents[classtable.LightsGuidance]) and cooldown[classtable.WordofGlory].ready then
    --    return classtable.WordofGlory
    --end
    if (CheckSpellCosts(classtable.AvengersShield, 'AvengersShield')) and cooldown[classtable.AvengersShield].ready then
        return classtable.AvengersShield
    end
    if (CheckSpellCosts(classtable.EyeofTyr, 'EyeofTyr')) and (not talents[classtable.LightsDeliverance]) and cooldown[classtable.EyeofTyr].ready then
        MaxDps:GlowCooldown(classtable.EyeofTyr, cooldown[classtable.EyeofTyr].ready)
    end
    --if (CheckSpellCosts(classtable.WordofGlory, 'WordofGlory')) and (buff[classtable.ShiningLightFreeBuff].up) and cooldown[classtable.WordofGlory].ready then
    --    return classtable.WordofGlory
    --end
    if (CheckSpellCosts(classtable.Consecration, 'Consecration')) and cooldown[classtable.Consecration].ready then
        return classtable.Consecration
    end
end
function Protection:hammer_of_light()
    if (CheckSpellCosts(classtable.HammerofLight, 'HammerofLight')) and (buff[classtable.BlessingofDawnBuff].count >0 or targets >= 5) and cooldown[classtable.HammerofLight].ready then
        return classtable.HammerofLight
    end
    if (CheckSpellCosts(classtable.EyeofTyr, 'EyeofTyr')) and cooldown[classtable.EyeofTyr].ready then
        MaxDps:GlowCooldown(classtable.EyeofTyr, cooldown[classtable.EyeofTyr].ready)
    end
    if (CheckSpellCosts(classtable.ShieldoftheRighteous, 'ShieldoftheRighteous')) and cooldown[classtable.ShieldoftheRighteous].ready then
        return classtable.ShieldoftheRighteous
    end
    if (CheckSpellCosts(classtable.EyeofTyr, 'EyeofTyr')) and (buff[classtable.BlessingofDawnBuff].count >0) and cooldown[classtable.EyeofTyr].ready then
        MaxDps:GlowCooldown(classtable.EyeofTyr, cooldown[classtable.EyeofTyr].ready)
    end
    if (CheckSpellCosts(classtable.HammerofWrath, 'HammerofWrath')) and cooldown[classtable.HammerofWrath].ready then
        return classtable.HammerofWrath
    end
    if (CheckSpellCosts(classtable.Judgment, 'Judgment')) and cooldown[classtable.Judgment].ready then
        return classtable.Judgment
    end
    if (CheckSpellCosts(classtable.BlessedHammer, 'BlessedHammer')) and cooldown[classtable.BlessedHammer].ready then
        return classtable.BlessedHammer
    end
    if (CheckSpellCosts(classtable.HammeroftheRighteous, 'HammeroftheRighteous')) and cooldown[classtable.HammeroftheRighteous].ready then
        return classtable.HammeroftheRighteous
    end
    if (CheckSpellCosts(classtable.CrusaderStrike, 'CrusaderStrike')) and cooldown[classtable.CrusaderStrike].ready then
        return classtable.CrusaderStrike
    end
    if (CheckSpellCosts(classtable.DivineToll, 'DivineToll')) and cooldown[classtable.DivineToll].ready then
        MaxDps:GlowCooldown(classtable.DivineToll, cooldown[classtable.DivineToll].ready)
    end
end
function Protection:trinkets()
end

function Protection:callaction()
    if (CheckSpellCosts(classtable.Rebuke, 'Rebuke')) and cooldown[classtable.Rebuke].ready then
        MaxDps:GlowCooldown(classtable.Rebuke, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    local cooldownsCheck = Protection:cooldowns()
    if cooldownsCheck then
        return cooldownsCheck
    end
    local trinketsCheck = Protection:trinkets()
    if trinketsCheck then
        return trinketsCheck
    end
    local standardCheck = Protection:standard()
    if standardCheck then
        return standardCheck
    end
    if (talents[classtable.LightsGuidance] and ( cooldown[classtable.EyeofTyr].remains <2 or buff[classtable.HammerofLightReadyBuff].up ) and ( not talents[classtable.Redoubt] or buff[classtable.RedoubtBuff].count >= 2 or not talents[classtable.BastionofLight] ) and talents[classtable.OfDuskandDawn]) then
        local hammer_of_lightCheck = Protection:hammer_of_light()
        if hammer_of_lightCheck then
            return Protection:hammer_of_light()
        end
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
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
    HolyPower = UnitPower('player', HolyPowerPT)
    HolyPowerMax = 5
    HolyPowerDeficit = HolyPowerMax - HolyPower
    classtable.HammerofLight = 427453
    classtable.HolyArmaments = 432459
    next_armament = function()
        local firstSpell = GetSpellInfo(classtable.HolyArmaments)
        local spellinfo = firstSpell and GetSpellInfo(firstSpell.spellID)
        return spellinfo and spellinfo.spellID or 0
    end
    for spellId in pairs(MaxDps.Flags) do
        self.Flags[spellId] = false
        self:ClearGlowIndependent(spellId, spellId)
    end
    classtable.AvengingWrathBuff = 31884
    classtable.HammerofLightReadyBuff = 0
    classtable.RedoubtBuff = 0
    classtable.BlessingofDawnBuff = 0
    classtable.BastionofLightBuff = 378974
    classtable.DivinePurposeBuff = 223819
    classtable.HammerofLightFreeBuff = 0
    classtable.SacredWeaponBuff = 0
    classtable.BulwarkofRighteousFuryBuff = 386652
    classtable.ShiningLightFreeBuff = 0

    local precombatCheck = Protection:precombat()
    if precombatCheck then
        return Protection:precombat()
    end

    local callactionCheck = Protection:callaction()
    if callactionCheck then
        return Protection:callaction()
    end
end
