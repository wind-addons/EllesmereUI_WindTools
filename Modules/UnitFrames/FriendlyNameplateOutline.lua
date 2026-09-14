local W, F, E, L = unpack((select(2, ...))) ---@type WindTools, Functions, ElvUI, LocaleTable
local FNO = W:NewModule("FriendlyNameplateOutline", "AceEvent-3.0")

-- Ported from EUI_Kogotool (BlizzUIEnhance "友方姓名板描边"), itself an
-- EllesmereUI compat layer: Ellesmere's friendly Name Only plates render
-- through Blizzard's shared system font objects, but only Ellesmere's own
-- outline stamp keeps them styled. Anything that resets those objects (CVar
-- changes, Ellesmere's size refresh) drops the outline. This module re-asserts
-- the outline flags after every SetFont, and keeps friendly plates visible in
-- follower dungeons where the game force-hides them via CVars.

local _G = _G

local hooksecurefunc = hooksecurefunc
local InCombatLockdown = InCombatLockdown
local unpack = unpack

local C_AddOns_IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local C_Timer_After = C_Timer.After

local FOLLOWER_DIFFICULTY_ID = 208

local hookedFonts = {}
local sizeRefreshHooked = false
local systemHooked = false
local writeGuard = false

-- SetFont on the system font objects fires inside Blizzard's nameplate update
-- chain; deferring every write through a timer keeps our own SetFont out of
-- that insecure execution path (taint).
local function Defer(fn, ...)
	local args = { ... }
	C_Timer_After(0, function()
		fn(unpack(args))
	end)
end

local function GetEllesmereNameplateProfile()
	local provider = _G.EllesmereNameplates_NS
	local db = provider and provider.db
	return provider, db and db.profile
end

local function IsEllesmereFriendlyNameOnly()
	local _, profile = GetEllesmereNameplateProfile()
	return profile ~= nil and profile.showFriendlyPlayers ~= false and profile.friendlyNameOnly ~= false
end

local function IsInFollowerDungeon()
	local C_LFGInfo = C_LFGInfo
	if C_LFGInfo and C_LFGInfo.IsInLFGFollowerDungeon and C_LFGInfo.IsInLFGFollowerDungeon() then
		return true
	end
	local _, _, difficultyID = GetInstanceInfo()
	return difficultyID == FOLLOWER_DIFFICULTY_ID
end

-- Re-apply Ellesmere's outline flags onto a system nameplate font object.
-- Only the flags are touched: font file and height stay whatever the last
-- writer (usually Ellesmere's own size override) set.
local function ApplyOutline(fontObject)
	if writeGuard or not fontObject or not FNO.db or not FNO.db.enable or not IsEllesmereFriendlyNameOnly() then
		return
	end

	local provider = GetEllesmereNameplateProfile()
	local desiredFlags = provider and provider.GetNPOutline and provider.GetNPOutline()
	if desiredFlags == nil then
		local EUI = _G.EllesmereUI
		desiredFlags = EUI and EUI.GetFontOutlineFlag and EUI.GetFontOutlineFlag("nameplates")
	end
	if type(desiredFlags) ~= "string" or desiredFlags == "" then
		return
	end

	local fontFile, fontHeight, currentFlags = fontObject:GetFont()
	if not fontFile or not fontHeight or currentFlags == desiredFlags then
		return
	end

	writeGuard = true
	fontObject:SetFont(fontFile, fontHeight, desiredFlags)
	writeGuard = false
end

local function ScheduleOutline(fontObject)
	if writeGuard then
		return
	end
	Defer(ApplyOutline, fontObject)
end

local function HookFontObject(fontObject)
	if not fontObject or not fontObject.GetFont or not fontObject.SetFont then
		return
	end
	if hookedFonts[fontObject] then
		return
	end
	hookedFonts[fontObject] = true
	hooksecurefunc(fontObject, "SetFont", ScheduleOutline)
	ApplyOutline(fontObject)
end

local function SetupOutline()
	-- EllesmereUINameplates is a separate optional addon; without it there is
	-- nothing to sync from.
	if not C_AddOns_IsAddOnLoaded("EllesmereUINameplates") then
		return
	end

	HookFontObject(_G.SystemFont_NamePlate)
	HookFontObject(_G.SystemFont_NamePlate_Outlined)

	local provider = GetEllesmereNameplateProfile()
	if not sizeRefreshHooked and provider and provider.RefreshFriendlyNameSize then
		sizeRefreshHooked = true
		hooksecurefunc(provider, "RefreshFriendlyNameSize", function()
			Defer(ApplyOutline, _G.SystemFont_NamePlate)
			Defer(ApplyOutline, _G.SystemFont_NamePlate_Outlined)
		end)
	end
end

-- Follower dungeons force friendly nameplates off through CVars; re-assert
-- Ellesmere's friendly-player visibility there while Name Only is active.
local function EnsureFollowerVisibility()
	if not FNO.db or not FNO.db.enable or not IsInFollowerDungeon() or not IsEllesmereFriendlyNameOnly() then
		return
	end
	if InCombatLockdown() then
		return
	end

	local provider = GetEllesmereNameplateProfile()
	if provider and provider.ForceFriendlyPlayerCVarsOn then
		provider.ForceFriendlyPlayerCVarsOn()
	end
end

local function SetupFollowerVisibility()
	local provider = GetEllesmereNameplateProfile()
	if not provider then
		return
	end
	if not systemHooked and provider.UpdateFriendlyNameplateSystem then
		systemHooked = true
		hooksecurefunc(provider, "UpdateFriendlyNameplateSystem", function()
			Defer(EnsureFollowerVisibility)
		end)
	end
	EnsureFollowerVisibility()
end

function FNO:Setup()
	if not self.db or not self.db.enable then
		return
	end
	SetupOutline()
	SetupFollowerVisibility()
end

-- EllesmereUINameplates and its EllesmereNameplates_NS provider may finish
-- initializing after we do; retry briefly instead of racing them.
local function StartSetupRetry()
	local retries = 0

	local function Try()
		if not (FNO.db and FNO.db.enable) then
			return
		end
		if not C_AddOns_IsAddOnLoaded("EllesmereUINameplates") then
			return -- not installed: nothing to wait for
		end
		local provider = GetEllesmereNameplateProfile()
		FNO:Setup()
		if provider and provider.RefreshFriendlyNameSize then
			return -- provider ready: hooks are in place
		end
		retries = retries + 1
		if retries < 40 then
			C_Timer_After(0.5, Try)
		end
	end

	Try()
end

function FNO:ProfileUpdate()
	self.db = E.db.WT.unitFrames.friendlyNameplateOutline
	self:Setup()
end

function FNO:Initialize()
	self.db = E.db.WT.unitFrames.friendlyNameplateOutline

	if not self.db.enable then
		return
	end

	StartSetupRetry()
end

W:RegisterModule(FNO:GetName())
