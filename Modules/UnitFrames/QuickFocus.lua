local W, F, E, L = unpack((select(2, ...))) ---@type WindTools, Functions, ElvUI, LocaleTable
local QF = W:NewModule("QuickFocus", "AceHook-3.0", "AceEvent-3.0")

local next = next
local strjoin = strjoin
local strmatch = strmatch
local strsub = strsub
local tAppendAll = tAppendAll
local unpack = unpack

local CreateFrame = CreateFrame
local EnumerateFrames = EnumerateFrames
local ClearOverrideBindings = ClearOverrideBindings
local InCombatLockdown = InCombatLockdown
local SetOverrideBindingClick = SetOverrideBindingClick

local pending = {}

function QF:SetupFrame(frame)
	if not frame or not frame.GetAttribute or not frame.SetAttribute or frame.windQuickFocus then
		return
	end

	if frame:GetName() and strmatch(frame:GetName(), "oUF_NPs") then
		return
	end

	if not frame.unit and not frame:GetAttribute("unit") then
		return
	end

	if not InCombatLockdown() then
		frame:SetAttribute(self.db.modifier .. "-type" .. strsub(self.db.button, 7, 7), "focus")
		frame.windQuickFocus = {
			modifier = self.db.modifier,
			button = self.db.button,
		}
		pending[frame] = nil
	else
		pending[frame] = true
	end
end

function QF:ScanFrames()
	local frame
	while true do
		frame = EnumerateFrames(frame)
		if not frame then
			break
		end
		self:SetupFrame(frame)
	end
end

function QF:ClearFrames()
	if InCombatLockdown() then
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "ClearFrames")
		return
	end

	local frame
	while true do
		frame = EnumerateFrames(frame)
		if not frame then
			break
		end
		if frame.windQuickFocus then
			local binding = frame.windQuickFocus
			frame:SetAttribute(binding.modifier .. "-type" .. strsub(binding.button, 7, 7), nil)
			frame.windQuickFocus = nil
		end
	end
end

function QF:PLAYER_REGEN_ENABLED()
	if next(pending) then
		for frame in next, pending do
			self:SetupFrame(frame)
		end
	end
end

function QF:GROUP_ROSTER_UPDATE()
	if not self.db or not self.db.enable then
		return
	end

	self:ScanFrames()
end

function QF:WaitUnitframesLoad(triedTimes)
	triedTimes = triedTimes or 0

	if triedTimes > 10 then
		self:Log("debug", "Failed to load unitframes after 10 times, please try again later.")
		return
	end

	self:GROUP_ROSTER_UPDATE()
end

function QF:GetMacroText()
	local lines = { "/focus mouseover" }

	if self.db.setMark and self.db.markNumber and self.db.markNumber >= 1 and self.db.markNumber <= 8 then
		if self.db.safeMark then
			tAppendAll(lines, {
				"/tm [@focus,exists,help][@focus,exists,harm] 0",
				"/tm [@focus,exists,help][@focus,exists,harm] " .. self.db.markNumber,
			})
		else
			tAppendAll(lines, {
				"/tm [@focus,exists] 0",
				"/tm [@focus,exists] " .. self.db.markNumber,
			})
		end
	end

	return strjoin("\n", unpack(lines))
end

function QF:Initialize()
	self.db = E.private.WT.unitFrames.quickFocus
	if not self.db or not self.db.enable then
		return
	end
	if self.initialized then
		return
	end

	local button = self.button
	if not button then
		button = CreateFrame("Button", "WTQuickFocusButton", E.UIParent, "SecureActionButtonTemplate")
		self.button = button
	else
		button:Show()
	end
	button:SetAttribute("type*", "macro")
	button:SetAttribute("macrotext", self:GetMacroText())
	button:RegisterForClicks(W.UseKeyDown and "AnyDown" or "AnyUp")
	SetOverrideBindingClick(button, true, self.db.modifier .. "-" .. self.db.button, "WTQuickFocusButton")

	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:WaitUnitframesLoad()
	self.initialized = true
end

function QF:ProfileUpdate()
	self.db = E.private.WT.unitFrames.quickFocus
	if not self.db or not self.db.enable then
		if self.initialized then
			self:ClearFrames()
			if self.button and not InCombatLockdown() then
				ClearOverrideBindings(self.button)
				self.button:Hide()
			end
			self.initialized = false
		end
		return
	end

	if not self.initialized then
		self:Initialize()
		return
	end

	if InCombatLockdown() then
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "ProfileUpdate")
		return
	end

	self.button:SetAttribute("macrotext", self:GetMacroText())
	ClearOverrideBindings(self.button)
	SetOverrideBindingClick(self.button, true, self.db.modifier .. "-" .. self.db.button, "WTQuickFocusButton")
	self:ScanFrames()
end

W:RegisterModule(QF:GetName())
