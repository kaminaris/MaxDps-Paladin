local addonName, addonTable = ...
_G[addonName] = addonTable

if not MaxDps then return end

--- @type  MaxDps
local MaxDps = MaxDps
local Paladin = MaxDps:NewModule('Paladin')
addonTable.Paladin = Paladin

Paladin.spellMeta = {
	__index = function(t, k)
		print('Spell Key ' .. k .. ' not found!')
	end
}

-- additional comment
function Paladin:Enable()
	if MaxDps.Spec == 1 then
		MaxDps.NextSpell = Paladin.Holy
		MaxDps:Print(MaxDps.Colors.Info .. 'Paladin Holy', "info")
	elseif MaxDps.Spec == 2 then
		MaxDps.NextSpell = Paladin.Protection
		MaxDps:Print(MaxDps.Colors.Info .. 'Paladin Protection', "info")
	elseif MaxDps.Spec == 3 then
		MaxDps.NextSpell = Paladin.Retribution
		MaxDps:Print(MaxDps.Colors.Info .. 'Paladin Retribution', "info")
	else
		if MaxDps:IsCataWow() or MaxDps:IsClassicWow() then
			MaxDps.NextSpell = Paladin.Retribution
			MaxDps:Print(MaxDps.Colors.Info .. 'Paladin Retribution', "info")
		end
	end

	return true
end