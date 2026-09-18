local addonName, Greenlit = ...

Greenlit.Cache = {
	items = {},
	pending = {},
}

local function ReadItemState(itemLocation, equipLoc)
	local upgradeInfo = C_Item.GetItemUpgradeInfo(itemLocation)
	if not upgradeInfo then
		return nil
	end

	local itemLevel = C_Item.GetDetailedItemLevelInfo(itemLocation)
	local highWatermark = C_ItemUpgrade.GetHighWatermarkForItem(itemLocation)

	return {
		track = upgradeInfo.trackString,
		rank = upgradeInfo.currentLevel,
		ceilingRank = upgradeInfo.maxLevel,
		itemLevel = itemLevel,
		highWatermark = highWatermark,
		equipLoc = equipLoc,
	}
end

function Greenlit.Cache.ContainerKeyFor(bagID, slot)
	return "container" .. bagID .. ":" .. slot
end

function Greenlit.Cache.EquippedKeyFor(equipmentSlot)
	return "equipped:" .. equipmentSlot
end

function Greenlit.Cache.Get(key)
	return Greenlit.Cache.items[key]
end

function Greenlit.Cache.GetEquipped(equipLoc)
	for key, item in pairs(Greenlit.Cache.items) do
		if item.equipLoc == equipLoc and key:match("^equipped:") then
			return item
		end
	end
	return nil
end

function Greenlit.Cache.Request(key, itemID, itemLocation, equipLoc)
	if not C_Item.IsItemDataCachedByID(itemID) then
		Greenlit.Cache.pending[itemID] = Greenlit.Cache.pending[itemID] or {}
		table.insert(Greenlit.Cache.pending[itemID], { key = key, itemLocation = itemLocation, equipLoc = equipLoc })
		return nil
	end

	local state = ReadItemState(itemLocation, equipLoc)
	if state then
		Greenlit.Cache.items[key] = state
	end
	return state
end

function Greenlit.Cache.TakePending(itemID)
	local waiting = Greenlit.Cache.pending[itemID]
	Greenlit.Cache.pending[itemID] = nil
	return waiting
end

function Greenlit.Cache.InvalidateSlot(equipLoc)
	for key, item in pairs(Greenlit.Cache.items) do
		if item.equipLoc == equipLoc then
			Greenlit.Cache.items[key] = nil
		end
	end
end
