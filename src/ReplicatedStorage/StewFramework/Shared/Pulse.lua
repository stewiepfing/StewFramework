--!strict

--[ Services ]--
local RunService = game:GetService("RunService")

--[ Types ]--
export type Phase = "Render" | "PreSimulation" | "PostSimulation" | "Heartbeat"
export type Handle = {Cancel: (self: Handle) -> ()}
type Job = {
	Name: string,
	Rate: number,
	Callback: (number) -> (),
	Elapsed: number,
	Cancelled: boolean,
}

--[ Variables ]--
local Pulse = {}
local Jobs: {[Phase]: {Job}} = {
	Render = {},
	PreSimulation = {},
	PostSimulation = {},
	Heartbeat = {},
}

--[ Functions ]--
local function step(phase: Phase, dt: number)
	local jobs = Jobs[phase]
	for i = #jobs, 1, -1 do
		local job = jobs[i]
		if job.Cancelled then
			table.remove(jobs, i)
			continue
		end
		job.Elapsed += dt
		local interval = job.Rate > 0 and 1 / job.Rate or 0
		if interval == 0 or job.Elapsed >= interval then
			local elapsed = job.Elapsed
			job.Elapsed = interval > 0 and job.Elapsed % interval or 0
			task.spawn(job.Callback, elapsed)
		end
	end
end

function Pulse.Schedule(config: {Name: string?, Rate: number?, Phase: Phase?, Callback: (number) -> ()}): Handle
	local phase = config.Phase or "Heartbeat"
	local job: Job = {
		Name = config.Name or "Pulse",
		Rate = config.Rate or 60,
		Callback = config.Callback,
		Elapsed = 0,
		Cancelled = false,
	}
	table.insert(Jobs[phase], job)
	return {
		Cancel = function()
			job.Cancelled = true
		end,
	}
end

function Pulse.CancelAll(phase: Phase?)
	if phase then
		for _, job in Jobs[phase] do job.Cancelled = true end
		return
	end
	for _, jobs in Jobs do
		for _, job in jobs do job.Cancelled = true end
	end
end

if RunService:IsClient() then RunService.PreRender:Connect(function(dt) step("Render", dt) end) end
RunService.PreSimulation:Connect(function(dt) step("PreSimulation", dt) end)
RunService.PostSimulation:Connect(function(dt) step("PostSimulation", dt) end)
RunService.Heartbeat:Connect(function(dt) step("Heartbeat", dt) end)

return table.freeze(Pulse)
