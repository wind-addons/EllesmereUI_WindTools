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
		local args = { ... }
		return xpcall(function() return func(unpack(args)) end, function(err) return geterrorhandler()(err) end)
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

local F = addon[2]
F.GetCompatibleFont = function(name) return name end

_WindTools = addon
_G.WindTools = addon

W.Title = "WindTools"
W.DisplayVersion = C_AddOns.GetAddOnMetadata(addonName, "X-Version") or "4.18"
W.Version = W.DisplayVersion
W.Utilities = W.Utilities or {}
W.CompatibleFont = false

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
	{ key = "item", title = "Item" },
	{ key = "combat", title = "Combat" },
	{ key = "announcement", title = "Announcement" },
	{ key = "maps", title = "Maps" },
	{ key = "quest", title = "Quest & Achieve" },
	{ key = "misc", title = "Misc" },
	{ key = "social", title = "Social" },
	{ key = "tooltips", title = "Tooltips" },
	{ key = "unitFrames", title = "Unit Frames" },
	{ key = "advanced", title = "Advanced" },
	{ key = "information", title = "Information" },
}

local PAGE_GROUPS = {
	{ page = "Items & Combat", categories = { "item", "combat", "announcement" } },
	{ page = "World & Quest", categories = { "maps", "quest", "misc" } },
	{ page = "Interface", categories = { "tooltips", "unitFrames" } },
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
for _, cat in ipairs(CATEGORIES) do
	CATEGORY_BY_KEY[cat.key] = cat
end

local function BuildPage(pageName, parent, yOffset)
	local y = yOffset or -6
	local group = GROUP_BY_PAGE[pageName]
	if not group or not group.categories then
		return math.abs(y) + 30
	end

	local Widgets = EllesmereUI.Widgets
	for index, categoryKey in ipairs(group.categories) do
		local category = CATEGORY_BY_KEY[categoryKey]
		if category then
			if index > 1 then
				local _, sh = Widgets:Spacer(parent, y, 8); y = y - sh
			end

			local builder = addon.OptionBuilders and addon.OptionBuilders[category.key]
			if builder then
				local ok, newY = xpcall(function() return builder(parent, y, category.title) end, function(err) return geterrorhandler()(err) end)
				if ok and type(newY) == "number" then
					y = newY
				end
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
		searchTerms = { "windtools", "wt", "item", "combat", "maps", "quest", "social", "announcement", "tooltips", "unitframes", "misc", "advanced" },
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
