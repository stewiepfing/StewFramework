--!strict

--[ Types ]--
type CleanupTask = RBXScriptConnection | Instance | thread | () -> () | {Destroy: (self: any) -> ()} | {Disconnect: (self: any) -> ()}
export type Cleanup = {
	Add: (self: Cleanup, task: CleanupTask) -> CleanupTask,
	Clean: (self: Cleanup) -> (),
	Destroy: (self: Cleanup) -> (),
}

--[ Variables ]--
local Cleanup = {}
Cleanup.__index = Cleanup

--[ Functions ]--
local function clean(task: CleanupTask)
	local kind = typeof(task)
	if kind == "RBXScriptConnection" then
		(task :: RBXScriptConnection):Disconnect()
	elseif kind == "Instance" then
		(task :: Instance):Destroy()
	elseif kind == "thread" then
		task.cancel(task :: thread)
	elseif kind == "function" then
		(task :: () -> ())()
	elseif type(task) == "table" then
		local object = task :: any
		if type(object.Destroy) == "function" then object:Destroy()
		elseif type(object.Disconnect) == "function" then object:Disconnect() end
	end
end

function Cleanup.new(): Cleanup
	return setmetatable({_tasks = {}, _destroyed = false}, Cleanup) :: any
end

function Cleanup:Add(taskObject: CleanupTask): CleanupTask
	if self._destroyed then
		clean(taskObject)
		return taskObject
	end
	table.insert(self._tasks, taskObject)
	return taskObject
end

function Cleanup:Clean()
	for i = #self._tasks, 1, -1 do
		local taskObject = self._tasks[i]
		self._tasks[i] = nil
		local ok, err = pcall(clean, taskObject)
		if not ok then warn("StewFramework Cleanup:", err) end
	end
end

function Cleanup:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	self:Clean()
end

return table.freeze(Cleanup)
