local W, F, E, L = unpack((select(2, ...))) ---@type WindTools, Functions, ElvUI, LocaleTable
local CB = W:NewModule("ChatBar") ---@class ChatBar : AceModule, AceHook-3.0, AceEvent-3.0
local LSM = E.Libs.LSM
local C = W.Utilities.Color

-- EllesmereUI native APIs (no ElvUI dependencies)
local EUI = _G.EllesmereUI
local PP = EUI and EUI.PP

local _G = _G
local format = format
local ipairs = ipairs
local pairs = pairs
local select = select
local sort = sort
local strmatch = strmatch
local tinsert = tinsert
local tostring = tostring

local C_Club_GetClubInfo = C_Club.GetClubInfo
local C_GuildInfo_IsGuildOfficer = C_GuildInfo.IsGuildOfficer
local ChatFrameUtil_OpenChat = ChatFrameUtil.OpenChat
local CreateFrame = CreateFrame
local DefaultChatFrame = _G.DEFAULT_CHAT_FRAME
local GetChannelList = GetChannelList
local GetChannelName = GetChannelName
local InCombatLockdown = InCombatLockdown
local IsEveryoneAssistant = IsEveryoneAssistant
local IsInGroup = IsInGroup
local IsInGuild = IsInGuild
local IsInRaid = IsInRaid
local JoinPermanentChannel = JoinPermanentChannel
local LeaveChannelByName = LeaveChannelByName
local RandomRoll = RandomRoll
local securecallfunction = securecallfunction
local UnitFactionGroup = UnitFactionGroup
local UnitIsGroupAssistant = UnitIsGroupAssistant
local UnitIsGroupLeader = UnitIsGroupLeader

local LE_PARTY_CATEGORY_HOME = LE_PARTY_CATEGORY_HOME
local LE_PARTY_CATEGORY_INSTANCE = LE_PARTY_CATEGORY_INSTANCE

local BUTTON_HOVER_FONT_SIZE_INCREASE = 4
local MOUSE_OVER_HEIGHT_PADDING = 6
local NORMAL_CHANNELS = { "SAY", "YELL", "PARTY", "INSTANCE", "RAID", "RAID_WARNING", "GUILD", "OFFICER", "EMOTE" }

-- Fallback texture path (ElvUI's normTex is not available in CompatE)
local NORM_TEX = "Interface\\Buttons\\WHITE8x8"

---Apply font from DB to a FontString, EllesmereUI-native way.
---Resolves "__global" via EllesmereUI.GetFontPath and uses EllesmereUI's
---outline flag system (none/outline/thick -> WoW font flags).
---@param fontString FontString The FontString to style
---@param db table Font DB: { name = "__global"|fontName, size = number, style = "none"|"outline"|"thick" }
local function ApplyFont(fontString, db)
	if not fontString or not db then
		return
	end
	local path
	if db.name == "__global" or not db.name then
		path = EUI and EUI.GetFontPath and EUI.GetFontPath("WindTools")
				or (LSM and LSM:Fetch("font", "Expressway"))
				or "Fonts\\FRIZQT__.TTF"
	else
		path = (LSM and LSM:Fetch("font", db.name)) or db.name
	end
	local flag = ""
	if db.style == "outline" then
		flag = EUI and EUI.GetFontOutlineFlag and EUI.GetFontOutlineFlag("WindTools") or "OUTLINE"
	elseif db.style == "thick" then
		flag = "THICKOUTLINE"
	end
	fontString:SetFont(path, db.size or 12, flag)
end

local checkFunctions = {
	PARTY = function()
		return IsInGroup(LE_PARTY_CATEGORY_HOME)
	end,
	INSTANCE = function()
		return IsInGroup(LE_PARTY_CATEGORY_INSTANCE)
	end,
	RAID = function()
		return IsInRaid()
	end,
	RAID_WARNING = function()
		return IsInRaid() and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") or IsEveryoneAssistant())
	end,
	GUILD = function()
		return IsInGuild()
	end,
	OFFICER = function()
		return IsInGuild() and C_GuildInfo_IsGuildOfficer()
	end,
}

---Get community channel ID by channel name
---@param text string The community channel name to search for
---@return number? channelId The channel ID if found
local function GetCommunityChannelByName(text)
	local channelList = { GetChannelList() }
	for _, v in pairs(channelList) do
		local clubId = strmatch(tostring(v), "Community:(.-):")
		if clubId then
			local info = C_Club_GetClubInfo(clubId)
			if info and info.name == text then
				return select(1, GetChannelName(tostring(v)))
			end
		end
	end
end

---Calculate the next button position offset
---@param anchor string The anchor direction ("LEFT" or "TOP")
---@param offsetX number Current X offset
---@param offsetY number Current Y offset
---@param buttonWidth number Width of the button
---@param buttonHeight number Height of the button
---@param spacing number Spacing between buttons
---@return number newOffsetX The new X offset
---@return number newOffsetY The new Y offset
local function CalculateNextOffset(anchor, offsetX, offsetY, buttonWidth, buttonHeight, spacing)
	if anchor == "LEFT" then
		return offsetX + buttonWidth + spacing, offsetY
	else
		return offsetX, offsetY - buttonHeight - spacing
	end
end

---Calculate the total size of the chat bar
---@param orientation string Bar orientation ("HORIZONTAL" or "VERTICAL")
---@param numberOfButtons number Total number of buttons
---@param spacing number Spacing between buttons
---@param buttonWidth number Width of each button
---@param buttonHeight number Height of each button
---@param hasBackdrop boolean Whether the bar has a backdrop
---@param backdropSpacing number Spacing for the backdrop
---@return number width The calculated bar width
---@return number height The calculated bar height
local function CalculateBarSize(
	orientation,
	numberOfButtons,
	spacing,
	buttonWidth,
	buttonHeight,
	hasBackdrop,
	backdropSpacing
)
	local width, height

	if hasBackdrop then
		if orientation == "HORIZONTAL" then
			width = backdropSpacing * 2 + buttonWidth * numberOfButtons + spacing * (numberOfButtons - 1)
			height = backdropSpacing * 2 + buttonHeight
		else
			width = backdropSpacing * 2 + buttonWidth
			height = backdropSpacing * 2 + buttonHeight * numberOfButtons + spacing * (numberOfButtons - 1)
		end
	else
		if orientation == "HORIZONTAL" then
			width = buttonWidth * numberOfButtons + spacing * (numberOfButtons - 1)
			height = buttonHeight
		else
			width = buttonWidth
			height = buttonHeight * numberOfButtons + spacing * (numberOfButtons - 1)
		end
	end

	return width, height
end

---Get the initial offset for button positioning
---@param hasBackdrop boolean Whether the bar has a backdrop
---@param backdropSpacing number Spacing for the backdrop
---@param anchor string The anchor direction ("LEFT" or "TOP")
---@return number offsetX The initial X offset
---@return number offsetY The initial Y offset
local function GetInitialOffset(hasBackdrop, backdropSpacing, anchor)
	local offsetX, offsetY = 0, 0

	if hasBackdrop then
		if anchor == "LEFT" then
			offsetX = offsetX + backdropSpacing
		else
			offsetY = offsetY - backdropSpacing
		end
	end

	return offsetX, offsetY
end

---Find the best matching world channel configuration
---@param configTable table Array of channel configurations
---@return table? config The best matching configuration or nil
local function GetBestWorldChannelConfig(configTable)
	local validConfigs = {}
	local myFaction = UnitFactionGroup("player")

	for _, c in pairs(configTable) do
		if
			(c.region == "ALL" or c.region == W.RealRegion)
			and (c.faction == "ALL" or c.faction == myFaction)
			and (c.realmID == "ALL" or c.realmID == W.CurrentRealmID)
		then
			tinsert(validConfigs, c)
		end
	end

	sort(validConfigs, function(a, b)
		if a.region ~= "ALL" and b.region == "ALL" then
			return true
		end

		if a.region == "ALL" and b.region ~= "ALL" then
			return false
		end

		if a.faction ~= "ALL" and b.faction == "ALL" then
			return true
		end

		if a.faction == "ALL" and b.faction ~= "ALL" then
			return false
		end

		if a.realmID == "ALL" and b.realmID ~= "ALL" then
			return true
		end

		return false
	end)

	return validConfigs[1]
end

---Apply a transparent black backdrop + 1px border to a frame, EllesmereUI style.
---@param frame Frame The frame to style
local function ApplyBackdrop(frame, createBorder)
	if not PP then
		return
	end
	-- Semi-transparent black background texture
	local bg = frame.bg or frame:CreateTexture(nil, "BACKGROUND")
	bg:SetTexture(NORM_TEX)
	bg:SetVertexColor(0, 0, 0, 0.5)
	bg:SetAllPoints()
	if bg.SetSnapToPixelGrid then
		bg:SetSnapToPixelGrid(false)
		bg:SetTexelSnappingBias(0)
	end
	frame.bg = bg
	-- 1px border via EllesmereUI PP system. Buttons defer border creation to
	-- BLOCK style only (see UpdateButton), so TEXT mode never has a border
	-- object at all instead of relying on hiding one after the fact.
	if createBorder ~= false then
		PP.CreateBorder(frame, 0, 0, 0, 1, 1, "BORDER", 0)
	end
end

---Set border color on a frame styled with ApplyBackdrop.
---@param frame Frame The frame
---@param r number Red
---@param g number Green
---@param b number Blue
---@param a number? Alpha (default 1)
local function SetBorderColor(frame, r, g, b, a)
	if PP and PP.SetBorderColor then
		PP.SetBorderColor(frame, r, g, b, a or 1)
	end
end

function CB:OnEnterBar()
	if self.db.mouseOver then
		E:UIFrameFadeIn(self.bar, 0.2, self.bar:GetAlpha(), 1)
	end
end

function CB:OnLeaveBar()
	if self.db.mouseOver then
		E:UIFrameFadeOut(self.bar, 0.2, self.bar:GetAlpha(), 0)
	end
end

---Update or create a chat button
---@param name string The button name/identifier
---@param func function The click handler function
---@param anchorPoint string The anchor point for positioning
---@param x number X position offset
---@param y number Y position offset
---@param color RGBA? Color configuration for the button
---@param tex string? Texture name for block style
---@param tooltip string? Tooltip text
---@param tips table? Array of tooltip tips
---@param abbr string Button abbreviation or icon
---@return Button button The created or updated button
function CB:UpdateButton(name, func, anchorPoint, x, y, color, tex, tooltip, tips, abbr)
	local valueColor = E.media.rgbvaluecolor

	if not self.bar[name] then
		local button = CreateFrame("Button", nil, self.bar, "SecureActionButtonTemplate, BackdropTemplate") --[[@as Button]]
		button:RegisterForClicks("AnyDown")
		button:SetScript("OnMouseUp", func)

		button.colorBlock = button:CreateTexture(nil, "ARTWORK")
		button.colorBlock:SetAllPoints()
		ApplyBackdrop(button, false)

		button.text = button:CreateFontString(nil, "OVERLAY")
		button.text:SetPoint("CENTER", button, "CENTER", 0, 0)
		ApplyFont(button.text, self.db.font)
		button.defaultFontSize = self.db.font.size

		-- Tooltip
		button:SetScript("OnEnter", function(btn)
			if CB.db.style == "BLOCK" then
				-- Highlight border with value color (replaces ElvUI shadow highlight)
				SetBorderColor(btn, valueColor.r, valueColor.g, valueColor.b, 1)
			else
				local fontName, _, fontFlags = btn.text:GetFont()
				btn.text:SetFont(fontName, btn.defaultFontSize + BUTTON_HOVER_FONT_SIZE_INCREASE, fontFlags)
			end

			_G.GameTooltip:SetOwner(btn, "ANCHOR_TOP", 0, 7)
			_G.GameTooltip:SetText(button.tooltip or _G[name] or "")

			if tips then
				for _, tip in ipairs(button.tips) do
					_G.GameTooltip:AddLine(tip)
				end
			end

			_G.GameTooltip:Show()
		end)

		button:SetScript("OnLeave", function(btn)
			_G.GameTooltip:Hide()
			if CB.db.style == "BLOCK" then
				-- Reset border to black
				SetBorderColor(btn, 0, 0, 0, 1)
			else
				local fontName, _, fontFlags = btn.text:GetFont()
				btn.text:SetFont(fontName, btn.defaultFontSize, fontFlags)
			end
		end)

		-- Hook OnEnter/OnLeave for bar fade (Blizzard native HookScript;
		-- WindTools' AddCommonMethods does not provide an AceHook-style
		-- module:HookScript(frame, script, handler) wrapper).
		button:HookScript("OnEnter", function()
			CB:OnEnterBar()
		end)
		button:HookScript("OnLeave", function()
			CB:OnLeaveBar()
		end)

		self.bar[name] = button
	end

	self.bar[name].tooltip = tooltip
	self.bar[name].tips = tips

	-- Block style
	if self.db.style == "BLOCK" then
		self.bar[name].colorBlock:SetTexture(tex and LSM:Fetch("statusbar", tex) or NORM_TEX)

		if color then
			self.bar[name].colorBlock:SetVertexColor(color.r, color.g, color.b, color.a)
		end

		self.bar[name].colorBlock:Show()
		self.bar[name].bg:Show()
		if PP then
			if PP.GetBorders and not PP.GetBorders(self.bar[name]) and PP.CreateBorder then
				PP.CreateBorder(self.bar[name], 0, 0, 0, 1, 1, "BORDER", 0)
			end
			if PP.ShowBorder then
				PP.ShowBorder(self.bar[name])
			end
		end
		self.bar[name].text:Hide()
	else
		local buttonText = self.db.color and color and C.StringWithRGB(abbr, color) or abbr
		self.bar[name].text:SetText(buttonText)
		self.bar[name].defaultFontSize = self.db.font.size
		ApplyFont(self.bar[name].text, self.db.font)
		self.bar[name].text:Show()

		self.bar[name].colorBlock:Hide()
		self.bar[name].bg:Hide()
		if PP and PP.HideBorder then
			PP.HideBorder(self.bar[name])
		end
	end

	-- Update size and position (EllesmereUI PP for pixel-perfect scaling)
	if PP then
		PP.Size(self.bar[name], CB.db.buttonWidth, CB.db.buttonHeight)
		self.bar[name]:ClearAllPoints()
		PP.Point(self.bar[name], anchorPoint, CB.bar, anchorPoint, x, y)
	else
		self.bar[name]:SetSize(CB.db.buttonWidth, CB.db.buttonHeight)
		self.bar[name]:ClearAllPoints()
		self.bar[name]:SetPoint(anchorPoint, CB.bar, anchorPoint, x, y)
	end

	self.bar[name]:Show()
	return self.bar[name]
end

---Hide/disable a chat button
---@param name string The button name to disable
function CB:DisableButton(name)
	if self.bar[name] then
		self.bar[name]:Hide()
	end
end

---Get the world channel ID based on user configuration
---@return number channelID The world channel ID, or 0 if not found
function CB:GetWorldChannelID()
	if not self.db.enable or not self.db.channels.world.enable then
		return 0
	end

	local db = self.db.channels.world
	local config = GetBestWorldChannelConfig(db.config)

	if not config or not config.name or config.name == "" then
		return 0
	end

	local channelID = GetChannelName(config.name)

	return channelID
end

function CB:UpdateBar()
	-- Honor the enable flag: this is the single refresh entry used by the
	-- options panel (afterCB), so toggling Enable must show/hide the bar live.
	if not self.db.enable then
		if self.bar then
			self.bar:Hide()
		end
		return
	end

	-- Lazily create the bar if it does not exist yet (e.g. user just flipped
	-- Enable on from the options panel; Initialize() may not have run).
	if not self.bar then
		CB:CreateBar()
		CB:RegisterMover()
		if self.db.autoHide then
			self:RegisterEvent("GROUP_ROSTER_UPDATE", "UpdateBar")
			self:RegisterEvent("PLAYER_GUILD_UPDATE", "UpdateBar")
		end
	end

	if InCombatLockdown() then
		F.TaskManager:AfterCombat(self.UpdateBar, self)
		return
	end

	self.bar:Show()

	local numberOfButtons = 0
	local orientation, hasBackdrop, backdropSpacing = self.db.orientation, self.db.backdrop, self.db.backdropSpacing
	local buttonWidth, buttonHeight, spacing = self.db.buttonWidth, self.db.buttonHeight, self.db.spacing
	local anchor = self.db.orientation == "HORIZONTAL" and "LEFT" or "TOP"
	local offsetX, offsetY = GetInitialOffset(hasBackdrop, backdropSpacing, anchor)

	for _, name in ipairs(NORMAL_CHANNELS) do
		local db = self.db.channels[name]
		local show = db and db.enable

		if show and self.db.autoHide then
			if checkFunctions[name] then
				show = checkFunctions[name]() and true or false
			end
		end

		if show then
			local chatFunc = function(_, mouseButton)
				if mouseButton ~= "LeftButton" or not db.cmd then
					return
				end
				local currentText = DefaultChatFrame.editBox:GetText()
				local command = format("/%s ", db.cmd)
				ChatFrameUtil_OpenChat(command .. currentText, DefaultChatFrame)
			end

			self:UpdateButton(name, chatFunc, anchor, offsetX, offsetY, db.color, self.db.tex, nil, nil, db.abbr)
			numberOfButtons = numberOfButtons + 1
			offsetX, offsetY = CalculateNextOffset(anchor, offsetX, offsetY, buttonWidth, buttonHeight, spacing)
		else
			self:DisableButton(name)
		end
	end

	if self.db.channels.world.enable then
		local db = self.db.channels.world
		local config = GetBestWorldChannelConfig(db.config)

		if not config or not config.name or config.name == "" then
			F.Print(L["World channel no found, please setup again."])
			self:DisableButton("WORLD")
		else
			local chatFunc = function(_, mouseButton)
				local channelID = GetChannelName(config.name)
				if mouseButton == "LeftButton" then
					local autoJoined = false
					if channelID == 0 and config.autoJoin then
						securecallfunction(JoinPermanentChannel, config.name)
						securecallfunction(DefaultChatFrame.AddChannel, DefaultChatFrame, config.name)
						channelID = GetChannelName(config.name)
						autoJoined = true
					end
					if channelID == 0 then
						return
					end
					local currentText = DefaultChatFrame.editBox:GetText()
					local command = format("/%s ", channelID)
					if autoJoined then
						-- If the channel is just joined, delay a bit to let the server process it
						E:Delay(0.5, ChatFrameUtil_OpenChat, command .. currentText, DefaultChatFrame)
					else
						ChatFrameUtil_OpenChat(command .. currentText, DefaultChatFrame)
					end
				elseif mouseButton == "RightButton" then
					if channelID == 0 then
						securecallfunction(JoinPermanentChannel, config.name)
						securecallfunction(DefaultChatFrame.AddChannel, DefaultChatFrame, config.name)
					else
						securecallfunction(LeaveChannelByName, config.name)
					end
				end
			end

			self:UpdateButton("WORLD", chatFunc, anchor, offsetX, offsetY, db.color, self.db.tex, config.name, {
				L["Left Click: Change to"] .. " " .. config.name,
				L["Right Click: Join/Leave"] .. " " .. config.name,
			}, db.abbr)

			numberOfButtons = numberOfButtons + 1
			offsetX, offsetY = CalculateNextOffset(anchor, offsetX, offsetY, buttonWidth, buttonHeight, spacing)
		end
	else
		self:DisableButton("WORLD")
	end

	if self.db.channels.community.enable then
		local db = self.db.channels.community
		local name = db.name
		if not name or name == "" then
			F.Print(L["Club channel no found, please setup again."])
			self:DisableButton("CLUB")
		else
			local chatFunc = function(_, mouseButton)
				if mouseButton ~= "LeftButton" then
					return
				end
				local clubChannelId = GetCommunityChannelByName(name)
				if not clubChannelId then
					F.Print(format(L["Club channel %s no found, please use the full name of the channel."], name))
				else
					local currentText = DefaultChatFrame.editBox:GetText()
					local command = format("/%s ", clubChannelId)
					ChatFrameUtil_OpenChat(command .. currentText, DefaultChatFrame)
				end
			end

			self:UpdateButton("CLUB", chatFunc, anchor, offsetX, offsetY, db.color, self.db.tex, name, nil, db.abbr)

			numberOfButtons = numberOfButtons + 1
			offsetX, offsetY = CalculateNextOffset(anchor, offsetX, offsetY, buttonWidth, buttonHeight, spacing)
		end
	else
		self:DisableButton("CLUB")
	end

	if self.db.channels.emote.enable and E.db.WT.social.emote.enable then
		local db = self.db.channels.emote

		local chatFunc = function(_, mouseButton)
			if mouseButton == "LeftButton" then
				if _G.WTCustomEmoteFrame then
					if _G.WTCustomEmoteFrame:IsShown() then
						_G.WTCustomEmoteFrame:Hide()
					else
						_G.WTCustomEmoteFrame:Show()
					end
				else
					F.Print(L["Please enable Emote module in WindTools Social category."])
				end
			end
		end

		local abbr = db.icon
				and ("|TInterface\\AddOns\\EllesmereUI_WindTools\\Media\\Emotes\\mario:" .. self.db.font.size .. "|t")
			or db.abbr
		self:UpdateButton(
			"WindEmote",
			chatFunc,
			anchor,
			offsetX,
			offsetY,
			db.color,
			self.db.tex,
			"Wind " .. L["Emote"],
			{ L["Left Click: Toggle"] },
			abbr
		)
		numberOfButtons = numberOfButtons + 1
		offsetX, offsetY =
			CalculateNextOffset(anchor, offsetX, offsetY, self.db.buttonWidth, self.db.buttonHeight, self.db.spacing)
	else
		self:DisableButton("WindEmote")
	end

	if self.db.channels.roll.enable then
		local db = self.db.channels.roll

		local chatFunc = function(_, mouseButton)
			if mouseButton == "LeftButton" then
				RandomRoll(1, 100)
			end
		end

		local abbr = (db.icon and "|TInterface\\Buttons\\UI-GroupLoot-Dice-Up:" .. self.db.font.size .. "|t") or db.abbr

		self:UpdateButton("ROLL", chatFunc, anchor, offsetX, offsetY, db.color, self.db.tex, nil, nil, abbr)

		numberOfButtons = numberOfButtons + 1
		offsetX, offsetY =
			CalculateNextOffset(anchor, offsetX, offsetY, self.db.buttonWidth, self.db.buttonHeight, self.db.spacing)
	else
		self:DisableButton("ROLL")
	end

	-- Update the size of the bar
	local width, height =
		CalculateBarSize(orientation, numberOfButtons, spacing, buttonWidth, buttonHeight, hasBackdrop, backdropSpacing)

	if self.db.mouseOver then
		self.bar:SetAlpha(0)
		if not self.db.backdrop then
			height = height + MOUSE_OVER_HEIGHT_PADDING
		end
	else
		self.bar:SetAlpha(1)
	end

	if PP then
		PP.Size(self.bar, width, height)
	else
		self.bar:SetSize(width, height)
	end

	if self.db.backdrop then
		self.bar.bg:Show()
		if PP and PP.ShowBorder then
			PP.ShowBorder(self.bar)
		end
	else
		self.bar.bg:Hide()
		if PP and PP.HideBorder then
			PP.HideBorder(self.bar)
		end
	end
end

CB.UpdateBar = F.ThrottleFunction(0.1, CB.UpdateBar)

function CB:CreateBar()
	if self.bar then
		return
	end

	local bar = CreateFrame("Frame", "WTChatBar", E.UIParent, "SecureHandlerStateTemplate")

	bar:SetResizable(false)
	bar:SetClampedToScreen(true)
	bar:SetFrameStrata("LOW")
	bar:SetFrameLevel(5) -- Higher than ElvUI Exp Bar
	ApplyBackdrop(bar)
	bar:ClearAllPoints()

	self.bar = bar

	-- Blizzard native HookScript (see UpdateButton for rationale).
	bar:HookScript("OnEnter", function()
		CB:OnEnterBar()
	end)
	bar:HookScript("OnLeave", function()
		CB:OnLeaveBar()
	end)

	self:ApplyDefaultPosition()
end

---Resolve a sensible default anchor frame: the EllesmereUI chat background if
---available, otherwise UIParent. Returns (frame, point, relPoint, x, y).
---Never returns nil for the frame — always falls back to UIParent so SetPoint
---cannot fail with a nil anchor (which would silently break the whole module
---inside SafeCall).
local function ResolveDefaultAnchor()
	local chatFrame = _G.ChatFrame1
	-- Prefer EllesmereUIChat's unified background panel when it is actually
	-- driving the chat (it spans chat + edit box as one panel). We MUST verify
	-- the panel is live, because a third-party chat addon (e.g. Chattynator)
	-- can leave a stale/hidden bg around whose SetAllPoints no longer reflects
	-- the real chat area.
	if chatFrame and EUI and EUI._chatCFD then
		local ok, data = pcall(EUI._chatCFD, chatFrame)
		if ok and data and data.bg then
			local bg = data.bg
			local live = bg.IsShown and bg:IsShown() and bg.GetWidth and bg:GetWidth() > 0
			if live then
				-- bar.BOTTOMLEFT on bg.TOPLEFT => bar sits just above the panel.
				return bg, "TOPLEFT", "TOPLEFT", 6, 30
			end
		end
	end
	-- ChatFrame1 is the Blizzard chat frame every chat addon is built on, so it
	-- is the most reliable anchor when EllesmereUIChat's panel is absent or
	-- stale (e.g. Chattynator active).
	if chatFrame and chatFrame.GetWidth and chatFrame:GetWidth() > 0 then
		return chatFrame, "TOPLEFT", "TOPLEFT", 6, 30
	end
	-- Last-resort fallback.
	return _G.UIParent, "BOTTOMLEFT", "BOTTOMLEFT", 6, 180
end

---Apply the saved mover position, or the default anchor if none.
function CB:ApplyDefaultPosition()
	if not self.bar then
		return
	end
	local pos = E.global.WT and E.global.WT.social and E.global.WT.social.chatBar
		and E.global.WT.social.chatBar.position
	self.bar:ClearAllPoints()
	if pos and pos.point and pos.x and pos.y then
		self.bar:SetPoint(pos.point, _G.UIParent, pos.relPoint or pos.point, pos.x, pos.y)
	else
		-- Default: above the chat panel (or UIParent fallback)
		local anchorFrame, point, relPoint, x, y = ResolveDefaultAnchor()
		self.bar:SetPoint(point, anchorFrame, relPoint, x, y)
	end
end

---Register the chat bar with EllesmereUI's Unlock Mode so it can be dragged
---and positioned alongside all other EllesmereUI layout elements.
function CB:RegisterMover()
	if not EUI or not EUI.RegisterUnlockElements or not EUI.MakeUnlockElement then
		return
	end

	local MK = EUI.MakeUnlockElement
	local key = "WTChatBar"

	local elements = {
		MK({
			key = key,
			label = L["Chat Bar"],
			group = "WindTools",
			order = 900,
			getFrame = function()
				return CB.bar
			end,
			getSize = function()
				if not CB.bar then
					return 1, 1
				end
				return CB.bar:GetWidth(), CB.bar:GetHeight()
			end,
			savePos = function(_, point, relPoint, x, y)
				if point and x and y then
					E.global.WT.social.chatBar.position = {
						point = point,
						relPoint = relPoint or point,
						x = x,
						y = y,
					}
				end
			end,
			loadPos = function()
				local pos = E.global.WT and E.global.WT.social and E.global.WT.social.chatBar
					and E.global.WT.social.chatBar.position
				if not pos then
					return nil
				end
				return {
					point = pos.point,
					relPoint = pos.relPoint or pos.point,
					x = pos.x,
					y = pos.y,
				}
			end,
			clearPos = function()
				E.global.WT.social.chatBar.position = nil
			end,
			applyPos = function()
				CB:ApplyDefaultPosition()
			end,
			isHidden = function()
				return not (CB.db and CB.db.enable)
			end,
		}),
	}

	EUI:RegisterUnlockElements(elements, "EllesmereUI_WindTools")
end

function CB:Initialize()
	self.db = E.db.WT.social.chatBar
	if not self.db.enable then
		return
	end

	CB:CreateBar()
	CB:UpdateBar()
	CB:RegisterMover()

	if self.db.autoHide then
		self:RegisterEvent("GROUP_ROSTER_UPDATE", "UpdateBar")
		self:RegisterEvent("PLAYER_GUILD_UPDATE", "UpdateBar")
	end
end

function CB:ProfileUpdate()
	self.db = E.db.WT.social.chatBar

	if not self.db.enable then
		if self.bar then
			self.bar:Hide()
		end
		return
	end

	if self.db.enable and not self.bar then
		self:Initialize()
	end

	self.bar:Show()

	if self.db.autoHide then
		self:RegisterEvent("GROUP_ROSTER_UPDATE", "UpdateBar")
		self:RegisterEvent("PLAYER_GUILD_UPDATE", "UpdateBar")
	else
		self:UnregisterEvent("GROUP_ROSTER_UPDATE")
		self:UnregisterEvent("PLAYER_GUILD_UPDATE")
	end
end

W:RegisterModule(CB:GetName())
