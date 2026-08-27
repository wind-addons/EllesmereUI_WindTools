local addon = select(2, ...)
local W = addon[1]
local E = addon[3]
local DBGet = addon.DBGet
local DBSet = addon.DBSet
local DBGet2 = addon.DBGet2
local DBSet2 = addon.DBSet2

local MODIFIER_VALUES = { shift = "Shift Key", ctrl = "Ctrl Key", alt = "Alt Key" }
local MODIFIER_ORDER = { "shift", "ctrl", "alt" }

local BUTTON_VALUES = {
	BUTTON1 = "Left Button", BUTTON2 = "Right Button", BUTTON3 = "Middle Button",
	BUTTON4 = "Side Button 4", BUTTON5 = "Side Button 5",
}
local BUTTON_ORDER = { "BUTTON1", "BUTTON2", "BUTTON3", "BUTTON4", "BUTTON5" }

local function UpdateQuickFocus()
	addon.SafeModuleCall(W.Modules.QuickFocus, "ProfileUpdate")
end

local function ToggleQuickFocus()
	UpdateQuickFocus()
	if addon.RefreshOptions then
		addon.RefreshOptions()
	end
end

-- Absorb / Role Icon / Name Clip modules are not ported to EllesmereUI yet;
-- their options render disabled on the merged Unit Frames page (matching the
-- original category layout: one page, module groups inline).
local NOT_PORTED = function() return true end

local MARK_VALUES = {
	[1] = "Star", [2] = "Circle", [3] = "Diamond", [4] = "Triangle",
	[5] = "Moon", [6] = "Square", [7] = "Cross", [8] = "Skull",
}
local MARK_ORDER = { 1, 2, 3, 4, 5, 6, 7, 8 }

local function BuildQuickFocus(parent, y, cat)
	local MH = function(mod, sub) return addon.MakeHeader(cat, mod, sub) end
	local Widgets = EllesmereUI.Widgets
	local _, h
	local qf = E.private.WT.unitFrames.quickFocus
	local qfDis = function() return not qf.enable end
	_, h = Widgets:SectionHeader(parent, MH("Quick Focus"), y); y = y - h
	_, h = Widgets:Toggle(parent, "Enable", y,
		DBGet(qf, "enable"), DBSet(qf, "enable", ToggleQuickFocus),
		"Focus the mouseover unit with a modifier key + mouse button."); y = y - h
	_, h = Widgets:DualRow(parent, y,
		{ type = "dropdown", text = "Modifier Key",
		  values = MODIFIER_VALUES, order = MODIFIER_ORDER,
		  getValue = DBGet(qf, "modifier"), setValue = DBSet(qf, "modifier", UpdateQuickFocus), disabled = qfDis },
		{ type = "dropdown", text = "Button",
		  values = BUTTON_VALUES, order = BUTTON_ORDER,
		  getValue = DBGet(qf, "button"), setValue = DBSet(qf, "button", UpdateQuickFocus), disabled = qfDis }
	); y = y - h
	_, h = Widgets:DualRow(parent, y,
		{ type = "toggle", text = "Set Mark", tooltip = "Set the raid marker on the quick focused target if possible.",
		  getValue = DBGet(qf, "setMark"), setValue = DBSet(qf, "setMark", UpdateQuickFocus), disabled = qfDis },
		{ type = "dropdown", text = "Mark",
		  values = MARK_VALUES, order = MARK_ORDER,
		  getValue = DBGet(qf, "markNumber"), setValue = DBSet(qf, "markNumber", UpdateQuickFocus), disabled = qfDis }
	); y = y - h
	return y
end

local function BuildAbsorb(parent, y, cat)
	local MH = function(mod, sub) return addon.MakeHeader(cat, mod, sub) end
	local Widgets = EllesmereUI.Widgets
	local _, h
	local ab = E.db.WT.unitFrames.absorb
	_, h = Widgets:SectionHeader(parent, MH("Absorb"), y); y = y - h
	if ab.damageAbsorb then
		local da = ab.damageAbsorb
		_, h = Widgets:Toggle(parent, "Enable Texture Replacement", y,
			DBGet(da, "enable"), DBSet(da, "enable"),
			"Enable the replacing of ElvUI absorb bar textures.", NOT_PORTED); y = y - h
		_, h = Widgets:Toggle(parent, "Blizzard Style", y,
			DBGet(da, "blizzardStyle"), DBSet(da, "blizzardStyle"),
			"Use the texture from Blizzard Raid Frames.", NOT_PORTED); y = y - h
	end
	local ri = E.db.WT.unitFrames.roleIcon
	if ri then
		_, h = Widgets:SectionHeader(parent, MH("Role Icon"), y); y = y - h
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(ri, "enable"), DBSet(ri, "enable"),
			"Replace the role icon texture on unit frames.", NOT_PORTED); y = y - h
	end
	return y
end

local function BuildNameClip(parent, y, cat)
	local MH = function(mod, sub) return addon.MakeHeader(cat, mod, sub) end
	local Widgets = EllesmereUI.Widgets
	local _, h
	local nc = E.private.WT.unitFrames.nameClip
	_, h = Widgets:SectionHeader(parent, MH("Name Clip"), y); y = y - h
	return y
end

-- Original WindTools layout: one Unit Frames category page with every module
-- group inline (Quick Focus, Absorb, Name Clip).
addon.RegisterOptionBuilder("unitFrames", function(parent, y, cat)
	local Widgets = EllesmereUI.Widgets
	y = BuildQuickFocus(parent, y, cat)
	local _, sh = Widgets:Spacer(parent, y, 8); y = y - sh
	y = BuildAbsorb(parent, y, cat)
	_, sh = Widgets:Spacer(parent, y, 8); y = y - sh
	return BuildNameClip(parent, y, cat)
end)
