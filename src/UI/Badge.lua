local addonName, Greenlit = ...

local function GetOrCreateBadge(itemButton)
	if not itemButton.GreenlitBadge then
		local badge = itemButton:CreateTexture(nil, "OVERLAY")
		badge:SetPoint("TOPLEFT", itemButton, "TOPLEFT", 2, -2)
		badge:SetSize(14, 14)
		itemButton.GreenlitBadge = badge
	end
	return itemButton.GreenlitBadge
end

local function ApplyBadge(itemButton, evaluation)
	local badge = GetOrCreateBadge(itemButton)

	if not evaluation then
		badge:Hide()
		return
	end

	local color = evaluation.candidate and Greenlit.colors.vendor or Greenlit.colors.hold
	badge:SetColorTexture(color[1], color[2], color[3], 0.9)
	badge:Show()
end

hooksecurefunc(ContainerFrameMixin, "UpdateItems", function(self)
	for _, itemButton in self:EnumerateValidItems() do
		local key = Greenlit.Cache.ContainerKeyFor(itemButton:GetBagID(), itemButton:GetID())
		ApplyBadge(itemButton, Greenlit.RuleEngine.lastResults[key])
	end
end)
