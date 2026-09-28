--!strict

--[ Types ]--
export type Unit = {
	Name: string?,
	Priority: number?,
	Dependencies: {string}?,
	Init: ((self: any) -> ())?,
	Start: ((self: any) -> ())?,
}

--[ Variables ]--
local Runtime = {}
local Units: {[string]: Unit} = {}
local Started = false

--[ Functions ]--
function Runtime.Register(name: string, unit: Unit)
	assert(not Started, "Runtime already started")
	assert(not Units[name], `Duplicate runtime unit "{name}"`)
	unit.Name = unit.Name or name
	Units[name] = unit
	return unit
end

local function visit(name: string, visiting: {[string]: boolean}, visited: {[string]: boolean}, order: {Unit})
	if visited[name] then return end
	assert(not visiting[name], `Circular dependency at "{name}"`)
	local unit = assert(Units[name], `Unknown dependency "{name}"`)
	visiting[name] = true
	for _, dependency in unit.Dependencies or {} do visit(dependency, visiting, visited, order) end
	visiting[name] = nil
	visited[name] = true
	table.insert(order, unit)
end

function Runtime.Start()
	if Started then return end
	Started = true
	local names = {}
	for name in Units do table.insert(names, name) end
	table.sort(names, function(a, b)
		return (Units[a].Priority or 0) > (Units[b].Priority or 0)
	end)
	local order, visited, visiting = {}, {}, {}
	for _, name in names do visit(name, visiting, visited, order) end
	for _, unit in order do if unit.Init then unit:Init() end end
	for _, unit in order do if unit.Start then task.spawn(unit.Start, unit) end end
end

function Runtime.Get(name: string): Unit?
	return Units[name]
end

return table.freeze(Runtime)
