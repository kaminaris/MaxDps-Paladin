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


local function CheckSpellCosts(spell,spellstring)
    if not IsSpellKnownOrOverridesKnown(spell) then return false end
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


function Holy:precombat()
    if (MaxDps:FindSpell(classtable.DevotionAura) and CheckSpellCosts(classtable.DevotionAura, 'DevotionAura')) and (not buff[classtable.PaladinAuraBuff].up) and cooldown[classtable.DevotionAura].ready then
        MaxDps:GlowCooldown(classtable.DevotionAura, cooldown[classtable.DevotionAura].ready)
    end
    --if (MaxDps:FindSpell(classtable.BeaconofLight) and CheckSpellCosts(classtable.BeaconofLight, 'BeaconofLight')) and (debuff[classtable.BeaconofLightDebuff].count  == 0) and cooldown[classtable.BeaconofLight].ready then
    --    return classtable.BeaconofLight
    --end
    --if (MaxDps:FindSpell(classtable.BeaconofFaith) and CheckSpellCosts(classtable.BeaconofFaith, 'BeaconofFaith')) and ( debuff[classtable.BeaconofFaithDebuff].count  == 0) and cooldown[classtable.BeaconofFaith].ready then
    --    return classtable.BeaconofFaith
    --end
end
function Holy:spenders()
    --if (MaxDps:FindSpell(classtable.WordofGlory) and CheckSpellCosts(classtable.WordofGlory, 'WordofGlory')) and ( ( curentHP <70 or not CheckEquipped('Shield') ) and buff[classtable.ShiningRighteousnessReadyBuff].up or buff[classtable.EmpyreanLegacyBuff].up) and cooldown[classtable.WordofGlory].ready then
    --    return classtable.WordofGlory
    --end
    --if (MaxDps:FindSpell(classtable.LightofDawn) and CheckSpellCosts(classtable.LightofDawn, 'LightofDawn')) and ( buff[classtable.ShiningRighteousnessReadyBuff].up) and cooldown[classtable.LightofDawn].ready then
    --    return classtable.LightofDawn
    --end
    if (MaxDps:FindSpell(classtable.ShieldoftheRighteous) and CheckSpellCosts(classtable.ShieldoftheRighteous, 'ShieldoftheRighteous')) and cooldown[classtable.ShieldoftheRighteous].ready then
        return classtable.ShieldoftheRighteous
    end
end

function Holy:callaction()
    if (MaxDps:FindSpell(classtable.Rebuke) and CheckSpellCosts(classtable.Rebuke, 'Rebuke')) and cooldown[classtable.Rebuke].ready then
        MaxDps:GlowCooldown(classtable.Rebuke, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (MaxDps:FindSpell(classtable.AvengingWrath) and CheckSpellCosts(classtable.AvengingWrath, 'AvengingWrath')) and cooldown[classtable.AvengingWrath].ready then
        MaxDps:GlowCooldown(classtable.AvengingWrath, cooldown[classtable.AvengingWrath].ready)
    end
    if (MaxDps:FindSpell(classtable.AvengingCrusader) and CheckSpellCosts(classtable.AvengingCrusader, 'AvengingCrusader')) and cooldown[classtable.AvengingCrusader].ready then
        MaxDps:GlowCooldown(classtable.AvengingCrusader, cooldown[classtable.AvengingCrusader].ready)
    end
    if (MaxDps:FindSpell(classtable.BlessingofSummer) and CheckSpellCosts(classtable.BlessingofSummer, 'BlessingofSummer')) and cooldown[classtable.BlessingofSummer].ready then
        return classtable.BlessingofSummer
    end
    if (MaxDps:FindSpell(classtable.BlessingofAutumn) and CheckSpellCosts(classtable.BlessingofAutumn, 'BlessingofAutumn')) and cooldown[classtable.BlessingofAutumn].ready then
        return classtable.BlessingofAutumn
    end
    if (MaxDps:FindSpell(classtable.BlessingofWinter) and CheckSpellCosts(classtable.BlessingofWinter, 'BlessingofWinter')) and cooldown[classtable.BlessingofWinter].ready then
        return classtable.BlessingofWinter
    end
    if (MaxDps:FindSpell(classtable.BlessingofSpring) and CheckSpellCosts(classtable.BlessingofSpring, 'BlessingofSpring')) and cooldown[classtable.BlessingofSpring].ready then
        return classtable.BlessingofSpring
    end
    if (not talents[classtable.AvengingCrusader] or cooldown[classtable.AvengingCrusader].remains >gcd or HolyPowerDeficit == 0) then
        local spendersCheck = Holy:spenders()
        if spendersCheck then
            return Holy:spenders()
        end
    end
    if (MaxDps:FindSpell(classtable.DivineToll) and CheckSpellCosts(classtable.DivineToll, 'DivineToll')) and cooldown[classtable.DivineToll].ready then
        MaxDps:GlowCooldown(classtable.DivineToll, cooldown[classtable.DivineToll].ready)
    end
    if (MaxDps:FindSpell(classtable.HolyPrism) and CheckSpellCosts(classtable.HolyPrism, 'HolyPrism')) and cooldown[classtable.HolyPrism].ready then
        return classtable.HolyPrism
    end
    --if (MaxDps:FindSpell(classtable.BeaconofVirtue) and CheckSpellCosts(classtable.BeaconofVirtue, 'BeaconofVirtue')) and cooldown[classtable.BeaconofVirtue].ready then
    --    return classtable.BeaconofVirtue
    --end
    if (MaxDps:FindSpell(classtable.Consecration) and CheckSpellCosts(classtable.Consecration, 'Consecration')) and (not buff[classtable.Consecration].up and C_Spell.IsSpellInRange(classtable.CrusaderStrike, 'target')) and cooldown[classtable.Consecration].ready then
        return classtable.Consecration
    end
    if (MaxDps:FindSpell(classtable.HammerofWrath) and CheckSpellCosts(classtable.HammerofWrath, 'HammerofWrath')) and cooldown[classtable.HammerofWrath].ready then
        return classtable.HammerofWrath
    end
    if (MaxDps:FindSpell(classtable.Judgment) and CheckSpellCosts(classtable.Judgment, 'Judgment')) and cooldown[classtable.Judgment].ready then
        return classtable.Judgment
    end
    if (MaxDps:FindSpell(classtable.HolyShock) and CheckSpellCosts(classtable.HolyShock, 'HolyShock')) and cooldown[classtable.HolyShock].ready then
        return classtable.HolyShock
    end
    if (MaxDps:FindSpell(classtable.CrusaderStrike) and CheckSpellCosts(classtable.CrusaderStrike, 'CrusaderStrike')) and (cooldown[classtable.HolyShock].remains >gcd) and cooldown[classtable.CrusaderStrike].ready then
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
