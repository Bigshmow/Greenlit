local addonName, Greenlit = ...

Greenlit.name = addonName

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(self, event, loadedAddonName)
	if event == "ADDON_LOADED" and loadedAddonName == addonName then
		self:UnregisterEvent("ADDON_LOADED")
	end
end)

SLASH_GREENLIT1 = "/greenlit"
SlashCmdList["GREENLIT"] = function()
	print("|cff33ff99Greenlit|r: rescan not implemented yet.")
end
