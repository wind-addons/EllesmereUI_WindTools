local addon = select(2, ...)
local W = addon[1]
local E = addon[3]
local DBGet = addon.DBGet
local DBSet = addon.DBSet
local DBGet2 = addon.DBGet2
local DBSet2 = addon.DBSet2
local FontSection = addon.FontSection

local ORIENTATION_VALUES = { NOANCHOR = "Drag", HORIZONTAL = "Horizontal", VERTICAL = "Vertical" }
local ORIENTATION_ORDER = { "NOANCHOR", "HORIZONTAL", "VERTICAL" }

local TEXT_ALIGN_VALUES = { LEFT = "Left", CENTER = "Center", RIGHT = "Right" }
local TEXT_ALIGN_ORDER = { "LEFT", "CENTER", "RIGHT" }

local function BuildSuperTracker(parent, y, cat)
	local Widgets = EllesmereUI.Widgets
	local MH = function(mod, sub) return addon.MakeHeader(cat, mod, sub) end
	local _, h
	local st = E.private.WT.maps.superTracker
	local stDis = function() return not st.enable end
	_, h = Widgets:SectionHeader(parent, MH("Super Tracker"), y); y = y - h
	_, h = Widgets:Toggle(parent, "Enable", y,
		DBGet(st, "enable"), DBSet(st, "enable"),
		"Additional features for waypoint."); y = y - h
	_, h = Widgets:DualRow(parent, y,
		{ type = "toggle", text = "Auto Track Waypoint", tooltip = "Auto track the waypoint after setting.",
		  getValue = DBGet(st, "autoTrackWaypoint"), setValue = DBSet(st, "autoTrackWaypoint"), disabled = stDis },
		{ type = "toggle", text = "Middle Click To Clear", tooltip = "Middle click the waypoint to clear it.",
		  getValue = DBGet(st, "middleClickToClear"), setValue = DBSet(st, "middleClickToClear"), disabled = stDis }
	); y = y - h
	_, h = Widgets:DualRow(parent, y,
		{ type = "toggle", text = "No Distance Limitation", tooltip = "Force to track the target even if it over 1000 yds.",
		  getValue = DBGet(st, "noLimit"), setValue = DBSet(st, "noLimit"), disabled = stDis },
		{ type = "toggle", text = "No Unit", tooltip = "Remove the unit in distance text.",
		  getValue = DBGet(st, "noUnit"), setValue = DBSet(st, "noUnit"), disabled = stDis }
	); y = y - h
	_, h = Widgets:SectionHeader(parent, MH("Super Tracker", "Distance Text"), y); y = y - h
	y = FontSection(Widgets, parent, y, st.distanceText)
	_, h = Widgets:SectionHeader(parent, MH("Super Tracker", "Waypoint Parse"), y); y = y - h
	_, h = Widgets:Toggle(parent, "Enable", y,
		DBGet2(st, "waypointParse", "enable"), DBSet2(st, "waypointParse", "enable")); y = y - h
	_, h = Widgets:DualRow(parent, y,
		{ type = "toggle", text = "Input Box", tooltip = "Add a input box to the world map.",
		  getValue = DBGet2(st, "waypointParse", "worldMapInput"),
		  setValue = DBSet2(st, "waypointParse", "worldMapInput") },
		{ type = "toggle", text = "Command", tooltip = "Enable to use the command to set the waypoint.",
		  getValue = DBGet2(st, "waypointParse", "command"),
		  setValue = DBSet2(st, "waypointParse", "command") }
	); y = y - h
	return y
end

local function BuildMinimap(parent, y, cat)
	local Widgets = EllesmereUI.Widgets
	local MH = function(mod, sub) return addon.MakeHeader(cat, mod, sub) end
	local _, h
	local db = E.db.WT.maps
	local pdb = E.private.WT.maps
	_, h = Widgets:SectionHeader(parent, MH("Rectangle Minimap"), y); y = y - h
	do
		local rm = db.rectangleMinimap
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(rm, "enable"), DBSet(rm, "enable"),
			"Change the shape of ElvUI minimap."); y = y - h
		_, h = Widgets:Slider(parent, "Height Percentage", y, 0.01, 1, 0.01,
			DBGet(rm, "heightPercentage"), DBSet(rm, "heightPercentage"),
			"Percentage of ElvUI minimap size."); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Fix HereBeDragons", tooltip = "Fix pins added by HereBeDragons to hide correctly on rectangular minimaps.",
			  getValue = DBGet(rm, "fixHereBeDragons"), setValue = DBSet(rm, "fixHereBeDragons") },
			{ type = "slider", text = "Pin Hiding Tolerance", min = 0, max = 100, step = 1,
			  getValue = DBGet(rm, "pinHidingTolerance"), setValue = DBSet(rm, "pinHidingTolerance"),
			  tooltip = "Prevents pins from appearing outside the rectangular minimap boundaries." }
		); y = y - h
	end
	_, h = Widgets:SectionHeader(parent, MH("Minimap Buttons"), y); y = y - h
	do
		local mb = pdb.minimapButtons
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(mb, "enable"), DBSet(mb, "enable"),
			"Toggle minimap buttons bar."); y = y - h
		_, h = Widgets:Toggle(parent, "Mouse Over", y,
			DBGet(mb, "mouseOver"), DBSet(mb, "mouseOver"),
			"Only show minimap buttons bar when you mouse over it."); y = y - h
		_, h = Widgets:SectionHeader(parent, MH("Minimap Buttons", "Bar"), y); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Bar Backdrop", tooltip = "Show a backdrop of the bar.",
			  getValue = DBGet(mb, "backdrop"), setValue = DBSet(mb, "backdrop") },
			{ type = "slider", text = "Backdrop Spacing", min = 0, max = 30, step = 1,
			  getValue = DBGet(mb, "backdropSpacing"), setValue = DBSet(mb, "backdropSpacing") }
		); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Inverse Direction", tooltip = "Reverse the direction of adding buttons.",
			  getValue = DBGet(mb, "inverseDirection"), setValue = DBSet(mb, "inverseDirection") },
			{ type = "toggle", text = "Reverse Order", tooltip = "Reverse the sort order of buttons.",
			  getValue = DBGet(mb, "reverseOrder"), setValue = DBSet(mb, "reverseOrder") }
		); y = y - h
		_, h = Widgets:Dropdown(parent, "Orientation", y,
			ORIENTATION_VALUES, ORIENTATION_ORDER,
			DBGet(mb, "orientation"), DBSet(mb, "orientation"),
			"Arrangement direction of the bar."); y = y - h
	end
	return y
end

local function BuildWorldMap(parent, y, cat)
	local Widgets = EllesmereUI.Widgets
	local MH = function(mod, sub) return addon.MakeHeader(cat, mod, sub) end
	local _, h
	local wm = E.private.WT.maps.worldMap
	_, h = Widgets:SectionHeader(parent, MH("World Map"), y); y = y - h
	_, h = Widgets:Toggle(parent, "Enable", y,
		DBGet(wm, "enable"), DBSet(wm, "enable"),
		"This module will help you to reveal and resize maps."); y = y - h
	_, h = Widgets:SectionHeader(parent, MH("World Map", "Reveal"), y); y = y - h
	_, h = Widgets:Toggle(parent, "Enable", y,
		DBGet2(wm, "reveal", "enable"), DBSet2(wm, "reveal", "enable"),
		"Remove Fog of War from your world map."); y = y - h
	_, h = Widgets:Toggle(parent, "Use Colored Fog", y,
		DBGet2(wm, "reveal", "useColor"), DBSet2(wm, "reveal", "useColor"),
		"Style Fog of War with special color."); y = y - h
	_, h = Widgets:SectionHeader(parent, MH("World Map", "Scale"), y); y = y - h
	_, h = Widgets:Toggle(parent, "Enable", y,
		DBGet2(wm, "scale", "enable"), DBSet2(wm, "scale", "enable"),
		"Resize world map."); y = y - h
	_, h = Widgets:Slider(parent, "Size", y, 0.1, 3, 0.01,
		DBGet2(wm, "scale", "size"), DBSet2(wm, "scale", "size")); y = y - h
	return y
end

local function BuildDifficultyEvents(parent, y, cat)
	local Widgets = EllesmereUI.Widgets
	local MH = function(mod, sub) return addon.MakeHeader(cat, mod, sub) end
	local _, h
	local pdb = E.private.WT.maps
	local db = E.db.WT.maps
	_, h = Widgets:SectionHeader(parent, MH("Instance Difficulty"), y); y = y - h
	do
		local id = pdb.instanceDifficulty
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(id, "enable"), DBSet(id, "enable"),
			"Reskin the instance difficulty in text style."); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "dropdown", text = "Text Align",
			  values = TEXT_ALIGN_VALUES, order = TEXT_ALIGN_ORDER,
			  getValue = DBGet(id, "align"), setValue = DBSet(id, "align") },
			{ type = "toggle", text = "Hide Blizzard Indicator",
			  getValue = DBGet(id, "hideBlizzard"), setValue = DBSet(id, "hideBlizzard") }
		); y = y - h
		y = FontSection(Widgets, parent, y, id.font)
		_, h = Widgets:Toggle(parent, "Custom Difficulty Strings", y,
			DBGet2(id, "difficulty", "custom"), DBSet2(id, "difficulty", "custom")); y = y - h
	end
	_, h = Widgets:SectionHeader(parent, MH("Event Tracker"), y); y = y - h
	do
		local et = db.eventTracker
		_, h = Widgets:Toggle(parent, "Enable", y,
			function() return et.enable end,
			function(v) et.enable = v end,
			"Add trackers for world events in the bottom of world map."); y = y - h
		_, h = Widgets:SectionHeader(parent, MH("Event Tracker", "Panel Style"), y); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Backdrop", tooltip = "Show a backdrop of the trackers.",
			  getValue = function() return et.panel and et.panel.backdrop end,
			  setValue = function(v) et.panel = et.panel or {}; et.panel.backdrop = v end },
			{ type = "slider", text = "Width", min = 50, max = 500, step = 1,
			  getValue = function() return et.panel and et.panel.trackerWidth end,
			  setValue = function(v) et.panel = et.panel or {}; et.panel.trackerWidth = v end }
		); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "slider", text = "Height", min = 2, max = 100, step = 1,
			  getValue = function() return et.panel and et.panel.trackerHeight end,
			  setValue = function(v) et.panel = et.panel or {}; et.panel.trackerHeight = v end },
			{ type = "spacer" }
		); y = y - h
	end
	return y
end

addon.RegisterOptionBuilder("maps", function(parent, y, cat, subPage)
	if     subPage == "Super Tracker"     then return BuildSuperTracker(parent, y, cat)
	elseif subPage == "Minimap"           then return BuildMinimap(parent, y, cat)
	elseif subPage == "World Map"         then return BuildWorldMap(parent, y, cat)
	elseif subPage == "Difficulty & Events" then return BuildDifficultyEvents(parent, y, cat)
	end
	return y
end)
