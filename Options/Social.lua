local addon = select(2, ...)
local W = addon[1]
local E = addon[3]
local DBGet = addon.DBGet
local DBSet = addon.DBSet
local DBGet2 = addon.DBGet2
local DBSet2 = addon.DBSet2
local FontSection = addon.FontSection
local KeyValueEditorButton = addon.KeyValueEditorButton

local ORIENTATION_VALUES = { HORIZONTAL = "Horizontal", VERTICAL = "Vertical" }
local ORIENTATION_ORDER = { "HORIZONTAL", "VERTICAL" }

local CHATBAR_STYLE = { BLOCK = "Block", TEXT = "Text" }
local CHATBAR_STYLE_ORDER = { "BLOCK", "TEXT" }

local ABBR_VALUES = { NONE = "None", SHORT = "Short", DEFAULT = "Default" }
local ABBR_ORDER = { "NONE", "SHORT", "DEFAULT" }

local FRIEND_STATUS_VALUES = { default = "Default", d3 = "Diablo 3", square = "Square" }
local FRIEND_STATUS_ORDER = { "default", "d3", "square" }

local FRIEND_GAME_ICON_VALUES = {
	BLIZZARD = "Default Blizzard Style",
	FACTION = "Use faction icon",
	PATCH = "Use patch icon",
}
local FRIEND_GAME_ICON_ORDER = { "BLIZZARD", "FACTION", "PATCH" }

local TEXT_ALIGN_VALUES = { LEFT = "Left", CENTER = "Center", RIGHT = "Right" }
local TEXT_ALIGN_ORDER = { "LEFT", "CENTER", "RIGHT" }

addon.RegisterOptionBuilder("social", function(parent, y, cat)
	local Widgets = EllesmereUI.Widgets
	local MH = function(mod, sub) return addon.MakeHeader(cat, mod, sub) end
	local _, h
	local db = E.db.WT.social

	_, h = Widgets:SectionHeader(parent, MH("Chat Bar"), y); y = y - h
	do
		local cb = db.chatBar
		local cbDis = function() return not cb.enable end
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(cb, "enable"), DBSet(cb, "enable"),
			"Add a chat bar for switching channel."); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Auto Hide", tooltip = "Hide channels that do not exist.",
			  getValue = DBGet(cb, "autoHide"), setValue = DBSet(cb, "autoHide"), disabled = cbDis },
			{ type = "toggle", text = "Mouse Over", tooltip = "Only show chat bar when you mouse over it.",
			  getValue = DBGet(cb, "mouseOver"), setValue = DBSet(cb, "mouseOver"), disabled = cbDis }
		); y = y - h
		_, h = Widgets:Dropdown(parent, "Orientation", y,
			ORIENTATION_VALUES, ORIENTATION_ORDER,
			DBGet(cb, "orientation"), DBSet(cb, "orientation"), nil, cbDis); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Bar Backdrop", tooltip = "Show a backdrop of the bar.",
			  getValue = DBGet(cb, "backdrop"), setValue = DBSet(cb, "backdrop"), disabled = cbDis },
			{ type = "slider", text = "Backdrop Spacing", min = 1, max = 30, step = 1,
			  getValue = DBGet(cb, "backdropSpacing"), setValue = DBSet(cb, "backdropSpacing"), disabled = cbDis }
		); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "slider", text = "Button Width", min = 2, max = 80, step = 1,
			  getValue = DBGet(cb, "buttonWidth"), setValue = DBSet(cb, "buttonWidth"), disabled = cbDis },
			{ type = "slider", text = "Button Height", min = 2, max = 60, step = 1,
			  getValue = DBGet(cb, "buttonHeight"), setValue = DBSet(cb, "buttonHeight"), disabled = cbDis }
		); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "slider", text = "Spacing", min = 0, max = 80, step = 1,
			  getValue = DBGet(cb, "spacing"), setValue = DBSet(cb, "spacing"), disabled = cbDis },
			{ type = "dropdown", text = "Style",
			  values = CHATBAR_STYLE, order = CHATBAR_STYLE_ORDER,
			  getValue = DBGet(cb, "style"), setValue = DBSet(cb, "style"), disabled = cbDis }
		); y = y - h
		if cb.style == "TEXT" then
			_, h = Widgets:Toggle(parent, "Use Color", y,
				DBGet(cb, "color"), DBSet(cb, "color"), nil, cbDis); y = y - h
			y = FontSection(Widgets, parent, y, cb.font)
		end
	end

	_, h = Widgets:SectionHeader(parent, MH("Chat Link"), y); y = y - h
	do
		local cl = db.chatLink
		local clDis = function() return not cl.enable end
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(cl, "enable"), DBSet(cl, "enable"),
			"Add extra information on the link, so that you can get basic information but do not need to click."); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Level", tooltip = "Display the level of the item on the item link.",
			  getValue = DBGet(cl, "level"), setValue = DBSet(cl, "level"), disabled = clDis },
			{ type = "toggle", text = "Numerical Quality Tier", tooltip = "Use numerical quality tier rather the icon on the item link.",
			  getValue = DBGet(cl, "numericalQualityTier"), setValue = DBSet(cl, "numericalQualityTier"), disabled = clDis }
		); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Translate Item", tooltip = "Translate the name in item links into your language.",
			  getValue = DBGet(cl, "translateItem"), setValue = DBSet(cl, "translateItem"), disabled = clDis },
			{ type = "toggle", text = "Icon",
			  getValue = DBGet(cl, "icon"), setValue = DBSet(cl, "icon"), disabled = clDis }
		); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Armor Category",
			  getValue = DBGet(cl, "armorCategory"), setValue = DBSet(cl, "armorCategory"), disabled = clDis },
			{ type = "toggle", text = "Weapon Category",
			  getValue = DBGet(cl, "weaponCategory"), setValue = DBSet(cl, "weaponCategory"), disabled = clDis }
		); y = y - h
		if cl.icon then
			_, h = Widgets:DualRow(parent, y,
				{ type = "slider", text = "Icon Height", min = 10, max = 100, step = 1,
				  getValue = DBGet(cl, "iconHeight"), setValue = DBSet(cl, "iconHeight"), disabled = clDis },
				{ type = "slider", text = "Icon Width", min = 10, max = 100, step = 1,
				  getValue = DBGet(cl, "iconWidth"), setValue = DBSet(cl, "iconWidth"), disabled = clDis }
			); y = y - h
			_, h = Widgets:Toggle(parent, "Keep Size Ratio", y,
				DBGet(cl, "keepRatio"), DBSet(cl, "keepRatio"), nil, clDis); y = y - h
		end
	end

	_, h = Widgets:SectionHeader(parent, MH("Chat Text"), y); y = y - h
	do
		local ct = db.chatText
		local ctDis = function() return not ct.enable end
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(ct, "enable"), DBSet(ct, "enable"), "Modify the chat text style."); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Remove Brackets",
			  getValue = DBGet(ct, "removeBrackets"), setValue = DBSet(ct, "removeBrackets"), disabled = ctDis },
			{ type = "toggle", text = "Class Icon", tooltip = "Show the class icon before the player name.",
			  getValue = DBGet(ct, "classIcon"), setValue = DBSet(ct, "classIcon"), disabled = ctDis }
		); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Faction Icon", tooltip = "Show the faction icon before the player name.",
			  getValue = DBGet(ct, "factionIcon"), setValue = DBSet(ct, "factionIcon"), disabled = ctDis },
			{ type = "spacer" }
		); y = y - h
		_, h = Widgets:SectionHeader(parent, MH("Chat Text", "Enhancements"), y); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Guild Member Status", tooltip = "Enhance the message when a guild member comes online or goes offline.",
			  getValue = DBGet(ct, "guildMemberStatus"), setValue = DBSet(ct, "guildMemberStatus"), disabled = ctDis },
			{ type = "toggle", text = "Merge Achievement", tooltip = "Merge the achievement message into one line.",
			  getValue = DBGet(ct, "mergeAchievement"), setValue = DBSet(ct, "mergeAchievement"), disabled = ctDis }
		); y = y - h
		_, h = Widgets:SectionHeader(parent, MH("Chat Text", "Character Name"), y); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Remove Realm",
			  getValue = DBGet(ct, "removeRealm"), setValue = DBSet(ct, "removeRealm"), disabled = ctDis },
			{ type = "slider", text = "Role Icon Size", min = 5, max = 25, step = 1,
			  getValue = DBGet(ct, "roleIconSize"), setValue = DBSet(ct, "roleIconSize"), disabled = ctDis }
		); y = y - h
		_, h = Widgets:Dropdown(parent, "Channel Abbreviation", y,
			ABBR_VALUES, ABBR_ORDER,
			DBGet(ct, "abbreviation"), DBSet(ct, "abbreviation"),
			"Modify the style of abbreviation of channels.", ctDis); y = y - h
		_, h = KeyValueEditorButton(Widgets, parent, y, {
			label = "Custom Abbreviations",
			title = "Custom Abbreviations",
			map = ct.customAbbreviation,
			keyLabel = "Channel Name",
			valueLabel = "Abbreviation",
			removeLabel = "Channel Name",
			invalidMessage = "Channel Name and Abbreviation are required.",
			notFoundMessage = "Custom abbreviation not found.",
			disabled = ctDis,
		}); y = y - h
	end

	_, h = Widgets:SectionHeader(parent, MH("Context Menu"), y); y = y - h
	do
		local cm = db.contextMenu
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(cm, "enable"), DBSet(cm, "enable"),
			"Add features to context menu based on menu types."); y = y - h
		_, h = Widgets:Toggle(parent, "Section Title", y,
			DBGet(cm, "sectionTitle"), DBSet(cm, "sectionTitle"),
			"Add a styled section title to the context menu."); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Guild Invite",
			  getValue = DBGet(cm, "guildInvite"), setValue = DBSet(cm, "guildInvite") },
			{ type = "toggle", text = "Who",
			  getValue = DBGet(cm, "who"), setValue = DBSet(cm, "who") }
		); y = y - h
		_, h = Widgets:Toggle(parent, "Report Stats", y,
			DBGet(cm, "reportStats"), DBSet(cm, "reportStats")); y = y - h
	end

	_, h = Widgets:SectionHeader(parent, MH("Emote"), y); y = y - h
	do
		local we = db.emote
		local weDis = function() return not we.enable end
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(we, "enable"), DBSet(we, "enable"),
			"Parse emote expression from other players."); y = y - h
		_, h = Widgets:Slider(parent, "Emote Icon Size", y, 5, 35, 1,
			DBGet(we, "size"), DBSet(we, "size"), nil, weDis); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Use Emote Panel", tooltip = "Press { to active the emote select window.",
			  getValue = DBGet(we, "panel"), setValue = DBSet(we, "panel"), disabled = weDis },
			{ type = "toggle", text = "Chat Bubbles",
			  getValue = DBGet(we, "chatBubbles"), setValue = DBSet(we, "chatBubbles"), disabled = weDis }
		); y = y - h
	end

	_, h = Widgets:SectionHeader(parent, MH("Friend List"), y); y = y - h
	do
		local fl = db.friendList
		local flDis = function() return not fl.enable end
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(fl, "enable"), DBSet(fl, "enable"),
			"Add additional information to the friend frame."); y = y - h

		_, h = Widgets:SectionHeader(parent, MH("Friend List", "Texture Replacement"), y); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "dropdown", text = "Status Icon Pack",
			  values = FRIEND_STATUS_VALUES, order = FRIEND_STATUS_ORDER,
			  getValue = DBGet2(fl, "textures", "status"), setValue = DBSet2(fl, "textures", "status"), disabled = flDis },
			{ type = "dropdown", text = "Game Icon Style for WoW",
			  values = FRIEND_GAME_ICON_VALUES, order = FRIEND_GAME_ICON_ORDER,
			  getValue = DBGet2(fl, "textures", "gameIcon"), setValue = DBSet2(fl, "textures", "gameIcon"), disabled = flDis }
		); y = y - h

		_, h = Widgets:SectionHeader(parent, MH("Friend List", "Name"), y); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Level",
			  getValue = DBGet(fl, "level"), setValue = DBSet(fl, "level"), disabled = flDis },
			{ type = "toggle", text = "Hide Max Level",
			  getValue = DBGet(fl, "hideMaxLevel"), setValue = DBSet(fl, "hideMaxLevel"), disabled = flDis }
		); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Use Note As Name", tooltip = "Replace the Real ID or the character name of friends with your notes.",
			  getValue = DBGet(fl, "useNoteAsName"), setValue = DBSet(fl, "useNoteAsName"), disabled = flDis },
			{ type = "toggle", text = "Use Class Color",
			  getValue = DBGet(fl, "useClassColor"), setValue = DBSet(fl, "useClassColor"), disabled = flDis }
		); y = y - h
		y = FontSection(Widgets, parent, y, fl.nameFont)

		_, h = Widgets:SectionHeader(parent, MH("Friend List", "Information"), y); y = y - h
		_, h = Widgets:Toggle(parent, "Hide Realm", y,
			DBGet(fl, "hideRealm"), DBSet(fl, "hideRealm"),
			"Hide the realm name of friends.", flDis); y = y - h
		y = FontSection(Widgets, parent, y, fl.infoFont)
	end

	_, h = Widgets:SectionHeader(parent, MH("Smart Tab"), y); y = y - h
	do
		local st = db.smartTab
		local stDis = function() return not st.enable end
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(st, "enable"), DBSet(st, "enable"),
			"This module will change the channel when Tab has been pressed."); y = y - h

		_, h = Widgets:SectionHeader(parent, MH("Smart Tab", "Channel"), y); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Yell",
			  getValue = DBGet(st, "yell"), setValue = DBSet(st, "yell"), disabled = stDis },
			{ type = "toggle", text = "Battleground",
			  getValue = DBGet(st, "battleground"), setValue = DBSet(st, "battleground"), disabled = stDis }
		); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Raid Warning",
			  getValue = DBGet(st, "raidWarning"), setValue = DBSet(st, "raidWarning"), disabled = stDis },
			{ type = "toggle", text = "Officer",
			  getValue = DBGet(st, "officer"), setValue = DBSet(st, "officer"), disabled = stDis }
		); y = y - h

		_, h = Widgets:SectionHeader(parent, MH("Smart Tab", "Whisper"), y); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Whisper Cycle",
			  getValue = DBGet(st, "whisperCycle"), setValue = DBSet(st, "whisperCycle"), disabled = stDis },
			{ type = "slider", text = "Expiration time (min)", min = 1, max = 2400, step = 1,
			  getValue = DBGet(st, "historyLimit"), setValue = DBSet(st, "historyLimit"), disabled = stDis }
		); y = y - h
	end

	return y
end)
