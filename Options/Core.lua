local addon = select(2, ...)

local xpcall = xpcall
local geterrorhandler = geterrorhandler
local tonumber = tonumber
local type = type
local tostring = tostring
local pairs = pairs
local table_insert = table.insert
local table_remove = table.remove
local IsShiftKeyDown = IsShiftKeyDown
local IsControlKeyDown = IsControlKeyDown
local IsAltKeyDown = IsAltKeyDown

local C_CVar_GetCVar = C_CVar.GetCVar
local C_CVar_GetCVarBool = C_CVar.GetCVarBool
local C_CVar_SetCVar = C_CVar.SetCVar

addon.OptionBuilders = addon.OptionBuilders or {}

function addon.RegisterOptionBuilder(categoryKey, fn)
	addon.OptionBuilders[categoryKey] = fn
end

function addon.MakeHeader(cat, module, sub)
	local L = EllesmereUI.L or function(s) return s end
	if sub then
		return L(cat) .. " · " .. L(module) .. " · " .. L(sub)
	end
	return L(cat) .. " · " .. L(module)
end

local function SafeCall(func, ...)
	if type(func) ~= "function" then return end
	local args = { ... }
	return xpcall(function() return func(unpack(args)) end, function(err) return geterrorhandler()(err) end)
end
addon.SafeCall = SafeCall

local function SafeModuleCall(module, method, ...)
	if not module then return end
	local fn = module and module[method]
	if type(fn) ~= "function" then return end
	local args = { ... }
	return xpcall(function() return fn(module, unpack(args)) end, function(err) return geterrorhandler()(err) end)
end
addon.SafeModuleCall = SafeModuleCall

local function DBGet(t, k)
	return function() return t and t[k] end
end

local function DBSet(t, k, after)
	return function(v)
		if not t then return end
		t[k] = v
		if after then SafeCall(after) end
	end
end

local function DBGet2(t, k1, k2)
	return function() return t and t[k1] and t[k1][k2] end
end

local function DBSet2(t, k1, k2, after)
	return function(v)
		if not t then return end
		if not t[k1] then t[k1] = {} end
		t[k1][k2] = v
		if after then SafeCall(after) end
	end
end

addon.DBGet = DBGet
addon.DBSet = DBSet
addon.DBGet2 = DBGet2
addon.DBSet2 = DBSet2

local function MarkSettingsChanged()
	EllesmereUI._settingsChanged = true
end

local function Print(text)
	if EllesmereUI.Print then
		EllesmereUI.Print("|cff0cd29f[WindTools]|r", text)
	elseif DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage("|cff0cd29f[WindTools]|r " .. tostring(text))
	end
end

local function CountTable(tbl, isArray)
	local count = 0
	if not tbl then return count end
	if isArray then
		return #tbl
	end
	for _ in pairs(tbl) do count = count + 1 end
	return count
end

function addon.ListEditorButton(Widgets, parent, y, opts)
	local addValue, removeValue = "", ""
	local _, showPopup
	local frame, h
	local function disabled()
		return opts.disabled and opts.disabled()
	end
	local function parse(raw)
		if opts.parse then return opts.parse(raw) end
		return raw and raw ~= "" and raw or nil
	end
	local function label()
		local count = CountTable(opts.list, opts.mode == "array")
		return (opts.label or opts.title or "Manage List") .. " (" .. count .. ")"
	end
	local function after()
		MarkSettingsChanged()
		if opts.after then opts.after() end
	end
	local function add(raw)
		if disabled() then return end
		local value = parse(raw)
		if value == nil then Print(opts.invalidMessage or "Invalid value."); return end
		if opts.mode == "array" then
			table_insert(opts.list, value)
		else
			opts.list[value] = opts.mapValue ~= nil and opts.mapValue or true
		end
		addValue = ""
		after()
	end
	local function remove(raw)
		if disabled() then return end
		local value = parse(raw)
		if value == nil then Print(opts.invalidMessage or "Invalid value."); return end
		if opts.mode == "array" then
			for index = #opts.list, 1, -1 do
				if opts.list[index] == value then
					table_remove(opts.list, index)
					after()
					return
				end
			end
		else
			if opts.list[value] ~= nil then
				opts.list[value] = nil
				after()
				return
			end
		end
		Print(opts.notFoundMessage or "Value not found.")
	end

	frame, h = Widgets:Button(parent, label(), y, function()
		if not showPopup then
			_, showPopup = EllesmereUI.BuildCogPopup({
				title = opts.title or opts.label or "Manage List",
				rows = {
					{ type = "input", label = opts.addLabel or "Add", get = function() return addValue end, set = function(v) addValue = v or "" end, disabled = disabled },
					{ type = "button", label = opts.addButton or "Add", action = function() add(addValue) end, disabled = disabled },
					{ type = "input", label = opts.removeLabel or "Remove", get = function() return removeValue end, set = function(v) removeValue = v or "" end, disabled = disabled },
					{ type = "button", label = opts.removeButton or "Remove", action = function() remove(removeValue); removeValue = "" end, disabled = disabled },
				},
			})
		end
		showPopup(frame)
	end)
	return frame, h
end

function addon.KeyValueEditorButton(Widgets, parent, y, opts)
	local keyValue, valueValue, removeKey = "", "", ""
	local _, showPopup
	local frame, h
	local function disabled()
		return opts.disabled and opts.disabled()
	end
	local function after()
		MarkSettingsChanged()
		if opts.after then opts.after() end
	end
	local function valid(value)
		return value and value ~= ""
	end
	frame, h = Widgets:Button(parent, opts.label or opts.title or "Manage Entries", y, function()
		if not showPopup then
			_, showPopup = EllesmereUI.BuildCogPopup({
				title = opts.title or opts.label or "Manage Entries",
				rows = {
					{ type = "input", label = opts.keyLabel or "Key", get = function() return keyValue end, set = function(v) keyValue = v or "" end, disabled = disabled },
					{ type = "input", label = opts.valueLabel or "Value", get = function() return valueValue end, set = function(v) valueValue = v or "" end, disabled = disabled },
					{ type = "button", label = opts.addButton or "Add / Update", action = function()
						if disabled() then return end
						if valid(keyValue) and valid(valueValue) then
							opts.map[keyValue] = valueValue
							keyValue, valueValue = "", ""
							after()
						else
							Print(opts.invalidMessage or "Both fields are required.")
						end
					end, disabled = disabled },
					{ type = "input", label = opts.removeLabel or "Remove", get = function() return removeKey end, set = function(v) removeKey = v or "" end, disabled = disabled },
					{ type = "button", label = opts.removeButton or "Remove", action = function()
						if disabled() then return end
						if valid(removeKey) and opts.map[removeKey] ~= nil then
							opts.map[removeKey] = nil
							removeKey = ""
							after()
						else
							Print(opts.notFoundMessage or "Entry not found.")
						end
					end, disabled = disabled },
				},
			})
		end
		showPopup(frame)
	end)
	return frame, h
end

local function FormatKey(key)
	if not key or key == "" then return EllesmereUI.L("Not Bound") end
	local parts = {}
	for mod in key:gmatch("(%u+)%-") do
		parts[#parts + 1] = mod:sub(1, 1) .. mod:sub(2):lower()
	end
	parts[#parts + 1] = key:match("[^%-]+$") or key
	return table.concat(parts, " + ")
end

function addon.KeybindAliasEditorButton(Widgets, parent, y, opts)
	local keyValue, aliasValue, removeKey = "", "", ""
	local popup, anchor
	local frame, h
	local function disabled()
		return opts.disabled and opts.disabled()
	end
	local function after()
		MarkSettingsChanged()
		if opts.after then opts.after() end
	end
	local function makeFont(owner, size, alpha)
		local fs = owner:CreateFontString(nil, "OVERLAY")
		fs:SetFont((EllesmereUI.GetFontPath and EllesmereUI.GetFontPath("options")) or "Fonts\\FRIZQT__.TTF", size or 12, "")
		fs:SetTextColor(1, 1, 1, alpha or 0.8)
		return fs
	end
	local function styledButton(owner, text, width, height)
		local btn = CreateFrame("Button", nil, owner)
		btn:SetSize(width, height)
		local bg = btn:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(EllesmereUI.DD_BG_R or 0.12, EllesmereUI.DD_BG_G or 0.12, EllesmereUI.DD_BG_B or 0.12, EllesmereUI.DD_BG_A or 0.85)
		btn._bg = bg
		if EllesmereUI.MakeBorder then
			btn._border = EllesmereUI.MakeBorder(btn, 1, 1, 1, EllesmereUI.DD_BRD_A or 0.18)
		end
		local label = makeFont(btn, 12, 0.75)
		label:SetPoint("CENTER")
		label:SetText(EllesmereUI.L(text))
		btn._label = label
		btn:SetScript("OnEnter", function(self)
			bg:SetColorTexture(EllesmereUI.DD_BG_R or 0.12, EllesmereUI.DD_BG_G or 0.12, EllesmereUI.DD_BG_B or 0.12, EllesmereUI.DD_BG_HA or 0.98)
			if self._border and self._border.SetColor then self._border:SetColor(1, 1, 1, 0.3) end
		end)
		btn:SetScript("OnLeave", function(self)
			bg:SetColorTexture(EllesmereUI.DD_BG_R or 0.12, EllesmereUI.DD_BG_G or 0.12, EllesmereUI.DD_BG_B or 0.12, EllesmereUI.DD_BG_A or 0.85)
			if self._border and self._border.SetColor then self._border:SetColor(1, 1, 1, EllesmereUI.DD_BRD_A or 0.18) end
		end)
		return btn, label
	end
	local function makeEditBox(owner, width)
		local box = CreateFrame("EditBox", nil, owner)
		box:SetSize(width, 26)
		box:SetAutoFocus(false)
		box:SetFont((EllesmereUI.GetFontPath and EllesmereUI.GetFontPath("options")) or "Fonts\\FRIZQT__.TTF", 12, "")
		box:SetTextColor(1, 1, 1, 0.75)
		box:SetJustifyH("CENTER")
		local bg = box:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(0.12, 0.12, 0.12, 0.8)
		if EllesmereUI.MakeBorder then EllesmereUI.MakeBorder(box, 0.4, 0.4, 0.4, 0.35) end
		box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
		return box
	end
	local function createPopup()
		popup = CreateFrame("Frame", nil, UIParent)
		popup:SetFrameStrata("DIALOG")
		popup:SetFrameLevel(220)
		popup:SetSize(260, 220)
		popup:EnableMouse(true)
		popup:Hide()
		local bg = popup:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(0.06, 0.08, 0.10, 0.95)
		if EllesmereUI.MakeBorder then EllesmereUI.MakeBorder(popup, 1, 1, 1, 0.15) end

		local title = makeFont(popup, 12, 0.7)
		title:SetPoint("TOP", popup, "TOP", 0, -14)
		title:SetText(EllesmereUI.L(opts.title or "Keybind Alias"))

		local keyLbl = makeFont(popup, 11, 0.55)
		keyLbl:SetPoint("TOPLEFT", popup, "TOPLEFT", 16, -42)
		keyLbl:SetText(EllesmereUI.L("Hot Key"))
		local keyBtn, keyBtnLbl = styledButton(popup, "Not Bound", 126, 28)
		keyBtn:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -16, -36)
		keyBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		local listening = false
		local function refreshKey()
			keyBtnLbl:SetText(listening and EllesmereUI.L("Press a key...") or FormatKey(keyValue))
		end
		keyBtn:SetScript("OnClick", function(self, button)
			if disabled() then return end
			if button == "RightButton" then
				listening = false
				self:EnableKeyboard(false)
				keyValue = ""
				refreshKey()
				return
			end
			if listening then return end
			listening = true
			refreshKey()
			self:EnableKeyboard(true)
		end)
		keyBtn:SetScript("OnKeyDown", function(self, key)
			if not listening then self:SetPropagateKeyboardInput(true); return end
			if key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL" or key == "LALT" or key == "RALT" then
				self:SetPropagateKeyboardInput(true)
				return
			end
			self:SetPropagateKeyboardInput(false)
			if key == "ESCAPE" then
				listening = false
				self:EnableKeyboard(false)
				refreshKey()
				return
			end
			local mods = ""
			if IsShiftKeyDown() then mods = mods .. "SHIFT-" end
			if IsControlKeyDown() then mods = mods .. "CTRL-" end
			if IsAltKeyDown() then mods = mods .. "ALT-" end
			keyValue = mods .. key
			listening = false
			self:EnableKeyboard(false)
			refreshKey()
		end)
		keyBtn:HookScript("OnEnter", function(self)
			if EllesmereUI.ShowWidgetTooltip then EllesmereUI.ShowWidgetTooltip(self, "Left-click to set a keybind.\nRight-click to unbind.") end
		end)
		keyBtn:HookScript("OnLeave", function() if EllesmereUI.HideWidgetTooltip then EllesmereUI.HideWidgetTooltip() end end)

		local aliasLbl = makeFont(popup, 11, 0.55)
		aliasLbl:SetPoint("TOPLEFT", popup, "TOPLEFT", 16, -78)
		aliasLbl:SetText(EllesmereUI.L("Alias"))
		local aliasBox = makeEditBox(popup, 126)
		aliasBox:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -16, -72)
		aliasBox:SetScript("OnTextChanged", function(self) aliasValue = self:GetText() or "" end)

		local addBtn = styledButton(popup, "Add / Update", 228, 28)
		addBtn:SetPoint("TOP", popup, "TOP", 0, -112)
		addBtn:SetScript("OnClick", function()
			if disabled() then return end
			if keyValue ~= "" and aliasValue ~= "" then
				opts.map[keyValue] = aliasValue
				keyValue, aliasValue = "", ""
				aliasBox:SetText("")
				refreshKey()
				after()
			else
				Print(opts.invalidMessage or "Hot Key and Alias are required.")
			end
		end)

		local removeLbl = makeFont(popup, 11, 0.55)
		removeLbl:SetPoint("TOPLEFT", popup, "TOPLEFT", 16, -154)
		removeLbl:SetText(EllesmereUI.L("Remove"))
		local removeBox = makeEditBox(popup, 126)
		removeBox:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -16, -148)
		removeBox:SetScript("OnTextChanged", function(self) removeKey = self:GetText() or "" end)
		local removeBtn = styledButton(popup, "Remove", 228, 26)
		removeBtn:SetPoint("TOP", popup, "TOP", 0, -184)
		removeBtn:SetScript("OnClick", function()
			if disabled() then return end
			if removeKey ~= "" and opts.map[removeKey] ~= nil then
				opts.map[removeKey] = nil
				removeKey = ""
				removeBox:SetText("")
				after()
			else
				Print(opts.notFoundMessage or "Alias not found.")
			end
		end)
		popup:SetScript("OnHide", function()
			listening = false
			keyBtn:EnableKeyboard(false)
			refreshKey()
		end)
	end

	frame, h = Widgets:Button(parent, opts.label or opts.title or "Manage Aliases", y, function()
		if not popup then createPopup() end
		if popup:IsShown() then popup:Hide(); return end
		anchor = frame
		popup:ClearAllPoints()
		popup:SetPoint("TOP", anchor, "BOTTOM", 0, -5)
		popup:Show()
	end)
	return frame, h
end

function addon.Placeholder(Widgets, parent, y, text)
	return Widgets:Button(parent, text or "This section has no configurable options yet.", y, function() end)
end

local function CVarGetBool(name)
	return function() return C_CVar_GetCVarBool(name) end
end
local function CVarSetBool(name)
	return function(v) C_CVar_SetCVar(name, v and "1" or "0") end
end
local function CVarGetNum(name)
	return function() return tonumber(C_CVar_GetCVar(name)) or 0 end
end
local function CVarSetNum(name)
	return function(v) C_CVar_SetCVar(name, tostring(v)) end
end
local function CVarGetStr(name)
	return function() return C_CVar_GetCVar(name) end
end
local function CVarSetStr(name)
	return function(v) C_CVar_SetCVar(name, tostring(v)) end
end

addon.CVarGetBool = CVarGetBool
addon.CVarSetBool = CVarSetBool
addon.CVarGetNum = CVarGetNum
addon.CVarSetNum = CVarSetNum
addon.CVarGetStr = CVarGetStr
addon.CVarSetStr = CVarSetStr

local FONT_OUTLINE_VALUES = {
	NONE = "None",
	OUTLINE = "OUTLINE",
	THICKOUTLINE = "THICKOUTLINE",
	MONOCHROME = "MONOCHROME",
	MONOCHROMEOUTLINE = "MONOCHROMEOUTLINE",
	MONOCHROMETHICKOUTLINE = "MONOCHROMETHICKOUTLINE",
}
local FONT_OUTLINE_ORDER = { "NONE", "OUTLINE", "THICKOUTLINE", "MONOCHROME", "MONOCHROMEOUTLINE", "MONOCHROMETHICKOUTLINE" }
addon.FONT_OUTLINE_VALUES = FONT_OUTLINE_VALUES
addon.FONT_OUTLINE_ORDER = FONT_OUTLINE_ORDER

local function GetLSMFonts()
	local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
	if LSM then return LSM:HashTable("font") end
	return { ["Expressway"] = "Expressway" }
end
addon.GetLSMFonts = GetLSMFonts

local function GetLSMStatusbars()
	local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
	if LSM then return LSM:HashTable("statusbar") end
	return { ["Blizzard"] = "Blizzard" }
end
addon.GetLSMStatusbars = GetLSMStatusbars

do
	local GetLSMFonts2 = addon.GetLSMFonts
	local FOV = addon.FONT_OUTLINE_VALUES
	local FOO = addon.FONT_OUTLINE_ORDER

	function addon.FontSection(Widgets, parent, y, dbTable)
		local _, h
		local fonts = GetLSMFonts2()
		_, h = Widgets:Dropdown(parent, "Font", y, fonts, addon.DBGet(dbTable, "name"), addon.DBSet(dbTable, "name")); y = y - h
		_, h = Widgets:Dropdown(parent, "Outline", y, FOV, FOO, addon.DBGet(dbTable, "style"), addon.DBSet(dbTable, "style")); y = y - h
		_, h = Widgets:Slider(parent, "Size", y, 5, 60, 1, addon.DBGet(dbTable, "size"), addon.DBSet(dbTable, "size")); y = y - h
		return y
	end
end

do
	local t = {}
	function addon.MakeChannelValues(...)
		for i = 1, select("#", ...) do
			local v = select(i, ...)
			t[v] = v
		end
		return t
	end
end
