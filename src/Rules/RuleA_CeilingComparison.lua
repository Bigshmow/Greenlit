local addonName, Greenlit = ...

local function TrackOffset(trackName)
	local offset = 0
	local track = Greenlit.trackOrder[1]

	while track ~= trackName do
		local checkpoint = Greenlit.checkpoints[track]
		if not checkpoint then
			return nil
		end

		offset = offset + Greenlit.maxRank - checkpoint
		track = Greenlit.NextTrack(track)
	end

	return offset
end

local function AbsolutePosition(trackName, rank)
	local offset = TrackOffset(trackName)
	if not offset then
		return nil
	end

	return offset + rank
end

function Greenlit.RuleA(candidate, owned)
	local candidatePosition = AbsolutePosition(candidate.track, candidate.ceilingRank)
	local ownedPosition = AbsolutePosition(owned.track, owned.ceilingRank)

	if not candidatePosition or not ownedPosition then
		return nil
	end

	if candidatePosition < ownedPosition then
		return {
			candidate = true,
			reasons = { "Lower ceiling than an item already owned in this slot." },
			rule = "RuleA",
		}
	end

	return nil
end
