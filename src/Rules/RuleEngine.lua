local addonName, Greenlit = ...

Greenlit.RuleEngine = {}
Greenlit.RuleEngine.lastResults = {}

function Greenlit.RuleEngine.Evaluate(key)
	local candidate = Greenlit.Cache.Get(key)
	if not candidate then
		return nil
	end

	local owned = Greenlit.Cache.GetEquipped(candidate.equipLoc)
	if not owned or owned == candidate then
		return nil
	end

	local ruleBResult = Greenlit.RuleB(candidate, owned)
	if ruleBResult then
		if not candidate.track then
			return ruleBResult
		end

		local groupKey = candidate.equipLoc .. ":" .. candidate.track
		if Greenlit.RuleC.ShouldKeep(groupKey) then
			return ruleBResult
		end
	end

	return Greenlit.RuleA(candidate, owned)
end

function Greenlit.RuleEngine.EvaluateAll()
	Greenlit.RuleC.Reset()

	local keys = {}
	for key in pairs(Greenlit.Cache.items) do
		if not key:match("^equipped:") then
			table.insert(keys, key)
		end
	end
	table.sort(keys)

	local results = {}
	for _, key in ipairs(keys) do
		results[key] = Greenlit.RuleEngine.Evaluate(key)
	end

	Greenlit.RuleEngine.lastResults = results
	return results
end
