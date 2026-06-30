local addon = select(2, ...)
local W = addon[1]
local E = addon[3]
local DBGet = addon.DBGet
local DBSet = addon.DBSet
local DBGet2 = addon.DBGet2
local DBSet2 = addon.DBSet2

local CHANNEL_PARTY = {
	NONE = "None", SELF = "Self (Chat Frame)", EMOTE = "Emote",
	PARTY = "Party", YELL = "Yell", SAY = "Say",
}
local CHANNEL_PARTY_ORDER = { "NONE", "SELF", "EMOTE", "PARTY", "YELL", "SAY" }

local CHANNEL_INSTANCE = {
	NONE = "None", PARTY = "Party", SELF = "Self (Chat Frame)", EMOTE = "Emote",
	INSTANCE_CHAT = "Instance", YELL = "Yell", SAY = "Say",
}
local CHANNEL_INSTANCE_ORDER = { "NONE", "PARTY", "SELF", "EMOTE", "INSTANCE_CHAT", "YELL", "SAY" }

local CHANNEL_RAID = {
	NONE = "None", SELF = "Self (Chat Frame)", EMOTE = "Emote",
	PARTY = "Party", RAID = "Raid", YELL = "Yell", SAY = "Say",
}
local CHANNEL_RAID_ORDER = { "NONE", "SELF", "EMOTE", "PARTY", "RAID", "YELL", "SAY" }

local CHANNEL_SOLO = {
	NONE = "None", SELF = "Self (Chat Frame)", EMOTE = "Emote",
	YELL = "Yell", SAY = "Say",
}
local CHANNEL_SOLO_ORDER = { "NONE", "SELF", "EMOTE", "YELL", "SAY" }

local UTILITY_CATEGORIES = {
	{ key = "feast", name = "Feasts" },
	{ key = "toy", name = "Toys" },
	{ key = "bot", name = "Bots" },
	{ key = "portal", name = "Portals" },
	{ key = "spell", name = "Spell" },
}

addon.RegisterOptionBuilder("announcement", function(parent, y, cat)
	local Widgets = EllesmereUI.Widgets
	local MH = function(mod, sub) return addon.MakeHeader(cat, mod, sub) end
	local _, h
	local db = E.db.WT.announcement

	_, h = Widgets:SectionHeader(parent, MH("General"), y); y = y - h
	_, h = Widgets:Slider(parent, "Same Message Interval", y, 0, 3600, 1,
		DBGet(db, "sameMessageInterval"), DBSet(db, "sameMessageInterval"),
		"Time interval between sending same messages measured in seconds. Set to 0 to disable."); y = y - h

	_, h = Widgets:SectionHeader(parent, MH("Quest"), y); y = y - h
	do
		local q = db.quest
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(q, "enable"), DBSet(q, "enable"),
			"Let your teammates know the progress of quests."); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Include Details", tooltip = "Announce every time the progress has been changed.",
			  getValue = DBGet(q, "includeDetails"), setValue = DBSet(q, "includeDetails") },
			{ type = "spacer" }
		); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Hide Level on Max Level",
			  tooltip = "Do not show quest level if the quest level is the same as the maximum level of your current expansion.",
			  getValue = DBGet(q, "hideLevelOnMaxLevel"), setValue = DBSet(q, "hideLevelOnMaxLevel") },
			{ type = "toggle", text = "Hide Level if Same as Player",
			  tooltip = "Do not show quest level if the quest level is the same as your current level.",
			  getValue = DBGet(q, "hideLevelIfSameAsPlayer"), setValue = DBSet(q, "hideLevelIfSameAsPlayer") }
		); y = y - h

		_, h = Widgets:Dropdown(parent, "In Party", y,
			CHANNEL_PARTY, CHANNEL_PARTY_ORDER,
			DBGet2(q, "channel", "party"), DBSet2(q, "channel", "party")); y = y - h
		_, h = Widgets:Dropdown(parent, "In Instance", y,
			CHANNEL_INSTANCE, CHANNEL_INSTANCE_ORDER,
			DBGet2(q, "channel", "instance"), DBSet2(q, "channel", "instance")); y = y - h
		_, h = Widgets:Dropdown(parent, "In Raid", y,
			CHANNEL_RAID, CHANNEL_RAID_ORDER,
			DBGet2(q, "channel", "raid"), DBSet2(q, "channel", "raid")); y = y - h
	end

	_, h = Widgets:SectionHeader(parent, MH("Utility"), y); y = y - h
	do
		local u = db.utility
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(u, "enable"), DBSet(u, "enable"),
			"Send the use of portals, ritual of summoning, feasts, etc."); y = y - h

		_, h = Widgets:Dropdown(parent, "Solo", y,
			CHANNEL_SOLO, CHANNEL_SOLO_ORDER,
			function() return u.channel and u.channel.solo end,
			function(v) u.channel = u.channel or {}; u.channel.solo = v end); y = y - h
		_, h = Widgets:Dropdown(parent, "In Party", y,
			CHANNEL_PARTY, CHANNEL_PARTY_ORDER,
			function() return u.channel and u.channel.party end,
			function(v) u.channel = u.channel or {}; u.channel.party = v end); y = y - h
		_, h = Widgets:Dropdown(parent, "In Instance", y,
			CHANNEL_INSTANCE, CHANNEL_INSTANCE_ORDER,
			function() return u.channel and u.channel.instance end,
			function(v) u.channel = u.channel or {}; u.channel.instance = v end); y = y - h
		_, h = Widgets:Dropdown(parent, "In Raid", y,
			CHANNEL_RAID, CHANNEL_RAID_ORDER,
			function() return u.channel and u.channel.raid end,
			function(v) u.channel = u.channel or {}; u.channel.raid = v end); y = y - h

		for _, cat in ipairs(UTILITY_CATEGORIES) do
			local cd = u.general and u.general[cat.key]
			if cd then
				_, h = Widgets:SectionHeader(parent, MH("Utility", cat.name), y); y = y - h
				_, h = Widgets:DualRow(parent, y,
					{ type = "toggle", text = "Enable",
					  getValue = DBGet(cd, "enable"), setValue = DBSet(cd, "enable") },
					{ type = "toggle", text = "Raid Warning", tooltip = "If possible, send the announcement as a raid warning.",
					  getValue = DBGet(cd, "raidWarning"), setValue = DBSet(cd, "raidWarning") }
				); y = y - h
			end
		end
	end

	_, h = Widgets:SectionHeader(parent, MH("Goodbye"), y); y = y - h
	do
		local gb = db.goodbye
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(gb, "enable"), DBSet(gb, "enable"),
			"Say goodbye after dungeon completed."); y = y - h
		_, h = Widgets:Slider(parent, "Delay (sec)", y, 0, 20, 1,
			DBGet(gb, "delay"), DBSet(gb, "delay")); y = y - h

		_, h = Widgets:DualRow(parent, y,
			{ type = "dropdown", text = "In Party",
			  values = { NONE = "None", EMOTE = "Emote", PARTY = "Party", YELL = "Yell", SAY = "Say" },
			  order = { "NONE", "EMOTE", "PARTY", "YELL", "SAY" },
			  getValue = DBGet2(gb, "channel", "party"), setValue = DBSet2(gb, "channel", "party") },
			{ type = "dropdown", text = "In Instance",
			  values = { NONE = "None", EMOTE = "Emote", PARTY = "Party", INSTANCE_CHAT = "Instance", YELL = "Yell", SAY = "Say" },
			  order = { "NONE", "EMOTE", "PARTY", "INSTANCE_CHAT", "YELL", "SAY" },
			  getValue = DBGet2(gb, "channel", "instance"), setValue = DBSet2(gb, "channel", "instance") }
		); y = y - h
		_, h = Widgets:Dropdown(parent, "In Raid", y,
			CHANNEL_RAID, CHANNEL_RAID_ORDER,
			DBGet2(gb, "channel", "raid"), DBSet2(gb, "channel", "raid")); y = y - h
	end

	_, h = Widgets:SectionHeader(parent, MH("Reset Instance"), y); y = y - h
	do
		local ri = db.resetInstance
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(ri, "enable"), DBSet(ri, "enable"),
			"Send a message after instance resetting."); y = y - h
		_, h = Widgets:Toggle(parent, "Difficulty Change", y,
			DBGet(ri, "difficultyChange"), DBSet(ri, "difficultyChange"),
			"Also announce when you change the instance difficulty."); y = y - h

		_, h = Widgets:Dropdown(parent, "In Party", y,
			CHANNEL_PARTY, CHANNEL_PARTY_ORDER,
			DBGet2(ri, "channel", "party"), DBSet2(ri, "channel", "party")); y = y - h
		_, h = Widgets:Dropdown(parent, "In Instance", y,
			CHANNEL_INSTANCE, CHANNEL_INSTANCE_ORDER,
			DBGet2(ri, "channel", "instance"), DBSet2(ri, "channel", "instance")); y = y - h
		_, h = Widgets:Dropdown(parent, "In Raid", y,
			CHANNEL_RAID, CHANNEL_RAID_ORDER,
			DBGet2(ri, "channel", "raid"), DBSet2(ri, "channel", "raid")); y = y - h
	end

	_, h = Widgets:SectionHeader(parent, MH("Keystone"), y); y = y - h
	do
		local ks = db.keystone
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(ks, "enable"), DBSet(ks, "enable"),
			"Announce your mythic keystone."); y = y - h
		_, h = Widgets:Toggle(parent, "!keys Command", y,
			DBGet(ks, "command"), DBSet(ks, "command"),
			"Send the keystone to party or guild chat when someone use !keys command."); y = y - h

		_, h = Widgets:Dropdown(parent, "In Party", y,
			CHANNEL_PARTY, CHANNEL_PARTY_ORDER,
			DBGet2(ks, "channel", "party"), DBSet2(ks, "channel", "party")); y = y - h
	end

	return y
end)
