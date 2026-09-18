local addonName, Greenlit = ...

function Greenlit.RuleB(candidate, owned)
	if not candidate.highWatermark or not owned.itemLevel then
		return nil
	end

	if candidate.highWatermark > owned.itemLevel then
		return {
			candidate = false,
			reasons = { "Could be upgraded for free/cheap past what's currently equipped." },
			rule = "RuleB",
		}
	end

	return nil
end
