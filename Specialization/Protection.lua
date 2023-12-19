
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

function Paladin:Protection()
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
    classtable.ConsecrationBuff = 188370
    --setmetatable(classtable, Paladin.spellMeta)

	if talents[classtable.AvengingWrath] and not talents[classtable.Sentinel] then
        MaxDps:GlowCooldown(classtable.AvengingWrath, cooldown[classtable.AvengingWrath].ready)
    end

	if talents[classtable.Sentinel] then
        MaxDps:GlowCooldown(classtable.Sentinel, cooldown[classtable.Sentinel].ready)
    end

    if targets > 2  then
        return Paladin:ProtectionMultiTarget()
    end
    return Paladin:ProtectionSingleTarget()
end

--optional abilities list

--Single-Target Rotation
function Paladin:ProtectionSingleTarget()
	--Cast Consecration IF you are not standing in it.
    if not buff[classtable.ConsecrationBuff].up and cooldown[classtable.Consecration].ready then
        return classtable.Consecration
    end
	--Cast Shield of the Righteous when you are at 3-5 Holy Power to prevent overcapping on Holy Power.
    if holyPower >= 3 and  cooldown[classtable.ShieldoftheRighteous].ready then
        return classtable.ShieldoftheRighteous
    end
	--Cast Judgment.
    if cooldown[classtable.Judgment].ready then
        return classtable.Judgment
    end
	--Cast Hammer of Wrath.
    if talents[classtable.HammerofWrath] and ((targethealthPerc < 20 or (buff[classtable.AvengingWrath].up or buff[classtable.Sentinel].up)) and holyPower <= 4) and cooldown[classtable.HammerofWrath].ready then
        return classtable.HammerofWrath
    end
	--Cast Avenger's Shield.
    if talents[classtable.AvengersShield] and cooldown[classtable.AvengersShield].ready then
        return classtable.AvengersShield
    end
	--Cast Hammer of the Righteous/Blessed Hammer.
    if talents[classtable.HammeroftheRighteous] and cooldown[classtable.HammeroftheRighteous].ready then
        return classtable.HammeroftheRighteous
    end
    if talents[classtable.BlessedHammer] and cooldown[classtable.BlessedHammer].ready then
        return classtable.BlessedHammer
    end
	--Refresh Consecration if everything else is on cooldown.
	if cooldown[classtable.Consecration].ready then
		return classtable.Consecration
	end
end

--Multi-Target Rotation
function Paladin:ProtectionMultiTarget()
	--Cast Consecration IF you are not standing in it.
    if not buff[classtable.ConsecrationBuff].up and cooldown[classtable.Consecration].ready then
        return classtable.Consecration
    end
	--Cast Shield of the Righteous when you are at 3-5 Holy Power to prevent overcapping on Holy Power.
    if holyPower >= 3 and  cooldown[classtable.ShieldoftheRighteous].ready then
        return classtable.ShieldoftheRighteous
    end
	--Cast Avenger's Shield.
    if talents[classtable.AvengersShield] and cooldown[classtable.AvengersShield].ready then
        return classtable.AvengersShield
    end
	--Cast Judgment.
    if cooldown[classtable.Judgment].ready then
        return classtable.Judgment
    end
	--Cast Hammer of Wrath.
    if talents[classtable.HammerofWrath] and ((targethealthPerc < 20 or (buff[classtable.AvengingWrath].up or buff[classtable.Sentinel].up)) and holyPower <= 4) and cooldown[classtable.HammerofWrath].ready then
        return classtable.HammerofWrath
    end
	--Cast Hammer of the Righteous/Blessed Hammer.
    if talents[classtable.HammeroftheRighteous] and cooldown[classtable.HammeroftheRighteous].ready then
        return classtable.HammeroftheRighteous
    end
    if talents[classtable.BlessedHammer] and cooldown[classtable.BlessedHammer].ready then
        return classtable.BlessedHammer
    end
	--Refresh Consecration if everything else is on cooldown.
	if cooldown[classtable.Consecration].ready then
		return classtable.Consecration
	end
end
