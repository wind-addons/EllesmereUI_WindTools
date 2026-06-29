local addon = select(2, ...)
local W = addon[1]
local E = addon[3]
local DBGet = addon.DBGet
local DBSet = addon.DBSet
local DBGet2 = addon.DBGet2
local DBSet2 = addon.DBSet2
local FontSection = addon.FontSection

local ORIENTATION_VALUES = { HORIZONTAL = "Horizontal", VERTICAL = "Vertical" }
local ORIENTATION_ORDER = { "HORIZONTAL", "VERTICAL" }

local VISIBILITY_VALUES = { DEFAULT = "Default", INPARTY = "In Party", ALWAYS = "Always Display" }
local VISIBILITY_ORDER = { "DEFAULT", "INPARTY", "ALWAYS" }

local MODIFIER_VALUES = { shift = "Shift Key", ctrl = "Ctrl Key", alt = "Alt Key" }
local MODIFIER_ORDER = { "shift", "ctrl", "alt" }

local SOUND_CHANNEL_VALUES = {
	Master = "Master", SFX = "SFX", Music = "Music",
	Ambience = "Ambience", Dialog = "Dialog",
}
local SOUND_CHANNEL_ORDER = { "Master", "Music", "SFX", "Ambience", "Dialog" }

local function BuildRaidMarkers(parent, y, cat)
	local Widgets = EllesmereUI.Widgets
	local MH = function(mod, sub) return addon.MakeHeader(cat, mod, sub) end
	local _, h
	local rm = E.db.WT.combat.raidMarkers
	local rmDis = function() return not rm.enable end
	_, h = Widgets:SectionHeader(parent, MH("Raid Markers"), y); y = y - h
	_, h = Widgets:Toggle(parent, "Enable", y,
		DBGet(rm, "enable"), DBSet(rm, "enable"),
		"Toggle raid markers bar."); y = y - h
	_, h = Widgets:Toggle(parent, "Inverse Mode", y,
		DBGet(rm, "inverse"), DBSet(rm, "inverse"),
		"Swap the functionality of normal click and click with modifier keys.", rmDis); y = y - h
	_, h = Widgets:SectionHeader(parent, MH("Raid Markers", "Visibility"), y); y = y - h
	_, h = Widgets:Dropdown(parent, "Visibility", y,
		VISIBILITY_VALUES, VISIBILITY_ORDER,
		DBGet(rm, "visibility"), DBSet(rm, "visibility"), nil, rmDis); y = y - h
	_, h = Widgets:DualRow(parent, y,
		{ type = "toggle", text = "Mouse Over", tooltip = "Only show raid markers bar when you mouse over it.",
		  getValue = DBGet(rm, "mouseOver"), setValue = DBSet(rm, "mouseOver"), disabled = rmDis },
		{ type = "toggle", text = "Tooltip", tooltip = "Show the tooltip when you mouse over the button.",
		  getValue = DBGet(rm, "tooltip"), setValue = DBSet(rm, "tooltip"), disabled = rmDis }
	); y = y - h
	_, h = Widgets:Dropdown(parent, "Modifier Key", y,
		MODIFIER_VALUES, MODIFIER_ORDER,
		DBGet(rm, "modifier"), DBSet(rm, "modifier"),
		"Set the modifier key for placing world markers.", rmDis); y = y - h
	_, h = Widgets:SectionHeader(parent, MH("Raid Markers", "Bar"), y); y = y - h
	_, h = Widgets:Toggle(parent, "Bar Backdrop", y,
		DBGet(rm, "backdrop"), DBSet(rm, "backdrop"),
		"Show a backdrop of the bar.", rmDis); y = y - h
	_, h = Widgets:DualRow(parent, y,
		{ type = "slider", text = "Backdrop Spacing", min = 1, max = 30, step = 1,
		  getValue = DBGet(rm, "backdropSpacing"), setValue = DBSet(rm, "backdropSpacing"), disabled = rmDis },
		{ type = "dropdown", text = "Orientation",
		  values = ORIENTATION_VALUES, order = ORIENTATION_ORDER,
		  getValue = DBGet(rm, "orientation"), setValue = DBSet(rm, "orientation"), disabled = rmDis }
	); y = y - h
	_, h = Widgets:SectionHeader(parent, MH("Raid Markers", "Buttons"), y); y = y - h
	_, h = Widgets:Toggle(parent, "Ready Check / Advanced Combat Logging", y,
		DBGet(rm, "readyCheck"), DBSet(rm, "readyCheck"), nil, rmDis); y = y - h
	_, h = Widgets:DualRow(parent, y,
		{ type = "toggle", text = "Count Down",
		  getValue = DBGet(rm, "countDown"), setValue = DBSet(rm, "countDown"), disabled = rmDis },
		{ type = "slider", text = "Count Down Time", min = 1, max = 10, step = 1,
		  getValue = DBGet(rm, "countDownTime"), setValue = DBSet(rm, "countDownTime"),
		  tooltip = "Count down time in seconds.", disabled = rmDis }
	); y = y - h
	_, h = Widgets:SectionHeader(parent, MH("Raid Markers", "Button Layout"), y); y = y - h
	_, h = Widgets:DualRow(parent, y,
		{ type = "slider", text = "Button Size", min = 15, max = 60, step = 1,
		  getValue = DBGet(rm, "buttonSize"), setValue = DBSet(rm, "buttonSize"), disabled = rmDis },
		{ type = "slider", text = "Button Spacing", min = 1, max = 30, step = 1,
		  getValue = DBGet(rm, "spacing"), setValue = DBSet(rm, "spacing"), disabled = rmDis }
	); y = y - h
	_, h = Widgets:DualRow(parent, y,
		{ type = "toggle", text = "Button Backdrop",
		  getValue = DBGet(rm, "buttonBackdrop"), setValue = DBSet(rm, "buttonBackdrop"), disabled = rmDis },
		{ type = "toggle", text = "Button Animation",
		  getValue = DBGet(rm, "buttonAnimation"), setValue = DBSet(rm, "buttonAnimation"), disabled = rmDis }
	); y = y - h
	if rm.buttonAnimation then
		_, h = Widgets:DualRow(parent, y,
			{ type = "slider", text = "Animation Duration", min = 0.01, max = 2, step = 0.01,
			  getValue = DBGet(rm, "buttonAnimationDuration"), setValue = DBSet(rm, "buttonAnimationDuration"), disabled = rmDis },
			{ type = "slider", text = "Animation Scale", min = 0.01, max = 5, step = 0.01,
			  getValue = DBGet(rm, "buttonAnimationScale"), setValue = DBSet(rm, "buttonAnimationScale"), disabled = rmDis }
		); y = y - h
	end
	return y
end

local function BuildCombatAlert(parent, y, cat)
	local Widgets = EllesmereUI.Widgets
	local MH = function(mod, sub) return addon.MakeHeader(cat, mod, sub) end
	local _, h
	local ca = E.db.WT.combat.combatAlert
	local caDis = function() return not ca.enable end
	_, h = Widgets:SectionHeader(parent, MH("Combat Alert"), y); y = y - h
	_, h = Widgets:Toggle(parent, "Enable", y,
		DBGet(ca, "enable"), DBSet(ca, "enable"),
		"This module will display a alert frame when entering and leaving combat."); y = y - h
	_, h = Widgets:DualRow(parent, y,
		{ type = "slider", text = "Speed", min = 0.1, max = 4, step = 0.01,
		  getValue = DBGet(ca, "speed"), setValue = DBSet(ca, "speed"),
		  tooltip = "The speed of the alert.", disabled = caDis },
		{ type = "spacer" }
	); y = y - h
	_, h = Widgets:SectionHeader(parent, MH("Combat Alert", "Animation"), y); y = y - h
	_, h = Widgets:DualRow(parent, y,
		{ type = "toggle", text = "Enable", tooltip = "Display an animation when you enter or leave combat.",
		  getValue = DBGet2(ca, "animationConfig", "animation"),
		  setValue = DBSet2(ca, "animationConfig", "animation"), disabled = caDis },
		{ type = "slider", text = "Animation Size", min = 0.1, max = 3, step = 0.01,
		  getValue = DBGet2(ca, "animationConfig", "animationSize"),
		  setValue = DBSet2(ca, "animationConfig", "animationSize"), disabled = caDis }
	); y = y - h
	_, h = Widgets:SectionHeader(parent, MH("Combat Alert", "Text"), y); y = y - h
	_, h = Widgets:Toggle(parent, "Enable", y,
		DBGet2(ca, "textConfig", "text"), DBSet2(ca, "textConfig", "text"),
		"Display a text when you enter or leave combat.", caDis); y = y - h
	_, h = Widgets:SectionHeader(parent, MH("Combat Alert", "Enter Text"), y); y = y - h
	_, h = Widgets:ColorPicker(parent, "Gradient Color 1", y,
		function() local c = ca.enterColor.left or {}; return c.r or 1, c.g or 0, c.b or 0, 1 end,
		function(r, g, b) ca.enterColor.left = ca.enterColor.left or {}; ca.enterColor.left.r, ca.enterColor.left.g, ca.enterColor.left.b = r, g, b end,
		false); y = y - h
	_, h = Widgets:ColorPicker(parent, "Gradient Color 2", y,
		function() local c = ca.enterColor.right or {}; return c.r or 1, c.g or 1, c.b or 0, 1 end,
		function(r, g, b) ca.enterColor.right = ca.enterColor.right or {}; ca.enterColor.right.r, ca.enterColor.right.g, ca.enterColor.right.b = r, g, b end,
		false); y = y - h
	_, h = Widgets:SectionHeader(parent, MH("Combat Alert", "Leave Text"), y); y = y - h
	_, h = Widgets:ColorPicker(parent, "Gradient Color 1", y,
		function() local c = ca.leaveColor.left or {}; return c.r or 0, c.g or 1, c.b or 0, 1 end,
		function(r, g, b) ca.leaveColor.left = ca.leaveColor.left or {}; ca.leaveColor.left.r, ca.leaveColor.left.g, ca.leaveColor.left.b = r, g, b end,
		false); y = y - h
	_, h = Widgets:ColorPicker(parent, "Gradient Color 2", y,
		function() local c = ca.leaveColor.right or {}; return c.r or 0, c.g or 0, c.b or 1, 1 end,
		function(r, g, b) ca.leaveColor.right = ca.leaveColor.right or {}; ca.leaveColor.right.r, ca.leaveColor.right.g, ca.leaveColor.right.b = r, g, b end,
		false); y = y - h
	_, h = Widgets:SectionHeader(parent, MH("Combat Alert", "Font"), y); y = y - h
	y = FontSection(Widgets, parent, y, ca.font)
	_, h = Widgets:SectionHeader(parent, MH("Combat Alert", "Sound - Enter"), y); y = y - h
	_, h = Widgets:Toggle(parent, "Enable", y,
		DBGet2(ca, "enterSound", "enable"), DBSet2(ca, "enterSound", "enable")); y = y - h
	_, h = Widgets:Dropdown(parent, "Sound Channel", y,
		SOUND_CHANNEL_VALUES, SOUND_CHANNEL_ORDER,
		DBGet2(ca, "enterSound", "channel"), DBSet2(ca, "enterSound", "channel")); y = y - h
	_, h = Widgets:SectionHeader(parent, MH("Combat Alert", "Sound - Leave"), y); y = y - h
	_, h = Widgets:Toggle(parent, "Enable", y,
		DBGet2(ca, "leaveSound", "enable"), DBSet2(ca, "leaveSound", "enable")); y = y - h
	_, h = Widgets:Dropdown(parent, "Sound Channel", y,
		SOUND_CHANNEL_VALUES, SOUND_CHANNEL_ORDER,
		DBGet2(ca, "leaveSound", "channel"), DBSet2(ca, "leaveSound", "channel")); y = y - h
	return y
end

local function BuildQuickTools(parent, y, cat)
	local Widgets = EllesmereUI.Widgets
	local MH = function(mod, sub) return addon.MakeHeader(cat, mod, sub) end
	local _, h
	local db = E.db.WT.combat
	local pdb = E.private.WT.combat
	_, h = Widgets:SectionHeader(parent, MH("Destroy Totem"), y); y = y - h
	do
		local dt = pdb.destroyTotem
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(dt, "enable"), DBSet(dt, "enable"),
			"Use key bindings or macro to destroy your totems quickly."); y = y - h
	end
	_, h = Widgets:SectionHeader(parent, MH("Quick Keystone"), y); y = y - h
	do
		local qk = db.quickKeystone
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(qk, "enable"), DBSet(qk, "enable"),
			"Put the keystone from bag automatically."); y = y - h
	end
	return y
end

local function BuildDamageMeter(parent, y, cat)
	local Widgets = EllesmereUI.Widgets
	local MH = function(mod, sub) return addon.MakeHeader(cat, mod, sub) end
	local _, h
	local dl = E.db.WT.combat.damageMeterLayout
	local dlDis = function() return not dl.enable end
	_, h = Widgets:SectionHeader(parent, MH("Damage Meter Layout"), y); y = y - h
	_, h = Widgets:Toggle(parent, "Enable", y,
		DBGet(dl, "enable"), DBSet(dl, "enable"),
		"Manage Blizzard Damage Meter windows with reusable layouts."); y = y - h
	_, h = Widgets:SectionHeader(parent, MH("Damage Meter Layout", "Container"), y); y = y - h
	_, h = Widgets:DualRow(parent, y,
		{ type = "slider", text = "Width", min = 200, max = 1600, step = 1,
		  getValue = DBGet(dl, "width"), setValue = DBSet(dl, "width"), disabled = dlDis },
		{ type = "slider", text = "Height", min = 120, max = 1000, step = 1,
		  getValue = DBGet(dl, "height"), setValue = DBSet(dl, "height"), disabled = dlDis }
	); y = y - h
	_, h = Widgets:DualRow(parent, y,
		{ type = "toggle", text = "Backdrop",
		  getValue = DBGet(dl, "backdrop"), setValue = DBSet(dl, "backdrop"), disabled = dlDis },
		{ type = "toggle", text = "Shadow",
		  getValue = DBGet(dl, "shadow"), setValue = DBSet(dl, "shadow"), disabled = dlDis }
	); y = y - h
	_, h = Widgets:DualRow(parent, y,
		{ type = "toggle", text = "Animation", tooltip = "Fade in/out the damage meters when switching layouts.",
		  getValue = DBGet2(dl, "animation", "enable"), setValue = DBSet2(dl, "animation", "enable"), disabled = dlDis },
		{ type = "slider", text = "Animation Duration", min = 0, max = 2, step = 0.01,
		  getValue = DBGet2(dl, "animation", "duration"), setValue = DBSet2(dl, "animation", "duration"), disabled = dlDis }
	); y = y - h
	_, h = Widgets:SectionHeader(parent, MH("Damage Meter Layout", "Auto Switch"), y); y = y - h
	_, h = Widgets:Toggle(parent, "Enable", y,
		DBGet2(dl, "autoSwitch", "enable"), DBSet2(dl, "autoSwitch", "enable"),
		"Automatically switch damage meter layouts based on different combat scenarios.", dlDis); y = y - h
	return y
end

addon.RegisterOptionBuilder("combat", function(parent, y, cat, subPage)
	if     subPage == "Raid Markers"  then return BuildRaidMarkers(parent, y, cat)
	elseif subPage == "Combat Alert"  then return BuildCombatAlert(parent, y, cat)
	elseif subPage == "Quick Tools"   then return BuildQuickTools(parent, y, cat)
	elseif subPage == "Damage Meter"  then return BuildDamageMeter(parent, y, cat)
	end
	return y
end)
