
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

function Paladin:Holy()
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
    --setmetatable(classtable, Paladin.spellMeta)

	if talents[classtable.AvengingWrath] and not talents[classtable.Sentinel] then
        MaxDps:GlowCooldown(classtable.AvengingWrath, cooldown[classtable.AvengingWrath].ready)
    end

    --if targets > 1  then
    --    return Paladin:HolyMultiTarget()
    --end
    return Paladin:HolySingleTarget()
end

--optional abilities list

--Single-Target Rotation
function Paladin:HolySingleTarget()
    --Keep Consecration on the ground. This is especially important in AoE situations.
    if cooldown[classtable.Consecration].ready then
        return classtable.Consecration
    end
    --Cast Shield of the Righteous if you have the Holy Power available to do so.
    if holyPower >= 3 and cooldown[classtable.ShieldoftheRighteous].ready then
        return classtable.ShieldoftheRighteous
    end
    --Cast Judgment off cooldown if using the Righteous Judgment talent.
    if talents[classtable.RighteousJudgment] and cooldown[classtable.Judgment].ready then
        return classtable.Judgment
    end
    --Cast Hammer of Wrath off cooldown.
    if talents[classtable.HammerofWrath] and (targethealthPerc < 20 or buff[classtable.AvengingWrath].up) and cooldown[classtable.HammerofWrath].ready then
        return classtable.HammerofWrath
    end
    --Cast Holy Shock off cooldown.
    if talents[classtable.HolyShock] and cooldown[classtable.HolyShock].ready then
        return classtable.HolyShock
    end
    --Use Crusader Strike if everything else is on cooldown.
    if cooldown[classtable.CrusaderStrike].ready then
        return classtable.CrusaderStrike
    end
end

--Multi-Target Rotation
function Paladin:HolyMultiTarget()

end
