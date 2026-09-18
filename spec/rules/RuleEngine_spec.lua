local luaunit = require("luaunit")
local loadAddonFile = dofile("spec/helpers/load_addon_file.lua")

local Greenlit

local function freshGreenlit()
	local g = {}
	loadAddonFile("src/Config.lua", "Greenlit", g)
	loadAddonFile("src/Cache.lua", "Greenlit", g)
	loadAddonFile("src/Rules/RuleA_CeilingComparison.lua", "Greenlit", g)
	loadAddonFile("src/Rules/RuleB_PendingFreeUpgrade.lua", "Greenlit", g)
	loadAddonFile("src/Rules/RuleC_DuplicateSuppression.lua", "Greenlit", g)
	loadAddonFile("src/Rules/RuleEngine.lua", "Greenlit", g)
	return g
end

TestRuleEngine = {}

function TestRuleEngine:setUp()
	Greenlit = freshGreenlit()
end

function TestRuleEngine:testNoOwnedItemIsSilence()
	Greenlit.Cache.items["container0:1"] = {
		track = "Champion", ceilingRank = 6, equipLoc = "INVTYPE_CHEST",
	}

	luaunit.assertNil(Greenlit.RuleEngine.Evaluate("container0:1"))
end

function TestRuleEngine:testEquippedItemNeverEvaluatesAgainstItself()
	Greenlit.Cache.items["equipped:5"] = {
		track = "Champion", ceilingRank = 6, equipLoc = "INVTYPE_CHEST", itemLevel = 300,
	}

	luaunit.assertNil(Greenlit.RuleEngine.Evaluate("equipped:5"))
end

function TestRuleEngine:testFallsThroughToRuleA()
	Greenlit.Cache.items["equipped:5"] = {
		track = "Hero", ceilingRank = 6, equipLoc = "INVTYPE_CHEST", itemLevel = 320,
	}
	Greenlit.Cache.items["container0:1"] = {
		track = "Champion", ceilingRank = 6, equipLoc = "INVTYPE_CHEST", itemLevel = 300,
	}

	local result = Greenlit.RuleEngine.Evaluate("container0:1")

	luaunit.assertNotNil(result)
	luaunit.assertEquals(result.candidate, true)
	luaunit.assertEquals(result.rule, "RuleA")
end

function TestRuleEngine:testRuleBTakesPriorityOverRuleA()
	-- Champion ceiling < Hero ceiling (Rule A would fire), but candidate's
	-- watermark beats what's equipped right now (Rule B should win instead).
	Greenlit.Cache.items["equipped:5"] = {
		track = "Hero", ceilingRank = 6, equipLoc = "INVTYPE_CHEST", itemLevel = 290,
	}
	Greenlit.Cache.items["container0:1"] = {
		track = "Champion", ceilingRank = 6, equipLoc = "INVTYPE_CHEST", itemLevel = 280, highWatermark = 300,
	}

	local result = Greenlit.RuleEngine.Evaluate("container0:1")

	luaunit.assertNotNil(result)
	luaunit.assertEquals(result.candidate, false)
	luaunit.assertEquals(result.rule, "RuleB")
end

function TestRuleEngine:testRuleCSuppressesSecondDuplicateBackToRuleA()
	Greenlit.Cache.items["equipped:5"] = {
		track = "Hero", ceilingRank = 6, equipLoc = "INVTYPE_CHEST", itemLevel = 290,
	}
	Greenlit.Cache.items["container0:1"] = {
		track = "Champion", ceilingRank = 6, equipLoc = "INVTYPE_CHEST", itemLevel = 280, highWatermark = 300,
	}
	Greenlit.Cache.items["container0:2"] = {
		track = "Champion", ceilingRank = 6, equipLoc = "INVTYPE_CHEST", itemLevel = 280, highWatermark = 300,
	}

	local results = Greenlit.RuleEngine.EvaluateAll()

	luaunit.assertEquals(results["container0:1"].rule, "RuleB")
	luaunit.assertEquals(results["container0:1"].candidate, false)

	luaunit.assertEquals(results["container0:2"].rule, "RuleA")
	luaunit.assertEquals(results["container0:2"].candidate, true)
end

function TestRuleEngine:testGroupWinnerIsDeterministicAcrossPasses()
	Greenlit.Cache.items["equipped:5"] = {
		track = "Hero", ceilingRank = 6, equipLoc = "INVTYPE_CHEST", itemLevel = 290,
	}
	Greenlit.Cache.items["container0:1"] = {
		track = "Champion", ceilingRank = 6, equipLoc = "INVTYPE_CHEST", itemLevel = 280, highWatermark = 300,
	}
	Greenlit.Cache.items["container0:2"] = {
		track = "Champion", ceilingRank = 6, equipLoc = "INVTYPE_CHEST", itemLevel = 280, highWatermark = 300,
	}

	local firstPass = Greenlit.RuleEngine.EvaluateAll()
	local secondPass = Greenlit.RuleEngine.EvaluateAll()

	luaunit.assertEquals(firstPass["container0:1"].rule, secondPass["container0:1"].rule)
	luaunit.assertEquals(firstPass["container0:2"].rule, secondPass["container0:2"].rule)
end

function TestRuleEngine:testNilTrackFallsBackToRuleBWithoutSuppression()
	Greenlit.Cache.items["equipped:5"] = {
		track = "Hero", ceilingRank = 6, equipLoc = "INVTYPE_CHEST", itemLevel = 290,
	}
	Greenlit.Cache.items["container0:1"] = {
		track = nil, ceilingRank = 6, equipLoc = "INVTYPE_CHEST", itemLevel = 280, highWatermark = 300,
	}

	local result = Greenlit.RuleEngine.Evaluate("container0:1")

	luaunit.assertNotNil(result)
	luaunit.assertEquals(result.rule, "RuleB")
end

function TestRuleEngine:testEvaluateAllExcludesEquippedKeys()
	Greenlit.Cache.items["equipped:5"] = {
		track = "Champion", ceilingRank = 6, equipLoc = "INVTYPE_CHEST", itemLevel = 300,
	}

	local results = Greenlit.RuleEngine.EvaluateAll()

	luaunit.assertNil(results["equipped:5"])
end

os.exit(luaunit.LuaUnit.run())
