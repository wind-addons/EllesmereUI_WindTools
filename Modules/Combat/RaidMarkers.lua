local W, F, E, L = unpack((select(2, ...))) ---@type WindTools, Functions, ElvUI, LocaleTable
local RM = W:NewModule("RaidMarkers", "AceEvent-3.0")
local EUI = _G.EllesmereUI

local _G = _G
local GameTooltip = _G.GameTooltip

local abs = abs
local format = format
local gsub = gsub
local strupper = strupper
local strlower = strlower

local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown
local RegisterStateDriver = RegisterStateDriver
local UnregisterStateDriver = UnregisterStateDriver

local C_AddOns_IsAddOnLoaded = C_AddOns.IsAddOnLoaded

local function SetSize(frame, width, height)
	frame:SetSize(width, height or width)
end

local function SetPoint(frame, ...)
	frame:SetPoint(...)
end

-- Backdrops are BACKGROUND-layer textures (not child frames) so that button
-- icons layered at ARTWORK stay visible above them.
local function CreateBackdrop(frame)
	local bg = frame:CreateTexture(nil, "BACKGROUND")
	bg:SetColorTexture(0.04, 0.05, 0.06, 0.92)
	bg:SetAllPoints()
	frame.backdrop = bg
	return bg
end

local TargetToWorld = {
	[1] = 5,
	[2] = 6,
	[3] = 3,
	[4] = 2,
	[5] = 7,
	[6] = 1,
	[7] = 4,
	[8] = 8,
}

function RM:UpdateBar()
	if not self.bar then
		return
	end

	if not self.db.enable then
		self.bar:Hide()
		return
	end

	local previousButton
	local numButtons = 0

	for i = 1, 11 do
		local button = self.bar.buttons[i]
		button:ClearAllPoints()
		SetSize(button, self.db.buttonSize)
		SetSize(button.tex, self.db.buttonSize)
		button.animGroup:Stop()

		if (i == 10 and not self.db.readyCheck) or (i == 11 and not self.db.countDown) then
			button:Hide()
		else
			button:Show()
			if self.db.orientation == "VERTICAL" then
				if i == 1 then
					SetPoint(button, "TOP", 0, -self.db.backdropSpacing)
				else
					SetPoint(button, "TOP", previousButton, "BOTTOM", 0, -self.db.spacing)
				end
			else
				if i == 1 then
					SetPoint(button, "LEFT", self.db.backdropSpacing, 0)
				else
					SetPoint(button, "LEFT", previousButton, "RIGHT", self.db.spacing, 0)
				end
			end
			previousButton = button
			numButtons = numButtons + 1
		end
	end

	local height = self.db.buttonSize + self.db.backdropSpacing * 2
	local width = self.db.backdropSpacing * 2 + self.db.buttonSize * numButtons + self.db.spacing * (numButtons - 1)

	if self.db.orientation == "VERTICAL" then
		width, height = height, width
	end

	self.bar:Show()
	SetSize(self.bar, width, height)

	if self.db.backdrop then
		self.bar.backdrop:Show()
	else
		self.bar.backdrop:Hide()
	end
end

function RM:UpdateButtons()
	if not self.bar or not self.bar.buttons then
		return
	end

	self.modifierString = gsub(self.db.modifier, "^%l", strupper)

	for i = 1, 11 do
		local button = self.bar.buttons[i]

		if self.db.buttonBackdrop then
			button.backdrop:Show()
		else
			button.backdrop:Hide()
		end

		if button and button.backdrop.shadow then
			if self.db.backdrop then
				button.backdrop.shadow:Hide()
			else
				button.backdrop.shadow:Show()
			end
		end

		-- Key bindings
		if button.isMarkButton then
			button:SetAttribute("shift-type*", nil)
			button:SetAttribute("alt-type*", nil)
			button:SetAttribute("ctrl-type*", nil)

			button:SetAttribute(format("%s-type*", self.db.modifier), "macro")

			if not self.db.inverse then
				button:SetAttribute("macrotext1", format("/tm %d", i))
				button:SetAttribute("macrotext2", "/tm 0")
				button:SetAttribute(format("%s-macrotext1", self.db.modifier), format("/wm %d", TargetToWorld[i]))
				button:SetAttribute(format("%s-macrotext2", self.db.modifier), format("/cwm %d", TargetToWorld[i]))
			else
				button:SetAttribute("macrotext1", format("/wm %d", TargetToWorld[i]))
				button:SetAttribute("macrotext2", format("/cwm %d", TargetToWorld[i]))
				button:SetAttribute(format("%s-macrotext1", self.db.modifier), format("/tm %d", i))
				button:SetAttribute(format("%s-macrotext2", self.db.modifier), "/tm 0")
			end
		end
	end
end

function RM:ToggleSettings()
	if InCombatLockdown() then
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "ToggleSettings")
		return
	else
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end

	if self.bar and not self.db.enable then
		UnregisterStateDriver(self.bar, "visibility")
		self.bar:Hide()
		return
	end

	self:UpdateButtons()
	self:UpdateBar()

	if self.bar and self.db and self.db.visibility then
		-- The bar stays visible by default (hidden only in pet battles).
		-- Upstream's "hide while solo without a target" behavior proved
		-- surprising when placing world markers out of combat.
		local driver
		if self.db.visibility == "INPARTY" then
			driver = "[group] show; [petbattle] hide; hide"
		else
			driver = "[petbattle] hide; show"
		end
		RegisterStateDriver(self.bar, "visibility", driver)
	end

	-- Fade in/out for mouseover
	if self.db.mouseOver then
		self.bar:SetScript("OnEnter", function(bar)
			bar:SetAlpha(1)
		end)

		self.bar:SetScript("OnLeave", function(bar)
			bar:SetAlpha(0)
		end)

		self.bar:SetAlpha(0)
	else
		self.bar:SetScript("OnEnter", nil)
		self.bar:SetScript("OnLeave", nil)
		self.bar:SetAlpha(1)
	end
end

---Resolve a sensible default anchor: the EllesmereUI chat background if it is
---live, otherwise ChatFrame1 (the Blizzard chat frame every chat addon is
---built on), otherwise UIParent. Mirrors the Chat Bar's anchor resolution;
---the bar defaults to hovering just above the chat panel, right-aligned
---(the Chat Bar occupies the left side above the same panel).
---@return Frame frame the anchor frame (never nil)
---@return string point
---@return string relPoint
---@return number x
---@return number y
local function ResolveDefaultAnchor()
	local chatFrame = _G.ChatFrame1
	if chatFrame and EUI and EUI._chatCFD then
		local ok, data = pcall(EUI._chatCFD, chatFrame)
		if ok and data and data.bg then
			local bg = data.bg
			local live = bg.IsShown and bg:IsShown() and bg.GetWidth and bg:GetWidth() > 0
			if live then
				-- bar.BOTTOMRIGHT on bg.TOPRIGHT => bar sits just above the panel.
				return bg, "TOPRIGHT", "TOPRIGHT", -6, 30
			end
		end
	end
	if chatFrame and chatFrame.GetWidth and chatFrame:GetWidth() > 0 then
		return chatFrame, "TOPRIGHT", "TOPRIGHT", -6, 30
	end
	-- Last-resort fallback.
	return E.UIParent, "BOTTOMRIGHT", "BOTTOMRIGHT", -20, 180
end

---Apply the saved mover position, or the default anchor if none.
function RM:ApplyDefaultPosition()
	if not self.bar then
		return
	end

	local pos = E.global.WT and E.global.WT.combat and E.global.WT.combat.raidMarkers
		and E.global.WT.combat.raidMarkers.position

	self.bar:ClearAllPoints()
	if pos and pos.point and pos.x and pos.y then
		SetPoint(self.bar, pos.point, _G.UIParent, pos.relPoint or pos.point, pos.x, pos.y)
	else
		local anchorFrame, point, relPoint, x, y = ResolveDefaultAnchor()
		SetPoint(self.bar, point, anchorFrame, relPoint, x, y)
	end
end

---Register the bar with EllesmereUI's Unlock Mode so it can be dragged and
---positioned alongside all other EllesmereUI layout elements (same approach
---as the Chat Bar and Extra Items Bar movers).
function RM:RegisterMover()
	if not EUI or not EUI.RegisterUnlockElements or not EUI.MakeUnlockElement then
		return
	end

	local MK = EUI.MakeUnlockElement

	local elements = {
		MK({
			key = "WTRaidMarkersBar",
			label = L["Raid Markers Bar"],
			group = "WindTools",
			order = 906,
			getFrame = function()
				return RM.bar
			end,
			getSize = function()
				if not RM.bar then
					return 1, 1
				end
				return RM.bar:GetWidth(), RM.bar:GetHeight()
			end,
			savePos = function(_, point, relPoint, x, y)
				if point and x and y then
					E.global.WT.combat.raidMarkers.position = {
						point = point,
						relPoint = relPoint or point,
						x = x,
						y = y,
					}
				end
			end,
			loadPos = function()
				local pos = E.global.WT and E.global.WT.combat and E.global.WT.combat.raidMarkers
					and E.global.WT.combat.raidMarkers.position
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
				E.global.WT.combat.raidMarkers.position = nil
			end,
			applyPos = function()
				RM:ApplyDefaultPosition()
			end,
			isHidden = function()
				return not (RM.db and RM.db.enable)
			end,
		}),
	}

	EUI:RegisterUnlockElements(elements, "EllesmereUI_WindTools")
end

function RM:CreateBar()
	if self.bar then
		return
	end

	-- SecureHandlerStateTemplate lets the visibility state driver run in a
	-- secure context (same approach as the Chat Bar). A single frame keeps
	-- the EllesmereUI mover registration straightforward.
	local bar = CreateFrame("Frame", "WTRaidMarkersBar", E.UIParent, "SecureHandlerStateTemplate")
	bar:SetResizable(false)
	bar:SetClampedToScreen(true)
	bar:SetFrameStrata("LOW")
	CreateBackdrop(bar)
	bar.buttons = {}
	self.bar = bar

	self:ApplyDefaultPosition()
	self:CreateButtons()
	self:ToggleSettings()
end

function RM:UpdateCountDownButton()
	if not (self.db and self.bar and self.bar.buttons and self.bar.buttons[11]) then
		return
	end

	local button = self.bar.buttons[11]
	if C_AddOns_IsAddOnLoaded("BigWigs") then
		button:SetAttribute("macrotext1", "/pull " .. self.db.countDownTime)
		button:SetAttribute("macrotext2", "/pull 0")
	elseif C_AddOns_IsAddOnLoaded("DBM-Core") then
		button:SetAttribute("macrotext1", "/dbm pull " .. self.db.countDownTime)
		button:SetAttribute("macrotext2", "/dbm pull 0")
	else
		button:SetAttribute("macrotext1", _G.SLASH_COUNTDOWN1 .. " " .. self.db.countDownTime)
		button:SetAttribute("macrotext2", _G.SLASH_COUNTDOWN1 .. " " .. 0)
	end
end

function RM:CreateButtons()
	self.modifierString = self.db.modifier:gsub("^%l", strupper)

	for i = 1, 11 do
		local button = self.bar.buttons[i]
		if not button then
			button = CreateFrame("Button", nil, self.bar, "SecureActionButtonTemplate") --[[@as Button]]
			CreateBackdrop(button)
		end
		SetSize(button, self.db.buttonSize)

		local tex = button:CreateTexture(nil, "ARTWORK")
		SetSize(tex, self.db.buttonSize)
		SetPoint(tex, "CENTER")
		button.tex = tex

		if i < 9 then -- Markers
			tex:SetTexture(format("Interface\\TargetingFrame\\UI-RaidTargetingIcon_%d", i))

			button:SetAttribute("type*", "macro")
			button:SetAttribute(format("%s-type*", self.db.modifier), "macro")

			button.isMarkButton = true
		elseif i == 9 then -- Clear All
			tex:SetTexture("Interface\\BUTTONS\\UI-GroupLoot-Pass-Up")

			button:ClearAttribute("marker")
			local prefix = strlower(RM.modifierString)
			if not self.db.inverse then
				button:SetAttribute(prefix .. "-type*", "worldmarker")
				button:SetAttribute(prefix .. "-action*", "clear")
				button:SetAttribute("type*", "raidtarget")
				button:SetAttribute("action", "clear-all")
			else
				button:SetAttribute(prefix .. "-type*", "raidtarget")
				button:SetAttribute(prefix .. "-action*", "clear-all")
				button:SetAttribute("type*", "worldmarker")
				button:SetAttribute("action", "clear")
			end
		elseif i == 10 then -- Ready Check & Combat Log
			tex:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
			button:SetAttribute("type*", "macro")
			button:SetAttribute("macrotext1", "/readycheck")
			button:SetAttribute("macrotext2", "/combatlog")
		elseif i == 11 then -- Pull Countdown
			tex:SetTexture("Interface\\Icons\\Spell_unused2")
			tex:SetTexCoord(0.25, 0.8, 0.2, 0.75)
			button:SetAttribute("type*", "macro")
			if C_AddOns_IsAddOnLoaded("BigWigs") then
				button:SetAttribute("macrotext1", "/pull " .. self.db.countDownTime)
				button:SetAttribute("macrotext2", "/pull 0")
			elseif C_AddOns_IsAddOnLoaded("DBM-Core") then
				button:SetAttribute("macrotext1", "/dbm pull " .. self.db.countDownTime)
				button:SetAttribute("macrotext2", "/dbm pull 0")
			else
				button:SetAttribute("macrotext1", _G.SLASH_COUNTDOWN1 .. " " .. self.db.countDownTime)
				button:SetAttribute("macrotext2", _G.SLASH_COUNTDOWN1 .. " " .. 0)
			end
		end

		button:RegisterForClicks(W.UseKeyDown and "AnyDown" or "AnyUp")

		local tooltipText = ""

		if i < 9 then
			if not self.db.inverse then
				tooltipText = format(
					"%s\n%s\n%s\n%s",
					L["Left Click to mark the target with this mark."],
					L["Right Click to clear the mark on the target."],
					format(L["%s + Left Click to place this world marker."], RM.modifierString),
					format(L["%s + Right Click to clear this world marker."], RM.modifierString)
				)
			else
				tooltipText = format(
					"%s\n%s\n%s\n%s",
					L["Left Click to place this world marker."],
					L["Right Click to clear this world marker."],
					format(L["%s + Left Click to mark the target with this mark."], RM.modifierString),
					format(L["%s + Right Click to clear the mark on the target."], RM.modifierString)
				)
			end
		elseif i == 9 then
			if not self.db.inverse then
				tooltipText = format(
					"%s\n%s",
					L["Click to clear all marks."],
					format(L["%s + Click to remove all world markers."], RM.modifierString)
				)
			else
				tooltipText = format(
					"%s\n%s",
					L["Click to remove all world markers."],
					format(L["%s + Click to clear all marks."], RM.modifierString)
				)
			end
		elseif i == 10 then
			tooltipText =
				format("%s\n%s", L["Left Click to ready check."], L["Right click to toggle advanced combat logging."])
		elseif i == 11 then
			tooltipText = format("%s\n%s", L["Left Click to start count down."], L["Right click to stop count down."])
		end

		local tooltipTitle = i <= 9 and L["Raid Markers"] or L["Raid Utility"]

		local animGroup = tex:CreateAnimationGroup()
		local scaleAnim = animGroup:CreateAnimation("Scale")
		scaleAnim:SetTarget(tex)
		scaleAnim:SetOrigin("CENTER", 0, 0)

		button.animGroup = animGroup

		animGroup:SetScript("OnPlay", function()
			tex:SetScale(1)
		end)

		animGroup:SetScript("OnFinished", function()
			tex:SetScale(tex.__toScale)
		end)

		button:SetScript("OnEnter", function(btn)
			if RM.db.buttonAnimation then
				local progress = F.Or(animGroup:GetProgress(), 0)
				local currentScale = F.Or(tex:GetScale(), 1)
				if abs(progress) > 0.002 and tex.__fromScale and tex.__toScale then
					currentScale = tex.__fromScale + (tex.__toScale - tex.__fromScale) * progress
				end
				animGroup:Stop()
				tex.__fromScale = currentScale
				tex.__toScale = RM.db.buttonAnimationScale
				scaleAnim:SetScaleFrom(currentScale, currentScale)
				scaleAnim:SetScaleTo(RM.db.buttonAnimationScale, RM.db.buttonAnimationScale)
				scaleAnim:SetDuration(
					(tex.__toScale - currentScale) / (tex.__toScale - 1) * RM.db.buttonAnimationDuration
				)
				animGroup:Play()
			end

			local icon = F.GetIconString(W.Media.Textures.smallLogo, 14)
			btn.backdrop:SetVertexColor(0.7, 0.7, 0, 0.92)
			if RM.db.tooltip then
				GameTooltip:SetOwner(btn, "ANCHOR_BOTTOM")
				GameTooltip:SetText(tooltipTitle .. " " .. icon)
				GameTooltip:AddLine(tooltipText, 1, 1, 1)
				GameTooltip:Show()
			end
		end)

		button:SetScript("OnLeave", function(btn)
			if RM.db.buttonAnimation then
				local progress = F.Or(animGroup:GetProgress(), 0)
				local currentScale = F.Or(tex:GetScale(), 1)
				if abs(progress) > 0.002 and tex.__fromScale and tex.__toScale then
					currentScale = tex.__fromScale + (tex.__toScale - tex.__fromScale) * progress
				end
				animGroup:Stop()
				tex.__fromScale = currentScale
				tex.__toScale = 1
				scaleAnim:SetScaleFrom(currentScale, currentScale)
				scaleAnim:SetScaleTo(1, 1)
				scaleAnim:SetDuration(
					RM.db.buttonAnimationDuration * (currentScale - 1) / (RM.db.buttonAnimationScale - 1)
				)
				animGroup:Play()
			end

		btn.backdrop:SetVertexColor(0.04, 0.05, 0.06, 0.92)
		if RM.db.tooltip then
			GameTooltip:Hide()
		end
		end)

		-- Fade in/out for mouseover
		button:HookScript("OnEnter", function()
			if not self.db.mouseOver then
				return
			end
			self.bar:SetAlpha(1)
			button.backdrop:SetVertexColor(0.7, 0.7, 0, 0.92)
		end)

		button:HookScript("OnLeave", function()
			if not self.db.mouseOver then
				return
			end
			self.bar:SetAlpha(0)
			button.backdrop:SetVertexColor(0.04, 0.05, 0.06, 0.92)
		end)

		self.bar.buttons[i] = button
	end
end

function RM:ProfileUpdate()
	self.db = E.db.WT.combat.raidMarkers

	if not self.db.enable then
		if self.bar then
			self.bar:Hide()
		end
		return
	end

	if not self.bar then
		-- Creating secure buttons and registering state drivers is prohibited
		-- in combat; defer until the player leaves combat.
		if InCombatLockdown() then
			self:RegisterEvent("PLAYER_REGEN_ENABLED", "ProfileUpdate")
			return
		end

		self:Initialize()
		return
	end

	self.modifierString = self.db.modifier:gsub("^%l", strupper)

	self:ToggleSettings()
end

function RM:Initialize()
	if not E.db.WT.combat.raidMarkers.enable then
		return
	end

	self.db = E.db.WT.combat.raidMarkers

	self:CreateBar()
	self:RegisterMover()
end

W:RegisterModule(RM:GetName())
