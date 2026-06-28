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

function addon.L(text)
	return EllesmereUI.L and EllesmereUI.L(text) or text
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

addon._activeListDropdown = nil
addon._activeListDropdownBtn = nil

function addon.OpenListDropdown(opts, anchorBtn)
	if opts.disabled and opts.disabled() then return end
	if addon._activeListDropdown then
		local same = (addon._activeListDropdownBtn == anchorBtn)
		addon._activeListDropdown()
		if same then return end
	end

	local EUI = EllesmereUI
	local PP = EUI and EUI.PP
	local EG = EUI and EUI.ELLESMERE_GREEN or { r = 0.05, g = 0.82, b = 0.62 }
	local MakeFont = EUI and EUI.MakeFont
	local MakeBorder = EUI and EUI.MakeBorder
	local SolidTex = EUI and EUI.SolidTex
	local CreateFrame = _G.CreateFrame

	local DD_BG_R = EUI and EUI.DD_BG_R or 0.075
	local DD_BG_G = EUI and EUI.DD_BG_G or 0.113
	local DD_BG_B = EUI and EUI.DD_BG_B or 0.141
	local DD_BG_HA = EUI and (EUI.DD_BG_HA or 0.98) or 0.98
	local DD_BRD_A = EUI and (EUI.DD_BRD_A or 0.20) or 0.20
	local DD_ITEM_HL_A = EUI and (EUI.DD_ITEM_HL_A or 0.08) or 0.08

	local MENU_W = opts.width or 260
	local ITEM_H = 28
	local ICON_SZ = 22
	local MAX_LIST_H = 200
	local INPUT_H = 34
	local EMPTY_H = 28

	local addValue = ""
	local menu, scrollFrame, scrollChild, inputBox, emptyLabel
	local rebuildRows

	local function parse(raw)
		if opts.parse then return opts.parse(raw) end
		return raw and raw ~= "" and raw or nil
	end
	local function after()
		MarkSettingsChanged()
		if opts.after then opts.after() end
	end
	local function addValueToList(raw)
		local value = parse(raw)
		if value == nil then Print(opts.invalidMessage or "Invalid value."); return false end
		if opts.mode == "array" then
			table_insert(opts.list, value)
		else
			opts.list[value] = opts.mapValue ~= nil and opts.mapValue or true
		end
		addValue = ""
		after()
		return true
	end
	local function removeByKey(key)
		if opts.mode == "array" then
			for index = #opts.list, 1, -1 do
				if opts.list[index] == key then
					table_remove(opts.list, index)
					after()
					return
				end
			end
		else
			if opts.list[key] ~= nil then
				opts.list[key] = nil
				after()
				return
			end
		end
	end
	local function getEntries()
		local entries = {}
		if opts.mode == "array" then
			for _, key in ipairs(opts.list) do entries[#entries + 1] = key end
		else
			for key in pairs(opts.list) do entries[#entries + 1] = key end
			table.sort(entries, function(a, b) return (tonumber(a) or 0) < (tonumber(b) or 0) end)
		end
		return entries
	end

	local function closeDropdown()
		if menu then
			menu:SetScript("OnUpdate", nil)
			menu:Hide()
			menu = nil
		end
		addon._activeListDropdown = nil
		addon._activeListDropdownBtn = nil
	end

	menu = CreateFrame("Frame", nil, _G.UIParent)
	menu:SetFrameStrata("FULLSCREEN_DIALOG")
	menu:SetFrameLevel(200)
	menu:SetClampedToScreen(true)
	menu:EnableMouse(true)
	menu:SetSize(MENU_W, 10)
	menu:SetPoint("TOPLEFT", anchorBtn, "BOTTOMLEFT", 0, -2)
	menu:Hide()

	if SolidTex then
		SolidTex(menu, "BACKGROUND", DD_BG_R, DD_BG_G, DD_BG_B, DD_BG_HA):SetAllPoints()
	end
	if MakeBorder and PP then MakeBorder(menu, 1, 1, 1, DD_BRD_A, PP) end

	local inputContainer = CreateFrame("Frame", nil, menu)
	inputContainer:SetHeight(INPUT_H)
	inputContainer:SetPoint("TOPLEFT", menu, "TOPLEFT", 0, 0)
	inputContainer:SetPoint("TOPRIGHT", menu, "TOPRIGHT", 0, 0)

	local inputFrame = CreateFrame("Frame", nil, inputContainer)
	inputFrame:SetHeight(26)
	inputFrame:SetPoint("LEFT", inputContainer, "LEFT", 6, 0)
	inputFrame:SetPoint("RIGHT", inputContainer, "RIGHT", -(6 + 52 + 4), 0)
	inputBox = CreateFrame("EditBox", nil, inputFrame)
	inputBox:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
	inputBox:SetTextColor(1, 1, 1, 0.9)
	inputBox:SetAutoFocus(false)
	inputBox:SetText(addValue)
	inputBox:SetAllPoints()
	inputBox:SetJustifyH("LEFT")
	inputBox:ClearFocus()
	if SolidTex then
		SolidTex(inputFrame, "BACKGROUND", DD_BG_R, DD_BG_G, DD_BG_B, 0.6):SetAllPoints()
	end
	if MakeBorder and PP then MakeBorder(inputFrame, 1, 1, 1, 0.10, PP) end
	inputBox:SetScript("OnTextChanged", function(self) addValue = self:GetText() or "" end)
	inputBox:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
		if addValueToList(addValue) then
			inputBox:SetText("")
			rebuildRows()
		end
	end)
	inputBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

	local addBtn = CreateFrame("Button", nil, inputContainer)
	addBtn:SetSize(52, 26)
	addBtn:SetPoint("RIGHT", inputContainer, "RIGHT", -6, 0)
	addBtn:SetFrameLevel(menu:GetFrameLevel() + 2)
	if SolidTex then
		SolidTex(addBtn, "BACKGROUND", EG.r, EG.g, EG.b, 0.18):SetAllPoints()
	end
	if MakeBorder and PP then MakeBorder(addBtn, EG.r, EG.g, EG.b, 0.4, PP) end
	if MakeFont then
		local addLbl = MakeFont(addBtn, 12, nil, EG.r, EG.g, EG.b, 0.9)
		addLbl:SetPoint("CENTER")
		addLbl:SetText(opts.addButton or "Add")
	end
	addBtn:SetScript("OnClick", function()
		if addValueToList(addValue) then
			inputBox:SetText("")
			rebuildRows()
		end
	end)

	emptyLabel = MakeFont and MakeFont(menu, 11, nil, 1, 1, 1, 0.35) or menu:CreateFontString(nil, "OVERLAY")
	if not MakeFont then
		emptyLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
		emptyLabel:SetTextColor(1, 1, 1, 0.35)
	end
	emptyLabel:SetPoint("TOP", menu, "TOP", 0, -(INPUT_H + 4))
	emptyLabel:Hide()

	scrollFrame = CreateFrame("ScrollFrame", nil, menu)
	scrollFrame:SetPoint("TOPLEFT", menu, "TOPLEFT", 1, -(INPUT_H + 1))
	scrollFrame:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -1, -(INPUT_H + 1))
	scrollFrame:EnableMouseWheel(true)
	scrollChild = CreateFrame("Frame", nil, scrollFrame)
	scrollChild:SetWidth(MENU_W - 2)
	scrollChild:SetHeight(1)
	scrollFrame:SetScrollChild(scrollChild)
	scrollFrame:SetScript("OnMouseWheel", function(self, delta)
		local s = self:GetVerticalScroll()
		local maxS = math.max(0, scrollChild:GetHeight() - self:GetHeight())
		self:SetVerticalScroll(math.max(0, math.min(maxS, s - delta * 30)))
	end)

	rebuildRows = function()
		local kids = { scrollChild:GetChildren() }
		for _, kid in ipairs(kids) do kid:Hide() end

		local entries = getEntries()
		local count = #entries

		if count == 0 then
			emptyLabel:Show()
			emptyLabel:SetText("List is empty")
			scrollFrame:SetHeight(EMPTY_H)
			scrollChild:SetHeight(1)
			menu:SetHeight(INPUT_H + 1 + EMPTY_H + 1)
		else
			emptyLabel:Hide()
			local contentH = count * ITEM_H
			local visH = math.min(contentH, MAX_LIST_H)
			scrollFrame:SetHeight(visH)
			scrollChild:SetHeight(contentH)
			menu:SetHeight(INPUT_H + 1 + visH + 1)

			for idx, key in ipairs(entries) do
				local row = CreateFrame("Button", nil, scrollChild)
				row:SetHeight(ITEM_H)
				row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 1, -((idx - 1) * ITEM_H))
				row:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -1, -((idx - 1) * ITEM_H))
				row:SetFrameLevel(menu:GetFrameLevel() + 2)

				local hl = row:CreateTexture(nil, "ARTWORK")
				hl:SetAllPoints()
				hl:SetColorTexture(1, 1, 1, 0)

				local icon = row:CreateTexture(nil, "ARTWORK")
				icon:SetSize(ICON_SZ, ICON_SZ)
				icon:SetPoint("LEFT", row, "LEFT", 10, 0)
				icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

				local nameFS = MakeFont and MakeFont(row, 13, nil, 0.75, 0.75, 0.75, 1)
					or row:CreateFontString(nil, "OVERLAY")
				if not MakeFont then
					nameFS:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
					nameFS:SetTextColor(0.75, 0.75, 0.75, 1)
				end
				nameFS:SetPoint("LEFT", icon, "RIGHT", 8, 0)
				nameFS:SetPoint("RIGHT", row, "RIGHT", -30, 0)
				nameFS:SetJustifyH("LEFT")
				nameFS:SetWordWrap(false)
				nameFS:SetMaxLines(1)

				local numKey = tonumber(key)
				if numKey then
					if _G.C_Item and _G.C_Item.GetItemInfoInstant then
						local _, _, _, _, iconFileID = _G.C_Item.GetItemInfoInstant(numKey)
						if iconFileID then icon:SetTexture(iconFileID) end
					end
					local iName = _G.GetItemInfo(numKey)
					if iName then
						nameFS:SetText(iName .. " (" .. key .. ")")
					else
						nameFS:SetText("Loading... (" .. key .. ")")
						local tc = 0; local ticker
						ticker = _G.C_Timer.NewTicker(0.2, function()
							tc = tc + 1
							local n = _G.GetItemInfo(numKey)
							if n then
								nameFS:SetText(n .. " (" .. key .. ")")
								ticker:Cancel()
							elseif tc >= 25 then
								ticker:Cancel()
							end
						end)
					end
				else
					nameFS:SetText(tostring(key))
				end

				row:SetScript("OnEnter", function()
					nameFS:SetTextColor(1, 1, 1, 1)
					hl:SetColorTexture(1, 1, 1, DD_ITEM_HL_A)
				end)
				row:SetScript("OnLeave", function()
					nameFS:SetTextColor(0.75, 0.75, 0.75, 1)
					hl:SetColorTexture(1, 1, 1, 0)
				end)

				local delBtn = CreateFrame("Button", nil, row)
				delBtn:SetSize(20, 20)
				delBtn:SetPoint("RIGHT", row, "RIGHT", -6, 0)
				delBtn:SetFrameLevel(row:GetFrameLevel() + 2)
				local delTex = delBtn:CreateFontString(nil, "OVERLAY")
				delTex:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
				delTex:SetTextColor(1, 0.35, 0.35, 0.5)
				delTex:SetAllPoints()
				delTex:SetText("×")
				delBtn:SetScript("OnEnter", function() delTex:SetTextColor(1, 0.35, 0.35, 1) end)
				delBtn:SetScript("OnLeave", function() delTex:SetTextColor(1, 0.35, 0.35, 0.5) end)
				delBtn:SetScript("OnClick", function()
					removeByKey(key)
					rebuildRows()
				end)
			end
		end

		scrollFrame:SetVerticalScroll(0)
	end

	menu:SetScript("OnShow", function(self)
		local btnScale = anchorBtn:GetEffectiveScale()
		local uiScale = _G.UIParent:GetEffectiveScale()
		self:SetScale(btnScale / uiScale)
		self:SetScript("OnUpdate", function(m)
			if not m:IsMouseOver() and not anchorBtn:IsMouseOver()
			   and _G.IsMouseButtonDown("LeftButton") then
				closeDropdown()
			end
		end)
	end)
	menu:SetScript("OnHide", function(self)
		self:SetScript("OnUpdate", nil)
	end)

	rebuildRows()
	menu:Show()
	addon._activeListDropdown = closeDropdown
	addon._activeListDropdownBtn = anchorBtn
end

addon.OpenListEditor = addon.OpenListDropdown

function addon.BuildListTrigger(parent, ddW, fLevel, labelText, onClick, disabledFn)
	local EUI = EllesmereUI
	local PP = EUI and EUI.PP
	local s = EUI and EUI.RD_DD_COLOURS
	local CreateFrame = _G.CreateFrame
	if not s then return CreateFrame("Button", nil, parent) end

	local btn = CreateFrame("Button", nil, parent)
	PP.Size(btn, ddW, 30)
	btn:SetFrameLevel(fLevel or 1)

	local bg = EUI.SolidTex(btn, "BACKGROUND", s[1], s[2], s[3], s[4])
	bg:SetAllPoints()
	local brd = EUI.MakeBorder(btn, s[9], s[10], s[11], s[12], PP)

	local lbl = EUI.MakeFont(btn, 13, nil, s[17], s[18], s[19])
	lbl:SetAlpha(s[20])
	lbl:SetJustifyH("LEFT")
	lbl:SetWordWrap(false)
	lbl:SetMaxLines(1)
	PP.Point(lbl, "LEFT", btn, "LEFT", 12, 0)

	if EUI.MakeDropdownArrow then
		local arrow = EUI.MakeDropdownArrow(btn, 12, PP)
		PP.Point(lbl, "RIGHT", arrow, "LEFT", -5, 0)
	else
		PP.Point(lbl, "RIGHT", btn, "RIGHT", -12, 0)
	end
	lbl:SetText(labelText)

	local function applyNormal()
		lbl:SetTextColor(s[17], s[18], s[19], s[20])
		brd:SetColor(s[9], s[10], s[11], s[12])
		bg:SetColorTexture(s[1], s[2], s[3], s[4])
	end
	local function applyHover()
		lbl:SetTextColor(s[21], s[22], s[23], s[24])
		brd:SetColor(s[13], s[14], s[15], s[16])
		bg:SetColorTexture(s[5], s[6], s[7], s[8])
	end

	btn:SetScript("OnEnter", function()
		if disabledFn and disabledFn() then return end
		applyHover()
	end)
	btn:SetScript("OnLeave", function() applyNormal() end)
	btn:SetScript("OnClick", function(self)
		if disabledFn and disabledFn() then return end
		onClick(self)
	end)

	applyNormal()
	btn._lbl = lbl
	return btn
end

function addon.ListEditorButton(Widgets, parent, y, opts)
	local frame, h
	local function label()
		local count = CountTable(opts.list, opts.mode == "array")
		return (opts.label or opts.title or "Manage List") .. " (" .. count .. ")"
	end
	frame, h = Widgets:Button(parent, label(), y, function()
		addon.OpenListDropdown(opts, frame)
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

	function addon.FontSection(Widgets, parent, y, dbTable, after)
		local _, h
		local fonts = GetLSMFonts2()
		local fontOrder = {}
		for k in pairs(fonts) do fontOrder[#fontOrder + 1] = k end
		table.sort(fontOrder)
		_, h = Widgets:Dropdown(parent, "Font", y, fonts, addon.DBGet(dbTable, "name"), addon.DBSet(dbTable, "name", after), fontOrder); y = y - h
		_, h = Widgets:Dropdown(parent, "Outline", y, FOV, addon.DBGet(dbTable, "style"), addon.DBSet(dbTable, "style", after), FOO); y = y - h
		_, h = Widgets:Slider(parent, "Size", y, 5, 60, 1, addon.DBGet(dbTable, "size"), addon.DBSet(dbTable, "size", after)); y = y - h
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
