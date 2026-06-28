local addonName, addon = ...

local EUI = _G.EllesmereUI
if not EUI or not EUI.Lite then
	return
end

local tinsert = tinsert
local type = type
local pairs = pairs
local error = error
local format = format
local xpcall = xpcall
local geterrorhandler = geterrorhandler

local function ErrorHandler(err)
	return geterrorhandler()(err)
end

local function SafeCall(func, ...)
	if type(func) == "function" then
		return xpcall(func, ErrorHandler, ...)
	end
end

local function DispatchMethod(owner, handler, ...)
	if type(handler) == "string" then
		local method = owner[handler]
		if method then
			return method(owner, ...)
		end
	elseif type(handler) == "function" then
		return handler(owner, ...)
	end
end

local function RegisterChatCommand(prefix, keys, func)
	if type(keys) ~= "table" then
		keys = { keys }
	end

	_G.SlashCmdList[prefix] = func
	for index, key in pairs(keys) do
		if type(key) == "string" and key ~= "" then
			if key:sub(1, 1) ~= "/" then
				key = "/" .. key
			end
			_G["SLASH_" .. prefix .. index] = key
		end
	end
end

local function AddCommonMethods(target)
	target.RegisterEvent = EUI.Lite._RegisterEvent
	target.UnregisterEvent = EUI.Lite._UnregisterEvent

	function target:GetName()
		return self.name
	end

	function target:SecureHook(object, method, handler)
		if type(object) == "string" then
			handler = method
			method = object
			object = _G
		end

		if not object or not method then
			return
		end

		self._hooks = self._hooks or {}
		self._hooks[object] = self._hooks[object] or {}
		if self._hooks[object][method] then
			return
		end

		hooksecurefunc(object, method, function(...)
			DispatchMethod(self, handler or method, ...)
		end)

		self._hooks[object][method] = true
	end

	function target:Hook(object, method, handler)
		self:SecureHook(object, method, handler)
	end

	function target:IsHooked(object, method)
		return self._hooks and self._hooks[object] and self._hooks[object][method] or false
	end

	function target:UnhookAll()
		-- Native hooksecurefunc hooks cannot be removed. Keep this method for
		-- WindTools compatibility so deferred unhook calls are harmless.
	end

	function target:ScheduleTimer(callback, delay, ...)
		local args = { ... }
		return C_Timer.NewTimer(delay or 0, function()
			DispatchMethod(self, callback, unpack(args))
		end)
	end

	function target:ScheduleRepeatingTimer(callback, interval, ...)
		local args = { ... }
		return C_Timer.NewTicker(interval or 0, function()
			DispatchMethod(self, callback, unpack(args))
		end)
	end

	function target:CancelTimer(timer)
		if timer and timer.Cancel then
			timer:Cancel()
		end
	end

	function target:RegisterChatCommand(command, callback)
		local key = "WINDTOOLS_" .. tostring(command):upper()
		RegisterChatCommand(key, command, function(message)
			DispatchMethod(self, callback, message)
		end)
	end
end

local function InstallModuleSystem(W)
	W.Modules = W.Modules or {}
	W.RegisteredModules = W.RegisteredModules or {}
	W._moduleOrder = W._moduleOrder or {}

	AddCommonMethods(W)

	function W:NewModule(name)
		if self.Modules[name] then
			return self.Modules[name]
		end

		local module = { name = name, parent = self }
		AddCommonMethods(module)
		self.Modules[name] = module
		tinsert(self._moduleOrder, name)
		return module
	end

	function W:GetModule(name, silent)
		local module = self.Modules and self.Modules[name]
		if not module and not silent then
			error(format("WindTools module '%s' not found.", tostring(name)), 2)
		end
		return module
	end

	function W:IterateModules()
		return pairs(self.Modules)
	end

	function W:RegisterModule(name)
		if not name then
			return
		end

		if self.initialized then
			local module = self:GetModule(name, true)
			if module and module.Initialize then
				SafeCall(module.Initialize, module)
			end
		else
			tinsert(self.RegisteredModules, name)
		end
	end

	function W:InitializeModules()
		for _, moduleName in pairs(self.RegisteredModules) do
			local module = self:GetModule(moduleName, true)
			if module and module.Initialize then
				SafeCall(module.Initialize, module)
			end
		end
	end

	function W:UpdateModules()
		for _, moduleName in pairs(self.RegisteredModules) do
			local module = self:GetModule(moduleName, true)
			if module and module.ProfileUpdate then
				SafeCall(module.ProfileUpdate, module)
			end
		end
	end

	function W:AddCommand(name, keys, func)
		RegisterChatCommand("WINDTOOLS_" .. tostring(name):upper(), keys, func)
	end

	return W
end

addon.InstallModuleSystem = InstallModuleSystem
