local addonName, Greenlit = ...

Greenlit.RuleC = {
	claimedGroups = {},
}

function Greenlit.RuleC.Reset()
	Greenlit.RuleC.claimedGroups = {}
end

function Greenlit.RuleC.ShouldKeep(groupKey)
	if Greenlit.RuleC.claimedGroups[groupKey] then
		return false
	end

	Greenlit.RuleC.claimedGroups[groupKey] = true
	return true
end
