local addon = select(2, ...)
local W = addon[1]
local E = addon[3]
local DBGet = addon.DBGet
local DBSet = addon.DBSet
local DBGet2 = addon.DBGet2
local DBSet2 = addon.DBSet2
local SafeModuleCall = addon.SafeModuleCall
local FontSection = addon.FontSection


local ceil = ceil
local floor = floor
local pairs = pairs
local ipairs = ipairs
local strsplit = strsplit

local ANCHOR_CORNER_VALUES = {
	TOPLEFT = "TOPLEFT", TOPRIGHT = "TOPRIGHT",
	BOTTOMLEFT = "BOTTOMLEFT", BOTTOMRIGHT = "BOTTOMRIGHT",
}
local ANCHOR_CORNER_ORDER = { "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }

local BAR_LABELS = { [1]="Bar 1", [2]="Bar 2", [3]="Bar 3", [4]="Bar 4", [5]="Bar 5" }
local BAR_ORDER = { 1, 2, 3, 4, 5 }

local GROUP_ITEMS = {
	{ key = "QUEST",      label = "Quest Items" },
	{ key = "EQUIP",      label = "Equipment" },
	{ key = "CUSTOM",     label = "Custom Items" },
	{ key = "BANNER",     label = "Banners" },
	{ key = "UTILITY",    label = "Utility" },
	{ key = "OPENABLE",   label = "Openable" },
	{ key = "DELVE",      label = "Delve" },
	{ key = "HOLIDAY",    label = "Holiday" },
	{ key = "POTIONGN",   label = "Potions (General)" },
	{ key = "POTIONMN",   label = "Potions (Midnight)" },
	{ key = "POTIONTWW",  label = "Potions (TWW)" },
	{ key = "FLASKMN",    label = "Flasks (Midnight)" },
	{ key = "FLASKTWW",   label = "Flasks (TWW)" },
	{ key = "VANTUSMN",   label = "Vantus (Midnight)" },
	{ key = "FOODMN",     label = "Food (Midnight)" },
	{ key = "FOODTWW",    label = "Food (TWW)" },
	{ key = "FOODVENDOR", label = "Food (Vendor)" },
	{ key = "MAGEFOOD",   label = "Mage Food" },
	{ key = "RUNEMN",     label = "Runes (Midnight)" },
	{ key = "PROFMN",     label = "Profession (MN)" },
	{ key = "FISHING",    label = "Fishing" },
	{ key = "SEEDS",      label = "Seeds" },
}

local function DeepCopy(t)
	if type(t) ~= "table" then return t end
	local r = {}
	for k, v in pairs(t) do r[k] = DeepCopy(v) end
	return r
end

local _selectedBar = 1

local OUTLINE_VALUES = { ["none"]="Drop Shadow", ["outline"]="Outline", ["thick"]="Thick Outline" }
local OUTLINE_ORDER = { "none", "outline", "thick" }

local function AttachCog(rgn, popupTitle, popupRows)
	if not rgn or not EllesmereUI.BuildCogPopup then return end
	local _, cogShow = EllesmereUI.BuildCogPopup({ title = popupTitle, rows = popupRows })
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

addon.RegisterOptionBuilder("extraItemsBar", function(parent, y, cat)
	local Widgets = EllesmereUI.Widgets
	local MH = function(mod, sub) return addon.MakeHeader(cat, mod, sub) end
	local _, h
	local db = E.db.WT.item.extraItemsBar
	local selectedBar = _selectedBar
	local activePreview = nil

	local updateBars = function() SafeModuleCall(W.Modules.ExtraItemsBar, "UpdateBars") end
	local function refreshWidgets()
		C_Timer.After(0, function()
			local rl = EllesmereUI._widgetRefreshList
			if rl then for i = 1, #rl do rl[i]() end end
		end)
	end
	local function SB() return db["bar" .. selectedBar] end
	local function SGet(k) return function() local b = SB(); return b and b[k] end end
	local function SSet(k) return function(v)
		local b = SB(); if b then b[k] = v end
		if activePreview and activePreview.Update then activePreview:Update() end
		refreshWidgets()
		updateBars()
	end end

	-- =========================================================================
	--  PREVIEW  (EAB-style, built inside content header)
	-- =========================================================================
	local function BuildLivePreview(hdr, yOff)
		local PAD = EllesmereUI.CONTENT_PAD or 20
		local maxW = hdr:GetWidth() - PAD * 2
		local PREVIEW_MAX_H = 160

		local barDB = SB()
		if not barDB then activePreview = nil; return 0 end

		local bw = barDB.buttonWidth or 35; local bh = barDB.buttonHeight or 30
		local nb = barDB.numButtons or 12; local bpr = barDB.buttonsPerRow or 12
		local sp = barDB.spacing or 3; local bs = barDB.backdropSpacing or 3

		local rows = ceil(nb / bpr); local cols = nb < bpr and nb or bpr
		local gw = 2 * bs + cols * bw + (cols - 1) * sp
		local gh = 2 * bs + rows * bh + (rows - 1) * sp

		local scale = UIParent:GetEffectiveScale() / hdr:GetEffectiveScale()
		if gw * scale > maxW then scale = maxW / gw end
		local scaledW = gw * scale
		local scaledH = gh * scale

		local wrapper = CreateFrame("Frame", nil, hdr)
		wrapper:SetSize(scaledW, floor(math.min(scaledH, PREVIEW_MAX_H)))
		wrapper:SetPoint("TOP", hdr, "TOP", 0, yOff)
		wrapper:SetClipsChildren(true)

		local sf = CreateFrame("ScrollFrame", nil, wrapper)
		sf:SetAllPoints(); sf:EnableMouseWheel(true)

		local pf = CreateFrame("Frame", nil, sf)
		pf:SetScale(scale); pf:SetSize(gw, gh)
		sf:SetScrollChild(pf)

		-- Bar backdrop
		local bgTex = pf:CreateTexture(nil, "BACKGROUND")
		bgTex:SetColorTexture(0.08, 0.10, 0.14, 0.55); bgTex:SetAllPoints()

		-- Pre-create 12 button frames
		local buttons = {}
		for i = 1, 12 do
			local bf = CreateFrame("Frame", nil, pf)
			bf:SetSize(bw, bh); bf:Hide()
			local icon = bf:CreateTexture(nil, "ARTWORK")
			icon:SetAllPoints()
			icon:SetColorTexture(0.06, 0.08, 0.10, 1)
			local countFS = bf:CreateFontString(nil, "OVERLAY")
			countFS:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
			countFS:SetTextColor(1, 1, 1, 0.8)
			countFS:SetPoint("BOTTOMRIGHT", -1, 2); countFS:SetText("")
			buttons[i] = { frame=bf, icon=icon, count=countFS }
		end

		-- Small scrollbar
		local pvTrack = CreateFrame("Frame", nil, wrapper)
		pvTrack:SetWidth(4)
		pvTrack:SetPoint("TOPRIGHT", wrapper, "TOPRIGHT", -2, -2)
		pvTrack:SetPoint("BOTTOMRIGHT", wrapper, "BOTTOMRIGHT", -2, 2)
		pvTrack:SetFrameLevel(wrapper:GetFrameLevel() + 5); pvTrack:Hide()
		local pvThumb = CreateFrame("Button", nil, pvTrack)
		pvThumb:SetWidth(4); pvThumb:SetFrameLevel(pvTrack:GetFrameLevel() + 1)
		local thumbTex = pvThumb:CreateTexture(nil, "ARTWORK")
		thumbTex:SetAllPoints(); thumbTex:SetColorTexture(1, 1, 1, 0.27)

		local function UpdatePVThumb()
			local ms = sf:GetVerticalScrollRange()
			if ms <= 0 then pvTrack:Hide(); return end
			pvTrack:Show()
			local th = sf:GetHeight(); local ratio = th / (th + ms)
			local thumbH = floor(math.max(20, (pvTrack:GetHeight()) * ratio))
			pvThumb:SetHeight(thumbH)
			local cur = sf:GetVerticalScroll()
			pvThumb:ClearAllPoints()
			pvThumb:SetPoint("TOP", pvTrack, "TOP", 0, -((cur / ms) * (pvTrack:GetHeight() - thumbH)))
		end
		sf:SetScript("OnScrollRangeChanged", UpdatePVThumb)

		-- Smooth scroll
		local smoothTarget = 0
		local smoothFrame = CreateFrame("Frame"); smoothFrame:Hide()
		smoothFrame:SetScript("OnUpdate", function(_, el)
			local cur = sf:GetVerticalScroll()
			local ms = sf:GetVerticalScrollRange()
			smoothTarget = floor(math.max(0, math.min(ms, smoothTarget)))
			local diff = smoothTarget - cur
			if math.abs(diff) < 0.3 then
				sf:SetVerticalScroll(smoothTarget); UpdatePVThumb(); smoothFrame:Hide(); return
			end
			sf:SetVerticalScroll(floor(math.max(0, math.min(ms, cur + diff * math.min(1, 12 * el)))))
			UpdatePVThumb()
		end)
		local function SmoothTo(t) smoothTarget = t; smoothFrame:Show() end
		sf:SetScript("OnMouseWheel", function(self, delta)
			local ms = self:GetVerticalScrollRange()
			if ms <= 0 then return end
			SmoothTo((smoothFrame:IsShown() and smoothTarget or self:GetVerticalScroll()) - delta * 40)
		end)

		pf._buttons = buttons; pf._bgTex = bgTex; pf._maxW = maxW
		pf._origScale = scale; pf._scrollFrame = sf; pf._wrapper = wrapper
		pf._PREVIEW_MAX_H = PREVIEW_MAX_H; pf._smoothFrame = smoothFrame
		pf._updatePVThumb = UpdatePVThumb
		pf._headerFixedH = math.abs(yOff) + 10

		pf.Update = function(self)
			local bdb = SB(); if not bdb then return end
			local _bw = bdb.buttonWidth or 35; local _bh = bdb.buttonHeight or 30
			local _nb = bdb.numButtons or 12; local _bpr = bdb.buttonsPerRow or 12
			local _sp = bdb.spacing or 3; local _bs = bdb.backdropSpacing or 3
			local anchor = bdb.anchor or "TOPLEFT"
			local _rows = ceil(_nb / _bpr); local _cols = _nb < _bpr and _nb or _bpr
			local _gw = 2 * _bs + _cols * _bw + (_cols - 1) * _sp
			local _gh = 2 * _bs + _rows * _bh + (_rows - 1) * _sp
			local s = self._origScale
			if _gw * s > self._maxW then s = self._maxW / _gw end
			local newWrapperH = floor(math.min(_gh * s, self._PREVIEW_MAX_H))
			self:SetSize(_gw, _gh); self:SetScale(s)
			self._wrapper:SetSize(_gw * s, newWrapperH)
			self._bgTex:SetAllPoints()
			if bdb.backdrop then self._bgTex:Show() else self._bgTex:Hide() end
			local realBar = _G["WTExtraItemsBar" .. selectedBar]
			for i = 1, 12 do
				local e = self._buttons[i]
				if i <= _nb then
					local idx = i - 1; local col = idx % _bpr; local row = floor(idx / _bpr)
					local x = _bs + col * (_bw + _sp); local _y
					if anchor == "TOPLEFT" or anchor == "TOPRIGHT" then
						_y = -(_bs + row * (_bh + _sp))
					else
						_y = -(_gh - _bs - (row + 1) * _bh - row * _sp)
					end
					if anchor == "TOPRIGHT" or anchor == "BOTTOMRIGHT" then
						x = _gw - _bs - (col + 1) * _bw - col * _sp
					end
					e.frame:SetSize(_bw, _bh); e.frame:ClearAllPoints()
					e.frame:SetPoint("TOPLEFT", self, "TOPLEFT", floor(x), floor(_y))
					local realBtn = realBar and realBar.buttons and realBar.buttons[i]
					if realBtn and realBtn:IsShown() and realBtn.tex then
						local tex = realBtn.tex:GetTexture()
						if tex then e.icon:SetTexture(tex); e.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
						else e.icon:SetColorTexture(0.06, 0.08, 0.10, 1) end
						e.count:SetText(realBtn.count and realBtn.count:GetText() or "")
					else
						e.icon:SetColorTexture(0.06, 0.08, 0.10, 1)
						e.count:SetText("")
					end
					e.frame:Show()
				else e.frame:Hide() end
			end
			if self._updatePVThumb then self._updatePVThumb() end
			if addon.UpdateContentHeaderHeight then
				addon.UpdateContentHeaderHeight(self._headerFixedH + newWrapperH)
			end
		end
		pf.Update(pf)
		activePreview = pf
		return floor(math.min(scaledH, PREVIEW_MAX_H))
	end

	-- =========================================================================
	--  CONTENT HEADER  (bar selector + preview, pinned at top)
	-- =========================================================================
	local _headerBuilder
	_headerBuilder = function(hdr, hdrW)
		local PAD = EllesmereUI.CONTENT_PAD or 20
		local fy = -18

		local DD_H = 32
		local ddW = 200
		local ddBtn, ddLbl = EllesmereUI.BuildDropdownControl(
			hdr, ddW, hdr:GetFrameLevel() + 5,
			BAR_LABELS, BAR_ORDER,
			function() return selectedBar end,
			function(v)
				_selectedBar = v
				selectedBar = v
				addon.InvalidateContentHeaderCache()
				addon.SetContentHeader(_headerBuilder)
				addon.RefreshOptions(true)
			end
		)
		ddBtn:ClearAllPoints()
		ddBtn:SetPoint("TOP", hdr, "TOP", 0, fy)
		ddBtn:SetHeight(DD_H)
		fy = fy - DD_H - 8

		local previewH = BuildLivePreview(hdr, fy)
		fy = fy - previewH

		return math.abs(fy) + 10
	end
	addon.SetContentHeader(_headerBuilder)

	-- =========================================================================
	--  GLOBAL SETTINGS
	-- =========================================================================
	local parseItemID = function(v) local id = tonumber(v); if id and id > 0 then return id end end
	local ebDis = function() return not db.enable end

	_, h = Widgets:SectionHeader(parent, MH("General"), y); y = y - h
	_, h = Widgets:Toggle(parent, "No Quantum Items", y,
		DBGet(db, "noQuantumItems"), DBSet(db, "noQuantumItems", updateBars),
		"Automatically blacklist the quantum items."); y = y - h
	local function itemSummary(list, isArray)
		local names = {}
		if isArray then
			for _, id in ipairs(list) do
				local n = _G.GetItemInfo(id)
				names[#names + 1] = n or tostring(id)
			end
		else
			for id in pairs(list) do
				local n = _G.GetItemInfo(id)
				names[#names + 1] = n or tostring(id)
			end
			table.sort(names)
		end
		if #names == 0 then return "(Empty)" end
		return table.concat(names, ", ")
	end
	local listRow
	listRow, h = Widgets:DualRow(parent, y,
		{ type="dropdown", text="Custom Items",
		  values={ ["_ph"]="..." }, order={ "_ph" },
		  getValue=function() return "_ph" end, setValue=function() end, disabled=ebDis },
		{ type="dropdown", text="Blacklist",
		  values={ ["_ph"]="..." }, order={ "_ph" },
		  getValue=function() return "_ph" end, setValue=function() end, disabled=ebDis }
	); y = y - h
	do
		local rgn = listRow and listRow._leftRegion
		if rgn then
			if rgn._control then rgn._control:Hide() end
			local trigger = addon.BuildListTrigger(rgn, 210, rgn:GetFrameLevel() + 2,
				itemSummary(db.customList, true),
				function(self) addon.OpenListDropdown({
					label="Custom Items", title="Custom Items", list=db.customList, mode="array", parse=parseItemID,
					invalidMessage="The item ID is invalid.", after=updateBars,
				}, self) end,
				ebDis)
			local PP = EllesmereUI.PP or EllesmereUI.PanelPP
			if PP then PP.Point(trigger, "RIGHT", rgn, "RIGHT", -20, 0) end
			rgn._control = trigger
			rgn._lastInline = nil
		end
	end
	do
		local rgn = listRow and listRow._rightRegion
		if rgn then
			if rgn._control then rgn._control:Hide() end
			local trigger = addon.BuildListTrigger(rgn, 210, rgn:GetFrameLevel() + 2,
				itemSummary(db.blackList, false),
				function(self) addon.OpenListDropdown({
					label="Blacklist", title="Blacklist", list=db.blackList, mode="map", parse=parseItemID,
					invalidMessage="The item ID is invalid.", after=updateBars,
				}, self) end,
				ebDis)
			local PP = EllesmereUI.PP or EllesmereUI.PanelPP
			if PP then PP.Point(trigger, "RIGHT", rgn, "RIGHT", -20, 0) end
			rgn._control = trigger
			rgn._lastInline = nil
		end
	end

	-- =========================================================================
	--  LAYOUT
	-- =========================================================================
	_, h = Widgets:SectionHeader(parent, MH("Layout"), y); y = y - h
	do
		local barDis = function() return not db.enable or not SB().enable end
		local lr0
		lr0, h = Widgets:DualRow(parent, y,
			{ type="toggle", text="Enable Bar " .. selectedBar,
			  getValue=SGet("enable"), setValue=SSet("enable"),
			  tooltip="Enable this specific bar.", disabled=function() return not db.enable end },
			{ type="toggle", text="Bar Backdrop",
			  getValue=SGet("backdrop"), setValue=SSet("backdrop"),
			  tooltip="Show a backdrop behind the bar.", disabled=barDis }
		); y = y - h

		local lr1, lr2, lr3
		lr1, h = Widgets:DualRow(parent, y,
			{ type="slider", text="Backdrop Spacing", min=1, max=30, step=1,
			  getValue=SGet("backdropSpacing"), setValue=SSet("backdropSpacing", updateBars),
			  tooltip="The spacing between the backdrop and the buttons.", disabled=barDis },
			{ type="slider", text="Button Spacing", min=1, max=30, step=1,
			  getValue=SGet("spacing"), setValue=SSet("spacing", updateBars),
			  tooltip="The spacing between buttons.", disabled=barDis }
		); y = y - h
		if lr1 and lr1._leftRegion then EllesmereUI.BuildSyncIcon({
			region=lr1._leftRegion, tooltip="Apply spacing to all Bars",
			onClick=function() for i=1,5 do local d=db["bar"..i]; if d then d.backdropSpacing=SB().backdropSpacing; d.spacing=SB().spacing end end; updateBars(); addon.RefreshOptions() end,
			isSynced=function() local vs=SB().spacing; local vb=SB().backdropSpacing; for i=1,5 do if db["bar"..i].enable and (db["bar"..i].spacing~=vs or db["bar"..i].backdropSpacing~=vb) then return false end end; return true end,
			multiApply={ elementKeys={1,2,3,4,5}, elementLabels={[1]="Bar 1",[2]="Bar 2",[3]="Bar 3",[4]="Bar 4",[5]="Bar 5"}, getCurrentKey=function() return selectedBar end, onApply=function(keys) for _,i in ipairs(keys) do local d=db["bar"..i]; if d then d.backdropSpacing=SB().backdropSpacing; d.spacing=SB().spacing end end; updateBars(); addon.RefreshOptions() end },
		}) end

		lr2, h = Widgets:DualRow(parent, y,
			{ type="slider", text="Buttons", min=1, max=12, step=1,
			  getValue=SGet("numButtons"), setValue=SSet("numButtons", updateBars), disabled=barDis },
			{ type="slider", text="Buttons Per Row", min=1, max=12, step=1,
			  getValue=SGet("buttonsPerRow"), setValue=SSet("buttonsPerRow", updateBars), disabled=barDis }
		); y = y - h
		if lr2 and lr2._leftRegion then EllesmereUI.BuildSyncIcon({
			region=lr2._leftRegion, tooltip="Apply button count to all Bars",
			onClick=function() for i=1,5 do local d=db["bar"..i]; if d then d.numButtons=SB().numButtons; d.buttonsPerRow=SB().buttonsPerRow end end; updateBars(); addon.RefreshOptions() end,
			isSynced=function() local vn=SB().numButtons; local vp=SB().buttonsPerRow; for i=1,5 do if db["bar"..i].enable and (db["bar"..i].numButtons~=vn or db["bar"..i].buttonsPerRow~=vp) then return false end end; return true end,
			multiApply={ elementKeys={1,2,3,4,5}, elementLabels={[1]="Bar 1",[2]="Bar 2",[3]="Bar 3",[4]="Bar 4",[5]="Bar 5"}, getCurrentKey=function() return selectedBar end, onApply=function(keys) for _,i in ipairs(keys) do local d=db["bar"..i]; if d then d.numButtons=SB().numButtons; d.buttonsPerRow=SB().buttonsPerRow end end; updateBars(); addon.RefreshOptions() end },
		}) end

		lr3, h = Widgets:DualRow(parent, y,
			{ type="slider", text="Button Width", min=2, max=80, step=1,
			  getValue=SGet("buttonWidth"), setValue=SSet("buttonWidth", updateBars), disabled=barDis },
			{ type="slider", text="Button Height", min=2, max=60, step=1,
			  getValue=SGet("buttonHeight"), setValue=SSet("buttonHeight", updateBars), disabled=barDis }
		); y = y - h
		if lr3 and lr3._leftRegion then EllesmereUI.BuildSyncIcon({
			region=lr3._leftRegion, tooltip="Apply size to all Bars",
			onClick=function() for i=1,5 do local d=db["bar"..i]; if d then d.buttonWidth=SB().buttonWidth; d.buttonHeight=SB().buttonHeight end end; updateBars(); addon.RefreshOptions() end,
			isSynced=function() local vw=SB().buttonWidth; local vh=SB().buttonHeight; for i=1,5 do if db["bar"..i].enable and (db["bar"..i].buttonWidth~=vw or db["bar"..i].buttonHeight~=vh) then return false end end; return true end,
			multiApply={ elementKeys={1,2,3,4,5}, elementLabels={[1]="Bar 1",[2]="Bar 2",[3]="Bar 3",[4]="Bar 4",[5]="Bar 5"}, getCurrentKey=function() return selectedBar end, onApply=function(keys) for _,i in ipairs(keys) do local d=db["bar"..i]; if d then d.buttonWidth=SB().buttonWidth; d.buttonHeight=SB().buttonHeight end end; updateBars(); addon.RefreshOptions() end },
		}) end

		local anchorRow
		anchorRow, h = Widgets:DualRow(parent, y,
			{ type="dropdown", text="Anchor Point",
			  values = ANCHOR_CORNER_VALUES, order = ANCHOR_CORNER_ORDER,
			  getValue=SGet("anchor"), setValue=SSet("anchor"),
			  tooltip="The first button anchors itself to this point on the bar.", disabled=barDis },
			{ type="dropdown", text="Button Groups",
			  values={ ["_placeholder"]="..." }, order={ "_placeholder" },
			  getValue=function() return "_placeholder" end,
			  setValue=function() end, disabled=barDis }
		); y = y - h
		do
			local rgn = anchorRow and anchorRow._rightRegion
			if rgn and rgn._control then rgn._control:Hide() end
			local PP = EllesmereUI.PP or EllesmereUI.PanelPP
			local function includeHas(key)
				local b = SB()
				if not b or not b.include then return false end
				for _, module in ipairs({ strsplit("[, ]", b.include) }) do
					if module == key then return true end
				end
				return false
			end
			local function includeSet(key, on)
				local b = SB()
				if not b then return end
				local set = {}
				for _, module in ipairs({ strsplit("[, ]", b.include or "") }) do
					if module ~= "" then set[module] = true end
				end
				if on then set[key] = true else set[key] = nil end
				local list = {}
				for k in pairs(set) do list[#list + 1] = k end
				b.include = table.concat(list, ",")
				if activePreview and activePreview.Update then activePreview:Update() end
				updateBars()
			end
			if rgn then
				local cbDD, cbDDRefresh = EllesmereUI.BuildVisOptsCBDropdown(
					rgn, 210, rgn:GetFrameLevel() + 2,
					GROUP_ITEMS,
					includeHas, includeSet
				)
				if PP then PP.Point(cbDD, "RIGHT", rgn, "RIGHT", -20, 0) end
				rgn._control = cbDD
				rgn._lastInline = nil
				EllesmereUI.RegisterWidgetRefresh(cbDDRefresh)
			end
		end
	end

	-- =========================================================================
	--  VISIBILITY
	-- =========================================================================
	_, h = Widgets:SectionHeader(parent, MH("Visibility"), y); y = y - h
	do
		local barDis = function() return not db.enable or not SB().enable end
		local vr1
		vr1, h = Widgets:DualRow(parent, y,
			{ type="toggle", text="Inherit Global Fade",
			  getValue=SGet("globalFade"), setValue=SSet("globalFade"), disabled=barDis },
			{ type="toggle", text="Mouse Over", tooltip="Only show the bar when you mouse over it.",
			  getValue=SGet("mouseOver"), setValue=SSet("mouseOver"), disabled=barDis }
		); y = y - h
		if vr1 and vr1._leftRegion then EllesmereUI.BuildSyncIcon({
			region=vr1._leftRegion, tooltip="Apply fade mode to all Bars",
			onClick=function() for i=1,5 do local d=db["bar"..i]; if d then d.globalFade=SB().globalFade; d.mouseOver=SB().mouseOver end end; updateBars(); addon.RefreshOptions() end,
			isSynced=function() local vg=SB().globalFade; local vm=SB().mouseOver; for i=1,5 do if db["bar"..i].enable and (db["bar"..i].globalFade~=vg or db["bar"..i].mouseOver~=vm) then return false end end; return true end,
			multiApply={ elementKeys={1,2,3,4,5}, elementLabels={[1]="Bar 1",[2]="Bar 2",[3]="Bar 3",[4]="Bar 4",[5]="Bar 5"}, getCurrentKey=function() return selectedBar end, onApply=function(keys) for _,i in ipairs(keys) do local d=db["bar"..i]; if d then d.globalFade=SB().globalFade; d.mouseOver=SB().mouseOver end end; updateBars(); addon.RefreshOptions() end },
		}) end
		AttachCog(vr1 and vr1._rightRegion, "Fade Settings", {
			{ type="slider", label="Fade Time", min=0, max=2, step=0.01,
			  get=function() return SB().fadeTime end,
			  set=function(v) SB().fadeTime = v; updateBars() end },
			{ type="slider", label="Alpha Min", min=0, max=1, step=0.01,
			  get=function() return SB().alphaMin end,
			  set=function(v) SB().alphaMin = v; updateBars() end },
			{ type="slider", label="Alpha Max", min=0, max=1, step=0.01,
			  get=function() return SB().alphaMax end,
			  set=function(v) SB().alphaMax = v; updateBars() end },
		})

		local vr2
		vr2, h = Widgets:DualRow(parent, y,
			{ type="toggle", text="Tooltip",
			  getValue=SGet("tooltip"), setValue=SSet("tooltip"), disabled=barDis },
			{ type="spacer" }
		); y = y - h
	end

	-- =========================================================================
	--  TEXT & FONTS  (gear popups)
	-- =========================================================================
	_, h = Widgets:SectionHeader(parent, MH("Text & Fonts"), y); y = y - h
	do
		local barDis = function() return not db.enable or not SB().enable end
		local fontValues, fontOrder = EllesmereUI.BuildFontDropdownData()

		local function fontCogRows(fontKey)
			return {
				{ type="dropdown", label="Font", values=fontValues, order=fontOrder,
				  get=function() return SB()[fontKey].name end,
				  set=function(v) SB()[fontKey].name = v; updateBars() end },
				{ type="dropdown", label="Outline", values=OUTLINE_VALUES, order=OUTLINE_ORDER,
				  get=function() return SB()[fontKey].style end,
				  set=function(v) SB()[fontKey].style = v; updateBars() end },
				{ type="slider", label="Size", min=5, max=60, step=1,
				  get=function() return SB()[fontKey].size end,
				  set=function(v) SB()[fontKey].size = v; updateBars() end },
				{ type="slider", label="X Offset", min=-20, max=20, step=1,
				  get=function() return SB()[fontKey].xOffset or 0 end,
				  set=function(v) SB()[fontKey].xOffset = v; updateBars() end },
				{ type="slider", label="Y Offset", min=-20, max=20, step=1,
				  get=function() return SB()[fontKey].yOffset or 0 end,
				  set=function(v) SB()[fontKey].yOffset = v; updateBars() end },
				{ type="colorpicker", label="Color",
				  get=function() local c=SB()[fontKey].color or {}; return c.r or 1, c.g or 1, c.b or 1 end,
				  set=function(r,g,b) local f=SB()[fontKey]; f.color=f.color or {}; f.color.r,f.color.g,f.color.b=r,g,b; updateBars() end },
			}
		end

		local fr1
		fr1, h = Widgets:DualRow(parent, y,
			{ type="toggle", text="Count Text",
			  getValue=function() return SB().enable end, setValue=function() end, disabled=barDis },
			{ type="toggle", text="Bind Text",
			  getValue=function() return SB().enable end, setValue=function() end, disabled=barDis }
		); y = y - h
		AttachCog(fr1 and fr1._leftRegion, "Count Text", fontCogRows("countFont"))
		AttachCog(fr1 and fr1._rightRegion, "Bind Text", fontCogRows("bindFont"))

		local fr2
		fr2, h = Widgets:DualRow(parent, y,
			{ type="toggle", text="Quality Tier",
			  getValue=function() return SB().enable end, setValue=function() end, disabled=barDis },
			{ type="spacer" }
		); y = y - h
		AttachCog(fr2 and fr2._leftRegion, "Quality Tier", {
			{ type="slider", label="Size", min=5, max=40, step=1,
			  get=function() return SB().qualityTier.size end,
			  set=function(v) SB().qualityTier.size = v; updateBars() end },
			{ type="slider", label="X Offset", min=-20, max=20, step=1,
			  get=function() return SB().qualityTier.xOffset or 0 end,
			  set=function(v) SB().qualityTier.xOffset = v; updateBars() end },
			{ type="slider", label="Y Offset", min=-20, max=20, step=1,
			  get=function() return SB().qualityTier.yOffset or 0 end,
			  set=function(v) SB().qualityTier.yOffset = v; updateBars() end },
		})
	end

	return y
end)
