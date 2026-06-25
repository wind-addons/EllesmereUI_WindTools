local addon = select(2, ...)
local W = addon[1]
local E = addon[3]
local DBGet = addon.DBGet
local DBSet = addon.DBSet
local DBGet2 = addon.DBGet2
local DBSet2 = addon.DBSet2
local GetLSMStatusbars = addon.GetLSMStatusbars

local MODIFIER_VALUES = { shift = "Shift Key", ctrl = "Ctrl Key", alt = "Alt Key" }
local MODIFIER_ORDER = { "shift", "ctrl", "alt" }

local BUTTON_VALUES = {
	BUTTON1 = "Left Button", BUTTON2 = "Right Button", BUTTON3 = "Middle Button",
	BUTTON4 = "Side Button 4", BUTTON5 = "Side Button 5",
}
local BUTTON_ORDER = { "BUTTON1", "BUTTON2", "BUTTON3", "BUTTON4", "BUTTON5" }

local MARK_VALUES = {
	[1] = "Star", [2] = "Circle", [3] = "Diamond", [4] = "Triangle",
	[5] = "Moon", [6] = "Square", [7] = "Cross", [8] = "Skull",
}
local MARK_ORDER = { 1, 2, 3, 4, 5, 6, 7, 8 }

addon.RegisterOptionBuilder("unitFrames", function(parent, y)
	local Widgets = EllesmereUI.Widgets
	local _, h
	local db = E.db.WT.unitFrames
	local pdb = E.private.WT.unitFrames

	_, h = Widgets:SectionHeader(parent, "QUICK FOCUS", y); y = y - h
	do
		local qf = pdb.quickFocus
		local qfDis = function() return not qf.enable end
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(qf, "enable"), DBSet(qf, "enable"),
			"Focus the target by modifier key + click."); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "dropdown", text = "Modifier Key",
			  values = MODIFIER_VALUES, order = MODIFIER_ORDER,
			  getValue = DBGet(qf, "modifier"), setValue = DBSet(qf, "modifier"), disabled = qfDis },
			{ type = "dropdown", text = "Button",
			  values = BUTTON_VALUES, order = BUTTON_ORDER,
			  getValue = DBGet(qf, "button"), setValue = DBSet(qf, "button"), disabled = qfDis }
		); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Set Mark", tooltip = "Set the raid marker on the quick focused target if possible.",
			  getValue = DBGet(qf, "setMark"), setValue = DBSet(qf, "setMark"), disabled = qfDis },
			{ type = "dropdown", text = "Mark",
			  values = MARK_VALUES, order = MARK_ORDER,
			  getValue = DBGet(qf, "markNumber"), setValue = DBSet(qf, "markNumber"), disabled = qfDis }
		); y = y - h
	end

	_, h = Widgets:SectionHeader(parent, "ABSORB", y); y = y - h
	do
		local ab = db.absorb
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(ab, "enable"), DBSet(ab, "enable"),
			"Modify the texture of the absorb bar."); y = y - h
		if ab.damageAbsorb then
			local da = ab.damageAbsorb
			_, h = Widgets:Toggle(parent, "Enable Texture Replacement", y,
				DBGet(da, "enable"), DBSet(da, "enable"),
				"Enable the replacing of ElvUI absorb bar textures."); y = y - h
			_, h = Widgets:Toggle(parent, "Blizzard Style", y,
				DBGet(da, "blizzardStyle"), DBSet(da, "blizzardStyle"),
				"Use the texture from Blizzard Raid Frames."); y = y - h
		end
	end

	_, h = Widgets:SectionHeader(parent, "ROLE ICON", y); y = y - h
	do
		local ri = db.roleIcon
		if ri then
			_, h = Widgets:Toggle(parent, "Enable", y,
				DBGet(ri, "enable"), DBSet(ri, "enable"),
				"Replace the role icon texture on unit frames."); y = y - h
		end
	end

	_, h = Widgets:SectionHeader(parent, "NAME CLIP", y); y = y - h
	do
		local nc = pdb.nameClip
		if nc then
			_, h = Widgets:Toggle(parent, "Enable", y,
				DBGet(nc, "enable"), DBSet(nc, "enable"),
				"Clip long names on unit frames to prevent text overflow."); y = y - h
		end
	end

	return y
end)
