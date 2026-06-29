-------------------------------------------------------------------------------
--  Options/Panel.lua
--  Standalone WindTools options panel with EllesmereUI visual style.
--
--  Does NOT register into EllesmereUI's options registry. Builds and owns its
--  own root frame, sidebar, content scroll, and footer. Reuses EllesmereUI's
--  exposed visual primitives (MakeFont, SolidTex, MakeBorder, Widgets, PanelPP)
--  so the look matches the host suite.
--
--  Public API (on W):
--    W:ShowOptions(page)   -- create + show, optionally jumping to a page
--    W:HideOptions()       -- hide
--    W:ToggleOptions(page) -- show/hide toggle
--    W:RefreshOptions(force) -- rebuild the current page
-------------------------------------------------------------------------------
local addonName, addon = ...

local W = addon[1]

local CreateFrame = CreateFrame
local UIParent = UIParent
local ipairs = ipairs
local pairs = pairs
local type = type
local wipe = wipe
local math_max = math.max
local math_min = math.min
local math_abs = math.abs
local strlower = strlower

-------------------------------------------------------------------------------
--  Layout constants
-------------------------------------------------------------------------------
local FRAME_W = 1120
local FRAME_H = 770
local SIDEBAR_W = 240
local HEADER_H = 92
local FOOTER_H = 56
local CONTENT_PAD = 30
local NAV_ROW_H = 34
local NAV_TOP = -16
local SCROLL_BAR_W = 4
local CLOSE_BTN_SIZE = 28

-- Navigation text colors (matching EllesmereUI's NAV_* constants)
local NAV_SELECTED_TEXT = { r = 1, g = 1, b = 1, a = 1 }
local NAV_ENABLED_TEXT  = { r = 1, g = 1, b = 1, a = 0.6 }
local NAV_HOVER_ENABLED_TEXT = { r = 1, g = 1, b = 1, a = 0.86 }

-------------------------------------------------------------------------------
--  State
-------------------------------------------------------------------------------
local frame            -- root frame (lazily created)
local activePage       -- current page name
local sidebarButtons = {}  -- pageName -> button frame
local contentScrollFrame
local contentScrollChild
local contentHeaderFrame
local contentHeaderHeight = 0
local contentScrollBottom = 0
local clickArea
local headerTitle, headerDesc
local pageWrapper      -- current page's wrapper frame
local versionText
local searchBox

-- Forward declarations for content layout
local UpdateScrollThumbFn
local UpdateContentLayout

-- Per-page widget refresh callbacks captured during page build.
local pageRefreshList = {}

-------------------------------------------------------------------------------
--  EUI helper shortcuts (resolved lazily to avoid load-order issues)
-------------------------------------------------------------------------------
local function EUI()
    return _G.EllesmereUI
end

local function L(text)
    local e = EUI()
    return e and e.L and e.L(text) or text
end

local function MakeFont(parent, size, flags, r, g, b, a)
    local e = EUI()
    if e and e.MakeFont then return e.MakeFont(parent, size, flags, r, g, b, a) end
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(STANDARD_TEXT_FONT, size, flags or "")
    if r then fs:SetTextColor(r, g, b, a or 1) end
    return fs
end

local function SolidTex(parent, layer, r, g, b, a)
    local e = EUI()
    if e and e.SolidTex then return e.SolidTex(parent, layer, r, g, b, a) end
    local tex = parent:CreateTexture(nil, layer or "BACKGROUND")
    tex:SetColorTexture(r, g, b, a or 1)
    return tex
end

local function MakeBorder(parent, r, g, b, a)
    local e = EUI()
    if e and e.MakeBorder then return e.MakeBorder(parent, r, g, b, a) end
end

-------------------------------------------------------------------------------
--  Widget refresh-list management
-------------------------------------------------------------------------------
local function ClearEUIRefreshList()
    local e = EUI()
    local rl = e and e._widgetRefreshList
    if rl then
        for i = 1, #rl do rl[i] = nil end
    end
end

local function SnapshotRefreshList()
    local e = EUI()
    local rl = e and e._widgetRefreshList
    wipe(pageRefreshList)
    if rl then
        for i = 1, #rl do pageRefreshList[i] = rl[i] end
    end
end

local function RestoreRefreshList()
    local e = EUI()
    local rl = e and e._widgetRefreshList
    if not rl then return end
    for i = 1, #rl do rl[i] = nil end
    for i = 1, #pageRefreshList do rl[i] = pageRefreshList[i] end
end

local function CallRefreshList()
    local e = EUI()
    local rl = e and e._widgetRefreshList
    if rl then
        for i = 1, #rl do
            if type(rl[i]) == "function" then rl[i]() end
        end
    end
end

-------------------------------------------------------------------------------
--  Color constants (resolved from EUI each time to pick up theme changes)
-------------------------------------------------------------------------------
local function EG()
    local e = EUI()
    return (e and e.ELLESMERE_GREEN) or { r = 0.05, g = 0.82, b = 0.62 }
end

local function DarkBG()
    local e = EUI()
    return (e and e.DARK_BG) or { r = 0.06, g = 0.08, b = 0.10 }
end

local function TextDim()
    local e = EUI()
    return (e and e.TEXT_DIM) or { r = 1, g = 1, b = 1, a = 0.53 }
end

-------------------------------------------------------------------------------
--  Content management
-------------------------------------------------------------------------------
local function ClearContent()
    if not contentScrollChild then return end
    local children = { contentScrollChild:GetChildren() }
    for _, child in ipairs(children) do
        child:Hide()
        child:SetParent(nil)
    end
    local regions = { contentScrollChild:GetRegions() }
    for _, region in ipairs(regions) do
        region:Hide()
        region:SetParent(nil)
    end
end

-------------------------------------------------------------------------------
--  Content header management (fixed region above scroll area)
-------------------------------------------------------------------------------
local function ClearContentHeader()
    if not contentHeaderFrame then return end
    local children = { contentHeaderFrame:GetChildren() }
    for _, c in ipairs(children) do c:Hide(); c:SetParent(nil) end
    contentHeaderFrame:Hide()
    contentHeaderFrame:SetHeight(1)
    contentHeaderHeight = 0
    if UpdateContentLayout then UpdateContentLayout() end
end

local function SetContentHeader(builder)
    if not contentHeaderFrame or type(builder) ~= "function" then return end
    local children = { contentHeaderFrame:GetChildren() }
    for _, c in ipairs(children) do c:Hide(); c:SetParent(nil) end
    local contentW = FRAME_W - SIDEBAR_W - CONTENT_PAD
    contentHeaderFrame:Show()
    local ok, h = pcall(builder, contentHeaderFrame, contentW)
    contentHeaderHeight = (ok and type(h) == "number" and h) or 0
    contentHeaderFrame:SetHeight(math_max(contentHeaderHeight, 1))
    if UpdateContentLayout then UpdateContentLayout() end
end

local function UpdateContentHeaderHeight(h)
    if not contentHeaderFrame or not contentHeaderFrame:IsShown() then return end
    contentHeaderHeight = h
    contentHeaderFrame:SetHeight(math_max(h, 1))
    if UpdateContentLayout then UpdateContentLayout() end
end

-- Override Core.lua wrappers with our own panel-local implementations
addon.SetContentHeader = function(builder) SetContentHeader(builder) end
addon.ClearContentHeader = function() ClearContentHeader() end
addon.UpdateContentHeaderHeight = function(h) UpdateContentHeaderHeight(h) end
addon.InvalidateContentHeaderCache = function() end

-------------------------------------------------------------------------------
--  Navigation decoration helpers
--  Replicates EllesmereUI's DecorateSidebarButton visual style:
--  - _indicator: 3px accent bar on the left edge (shown when selected)
--  - _glow: horizontal gradient background (shown when selected)
--  - _glowTop/_glowBot: 1px horizontal edge lines (shown when selected)
--  - _hoverGlow: subtle horizontal gradient (shown on hover)
--  - _hoverIndicator: 3px light bar on the left edge (shown on hover)
-------------------------------------------------------------------------------
local function MakeNavGradient(btn, r, g, b, startA)
    local tex = btn:CreateTexture(nil, "BACKGROUND")
    tex:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    tex:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    tex:SetColorTexture(r, g, b, 1)
    tex:SetGradient("HORIZONTAL", CreateColor(r, g, b, startA), CreateColor(r, g, b, 0))
    tex:Hide()
    return tex
end

local function MakeNavEdgeLine(btn, edge)
    local g = btn:CreateTexture(nil, "BORDER")
    g:SetHeight(1)
    g:SetPoint(edge .. "LEFT", btn, edge .. "LEFT", 0, 0)
    g:SetPoint(edge .. "RIGHT", btn, edge .. "RIGHT", 0, 0)
    g:SetColorTexture(0.7, 0.7, 0.7, 1)
    g:SetGradient("HORIZONTAL", CreateColor(0.7, 0.7, 0.7, 0.5), CreateColor(0.7, 0.7, 0.7, 0))
    g:Hide()
    return g
end

local function DecorateSidebarButton(btn)
    local eg = EG()

    btn._indicator = SolidTex(btn, "ARTWORK", eg.r, eg.g, eg.b, 1)
    btn._indicator:SetWidth(3)
    btn._indicator:SetPoint("TOPLEFT", btn, "TOPLEFT", -1, 0)
    btn._indicator:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", -1, 0)
    btn._indicator:Hide()

    btn._glow = MakeNavGradient(btn, eg.r, eg.g, eg.b, 0.15)
    btn._glowTop = MakeNavEdgeLine(btn, "TOP")
    btn._glowBot = MakeNavEdgeLine(btn, "BOTTOM")

    local hR, hG, hB = 0.85, 0.95, 0.90
    btn._hoverGlow = MakeNavGradient(btn, hR, hG, hB, 0.03)
    btn._hoverIndicator = SolidTex(btn, "ARTWORK", hR, hG, hB, 0.25)
    btn._hoverIndicator:SetWidth(3)
    btn._hoverIndicator:SetPoint("TOPLEFT", btn, "TOPLEFT", -1, 0)
    btn._hoverIndicator:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", -1, 0)
    btn._hoverIndicator:Hide()
end

-------------------------------------------------------------------------------
--  Page selection
-------------------------------------------------------------------------------
local function UpdateSidebarHighlight()
    for pageName, btn in pairs(sidebarButtons) do
        btn._hoverGlow:Hide()
        btn._hoverIndicator:Hide()
        if pageName == activePage then
            btn._indicator:Show()
            btn._glow:Show()
            btn._glowTop:Show()
            btn._glowBot:Show()
            btn._label:SetTextColor(NAV_SELECTED_TEXT.r, NAV_SELECTED_TEXT.g, NAV_SELECTED_TEXT.b, NAV_SELECTED_TEXT.a)
        else
            btn._indicator:Hide()
            btn._glow:Hide()
            btn._glowTop:Hide()
            btn._glowBot:Hide()
            btn._label:SetTextColor(NAV_ENABLED_TEXT.r, NAV_ENABLED_TEXT.g, NAV_ENABLED_TEXT.b, NAV_ENABLED_TEXT.a)
        end
    end
end

local function SelectPage(pageName)
    if not pageName or pageName == activePage then return end

    local group = addon.OptionGroupByPage and addon.OptionGroupByPage[pageName]
    if not group then return end

    -- Find sidebar group label for this page (for header description)
    local groupLabel = ""
    local sidebarGroups = addon.SidebarGroups or {}
    for _, sg in ipairs(sidebarGroups) do
        for _, pn in ipairs(sg.pages or {}) do
            if pn == pageName then groupLabel = sg.label or "" break end
        end
    end

    -- Update header: title shows page name, desc shows group name
    if headerTitle then headerTitle:SetText(L(pageName)) end
    if headerDesc then
        headerDesc:SetText(L(groupLabel))
    end

    activePage = pageName
    UpdateSidebarHighlight()

    -- Build page content
    ClearContent()
    ClearContentHeader()

    local e2 = EUI()
    if e2 and e2.ResetRowCounters then e2.ResetRowCounters() end
    ClearEUIRefreshList()

    pageWrapper = CreateFrame("Frame", nil, contentScrollChild)
    pageWrapper:SetAllPoints(contentScrollChild)

    local startY = -6
    local totalH = 0
    if addon.BuildOptionsPage then
        local ok, h = pcall(addon.BuildOptionsPage, pageName, pageWrapper, startY)
        if ok and type(h) == "number" then
            totalH = h
        else
            totalH = 600
        end
    end

    contentScrollChild:SetHeight(math_max(totalH + 30, 100))

    -- Snapshot the refresh callbacks registered during build
    SnapshotRefreshList()
    -- Populate initial widget values
    CallRefreshList()

    -- Reset scroll to top
    if contentScrollFrame and contentScrollFrame.SetVerticalScroll then
        contentScrollFrame:SetVerticalScroll(0)
    end
end

-------------------------------------------------------------------------------
--  Refresh current page (rebuild)
-------------------------------------------------------------------------------
local function RefreshPage(force)
    if not activePage or not pageWrapper then return end

    if not force and #pageRefreshList > 0 then
        -- Fast path: just re-read widget values
        RestoreRefreshList()
        CallRefreshList()
        return
    end

    -- Slow path: full rebuild
    local currentPage = activePage
    activePage = nil  -- force SelectPage to rebuild
    SelectPage(currentPage)
end

-------------------------------------------------------------------------------
--  Search filter
--  Hides/shows page buttons based on the search query. Group headers
--  visibility follows whether any child in that group is visible.
-------------------------------------------------------------------------------
local groupHeaders = {}  -- groupLabel -> fontstring

local function ApplySearch(text)
    text = text and strlower(text) or ""

    -- Page buttons
    for pageName, btn in pairs(sidebarButtons) do
        if text == "" then
            btn:Show()
        else
            local pageLower = strlower(pageName)
            if pageLower:find(text, 1, true) then
                btn:Show()
            else
                btn:Hide()
            end
        end
    end

    -- Group headers: hide if no child is visible
    local sidebarGroups = addon.SidebarGroups or {}
    for _, group in ipairs(sidebarGroups) do
        local header = groupHeaders[group.label]
        if header then
            if text == "" then
                header:Show()
            else
                local anyVisible = false
                for _, pageName in ipairs(group.pages) do
                    local btn = sidebarButtons[pageName]
                    if btn and btn:IsShown() then anyVisible = true; break end
                end
                if anyVisible then header:Show() else header:Hide() end
            end
        end
    end
end

-------------------------------------------------------------------------------
--  Sidebar construction
--  Layout (mirrors EllesmereUI):
--    1. Title (WindTools)
--    2. Special page buttons (Information, Advanced)
--    3. Search box
--    4. Group headers + child page rows (scrollable area)
--    5. Version text at bottom
-------------------------------------------------------------------------------
local SIDEBAR_PAD = 20
local SPECIAL_ROW_H = 36
local GROUP_ROW_H = 28
local CHILD_ROW_H = 28
local CHILD_INDENT = 16
local GROUP_GAP = 10
local SEARCH_GAP = 14

local function CreateSidebarButton(sidebar, y, pageName, indent, rowH)
    local btn = CreateFrame("Button", nil, sidebar)
    btn:SetSize(SIDEBAR_W - SIDEBAR_PAD, rowH)
    btn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", SIDEBAR_PAD, y)
    btn:SetFrameLevel(sidebar:GetFrameLevel() + 1)

    DecorateSidebarButton(btn)

    local label = MakeFont(btn, 14, nil, NAV_ENABLED_TEXT.r, NAV_ENABLED_TEXT.g, NAV_ENABLED_TEXT.b, NAV_ENABLED_TEXT.a)
    label:SetPoint("LEFT", btn, "LEFT", indent, 0)
    label:SetText(L(pageName))
    label:SetJustifyH("LEFT")
    btn._label = label

    local hlTex = SolidTex(btn, "HIGHLIGHT", 1, 1, 1, 0)
    hlTex:SetAllPoints()

    btn:SetScript("OnEnter", function(self)
        if activePage ~= pageName then
            hlTex:SetAlpha(0.06)
            self._hoverGlow:Show()
            self._hoverIndicator:Show()
            self._label:SetTextColor(NAV_HOVER_ENABLED_TEXT.r, NAV_HOVER_ENABLED_TEXT.g, NAV_HOVER_ENABLED_TEXT.b, NAV_HOVER_ENABLED_TEXT.a)
        end
    end)
    btn:SetScript("OnLeave", function(self)
        hlTex:SetAlpha(0)
        self._hoverGlow:Hide()
        self._hoverIndicator:Hide()
        if activePage ~= pageName then
            self._label:SetTextColor(NAV_ENABLED_TEXT.r, NAV_ENABLED_TEXT.g, NAV_ENABLED_TEXT.b, NAV_ENABLED_TEXT.a)
        end
    end)
    btn:SetScript("OnClick", function()
        SelectPage(pageName)
    end)

    sidebarButtons[pageName] = btn
    return btn
end

local function BuildSidebar(sidebar)
    local eg = EG()
    local td = TextDim()

    -- 1. Title
    local title = MakeFont(sidebar, 22, "", eg.r, eg.g, eg.b, 1)
    title:SetPoint("TOPLEFT", sidebar, "TOPLEFT", SIDEBAR_PAD, NAV_TOP)
    title:SetText(L("WindTools"))
    title:SetJustifyH("LEFT")

    local y = NAV_TOP - 36

    -- 2. Special page buttons (full-width, like EUI's top nav rows)
    local specialPages = addon.SpecialPages or {}
    for _, pageName in ipairs(specialPages) do
        CreateSidebarButton(sidebar, y, pageName, 8, SPECIAL_ROW_H)
        y = y - SPECIAL_ROW_H
    end

    -- 3. Search box
    y = y - SEARCH_GAP
    local sbFrame = CreateFrame("Frame", nil, sidebar)
    sbFrame:SetSize(SIDEBAR_W - SIDEBAR_PAD * 2, 26)
    sbFrame:SetPoint("TOPLEFT", sidebar, "TOPLEFT", SIDEBAR_PAD, y)
    sbFrame:SetFrameLevel(sidebar:GetFrameLevel() + 1)
    local sbBg = SolidTex(sbFrame, "BACKGROUND", 0.075, 0.113, 0.141, 0.6)
    sbBg:SetAllPoints()
    MakeBorder(sbFrame, 1, 1, 1, 0.10)

    searchBox = CreateFrame("EditBox", nil, sbFrame)
    searchBox:SetAllPoints()
    searchBox:SetAutoFocus(false)
    local e = EUI()
    searchBox:SetFont((e and e.EXPRESSWAY) or STANDARD_TEXT_FONT, 12, "")
    searchBox:SetTextColor(1, 1, 1, 0.9)
    searchBox:SetTextInsets(8, 8, 0, 0)
    searchBox:SetMaxLetters(30)

    local placeholder = MakeFont(sbFrame, 11, nil, td.r, td.g, td.b, 0.3)
    placeholder:SetPoint("LEFT", sbFrame, "LEFT", 8, 0)
    placeholder:SetText(L("Search..."))

    searchBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText() or ""
        if text == "" then
            placeholder:Show()
        else
            placeholder:Hide()
        end
        ApplySearch(text)
    end)
    searchBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)

    y = y - 26 - SEARCH_GAP

    -- 4. Grouped page rows
    local sidebarGroups = addon.SidebarGroups or {}
    for gi, group in ipairs(sidebarGroups) do
        if gi > 1 then
            y = y - GROUP_GAP
        end

        -- Group header (accent-colored label, not clickable)
        local headerLabel = MakeFont(sidebar, 15, nil, eg.r, eg.g, eg.b, 0.85)
        headerLabel:SetPoint("TOPLEFT", sidebar, "TOPLEFT", SIDEBAR_PAD, y)
        headerLabel:SetText(L(group.label))
        headerLabel:SetJustifyH("LEFT")
        groupHeaders[group.label] = headerLabel
        y = y - GROUP_ROW_H

        -- Child rows
        for _, pageName in ipairs(group.pages) do
            CreateSidebarButton(sidebar, y, pageName, CHILD_INDENT, CHILD_ROW_H)
            y = y - CHILD_ROW_H
        end
    end

    -- 5. Version text at bottom
    versionText = MakeFont(sidebar, 10, nil, td.r, td.g, td.b, td.a)
    versionText:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMLEFT", SIDEBAR_PAD, 16)
    versionText:SetAlpha(0.5)
    local ver = "v" .. (W.DisplayVersion or "?")
    versionText:SetText(ver)
end

-------------------------------------------------------------------------------
--  Content area construction (title header + content header + scroll)
-------------------------------------------------------------------------------
local function BuildContentArea()
    local contentW = FRAME_W - SIDEBAR_W - CONTENT_PAD

    -- Title header (always visible)
    local headerFrame = CreateFrame("Frame", nil, clickArea)
    headerFrame:SetSize(contentW, HEADER_H)
    headerFrame:SetPoint("TOPLEFT", clickArea, "TOPLEFT", SIDEBAR_W, 0)

    headerTitle = MakeFont(headerFrame, 32, "", 1, 1, 1, 1)
    headerTitle:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", CONTENT_PAD, -28)
    headerTitle:SetText(L("WindTools"))

    headerDesc = MakeFont(headerFrame, 13, nil, TextDim().r, TextDim().g, TextDim().b, TextDim().a)
    headerDesc:SetPoint("TOPLEFT", headerTitle, "BOTTOMLEFT", 2, -10)
    headerDesc:SetWidth(contentW - CONTENT_PAD * 2)
    headerDesc:SetJustifyH("LEFT")

    -- Content header (optional, pinned between title and scroll area)
    contentHeaderFrame = CreateFrame("Frame", nil, clickArea)
    contentHeaderFrame:SetWidth(contentW)
    contentHeaderFrame:SetHeight(1)
    contentHeaderFrame:SetPoint("TOPLEFT", clickArea, "TOPLEFT", SIDEBAR_W, -HEADER_H)
    contentHeaderFrame:SetFrameLevel(clickArea:GetFrameLevel() + 3)
    contentHeaderFrame:EnableMouseWheel(true)
    contentHeaderFrame:SetScript("OnMouseWheel", function(_, delta)
        if contentScrollFrame then
            local fn = contentScrollFrame:GetScript("OnMouseWheel")
            if fn then fn(contentScrollFrame, delta) end
        end
    end)
    contentHeaderFrame:SetClipsChildren(true)
    contentHeaderFrame:Hide()

    local chBg = SolidTex(contentHeaderFrame, "BACKGROUND", 0, 0, 0, 0.1)
    chBg:SetAllPoints()
    local chDiv = SolidTex(contentHeaderFrame, "OVERLAY", 1, 1, 1, 0.06)
    chDiv:SetHeight(1)
    chDiv:SetPoint("BOTTOMLEFT", contentHeaderFrame, "BOTTOMLEFT", 0, 0)
    chDiv:SetPoint("BOTTOMRIGHT", contentHeaderFrame, "BOTTOMRIGHT", 0, 0)

    -- Footer offset
    contentScrollBottom = FOOTER_H + 8

    -- Scroll frame (position and height managed by UpdateContentLayout)
    contentScrollFrame = CreateFrame("ScrollFrame", "WindToolsOptionsScrollFrame", clickArea)
    contentScrollFrame:SetWidth(contentW)
    contentScrollFrame:EnableMouseWheel(true)
    contentScrollFrame:SetClipsChildren(true)

    contentScrollChild = CreateFrame("Frame", nil, contentScrollFrame)
    contentScrollChild:SetWidth(contentW)
    contentScrollChild:SetHeight(1)
    contentScrollFrame:SetScrollChild(contentScrollChild)

    -- Thin scrollbar
    local scrollTrack = CreateFrame("Frame", nil, contentScrollFrame)
    scrollTrack:SetWidth(SCROLL_BAR_W)
    scrollTrack:SetPoint("TOPRIGHT", contentScrollFrame, "TOPRIGHT", -8, -4)
    scrollTrack:SetPoint("BOTTOMRIGHT", contentScrollFrame, "BOTTOMRIGHT", -8, 4)
    scrollTrack:Hide()

    local trackBg = SolidTex(scrollTrack, "BACKGROUND", 1, 1, 1, 0.02)
    trackBg:SetAllPoints()

    local scrollThumb = CreateFrame("Button", nil, scrollTrack)
    scrollThumb:SetWidth(SCROLL_BAR_W)
    scrollThumb:SetHeight(60)
    scrollThumb:SetPoint("TOP", scrollTrack, "TOP", 0, 0)
    scrollThumb:EnableMouse(true)
    scrollThumb:RegisterForDrag("LeftButton")

    local thumbTex = SolidTex(scrollThumb, "ARTWORK", 1, 1, 1, 0.27)
    thumbTex:SetAllPoints()

    local function UpdateScrollThumb()
        local maxScroll = contentScrollFrame:GetVerticalScrollRange()
        if maxScroll <= 0 then
            scrollTrack:Hide()
            return
        end
        scrollTrack:Show()
        local trackH = scrollTrack:GetHeight()
        local visH = contentScrollFrame:GetHeight()
        local visibleRatio = visH / (visH + maxScroll)
        local thumbH = math_max(30, trackH * visibleRatio)
        scrollThumb:SetHeight(thumbH)
        local scrollRatio = contentScrollFrame:GetVerticalScroll() / maxScroll
        local maxThumbTravel = trackH - thumbH
        scrollThumb:ClearAllPoints()
        scrollThumb:SetPoint("TOP", scrollTrack, "TOP", 0, -(scrollRatio * maxThumbTravel))
    end
    UpdateScrollThumbFn = UpdateScrollThumb

    contentScrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local step = 60
        local newScroll = current - (delta * step)
        local maxScroll = self:GetVerticalScrollRange()
        newScroll = math_max(0, math.min(newScroll, maxScroll))
        self:SetVerticalScroll(newScroll)
        UpdateScrollThumb()
    end)

    contentScrollFrame:SetScript("OnScrollRangeChanged", function()
        UpdateScrollThumb()
    end)

    local isDragging = false
    scrollThumb:SetScript("OnDragStart", function()
        isDragging = true
    end)
    scrollThumb:SetScript("OnDragStop", function()
        isDragging = false
    end)
    scrollThumb:SetScript("OnUpdate", function()
        if not isDragging then return end
        local my = select(2, scrollThumb:GetCenter())
        local _, scY = contentScrollFrame:GetCenter()
        local delta = my - scY
        local trackH = scrollTrack:GetHeight()
        local maxScroll = contentScrollFrame:GetVerticalScrollRange()
        local ratio = math_max(0, math.min(1, (-delta) / (trackH / 2)))
        contentScrollFrame:SetVerticalScroll(ratio * maxScroll)
        UpdateScrollThumb()
    end)

    -- Layout updater: repositions scroll frame based on contentHeaderHeight
    UpdateContentLayout = function()
        if not contentScrollFrame then return end
        local scrollTop = HEADER_H + contentHeaderHeight + 8
        contentScrollFrame:ClearAllPoints()
        contentScrollFrame:SetPoint("TOPLEFT", clickArea, "TOPLEFT", SIDEBAR_W, -scrollTop)
        local scrollH = FRAME_H - scrollTop - contentScrollBottom
        contentScrollFrame:SetHeight(math_max(scrollH, 10))
        UpdateScrollThumb()
    end

    UpdateContentLayout()

    return contentScrollBottom
end

-------------------------------------------------------------------------------
--  Footer construction
-------------------------------------------------------------------------------
local function BuildFooter(clickArea, scrollBottom)
    local eg = EG()
    local td = TextDim()
    local contentW = FRAME_W - SIDEBAR_W - CONTENT_PAD

    local footer = CreateFrame("Frame", nil, clickArea)
    footer:SetSize(contentW, FOOTER_H)
    footer:SetPoint("BOTTOMLEFT", clickArea, "BOTTOMLEFT", SIDEBAR_W, 0)

    -- Reset Profile button
    local resetBtn = CreateFrame("Button", nil, footer)
    resetBtn:SetSize(140, 32)
    resetBtn:SetPoint("LEFT", footer, "LEFT", CONTENT_PAD, 0)
    local resetBg = SolidTex(resetBtn, "BACKGROUND", DarkBG().r, DarkBG().g, DarkBG().b, 0.92)
    resetBg:SetAllPoints()
    MakeBorder(resetBtn, eg.r, eg.g, eg.b, 0.4)
    local resetLabel = MakeFont(resetBtn, 12, nil, eg.r, eg.g, eg.b, 0.9)
    resetLabel:SetPoint("CENTER")
    resetLabel:SetText(L("Reset Profile"))

    resetBtn:SetScript("OnClick", function()
        local e = EUI()
        if e and e.ShowConfirmPopup then
            e:ShowConfirmPopup({
                title = L("Reset WindTools Profile"),
                message = L("This will reset all WindTools settings in the current profile to defaults. Continue?"),
                confirmText = L("Reset"),
                cancelText = CANCEL,
                onConfirm = function()
                    local db = addon.GetDB and addon.GetDB()
                    if db and db.ResetProfile then
                        db:ResetProfile()
                    end
                    if W.UpdateModules then W:UpdateModules() end
                    RefreshPage(true)
                end,
            })
        end
    end)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, footer)
    closeBtn:SetSize(100, 32)
    closeBtn:SetPoint("RIGHT", footer, "RIGHT", -CONTENT_PAD, 0)
    local closeBg = SolidTex(closeBtn, "BACKGROUND", DarkBG().r, DarkBG().g, DarkBG().b, 0.92)
    closeBg:SetAllPoints()
    MakeBorder(closeBtn, 1, 1, 1, 0.15)
    local closeLabel = MakeFont(closeBtn, 12, nil, td.r, td.g, td.b, td.a)
    closeLabel:SetPoint("CENTER")
    closeLabel:SetText(L("Close"))

    closeBtn:SetScript("OnClick", function()
        if frame then frame:Hide() end
    end)
end

-------------------------------------------------------------------------------
--  Close button (top-right corner X)
-------------------------------------------------------------------------------
local function BuildCloseButton(clickArea)
    local td = TextDim()
    local btn = CreateFrame("Button", nil, clickArea)
    btn:SetSize(CLOSE_BTN_SIZE, CLOSE_BTN_SIZE)
    btn:SetPoint("TOPRIGHT", clickArea, "TOPRIGHT", -8, -8)
    btn:SetFrameLevel(clickArea:GetFrameLevel() + 10)

    local xLabel = MakeFont(btn, 16, nil, td.r, td.g, td.b, 0.5)
    xLabel:SetPoint("CENTER")
    xLabel:SetText("x")

    btn:SetScript("OnEnter", function()
        xLabel:SetTextColor(1, 0.3, 0.3, 1)
    end)
    btn:SetScript("OnLeave", function()
        xLabel:SetTextColor(td.r, td.g, td.b, 0.5)
    end)
    btn:SetScript("OnClick", function()
        if frame then frame:Hide() end
    end)
end

-------------------------------------------------------------------------------
--  Frame construction (lazy, called on first open)
-------------------------------------------------------------------------------
local function CreateOptionsFrame()
    if frame then return frame end

    local e = EUI()
    -- Ensure EllesmereUI Widgets and deferred initializers are loaded
    if e and e.EnsureLoaded then e:EnsureLoaded() end

    local dark = DarkBG()

    frame = CreateFrame("Frame", "WindToolsOptionsFrame", UIParent)
    frame:SetSize(FRAME_W, FRAME_H)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(100)
    frame:Hide()
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)

    -- Background
    local dark = DarkBG()
    local bg = SolidTex(frame, "BACKGROUND", dark.r, dark.g, dark.b, 0.98)
    bg:SetAllPoints()
    MakeBorder(frame, 1, 1, 1, 0.12)

    -- Pixel-perfect scale: match EllesmereUI's base scale
    local physW = GetPhysicalScreenSize and GetPhysicalScreenSize() or 1920
    local baseScale = GetScreenWidth() / physW
    local userScale = (EllesmereUIDB and EllesmereUIDB.panelScale) or 1.0
    frame:SetScale(baseScale * userScale)

    -- Re-apply scale on show (resolution may have changed)
    frame:SetScript("OnShow", function()
        local pw = GetPhysicalScreenSize and GetPhysicalScreenSize() or 1920
        local bs = GetScreenWidth() / pw
        local us = (EllesmereUIDB and EllesmereUIDB.panelScale) or 1.0
        frame:SetScale(bs * us)
    end)

    -- Click area (handles drag + mouse, like EUI's clickArea)
    clickArea = CreateFrame("Frame", nil, frame)
    clickArea:SetAllPoints(frame)
    clickArea:SetFrameLevel(frame:GetFrameLevel() + 1)
    clickArea:EnableMouse(true)
    clickArea:SetMovable(true)
    clickArea:RegisterForDrag("LeftButton")
    clickArea:SetScript("OnDragStart", function() frame:StartMoving() end)
    clickArea:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)

    -- Close button (top-right, above everything)
    BuildCloseButton(clickArea)

    -- Sidebar (child of clickArea, like EUI)
    local sidebar = CreateFrame("Frame", nil, clickArea)
    sidebar:SetSize(SIDEBAR_W, FRAME_H)
    sidebar:SetPoint("TOPLEFT", clickArea, "TOPLEFT", 0, 0)
    sidebar:SetFrameLevel(clickArea:GetFrameLevel() + 2)

    -- Sidebar divider
    local divider = SolidTex(sidebar, "BORDER", 1, 1, 1, 0.06)
    divider:SetPoint("TOPRIGHT", sidebar, "TOPRIGHT", 0, 0)
    divider:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", 0, 0)
    divider:SetWidth(1)

    BuildSidebar(sidebar)

    BuildContentArea()
    BuildFooter(clickArea, contentScrollBottom)

    -- ESC to close
    if e and e.RegisterEscapeClose then
        e.RegisterEscapeClose(frame)
    else
        local UISpecialFrames = _G.UISpecialFrames
        if UISpecialFrames then
            UISpecialFrames[#UISpecialFrames + 1] = "WindToolsOptionsFrame"
        end
    end

    return frame
end

-------------------------------------------------------------------------------
--  Page name resolution
-------------------------------------------------------------------------------
local function ResolvePage(path)
    if not path or path == "" then return nil end

    local pageNames = addon.OptionPageNames or {}
    local lower = strlower(path)

    -- Try direct match first
    for _, name in ipairs(pageNames) do
        if strlower(name) == lower then return name end
    end

    -- Try EUI-style comma-separated path (2nd field is the page)
    local second = path:match("([^,]+),([^,]+)")
    if second then
        local pagePart = path:match("[^,]+,([^,]+)")
        if pagePart then
            local ppLower = strlower(pagePart)
            for _, name in ipairs(pageNames) do
                if strlower(name) == ppLower then return name end
            end
        end
    end

    -- Partial match
    for _, name in ipairs(pageNames) do
        if strlower(name):find(lower, 1, true) then return name end
    end

    return nil
end

-------------------------------------------------------------------------------
--  Public API
-------------------------------------------------------------------------------

--- Show the WindTools options panel.
--- @param page string|nil Optional page name to jump to.
function W:ShowOptions(page)
    local e = EUI()
    if e and e.EnsureLoaded then e:EnsureLoaded() end
    if addon.InitDB then addon.InitDB() end

    CreateOptionsFrame()
    if not frame then return end

    -- Close EllesmereUI panel if open (avoid two overlapping panels)
    if e and e._mainFrame and e._mainFrame:IsShown() then
        e._mainFrame:Hide()
    end

    frame:Show()

    local target = ResolvePage(page)
    if target then
        -- Force selection even if same page (first open)
        activePage = nil
        SelectPage(target)
    elseif not activePage then
        -- Default to first special page (Information), or first grouped page
        local specialPages = addon.SpecialPages or {}
        local sidebarGroups = addon.SidebarGroups or {}
        local firstPage = specialPages[1]
            or (sidebarGroups[1] and sidebarGroups[1].pages and sidebarGroups[1].pages[1])
        if firstPage then
            SelectPage(firstPage)
        end
    else
        -- Re-read widget values for current page
        RestoreRefreshList()
        CallRefreshList()
    end
end

--- Hide the WindTools options panel.
function W:HideOptions()
    if frame then frame:Hide() end
end

--- Toggle the WindTools options panel.
--- @param page string|nil Optional page name to jump to on open.
function W:ToggleOptions(page)
    if frame and frame:IsShown() then
        frame:Hide()
    else
        W:ShowOptions(page)
    end
end

--- Refresh the current options page.
--- @param force boolean|nil If true, fully rebuild the page.
function W:RefreshOptions(force)
    RefreshPage(force)
end

-- Bridge for option builders that previously called EllesmereUI:RefreshPage().
addon.RefreshOptions = function(force)
    if W.RefreshOptions then W:RefreshOptions(force) end
end
