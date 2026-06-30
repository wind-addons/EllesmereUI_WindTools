local addon = select(2, ...)
local W = addon[1]
local E = addon[3]
local DBGet = addon.DBGet
local DBSet = addon.DBSet
local DBGet2 = addon.DBGet2
local DBSet2 = addon.DBSet2

local MODIFIER_VALUES = {
	NONE = "None", SHIFT = "Shift", CTRL = "Ctrl", ALT = "Alt",
	ALT_SHIFT = "Alt + Shift", CTRL_SHIFT = "Ctrl + Shift",
	CTRL_ALT = "Ctrl + Alt", CTRL_ALT_SHIFT = "Ctrl + Alt + Shift",
}
local MODIFIER_ORDER = { "NONE", "SHIFT", "CTRL", "ALT", "ALT_SHIFT", "CTRL_SHIFT", "CTRL_ALT", "CTRL_ALT_SHIFT" }

local HEADER_STYLE_VALUES = { NONE = "None", TEXT = "Text", TEXTURE = "Texture" }
local HEADER_STYLE_ORDER = { "NONE", "TEXT", "TEXTURE" }

local GROUP_INFO_MODE = { NORMAL = "Normal", COMPACT = "Compact" }
local GROUP_INFO_MODE_ORDER = { "NORMAL", "COMPACT" }

local function BuildGeneral(parent, y, cat)
	local Widgets = EllesmereUI.Widgets
	local MH = function(mod, sub) return addon.MakeHeader(cat, mod, sub) end
	local _, h
	local pdb = E.private.WT.tooltips
	_, h = Widgets:SectionHeader(parent, MH("General"), y); y = y - h
	_, h = Widgets:Dropdown(parent, "General Modifier Key", y,
		MODIFIER_VALUES, MODIFIER_ORDER,
		DBGet(pdb, "modifier"), DBSet(pdb, "modifier"),
		"The modifier key to show additional information from WindTools."); y = y - h
	_, h = Widgets:SectionHeader(parent, MH("General", "Title Icon"), y); y = y - h
	_, h = Widgets:Toggle(parent, "Enable", y,
		DBGet2(pdb, "titleIcon", "enable"), DBSet2(pdb, "titleIcon", "enable"),
		"Add an icon to the title of items, spells, achievements, and more."); y = y - h
	_, h = Widgets:DualRow(parent, y,
		{ type = "slider", text = "Icon Width", min = 1, max = 50, step = 1,
		  getValue = DBGet2(pdb, "titleIcon", "width"), setValue = DBSet2(pdb, "titleIcon", "width") },
		{ type = "slider", text = "Icon Height", min = 1, max = 50, step = 1,
		  getValue = DBGet2(pdb, "titleIcon", "height"), setValue = DBSet2(pdb, "titleIcon", "height") }
	); y = y - h
	_, h = Widgets:DualRow(parent, y,
		{ type = "toggle", text = "Faction Icon", tooltip = "Show a faction icon in the top right of tooltips.",
		  getValue = DBGet(pdb, "factionIcon"), setValue = DBSet(pdb, "factionIcon") },
		{ type = "toggle", text = "Pet Icon", tooltip = "Add an icon for indicating the type of the pet.",
		  getValue = DBGet(pdb, "petIcon"), setValue = DBSet(pdb, "petIcon") }
	); y = y - h
	_, h = Widgets:DualRow(parent, y,
		{ type = "toggle", text = "Pet ID", tooltip = "Show battle pet species ID in tooltips.",
		  getValue = DBGet(pdb, "petId"), setValue = DBSet(pdb, "petId") },
		{ type = "toggle", text = "Tier Set", tooltip = "Show the number of tier set equipments.",
		  getValue = DBGet(pdb, "tierSet"), setValue = DBSet(pdb, "tierSet") }
	); y = y - h
	return y
end

local function BuildProgression(parent, y, cat)
	local Widgets = EllesmereUI.Widgets
	local MH = function(mod, sub) return addon.MakeHeader(cat, mod, sub) end
	local _, h
	local pg = E.private.WT.tooltips.progression
	_, h = Widgets:SectionHeader(parent, MH("Progression"), y); y = y - h
	_, h = Widgets:Toggle(parent, "Enable", y,
		DBGet(pg, "enable"), DBSet(pg, "enable"),
		"Add progression information to tooltips."); y = y - h
	_, h = Widgets:DualRow(parent, y,
		{ type = "toggle", text = "Disable In Combat", tooltip = "Disable progression information in combat.",
		  getValue = DBGet(pg, "disableInCombat"), setValue = DBSet(pg, "disableInCombat") },
		{ type = "dropdown", text = "Header Style",
		  values = HEADER_STYLE_VALUES, order = HEADER_STYLE_ORDER,
		  getValue = DBGet(pg, "header"), setValue = DBSet(pg, "header") }
	); y = y - h
	if pg.raid then
		_, h = Widgets:Toggle(parent, "Raid", y,
			function() return pg.raid.enable end,
			function(v) pg.raid.enable = v end); y = y - h
	end
	if pg.mythicPlus then
		_, h = Widgets:Toggle(parent, "Mythic Plus", y,
			function() return pg.mythicPlus.enable end,
			function(v) pg.mythicPlus.enable = v end); y = y - h
	end
	return y
end

local function BuildKeystoneGroupInfo(parent, y, cat)
	local Widgets = EllesmereUI.Widgets
	local MH = function(mod, sub) return addon.MakeHeader(cat, mod, sub) end
	local _, h
	local db = E.db.WT.tooltips
	_, h = Widgets:SectionHeader(parent, MH("Keystone"), y); y = y - h
	do
		local ks = db.keystone
		local ksDis = function() return not ks.enable end
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(ks, "enable"), DBSet(ks, "enable"),
			"Show the keystone information in the tooltip."); y = y - h
		_, h = Widgets:Toggle(parent, "Use Abbreviation", y,
			DBGet(ks, "useAbbreviation"), DBSet(ks, "useAbbreviation"),
			"Use abbreviation for the keystone name.", ksDis); y = y - h
	end
	_, h = Widgets:SectionHeader(parent, MH("Group Info"), y); y = y - h
	do
		local gi = db.groupInfo
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(gi, "enable"), DBSet(gi, "enable"),
			"Add LFG group info to tooltip."); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Exclude Dungeons", tooltip = "It will not show the group info for dungeons.",
			  getValue = DBGet(gi, "excludeDungeon"), setValue = DBSet(gi, "excludeDungeon") },
			{ type = "toggle", text = "Hide Blizzard", tooltip = "Hide the default Blizzard group information.",
			  getValue = DBGet(gi, "hideBlizzard"), setValue = DBSet(gi, "hideBlizzard") }
		); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Add Title", tooltip = "Display an additional title.",
			  getValue = DBGet(gi, "title"), setValue = DBSet(gi, "title") },
			{ type = "dropdown", text = "Mode",
			  values = GROUP_INFO_MODE, order = GROUP_INFO_MODE_ORDER,
			  getValue = DBGet(gi, "mode"), setValue = DBSet(gi, "mode") }
		); y = y - h
	end
	return y
end

local function BuildAdvanced(parent, y, cat)
	local Widgets = EllesmereUI.Widgets
	local MH = function(mod, sub) return addon.MakeHeader(cat, mod, sub) end
	local _, h
	local db = E.db.WT.tooltips
	local pdb = E.private.WT.tooltips
	_, h = Widgets:SectionHeader(parent, MH("ElvUI Tooltip Tweaks"), y); y = y - h
	do
		local et = db.elvUITweaks
		if et then
			_, h = Widgets:SectionHeader(parent, MH("ElvUI Tooltip Tweaks", "Health Bar"), y); y = y - h
			if et.healthBar then
				_, h = Widgets:DualRow(parent, y,
					{ type = "slider", text = "Health Bar Y-Offset", min = -50, max = 50, step = 1,
					  getValue = DBGet2(et, "healthBar", "barYOffset"), setValue = DBSet2(et, "healthBar", "barYOffset") },
					{ type = "slider", text = "Health Text Y-Offset", min = -50, max = 50, step = 1,
					  getValue = DBGet2(et, "healthBar", "textYOffset"), setValue = DBSet2(et, "healthBar", "textYOffset") }
				); y = y - h
			end
			_, h = Widgets:SectionHeader(parent, MH("ElvUI Tooltip Tweaks", "Spec Icon"), y); y = y - h
			if et.specIcon then
				_, h = Widgets:Toggle(parent, "Enable", y,
					DBGet2(et, "specIcon", "enable"), DBSet2(et, "specIcon", "enable"),
					"Show the icon of the specialization."); y = y - h
				_, h = Widgets:DualRow(parent, y,
					{ type = "slider", text = "Icon Width", min = 1, max = 50, step = 1,
					  getValue = DBGet2(et, "specIcon", "width"), setValue = DBSet2(et, "specIcon", "width") },
					{ type = "slider", text = "Icon Height", min = 1, max = 50, step = 1,
					  getValue = DBGet2(et, "specIcon", "height"), setValue = DBSet2(et, "specIcon", "height") }
				); y = y - h
			end
			_, h = Widgets:SectionHeader(parent, MH("ElvUI Tooltip Tweaks", "Miscellaneous"), y); y = y - h
			_, h = Widgets:Toggle(parent, "Force Item Level", y,
				function() return et.forceItemLevel end,
				function(v) et.forceItemLevel = v end,
				"Even you are not pressing the modifier key, the item level will still be shown."); y = y - h
		end
	end
	_, h = Widgets:SectionHeader(parent, MH("Objective Progress"), y); y = y - h
	do
		local op = pdb.objectiveProgress
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(op, "enable"), DBSet(op, "enable"),
			"Add more details of objective progress information into tooltips."); y = y - h
		_, h = Widgets:Slider(parent, "Accuracy", y, 0, 5, 1,
			DBGet(op, "accuracy"), DBSet(op, "accuracy")); y = y - h
	end
	return y
end

addon.RegisterOptionBuilder("tooltips", function(parent, y, cat, subPage)
	if     subPage == "Tooltip Info"          then return BuildGeneral(parent, y, cat)
	elseif subPage == "Progression"           then return BuildProgression(parent, y, cat)
	elseif subPage == "Keystone & Group Info" then return BuildKeystoneGroupInfo(parent, y, cat)
	elseif subPage == "Tooltip Advanced"      then return BuildAdvanced(parent, y, cat)
	end
	return y
end)
