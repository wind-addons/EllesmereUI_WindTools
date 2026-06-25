local addonName, addon = ...

local EUI = _G.EllesmereUI
if not EUI then
	return
end

local FONT_KEY = addonName
local unpack = unpack
local type = type
local pairs = pairs
local tostring = tostring
local tonumber = tonumber
local format = format
local floor = floor
local max = math.max
local min = math.min

local function DeepCopy(value, seen)
	if type(value) ~= "table" then
		return value
	end

	seen = seen or {}
	if seen[value] then
		return seen[value]
	end

	local copy = {}
	seen[value] = copy
	for key, child in pairs(value) do
		copy[DeepCopy(key, seen)] = DeepCopy(child, seen)
	end
	return copy
end

local function CopyTable(target, source)
	if type(target) ~= "table" or type(source) ~= "table" then
		return target
	end

	for key, value in pairs(source) do
		if type(value) == "table" then
			if type(target[key]) ~= "table" then
				target[key] = {}
			end
			CopyTable(target[key], value)
		else
			target[key] = value
		end
	end

	return target
end

local function RemoveTableDuplicates(target, defaults)
	if type(target) ~= "table" or type(defaults) ~= "table" then
		return target
	end

	for key, value in pairs(defaults) do
		if type(value) == "table" and type(target[key]) == "table" then
			RemoveTableDuplicates(target[key], value)
			if next(target[key]) == nil then
				target[key] = nil
			end
		elseif target[key] == value then
			target[key] = nil
		end
	end

	return target
end

local function SplitString(text, separator)
	separator = separator or ","
	local first, second = strsplit(separator, text or "")
	return first, second
end

local function GetFontPath()
	return EUI.GetFontPath and EUI.GetFontPath(FONT_KEY) or _G.STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
end

local function GetFontName()
	return EUI.GetFontName and EUI.GetFontName(FONT_KEY) or "Expressway"
end

local function GetFontOutlineFlag(fallback)
	if fallback and fallback ~= "NONE" then
		return fallback
	end
	return EUI.GetFontOutlineFlag and EUI.GetFontOutlineFlag(FONT_KEY) or ""
end

local function PrimeAndSetFont(fontString, font, size, flags)
	if not fontString or not fontString.SetFont then
		return
	end

	font = font or GetFontPath()
	size = size or select(2, fontString:GetFont()) or 12
	flags = GetFontOutlineFlag(flags)
	if EUI.PrimeFontShadow then
		EUI.PrimeFontShadow(fontString, flags == "")
	end
	fontString:SetFont(font, size, flags)
end

local function InstallFontTemplateCompat()
	local region = CreateFrame("Frame"):CreateFontString(nil, "ARTWORK")
	local meta = getmetatable(region)
	if meta and meta.__index and not meta.__index.FontTemplate then
		meta.__index.FontTemplate = function(self, font, size, flags)
			PrimeAndSetFont(self, font, size, flags)
		end
	end
end

local function ClampColor(value)
	return max(0, min(1, tonumber(value) or 0))
end

local function ColorHex(r, g, b)
	return format("%02x%02x%02x", floor(ClampColor(r) * 255 + 0.5), floor(ClampColor(g) * 255 + 0.5), floor(ClampColor(b) * 255 + 0.5))
end

local function TextGradient(text, r1, g1, b1)
	return "|cff" .. ColorHex(r1 or 1, g1 or 1, b1 or 1) .. tostring(text or "") .. "|r"
end

local function ClassColor(classFile, asTable)
	local color
	if EUI.GetClassColor then
		color = EUI.GetClassColor(classFile)
	elseif _G.C_ClassColor and C_ClassColor.GetClassColor then
		color = C_ClassColor.GetClassColor(classFile)
	end

	color = color or { r = 1, g = 1, b = 1 }
	if asTable then
		return { r = color.r or 1, g = color.g or 1, b = color.b or 1 }
	end
	return color.r or 1, color.g or 1, color.b or 1
end

local function CreateCompatE()
	InstallFontTemplateCompat()

	local E = {
		UIParent = _G.UIParent,
		TexCoords = { 0, 1, 0, 1 },
		PopupDialogs = _G.StaticPopupDialogs or {},
		ConfigModeLayouts = {},
		ConfigModeLocalizedStrings = {},
		NewSign = "",
		version = 999,
		noop = function() end,
		media = {
			normFont = GetFontPath(),
			rgbvaluecolor = { r = 0.05, g = 0.82, b = 0.62 },
		},
		Media = {
			Textures = {},
		},
		db = {
			general = {
				font = GetFontName(),
				fontSize = 12,
				valuecolor = { r = 0.05, g = 0.82, b = 0.62 },
			},
			unitframe = {
				statusbar = "Blizzard",
				font = GetFontName(),
				fontSize = 12,
				fontOutline = "OUTLINE",
			},
		},
		global = {
			general = {},
		},
		private = {},
		Libs = {},
	}

	E.myname = UnitName("player") or "Player"
	E.myrealm = GetRealmName and GetRealmName() or "Realm"
	E.mynameRealm = E.myname .. "-" .. E.myrealm
	E.myclass = select(2, UnitClass("player")) or "PRIEST"
	E.myClassColor = ClassColor(E.myclass, true)

	function E:Delay(delay, callback, ...)
		local args = { ... }
		local timer = C_Timer.NewTimer(delay or 0, function()
			callback(unpack(args))
		end)
		return timer
	end

	function E:CopyTable(target, source)
		if target == nil then
			return DeepCopy(source)
		end
		return CopyTable(target, source)
	end

	function E:RemoveTableDuplicates(target, defaults)
		return RemoveTableDuplicates(target, defaults)
	end

	function E:SplitString(text, separator)
		return SplitString(text, separator)
	end

	function E:TextGradient(text, r1, g1, b1)
		return TextGradient(text, r1, g1, b1)
	end

	function E:ClassColor(classFile, asTable)
		return ClassColor(classFile, asTable)
	end

	function E:UIFrameFadeIn(...)
		return UIFrameFadeIn(...)
	end

	function E:UIFrameFadeOut(...)
		return UIFrameFadeOut(...)
	end

	function E:StaticPopup_Show(name, ...)
		return StaticPopup_Show(name, ...)
	end

	function E:ToggleOptions()
		if EUI.Toggle then
			return EUI:Toggle()
		elseif EUI.OpenOptions then
			return EUI:OpenOptions()
		end
	end

	function E:Print(...)
		if EUI.Print then
			return EUI.Print(...)
		end
	end

	function E:IsAddOnEnabled(name)
		return C_AddOns.GetAddOnEnableState(name, E.myname) == 2
	end

	function E:IsSecretValue(value)
		return value == nil
	end

	function E:NotSecretValue(value)
		return value ~= nil
	end

	function E:AddLib(key, major)
		self.Libs[key] = LibStub and LibStub:GetLibrary(major, true)
		return self.Libs[key]
	end

	E.Libs.LSM = LibStub and LibStub:GetLibrary("LibSharedMedia-3.0", true)
	E.Libs.Deflate = LibStub and LibStub:GetLibrary("LibDeflate", true)
	E.Libs.Keystone = LibStub and LibStub:GetLibrary("LibKeystone", true)

	return E
end

addon.CreateCompatE = CreateCompatE
