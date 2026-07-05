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
local GetInventoryItemTexture = GetInventoryItemTexture
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

local function GetGlobalFontPath()
	return EUI and EUI.GetFontPath and EUI.GetFontPath("WindTools")
		or STANDARD_TEXT_FONT
		or "Fonts\\FRIZQT__.TTF"
end

local function ResolveFontPath(name)
	if type(name) ~= "string" then
		name = nil
	end

	if not name or name == "" or name == "__global" then
		return GetGlobalFontPath()
	end

	if EUI and EUI.ResolveFontName then
		local path = EUI.ResolveFontName(name)
		if path then return path end
	end

	if EUI and EUI._smFontPaths and EUI._smFontPaths[name] then
		return EUI._smFontPaths[name]
	end

	local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
	if LSM and LSM:IsValid("font", name) then
		local path = LSM:Fetch("font", name)
		if path then return path end
	end

	if name:find("[\\/]", 1, false) or name:find("%.ttf$") or name:find("%.otf$") then
		return name
	end

	return GetGlobalFontPath()
end

local function ApplyFontToDB(fontString, db, defaultSize)
	if not fontString then return end
	db = db or { name = "__global" }
	local path = ResolveFontPath(db.name)
	local flag = ""
	local style = db.style and db.style:lower()
	if style == "outline" then
		flag = EUI and EUI.GetFontOutlineFlag and EUI.GetFontOutlineFlag("WindTools") or "OUTLINE"
	elseif style == "thick" or style == "thickoutline" then
		flag = "THICKOUTLINE"
	end
	local ok = pcall(fontString.SetFont, fontString, path, db.size or defaultSize or 12, flag)
	if not ok then
		fontString:SetFont(GetGlobalFontPath(), db.size or defaultSize or 12, flag)
	end
end

local function SetIconTexCoords(tex, width, height)
	if not tex then return end
	local left, right, top, bottom = 0.08, 0.92, 0.08, 0.92
	width = width or 1
	height = height or 1
	if width > height then
		local offset = (bottom - top) * (1 - height / width) / 2
		top = top + offset
		bottom = bottom - offset
	elseif width < height then
		local offset = (right - left) * (1 - width / height) / 2
		left = left + offset
		right = right - offset
	end
	tex:SetTexCoord(left, right, top, bottom)
end

local function NormalizeVisibility(visibility)
	visibility = visibility or "show"
	-- Old WindTools defaults used strings like "[petbattle]hide;show". Blizzard's
	-- state driver expects a space between the macro condition and state token.
	visibility = visibility:gsub("%](%S)", "] %1")
	visibility = visibility:gsub(";(%S)", "; %1")
	return visibility
end

local DEFAULT_BAR_DB = {
	enable = true,
	mouseOver = false,
	globalFade = false,
	visibility = "[petbattle] hide; show",
	fadeTime = 0.3,
	alphaMin = 0,
	alphaMax = 1,
	numButtons = 12,
	backdrop = true,
	backdropSpacing = 3,
	buttonSize = 34,
	buttonsPerRow = 12,
	anchor = "TOPLEFT",
	spacing = 3,
	tooltip = true,
	qualityTier = {
		size = 16,
		xOffset = 0,
		yOffset = 0,
	},
	countFont = {
		name = "__global",
		size = 12,
		style = "OUTLINE",
		xOffset = 0,
		yOffset = 0,
		color = { r = 1, g = 1, b = 1 },
	},
	bindFont = {
		name = "__global",
		size = 12,
		style = "OUTLINE",
		xOffset = 0,
		yOffset = 0,
		color = { r = 1, g = 1, b = 1 },
	},
	include = "CUSTOM",
}

local VALID_ANCHORS = {
	TOPLEFT = true,
	TOPRIGHT = true,
	BOTTOMLEFT = true,
	BOTTOMRIGHT = true,
}

local function FillDefaults(db, defaults)
	if not db or not defaults then return end
	for key, value in pairs(defaults) do
		if type(value) == "table" then
			if type(db[key]) ~= "table" then
				db[key] = {}
			end
			FillDefaults(db[key], value)
		elseif db[key] == nil then
			db[key] = value
		end
	end
end

local function EnsureBarDB(barDB)
	if barDB.buttonSize == nil and (barDB.buttonWidth or barDB.buttonHeight) then
		barDB.buttonSize = barDB.buttonWidth or barDB.buttonHeight
	end
	barDB.buttonWidth = nil
	barDB.buttonHeight = nil

	FillDefaults(barDB, DEFAULT_BAR_DB)
	if barDB.countFont and (barDB.countFont.name == "Montserrat" or barDB.countFont.name == "Montserrat (en)") then
		barDB.countFont.name = "__global"
	end
	if barDB.bindFont and (barDB.bindFont.name == "Montserrat" or barDB.bindFont.name == "Montserrat (en)") then
		barDB.bindFont.name = "__global"
	end
	barDB.numButtons = math.max(1, math.min(12, tonumber(barDB.numButtons) or DEFAULT_BAR_DB.numButtons))
	barDB.buttonsPerRow = math.max(1, math.min(12, tonumber(barDB.buttonsPerRow) or DEFAULT_BAR_DB.buttonsPerRow))
	barDB.buttonSize = math.max(1, tonumber(barDB.buttonSize) or DEFAULT_BAR_DB.buttonSize)
	barDB.backdropSpacing = math.max(0, tonumber(barDB.backdropSpacing) or DEFAULT_BAR_DB.backdropSpacing)
	barDB.spacing = math.max(0, tonumber(barDB.spacing) or DEFAULT_BAR_DB.spacing)
	barDB.fadeTime = tonumber(barDB.fadeTime) or DEFAULT_BAR_DB.fadeTime
	barDB.alphaMin = tonumber(barDB.alphaMin) or DEFAULT_BAR_DB.alphaMin
	barDB.alphaMax = tonumber(barDB.alphaMax) or DEFAULT_BAR_DB.alphaMax
	if not VALID_ANCHORS[barDB.anchor] then
		barDB.anchor = DEFAULT_BAR_DB.anchor
	end
	barDB.visibility = NormalizeVisibility(barDB.visibility)
end

local function SafeRegisterEvent(module, event, method)
	if not module or not event then return end
	pcall(module.RegisterEvent, module, event, method)
end

local function SetDefaultBarPosition(bar, id)
	bar:SetPoint("BOTTOMLEFT", E.UIParent, "BOTTOMLEFT", 0, 220 + (id - 1) * 42)
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
	local button = _G[name] or CreateFrame("Button", name, E.UIParent, "SecureActionButtonTemplate, BackdropTemplate")
	button:SetSize(barDB.buttonSize, barDB.buttonSize)
	button:SetClampedToScreen(true)
	button:SetAttribute("type", "item")
	button:EnableMouse(false)
	button:RegisterForClicks("AnyDown")

	local tex = button:CreateTexture(nil, "OVERLAY", nil)
	tex:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
	tex:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
	SetIconTexCoords(tex, barDB.buttonSize, barDB.buttonSize)

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

	local cooldown = _G[name .. "Cooldown"] or CreateFrame("Cooldown", name .. "Cooldown", button, "CooldownFrameTemplate")
	cooldown:SetParent(button)

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
		if PP and PP.SetBorderColor then
			PP.SetBorderColor(button, 0, 0, 0)
		end

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

		-- 同步取装备槽图标：首次加载时立即可用，规避 item:GetItemIcon() 在
		-- itemInfo 未完全缓存时返回 nil（图标发黑，需 reload 才恢复）的问题。
		local slotIcon = GetInventoryItemTexture("player", slotID)
		if slotIcon then
			button.tex:SetTexture(slotIcon)
		end

		waitGroup.count = waitGroup.count + 1
		async.WithItemSlotID(slotID, function(item)
			button.itemName = item:GetItemName()
			if not slotIcon then
				local icon = item:GetItemIcon()
				if icon then
					button.tex:SetTexture(icon)
				end
			end

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
	button:SetSize(barDB.buttonSize, barDB.buttonSize)
	SetIconTexCoords(button.tex, barDB.buttonSize, barDB.buttonSize)
end

function EB:SetEmptyButton(button)
	button.itemName = nil
	button.itemID = nil
	button.spellName = nil
	button.slotID = nil
	button.countText = nil
	button.questLogIndex = nil
	button:SetScript("OnUpdate", nil)
	button.tex:SetTexture(NORM_TEX)
	button.tex:SetVertexColor(0.06, 0.08, 0.10, 1)
	button.count:SetText()
	button.qualityTier:SetText("")
	button.qualityTier:Hide()
	if PP and PP.SetBorderColor then
		PP.SetBorderColor(button, 0, 0, 0)
	end
	if not InCombatLockdown() then
		button:SetAttribute("macrotext", nil)
		button:EnableMouse(false)
	end
	button:Show()
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
	EnsureBarDB(barDB)

	local existingBar = _G["WTExtraItemsBar" .. id]
	if existingBar and existingBar.buttons and existingBar.buttons[1] then
		self.bars[id] = existingBar
		return
	end

	local bar = existingBar or CreateFrame("Frame", "WTExtraItemsBar" .. id, E.UIParent, "SecureHandlerStateTemplate")
	bar.id = id
	bar:SetClampedToScreen(true)
	bar:SetFrameStrata("LOW")
	bar:SetFrameLevel(5)

	local bg = bar.bg or bar:CreateTexture(nil, "BACKGROUND")
	bg:SetTexture(NORM_TEX)
	bg:SetVertexColor(0, 0, 0, 0.5)
	bg:SetAllPoints()
	if bg.SetSnapToPixelGrid then
		bg:SetSnapToPixelGrid(false)
		bg:SetTexelSnappingBias(0)
	end
	bar.bg = bg
	bar.backdrop = bg

	bar.buttons = {}
	self.bars[id] = bar
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

function EB:GetItemRejectReason(itemID)
	if not itemID then
		return "no-item-id"
	end
	if self.db and self.db.blackList and self.db.blackList[itemID] then
		return "blacklisted"
	end
	if self.StateCheckList and self.StateCheckList[itemID] and not self:GetState(self.StateCheckList[itemID]) then
		return "state-disabled"
	end
	local count = C_Item_GetItemCount(itemID)
	local countThreshold = self.CountThreshold[itemID] or 1
	if not count or count < countThreshold then
		return "missing-or-below-threshold", count or 0, countThreshold
	end
	return nil, count, countThreshold
end

function EB:GetMatchDebug(id)
	local result = {
		bar = id,
		db = self.db ~= nil,
		enabled = self.db and self.db.enable,
		barEnabled = false,
		include = nil,
		questItems = #questItemList,
		equipmentSlots = #equipmentList,
		modules = {},
		passed = {},
		rejects = {},
		rejectSamples = {},
	}
	if not self.db then return result end
	local barDB = self.db["bar" .. (id or 1)]
	if not barDB then return result end
	result.barEnabled = barDB.enable
	result.include = barDB.include

	local function bumpReject(reason, moduleName, itemID, source, count, threshold)
		reason = reason or "unknown"
		result.rejects[reason] = (result.rejects[reason] or 0) + 1
		local samples = result.rejectSamples[reason]
		if not samples then
			samples = {}
			result.rejectSamples[reason] = samples
		end
		if #samples < 12 then
			samples[#samples + 1] = {
				module = moduleName,
				source = source,
				itemID = itemID,
				count = count or 0,
				countIncludingBank = itemID and C_Item_GetItemCount(itemID, true) or 0,
				threshold = threshold or 1,
			}
		end
	end
	local function checkItem(moduleName, itemID, source)
		local reason, count, threshold = self:GetItemRejectReason(itemID)
		local moduleEntry = result.modules[#result.modules]
		if reason then
			if moduleEntry then moduleEntry.rejected = (moduleEntry.rejected or 0) + 1 end
			bumpReject(reason, moduleName, itemID, source, count, threshold)
		else
			if moduleEntry then moduleEntry.passed = (moduleEntry.passed or 0) + 1 end
			result.passed[#result.passed + 1] = {
				module = moduleName,
				source = source,
				itemID = itemID,
				count = count,
				threshold = threshold,
			}
		end
	end

	for _, moduleName in ipairs({ strsplit("[, ]", barDB.include or "") }) do
		local entry = { name = moduleName, candidates = 0 }
		result.modules[#result.modules + 1] = entry
		if self.ModuleList and self.ModuleList[moduleName] then
			for _, itemID in pairs(self.ModuleList[moduleName]) do
				entry.candidates = entry.candidates + 1
				checkItem(moduleName, itemID, "module")
			end
		elseif moduleName == "QUEST" then
			for _, data in ipairs(questItemList) do
				entry.candidates = entry.candidates + 1
				checkItem(moduleName, data.itemID, "quest")
			end
		elseif moduleName == "EQUIP" then
			for _, slotID in pairs(equipmentList) do
				entry.candidates = entry.candidates + 1
				checkItem(moduleName, GetInventoryItemID("player", slotID), "slot:" .. slotID)
			end
		elseif strmatch(moduleName, "^SLOT:") then
			local slotFilter = strmatch(moduleName, "^SLOT:(.+)$")
			local allowedSlots = ParseSlotFilter(slotFilter)
			if allowedSlots then
				for _, slotID in pairs(equipmentList) do
					if allowedSlots[slotID] then
						entry.candidates = entry.candidates + 1
						checkItem(moduleName, GetInventoryItemID("player", slotID), "slot:" .. slotID)
					end
				end
			end
		elseif moduleName == "CUSTOM" then
			for _, itemID in pairs(self.db.customList or {}) do
				entry.candidates = entry.candidates + 1
				checkItem(moduleName, itemID, "custom")
			end
		else
			entry.unknown = true
		end
	end

	result.passedCount = #result.passed
	return result
end

function EB:GetMatchSummary(id)
	local debugState = self:GetMatchDebug(id)
	local summary = {
		bar = debugState.bar,
		enabled = debugState.enabled,
		barEnabled = debugState.barEnabled,
		include = debugState.include,
		questItems = debugState.questItems,
		equipmentSlots = debugState.equipmentSlots,
		passedCount = debugState.passedCount,
		rejects = debugState.rejects,
		modules = {},
		firstPassed = nil,
		firstRejects = {},
	}
	for i, moduleInfo in ipairs(debugState.modules or {}) do
		summary.modules[i] = {
			name = moduleInfo.name,
			candidates = moduleInfo.candidates,
			passed = moduleInfo.passed or 0,
			rejected = moduleInfo.rejected or 0,
			unknown = moduleInfo.unknown,
		}
	end
	if debugState.passed and debugState.passed[1] then
		summary.firstPassed = debugState.passed[1]
	end
	for reason, samples in pairs(debugState.rejectSamples or {}) do
		local short = {}
		for i = 1, math.min(#samples, 3) do
			short[i] = samples[i]
		end
		summary.firstRejects[reason] = short
	end
	return summary
end

function EB:GetAllMatchSummary()
	local result = {}
	for i = 1, 5 do
		result[i] = self:GetMatchSummary(i)
	end
	return result
end

function EB:UpdateBar(id)
	if not self.db or not self.db["bar" .. id] then
		return
	end

	local bar = self.bars[id]
	local barDB = self.db["bar" .. id]
	EnsureBarDB(barDB)
	if not bar then
		return
	end

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
		for i = 1, 12 do
			if bar.buttons and bar.buttons[i] then
				bar.buttons[i]:Hide()
			end
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

	local populatedButtons = buttonID - 1
	local displayButtons = populatedButtons > 0 and populatedButtons or (barDB.numButtons or 1)
	if displayButtons > 12 then displayButtons = 12 end
	local numRows = ceil(displayButtons / barDB.buttonsPerRow)
	local numCols = displayButtons > barDB.buttonsPerRow and barDB.buttonsPerRow or displayButtons
	local newBarWidth = 2 * barDB.backdropSpacing + numCols * barDB.buttonSize + (numCols - 1) * barDB.spacing
	local newBarHeight = 2 * barDB.backdropSpacing + numRows * barDB.buttonSize + (numRows - 1) * barDB.spacing
	bar:SetSize(newBarWidth, newBarHeight)

	if displayButtons < 12 then
		for hideButtonID = displayButtons + 1, 12 do
			bar.buttons[hideButtonID]:Hide()
		end
	end

	for i = 1, displayButtons do
		local anchor = barDB.anchor
		local button = bar.buttons[i]
		if i > populatedButtons then
			self:SetEmptyButton(button)
		end

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

	local visibility = NormalizeVisibility(barDB.visibility)
	if bar.registeredVisibility ~= visibility and bar.register then
		UnregisterStateDriver(bar, "visibility")
		bar.register = false
		bar.registeredVisibility = nil
	end

	if not bar.register then
		RegisterStateDriver(bar, "visibility", visibility)
		bar.register = true
		bar.registeredVisibility = visibility
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
	if not self.bars then
		return
	end
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
	self.createErrors = {}

	for i = 1, 5 do
		local ok, err = pcall(self.CreateBar, self, i)
		if not ok then
			self.createErrors[i] = err
		end
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
				if not point or x == nil or y == nil then
					return
				end
				-- EllesmereUI 的 SaveBarPosition 会先把坐标转成 CENTER/CENTER
				-- （bar 中心相对 UIParent CENTER 的偏移，UIParent scale 下）。这里
				-- 再转成 BOTTOMLEFT（bar 左下角相对 UIParent 左下角），让 SetSize
				-- 时 bar 左下角固定、向右上增长，而非从中心向四周扩展。
				local bar = EB.bars[id]
				local uiS = UIParent:GetEffectiveScale()
				local bS = bar and bar:GetEffectiveScale() or uiS
				local ratio = bS / uiS
				local w = (bar and bar:GetWidth() or 0) * ratio
				local h = (bar and bar:GetHeight() or 0) * ratio
				local uiW = UIParent:GetWidth()
				local uiH = UIParent:GetHeight()
				local blX = uiW / 2 + x - w / 2
				local blY = uiH / 2 + y - h / 2
				E.global.WT.item.extraItemsBar["bar" .. id].position = {
					point = "BOTTOMLEFT",
					relPoint = "BOTTOMLEFT",
					x = blX,
					y = blY,
				}
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
				if pos and pos.point == "BOTTOMLEFT" and pos.x and pos.y then
					bar:SetPoint("BOTTOMLEFT", E.UIParent, "BOTTOMLEFT", pos.x, pos.y)
				else
					E.global.WT.item.extraItemsBar["bar" .. id].position = nil
					SetDefaultBarPosition(bar, id)
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

function EB:GetDebugState()
	local state = {
		db = self.db ~= nil,
		dbEnable = self.db and self.db.enable,
		initialized = self.initialized,
		barsTable = self.bars ~= nil,
		bars = {},
	}
	for i = 1, 5 do
		local bar = self.bars and self.bars[i]
		local gbar = _G["WTExtraItemsBar" .. i]
		local frame = bar or gbar
		local bd = self.db and self.db["bar" .. i]
		state.bars[i] = {
			db = bd ~= nil,
			enable = bd and bd.enable,
			createError = self.createErrors and self.createErrors[i] or nil,
			include = bd and bd.include,
			numButtons = bd and bd.numButtons,
			buttonsPerRow = bd and bd.buttonsPerRow,
			buttonSize = bd and bd.buttonSize,
			backdropSpacing = bd and bd.backdropSpacing,
			spacing = bd and bd.spacing,
			anchor = bd and bd.anchor,
			visibility = bd and bd.visibility,
			moduleFrame = bar ~= nil,
			globalFrame = gbar ~= nil,
			shown = frame and frame:IsShown() or false,
			alpha = frame and frame:GetAlpha() or nil,
			width = frame and frame:GetWidth() or nil,
			height = frame and frame:GetHeight() or nil,
			point = frame and frame:GetPoint(1) or nil,
		}
		if frame and frame.buttons then
			local visibleButtons = 0
			for j = 1, 12 do
				local button = frame.buttons[j]
				if button and button:IsShown() then
					visibleButtons = visibleButtons + 1
				end
			end
			state.bars[i].visibleButtons = visibleButtons
		end
	end
	return state
end

function EB:Initialize()
	self.db = E.db.WT.item.extraItemsBar
	if not self.db or not self.db.enable or self.initialized then
		return
	end

	self:CreateAll()
	for i = 1, 5 do
		self:RegisterMover(i)
		self:ApplyDefaultPosition(i)
	end

	UpdateQuestItemList()
	UpdateEquipmentList()
	self:UpdateState(EB.STATE.QUANTUM_ITEM_ALLOWED)
	self:UpdateBars()
	self:UpdateBinding()

	self.initialized = true

	SafeRegisterEvent(self, "BAG_UPDATE_DELAYED", "UpdateBars")
	SafeRegisterEvent(self, "ITEM_LOCKED")
	SafeRegisterEvent(self, "PLAYER_ALIVE", "UpdateBars")
	SafeRegisterEvent(self, "PLAYER_EQUIPMENT_CHANGED", "UpdateEquipmentItem")
	SafeRegisterEvent(self, "PLAYER_UNGHOST", "UpdateBars")
	SafeRegisterEvent(self, "QUEST_ACCEPTED", "UpdateQuestItem")
	SafeRegisterEvent(self, "QUEST_LOG_UPDATE", "UpdateQuestItem")
	SafeRegisterEvent(self, "QUEST_TURNED_IN", "UpdateQuestItem")
	SafeRegisterEvent(self, "QUEST_WATCH_LIST_CHANGED", "UpdateQuestItem")
	SafeRegisterEvent(self, "UNIT_INVENTORY_CHANGED")
	SafeRegisterEvent(self, "UPDATE_BINDINGS", "UpdateBinding")
	SafeRegisterEvent(self, "ZONE_CHANGED", "UpdateBars")
	SafeRegisterEvent(self, "ZONE_CHANGED_NEW_AREA", "UpdateBars")
end

function EB:ApplyDefaultPosition(id)
	local bar = self.bars[id]
	if not bar then return end

	local pos = E.global.WT.item.extraItemsBar["bar" .. id].position
	bar:ClearAllPoints()
	if pos and pos.point == "BOTTOMLEFT" and pos.x and pos.y then
		bar:SetPoint("BOTTOMLEFT", E.UIParent, "BOTTOMLEFT", pos.x, pos.y)
	else
		-- 旧存档（CENTER 等）的 x/y 与 BOTTOMLEFT 不兼容，清除并重置默认。
		E.global.WT.item.extraItemsBar["bar" .. id].position = nil
		SetDefaultBarPosition(bar, id)
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
