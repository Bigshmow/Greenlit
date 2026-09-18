local luaunit = require("luaunit")
local loadAddonFile = dofile("spec/helpers/load_addon_file.lua")

local Greenlit

local function freshGreenlit()
	local g = {}
	loadAddonFile("src/Config.lua", "Greenlit", g)
	return g
end

TestConfig = {}

function TestConfig:setUp()
	Greenlit = freshGreenlit()
end

function TestConfig:testTrackOrder()
	luaunit.assertEquals(Greenlit.trackOrder, { "Adventurer", "Veteran", "Champion", "Hero", "Myth" })
end

function TestConfig:testMaxRank()
	luaunit.assertEquals(Greenlit.maxRank, 6)
end

function TestConfig:testEveryTrackExceptLastHasACheckpoint()
	for i, track in ipairs(Greenlit.trackOrder) do
		if i < #Greenlit.trackOrder then
			luaunit.assertNotNil(Greenlit.checkpoints[track])
		else
			luaunit.assertNil(Greenlit.checkpoints[track])
		end
	end
end

function TestConfig:testNextTrackWalksTheFullOrder()
	luaunit.assertEquals(Greenlit.NextTrack("Adventurer"), "Veteran")
	luaunit.assertEquals(Greenlit.NextTrack("Veteran"), "Champion")
	luaunit.assertEquals(Greenlit.NextTrack("Champion"), "Hero")
	luaunit.assertEquals(Greenlit.NextTrack("Hero"), "Myth")
end

function TestConfig:testNextTrackOfLastTrackIsNil()
	luaunit.assertNil(Greenlit.NextTrack("Myth"))
end

function TestConfig:testNormalizeEquipLocMergesRobeIntoChest()
	luaunit.assertEquals(Greenlit.NormalizeEquipLoc("INVTYPE_ROBE"), "INVTYPE_CHEST")
end

function TestConfig:testNormalizeEquipLocLeavesOthersUnchanged()
	luaunit.assertEquals(Greenlit.NormalizeEquipLoc("INVTYPE_CHEST"), "INVTYPE_CHEST")
	luaunit.assertEquals(Greenlit.NormalizeEquipLoc("INVTYPE_WEAPON"), "INVTYPE_WEAPON")
end

function TestConfig:testArmorEquipLocsIncludesAllNineArmorSlots()
	local expected = {
		"INVTYPE_HEAD", "INVTYPE_SHOULDER", "INVTYPE_CHEST", "INVTYPE_WAIST",
		"INVTYPE_LEGS", "INVTYPE_FEET", "INVTYPE_WRIST", "INVTYPE_HAND", "INVTYPE_CLOAK",
	}
	for _, equipLoc in ipairs(expected) do
		luaunit.assertTrue(Greenlit.armorEquipLocs[equipLoc])
	end
end

function TestConfig:testArmorEquipLocsExcludesNonArmorSlots()
	local excluded = {
		"INVTYPE_FINGER", "INVTYPE_TRINKET", "INVTYPE_NECK",
		"INVTYPE_WEAPON", "INVTYPE_SHIELD", "INVTYPE_HOLDABLE", "INVTYPE_ROBE",
	}
	for _, equipLoc in ipairs(excluded) do
		luaunit.assertNil(Greenlit.armorEquipLocs[equipLoc])
	end
end

os.exit(luaunit.LuaUnit.run())
