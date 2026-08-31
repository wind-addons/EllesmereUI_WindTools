local W, F, E, L = unpack((select(2, ...))) ---@type WindTools, Functions, ElvUI, LocaleTable
local QF = W:NewModule("QuickFocus", "AceHook-3.0", "AceEvent-3.0")

local next = next
local geterrorhandler = geterrorhandler
local getmetatable = getmetatable
local rawset = rawset
local setmetatable = setmetatable
local strjoin = strjoin
local strmatch = strmatch
local strsub = strsub
local tAppendAll = tAppendAll
local unpack = unpack
local xpcall = xpcall

local CreateFrame = CreateFrame
local ClearOverrideBindings = ClearOverrideBindings
local InCombatLockdown = InCombatLockdown
local SetOverrideBindingClick = SetOverrideBindingClick

-- Frames first spotted during combat lockdown wait here until combat ends.
-- Weak keys let frames destroyed mid-combat drop out instead of leaking.
local pending = setmetatable({}, { __mode = "k" })
-- Every frame we put the focus attribute on, so cleanup and rebinding only
-- ever touch our own frames instead of walking the UI.
local tracked = setmetatable({}, { __mode = "k" })

function QF:SetupFrame(frame)
	if not self.db or not self.db.enable then
		return
	end

	if not frame or not frame.GetName or not frame.GetAttribute or not frame.SetAttribute then
		return
	end

	-- Blizzard's damage meter overrides GetName() on its bars and returns a
	-- non-string, so guard the type before matching.
	local name = frame:GetName()
	if name and type(name) == "string" and strmatch(name, "oUF_NPs") then
		return
	end

	if not frame.unit and not frame:GetAttribute("unit") then
		return
	end

	local modifier, button = self.db.modifier, self.db.button
	local binding = frame.windQuickFocus
	if binding and binding.modifier == modifier and binding.button == button then
		return
	end

	if InCombatLockdown() then
		pending[frame] = true
		return
	end

	-- Binding settings changed since this frame was set up: drop the stale
	-- attribute before applying the new one.
	if binding then
		frame:SetAttribute(binding.modifier .. "-type" .. strsub(binding.button, 7, 7), nil)
	end
	frame:SetAttribute(modifier .. "-type" .. strsub(button, 7, 7), "focus")
	frame.windQuickFocus = {
		modifier = modifier,
		button = button,
	}
	tracked[frame] = true
	pending[frame] = nil
end

function QF:TeardownFrame(frame)
	local binding = frame and frame.windQuickFocus
	if not binding or not frame.SetAttribute then
		return
	end

	if not InCombatLockdown() then
		frame:SetAttribute(binding.modifier .. "-type" .. strsub(binding.button, 7, 7), nil)
		frame.windQuickFocus = nil
		tracked[frame] = nil
		pending[frame] = nil
	end
	-- In combat the owner is almost certainly discarding the frame anyway;
	-- the attribute disappears with it.
end

-- oUF-based unit frames (EllesmereUI included), EllesmereUI raid frames with
-- their own click-cast engine off, and any Clique-compatible addon announce
-- themselves through the global ClickCastFrames registry. Watching it reaches
-- those frames the moment they spawn, without walking the whole UI.
function QF:InstallRegistryHook()
	local registry = _G.ClickCastFrames

	if type(registry) == "table" and getmetatable(registry) then
		-- Another consumer (Clique, EllesmereUI's click-cast engine) already
		-- owns the table; never fight over it.
		for frame in pairs(registry) do
			self:SetupFrame(frame)
		end
		return
	end

	-- The local must exist before the closure is defined, otherwise `proxy`
	-- inside __newindex resolves to a nil global at runtime.
	local proxy = {}
	setmetatable(proxy, {
		__newindex = function(_, frame, value)
			-- Persist entries so a consumer taking the table over from us
			-- later can still discover them.
			rawset(proxy, frame, value)
			-- Runs inside other addons' spawn paths, so errors must not
			-- escape into their code.
			if value == nil or value == false then
				xpcall(QF.TeardownFrame, geterrorhandler(), QF, frame)
			else
				xpcall(QF.SetupFrame, geterrorhandler(), QF, frame)
			end
		end,
	})

	_G.ClickCastFrames = proxy

	if type(registry) == "table" then
		for frame, value in pairs(registry) do
			proxy[frame] = value
		end
	end
end

function QF:ClearFrames()
	if InCombatLockdown() then
		self.deferredClear = true
		return
	end

	for frame in next, tracked do
		local binding = frame.windQuickFocus
		if binding then
			frame:SetAttribute(binding.modifier .. "-type" .. strsub(binding.button, 7, 7), nil)
			frame.windQuickFocus = nil
		end
		tracked[frame] = nil
	end
end

function QF:ReleaseButton()
	if InCombatLockdown() then
		self.deferredRelease = true
		return
	end

	if self.button then
		ClearOverrideBindings(self.button)
		self.button:Hide()
	end
	self.deferredRelease = nil
end

-- PLAYER_REGEN_ENABLED is registered exactly once (in Initialize); combat
-- work is deferred through flags because re-registering the event with
-- another handler would silently replace this one.
function QF:PLAYER_REGEN_ENABLED()
	if next(pending) then
		for frame in next, pending do
			self:SetupFrame(frame)
		end
	end

	if self.deferredClear then
		self.deferredClear = nil
		self:ClearFrames()
	end

	if self.deferredRelease then
		self:ReleaseButton()
	end

	if self.deferredProfileUpdate then
		self.deferredProfileUpdate = nil
		self:ProfileUpdate()
	end
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
	end
	-- Hidden frames never process binding clicks, so the override binding
	-- only works after the button is shown (previously required an
	-- off/on toggle to take effect).
	button:Show()
	button:SetAttribute("type*", "macro")
	button:SetAttribute("macrotext", self:GetMacroText())
	button:RegisterForClicks(W.UseKeyDown and "AnyDown" or "AnyUp")
	SetOverrideBindingClick(button, true, self.db.modifier .. "-" .. self.db.button, "WTQuickFocusButton")

	self:InstallRegistryHook()
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self.initialized = true
end

function QF:ProfileUpdate()
	self.db = E.private.WT.unitFrames.quickFocus
	if not self.db or not self.db.enable then
		if self.initialized then
			self.initialized = false
			for frame in next, pending do
				pending[frame] = nil
			end
			self.deferredProfileUpdate = nil
			self:ClearFrames()
			self:ReleaseButton()
		end
		return
	end

	if not self.initialized then
		self:Initialize()
		return
	end

	if InCombatLockdown() then
		self.deferredProfileUpdate = true
		return
	end

	self.button:SetAttribute("macrotext", self:GetMacroText())
	ClearOverrideBindings(self.button)
	SetOverrideBindingClick(self.button, true, self.db.modifier .. "-" .. self.db.button, "WTQuickFocusButton")
	for frame in next, tracked do
		self:SetupFrame(frame)
	end
end

W:RegisterModule(QF:GetName())
