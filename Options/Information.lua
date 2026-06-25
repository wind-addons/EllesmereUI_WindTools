local addon = select(2, ...)
local W = addon[1]
local E = addon[3]

addon.RegisterOptionBuilder("information", function(parent, y, cat)
	local MH = function(mod, sub) return addon.MakeHeader(cat, mod, sub) end
	local Widgets = EllesmereUI.Widgets
	local _, h

	_, h = Widgets:SectionHeader(parent, MH("WindTools"), y); y = y - h

	_, h = Widgets:Button(parent, "Version: " .. tostring(W.Version), y, function() end); y = y - h

	_, h = Widgets:SectionHeader(parent, MH("Help"), y); y = y - h

	_, h = Widgets:Button(parent, "GitHub Repository", y, function()
		if E.StaticPopup_Show then
			E:StaticPopup_Show("WINDTOOLS_EDITBOX", nil, nil, "https://github.com/wind-addons/ElvUI_WindTools")
		end
	end); y = y - h

	_, h = Widgets:Button(parent, "Report Issue", y, function()
		if E.StaticPopup_Show then
			E:StaticPopup_Show("WINDTOOLS_EDITBOX", nil, nil, "https://github.com/wind-addons/ElvUI_WindTools/issues")
		end
	end); y = y - h

	_, h = Widgets:Button(parent, "Wiki", y, function()
		if E.StaticPopup_Show then
			E:StaticPopup_Show("WINDTOOLS_EDITBOX", nil, nil, "https://github.com/wind-addons/ElvUI_WindTools/wiki")
		end
	end); y = y - h

	_, h = Widgets:SectionHeader(parent, MH("Credits"), y); y = y - h

	_, h = Widgets:Button(parent, "Author: fang2hou, XanaHopper", y, function() end); y = y - h

	return y
end)
