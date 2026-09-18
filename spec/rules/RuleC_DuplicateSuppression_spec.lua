local luaunit = require("luaunit")
local loadAddonFile = dofile("spec/helpers/load_addon_file.lua")

local Greenlit

local function freshGreenlit()
	local g = {}
	loadAddonFile("src/Rules/RuleC_DuplicateSuppression.lua", "Greenlit", g)
	return g
end

TestRuleC = {}

function TestRuleC:setUp()
	Greenlit = freshGreenlit()
end

function TestRuleC:testFirstInGroupIsKept()
	luaunit.assertTrue(Greenlit.RuleC.ShouldKeep("INVTYPE_CHEST:Champion"))
end

function TestRuleC:testSecondInSameGroupIsNotKept()
	Greenlit.RuleC.ShouldKeep("INVTYPE_CHEST:Champion")

	luaunit.assertFalse(Greenlit.RuleC.ShouldKeep("INVTYPE_CHEST:Champion"))
end

function TestRuleC:testDifferentGroupIsIndependentlyKept()
	Greenlit.RuleC.ShouldKeep("INVTYPE_CHEST:Champion")

	luaunit.assertTrue(Greenlit.RuleC.ShouldKeep("INVTYPE_CHEST:Hero"))
end

function TestRuleC:testResetClearsClaims()
	Greenlit.RuleC.ShouldKeep("INVTYPE_CHEST:Champion")
	Greenlit.RuleC.Reset()

	luaunit.assertTrue(Greenlit.RuleC.ShouldKeep("INVTYPE_CHEST:Champion"))
end

os.exit(luaunit.LuaUnit.run())
