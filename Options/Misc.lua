local addon = select(2, ...)
local W = addon[1]
local E = addon[3]
local L = addon[4]

local DBGet = addon.DBGet
local DBSet = addon.DBSet
local DBGet2 = addon.DBGet2
local DBSet2 = addon.DBSet2
local SafeCall = addon.SafeCall
local SafeModuleCall = addon.SafeModuleCall
local CVarGetBool = addon.CVarGetBool
local CVarSetBool = addon.CVarSetBool
local CVarGetNum = addon.CVarGetNum
local CVarSetNum = addon.CVarSetNum
local CVarGetStr = addon.CVarGetStr
local CVarSetStr = addon.CVarSetStr
local GetLSMFonts = addon.GetLSMFonts
local GetLSMStatusbars = addon.GetLSMStatusbars
local FONT_OUTLINE_VALUES = addon.FONT_OUTLINE_VALUES
local FONT_OUTLINE_ORDER = addon.FONT_OUTLINE_ORDER

local ANIMATION_EASE_VALUES = {
	linear = "Linear Ease",
	quadratic = "Quadratic Ease",
	cubic = "Cubic Ease",
	quartic = "Quartic Ease",
	quintic = "Quintic Ease",
	sinusoidal = "Sinusoidal Ease",
	exponential = "Exponential Ease",
	circular = "Circular Ease",
	bounce = "Bounce Ease",
}
local ANIMATION_EASE_ORDER = {
	"linear", "quadratic", "cubic", "quartic", "quintic",
	"sinusoidal", "exponential", "circular", "bounce",
}

local COLOR_MODE_VALUES = {
	DEFAULT = "Default",
	CLASS = "Class Color",
	VALUE = "Value Color",
	CUSTOM = "Custom",
}
local COLOR_MODE_ORDER = { "DEFAULT", "CLASS", "VALUE", "CUSTOM" }

local ANCHOR_VALUES = {
	TOP = "TOP", BOTTOM = "BOTTOM",
	LEFT = "LEFT", RIGHT = "RIGHT", CENTER = "CENTER",
	TOPLEFT = "TOPLEFT", TOPRIGHT = "TOPRIGHT",
	BOTTOMLEFT = "BOTTOMLEFT", BOTTOMRIGHT = "BOTTOMRIGHT",
}
local ANCHOR_ORDER = {
	"TOP", "BOTTOM", "LEFT", "RIGHT", "CENTER",
	"TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT",
}

local SCREENSHOT_FORMAT_VALUES = { jpeg = "JPG", png = "PNG", tga = "TGA" }
local SCREENSHOT_FORMAT_ORDER = { "jpeg", "png", "tga" }

local MOUSE_ACCEL_VALUES = {
	["-1"] = "System Default",
	["0"] = "Disable",
	["1"] = "Raw Mouse Acceleration",
}
local MOUSE_ACCEL_ORDER = { "-1", "0", "1" }

local LFG_ADDITIONAL_TEXT_TARGET = { TITLE = "Title", DESC = "Description" }
local LFG_ADDITIONAL_TEXT_TARGET_ORDER = { "TITLE", "DESC" }

local LFG_ICON_PACK_ORDER = {
	"SPEC", "SQUARE", "HEXAGON", "FFXIV", "SUNUI", "LYNUI", "ELVUI_OLD", "DEFAULT",
}
local LFG_ICON_PACK_VALUES = {
	SPEC = "Specialization",
	SQUARE = "Square",
	HEXAGON = "Hexagon",
	FFXIV = "FFXIV",
	SUNUI = "SunUI",
	LYNUI = "LynUI",
	ELVUI_OLD = "ElvUI Old",
	DEFAULT = "Default",
}

local AVAILABLE_BUTTON_VALUES = {
	CHARACTER = "Character",
	SPELLBOOK = "Spellbook",
	TALENTS = "Talents",
	FRIENDS = "Friend List",
	GUILD = "Guild",
	GROUP_FINDER = "Group Finder",
	ACHIEVEMENTS = "Achievements",
	ENCOUNTER_JOURNAL = "Encounter Journal",
	COLLECTIONS = "Collections",
	TOY_BOX = "Toy Box",
	PET_JOURNAL = "Pet Journal",
	BAGS = "Bags",
	SCREENSHOT = "Screenshot",
	HOME = "Home",
	HEARTHSTONE = "Hearthstone",
	BLIZZARD_SHOP = "Blizzard Shop",
}
local AVAILABLE_BUTTON_ORDER = {
	"CHARACTER", "SPELLBOOK", "TALENTS", "FRIENDS", "GUILD", "GROUP_FINDER",
	"ACHIEVEMENTS", "ENCOUNTER_JOURNAL", "COLLECTIONS", "TOY_BOX", "PET_JOURNAL",
	"BAGS", "SCREENSHOT", "HOME", "HEARTHSTONE", "BLIZZARD_SHOP",
}

local TOOLTIP_ANCHOR_VALUES = { ANCHOR_TOP = "TOP", ANCHOR_BOTTOM = "BOTTOM" }
local TOOLTIP_ANCHOR_ORDER = { "ANCHOR_TOP", "ANCHOR_BOTTOM" }

local function FontSection(Widgets, parent, y, dbTable, prefix)
	local _, h
	local fonts = GetLSMFonts()
	_, h = Widgets:Dropdown(parent, "Font", y, fonts, DBGet(dbTable, "name"), DBSet(dbTable, "name")); y = y - h
	_, h = Widgets:Dropdown(parent, "Outline", y,
		FONT_OUTLINE_VALUES, FONT_OUTLINE_ORDER,
		DBGet(dbTable, "style"), DBSet(dbTable, "style")); y = y - h
	_, h = Widgets:Slider(parent, "Size", y, 5, 60, 1,
		DBGet(dbTable, "size"), DBSet(dbTable, "size")); y = y - h
	return y
end

addon.RegisterOptionBuilder("misc", function(parent, y)
	local Widgets = EllesmereUI.Widgets
	local _, h
	local db = E.db.WT.misc
	local pdb = E.private.WT.misc

	_, h = Widgets:SectionHeader(parent, "GENERAL", y); y = y - h

	_, h = Widgets:DualRow(parent, y,
		{ type = "toggle", text = "Pause to slash", tooltip = "Just for Chinese and Korean players",
		  getValue = DBGet(pdb, "pauseToSlash"), setValue = DBSet(pdb, "pauseToSlash") },
		{ type = "toggle", text = "Math Without Kanji", tooltip = "Use alphabet rather than kanji (Only for Chinese players)",
		  getValue = DBGet(pdb, "noKanjiMath"), setValue = DBSet(pdb, "noKanjiMath") }
	); y = y - h

	_, h = Widgets:DualRow(parent, y,
		{ type = "toggle", text = "Disable Talking Head", tooltip = "Disable Blizzard Talking Head.",
		  getValue = DBGet(db, "disableTalkingHead"), setValue = DBSet(db, "disableTalkingHead") },
		{ type = "toggle", text = "Skip Cut Scene",
		  getValue = DBGet(pdb, "skipCutScene"),
		  setValue = DBSet(pdb, "skipCutScene", function() SafeModuleCall(W.Modules.Misc, "SkipCutScene") end) }
	); y = y - h

	if pdb.skipCutScene then
		_, h = Widgets:Toggle(parent, "Only Watched",
			y, DBGet(pdb, "onlyStopWatched"), DBSet(pdb, "onlyStopWatched"),
			"Only skip watched cut scene. (some cut scenes can't be skipped)"); y = y - h
	end

	_, h = Widgets:DualRow(parent, y,
		{ type = "toggle", text = "Hide Crafter", tooltip = "Hide crafter name in the item tooltip.",
		  getValue = DBGet(db, "hideCrafter"), setValue = DBSet(db, "hideCrafter") },
		{ type = "toggle", text = "No Loot Panel", tooltip = "Disable Blizzard loot info which auto showing after combat overed.",
		  getValue = DBGet(db, "noLootPanel"),
		  setValue = DBSet(db, "noLootPanel", function() SafeModuleCall(W.Modules.Misc, "LootPanel") end) }
	); y = y - h

	_, h = Widgets:DualRow(parent, y,
		{ type = "toggle", text = "Keybind Text Above",
		  tooltip = "Show keybinds above the ElvUI cooldown and glow effect on the action buttons.",
		  getValue = DBGet(pdb, "keybindTextAbove"), setValue = DBSet(pdb, "keybindTextAbove") },
		{ type = "toggle", text = "Guild News IL", tooltip = "Show item level of each item in guild news.",
		  getValue = DBGet(pdb, "guildNewsItemLevel"), setValue = DBSet(pdb, "guildNewsItemLevel") }
	); y = y - h

	_, h = Widgets:DualRow(parent, y,
		{ type = "toggle", text = "View SC Group", tooltip = "Let you can view the group created by Simplified Chinese players.",
		  getValue = DBGet(pdb, "addCNFilter"), setValue = DBSet(pdb, "addCNFilter") },
		{ type = "toggle", text = "Anti-override", tooltip = "Unblock the profanity filter and disable model override.",
		  getValue = DBGet(pdb, "antiOverride"), setValue = DBSet(pdb, "antiOverride") }
	); y = y - h

	_, h = Widgets:DualRow(parent, y,
		{ type = "toggle", text = "Auto Toggle Chat Bubble", tooltip = "Only show chat bubble in instance.",
		  getValue = DBGet(pdb, "autoToggleChatBubble"), setValue = DBSet(pdb, "autoToggleChatBubble") },
		{ type = "toggle", text = "Reshii Wraps Upgrade",
		  tooltip = "Middle click the character back slot to open the Reshii Wraps upgrade menu.",
		  getValue = DBGet(pdb, "reshiiWrapsUpgrade"), setValue = DBSet(pdb, "reshiiWrapsUpgrade") }
	); y = y - h

	_, h = Widgets:SectionHeader(parent, "AUTOMATION", y); y = y - h
	do
		local auto = db.automation
		local autoEnabled = function() return auto.enable end
		_, h = Widgets:Toggle(parent, "Enable", y, DBGet(auto, "enable"), DBSet(auto, "enable")); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Auto Hide Map", tooltip = "Automatically close world map if player enters combat.",
			  getValue = DBGet(auto, "hideWorldMapAfterEnteringCombat"),
			  setValue = DBSet(auto, "hideWorldMapAfterEnteringCombat"), disabled = function() return not auto.enable end },
			{ type = "toggle", text = "Auto Hide Bag", tooltip = "Automatically close bag if player enters combat.",
			  getValue = DBGet(auto, "hideBagAfterEnteringCombat"),
			  setValue = DBSet(auto, "hideBagAfterEnteringCombat"), disabled = autoEnabled }
		); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Accept Resurrect", tooltip = "Accept resurrect from other player automatically when you not in combat.",
			  getValue = DBGet(auto, "acceptResurrect"),
			  setValue = DBSet(auto, "acceptResurrect"), disabled = autoEnabled },
			{ type = "toggle", text = "Accept Combat Resurrect", tooltip = "Accept resurrect from other player automatically when you in combat.",
			  getValue = DBGet(auto, "acceptCombatResurrect"),
			  setValue = DBSet(auto, "acceptCombatResurrect"), disabled = autoEnabled }
		); y = y - h
		_, h = Widgets:Toggle(parent, "Confirm Summon", y,
			DBGet(auto, "confirmSummon"), DBSet(auto, "confirmSummon"),
			"Confirm summon from other player automatically."); y = y - h
		_, h = Widgets:Toggle(parent, "Exit Phase Diving", y,
			DBGet(db.exitPhaseDiving, "enable"), DBSet(db.exitPhaseDiving, "enable")); y = y - h
		if db.exitPhaseDiving.enable then
			_, h = Widgets:DualRow(parent, y,
				{ type = "slider", text = "Width", min = 5, max = 1000, step = 1,
				  getValue = DBGet(db.exitPhaseDiving, "width"),
				  setValue = DBSet(db.exitPhaseDiving, "width") },
				{ type = "slider", text = "Height", min = 5, max = 1000, step = 1,
				  getValue = DBGet(db.exitPhaseDiving, "height"),
				  setValue = DBSet(db.exitPhaseDiving, "height") }
			); y = y - h
		end
	end

	_, h = Widgets:SectionHeader(parent, "CVARS EDITOR", y); y = y - h
	do
		_, h = Widgets:SectionHeader(parent, "General", y); y = y - h
		_, h = Widgets:Toggle(parent, "Auto Compare", y,
			CVarGetBool("alwaysCompareItems"), CVarSetBool("alwaysCompareItems"),
			"Always compare items when hovering over them."); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "slider", text = "Screenshot Quality", min = 1, max = 10, step = 1,
			  getValue = CVarGetNum("screenshotQuality"), setValue = CVarSetNum("screenshotQuality") },
			{ type = "dropdown", text = "Screenshot Format",
			  values = SCREENSHOT_FORMAT_VALUES, order = SCREENSHOT_FORMAT_ORDER,
			  getValue = CVarGetStr("screenshotFormat"), setValue = CVarSetStr("screenshotFormat") }
		); y = y - h

		_, h = Widgets:SectionHeader(parent, "Combat", y); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Floating Damage Text",
			  getValue = CVarGetBool("floatingCombatTextCombatDamage_v2"),
			  setValue = CVarSetBool("floatingCombatTextCombatDamage_v2") },
			{ type = "toggle", text = "Floating Healing Text",
			  getValue = CVarGetBool("floatingCombatTextCombatHealing_v2"),
			  setValue = CVarSetBool("floatingCombatTextCombatHealing_v2") }
		); y = y - h
		_, h = Widgets:Slider(parent, "Floating Text Scale", y, 0.1, 5, 0.1,
			CVarGetNum("WorldTextScale_v2"), CVarSetNum("WorldTextScale_v2")); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "slider", text = "Spell Queue Window", min = 0, max = 400, step = 1,
			  getValue = CVarGetNum("SpellQueueWindow"), setValue = CVarSetNum("SpellQueueWindow") },
			{ type = "slider", text = "Camera Max Zoom", min = 1, max = 2.6, step = 0.01,
			  getValue = CVarGetNum("cameraDistanceMaxZoomFactor"),
			  setValue = CVarSetNum("cameraDistanceMaxZoomFactor") }
		); y = y - h

		_, h = Widgets:SectionHeader(parent, "Visual Effect", y); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Glow Effect", getValue = CVarGetBool("ffxGlow"), setValue = CVarSetBool("ffxGlow") },
			{ type = "toggle", text = "Death Effect", getValue = CVarGetBool("ffxDeath"), setValue = CVarSetBool("ffxDeath") }
		); y = y - h
		_, h = Widgets:Toggle(parent, "Nether Effect", y,
			CVarGetBool("ffxNether"), CVarSetBool("ffxNether")); y = y - h

		_, h = Widgets:SectionHeader(parent, "Control", y); y = y - h
		_, h = Widgets:Toggle(parent, "Raw Mouse", y,
			CVarGetBool("rawMouseEnable"), CVarSetBool("rawMouseEnable"),
			"It will fix the problem if your cursor has abnormal movement."); y = y - h
		_, h = Widgets:Dropdown(parent, "Acceleration Type", y,
			MOUSE_ACCEL_VALUES, MOUSE_ACCEL_ORDER,
			CVarGetStr("mouseAcceleration"), CVarSetStr("mouseAcceleration")); y = y - h
		_, h = Widgets:Toggle(parent, "Action on keydown", y,
			CVarGetBool("ActionButtonUseKeyDown"), CVarSetBool("ActionButtonUseKeyDown"),
			"Trigger the action when pressing the key down rather than releasing it."); y = y - h
	end

	_, h = Widgets:SectionHeader(parent, "MOVE FRAMES", y); y = y - h
	do
		local mf = pdb.moveFrames
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(mf, "enable"), DBSet(mf, "enable")); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Move ElvUI Bags",
			  getValue = DBGet(mf, "elvUIBags"), setValue = DBSet(mf, "elvUIBags") },
			{ type = "toggle", text = "TSM Compatible", tooltip = "Fix the merchant frame showing when you using Trader Skill Master.",
			  getValue = DBGet(mf, "tradeSkillMasterCompatible"),
			  setValue = DBSet(mf, "tradeSkillMasterCompatible") }
		); y = y - h
		_, h = Widgets:Toggle(parent, "Remember Positions", y,
			DBGet(mf, "rememberPositions"), DBSet(mf, "rememberPositions")); y = y - h
		if mf.rememberPositions then
			_, h = Widgets:Toggle(parent, "Auto Reset Off-screen Frames", y,
				DBGet(mf, "autoResetOffScreenFrames"), DBSet(mf, "autoResetOffScreenFrames"),
				"Automatically clear the remembered position if the frame is off the screen."); y = y - h
		end
		_, h = Widgets:Button(parent, "Clear History", y, function()
			mf.framePositions = {}
		end); y = y - h
	end

	_, h = Widgets:SectionHeader(parent, "MUTE", y); y = y - h
	do
		local mute = pdb.mute
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(mute, "enable"), DBSet(mute, "enable"),
			"Disable some annoying sound effects."); y = y - h
		if mute.other then
			_, h = Widgets:DualRow(parent, y,
				{ type = "toggle", text = "Tortollan", getValue = DBGet(mute.other, "Tortollan"), setValue = DBSet(mute.other, "Tortollan") },
				{ type = "toggle", text = "Crying", tooltip = "Mute crying sounds of all races.",
				  getValue = DBGet(mute.other, "Crying"), setValue = DBSet(mute.other, "Crying") }
			); y = y - h
			_, h = Widgets:DualRow(parent, y,
				{ type = "toggle", text = "Dragon", tooltip = "Mute the sound of dragons.",
				  getValue = DBGet(mute.other, "Dragon"), setValue = DBSet(mute.other, "Dragon") },
				{ type = "toggle", text = "Jewelcrafting", tooltip = "Mute the sound of jewelcrafting.",
				  getValue = DBGet(mute.other, "Jewelcrafting"), setValue = DBSet(mute.other, "Jewelcrafting") }
			); y = y - h
			if mute.other["Smolderheart"] ~= nil then
				_, h = Widgets:Toggle(parent, "Smolderheart", y,
					DBGet(mute.other, "Smolderheart"), DBSet(mute.other, "Smolderheart")); y = y - h
			end
			if mute.other["Elegy of the Eternals"] ~= nil then
				_, h = Widgets:Toggle(parent, "Elegy of the Eternals", y,
					DBGet(mute.other, "Elegy of the Eternals"),
					DBSet(mute.other, "Elegy of the Eternals")); y = y - h
			end
		end
	end

	_, h = Widgets:SectionHeader(parent, "GAME BAR", y); y = y - h
	do
		local gb = db.gameBar
		local gbDisabled = function() return not gb.enable end
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(gb, "enable"), DBSet(gb, "enable"),
			"Toggle the game bar."); y = y - h

		_, h = Widgets:SectionHeader(parent, "General", y); y = y - h
		_, h = Widgets:Toggle(parent, "Bar Backdrop", y,
			DBGet(gb, "backdrop"), DBSet(gb, "backdrop"), "Show a backdrop of the bar."); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "slider", text = "Backdrop Spacing", min = 1, max = 30, step = 1,
			  getValue = DBGet(gb, "backdropSpacing"), setValue = DBSet(gb, "backdropSpacing"),
			  tooltip = "The spacing between the backdrop and the buttons.", disabled = gbDisabled },
			{ type = "slider", text = "Button Spacing", min = 1, max = 30, step = 1,
			  getValue = DBGet(gb, "spacing"), setValue = DBSet(gb, "spacing"),
			  tooltip = "The spacing between buttons.", disabled = gbDisabled }
		); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "slider", text = "Time Area Width", min = 1, max = 200, step = 1,
			  getValue = DBGet(gb, "timeAreaWidth"), setValue = DBSet(gb, "timeAreaWidth"), disabled = gbDisabled },
			{ type = "slider", text = "Time Area Height", min = 1, max = 100, step = 1,
			  getValue = DBGet(gb, "timeAreaHeight"), setValue = DBSet(gb, "timeAreaHeight"), disabled = gbDisabled }
		); y = y - h
		_, h = Widgets:Slider(parent, "Button Size", y, 2, 80, 1,
			DBGet(gb, "buttonSize"), DBSet(gb, "buttonSize"),
			"The size of the buttons."); y = y - h

		_, h = Widgets:SectionHeader(parent, "Display", y); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Mouse Over", tooltip = "Show the bar only when the mouse is hovered over the area.",
			  getValue = DBGet(gb, "mouseOver"), setValue = DBSet(gb, "mouseOver"), disabled = gbDisabled },
			{ type = "toggle", text = "Notification", tooltip = "Add an indicator icon to buttons.",
			  getValue = DBGet(gb, "notification"), setValue = DBSet(gb, "notification"), disabled = gbDisabled }
		); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "slider", text = "Fade Time", min = 0, max = 3, step = 0.01,
			  getValue = DBGet(gb, "fadeTime"), setValue = DBSet(gb, "fadeTime"),
			  tooltip = "The animation speed.", disabled = gbDisabled },
			{ type = "dropdown", text = "Tooltip Anchor",
			  values = TOOLTIP_ANCHOR_VALUES, order = TOOLTIP_ANCHOR_ORDER,
			  getValue = DBGet(gb, "tooltipsAnchor"), setValue = DBSet(gb, "tooltipsAnchor"), disabled = gbDisabled }
		); y = y - h

		_, h = Widgets:SectionHeader(parent, "Animation", y); y = y - h
		_, h = Widgets:Slider(parent, "Duration", y, 0, 3, 0.01,
			DBGet2(gb, "animation", "duration"), DBSet2(gb, "animation", "duration"),
			"The duration of the animation in seconds."); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "dropdown", text = "Ease",
			  values = ANIMATION_EASE_VALUES, order = ANIMATION_EASE_ORDER,
			  getValue = DBGet2(gb, "animation", "ease"),
			  setValue = DBSet2(gb, "animation", "ease"),
			  tooltip = "The easing function used for colorize the button." },
			{ type = "toggle", text = "Invert Ease",
			  getValue = DBGet2(gb, "animation", "easeInvert"),
			  setValue = DBSet2(gb, "animation", "easeInvert") }
		); y = y - h

		_, h = Widgets:SectionHeader(parent, "Color - Normal", y); y = y - h
		_, h = Widgets:Dropdown(parent, "Mode", y,
			COLOR_MODE_VALUES, COLOR_MODE_ORDER,
			DBGet(gb, "normalColor"), DBSet(gb, "normalColor")); y = y - h
		if gb.normalColor == "CUSTOM" then
			_, h = Widgets:ColorPicker(parent, "Custom Color", y,
				function()
					local c = gb.customNormalColor or {}
					return c.r or 1, c.g or 1, c.b or 1, c.a or 1
				end,
				function(r, g, b, a)
					gb.customNormalColor = gb.customNormalColor or {}
					gb.customNormalColor.r, gb.customNormalColor.g, gb.customNormalColor.b = r, g, b
					gb.customNormalColor.a = a
				end, true); y = y - h
		end

		_, h = Widgets:SectionHeader(parent, "Color - Hover", y); y = y - h
		_, h = Widgets:Dropdown(parent, "Mode", y,
			COLOR_MODE_VALUES, COLOR_MODE_ORDER,
			DBGet(gb, "hoverColor"), DBSet(gb, "hoverColor")); y = y - h
		if gb.hoverColor == "CUSTOM" then
			_, h = Widgets:ColorPicker(parent, "Custom Color", y,
				function()
					local c = gb.customHoverColor or {}
					return c.r or 0, c.g or 0.659, c.b or 1, c.a or 1
				end,
				function(r, g, b, a)
					gb.customHoverColor = gb.customHoverColor or {}
					gb.customHoverColor.r, gb.customHoverColor.g, gb.customHoverColor.b = r, g, b
					gb.customHoverColor.a = a
				end, true); y = y - h
		end

		_, h = Widgets:SectionHeader(parent, "Additional Text", y); y = y - h
		do
			local at = gb.additionalText
			_, h = Widgets:DualRow(parent, y,
				{ type = "toggle", text = "Enable",
				  getValue = DBGet(at, "enable"), setValue = DBSet(at, "enable"), disabled = gbDisabled },
				{ type = "toggle", text = "Slow Mode", tooltip = "Update the additional text every 10 seconds rather than every 1 second such that the used memory will be lower.",
				  getValue = DBGet(at, "slowMode"), setValue = DBSet(at, "slowMode"), disabled = gbDisabled }
			); y = y - h
			_, h = Widgets:DualRow(parent, y,
				{ type = "dropdown", text = "Anchor Point",
				  values = ANCHOR_VALUES, order = ANCHOR_ORDER,
				  getValue = DBGet(at, "anchor"), setValue = DBSet(at, "anchor"), disabled = gbDisabled },
				{ type = "spacer" }
			); y = y - h
			_, h = Widgets:DualRow(parent, y,
				{ type = "slider", text = "X-Offset", min = -100, max = 100, step = 1,
				  getValue = DBGet(at, "x"), setValue = DBSet(at, "x"), disabled = gbDisabled },
				{ type = "slider", text = "Y-Offset", min = -100, max = 100, step = 1,
				  getValue = DBGet(at, "y"), setValue = DBSet(at, "y"), disabled = gbDisabled }
			); y = y - h
			y = FontSection(Widgets, parent, y, at.font)
		end

		_, h = Widgets:SectionHeader(parent, "Time", y); y = y - h
		do
			local tm = gb.time
			_, h = Widgets:DualRow(parent, y,
				{ type = "toggle", text = "Local Time",
				  getValue = DBGet(tm, "localTime"), setValue = DBSet(tm, "localTime"), disabled = gbDisabled },
				{ type = "toggle", text = "24 Hours",
				  getValue = DBGet(tm, "twentyFour"), setValue = DBSet(tm, "twentyFour"), disabled = gbDisabled }
			); y = y - h
			_, h = Widgets:DualRow(parent, y,
				{ type = "toggle", text = "Flash",
				  getValue = DBGet(tm, "flash"), setValue = DBSet(tm, "flash"), disabled = gbDisabled },
				{ type = "toggle", text = "Avoid Reload in Combat", tooltip = "Disable the middle click UI reloading in combat.",
				  getValue = DBGet(tm, "avoidReloadInCombat"), setValue = DBSet(tm, "avoidReloadInCombat"), disabled = gbDisabled }
			); y = y - h
			_, h = Widgets:DualRow(parent, y,
				{ type = "toggle", text = "Always Show System Info", tooltip = "The system information will be always shown rather than showing only being hovered.",
				  getValue = DBGet(tm, "alwaysSystemInfo"), setValue = DBSet(tm, "alwaysSystemInfo"), disabled = gbDisabled },
				{ type = "slider", text = "Interval", min = 1, max = 60, step = 1,
				  getValue = DBGet(tm, "interval"), setValue = DBSet(tm, "interval"),
				  tooltip = "The interval of updating.", disabled = gbDisabled }
			); y = y - h
			y = FontSection(Widgets, parent, y, tm.font)
			_, h = Widgets:SectionHeader(parent, "System Info Font", y); y = y - h
			y = FontSection(Widgets, parent, y, tm.systemInfoFont)
		end

		_, h = Widgets:SectionHeader(parent, "Friends", y); y = y - h
		do
			local fr = gb.friends
			_, h = Widgets:DualRow(parent, y,
				{ type = "toggle", text = "Show All Friends", tooltip = "Show all friends rather than only friends who are currently playing WoW.",
				  getValue = DBGet(fr, "showAllFriends"), setValue = DBSet(fr, "showAllFriends"), disabled = gbDisabled },
				{ type = "toggle", text = "Count Sub Accounts", tooltip = "Count active WoW sub accounts rather than Battle.net Accounts.",
				  getValue = DBGet(fr, "countSubAccounts"), setValue = DBSet(fr, "countSubAccounts"), disabled = gbDisabled }
			); y = y - h
		end

		_, h = Widgets:SectionHeader(parent, "Group Finder", y); y = y - h
		_, h = Widgets:Toggle(parent, "Prefer NetEase Meeting Stone", y,
			DBGet2(gb, "groupFinder", "preferNetEaseMeetingStone"),
			DBSet2(gb, "groupFinder", "preferNetEaseMeetingStone"),
			"If Meeting Stone is installed, left click the Group Finder button to open NetEase Meeting Stone instead of the Blizzard one."); y = y - h

		_, h = Widgets:SectionHeader(parent, "Left Panel", y); y = y - h
		for i = 1, 7 do
			_, h = Widgets:Dropdown(parent, ("Button #%d"):format(i), y,
				AVAILABLE_BUTTON_VALUES, AVAILABLE_BUTTON_ORDER,
				function() return gb.left and gb.left[i] end,
				function(v) gb.left = gb.left or {}; gb.left[i] = v end,
				nil, nil); y = y - h
		end
		_, h = Widgets:SectionHeader(parent, "Right Panel", y); y = y - h
		for i = 1, 7 do
			_, h = Widgets:Dropdown(parent, ("Button #%d"):format(i), y,
				AVAILABLE_BUTTON_VALUES, AVAILABLE_BUTTON_ORDER,
				function() return gb.right and gb.right[i] end,
				function(v) gb.right = gb.right or {}; gb.right[i] = v end,
				nil, nil); y = y - h
		end
	end

	_, h = Widgets:SectionHeader(parent, "LFG LIST", y); y = y - h
	do
		local ll = pdb.lfgList
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(ll, "enable"), DBSet(ll, "enable")); y = y - h

		_, h = Widgets:SectionHeader(parent, "Icon", y); y = y - h
		do
			local ic = ll.icon
			local icDis = function() return not ll.enable end
			_, h = Widgets:DualRow(parent, y,
				{ type = "toggle", text = "Enable", getValue = DBGet(ic, "enable"), setValue = DBSet(ic, "enable"), disabled = icDis },
				{ type = "toggle", text = "Leader", tooltip = "Add an indicator for the leader.",
				  getValue = DBGet(ic, "leader"), setValue = DBSet(ic, "leader"), disabled = icDis }
			); y = y - h
			_, h = Widgets:DualRow(parent, y,
				{ type = "toggle", text = "Reskin Icon", tooltip = "Change role icons.",
				  getValue = DBGet(ic, "reskin"), setValue = DBSet(ic, "reskin"), disabled = icDis },
				{ type = "toggle", text = "Border",
				  getValue = DBGet(ic, "border"), setValue = DBSet(ic, "border"), disabled = icDis }
			); y = y - h
			if ic.reskin then
				_, h = Widgets:Dropdown(parent, "Style", y,
					LFG_ICON_PACK_VALUES, LFG_ICON_PACK_ORDER,
					DBGet(ic, "pack"), DBSet(ic, "pack"),
					"Change the icons that indicate the role."); y = y - h
			end
			_, h = Widgets:DualRow(parent, y,
				{ type = "slider", text = "Size", min = 1, max = 20, step = 1,
				  getValue = DBGet(ic, "size"), setValue = DBSet(ic, "size"), disabled = icDis },
				{ type = "slider", text = "Alpha", min = 0, max = 1, step = 0.01,
				  getValue = DBGet(ic, "alpha"), setValue = DBSet(ic, "alpha"), disabled = icDis }
			); y = y - h
			_, h = Widgets:Toggle(parent, "Hide default class circles", y,
				DBGet(ic, "hideDefaultClassCircle"), DBSet(ic, "hideDefaultClassCircle"),
				"Disable the default class-colored background circle in LFG Lists, leaving only the skinned icons from preferences"); y = y - h
		end

		_, h = Widgets:SectionHeader(parent, "Class Line", y); y = y - h
		do
			local ln = ll.line
			local lnDis = function() return not ll.enable end
			_, h = Widgets:Toggle(parent, "Enable", y,
				DBGet(ln, "enable"), DBSet(ln, "enable"),
				"Add a line in class color."); y = y - h
			_, h = Widgets:Dropdown(parent, "Texture", y,
				GetLSMStatusbars(), nil,
				DBGet(ln, "tex"), DBSet(ln, "tex")); y = y - h
			_, h = Widgets:DualRow(parent, y,
				{ type = "slider", text = "Width", min = 1, max = 20, step = 1,
				  getValue = DBGet(ln, "width"), setValue = DBSet(ln, "width"), disabled = lnDis },
				{ type = "slider", text = "Height", min = 1, max = 20, step = 1,
				  getValue = DBGet(ln, "height"), setValue = DBSet(ln, "height"), disabled = lnDis }
			); y = y - h
			_, h = Widgets:DualRow(parent, y,
				{ type = "slider", text = "X-Offset", min = -20, max = 20, step = 1,
				  getValue = DBGet(ln, "offsetX"), setValue = DBSet(ln, "offsetX"), disabled = lnDis },
				{ type = "slider", text = "Y-Offset", min = -20, max = 20, step = 1,
				  getValue = DBGet(ln, "offsetY"), setValue = DBSet(ln, "offsetY"), disabled = lnDis }
			); y = y - h
			_, h = Widgets:Slider(parent, "Alpha", y, 0, 1, 0.01,
				DBGet(ln, "alpha"), DBSet(ln, "alpha"), nil, lnDis); y = y - h
		end

		_, h = Widgets:SectionHeader(parent, "Additional Text", y); y = y - h
		do
			local at = ll.additionalText
			local atDis = function() return not ll.enable end
			_, h = Widgets:Toggle(parent, "Enable", y,
				DBGet(at, "enable"), DBSet(at, "enable"),
				"Add some additional information into title or description."); y = y - h
			_, h = Widgets:DualRow(parent, y,
				{ type = "dropdown", text = "Target",
				  values = LFG_ADDITIONAL_TEXT_TARGET, order = LFG_ADDITIONAL_TEXT_TARGET_ORDER,
				  getValue = DBGet(at, "target"), setValue = DBSet(at, "target"), disabled = atDis },
				{ type = "toggle", text = "Shorten Description", tooltip = "Remove useless part from description.",
				  getValue = DBGet(at, "shortenDescription"), setValue = DBSet(at, "shortenDescription"), disabled = atDis }
			); y = y - h
		end

		_, h = Widgets:SectionHeader(parent, "Party Keystone", y); y = y - h
		do
			local pk = ll.partyKeystone
			_, h = Widgets:Toggle(parent, "Enable", y,
				DBGet(pk, "enable"), DBSet(pk, "enable"),
				"Add an additional frame to show party members' keystone."); y = y - h
			y = FontSection(Widgets, parent, y, pk.font)
		end

		_, h = Widgets:SectionHeader(parent, "Right Panel", y); y = y - h
		do
			local rp = ll.rightPanel
			local rpDis = function() return not ll.enable end
			_, h = Widgets:DualRow(parent, y,
				{ type = "toggle", text = "Enable", tooltip = "Add an additional frame to filter the groups.",
				  getValue = DBGet(rp, "enable"), setValue = DBSet(rp, "enable"), disabled = rpDis },
				{ type = "toggle", text = "Auto Refresh", tooltip = "Automatically refresh the list after you changing the filter.",
				  getValue = DBGet(rp, "autoRefresh"), setValue = DBSet(rp, "autoRefresh"), disabled = rpDis }
			); y = y - h
			_, h = Widgets:DualRow(parent, y,
				{ type = "toggle", text = "Auto Join", tooltip = "Automatically join the dungeon when clicking on the LFG row, without asking for role confirmation.",
				  getValue = DBGet(rp, "autoJoin"), setValue = DBSet(rp, "autoJoin"), disabled = rpDis },
				{ type = "toggle", text = "Skip Confirmation", tooltip = "Skip signup confirmation during automatic join on listing click",
				  getValue = DBGet(rp, "skipConfirmation"), setValue = DBSet(rp, "skipConfirmation"), disabled = rpDis }
			); y = y - h
			_, h = Widgets:DualRow(parent, y,
				{ type = "slider", text = "Font Size Adjustment", min = -10, max = 20, step = 1,
				  getValue = DBGet(rp, "adjustFontSize"), setValue = DBSet(rp, "adjustFontSize"),
				  tooltip = "Adjust the font size of the right panel.", disabled = rpDis },
				{ type = "toggle", text = "Filter Button Tooltip", tooltip = "Show the dungeon full name when hovering over the filter button.",
				  getValue = DBGet(rp, "filterButtonTooltip"), setValue = DBSet(rp, "filterButtonTooltip"), disabled = rpDis }
			); y = y - h
			if rp.disableSafeFilters ~= nil then
				_, h = Widgets:Toggle(parent, "Disable safe filters", y,
					DBGet(rp, "disableSafeFilters"), DBSet(rp, "disableSafeFilters"),
					"Disable the default behavior that prevents inconsistent filters with flags 'Has Tank', 'Has Healer' and 'Role Available'"); y = y - h
			end
		end
	end

	_, h = Widgets:SectionHeader(parent, "SPELL ACTIVATION ALERT", y); y = y - h
	do
		local sa = db.spellActivationAlert
		local saDis = function() return not sa.enable end
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(sa, "enable"), DBSet(sa, "enable")); y = y - h
		_, h = Widgets:Toggle(parent, "Visibility", y,
			CVarGetBool("displaySpellActivationOverlays"), CVarSetBool("displaySpellActivationOverlays"),
			"Enable/Disable the spell activation alert frame."); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "slider", text = "Opacity", min = 0, max = 1, step = 0.01,
			  getValue = CVarGetNum("spellActivationOverlayOpacity"),
			  setValue = CVarSetNum("spellActivationOverlayOpacity"),
			  tooltip = "Set the opacity of the spell activation alert frame. (Blizzard CVar)", disabled = saDis },
			{ type = "slider", text = "Scale", min = 0.1, max = 5, step = 0.01,
			  getValue = DBGet(sa, "scale"), setValue = DBSet(sa, "scale"),
			  tooltip = "Set the scale of the spell activation alert frame.", disabled = saDis }
		); y = y - h
	end

	_, h = Widgets:SectionHeader(parent, "KEYBIND ALIAS", y); y = y - h
	do
		local ka = db.keybindAlias
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(ka, "enable"), DBSet(ka, "enable"),
			"Custom hotkey alias for keybinding."); y = y - h
	end

	return y
end)
