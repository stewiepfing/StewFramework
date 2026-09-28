--!strict

--[ Variables ]--
local Shared = script:WaitForChild("Shared")
local Cache: {[string]: any} = {}

local _L = setmetatable({}, {
	__index = function(_, name: string)
		local cached = Cache[name]
		if cached ~= nil then return cached end
		local module = Shared:FindFirstChild(name)
		if not module or not module:IsA("ModuleScript") then error(`StewFramework: unknown module "{name}"`, 2) end
		local value = require(module)
		Cache[name] = value
		return value
	end,
	__newindex = function()
		error("StewFramework is read-only", 2)
	end,
	__metatable = "StewFramework",
})

return _L
