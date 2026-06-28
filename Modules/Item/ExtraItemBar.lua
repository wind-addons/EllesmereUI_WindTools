local W, F, E, L = unpack((select(2, ...))) ---@type WindTools, Functions, ElvUI, LocaleTable
local EB = W:NewModule("ExtraItemsBar")
local async = W.Utilities.Async

local EUI = _G.EllesmereUI
local PP = EUI and EUI.PP

local _G = _G
local ceil = ceil
local format = format
local ipairs = ipairs
local pairs = pairs
local sort = sort
local strmatch = strmatch
local strsplit = strsplit
local tinsert = tinsert
local tonumber = tonumber
local unpack = unpack
local wipe = wipe

local CooldownFrame_Set = CooldownFrame_Set
local CreateAtlasMarkup = CreateAtlasMarkup
local CreateFrame = CreateFrame
local GameTooltip = _G.GameTooltip
local GetBindingKey = GetBindingKey
local GetInventoryItemCooldown = GetInventoryItemCooldown
local GetInventoryItemID = GetInventoryItemID
local GetQuestLogSpecialItemCooldown = GetQuestLogSpecialItemCooldown
local GetQuestLogSpecialItemInfo = GetQuestLogSpecialItemInfo
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown
local RegisterStateDriver = RegisterStateDriver
local UnregisterStateDriver = UnregisterStateDriver
local UIFrameFadeIn = UIFrameFadeIn
local UIFrameFadeOut = UIFrameFadeOut

local C_Item_GetItemCooldown = C_Item.GetItemCooldown
local C_Item_GetItemCount = C_Item.GetItemCount
local C_Item_GetItemInfoInstant = C_Item.GetItemInfoInstant
local C_Item_IsItemInRange = C_Item.IsItemInRange
local C_Item_IsUsableItem = C_Item.IsUsableItem
local C_QuestLog_GetDistanceSqToQuest = C_QuestLog.GetDistanceSqToQuest
local C_QuestLog_GetNumQuestLogEntries = C_QuestLog.GetNumQuestLogEntries
local C_QuestLog_GetQuestIDForLogIndex = C_QuestLog.GetQuestIDForLogIndex
local C_Timer_NewTicker = C_Timer.NewTicker
local C_TradeSkillUI_GetItemReagentQualityInfo = C_TradeSkillUI.GetItemReagentQualityInfo

local NORM_TEX = "Interface\\Buttons\\WHITE8x8"

local questItemList = {}
local function UpdateQuestItemList()
	wipe(questItemList)

	for questLogIndex = 1, C_QuestLog_GetNumQuestLogEntries() do
		local link = GetQuestLogSpecialItemInfo(questLogIndex)
		if link then
			local questID = C_QuestLog_GetQuestIDForLogIndex(questLogIndex)
			local distance = questID and C_QuestLog_GetDistanceSqToQuest(questID)
			local itemID = C_Item_GetItemInfoInstant(link)
			tinsert(questItemList, { questLogIndex = questLogIndex, itemID = itemID, distance = distance or 1e8 })
		end
	end

	sort(questItemList, function(a, b)
		return a.distance < b.distance
	end)
end

local forceUsableItems = {
	[193634] = true,
	[206448] = true,
}

local equipmentList = {}
local function UpdateEquipmentList()
	wipe(equipmentList)
	for slotID = 1, 18 do
		local itemID = GetInventoryItemID("player", slotID)
		if itemID and (C_Item_IsUsableItem(itemID) or forceUsableItems[itemID]) then
			tinsert(equipmentList, slotID)
		end
	end
end

local function ParseSlotFilter(slotStr)
	if not slotStr or slotStr == "" then
		return nil
	end

	local allowedSlots = {}

	if strmatch(slotStr, "^(%d+)-(%d+)$") then
		local startSlot, endSlot = strmatch(slotStr, "^(%d+)-(%d+)$")
		startSlot, endSlot = tonumber(startSlot), tonumber(endSlot)
		if startSlot and endSlot and startSlot <= endSlot then
			for slotID = startSlot, endSlot do
				if slotID >= 1 and slotID <= 18 then
					allowedSlots[slotID] = true
				end
			end
		end
	elseif strmatch(slotStr, "^%d+$") then
		local slotID = tonumber(slotStr)
		if slotID and slotID >= 1 and slotID <= 18 then
			allowedSlots[slotID] = true
		end
	end

	return allowedSlots
end

local UpdateAfterCombat = {
	[1] = false,
	[2] = false,
	[3] = false,
	[4] = false,
	[5] = false,
}

local function ApplyFontToDB(fontString, db, defaultSize)
	if not fontString or not db then return end
	local path
	if db.name == "__global" or not db.name then
		path = EUI and EUI.GetFontPath and EUI.GetFontPath("WindTools")
			or "Fonts\\FRIZQT__.TTF"
	else
		path = db.name
	end
	local flag = ""
	if db.style == "outline" then
		flag = EUI and EUI.GetFontOutlineFlag and EUI.GetFontOutlineFlag("WindTools") or "OUTLINE"
	elseif db.style == "thick" then
		flag = "THICKOUTLINE"
	end
	fontString:SetFont(path, db.size or defaultSize or 12, flag)
end

do
	local fakeButton = {
		HotKey = {
			text = "",
			SetText = function(self, text) self.text = text end,
			GetText = function(self) return self.text end,
		},
	}

	function EB:GetBindingKeyWithElvUI(key)
		return GetBindingKey(key) or ""
	end
end

function EB:CreateButton(name, barDB)
	local button = CreateFrame("Button", name, E.UIParent, "SecureActionButtonTemplate, BackdropTemplate")
	button:SetSize(barDB.buttonWidth, barDB.buttonHeight)
	button:SetClampedToScreen(true)
	button:SetAttribute("type", "item")
	button:EnableMouse(false)
	button:RegisterForClicks("AnyDown")

	local tex = button:CreateTexture(nil, "OVERLAY", nil)
	tex:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
	tex:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
	tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	local qualityTier = button:CreateFontString(nil, "OVERLAY")
	qualityTier:SetTextColor(1, 1, 1, 1)
	qualityTier:SetPoint("TOPLEFT", button, "TOPLEFT")
	qualityTier:SetJustifyH("CENTER")
	qualityTier:SetFont("Fonts\\FRIZQT__.TTF", barDB.qualityTier.size or 12, "OUTLINE")

	local count = button:CreateFontString(nil, "OVERLAY")
	count:SetTextColor(1, 1, 1, 1)
	count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT")
	count:SetJustifyH("CENTER")
	ApplyFontToDB(count, barDB.countFont, 12)

	local bind = button:CreateFontString(nil, "OVERLAY")
	bind:SetTextColor(0.6, 0.6, 0.6)
	bind:SetPoint("TOPRIGHT", button, "TOPRIGHT")
	bind:SetJustifyH("CENTER")
	ApplyFontToDB(bind, barDB.bindFont, 12)

	local cooldown = CreateFrame("Cooldown", name .. "Cooldown", button, "CooldownFrameTemplate")

	button.tex = tex
	button.qualityTier = qualityTier
	button.count = count
	button.bind = bind
	button.cooldown = cooldown

	if PP then
		PP.CreateBorder(button, 0, 0, 0, 1, 1, "BORDER", 0)
	end

	button.SetTier = function(_, itemIDOrLink)
		local qualityInfo = C_TradeSkillUI_GetItemReagentQualityInfo(itemIDOrLink)

		if not qualityInfo or not qualityInfo.icon or qualityInfo.icon == "" then
			button.qualityTier:SetText("")
			button.qualityTier:Hide()
		else
			button.qualityTier:SetText(CreateAtlasMarkup(qualityInfo.icon))
			button.qualityTier:Show()
		end
	end

	return button
end

function EB:SetUpButton(button, itemData, slotID, waitGroup)
	button.itemName = nil
	button.itemID = nil
	button.spellName = nil
	button.slotID = nil
	button.countText = nil

	if itemData then
		button.itemID = itemData.itemID
		button.countText = C_Item_GetItemCount(itemData.itemID, nil, true)
		button.questLogIndex = itemData.questLogIndex

		waitGroup.count = waitGroup.count + 1
		async.WithItemID(itemData.itemID, function(item)
			button.itemName = item:GetItemName()
			button.tex:SetTexture(item:GetItemIcon())
			button:SetTier(itemData.itemID)
			E:Delay(0.1, function()
				waitGroup.count = waitGroup.count - 1
			end)
		end)
	elseif slotID then
		button.slotID = slotID

		waitGroup.count = waitGroup.count + 1
		async.WithItemSlotID(slotID, function(item)
			button.itemName = item:GetItemName()
			button.tex:SetTexture(item:GetItemIcon())

			local color = item:GetItemQualityColor()

			if PP and PP.SetBorderColor and color then
				PP.SetBorderColor(button, color.r, color.g, color.b)
			end

			button:SetTier(item:GetItemID())

			E:Delay(0.1, function()
				waitGroup.count = waitGroup.count - 1
			end)
		end)
	end

	if button.countText and button.countText > 1 then
		button.count:SetText(button.countText)
	else
		button.count:SetText()
	end

	local OnUpdateFunction
	if button.itemID then
		OnUpdateFunction = function(_)
			local start, duration, enable
			if button.questLogIndex and button.questLogIndex > 0 then
				start, duration, enable = GetQuestLogSpecialItemCooldown(button.questLogIndex)
			else
				start, duration, enable = C_Item_GetItemCooldown(button.itemID)
			end
			CooldownFrame_Set(button.cooldown, start, duration, enable)
			if duration and duration > 0 and enable and enable == 0 then
				button.tex:SetVertexColor(0.4, 0.4, 0.4)
			elseif not InCombatLockdown() and C_Item_IsItemInRange(button.itemID, "target") == false then
				button.tex:SetVertexColor(1, 0, 0)
			else
				button.tex:SetVertexColor(1, 1, 1)
			end
		end
	elseif button.slotID then
		OnUpdateFunction = function(_)
			local start, duration, enable = GetInventoryItemCooldown("player", button.slotID)
			CooldownFrame_Set(button.cooldown, start, duration, enable)
		end
	end
	button:SetScript("OnUpdate", OnUpdateFunction)

	button:SetScript("OnEnter", function(_)
		local bar = button:GetParent()
		local barDB = EB.db["bar" .. bar.id]
		if not bar or not barDB then
			return
		end

		if barDB.mouseOver and not barDB.globalFade then
			local alphaCurrent = bar:GetAlpha()
			UIFrameFadeIn(
				bar,
				barDB.fadeTime * (barDB.alphaMax - alphaCurrent) / (barDB.alphaMax - barDB.alphaMin),
				alphaCurrent,
				barDB.alphaMax
			)
		end

		if barDB.tooltip then
			GameTooltip:SetOwner(button, "ANCHOR_BOTTOMRIGHT", 0, -2)
			GameTooltip:ClearLines()

			if button.slotID then
				GameTooltip:SetInventoryItem("player", button.slotID)
			else
				GameTooltip:SetItemByID(button.itemID)
			end

			GameTooltip:Show()
		end
	end)

	button:SetScript("OnLeave", function(_)
		local bar = button:GetParent()
		local barDB = EB.db["bar" .. bar.id]
		if not bar or not barDB then
			return
		end

		if barDB.mouseOver and not barDB.globalFade then
			local alphaCurrent = bar:GetAlpha()
			UIFrameFadeOut(
				bar,
				barDB.fadeTime * (alphaCurrent - barDB.alphaMin) / (barDB.alphaMax - barDB.alphaMin),
				alphaCurrent,
				barDB.alphaMin
			)
		end

		GameTooltip:Hide()
	end)

	if not InCombatLockdown() then
		button:EnableMouse(true)
		button:Show()
		button:SetAttribute("type", "macro")

		local macroText
		if button.slotID then
			macroText = "/use " .. button.slotID
		elseif button.itemName then
			macroText = "/use item:" .. button.itemID
			if button.itemID == 172347 then
				macroText = macroText .. "\n/use 5"
			end
		end

		if macroText then
			button:SetAttribute("macrotext", macroText)
		end
	end
end

function EB:UpdateButtonSize(button, barDB)
	button:SetSize(barDB.buttonWidth, barDB.buttonHeight)
	button.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
end

function EB:PLAYER_REGEN_ENABLED()
	for i = 1, 5 do
		if UpdateAfterCombat[i] then
			self:UpdateBar(i)
			UpdateAfterCombat[i] = false
		end
	end
end

function EB:UpdateBarTextOnCombat(i)
	for k = 1, 12 do
		local button = self.bars[i].buttons[k]
		if button.itemID and button:IsShown() then
			button.countText = C_Item_GetItemCount(button.itemID, nil, true)
			if button.countText and button.countText > 1 then
				button.count:SetText(button.countText)
			else
				button.count:SetText()
			end
		end
	end
end

function EB:CreateBar(id)
	if not self.db or not self.db["bar" .. id] then
		return
	end

	local barDB = self.db["bar" .. id]

	local bar = CreateFrame("Frame", "WTExtraItemsBar" .. id, E.UIParent, "SecureHandlerStateTemplate")
	bar.id = id
	bar:SetClampedToScreen(true)
	bar:SetFrameStrata("LOW")
	bar:SetFrameLevel(5)

	local bg = bar:CreateTexture(nil, "BACKGROUND")
	bg:SetTexture(NORM_TEX)
	bg:SetVertexColor(0, 0, 0, 0.5)
	bg:SetAllPoints()
	if bg.SetSnapToPixelGrid then
		bg:SetSnapToPixelGrid(false)
		bg:SetTexelSnappingBias(0)
	end
	bar.bg = bg
	bar.backdrop = bg

	if PP then
		PP.CreateBorder(bar, 0, 0, 0, 1, 1, "BORDER", 0)
	end

	bar.buttons = {}
	for i = 1, 12 do
		bar.buttons[i] = self:CreateButton(bar:GetName() .. "Button" .. i, barDB)
		bar.buttons[i]:SetParent(bar)
		if i == 1 then
			bar.buttons[i]:SetPoint("LEFT", bar, "LEFT", 5, 0)
		else
			bar.buttons[i]:SetPoint("LEFT", bar.buttons[i - 1], "RIGHT", 5, 0)
		end
	end

	bar:SetScript("OnEnter", function(_)
		if not barDB then return end
		if barDB.mouseOver and not barDB.globalFade then
			local alphaCurrent = bar:GetAlpha()
			UIFrameFadeIn(
				bar,
				barDB.fadeTime * (barDB.alphaMax - alphaCurrent) / (barDB.alphaMax - barDB.alphaMin),
				alphaCurrent,
				barDB.alphaMax
			)
		end
	end)

	bar:SetScript("OnLeave", function(_)
		if not barDB then return end
		if barDB.mouseOver and not barDB.globalFade then
			local alphaCurrent = bar:GetAlpha()
			UIFrameFadeOut(
				bar,
				barDB.fadeTime * (alphaCurrent - barDB.alphaMin) / (barDB.alphaMax - barDB.alphaMin),
				alphaCurrent,
				barDB.alphaMin
			)
		end
	end)

	self.bars[id] = bar
end

function EB:ValidateItem(itemID)
	if not itemID then
		return false
	end

	if self.db.blackList[itemID] then
		return false
	end

	if self.StateCheckList[itemID] and not self:GetState(self.StateCheckList[itemID]) then
		return false
	end

	local count = C_Item_GetItemCount(itemID)
	local countThreshold = self.CountThreshold[itemID] or 1
	if not count or count < countThreshold then
		return false
	end

	return true
end

function EB:UpdateBar(id)
	if not self.db or not self.db["bar" .. id] then
		return
	end

	local bar = self.bars[id]
	local barDB = self.db["bar" .. id]

	if bar.waitGroup and bar.waitGroup.ticker then
		bar.waitGroup.ticker:Cancel()
	end

	bar.waitGroup = { count = 0 }

	if InCombatLockdown() then
		self:UpdateBarTextOnCombat(id)
		UpdateAfterCombat[id] = true
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end

	if not self.db.enable or not barDB.enable then
		if bar.register then
			UnregisterStateDriver(bar, "visibility")
			bar.register = false
			bar.registeredVisibility = nil
		end
		bar:Hide()
		return
	end

	local buttonID = 1

	local function addNormalButton(itemID)
		if self:ValidateItem(itemID) and buttonID <= barDB.numButtons then
			self:SetUpButton(bar.buttons[buttonID], { itemID = itemID }, nil, bar.waitGroup)
			self:UpdateButtonSize(bar.buttons[buttonID], barDB)
			buttonID = buttonID + 1
		end
	end

	local function addSlotButton(slotID)
		local itemID = GetInventoryItemID("player", slotID)
		if self:ValidateItem(itemID) and buttonID <= barDB.numButtons then
			self:SetUpButton(bar.buttons[buttonID], nil, slotID, bar.waitGroup)
			self:UpdateButtonSize(bar.buttons[buttonID], barDB)
			buttonID = buttonID + 1
		end
	end

	local function addNormalButtons(list)
		for _, itemID in pairs(list) do
			addNormalButton(itemID)
		end
	end

	for _, module in ipairs({ strsplit("[, ]", barDB.include) }) do
		if buttonID <= barDB.numButtons then
			if self.ModuleList[module] then
				addNormalButtons(self.ModuleList[module])
			elseif module == "QUEST" then
				for _, data in ipairs(questItemList) do
					addNormalButton(data.itemID)
				end
			elseif module == "EQUIP" then
				for _, slotID in pairs(equipmentList) do
					addSlotButton(slotID)
				end
			elseif strmatch(module, "^SLOT:") then
				local slotFilter = strmatch(module, "^SLOT:(.+)$")
				local allowedSlots = ParseSlotFilter(slotFilter)
				if allowedSlots then
					for _, slotID in pairs(equipmentList) do
						if allowedSlots[slotID] then
							addSlotButton(slotID)
						end
					end
				end
			elseif module == "CUSTOM" then
				addNormalButtons(self.db.customList)
			end
		end
	end

	local numRows = ceil((buttonID - 1) / barDB.buttonsPerRow)
	local numCols = buttonID > barDB.buttonsPerRow and barDB.buttonsPerRow or (buttonID - 1)
	local newBarWidth = 2 * barDB.backdropSpacing + numCols * barDB.buttonWidth + (numCols - 1) * barDB.spacing
	local newBarHeight = 2 * barDB.backdropSpacing + numRows * barDB.buttonHeight + (numRows - 1) * barDB.spacing
	bar:SetSize(newBarWidth, newBarHeight)

	if buttonID == 1 then
		if bar.register then
			UnregisterStateDriver(bar, "visibility")
			bar.register = false
			bar.registeredVisibility = nil
		end
		bar:Hide()
		return
	end

	if buttonID <= 12 then
		for hideButtonID = buttonID, 12 do
			bar.buttons[hideButtonID]:Hide()
		end
	end

	for i = 1, buttonID - 1 do
		local anchor = barDB.anchor
		local button = bar.buttons[i]

		button:ClearAllPoints()

		if i == 1 then
			if anchor == "TOPLEFT" then
				button:SetPoint(anchor, bar, anchor, barDB.backdropSpacing, -barDB.backdropSpacing)
			elseif anchor == "TOPRIGHT" then
				button:SetPoint(anchor, bar, anchor, -barDB.backdropSpacing, -barDB.backdropSpacing)
			elseif anchor == "BOTTOMLEFT" then
				button:SetPoint(anchor, bar, anchor, barDB.backdropSpacing, barDB.backdropSpacing)
			elseif anchor == "BOTTOMRIGHT" then
				button:SetPoint(anchor, bar, anchor, -barDB.backdropSpacing, barDB.backdropSpacing)
			end
		elseif i <= barDB.buttonsPerRow then
			local nearest = bar.buttons[i - 1]
			if anchor == "TOPLEFT" or anchor == "BOTTOMLEFT" then
				button:SetPoint("LEFT", nearest, "RIGHT", barDB.spacing, 0)
			else
				button:SetPoint("RIGHT", nearest, "LEFT", -barDB.spacing, 0)
			end
		else
			local nearest = bar.buttons[i - barDB.buttonsPerRow]
			if anchor == "TOPLEFT" or anchor == "TOPRIGHT" then
				button:SetPoint("TOP", nearest, "BOTTOM", 0, -barDB.spacing)
			else
				button:SetPoint("BOTTOM", nearest, "TOP", 0, barDB.spacing)
			end
		end

		button.qualityTier:SetFont("Fonts\\FRIZQT__.TTF", barDB.qualityTier.size or 12, "OUTLINE")

		ApplyFontToDB(button.count, barDB.countFont, 12)

		if barDB.countFont and barDB.countFont.color then
			local c = barDB.countFont.color
			button.count:SetTextColor(c.r or 1, c.g or 1, c.b or 1)
		end

		ApplyFontToDB(button.bind, barDB.bindFont, 12)

		if barDB.bindFont and barDB.bindFont.color then
			local c = barDB.bindFont.color
			button.bind:SetTextColor(c.r or 1, c.g or 1, c.b or 1)
		end

		button.qualityTier:ClearAllPoints()
		button.qualityTier:SetPoint("TOPLEFT", button, "TOPLEFT", barDB.qualityTier.xOffset or 0, barDB.qualityTier.yOffset or 0)

		button.count:ClearAllPoints()
		button.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", barDB.countFont.xOffset or 0, barDB.countFont.yOffset or 0)

		button.bind:ClearAllPoints()
		button.bind:SetPoint("TOPRIGHT", button, "TOPRIGHT", barDB.bindFont.xOffset or 0, barDB.bindFont.yOffset or 0)
	end

	if bar.registeredVisibility ~= barDB.visibility and bar.register then
		UnregisterStateDriver(bar, "visibility")
		bar.register = false
		bar.registeredVisibility = nil
	end

	if not bar.register then
		RegisterStateDriver(bar, "visibility", barDB.visibility)
		bar.register = true
		bar.registeredVisibility = barDB.visibility
	end

	if barDB.backdrop then
		bar.bg:Show()
	else
		bar.bg:Hide()
	end

	bar.waitGroup.ticker = C_Timer_NewTicker(0.1, function()
		if bar.waitGroup.count == 0 then
			if bar.waitGroup.ticker then
				bar.waitGroup.ticker:Cancel()
			end
			bar.alphaMin = barDB.alphaMin
			bar.alphaMax = barDB.alphaMax

			if barDB.globalFade then
				bar:SetAlpha(1)
			else
				bar:SetAlpha(barDB.mouseOver and barDB.alphaMin or barDB.alphaMax)
			end

			bar.waitGroup = nil
		end
	end)
end

function EB:UpdateBars()
	self:UpdateState(EB.STATE.IN_DELVE)
	for i = 1, 5 do
		self:UpdateBar(i)
	end
end

do
	local lastUpdateTime = 0
	function EB:UNIT_INVENTORY_CHANGED()
		local now = GetTime()
		if now - lastUpdateTime < 0.25 then
			return
		end
		lastUpdateTime = now
		UpdateQuestItemList()
		UpdateEquipmentList()

		self:UpdateBars()
	end
end

function EB:UpdateQuestItem()
	UpdateQuestItemList()
	self:UpdateBars()
end

function EB:UpdateEquipmentItem()
	UpdateEquipmentList()
	self:UpdateBars()
end

do
	local InUpdating = false
	function EB:ITEM_LOCKED()
		if InUpdating then
			return
		end

		InUpdating = true
		E:Delay(1, function()
			UpdateEquipmentList()
			self:UpdateBars()
			InUpdating = false
		end)
	end
end

function EB:CreateAll()
	self.bars = {}

	for i = 1, 5 do
		self:CreateBar(i)
	end
end

function EB:RegisterMover(id)
	if not EUI or not EUI.RegisterUnlockElements or not EUI.MakeUnlockElement then
		return
	end

	local MK = EUI.MakeUnlockElement
	local key = "WTExtraItemsBar" .. id

	local elements = {
		MK({
			key = key,
			label = L["Extra Items Bar"] .. " " .. id,
			group = "WindTools",
			order = 900 + id,
			getFrame = function()
				return EB.bars[id]
			end,
			getSize = function()
				if not EB.bars[id] then return 1, 1 end
				return EB.bars[id]:GetWidth(), EB.bars[id]:GetHeight()
			end,
			savePos = function(_, point, relPoint, x, y)
				if point and x and y then
					E.global.WT.item.extraItemsBar["bar" .. id].position = {
						point = point,
						relPoint = relPoint or point,
						x = x,
						y = y,
					}
				end
			end,
			loadPos = function()
				local pos = E.global.WT.item.extraItemsBar["bar" .. id].position
				if not pos then return nil end
				return {
					point = pos.point,
					relPoint = pos.relPoint or pos.point,
					x = pos.x,
					y = pos.y,
				}
			end,
			clearPos = function()
				E.global.WT.item.extraItemsBar["bar" .. id].position = nil
			end,
			applyPos = function()
				local bar = EB.bars[id]
				if not bar then return end
				local pos = E.global.WT.item.extraItemsBar["bar" .. id].position
				bar:ClearAllPoints()
				if pos and pos.point and pos.x and pos.y then
					bar:SetPoint(pos.point, E.UIParent, pos.relPoint or pos.point, pos.x, pos.y)
				else
					bar:SetPoint("BOTTOMLEFT", _G.RightChatPanel or _G.UIParent, "TOPLEFT", 0, (id - 1) * 45)
				end
			end,
			isHidden = function()
				local db = EB.db
				if not db or not db.enable then return true end
				local bd = db["bar" .. id]
				return not bd or not bd.enable
			end,
		}),
	}

	EUI:RegisterUnlockElements(elements, "EllesmereUI_WindTools")
end

function EB:UpdateBinding()
	if not self.db then
		return
	end

	for i = 1, 5 do
		local bar = self.bars[i]
		if bar then
			for j = 1, 12 do
				local button = bar.buttons[j]
				if button then
					local bindingName = format("CLICK WTExtraItemsBar%dButton%d:LeftButton", i, j)
					button.bind:SetText(GetBindingKey(bindingName) or "")
				end
			end
		end
	end
end

function EB:Initialize()
	self.db = E.db.WT.item.extraItemsBar
	if not self.db or not self.db.enable or self.initialized then
		return
	end

	self:CreateAll()
	UpdateQuestItemList()
	UpdateEquipmentList()
	self:UpdateState(EB.STATE.QUANTUM_ITEM_ALLOWED)
	self:UpdateBars()
	self:UpdateBinding()

	for i = 1, 5 do
		self:RegisterMover(i)
		self:ApplyDefaultPosition(i)
	end

	self:RegisterEvent("BAG_UPDATE_DELAYED", "UpdateBars")
	self:RegisterEvent("ITEM_LOCKED")
	self:RegisterEvent("PLAYER_ALIVE", "UpdateBars")
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "UpdateEquipmentItem")
	self:RegisterEvent("PLAYER_UNGHOST", "UpdateBars")
	self:RegisterEvent("QUEST_ACCEPTED", "UpdateQuestItem")
	self:RegisterEvent("QUEST_LOG_UPDATE", "UpdateQuestItem")
	self:RegisterEvent("QUEST_TURNED_IN", "UpdateQuestItem")
	self:RegisterEvent("QUEST_WATCH_LIST_CHANGED", "UpdateQuestItem")
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	self:RegisterEvent("UPDATE_BINDINGS", "UpdateBinding")
	self:RegisterEvent("ZONE_CHANGED", "UpdateBars")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "UpdateBars")

	self.initialized = true
end

function EB:ApplyDefaultPosition(id)
	local bar = self.bars[id]
	if not bar then return end

	local pos = E.global.WT.item.extraItemsBar["bar" .. id].position
	bar:ClearAllPoints()
	if pos and pos.point and pos.x and pos.y then
		bar:SetPoint(pos.point, E.UIParent, pos.relPoint or pos.point, pos.x, pos.y)
	else
		bar:SetPoint("BOTTOMLEFT", _G.RightChatPanel or _G.UIParent, "TOPLEFT", 0, (id - 1) * 45)
	end
end

function EB:ProfileUpdate()
	self:Initialize()

	if self.db.enable then
		UpdateQuestItemList()
		UpdateEquipmentList()
		self:UpdateState(EB.STATE.QUANTUM_ITEM_ALLOWED)
	elseif self.initialized then
		self:UnregisterEvent("BAG_UPDATE_DELAYED")
		self:UnregisterEvent("PLAYER_ALIVE")
		self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
		self:UnregisterEvent("PLAYER_UNGHOST")
		self:UnregisterEvent("QUEST_ACCEPTED")
		self:UnregisterEvent("QUEST_LOG_UPDATE")
		self:UnregisterEvent("QUEST_TURNED_IN")
		self:UnregisterEvent("QUEST_WATCH_LIST_CHANGED")
		self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
		self:UnregisterEvent("UPDATE_BINDINGS")
		self:UnregisterEvent("ZONE_CHANGED")
		self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
	end

	self:UpdateBars()
end

W:RegisterModule(EB:GetName())
