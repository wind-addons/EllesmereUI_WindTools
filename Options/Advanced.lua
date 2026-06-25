local addon = select(2, ...)
local W = addon[1]
local E = addon[3]
local DBGet = addon.DBGet
local DBSet = addon.DBSet
local DBGet2 = addon.DBGet2
local DBSet2 = addon.DBSet2

local LOG_LEVEL_VALUES = {
	[1] = "1 - ERROR", [2] = "2 - WARNING", [3] = "3 - INFO", [4] = "4 - DEBUG",
}
local LOG_LEVEL_ORDER = { 1, 2, 3, 4 }

addon.RegisterOptionBuilder("advanced", function(parent, y, cat)
	local MH = function(mod, sub) return addon.MakeHeader(cat, mod, sub) end
	local Widgets = EllesmereUI.Widgets
	local _, h
	local gdb = E.global.WT

	_, h = Widgets:SectionHeader(parent, MH("Core"), y); y = y - h
	do
		_, h = Widgets:Toggle(parent, "Login Message", y,
			function() return gdb.core and gdb.core.loginMessage end,
			function(v) gdb.core = gdb.core or {}; gdb.core.loginMessage = v end,
			"The message will be shown in chat when you first login."); y = y - h
		_, h = Widgets:Toggle(parent, "Changelog Popup", y,
			function() return gdb.core and gdb.core.changlogPopup end,
			function(v) gdb.core = gdb.core or {}; gdb.core.changlogPopup = v end,
			"Show the changelog popup rather than chat message after every update."); y = y - h
		_, h = Widgets:Toggle(parent, "ElvUI Version Popup", y,
			function() return gdb.core and gdb.core.elvUIVersionPopup end,
			function(v) gdb.core = gdb.core or {}; gdb.core.elvUIVersionPopup = v end,
			"Show the ElvUI version popup rather than chat message when ElvUI version is outdated."); y = y - h
		_, h = Widgets:Toggle(parent, "Compatibility Check", y,
			function() return gdb.core and gdb.core.compatibilityCheck end,
			function(v) gdb.core = gdb.core or {}; gdb.core.compatibilityCheck = v end,
			"Help you to enable/disable the modules for a better experience with other plugins."); y = y - h
	end

	_, h = Widgets:SectionHeader(parent, MH("Game Fix"), y); y = y - h
	do
		_, h = Widgets:Toggle(parent, "CVar Alert", y,
			function() return gdb.core and gdb.core.cvarAlert end,
			function(v) gdb.core = gdb.core or {}; gdb.core.cvarAlert = v end,
			"It will alert you to reload UI when you change the CVar ActionButtonUseKeyDown."); y = y - h
		_, h = Widgets:Toggle(parent, "Fix SetPassThroughButtons", y,
			function() return gdb.core and gdb.core.fixSetPassThroughButtons end,
			function(v) gdb.core = gdb.core or {}; gdb.core.fixSetPassThroughButtons = v end,
			"Fix the issue that sometimes SetPassThroughButtons got tainted."); y = y - h
	end

	_, h = Widgets:SectionHeader(parent, MH("Developer"), y); y = y - h
	do
		_, h = Widgets:Dropdown(parent, "Log Level", y,
			LOG_LEVEL_VALUES, LOG_LEVEL_ORDER,
			function() return gdb.developer and gdb.developer.logLevel end,
			function(v) gdb.developer = gdb.developer or {}; gdb.developer.logLevel = v end,
			"Only display log message that the level is higher than you choose."); y = y - h
		if gdb.developer and gdb.developer.tableAttributeDisplay then
			local tad = gdb.developer.tableAttributeDisplay
			_, h = Widgets:Toggle(parent, "Table Attribute Display", y,
				DBGet(tad, "enable"), DBSet(tad, "enable"),
				"Modify the debug tool that displays table attributes."); y = y - h
			_, h = Widgets:DualRow(parent, y,
				{ type = "slider", text = "Width", min = 0, max = 2000, step = 10,
				  getValue = DBGet(tad, "width"), setValue = DBSet(tad, "width") },
				{ type = "slider", text = "Height", min = 0, max = 2000, step = 10,
				  getValue = DBGet(tad, "height"), setValue = DBSet(tad, "height") }
			); y = y - h
		end
	end

	return y
end)
