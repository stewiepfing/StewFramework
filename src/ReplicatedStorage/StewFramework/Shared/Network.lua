--!strict

--[ Services ]--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--[ Variables ]--
local ROOT_NAME = "_StewNetwork"
local Root = ReplicatedStorage:FindFirstChild(ROOT_NAME)
if RunService:IsServer() and not Root then
	Root = Instance.new("Folder")
	Root.Name = ROOT_NAME
	Root.Parent = ReplicatedStorage
elseif not Root then
	Root = ReplicatedStorage:WaitForChild(ROOT_NAME)
end

local Network = {}
local Limits: {[string]: {[Player]: {Window: number, Count: number}}} = {}

--[ Functions ]--
local function remote(name: string): RemoteEvent
	local object = Root:FindFirstChild(name)
	if object then return object :: RemoteEvent end
	assert(RunService:IsServer(), `Remote "{name}" does not exist`)
	local created = Instance.new("RemoteEvent")
	created.Name = name
	created.Parent = Root
	return created
end

function Network.Event(name: string): RemoteEvent
	return remote(name)
end

function Network.Fire(name: string, target: Player?, ...: any)
	local event = remote(name)
	if RunService:IsServer() then
		if target then event:FireClient(target, ...) else event:FireAllClients(...) end
	else
		event:FireServer(target, ...)
	end
end

function Network.On(name: string, callback: (...any) -> (), maxPerSecond: number?): RBXScriptConnection
	local event = remote(name)
	if RunService:IsClient() then return event.OnClientEvent:Connect(callback) end
	local rate = maxPerSecond
	if not rate then return event.OnServerEvent:Connect(callback) end
	Limits[name] = Limits[name] or {}
	return event.OnServerEvent:Connect(function(player: Player, ...: any)
		local now = os.clock()
		local state = Limits[name][player]
		if not state or now - state.Window >= 1 then
			state = {Window = now, Count = 0}
			Limits[name][player] = state
		end
		state.Count += 1
		if state.Count <= rate then callback(player, ...) end
	end)
end

return table.freeze(Network)
