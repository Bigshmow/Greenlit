local addonName, Greenlit = ...

Greenlit.trackOrder = { "Adventurer", "Veteran", "Champion", "Hero", "Myth" }

Greenlit.maxRank = 6

Greenlit.checkpoints = {
	Adventurer = 2,
	Veteran = 2,
	Champion = 2,
	Hero = 2,
}

Greenlit.colors = {
	vendor = { 0.8, 0.1, 0.1 },
	hold = { 0.1, 0.6, 0.9 },
}

Greenlit.armorEquipLocs = {
	INVTYPE_HEAD = true,
	INVTYPE_SHOULDER = true,
	INVTYPE_CHEST = true,
	INVTYPE_WAIST = true,
	INVTYPE_LEGS = true,
	INVTYPE_FEET = true,
	INVTYPE_WRIST = true,
	INVTYPE_HAND = true,
	INVTYPE_CLOAK = true,
}

function Greenlit.NormalizeEquipLoc(equipLoc)
	if equipLoc == "INVTYPE_ROBE" then
		return "INVTYPE_CHEST"
	end
	return equipLoc
end

function Greenlit.NextTrack(trackName)
	for i, name in ipairs(Greenlit.trackOrder) do
		if name == trackName then
			return Greenlit.trackOrder[i + 1]
		end
	end
	return nil
end
