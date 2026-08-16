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
		local function notAvailable() return true end
		_, h = Widgets:DualRow(parent, y,
			{ type="toggle", text="ElvUI Version Popup",
			  getValue=function() return gdb.core and gdb.core.elvUIVersionPopup end,
			  setValue=function(v) gdb.core = gdb.core or {}; gdb.core.elvUIVersionPopup = v end,
			  tooltip="Show the ElvUI version popup rather than chat message when ElvUI version is outdated.",
			  disabled=notAvailable, disabledTooltip="This feature is not available yet." },
			{ type="spacer" }
		); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type="toggle", text="Compatibility Check",
			  getValue=function() return gdb.core and gdb.core.compatibilityCheck end,
			  setValue=function(v) gdb.core = gdb.core or {}; gdb.core.compatibilityCheck = v end,
			  tooltip="Help you to enable/disable the modules for a better experience with other plugins.",
			  disabled=notAvailable, disabledTooltip="This feature is not available yet." },
			{ type="spacer" }
		); y = y - h
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
			local function tadDisabled() return true end
			_, h = Widgets:DualRow(parent, y,
				{ type = "toggle", text = "Table Attribute Display",
				  getValue = DBGet(tad, "enable"), setValue = DBSet(tad, "enable"),
				  tooltip = "Modify the debug tool that displays table attributes.",
				  disabled = tadDisabled, disabledTooltip = "This feature is not available yet." },
				{ type = "spacer" }
			); y = y - h
			_, h = Widgets:DualRow(parent, y,
				{ type = "slider", text = "Width", min = 0, max = 2000, step = 10,
				  getValue = DBGet(tad, "width"), setValue = DBSet(tad, "width"),
				  disabled = tadDisabled },
				{ type = "slider", text = "Height", min = 0, max = 2000, step = 10,
				  getValue = DBGet(tad, "height"), setValue = DBSet(tad, "height"),
				  disabled = tadDisabled }
			); y = y - h
		end
	end

	return y
end)
