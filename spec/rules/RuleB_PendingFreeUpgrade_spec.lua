local luaunit = require("luaunit")
local loadAddonFile = dofile("spec/helpers/load_addon_file.lua")

local Greenlit

local function freshGreenlit()
	local g = {}
	loadAddonFile("src/Rules/RuleB_PendingFreeUpgrade.lua", "Greenlit", g)
	return g
end

TestRuleB = {}

function TestRuleB:setUp()
	Greenlit = freshGreenlit()
end

function TestRuleB:testNoHighWatermarkIsSilence()
	local candidate = { highWatermark = nil }
	local owned = { itemLevel = 300 }

	luaunit.assertNil(Greenlit.RuleB(candidate, owned))
end

function TestRuleB:testWatermarkAboveEquippedIsHold()
	local candidate = { highWatermark = 310 }
	local owned = { itemLevel = 300 }

	local result = Greenlit.RuleB(candidate, owned)

	luaunit.assertNotNil(result)
	luaunit.assertEquals(result.candidate, false)
	luaunit.assertEquals(result.rule, "RuleB")
end

function TestRuleB:testWatermarkEqualToEquippedIsSilence()
	local candidate = { highWatermark = 300 }
	local owned = { itemLevel = 300 }

	luaunit.assertNil(Greenlit.RuleB(candidate, owned))
end

function TestRuleB:testWatermarkBelowEquippedIsSilence()
	local candidate = { highWatermark = 290 }
	local owned = { itemLevel = 300 }

	luaunit.assertNil(Greenlit.RuleB(candidate, owned))
end

function TestRuleB:testNilOwnedItemLevelIsSilenceNotError()
	local candidate = { highWatermark = 310 }
	local owned = { itemLevel = nil }

	luaunit.assertNil(Greenlit.RuleB(candidate, owned))
end

os.exit(luaunit.LuaUnit.run())
