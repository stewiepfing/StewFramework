# StewFramework

Reusable Roblox/Luau game framework built around a compact lazy-loaded `_L` API.

## Goals

- Strict Luau
- Lazy module loading and caching
- Small kernel with optional systems
- Shared client/server APIs where practical
- Server-authoritative networking
- Centralized scheduling
- Predictable lifecycle
- Compact production code

## Layout

```
src/
  ReplicatedStorage/
    StewFramework/
      init.lua
      Shared/
        Cleanup.lua
        Network.lua
        Pulse.lua
        Signal.lua
  ServerScriptService/
    StewFrameworkServer.server.lua
  StarterPlayer/
    StarterPlayerScripts/
      StewFrameworkClient.client.lua
```

## Usage

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _L = require(ReplicatedStorage.StewFramework)

local Network = _L.Network
local Pulse = _L.Pulse
```

The core stays intentionally small. Data, replication, state, components, workers, UI, input, audio, effects, profiling, and other systems can be added as framework packages without bloating startup.
