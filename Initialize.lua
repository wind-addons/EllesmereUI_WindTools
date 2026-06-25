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

local function L(text)
	return EUI.L and EUI.L(text) or text
end

local CATEGORIES = {
	{
		key = "item",
		page = "Item",
		title = "Item",
		description = "Item, merchant, mail, inspect, and equipment quality-of-life options.",
		status = "Disconnected",
		modules = {
			{ key = "alreadyKnown", label = "Already Known", status = "Disconnected", note = "Mark recipes, toys, and appearances already known by the character." },
			{ key = "contacts", label = "Contacts", status = "Disconnected", note = "Mail contact favorites, alts, and recipient helpers." },
			{ key = "deleteItem", label = "Delete Item", status = "Disconnected", note = "Fast delete confirmation and protected item helpers." },
			{ key = "extendMerchantPages", label = "Extend Merchant Pages", status = "Disconnected", note = "Additional merchant page controls." },
			{ key = "extraItemsBar", label = "Extra Items Bar", status = "Disconnected", note = "Bars for quest, consumable, equipment, and custom tracked items." },
			{ key = "fastLoot", label = "Fast Loot", status = "Disconnected", note = "Accelerated loot window behavior." },
			{ key = "inspect", label = "Inspect", status = "Disconnected", note = "Inspect frame enhancements and character information." },
			{ key = "itemLevel", label = "Item Level", status = "Disconnected", note = "Item level overlays and display tweaks." },
			{ key = "trade", label = "Trade", status = "Disconnected", note = "Trade window convenience behavior." },
		},
	},
	{
		key = "combat",
		page = "Combat",
		title = "Combat",
		description = "Combat feedback, markers, keystone helpers, and meter layout options.",
		status = "Disconnected",
		modules = {
			{ key = "combatAlert", label = "Combat Alert", status = "Disconnected", note = "Enter/leave combat visual and audio alerts." },
			{ key = "destroyTotem", label = "Destroy Totem", status = "Disconnected", note = "Key-driven hostile totem targeting helpers." },
			{ key = "quickKeystone", label = "Quick Keystone", status = "Disconnected", note = "Mythic Keystone convenience interactions." },
			{ key = "raidMarkers", label = "Raid Markers", status = "Disconnected", note = "Raid marker and world marker bar." },
			{ key = "damageMeterLayout", label = "Damage Meter Layout", status = "Disconnected", note = "Details window layout and auto-switching helpers." },
		},
	},
	{
		key = "maps",
		page = "Maps",
		title = "Maps",
		description = "World map, minimap, tracker, and event display options.",
		status = "Disconnected",
		modules = {
			{ key = "eventTracker", label = "Event Tracker", status = "Disconnected", note = "Track time-limited world events." },
			{ key = "instanceDifficulty", label = "Instance Difficulty", status = "Disconnected", note = "Instance difficulty text and map display." },
			{ key = "minimapButtons", label = "Minimap Buttons", status = "Disconnected", note = "Collect and arrange minimap addon buttons." },
			{ key = "rectangleMinimap", label = "Rectangle Minimap", status = "Disconnected", note = "Rectangular minimap layout." },
			{ key = "superTracker", label = "Super Tracker", status = "Disconnected", note = "Waypoint, distance, and objective tracker helpers." },
			{ key = "worldMap", label = "World Map", status = "Disconnected", note = "World map reveal, scale, and interaction tweaks." },
		},
	},
	{
		key = "quest",
		page = "Quest & Achieve",
		title = "Quest & Achieve",
		description = "Quest tracker, achievement tracker, objective progress, and turn-in options.",
		status = "Disconnected",
		modules = {
			{ key = "achievementScreenshot", label = "Achievement Screenshot", status = "Disconnected", note = "Automatic screenshots for achievements." },
			{ key = "achievementTracker", label = "Achievement Tracker", status = "Disconnected", note = "Achievement objective tracking enhancements." },
			{ key = "autoCollapse", label = "Auto Collapse", status = "Disconnected", note = "Objective tracker auto-collapse behavior." },
			{ key = "objectiveTracker", label = "Objective Tracker", status = "Disconnected", note = "Objective tracker style and behavior tweaks." },
			{ key = "preyHunt", label = "Prey Hunt", status = "Disconnected", note = "Prey hunt tracking helpers." },
			{ key = "progress", label = "Quest Progress", status = "Disconnected", note = "Quest progress text and template helpers." },
			{ key = "switchButtons", label = "Switch Buttons", status = "Disconnected", note = "Quest/achievement switch button helpers." },
			{ key = "turnIn", label = "Turn In", status = "Disconnected", note = "Quest gossip and turn-in automation." },
		},
	},
	{
		key = "social",
		page = "Social",
		title = "Social",
		description = "Chat, links, emotes, friends, and context menu options.",
		status = "Disconnected",
		modules = {
			{ key = "chatBar", label = "Chat Bar", status = "Disconnected", note = "Chat channel button bar." },
			{ key = "chatText", label = "Chat Text", status = "Disconnected", note = "Chat text formatting, copy, and quality-of-life tweaks." },
			{ key = "chatLink", label = "Chat Link", status = "Disconnected", note = "Enhanced chat hyperlinks." },
			{ key = "contextMenu", label = "Context Menu", status = "Disconnected", note = "Right-click menu additions." },
			{ key = "emote", label = "Emote", status = "Disconnected", note = "Custom chat emote textures and parsing." },
			{ key = "friendList", label = "Friend List", status = "Disconnected", note = "Friend list enhancements." },
			{ key = "smartTab", label = "Smart Tab", status = "Disconnected", note = "Chat editbox tab completion helpers." },
		},
	},
	{
		key = "announcement",
		page = "Announcement",
		title = "Announcement",
		description = "Automatic group, quest, keystone, and utility announcement options.",
		status = "Disconnected",
		modules = {
			{ key = "goodbye", label = "Goodbye", status = "Disconnected", note = "Automatically send goodbye messages." },
			{ key = "keystone", label = "Keystone", status = "Disconnected", note = "Announce owned or changed keystones." },
			{ key = "quest", label = "Quest", status = "Disconnected", note = "Announce quest progress to group channels." },
			{ key = "resetInstance", label = "Reset Instance", status = "Disconnected", note = "Announce instance reset and difficulty changes." },
			{ key = "utility", label = "Utility", status = "Disconnected", note = "Announce feasts, portals, toys, bots, and custom spells." },
		},
	},
	{
		key = "tooltips",
		page = "Tooltips",
		title = "Tooltips",
		description = "Tooltip information, Mythic Plus, progression, and item-set options.",
		status = "Deferred",
		modules = {
			{ key = "mythicPlus", label = "Mythic Plus", status = "Deferred", note = "Depends on ElvUI Tooltip internals." },
			{ key = "unitInfo", label = "Unit Info", status = "Deferred", note = "Unit details in GameTooltip." },
			{ key = "groupInfo", label = "Group Info", status = "Deferred", note = "LFG and group details in tooltip." },
			{ key = "healthBar", label = "Health Bar", status = "Deferred", note = "ElvUI tooltip health bar tweaks." },
			{ key = "icons", label = "Icons", status = "Deferred", note = "Tooltip icon additions." },
			{ key = "keystone", label = "Keystone", status = "Deferred", note = "Keystone tooltip enrichment." },
			{ key = "objectiveProgress", label = "Objective Progress", status = "Deferred", note = "Objective progress tooltip data." },
			{ key = "progression", label = "Progression", status = "Deferred", note = "Raid and dungeon progression tooltip data." },
			{ key = "tierSet", label = "Tier Set", status = "Deferred", note = "Tier set information in item tooltips." },
		},
	},
	{
		key = "unitFrames",
		page = "Unit Frames",
		title = "Unit Frames",
		description = "Unit frame tags, absorb, role icon, focus, and name clipping options.",
		status = "Deferred",
		modules = {
			{ key = "absorb", label = "Absorb", status = "Deferred", note = "Depends on UnitFrames heal prediction internals." },
			{ key = "nameClip", label = "Name Clip", status = "Deferred", note = "Depends on UnitFrames name positioning internals." },
			{ key = "quickFocus", label = "Quick Focus", status = "Deferred", note = "Focus helpers tied to unit frame behavior." },
			{ key = "roleIcon", label = "Role Icon", status = "Deferred", note = "Unit frame role icon replacements." },
			{ key = "tags", label = "Tags", status = "Deferred", note = "ElvUI tag system integration needs replacement." },
		},
	},
	{
		key = "skins",
		page = "Skins",
		title = "Skins",
		description = "Blizzard, widget, library, ElvUI, and third-party addon skin options.",
		status = "Deferred",
		modules = {
			{ key = "core", label = "Core", status = "Deferred", note = "Skin engine and shared helpers." },
			{ key = "blizzard", label = "Blizzard", status = "Deferred", note = "Large set of Blizzard frame skins." },
			{ key = "addons", label = "Addons", status = "Deferred", note = "Third-party addon skins." },
			{ key = "libraries", label = "Libraries", status = "Deferred", note = "Library-provided widget skins." },
			{ key = "widgets", label = "Widgets", status = "Deferred", note = "AceGUI and shared widget skins." },
			{ key = "elvui", label = "ElvUI", status = "Deferred", note = "ElvUI-specific skins will likely be dropped or rewritten." },
			{ key = "textureString", label = "Texture String", status = "Deferred", note = "Texture-string replacement helpers." },
			{ key = "vignetting", label = "Vignetting", status = "Deferred", note = "Screen edge visual effect." },
		},
	},
	{
		key = "misc",
		page = "Misc",
		title = "Misc",
		description = "General quality-of-life, automation, LFG, frame movement, and utility options.",
		status = "Disconnected",
		modules = {
			{ key = "addCNFilter", label = "Add CN Filter", status = "Disconnected", note = "Chinese-region text filter additions." },
			{ key = "antiOverride", label = "Anti Override", status = "Disconnected", note = "Prevent unwanted action bar override behavior." },
			{ key = "autoToggleChatBubble", label = "Auto Toggle Chat Bubble", status = "Disconnected", note = "Context-aware chat bubble toggling." },
			{ key = "disableTalkingHead", label = "Disable Talking Head", status = "Disconnected", note = "Hide talking head frames." },
			{ key = "exitPhaseDiving", label = "Exit Phase Diving", status = "Disconnected", note = "Exit button for phase diving states." },
			{ key = "extraBindingButtons", label = "Extra Binding Buttons", status = "Disconnected", note = "Extra bind-only action buttons." },
			{ key = "gameBar", label = "Game Bar", status = "Disconnected", note = "Micro menu and utility button bar." },
			{ key = "guildNewsItemLevel", label = "Guild News Item Level", status = "Disconnected", note = "Item level in guild news entries." },
			{ key = "hideCrafter", label = "Hide Crafter", status = "Disconnected", note = "Hide crafter name in some item contexts." },
			{ key = "keybindAlias", label = "Keybind Alias", status = "Disconnected", note = "Display aliases for keybind text." },
			{ key = "keybindTextAbove", label = "Keybind Text Above", status = "Disconnected", note = "Move action button keybind text above icons." },
			{ key = "lfgList", label = "LFG List", status = "Disconnected", note = "Group finder filtering and visual helpers." },
			{ key = "lootPanel", label = "Loot Panel", status = "Disconnected", note = "Loot display helpers." },
			{ key = "math", label = "Math", status = "Disconnected", note = "Chat math expression helpers." },
			{ key = "moveFrames", label = "Move Frames", status = "Disconnected", note = "Frame movement and remembered positions." },
			{ key = "mute", label = "Mute", status = "Disconnected", note = "Mute selected annoying sounds." },
			{ key = "pauseToSlash", label = "Pause to Slash", status = "Disconnected", note = "Convert full-width punctuation into slash commands." },
			{ key = "reshiiWrapsUpgrade", label = "Reshii Wraps Upgrade", status = "Disconnected", note = "Expansion-specific upgrade helper." },
			{ key = "skipCutScene", label = "Skip Cutscene", status = "Disconnected", note = "Cutscene skip and watched-state behavior." },
			{ key = "spellActivationAlert", label = "Spell Activation Alert", status = "Disconnected", note = "Spell activation alert visual tweaks." },
		},
	},
	{
		key = "advanced",
		page = "Advanced",
		title = "Advanced",
		description = "Migration, compatibility, profile, and developer-oriented settings.",
		status = "Shell",
		modules = {
			{ key = "compatibility", label = "Compatibility Checks", status = "Shell", note = "Original checks target ElvUI plugin overlap and are not active." },
			{ key = "changelog", label = "Changelog", status = "Shell", note = "Changelog display is not wired yet." },
			{ key = "profileTools", label = "Profile Tools", status = "Shell", note = "Import/export/reset tools need EllesmereUI-native handling." },
			{ key = "developer", label = "Developer", status = "Shell", note = "Debug settings can be rebuilt after module runtime exists." },
		},
	},
	{
		key = "information",
		page = "Information",
		title = "Information",
		description = "Credits, links, help, and migration notes.",
		status = "Shell",
		modules = {
			{ key = "credits", label = "Credits", status = "Shell", note = "Original WindTools credits are preserved in repository files." },
			{ key = "links", label = "Links", status = "Shell", note = "External links and support dialogs are not wired yet." },
			{ key = "migrationNotes", label = "Migration Notes", status = "Shell", note = "Tracks the EllesmereUI migration status." },
		},
	},
}

local PAGE_GROUPS = {
	{ page = "Status" },
	{ page = "Items & Combat", categories = { "item", "combat", "announcement" } },
	{ page = "World & Quest", categories = { "maps", "quest", "misc" } },
	{ page = "Interface", categories = { "tooltips", "unitFrames", "skins" } },
	{ page = "Social", categories = { "social" } },
	{ page = "Advanced", categories = { "advanced", "information" } },
}

local PAGE_NAMES = {}
local CATEGORY_BY_KEY = {}
local GROUP_BY_PAGE = {}
local DEFAULT_MODULES = {}
for _, group in ipairs(PAGE_GROUPS) do
	PAGE_NAMES[#PAGE_NAMES + 1] = group.page
	GROUP_BY_PAGE[group.page] = group
end
for _, category in ipairs(CATEGORIES) do
	CATEGORY_BY_KEY[category.key] = category
	DEFAULT_MODULES[category.key] = {}
	for _, module in ipairs(category.modules) do
		DEFAULT_MODULES[category.key][module.key] = false
	end
end

local DEFAULTS = {
	profile = {
		core = {
			loginMessage = true,
		},
		optionPages = {},
		modulePrefs = DEFAULT_MODULES,
	},
}

for _, category in ipairs(CATEGORIES) do
	DEFAULTS.profile.optionPages[category.key] = {
		showDisconnected = true,
		migrationReady = false,
	}
end

local E = CreateCompatE()
local W = EUI.Lite.NewAddon(addonName)
InstallModuleSystem(W)

local db = EUI.Lite.NewDB("EllesmereUI_WindToolsDB", DEFAULTS)
_G.WindToolsGlobalDB = _G.WindToolsGlobalDB or {}
_G.WindToolsGlobalDB.WT = _G.WindToolsGlobalDB.WT or {}
_G.WindToolsGlobalDB.WT.core = _G.WindToolsGlobalDB.WT.core or {}
_G.WindToolsGlobalDB.WT.developer = _G.WindToolsGlobalDB.WT.developer or {}
_G.WindToolsGlobalDB.WT.changelogRead = _G.WindToolsGlobalDB.WT.changelogRead or 0
_G.WindToolsGlobalDB.WT.DisabledAddOns = _G.WindToolsGlobalDB.WT.DisabledAddOns or {}

_G.WindToolsPrivateDB = _G.WindToolsPrivateDB or {}
_G.WindToolsPrivateDB.WT = _G.WindToolsPrivateDB.WT or {}

local globalCore = _G.WindToolsGlobalDB.WT.core
if globalCore.elvUIVersionPopup == nil then globalCore.elvUIVersionPopup = false end
if globalCore.changlogPopup == nil then globalCore.changlogPopup = true end
if globalCore.cvarAlert == nil then globalCore.cvarAlert = true end
if globalCore.fixSetPassThroughButtons == nil then globalCore.fixSetPassThroughButtons = false end
if globalCore.loginMessage == nil then globalCore.loginMessage = true end

E.db.WT = db.profile
E.global.WT = _G.WindToolsGlobalDB.WT
E.private.WT = _G.WindToolsPrivateDB.WT

addon[1] = W
addon[2] = {}
addon[3] = E
addon[4] = setmetatable({}, { __index = function(_, key) return L(key) end })
addon[5] = db.profile
addon[6] = _G.WindToolsPrivateDB.WT
addon[7] = _G.WindToolsGlobalDB.WT

W.Title = "WindTools"
W.DisplayVersion = C_AddOns.GetAddOnMetadata(addonName, "X-Version") or "4.18 migration"
W.Version = C_AddOns.GetAddOnMetadata(addonName, "X-Version") or "4.18"
W.db = db
W.Utilities = W.Utilities or {}
W:RegisterEvent("PLAYER_LOGIN", function()
	W.initialized = true
	W:InitializeModules()
end)

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

_G.WindTools = addon

local function Print(...)
	if EUI.Print then
		EUI.Print("|cff0cd29f[WindTools]|r", ...)
	end
end

function W:OnProfileChanged()
	self:UpdateModules()
end

local function AddText(parent, text, y, color, height)
	local fs = parent:CreateFontString(nil, "ARTWORK", color or "GameFontNormal")
	fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
	fs:SetPoint("RIGHT", parent, "RIGHT", -20, 0)
	fs:SetJustifyH("LEFT")
	fs:SetText(L(text))
	return height or 28
end

local function Section(parent, title, y)
	local widgets = EUI.Widgets
	local height
	if widgets then
		_, height = widgets:SectionHeader(parent, L(title), y)
		return y - height
	end
	return y - AddText(parent, title, y, "GameFontNormalLarge", 34)
end

local function Toggle(parent, text, y, getValue, setValue, tooltip)
	local widgets = EUI.Widgets
	local height
	if widgets then
		_, height = widgets:Toggle(parent, L(text), y, getValue, setValue, tooltip and L(tooltip) or nil)
		return y - height
	end
	return y - AddText(parent, text .. ": " .. (getValue() and L("On") or L("Off")), y, "GameFontHighlight")
end

local function EnsureCategoryDB(category)
	local profile = db.profile
	if type(profile.optionPages) ~= "table" then
		profile.optionPages = {}
	end
	if type(profile.optionPages[category.key]) ~= "table" then
		profile.optionPages[category.key] = {}
	end
	if profile.optionPages[category.key].showDisconnected == nil then
		profile.optionPages[category.key].showDisconnected = true
	end
	if profile.optionPages[category.key].migrationReady == nil then
		profile.optionPages[category.key].migrationReady = false
	end

	if type(profile.modulePrefs) ~= "table" then
		profile.modulePrefs = {}
	end
	if type(profile.modulePrefs[category.key]) ~= "table" then
		profile.modulePrefs[category.key] = {}
	end

	return profile.optionPages[category.key], profile.modulePrefs[category.key]
end

local function RenderStatusPage(parent, y)
	y = Section(parent, "WindTools Migration Shell", y)
	y = y - AddText(parent, "This addon is registered through EllesmereUI. The original ElvUI-backed WindTools modules remain disconnected so they do not load against missing ElvUI APIs.", y, "GameFontHighlight", 52)
	y = y - AddText(parent, "Current scope: option-page shell, profile storage, local module runtime, libraries, and core utilities. Gameplay feature modules are still inactive.", y, "GameFontHighlight", 42)
	y = y - 10
	y = Section(parent, "Option Categories", y)

	for _, category in ipairs(CATEGORIES) do
		y = y - AddText(parent, L(category.page) .. " - " .. L(category.status) .. ": " .. L(category.description), y, "GameFontHighlight", 32)
	end

	return y
end

local function RenderCategoryPage(category, parent, y)
	local pageDB, moduleDB = EnsureCategoryDB(category)

	y = Section(parent, category.title, y)
	y = y - AddText(parent, category.description, y, "GameFontHighlight", 36)
	y = y - AddText(parent, L("Status") .. ": " .. L(category.status) .. ". " .. L("These controls store migration preferences only; they do not load feature code yet."), y, "GameFontHighlight", 42)
	y = y - 8

	y = Toggle(parent, "Mark this option page as migration-ready", y, function()
		return pageDB.migrationReady and true or false
	end, function(value)
		pageDB.migrationReady = value and true or false
	end, "Bookkeeping flag for the migration pass. It does not enable gameplay behavior.")

	y = Toggle(parent, "Show disconnected module placeholders", y, function()
		return pageDB.showDisconnected and true or false
	end, function(value)
		pageDB.showDisconnected = value and true or false
	end, "Controls whether this page lists modules that are not wired yet.")

	if not pageDB.showDisconnected then
		return y
	end

	y = y - 8
	y = Section(parent, "Modules", y)

	for _, module in ipairs(category.modules) do
		if moduleDB[module.key] == nil then
			moduleDB[module.key] = false
		end
		y = Toggle(parent, L(module.label) .. " - " .. L(module.status), y, function()
			return moduleDB[module.key] and true or false
		end, function(value)
			moduleDB[module.key] = value and true or false
		end, L(module.note) .. " " .. L("This is a stored preference only until the module is migrated."))
	end

	return y
end

local function BuildPage(pageName, parent, yOffset)
	local y = yOffset or -6
	if pageName == "Status" then
		y = RenderStatusPage(parent, y)
	else
		local group = GROUP_BY_PAGE[pageName]
		if group and group.categories then
			for index, categoryKey in ipairs(group.categories) do
				local category = CATEGORY_BY_KEY[categoryKey]
				if category then
					if index > 1 then
						y = y - 16
					end
					y = RenderCategoryPage(category, parent, y)
				end
			end
		else
			y = Section(parent, "WindTools", y)
			y = y - AddText(parent, "Unknown migration page: " .. tostring(pageName), y, "GameFontHighlight")
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
		description = "Migration shell for WindTools on EllesmereUI.",
		pages = PAGE_NAMES,
		buildPage = BuildPage,
		searchTerms = { "windtools", "wt", "migration", "external", "item", "combat", "maps", "quest", "social", "announcement", "tooltips", "unitframes", "skins", "misc", "advanced" },
		onReset = function()
			db:ResetProfile()
		end,
	})

	if not ok then
		Print("external registration failed:", tostring(err))
	end
end

function W:OnEnable()
	RegisterExternalModule()
	if EUI.RegisterModuleCallback then
		EUI.RegisterModuleCallback(self, "ProfileChanged", "OnProfileChanged")
	end
	if db.profile.core.loginMessage then
		Print("loaded as an EllesmereUI migration shell; original feature modules are disconnected.")
	end
end

_G.WindTools_OnAddonCompartmentClick = function()
	if EUI.Toggle then
		EUI:Toggle()
	elseif EUI.OpenOptions then
		EUI:OpenOptions()
	else
		Print("Open EllesmereUI options and select WindTools under External.")
	end
end
