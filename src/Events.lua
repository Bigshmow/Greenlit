local addonName, Greenlit = ...

local function TryCacheItem(key, itemID, itemLocation)
	local _, _, _, equipLoc = C_Item.GetItemInfoInstant(itemID)
	equipLoc = Greenlit.NormalizeEquipLoc(equipLoc)

	if not Greenlit.armorEquipLocs[equipLoc] then
		return
	end

	Greenlit.Cache.Request(key, itemID, itemLocation, equipLoc)
end

local function ScanContainer(bagID)
	for slot = 1, C_Container.GetContainerNumSlots(bagID) do
		local itemID = C_Container.GetContainerItemID(bagID, slot)
		if itemID then
			local itemLocation = ItemLocation:CreateFromBagAndSlot(bagID, slot)
			local key = Greenlit.Cache.ContainerKeyFor(bagID, slot)
			TryCacheItem(key, itemID, itemLocation)
		end
	end
end

local function ScanBags()
	for bagID = 0, NUM_BAG_SLOTS do
		ScanContainer(bagID)
	end
end

local function ScanBank()
	for _, bagID in ipairs(C_Bank.FetchPurchasedBankTabIDs(Enum.BankType.Character)) do
		ScanContainer(bagID)
	end
end

local EQUIP_SLOT_TO_EQUIP_LOC = {
	[INVSLOT_HEAD] = "INVTYPE_HEAD",
	[INVSLOT_SHOULDER] = "INVTYPE_SHOULDER",
	[INVSLOT_CHEST] = "INVTYPE_CHEST",
	[INVSLOT_WAIST] = "INVTYPE_WAIST",
	[INVSLOT_LEGS] = "INVTYPE_LEGS",
	[INVSLOT_FEET] = "INVTYPE_FEET",
	[INVSLOT_WRIST] = "INVTYPE_WRIST",
	[INVSLOT_HAND] = "INVTYPE_HAND",
	[INVSLOT_BACK] = "INVTYPE_CLOAK",
}

local function ScanEquipped()
	for equipmentSlot in pairs(EQUIP_SLOT_TO_EQUIP_LOC) do
		local itemLocation = ItemLocation:CreateFromEquipmentSlot(equipmentSlot)
		if C_Item.DoesItemExist(itemLocation) then
			local itemID = C_Item.GetItemID(itemLocation)
			local key = Greenlit.Cache.EquippedKeyFor(equipmentSlot)
			TryCacheItem(key, itemID, itemLocation)
		end
	end
end

local function OnEquipmentChanged(equipmentSlot, hasCurrent)
	local equipLoc = EQUIP_SLOT_TO_EQUIP_LOC[equipmentSlot]
	if not equipLoc then
		return
	end

	Greenlit.Cache.InvalidateSlot(equipLoc)

	if not hasCurrent then
		return
	end

	local itemLocation = ItemLocation:CreateFromEquipmentSlot(equipmentSlot)
	local itemID = C_Item.GetItemID(itemLocation)
	local key = Greenlit.Cache.EquippedKeyFor(equipmentSlot)
	TryCacheItem(key, itemID, itemLocation)
end

local function OnItemInfoReceived(itemID)
	local waiting = Greenlit.Cache.TakePending(itemID)
	if not waiting then
		return
	end

	for _, entry in ipairs(waiting) do
		Greenlit.Cache.Request(entry.key, itemID, entry.itemLocation, entry.equipLoc)
	end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eventFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
eventFrame:RegisterEvent("BANKFRAME_OPENED")
eventFrame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		ScanEquipped()
		ScanBags()
	elseif event == "BAG_UPDATE_DELAYED" then
		ScanBags()
	elseif event == "PLAYER_EQUIPMENT_CHANGED" then
		OnEquipmentChanged(...)
	elseif event == "GET_ITEM_INFO_RECEIVED" then
		OnItemInfoReceived(...)
	elseif event == "BANKFRAME_OPENED" or event == "PLAYERBANKSLOTS_CHANGED" then
		ScanBank()
	end

	Greenlit.RuleEngine.EvaluateAll()
end)
