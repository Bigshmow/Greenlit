local luaunit = require("luaunit")
local loadAddonFile = dofile("spec/helpers/load_addon_file.lua")

local Greenlit

local function freshGreenlit()
	local g = {}
	loadAddonFile("src/Config.lua", "Greenlit", g)
	loadAddonFile("src/Rules/RuleA_CeilingComparison.lua", "Greenlit", g)
	return g
end

TestRuleA = {}

function TestRuleA:setUp()
	Greenlit = freshGreenlit()
end

function TestRuleA:testLowerCeilingIsVendorCandidate()
	local candidate = { track = "Champion", ceilingRank = 6 }
	local owned = { track = "Hero", ceilingRank = 6 }

	local result = Greenlit.RuleA(candidate, owned)

	luaunit.assertNotNil(result)
	luaunit.assertEquals(result.candidate, true)
	luaunit.assertEquals(result.rule, "RuleA")
end

function TestRuleA:testHigherCeilingIsSilence()
	local candidate = { track = "Hero", ceilingRank = 6 }
	local owned = { track = "Champion", ceilingRank = 6 }

	luaunit.assertNil(Greenlit.RuleA(candidate, owned))
end

function TestRuleA:testSameTrackTieIsSilence()
	local candidate = { track = "Champion", ceilingRank = 6 }
	local owned = { track = "Champion", ceilingRank = 6 }

	luaunit.assertNil(Greenlit.RuleA(candidate, owned))
end

function TestRuleA:testCrossTrackCheckpointTieIsSilence()
	-- Champion 6/6 ties Hero 2/6 exactly, per Config.checkpoints.Champion = 2.
	-- If this ever fails, either the checkpoint table or the absolute-
	-- position math in RuleA has drifted from what DECISION_LOG.md says.
	local candidate = { track = "Hero", ceilingRank = 2 }
	local owned = { track = "Champion", ceilingRank = 6 }

	luaunit.assertNil(Greenlit.RuleA(candidate, owned))
end

function TestRuleA:testJustPastCheckpointIsVendorCandidate()
	local candidate = { track = "Hero", ceilingRank = 1 }
	local owned = { track = "Champion", ceilingRank = 6 }

	local result = Greenlit.RuleA(candidate, owned)

	luaunit.assertNotNil(result)
	luaunit.assertEquals(result.candidate, true)
end

function TestRuleA:testNilTrackIsSilenceNotError()
	local candidate = { track = nil, ceilingRank = 6 }
	local owned = { track = "Champion", ceilingRank = 6 }

	luaunit.assertNil(Greenlit.RuleA(candidate, owned))
end

function TestRuleA:testUnrecognizedTrackIsSilenceNotError()
	local candidate = { track = "SomeFutureTrackName", ceilingRank = 6 }
	local owned = { track = "Champion", ceilingRank = 6 }

	luaunit.assertNil(Greenlit.RuleA(candidate, owned))
end

function TestRuleA:testOwnedNilTrackIsSilenceNotError()
	local candidate = { track = "Champion", ceilingRank = 6 }
	local owned = { track = nil, ceilingRank = 6 }

	luaunit.assertNil(Greenlit.RuleA(candidate, owned))
end

os.exit(luaunit.LuaUnit.run())
