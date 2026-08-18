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
        local args = {...}
        return xpcall(function()
            return func(unpack(args))
        end, function(err)
            return geterrorhandler()(err)
        end)
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
addon[4] = setmetatable({}, {
    __index = function(_, key)
        return L(key)
    end
})
addon[5] = V
addon[6] = P
addon[7] = G

local F = addon[2]
F.GetCompatibleFont = function(name)
    return name
end

_WindTools = addon
_G.WindTools = addon

W.Title = "WindTools"
W.DisplayVersion = C_AddOns.GetAddOnMetadata(addonName, "X-Version") or "0.1.0"
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
    if db then
        return
    end

    db = EUI.Lite.NewDB("EllesmereUI_WindToolsDB", {
        profile = P
    })
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

addon.Print = Print

-------------------------------------------------------------------------------
--  Options page definitions
--  PAGE_GROUPS: ordered list of pages; each page aggregates one or more
--               category builders registered via addon.RegisterOptionBuilder.
--  A page renders by walking its categories and calling each builder with
--  (parent, y, title). Builders return the new y offset.
--
--  CATEGORY_TITLES: maps the internal category key (used in
--  RegisterOptionBuilder) to the human-readable title passed as the third
--  argument to each builder. Builders use this title for section headers.
-------------------------------------------------------------------------------
local CATEGORY_TITLES = {
    information    = "Information",
    misc           = "Misc",
    announcement   = "Announcement",
    item           = "Item",
    extraItemsBar  = "Extra Items Bar",
    combat         = "Combat",
    social         = "Social",
    maps           = "Maps",
    quest          = "Quest",
    tooltips       = "Tooltips",
    unitFrames     = "Unit Frames",
    skins          = "Skins",
    advanced       = "Advanced",
}

-- All pages and their category mappings (flat, used by BuildPage).
local PAGE_GROUPS = {{
    page = "Information",       categories = {"information"}
}, {
    page = "General",           categories = {"misc"}
}, {
    page = "Loot & Trade",      categories = {"item"}
}, {
    page = "Display",           categories = {"item"}
}, {
    page = "Inspect",           categories = {"item"}
}, {
    page = "Item Level",        categories = {"item"}
}, {
    page = "Merchant",          categories = {"item"}
}, {
    page = "Extra Items Bar",   categories = {"extraItemsBar"}
}, {
    page = "Announcement",      categories = {"announcement"}
}, {
    page = "Raid Markers",      categories = {"combat"}
}, {
    page = "Combat Alert",      categories = {"combat"}
}, {
    page = "Quick Tools",       categories = {"combat"}
}, {
    page = "Damage Meter",      categories = {"combat"}
}, {
    page = "Chat Bar",          categories = {"social"}
}, {
    page = "Smart Tab",         categories = {"social"}
}, {
    page = "Super Tracker",     categories = {"maps"}
}, {
    page = "Minimap",           categories = {"maps"}
}, {
    page = "World Map",         categories = {"maps"}
}, {
    page = "Difficulty & Events", categories = {"maps"}
}, {
    page = "Objective Tracker", categories = {"quest"}
}, {
    page = "Automation",        categories = {"quest"}
}, {
    page = "Progress & Turn In", categories = {"quest"}
}, {
    page = "Achievement",       categories = {"quest"}
}, {
    page = "Tooltip Info",      categories = {"tooltips"}
}, {
    page = "Progression",       categories = {"tooltips"}
}, {
    page = "Keystone & Group Info", categories = {"tooltips"}
}, {
    page = "Tooltip Advanced",  categories = {"tooltips"}
}, {
    page = "Quick Focus",       categories = {"unitFrames"}
}, {
    page = "Absorb",            categories = {"unitFrames"}
}, {
    page = "Name Clip",         categories = {"unitFrames"}
}, {
    page = "Skins",             categories = {"skins"}
}, {
    page = "Advanced",          categories = {"advanced"}
}}

local PAGE_NAMES = {}
local GROUP_BY_PAGE = {}
for _, group in ipairs(PAGE_GROUPS) do
    PAGE_NAMES[#PAGE_NAMES + 1] = group.page
    GROUP_BY_PAGE[group.page] = group
end

-------------------------------------------------------------------------------
--  Sidebar layout
--  Mirrors EllesmereUI's sidebar structure: special buttons at the top,
--  then a search bar, then grouped page rows with accent-colored headers.
-------------------------------------------------------------------------------

-- Pages shown as full-width special buttons above the search bar.
local SPECIAL_PAGES = { "Information", "Advanced" }

-- Grouped pages shown below the search bar. Each group has a label and an
-- ordered list of page names.
local SIDEBAR_GROUPS = {
    { label = "General",      pages = { "General" } },
    { label = "Items",        pages = { "Loot & Trade", "Display", "Inspect", "Item Level", "Merchant", "Extra Items Bar" } },
    { label = "Combat",       pages = { "Raid Markers", "Combat Alert", "Quick Tools", "Damage Meter" } },
    { label = "Social",       pages = { "Chat Bar", "Smart Tab", "Announcement" } },
    { label = "Maps",         pages = { "Super Tracker", "Minimap", "World Map", "Difficulty & Events" } },
    { label = "Quest",        pages = { "Objective Tracker", "Automation", "Progress & Turn In", "Achievement" } },
    { label = "UI Tweaks",    pages = { "Tooltip Info", "Progression", "Keystone & Group Info", "Tooltip Advanced", "Quick Focus", "Absorb", "Name Clip", "Skins" } },
}

-- Build a single options page by invoking its registered category builders.
-- pageName is passed as the 4th arg (subPage) so dispatch builders can
-- route to the correct section. Returns total content height.
local function BuildPage(pageName, parent, yOffset)
    local y = yOffset or -6
    local group = GROUP_BY_PAGE[pageName]
    if not group then
        return math.abs(y) + 30
    end

    local Widgets = EllesmereUI.Widgets
    for index, categoryKey in ipairs(group.categories or {}) do
        local builder = addon.OptionBuilders and addon.OptionBuilders[categoryKey]
        if builder then
            if index > 1 then
                local _, sh = Widgets:Spacer(parent, y, 8)
                y = y - sh
            end
            local title = CATEGORY_TITLES[categoryKey] or categoryKey
            local ok, newY = xpcall(function()
                return builder(parent, y, title, pageName)
            end, function(err)
                return geterrorhandler()(err)
            end)
            if ok and type(newY) == "number" then
                y = newY
            end
        end
    end
    return math.abs(y) + 30
end

-- Expose options metadata + builders to the rest of the addon (Panel.lua).
addon.OptionPageGroups = PAGE_GROUPS
addon.OptionPageNames = PAGE_NAMES
addon.OptionGroupByPage = GROUP_BY_PAGE
addon.SpecialPages = SPECIAL_PAGES
addon.SidebarGroups = SIDEBAR_GROUPS
addon.BuildOptionsPage = BuildPage
addon.InitDB = InitDB
addon.GetDB = function() return db end

-------------------------------------------------------------------------------
--  Blizzard Settings panel entry (Options -> AddOns)
--  Registers a canvas-layout category with a single button that opens the
--  standalone WindTools options panel. Uses the same Settings API as
--  EllesmereUI's own entry.
-------------------------------------------------------------------------------
local function RegisterBlizzardOptionsEntry()
    if not Settings or not Settings.RegisterCanvasLayoutCategory then return end

    local panel = CreateFrame("Frame")
    panel.name = L("WindTools") .. " for EllesmereUI"

    local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btn:SetSize(220, 30)
    btn:SetPoint("CENTER", panel, "CENTER", 0, 0)
    btn:SetText("Open WindTools")

    btn:SetScript("OnClick", function()
        -- Close Blizzard settings first to avoid overlapping windows
        if SettingsPanel and SettingsPanel:IsShown() then
            HideUIPanel(SettingsPanel)
        end
        C_Timer.After(0, function()
            if W.ToggleOptions then
                W:ToggleOptions()
            end
        end)
    end)

    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
end

function W:OnProfileChanged()
    self:UpdateModules()
end

W:RegisterEvent("PLAYER_LOGIN", function()
    InitDB()
    W.initialized = true
    SafeCall(W.InitializeModules, W)
    RegisterBlizzardOptionsEntry()
    if db and db.profile.core and db.profile.core.loginMessage then
        Print("loaded for EllesmereUI.")
    end
end)

-------------------------------------------------------------------------------
--  AddOn Compartment + slash command entry
--  Both open the standalone WindTools options panel (W:ToggleOptions).
--  The panel is implemented in Options/Panel.lua and lazily built on first
--  open, so it is safe to reference here even before that file has loaded
--  its body (the function is looked up at call time via W:ToggleOptions).
-------------------------------------------------------------------------------
_G.WindTools_OnAddonCompartmentClick = function()
    if W.ToggleOptions then
        W:ToggleOptions()
    else
        Print("options panel is not available.")
    end
end
