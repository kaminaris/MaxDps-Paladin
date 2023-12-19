
local _, addonTable = ...

--- @type MaxDps
if not MaxDps then return end

local Paladin = addonTable.Paladin
local MaxDps = MaxDps
local UnitPower = UnitPower
local UnitHealth = UnitHealth
local UnitAura = UnitAura
local GetSpellDescription = GetSpellDescription
local UnitHealthMax = UnitHealthMax
local UnitPowerMax = UnitPowerMax
local HolyPower = Enum.PowerType.HolyPower

local fd
local cooldown
local buff
local debuff
local talents
local targets
local holyPower
local targetHP
local targetmaxHP
local targethealthPerc
local curentHP
local maxHP
local healthPerc

local className, classFilename, classId = UnitClass('player')
local currentSpec = GetSpecialization()
local currentSpecName = currentSpec and select(2, GetSpecializationInfo(currentSpec)) or "None"
local classtable

function Paladin:Retribution()
    fd = MaxDps.FrameData
    cooldown = fd.cooldown
    buff = fd.buff
    debuff = fd.debuff
    talents = fd.talents
    targets = MaxDps:SmartAoe()
    holyPower = UnitPower('player', HolyPower)
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP / targetmaxHP) * 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    classtable = MaxDps.SpellTable
    classtable.DivineArbiterBuff = 406975
    classtable.EmpyreanLegacyBuff = 387178
    classtable.EmpyreanPowerBuff = 326733
    classtable.EchoesofWrathBuff = 423590
    classtable.ExpurgationDot = 383346
    classtable.TemplarSlash = 406647
    classtable.FinalVerdictBuff = 383329
    --setmetatable(classtable, Paladin.spellMeta)

	if talents[classtable.AvengingWrath] then
        MaxDps:GlowCooldown(classtable.AvengingWrath, cooldown[classtable.AvengingWrath].ready)
    end

    if targets > 1  then
        return Paladin:RetributionMultiTarget()
    end
    return Paladin:RetributionSingleTarget()
end

--optional abilities list
--Generators
--Spenders
--Cooldowns/Other
--Crusading Strikes
--Vanguard of Justice
--Avenging Wrath: Might
--Templar Strikes
--Empyrean Power
--Crusade
--Holy Blade
--Empyrean Legacy
--Execution Sentence
--Wake of Ashes
--Divine Arbiter
--Final Reckoning
--Divine Toll
--Consecrated Blade
--Tier 30 4pc Set Bonus
--Divine Hammer
--Tier 31 Set Bonus

--Single-Target Rotation
function Paladin:RetributionSingleTarget()
    ----Cast Avenging Wrath.
    --if talents[classtable.AvengingWrath] and cooldown[classtable.AvengingWrath].ready then
    --    return classtable.AvengingWrath
    --end
    --Cast Crusade if you have at least 4 Holy Power.
    if talents[classtable.Crusade] and holyPower >= 4 and cooldown[classtable.Crusade].ready then
        return classtable.Crusade
    end
    --Cast Execution Sentence.
    if talents[classtable.ExecutionSentence] and cooldown[classtable.ExecutionSentence].ready then
        return classtable.ExecutionSentence
    end
    --Cast Final Reckoning if you have at least 4 Holy Power.
    if talents[classtable.FinalReckoning] and holyPower >= 4 and cooldown[classtable.FinalReckoning].ready then
        return classtable.FinalReckoning
    end
    --Cast Divine Storm if you have an Empyrean Power proc and 5 Holy Power.
    if talents[classtable.DivineStorm] and talents[classtable.EmpyreanPower] and buff[classtable.EmpyreanPowerBuff].up and holyPower >= 5 and cooldown[classtable.DivineStorm].ready then
        return classtable.DivineStorm
    end
    --Cast Final Verdict if you have 5 Holy Power or Echoes of Wrath active.
    if talents[classtable.FinalVerdict] and (holyPower >= 5 or (buff[classtable.EchoesofWrathBuff].up and holyPower >= 4)) and cooldown[classtable.FinalVerdict].ready then
        return classtable.FinalVerdict
    end
    --Cast Wake of Ashes if you have 2 or less Holy Power.
    if talents[classtable.WakeofAshes] and holyPower <= 2 and cooldown[classtable.WakeofAshes].ready then
        return classtable.WakeofAshes
    end
    --Cast Blade of Justice if Expurgation is not active on your target.
    if MaxDps.tier and MaxDps.tier[31].count >= 2 and talents[classtable.BladeofJustice] and (talents[classtable.Expurgation] and not debuff[classtable.ExpurgationDot].up) and cooldown[classtable.BladeofJustice].ready then
        return classtable.BladeofJustice
    end
    --Cast Divine Toll if you have 3 or less Holy Power.
    if talents[classtable.DivineToll] and holyPower <= 3 and cooldown[classtable.DivineToll].ready then
        return classtable.DivineToll
    end
    --Cast Judgment.
    if cooldown[classtable.Judgment].ready then
        return classtable.Judgment
    end
    --Cast Hammer of Wrath if your target is above 20% health, or if you have 3 or less Holy Power.
    if talents[classtable.HammerofWrath] and ((targethealthPerc < 20 or buff[classtable.AvengingWrath].up or (talents[classtable.FinalVerdict] and buff[classtable.FinalVerdictBuff].up)) and holyPower <= 4) and cooldown[classtable.HammerofWrath].ready then
        return classtable.HammerofWrath
    end
    --Cast Templar Slash if it will expire within a GCD.
    if MaxDps:FindSpell(classtable.TemplarStrike) and cooldown[classtable.TemplarStrike].ready then
        return classtable.TemplarStrike
    end
    if talents[classtable.TemplarStrikes] and MaxDps:FindSpell(classtable.TemplarSlash) and cooldown[classtable.TemplarSlash].ready then
        return classtable.TemplarSlash
    end
	--if talents[classtable.TemplarStrikes] and cooldown[classtable.TemplarSlash].ready and MaxDps.Spells[classtable.TemplarSlash] then
	--	return classtable.TemplarSlash
	--end
	--if talents[classtable.TemplarStrikes] and cooldown[classtable.TemplarStrike].charges >= 1 and MaxDps.Spells[classtable.TemplarStrike] then
	--	return classtable.TemplarStrike
	--end
    --Cast Blade of Justice.
    if (talents[classtable.BladeofJustice] and not talents[classtable.HolyBlade] and cooldown[classtable.BladeofJustice].ready) or (talents[classtable.BladeofJustice] and talents[classtable.HolyBlade] and holyPower <= 3 and cooldown[classtable.BladeofJustice].ready) then
        return classtable.BladeofJustice
    end
    --Cast Divine Storm if you have an Empyrean Power proc.
    if talents[classtable.DivineStorm] and talents[classtable.EmpyreanPower] and buff[classtable.EmpyreanPowerBuff].up and cooldown[classtable.DivineStorm].ready then
        return classtable.DivineStorm
    end
	if not talents[classtable.TemplarStrikes] and not talents[classtable.CrusadingStrikes] and cooldown[classtable.CrusaderStrike].count == 2 and cooldown[classtable.CrusaderStrike].ready then
		return classtable.CrusaderStrike
	end
    --Cast Final Verdict with 4 Holy Power.
    if talents[classtable.FinalVerdict] and ((talents[classtable.VanguardofJustice] and holyPower == 4) or (not talents[classtable.VanguardofJustice] and (holyPower == 3 or holyPower == 4))) and cooldown[classtable.FinalVerdict].ready then
        return classtable.FinalVerdict
    end
	if not talents[classtable.TemplarStrikes] and not talents[classtable.CrusadingStrikes] and cooldown[classtable.CrusaderStrike].ready then
		return classtable.CrusaderStrike
	end
    --Cast Templar Strikes or Templar Slash.
    if talents[classtable.TemplarStrikes] and (MaxDps:FindSpell(classtable.TemplarStrikes) and cooldown[classtable.TemplarStrikes].ready) or (MaxDps:FindSpell(classtable.TemplarSlash) and cooldown[classtable.TemplarSlash].ready) then
        return (MaxDps:FindSpell(classtable.TemplarStrikes) and classtable.TemplarStrikes) or (MaxDps:FindSpell(classtable.TemplarSlash) and classtable.TemplarSlash)
    end
    --Cast Divine Hammer.
    if talents[classtable.DivineHammer] and cooldown[classtable.DivineHammer].ready then
        return classtable.DivineHammer
    end
    if not talents[classtable.ConsecratedBlade] and not talents[classtable.DivineHammer] and cooldown[classtable.Consecration].ready then
        return classtable.Consecration
    end
end

--Multi-Target Rotation
function Paladin:RetributionMultiTarget()
    ----Cast Avenging Wrath.
    --if talents[classtable.AvengingWrath] and cooldown[classtable.AvengingWrath].ready then
    --    return classtable.AvengingWrath
    --end
    --Cast Crusade if you have at least 4 Holy Power.
    if talents[classtable.Crusade] and holyPower >= 4 and cooldown[classtable.Crusade].ready then
        return classtable.Crusade
    end
    --Cast Execution Sentence.
    if talents[classtable.ExecutionSentence] and cooldown[classtable.ExecutionSentence].ready then
        return classtable.ExecutionSentence
    end
    --Cast Final Reckoning if you have at least 4 Holy Power.
    if talents[classtable.FinalReckoning] and holyPower >= 4 and cooldown[classtable.FinalReckoning].ready then
        return classtable.FinalReckoning
    end
    --Cast Final Verdict if you have 25 stacks of Divine Arbiter or Empyrean Legacy active and 5 Holy Power.
    if talents[classtable.FinalVerdict] and (buff[classtable.DivineArbiterBuff].count >= 25 or (talents[classtable.EmpyreanLegacy] and buff[classtable.EmpyreanLegacyBuff].up and holyPower == 5)) and cooldown[classtable.FinalVerdict].ready then
        return classtable.FinalVerdict
    end
    --Cast Divine Storm if you have 5 Holy Power or Echoes of Wrath active.
    if talents[classtable.DivineStorm] and (holyPower >= 5 or (buff[classtable.EchoesofWrathBuff].up and holyPower >= 4)) and cooldown[classtable.DivineStorm].ready then
        return classtable.DivineStorm
    end
    --Cast Wake of Ashes if you have 2 or less Holy Power.
    if talents[classtable.WakeofAshes] and holyPower <= 2 and cooldown[classtable.WakeofAshes].ready then
        return classtable.WakeofAshes
    end
    --Cast Blade of Justice if Expurgation is not active on your target.
    if MaxDps.tier and MaxDps.tier[31].count >= 2 and talents[classtable.BladeofJustice] and (talents[classtable.Expurgation] and not debuff[classtable.ExpurgationDot].up) and cooldown[classtable.BladeofJustice].ready then
        return classtable.BladeofJustice
    end
    --Cast Divine Toll if you have 1 or less Holy Power.
    if talents[classtable.DivineToll] and holyPower <= 1 and cooldown[classtable.DivineToll].ready then
        return classtable.DivineToll
    end
    if MaxDps.tier and MaxDps.tier[30].count >= 4 then
        --Cast Blade of Justice if you have 4 or more targets.
        if talents[classtable.BladeofJustice] and targets >= 4 and cooldown[classtable.BladeofJustice].ready then
            return classtable.BladeofJustice
        end
        --Cast Hammer of Wrath if your target is above 20% health, or if you have 3 or less Holy Power.
        if talents[classtable.HammerofWrath] and ((targethealthPerc < 20 or buff[classtable.AvengingWrath].up or (talents[classtable.FinalVerdict] and buff[classtable.FinalVerdictBuff].up)) and holyPower <= 4) and cooldown[classtable.HammerofWrath].ready then
            return classtable.HammerofWrath
        end
    end
    --Cast Judgment.
    if cooldown[classtable.Judgment].ready then
        return classtable.Judgment
    end
    --Cast Templar Slash if it will expire within a GCD.
    --if MaxDps:FindSpell(classtable.TemplarStrike) and cooldown[classtable.TemplarStrike].ready then
    --    return classtable.TemplarStrike
    --end
    --if talents[classtable.TemplarStrikes] and MaxDps:FindSpell(classtable.TemplarSlash) and cooldown[classtable.TemplarSlash].ready then
    --    return classtable.TemplarSlash
    --end
	if talents[classtable.TemplarStrikes] and cooldown[classtable.TemplarSlash].ready and MaxDps.Spells[classtable.TemplarSlash] then
		return classtable.TemplarSlash
	end
	if talents[classtable.TemplarStrikes] and cooldown[classtable.TemplarStrike].charges >= 1 and MaxDps.Spells[classtable.TemplarStrike] then
		return classtable.TemplarStrike
	end
    --Cast Blade of Justice if you have 4 or more targets.
    if (talents[classtable.BladeofJustice] and not talents[classtable.HolyBlade] and targets >= 4 and cooldown[classtable.BladeofJustice].ready) or (talents[classtable.BladeofJustice] and talents[classtable.HolyBlade] and holyPower <= 3 and targets >= 4 and cooldown[classtable.BladeofJustice].ready) then
        return classtable.BladeofJustice
    end
	if not talents[classtable.TemplarStrikes] and not talents[classtable.CrusadingStrikes] and cooldown[classtable.CrusaderStrike].count == 2 and cooldown[classtable.CrusaderStrike].ready then
		return classtable.CrusaderStrike
	end
    --Cast Divine Storm if you have an Empyrean Power proc.
    if talents[classtable.DivineStorm] and talents[classtable.EmpyreanPower] and buff[classtable.EmpyreanPowerBuff].up and cooldown[classtable.DivineStorm].ready then
        return classtable.DivineStorm
    end
    --Cast Final Verdict if you have 25 stacks of Divine Arbiter or Empyrean Legacy active and 4 Holy Power.
    if talents[classtable.FinalVerdict] and (buff[classtable.DivineArbiterBuff].count >= 25 or (talents[classtable.EmpyreanLegacy] and buff[classtable.EmpyreanLegacyBuff].up and (talents[classtable.VanguardofJustice] and holyPower == 4) or ( not talents[classtable.VanguardofJustice] and holyPower >= 3))) and cooldown[classtable.FinalVerdict].ready then
        return classtable.FinalVerdict
    end
    --Cast Divine Storm with 4 Holy Power.
    if talents[classtable.DivineStorm] and ((talents[classtable.VanguardofJustice] and holyPower == 4) or (not talents[classtable.VanguardofJustice] and (holyPower == 3 or holyPower == 4))) and cooldown[classtable.DivineStorm].ready then
        return classtable.DivineStorm
    end
	if not talents[classtable.TemplarStrikes] and not talents[classtable.CrusadingStrikes] and cooldown[classtable.CrusaderStrike].ready then
		return classtable.CrusaderStrike
	end
    --Cast Templar Strikes or Templar Slash.
    if talents[classtable.TemplarStrikes] and (MaxDps:FindSpell(classtable.TemplarStrikes) and cooldown[classtable.TemplarStrikes].ready) or (MaxDps:FindSpell(classtable.TemplarSlash) and cooldown[classtable.TemplarSlash].ready) then
        return (MaxDps:FindSpell(classtable.TemplarStrikes) and classtable.TemplarStrikes) or (MaxDps:FindSpell(classtable.TemplarSlash) and classtable.TemplarSlash)
    end
    --Cast Divine Hammer.
    if talents[classtable.DivineHammer] and cooldown[classtable.DivineHammer].ready then
        return classtable.DivineHammer
    end
    if not talents[classtable.ConsecratedBlade] and not talents[classtable.DivineHammer] and cooldown[classtable.Consecration].ready then
        return classtable.Consecration
    end
end
