local addon = select(2, ...)

local xpcall = xpcall
local geterrorhandler = geterrorhandler
local tonumber = tonumber
local type = type

local C_CVar_GetCVar = C_CVar.GetCVar
local C_CVar_GetCVarBool = C_CVar.GetCVarBool
local C_CVar_SetCVar = C_CVar.SetCVar

addon.OptionBuilders = addon.OptionBuilders or {}

function addon.RegisterOptionBuilder(categoryKey, fn)
	addon.OptionBuilders[categoryKey] = fn
end

local function SafeCall(func, ...)
	if type(func) ~= "function" then return end
	return xpcall(func, function(err) return geterrorhandler()(err) end, ...)
end
addon.SafeCall = SafeCall

local function SafeModuleCall(module, method, ...)
	if not module then return end
	local fn = module and module[method]
	if type(fn) ~= "function" then return end
	return xpcall(fn, function(err) return geterrorhandler()(err) end, module, ...)
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

	function addon.FontSection(Widgets, parent, y, dbTable)
		local _, h
		local fonts = GetLSMFonts2()
		_, h = Widgets:Dropdown(parent, "Font", y, fonts, addon.DBGet(dbTable, "name"), addon.DBSet(dbTable, "name")); y = y - h
		_, h = Widgets:Dropdown(parent, "Outline", y, FOV, FOO, addon.DBGet(dbTable, "style"), addon.DBSet(dbTable, "style")); y = y - h
		_, h = Widgets:Slider(parent, "Size", y, 5, 60, 1, addon.DBGet(dbTable, "size"), addon.DBSet(dbTable, "size")); y = y - h
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
