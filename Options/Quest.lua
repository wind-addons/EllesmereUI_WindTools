local addon = select(2, ...)
local W = addon[1]
local E = addon[3]
local DBGet = addon.DBGet
local DBSet = addon.DBSet
local DBGet2 = addon.DBGet2
local DBSet2 = addon.DBSet2
local FontSection = addon.FontSection

local COLLAPSE_VALUES = { none = "Do Nothing", collapse = "Collapse", expand = "Expand", hide = "Hide" }
local COLLAPSE_ORDER = { "none", "collapse", "expand", "hide" }

local TURNIN_MODE = { ALL = "Accept and Complete", ACCEPT = "Only Accept", COMPLETE = "Only Complete" }
local TURNIN_MODE_ORDER = { "ALL", "ACCEPT", "COMPLETE" }

local TURNIN_MODIFIER = {
	ANY = "Any", ALT = "Alt Key", CTRL = "Ctrl Key", SHIFT = "Shift Key", NONE = "None",
}
local TURNIN_MODIFIER_ORDER = { "ANY", "ALT", "CTRL", "SHIFT", "NONE" }

addon.RegisterOptionBuilder("quest", function(parent, y)
	local Widgets = EllesmereUI.Widgets
	local _, h
	local db = E.db.WT.quest
	local pdb = E.private.WT.quest

	_, h = Widgets:SectionHeader(parent, "OBJECTIVE TRACKER", y); y = y - h
	do
		local ot = pdb.objectiveTracker
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(ot, "enable"), DBSet(ot, "enable"),
			"Customize the font of Objective Tracker and add colorful progress text."); y = y - h

		_, h = Widgets:SectionHeader(parent, "Progress", y); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "No Dash",
			  getValue = DBGet(ot, "noDash"), setValue = DBSet(ot, "noDash") },
			{ type = "toggle", text = "Colorful Progress",
			  getValue = DBGet(ot, "colorfulProgress"), setValue = DBSet(ot, "colorfulProgress") }
		); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Percentage",
			  getValue = DBGet(ot, "percentage"), setValue = DBSet(ot, "percentage") },
			{ type = "toggle", text = "Colorful Percentage",
			  getValue = DBGet(ot, "colorfulPercentage"), setValue = DBSet(ot, "colorfulPercentage") }
		); y = y - h

		_, h = Widgets:SectionHeader(parent, "Header", y); y = y - h
		y = FontSection(Widgets, parent, y, ot.header)
		if ot.header then
			_, h = Widgets:DualRow(parent, y,
				{ type = "toggle", text = "Short Header",
				  getValue = DBGet2(ot, "header", "shortHeader"), setValue = DBSet2(ot, "header", "shortHeader") },
				{ type = "toggle", text = "Uppercase",
				  getValue = DBGet2(ot, "header", "uppercase"), setValue = DBSet2(ot, "header", "uppercase") }
			); y = y - h
		end
	end

	_, h = Widgets:SectionHeader(parent, "AUTO COLLAPSE", y); y = y - h
	do
		local ac = db.autoCollapse
		local acDis = function() return not ac.enable end
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(ac, "enable"), DBSet(ac, "enable"),
			"Automatically collapse/expand/hide the objective tracker based on conditions."); y = y - h
		_, h = Widgets:Toggle(parent, "Ignore Manual Toggle", y,
			DBGet(ac, "ignoreManualToggle"), DBSet(ac, "ignoreManualToggle"),
			"When enabled, manual expand or collapse actions will be ignored.", acDis); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "dropdown", text = "In Combat",
			  values = COLLAPSE_VALUES, order = COLLAPSE_ORDER,
			  getValue = DBGet(ac, "combat"), setValue = DBSet(ac, "combat"), disabled = acDis },
			{ type = "dropdown", text = "In Vehicle",
			  values = COLLAPSE_VALUES, order = COLLAPSE_ORDER,
			  getValue = DBGet(ac, "vehicle"), setValue = DBSet(ac, "vehicle"), disabled = acDis }
		); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "dropdown", text = "Resting",
			  values = COLLAPSE_VALUES, order = COLLAPSE_ORDER,
			  getValue = DBGet(ac, "resting"), setValue = DBSet(ac, "resting"), disabled = acDis },
			{ type = "dropdown", text = "Out of Instance",
			  values = COLLAPSE_VALUES, order = COLLAPSE_ORDER,
			  getValue = DBGet(ac, "outOfInstance"), setValue = DBSet(ac, "outOfInstance"), disabled = acDis }
		); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "dropdown", text = "Battleground",
			  values = COLLAPSE_VALUES, order = COLLAPSE_ORDER,
			  getValue = DBGet(ac, "battleground"), setValue = DBSet(ac, "battleground"), disabled = acDis },
			{ type = "dropdown", text = "Arena",
			  values = COLLAPSE_VALUES, order = COLLAPSE_ORDER,
			  getValue = DBGet(ac, "arena"), setValue = DBSet(ac, "arena"), disabled = acDis }
		); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "dropdown", text = "Dungeon",
			  values = COLLAPSE_VALUES, order = COLLAPSE_ORDER,
			  getValue = DBGet(ac, "dungeon"), setValue = DBSet(ac, "dungeon"), disabled = acDis },
			{ type = "dropdown", text = "Raid",
			  values = COLLAPSE_VALUES, order = COLLAPSE_ORDER,
			  getValue = DBGet(ac, "raid"), setValue = DBSet(ac, "raid"), disabled = acDis }
		); y = y - h
	end

	_, h = Widgets:SectionHeader(parent, "SWITCH BUTTONS", y); y = y - h
	do
		local sb = db.switchButtons
		local sbDis = function() return not sb.enable end
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(sb, "enable"), DBSet(sb, "enable"),
			"Add a bar that contains buttons to enable/disable modules quickly."); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Hide With Objective Tracker",
			  getValue = DBGet(sb, "hideWithObjectiveTracker"), setValue = DBSet(sb, "hideWithObjectiveTracker"), disabled = sbDis },
			{ type = "toggle", text = "Tooltip",
			  getValue = DBGet(sb, "tooltip"), setValue = DBSet(sb, "tooltip"), disabled = sbDis }
		); y = y - h
		_, h = Widgets:Toggle(parent, "Bar Backdrop", y,
			DBGet(sb, "backdrop"), DBSet(sb, "backdrop"), nil, sbDis); y = y - h
	end

	_, h = Widgets:SectionHeader(parent, "PROGRESS", y); y = y - h
	do
		local qp = db.progress
		local qpDis = function() return not qp.enable end
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(qp, "enable"), DBSet(qp, "enable"),
			"Display colorful quest progress information to replace Blizzard's default."); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Scenario", tooltip = "Enable scenario progress tracking.",
			  getValue = DBGet(qp, "scenario"), setValue = DBSet(qp, "scenario"), disabled = qpDis },
			{ type = "toggle", text = "Disable In Mythic+", tooltip = "Disable the progress message in Mythic+ dungeons.",
			  getValue = DBGet(qp, "disableInMythicPlus"), setValue = DBSet(qp, "disableInMythicPlus"), disabled = qpDis }
		); y = y - h
		_, h = Widgets:Slider(parent, "Disable If Required Over", y, 1, 2000, 1,
			DBGet(qp, "disableIfRequiredOver"), DBSet(qp, "disableIfRequiredOver"),
			"Disable the progress message if the required number of objectives is over this value.", qpDis); y = y - h
	end

	_, h = Widgets:SectionHeader(parent, "TURN IN", y); y = y - h
	do
		local ti = db.turnIn
		local tiDis = function() return not ti.enable end
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(ti, "enable"), DBSet(ti, "enable"),
			"Make quest acceptance and completion automatically."); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "dropdown", text = "Mode",
			  values = TURNIN_MODE, order = TURNIN_MODE_ORDER,
			  getValue = DBGet(ti, "mode"), setValue = DBSet(ti, "mode"), disabled = tiDis },
			{ type = "dropdown", text = "Pause On Press", tooltip = "Pause the automation by pressing a modifier key.",
			  values = TURNIN_MODIFIER, order = TURNIN_MODIFIER_ORDER,
			  getValue = DBGet(ti, "pauseModifier"), setValue = DBSet(ti, "pauseModifier"), disabled = tiDis }
		); y = y - h
		_, h = Widgets:SectionHeader(parent, "Automation Conditions", y); y = y - h
		local ec = ti.enableCondition
		if ec then
			_, h = Widgets:DualRow(parent, y,
				{ type = "toggle", text = "Account Completed", tooltip = "Enable automation for the quests already completed on any character in your account.",
				  getValue = DBGet(ec, "accountCompleted"), setValue = DBSet(ec, "accountCompleted"), disabled = tiDis },
				{ type = "toggle", text = "Daily Quests",
				  getValue = DBGet(ec, "daily"), setValue = DBSet(ec, "daily"), disabled = tiDis }
			); y = y - h
			_, h = Widgets:DualRow(parent, y,
				{ type = "toggle", text = "Weekly Quests",
				  getValue = DBGet(ec, "weekly"), setValue = DBSet(ec, "weekly"), disabled = tiDis },
				{ type = "toggle", text = "PvP Quests",
				  getValue = DBGet(ec, "pvp"), setValue = DBSet(ec, "pvp"), disabled = tiDis }
			); y = y - h
		end
	end

	_, h = Widgets:SectionHeader(parent, "PREY HUNT", y); y = y - h
	do
		local ph = db.preyHunt
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(ph, "enable"), DBSet(ph, "enable"),
			"Additional UI enhancements for Prey Hunt."); y = y - h
	end

	_, h = Widgets:SectionHeader(parent, "ACHIEVEMENT SCREENSHOT", y); y = y - h
	do
		local as = db.achievementScreenshot
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(as, "enable"), DBSet(as, "enable"),
			"Screenshot after you earned an achievement automatically."); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Hide Combat Alert", tooltip = "Hide combat alert frame when taking screenshot.",
			  getValue = DBGet(as, "hideCombatAlert"), setValue = DBSet(as, "hideCombatAlert") },
			{ type = "toggle", text = "Ignore Earned Before", tooltip = "Ignore achievements already earned by other characters on this account.",
			  getValue = DBGet(as, "ignoreEarnedBefore"), setValue = DBSet(as, "ignoreEarnedBefore") }
		); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Force Show UI", tooltip = "Force show UI which may be hidden by other addons before taking screenshot.",
			  getValue = DBGet(as, "forceShowUI"), setValue = DBSet(as, "forceShowUI") },
			{ type = "toggle", text = "Chat Message", tooltip = "Show a chat message when a screenshot is taken.",
			  getValue = DBGet(as, "chatMessage"), setValue = DBSet(as, "chatMessage") }
		); y = y - h
	end

	_, h = Widgets:SectionHeader(parent, "ACHIEVEMENT TRACKER", y); y = y - h
	do
		local at = db.achievementTracker
		local atDis = function() return not at.enable end
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(at, "enable"), DBSet(at, "enable"),
			"Show an enhanced achievement tracker with filtering and detailed progress information."); y = y - h
		_, h = Widgets:Toggle(parent, "Tooltip", y,
			DBGet(at, "tooltip"), DBSet(at, "tooltip"),
			"Show tips when hovering over the achievements.", atDis); y = y - h
		if at.size then
			_, h = Widgets:DualRow(parent, y,
				{ type = "slider", text = "Width", min = 400, max = 1200, step = 1,
				  getValue = DBGet2(at, "size", "width"), setValue = DBSet2(at, "size", "width"), disabled = atDis },
				{ type = "slider", text = "Height", min = 100, max = 800, step = 1,
				  getValue = DBGet2(at, "size", "height"), setValue = DBSet2(at, "size", "height"), disabled = atDis }
			); y = y - h
		end
	end

	return y
end)
