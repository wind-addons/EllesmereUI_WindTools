local addon = select(2, ...)
local W = addon[1]
local E = addon[3]
local DBGet = addon.DBGet
local DBSet = addon.DBSet
local DBGet2 = addon.DBGet2
local DBSet2 = addon.DBSet2
local FontSection = addon.FontSection
local KeyValueEditorButton = addon.KeyValueEditorButton
local GetLSMStatusbars = addon.GetLSMStatusbars

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

local function BuildChatBar(parent, y, cat)
	local Widgets = EllesmereUI.Widgets
	local MH = function(mod, sub) return addon.MakeHeader(cat, mod, sub) end
	local L = addon.L
	local _, h
	local db = E.db.WT.social
	local cb = db.chatBar
	local function chatBarOff() return not cb.enable end
	local function chatBarTextOff() return not cb.enable or cb.style ~= "TEXT" end

	local function afterCB()
		C_Timer.After(0, function()
			local rl = EllesmereUI._widgetRefreshList
			if rl then for i = 1, #rl do rl[i]() end end
		end)
		local mod = W:GetModule("ChatBar")
		if mod and mod.UpdateBar then mod:UpdateBar() end
	end

	_, h = Widgets:SectionHeader(parent, L("Chat Bar"), y); y = y - h
	local row2
	row2, h = Widgets:DualRow(parent, y,
		{ type="toggle", text="Auto Hide", tooltip="Hide channels that do not exist.",
		  getValue = DBGet(cb, "autoHide"), setValue = DBSet(cb, "autoHide", afterCB),
		  disabled = chatBarOff },
		{ type="toggle", text="Mouse Over", tooltip="Only show chat bar when you mouse over it.",
		  getValue = DBGet(cb, "mouseOver"), setValue = DBSet(cb, "mouseOver", afterCB),
		  disabled = chatBarOff }
	); y = y - h
	local row3
	row3, h = Widgets:DualRow(parent, y,
		{ type="slider", text="Button Width", min = 2, max = 80, step = 1,
		  getValue = DBGet(cb, "buttonWidth"), setValue = DBSet(cb, "buttonWidth", afterCB),
		  disabled = chatBarOff },
		{ type="slider", text="Button Height", min = 2, max = 60, step = 1,
		  getValue = DBGet(cb, "buttonHeight"), setValue = DBSet(cb, "buttonHeight", afterCB),
		  disabled = chatBarOff }
	); y = y - h
	local row4
	row4, h = Widgets:DualRow(parent, y,
		{ type="slider", text="Spacing", min = 0, max = 80, step = 1,
		  getValue = DBGet(cb, "spacing"), setValue = DBSet(cb, "spacing", afterCB),
		  disabled = chatBarOff },
		{ type="dropdown", text="Style",
		  values = CHATBAR_STYLE, order = CHATBAR_STYLE_ORDER,
		  getValue = DBGet(cb, "style"), setValue = DBSet(cb, "style", afterCB),
		  disabled = chatBarOff }
	); y = y - h
	local texLookup = GetLSMStatusbars()
	local texDisplay = {}
	local texOrder = {}
	for name in pairs(texLookup) do
		texDisplay[name] = name
		texOrder[#texOrder + 1] = name
	end
	table.sort(texOrder)
	texDisplay._menuOpts = {
		itemHeight = 28,
		background = function(key)
			return texLookup[key]
		end,
	}
	local texRow
	texRow, h = Widgets:Dropdown(parent, "Texture", y,
		texDisplay,
		DBGet(cb, "tex"), DBSet(cb, "tex", afterCB), texOrder,
		"Texture used for block-style buttons."); y = y - h
	local fontValues, fontOrder = EllesmereUI.BuildFontDropdownData()
	local outlineValues = { ["none"] = "Drop Shadow", ["outline"] = "Outline", ["thick"] = "Thick Outline" }
	local outlineOrder = { "none", "outline", "thick" }
	local textRow1
	textRow1, h = Widgets:DualRow(parent, y,
		{ type="toggle", text="Use Color",
		  getValue = DBGet(cb, "color"), setValue = DBSet(cb, "color", afterCB),
		  disabled = chatBarTextOff },
		{ type="toggle", text="Font Settings",
		  getValue = function() return cb.style == "TEXT" end, setValue = function() end,
		  disabled = chatBarTextOff }
	); y = y - h
	if textRow1 and textRow1._rightRegion and EllesmereUI.BuildCogPopup then
		local _, cogShow = EllesmereUI.BuildCogPopup({
			title = "Text Style Font",
			rows = {
				{ type="dropdown", label="Font", values=fontValues, order=fontOrder,
				  get=function() return cb.font.name end,
				  set=function(v) cb.font.name = v; afterCB() end },
				{ type="dropdown", label="Outline", values=outlineValues, order=outlineOrder,
				  get=function() return cb.font.style end,
				  set=function(v) cb.font.style = v; afterCB() end },
				{ type="slider", label="Size", min=5, max=60, step=1,
				  get=function() return cb.font.size end,
				  set=function(v) cb.font.size = v; afterCB() end },
			},
		})
		local rgn = textRow1._rightRegion
		local cogBtn = CreateFrame("Button", nil, rgn)
		cogBtn:SetSize(26, 26)
		cogBtn:SetPoint("RIGHT", rgn._lastInline or rgn._control or rgn, "LEFT", -8, 0)
		rgn._lastInline = cogBtn
		cogBtn:SetFrameLevel(rgn:GetFrameLevel() + 5)
		cogBtn:SetAlpha(0.4)
		local cogTex = cogBtn:CreateTexture(nil, "OVERLAY")
		cogTex:SetAllPoints()
		cogTex:SetTexture(EllesmereUI.COGS_ICON)
		cogBtn:SetScript("OnEnter", function(self) self:SetAlpha(0.7) end)
		cogBtn:SetScript("OnLeave", function(self) self:SetAlpha(0.4) end)
		cogBtn:SetScript("OnClick", function(self) cogShow(self) end)
	end
	_, h = Widgets:Button(parent, "Reset Chat Bar Position", y, function()
		local gdb = E.global.WT and E.global.WT.social and E.global.WT.social.chatBar
		if gdb then gdb.position = nil end
		local mod = W:GetModule("ChatBar")
		if mod and mod.ApplyDefaultPosition then mod:ApplyDefaultPosition() end
	end); y = y - h
	return y
end

local function BuildSmartTab(parent, y, cat)
	local Widgets = EllesmereUI.Widgets
	local L = addon.L
	local _, h
	local st = E.db.WT.social.smartTab
	local stDis = function() return not st.enable end
	_, h = Widgets:SectionHeader(parent, L("SmartTab"), y); y = y - h
	local stPriv = E.private and E.private.WT and E.private.WT.social
		and E.private.WT.social.smartTab or {}
	_, h = Widgets:Toggle(parent, "Enable Tab Switching", y,
		function() return stPriv.allowUnsafeChatEditHooks ~= false end,
		function(v)
			stPriv.allowUnsafeChatEditHooks = v and true or false
			print("|cFFFF6030[WindTools]|r SmartTab Tab-switching changed — /reload to apply.")
		end,
		"Cycle chat channels with Tab. WARNING: hooks Blizzard's chat edit box; in modern clients this can taint it and block sending chat. Disable if you get chat send failures."); y = y - h
	_, h = Widgets:SectionHeader(parent, L("Channel"), y); y = y - h
	do
		local channelItems = {
			{ key = "yell",        label = "Yell" },
			{ key = "battleground", label = "Battleground" },
			{ key = "raidWarning",  label = "Raid Warning" },
			{ key = "officer",      label = "Officer" },
		}
		local channelRow
		channelRow, h = Widgets:DualRow(parent, y,
			{ type="dropdown", text="Channel", tooltip="Select which channels Smart Tab should cycle through.",
			  values={ ["_placeholder"]="..." }, order={ "_placeholder" },
			  getValue=function() return "_placeholder" end,
			  setValue=function() end, disabled = stDis },
			{ type="spacer" }
		); y = y - h
		do
			local rgn = channelRow._leftRegion
			if rgn._control then rgn._control:Hide() end
			local PP = EllesmereUI.PP or EllesmereUI.PanelPP
			local cbDD, cbDDRefresh = EllesmereUI.BuildVisOptsCBDropdown(
				rgn, 210, rgn:GetFrameLevel() + 2,
				channelItems,
				function(k) return st[k] end,
				function(k, v) st[k] = v end
			)
			PP.Point(cbDD, "RIGHT", rgn, "RIGHT", -20, 0)
			rgn._control = cbDD
			rgn._lastInline = nil
			EllesmereUI.RegisterWidgetRefresh(cbDDRefresh)
		end
	end
	_, h = Widgets:SectionHeader(parent, L("Whisper"), y); y = y - h
	_, h = Widgets:DualRow(parent, y,
		{ type = "toggle", text = "Whisper Cycle",
		  getValue = DBGet(st, "whisperCycle"), setValue = DBSet(st, "whisperCycle"), disabled = stDis },
		{ type = "slider", text = "Expiration time (min)", min = 1, max = 2400, step = 1,
		  getValue = DBGet(st, "historyLimit"), setValue = DBSet(st, "historyLimit"), disabled = stDis }
	); y = y - h
	return y
end

addon.RegisterOptionBuilder("social", function(parent, y, cat, subPage)
	if     subPage == "Chat Bar"  then return BuildChatBar(parent, y, cat)
	elseif subPage == "Smart Tab" then return BuildSmartTab(parent, y, cat)
	end
	return y
end)
