--!strict

--[ Types ]--
export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
}
export type Signal<T...> = {
	Connect: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
	Once: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
	Wait: (self: Signal<T...>) -> T...,
	Fire: (self: Signal<T...>, T...) -> (),
	Destroy: (self: Signal<T...>) -> (),
}

--[ Variables ]--
local Signal = {}
Signal.__index = Signal

--[ Functions ]--
function Signal.new<T...>(): Signal<T...>
	local self = setmetatable({
		_connections = {} :: {[Connection]: (T...) -> ()},
		_destroyed = false,
	}, Signal)
	return self :: any
end

function Signal:Connect<T...>(callback: (T...) -> ()): Connection
	assert(not self._destroyed, "Signal is destroyed")
	local connection
	connection = {
		Connected = true,
		Disconnect = function(c)
			if not c.Connected then return end
			c.Connected = false
			self._connections[c] = nil
		end,
	}
	self._connections[connection] = callback
	return connection
end

function Signal:Once<T...>(callback: (T...) -> ()): Connection
	local connection: Connection
	connection = self:Connect(function(...: T...)
		connection:Disconnect()
		callback(...)
	end)
	return connection
end

function Signal:Wait<T...>(): T...
	local thread = coroutine.running()
	local connection: Connection
	connection = self:Connect(function(...: T...)
		connection:Disconnect()
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function Signal:Fire<T...>(...: T...)
	if self._destroyed then return end
	for connection, callback in self._connections do
		if connection.Connected then task.spawn(callback, ...) end
	end
end

function Signal:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	for connection in self._connections do connection:Disconnect() end
	table.clear(self._connections)
end

return table.freeze(Signal)
