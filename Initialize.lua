local addonName, addon = ...

local EUI = _G.EllesmereUI
if not EUI or not EUI.Lite then
	local frame = _G.DEFAULT_CHAT_FRAME
	if frame then
		frame:AddMessage("EllesmereUI_WindTools requires EllesmereUI to load first.")
	end
	return
end

local CreateCompatE = addon.CreateCompatE
local InstallModuleSystem = addon.InstallModuleSystem
if not CreateCompatE or not InstallModuleSystem then
	local frame = _G.DEFAULT_CHAT_FRAME
	if frame then
		frame:AddMessage("EllesmereUI_WindTools compat layer did not load.")
	end
	return
end

local xpcall = xpcall
local geterrorhandler = geterrorhandler
local function SafeCall(func, ...)
	if type(func) == "function" then
		return xpcall(func, function(err) return geterrorhandler()(err) end, ...)
	end
end

local function L(text)
	return EUI.L and EUI.L(text) or text
end

local E = CreateCompatE()
local W = EUI.Lite.NewAddon(addonName)
InstallModuleSystem(W)

local V, P, G = {}, {}, {}

addon[1] = W
addon[2] = {}
addon[3] = E
addon[4] = setmetatable({}, { __index = function(_, key) return L(key) end })
addon[5] = V
addon[6] = P
addon[7] = G

_WindTools = addon
_G.WindTools = addon

W.Title = "WindTools"
W.DisplayVersion = C_AddOns.GetAddOnMetadata(addonName, "X-Version") or "4.18"
W.Version = W.DisplayVersion
W.Utilities = W.Utilities or {}

W.Modules.Misc = W:NewModule("Misc")
W.Modules.Skins = W:NewModule("Skins")
W.Modules.Tooltips = W:NewModule("Tooltips")
W.Modules.MoveFrames = W:NewModule("MoveFrames")
W:NewModule("QuestProgress")

E:AddLib("OpenRaid", "LibOpenRaid-1.0")
E:AddLib("ObjectiveProgressWT", "LibObjectiveProgress-WT")
E:AddLib("RangeCheck", "LibRangeCheck-3.0")
E:AddLib("Keystone", "LibKeystone")
E:AddLib("WTItemEnchant", "LibItemEnchant-WT")

local db

local function InitDB()
	if db then return end

	db = EUI.Lite.NewDB("EllesmereUI_WindToolsDB", { profile = P })
	E.db.WT = db.profile

	_G.WindToolsGlobalDB = _G.WindToolsGlobalDB or {}
	if EUI.Lite.DeepMergeDefaults then
		EUI.Lite.DeepMergeDefaults(_G.WindToolsGlobalDB, G)
	end
	E.global.WT = _G.WindToolsGlobalDB

	_G.WindToolsPrivateDB = _G.WindToolsPrivateDB or {}
	if EUI.Lite.DeepMergeDefaults then
		EUI.Lite.DeepMergeDefaults(_G.WindToolsPrivateDB, V)
	end
	E.private.WT = _G.WindToolsPrivateDB

	W.db = db
end

local function Print(...)
	if EUI.Print then
		EUI.Print("|cff0cd29f[WindTools]|r", ...)
	end
end

local CATEGORIES = {
	{
		key = "item", page = "Item", title = "Item",
		description = "Item, merchant, mail, inspect, and equipment quality-of-life options.",
		modules = {
			{ key = "alreadyKnown", label = "Already Known", note = "Mark recipes, toys, and appearances already known by the character." },
			{ key = "contacts", label = "Contacts", note = "Mail contact favorites, alts, and recipient helpers." },
			{ key = "deleteItem", label = "Delete Item", note = "Fast delete confirmation and protected item helpers." },
			{ key = "extendMerchantPages", label = "Extend Merchant Pages", note = "Additional merchant page controls." },
			{ key = "extraItemsBar", label = "Extra Items Bar", note = "Bars for quest, consumable, equipment, and custom tracked items." },
			{ key = "fastLoot", label = "Fast Loot", note = "Accelerated loot window behavior." },
			{ key = "inspect", label = "Inspect", note = "Inspect frame enhancements and character information." },
			{ key = "itemLevel", label = "Item Level", note = "Item level overlays and display tweaks." },
			{ key = "trade", label = "Trade", note = "Trade window convenience behavior." },
		},
	},
	{
		key = "combat", page = "Combat", title = "Combat",
		description = "Combat feedback, markers, keystone helpers, and meter layout options.",
		modules = {
			{ key = "combatAlert", label = "Combat Alert", note = "Enter/leave combat visual and audio alerts." },
			{ key = "destroyTotem", label = "Destroy Totem", note = "Key-driven hostile totem targeting helpers." },
			{ key = "quickKeystone", label = "Quick Keystone", note = "Mythic Keystone convenience interactions." },
			{ key = "raidMarkers", label = "Raid Markers", note = "Raid marker and world marker bar." },
			{ key = "damageMeterLayout", label = "Damage Meter Layout", note = "Details window layout and auto-switching helpers." },
		},
	},
	{
		key = "maps", page = "Maps", title = "Maps",
		description = "World map, minimap, tracker, and event display options.",
		modules = {
			{ key = "eventTracker", label = "Event Tracker", note = "Track time-limited world events." },
			{ key = "instanceDifficulty", label = "Instance Difficulty", note = "Instance difficulty text and map display." },
			{ key = "minimapButtons", label = "Minimap Buttons", note = "Collect and arrange minimap addon buttons." },
			{ key = "rectangleMinimap", label = "Rectangle Minimap", note = "Rectangular minimap layout." },
			{ key = "superTracker", label = "Super Tracker", note = "Waypoint, distance, and objective tracker helpers." },
			{ key = "worldMap", label = "World Map", note = "World map reveal, scale, and interaction tweaks." },
		},
	},
	{
		key = "quest", page = "Quest & Achieve", title = "Quest & Achieve",
		description = "Quest tracker, achievement tracker, objective progress, and turn-in options.",
		modules = {
			{ key = "achievementScreenshot", label = "Achievement Screenshot", note = "Automatic screenshots for achievements." },
			{ key = "achievementTracker", label = "Achievement Tracker", note = "Achievement objective tracking enhancements." },
			{ key = "autoCollapse", label = "Auto Collapse", note = "Objective tracker auto-collapse behavior." },
			{ key = "objectiveTracker", label = "Objective Tracker", note = "Objective tracker style and behavior tweaks." },
			{ key = "preyHunt", label = "Prey Hunt", note = "Prey hunt tracking helpers." },
			{ key = "progress", label = "Quest Progress", note = "Quest progress text and template helpers." },
			{ key = "switchButtons", label = "Switch Buttons", note = "Quest/achievement switch button helpers." },
			{ key = "turnIn", label = "Turn In", note = "Quest gossip and turn-in automation." },
		},
	},
	{
		key = "social", page = "Social", title = "Social",
		description = "Chat, links, emotes, friends, and context menu options.",
		modules = {
			{ key = "chatBar", label = "Chat Bar", note = "Chat channel button bar." },
			{ key = "chatText", label = "Chat Text", note = "Chat text formatting, copy, and quality-of-life tweaks." },
			{ key = "chatLink", label = "Chat Link", note = "Enhanced chat hyperlinks." },
			{ key = "contextMenu", label = "Context Menu", note = "Right-click menu additions." },
			{ key = "emote", label = "Emote", note = "Custom chat emote textures and parsing." },
			{ key = "friendList", label = "Friend List", note = "Friend list enhancements." },
			{ key = "smartTab", label = "Smart Tab", note = "Chat editbox tab completion helpers." },
		},
	},
	{
		key = "announcement", page = "Announcement", title = "Announcement",
		description = "Automatic group, quest, keystone, and utility announcement options.",
		modules = {
			{ key = "goodbye", label = "Goodbye", note = "Automatically send goodbye messages." },
			{ key = "keystone", label = "Keystone", note = "Announce owned or changed keystones." },
			{ key = "quest", label = "Quest", note = "Announce quest progress to group channels." },
			{ key = "resetInstance", label = "Reset Instance", note = "Announce instance reset and difficulty changes." },
			{ key = "utility", label = "Utility", note = "Announce feasts, portals, toys, bots, and custom spells." },
		},
	},
	{
		key = "tooltips", page = "Tooltips", title = "Tooltips", deferred = true,
		description = "Tooltip information, Mythic Plus, progression, and item-set options.",
		modules = {
			{ key = "mythicPlus", label = "Mythic Plus", note = "Depends on Tooltip internals." },
			{ key = "unitInfo", label = "Unit Info", note = "Unit details in GameTooltip." },
			{ key = "groupInfo", label = "Group Info", note = "LFG and group details in tooltip." },
			{ key = "healthBar", label = "Health Bar", note = "Tooltip health bar tweaks." },
			{ key = "icons", label = "Icons", note = "Tooltip icon additions." },
			{ key = "keystone", label = "Keystone", note = "Keystone tooltip enrichment." },
			{ key = "objectiveProgress", label = "Objective Progress", note = "Objective progress tooltip data." },
			{ key = "progression", label = "Progression", note = "Raid and dungeon progression tooltip data." },
			{ key = "tierSet", label = "Tier Set", note = "Tier set information in item tooltips." },
		},
	},
	{
		key = "unitFrames", page = "Unit Frames", title = "Unit Frames", deferred = true,
		description = "Unit frame tags, absorb, role icon, focus, and name clipping options.",
		modules = {
			{ key = "absorb", label = "Absorb", note = "Depends on UnitFrames heal prediction internals." },
			{ key = "nameClip", label = "Name Clip", note = "Depends on UnitFrames name positioning internals." },
			{ key = "quickFocus", label = "Quick Focus", note = "Focus helpers tied to unit frame behavior." },
			{ key = "roleIcon", label = "Role Icon", note = "Unit frame role icon replacements." },
			{ key = "tags", label = "Tags", note = "Tag system integration needs replacement." },
		},
	},
	{
		key = "skins", page = "Skins", title = "Skins", deferred = true,
		description = "Blizzard, widget, library, and third-party addon skin options.",
		modules = {
			{ key = "core", label = "Core", note = "Skin engine and shared helpers." },
			{ key = "blizzard", label = "Blizzard", note = "Large set of Blizzard frame skins." },
			{ key = "addons", label = "Addons", note = "Third-party addon skins." },
			{ key = "libraries", label = "Libraries", note = "Library-provided widget skins." },
			{ key = "widgets", label = "Widgets", note = "AceGUI and shared widget skins." },
			{ key = "textureString", label = "Texture String", note = "Texture-string replacement helpers." },
			{ key = "vignetting", label = "Vignetting", note = "Screen edge visual effect." },
		},
	},
	{
		key = "misc", page = "Misc", title = "Misc",
		description = "General quality-of-life, automation, LFG, frame movement, and utility options.",
		modules = {
			{ key = "addCNFilter", label = "Add CN Filter", note = "Chinese-region text filter additions." },
			{ key = "antiOverride", label = "Anti Override", note = "Prevent unwanted action bar override behavior." },
			{ key = "autoToggleChatBubble", label = "Auto Toggle Chat Bubble", note = "Context-aware chat bubble toggling." },
			{ key = "disableTalkingHead", label = "Disable Talking Head", note = "Hide talking head frames." },
			{ key = "exitPhaseDiving", label = "Exit Phase Diving", note = "Exit button for phase diving states." },
			{ key = "extraBindingButtons", label = "Extra Binding Buttons", note = "Extra bind-only action buttons." },
			{ key = "gameBar", label = "Game Bar", note = "Micro menu and utility button bar." },
			{ key = "guildNewsItemLevel", label = "Guild News Item Level", note = "Item level in guild news entries." },
			{ key = "hideCrafter", label = "Hide Crafter", note = "Hide crafter name in some item contexts." },
			{ key = "keybindAlias", label = "Keybind Alias", note = "Display aliases for keybind text." },
			{ key = "keybindTextAbove", label = "Keybind Text Above", note = "Move action button keybind text above icons." },
			{ key = "lfgList", label = "LFG List", note = "Group finder filtering and visual helpers." },
			{ key = "lootPanel", label = "Loot Panel", note = "Loot display helpers." },
			{ key = "math", label = "Math", note = "Chat math expression helpers." },
			{ key = "moveFrames", label = "Move Frames", note = "Frame movement and remembered positions." },
			{ key = "mute", label = "Mute", note = "Mute selected annoying sounds." },
			{ key = "pauseToSlash", label = "Pause to Slash", note = "Convert full-width punctuation into slash commands." },
			{ key = "reshiiWrapsUpgrade", label = "Reshii Wraps Upgrade", note = "Expansion-specific upgrade helper." },
			{ key = "skipCutScene", label = "Skip Cutscene", note = "Cutscene skip and watched-state behavior." },
			{ key = "spellActivationAlert", label = "Spell Activation Alert", note = "Spell activation alert visual tweaks." },
		},
	},
	{
		key = "advanced", page = "Advanced", title = "Advanced",
		description = "Migration, compatibility, profile, and developer-oriented settings.",
		modules = {},
	},
	{
		key = "information", page = "Information", title = "Information",
		description = "Credits, links, help, and migration notes.",
		modules = {},
	},
}

local PAGE_GROUPS = {
	{ page = "Items & Combat", categories = { "item", "combat", "announcement" } },
	{ page = "World & Quest", categories = { "maps", "quest", "misc" } },
	{ page = "Interface", categories = { "tooltips", "unitFrames", "skins" } },
	{ page = "Social", categories = { "social" } },
	{ page = "Advanced", categories = { "advanced", "information" } },
}

local PAGE_NAMES = {}
local CATEGORY_BY_KEY = {}
local GROUP_BY_PAGE = {}
for _, group in ipairs(PAGE_GROUPS) do
	PAGE_NAMES[#PAGE_NAMES + 1] = group.page
	GROUP_BY_PAGE[group.page] = group
end
for _, category in ipairs(CATEGORIES) do
	CATEGORY_BY_KEY[category.key] = category
end

local function RenderCategoryFallback(category, parent, y)
	local Widgets = EllesmereUI.Widgets
	local dummy, h

	dummy, h = Widgets:SectionHeader(parent, L(category.title), y); y = y - h

	for _, module in ipairs(category.modules) do
		local label = L(module.label)
		local tooltip = L(module.note)

		local dbPath = E.db.WT and E.db.WT[category.key] and E.db.WT[category.key][module.key]
		local getValue = type(dbPath) == "table" and function()
			return dbPath.enable ~= nil and dbPath.enable or false
		end or function() return false end

		local setValue = type(dbPath) == "table" and function(value)
			dbPath.enable = value
		end or function(value) end

		dummy, h = Widgets:Toggle(parent, label, y, getValue, setValue, tooltip); y = y - h
	end

	return y
end

local function RenderCategoryPage(category, parent, y)
	local builder = addon.OptionBuilders and addon.OptionBuilders[category.key]
	if builder then
		return builder(parent, y)
	end
	return RenderCategoryFallback(category, parent, y)
end

local function BuildPage(pageName, parent, yOffset)
	local y = yOffset or -6
	local group = GROUP_BY_PAGE[pageName]
	if group and group.categories then
		for index, categoryKey in ipairs(group.categories) do
			local category = CATEGORY_BY_KEY[categoryKey]
			if category then
				if index > 1 then
					y = y - 10
				end
				y = RenderCategoryPage(category, parent, y)
			end
		end
	end
	return math.abs(y) + 30
end

local function RegisterExternalModule()
	if not EUI.RegisterExternalModule then
		Print("RegisterExternalModule is unavailable; update EllesmereUI.")
		return
	end

	local ok, err = EUI.RegisterExternalModule({
		folder = addonName,
		display = "WindTools",
		apiVersion = EUI.API_VERSION,
		title = "WindTools",
		description = "WindTools for EllesmereUI.",
		pages = PAGE_NAMES,
		buildPage = BuildPage,
		searchTerms = { "windtools", "wt", "item", "combat", "maps", "quest", "social", "announcement", "tooltips", "unitframes", "skins", "misc", "advanced" },
		onReset = function()
			if db then db:ResetProfile() end
		end,
	})

	if not ok then
		Print("external registration failed:", tostring(err))
	end
end

function W:OnProfileChanged()
	self:UpdateModules()
end

W:RegisterEvent("PLAYER_LOGIN", function()
	InitDB()
	W.initialized = true
	SafeCall(W.InitializeModules, W)
	RegisterExternalModule()
	if EUI.RegisterModuleCallback then
		EUI.RegisterModuleCallback(W, "ProfileChanged", "OnProfileChanged")
	end
	if db and db.profile.core and db.profile.core.loginMessage then
		Print("loaded for EllesmereUI.")
	end
end)

_G.WindTools_OnAddonCompartmentClick = function()
	if EUI.Toggle then
		EUI:Toggle()
	elseif EUI.OpenOptions then
		EUI:OpenOptions()
	else
		Print("Open EllesmereUI options and select WindTools under External.")
	end
end
