return function(path, addonName, Greenlit)
	local chunk = assert(loadfile(path))
	chunk(addonName, Greenlit)
end
