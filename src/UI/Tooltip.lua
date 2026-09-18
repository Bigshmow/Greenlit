local addonName, Greenlit = ...

hooksecurefunc(GameTooltip, "SetBagItem", function(self, bag, slot)
	local key = Greenlit.Cache.ContainerKeyFor(bag, slot)
	local evaluation = Greenlit.RuleEngine.lastResults[key]

	if not evaluation then
		return
	end

	local color = evaluation.candidate and Greenlit.colors.vendor or Greenlit.colors.hold
	local header = evaluation.candidate and "Greenlit: Vendor Candidate" or "Greenlit: Hold"

	self:AddLine(" ")
	self:AddLine(header, color[1], color[2], color[3])
	for _, reason in ipairs(evaluation.reasons) do
		self:AddLine(reason, 1, 1, 1, true)
	end
	self:Show()
end)
