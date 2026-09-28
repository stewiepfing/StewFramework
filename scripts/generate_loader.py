from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
SHARED = ROOT / "src/ReplicatedStorage/StewFramework/Shared"
OUTPUT = ROOT / "src/ReplicatedStorage/StewFramework/init.lua"
IDENTIFIER = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")

names = sorted(
    path.stem for path in SHARED.glob("*.lua")
    if not path.stem.startswith("_") and IDENTIFIER.match(path.stem)
)

types = "\n".join(f"\t{name}: typeof(require(Shared.{name}))," for name in names)

content = f'''--!strict

--[ Variables ]--
local Shared = script:WaitForChild("Shared")
local Cache: {{[string]: any}} = {{}}

--[ Types ]--
export type Framework = {{
{types}
}}

--[ Loader ]--
local _L = setmetatable({{}}, {{
\t__index = function(_, name: string)
\t\tlocal cached = Cache[name]
\t\tif cached ~= nil then return cached end
\t\tlocal module = Shared:FindFirstChild(name)
\t\tif not module or not module:IsA("ModuleScript") then error(\`StewFramework: unknown module "{{name}}"\`, 2) end
\t\tlocal value = require(module)
\t\tCache[name] = value
\t\treturn value
\tend,
\t__newindex = function()
\t\terror("StewFramework is read-only", 2)
\tend,
\t__metatable = "StewFramework",
}}) :: Framework

return _L
'''

OUTPUT.write_text(content, encoding="utf-8")
print(f"Generated {{OUTPUT.relative_to(ROOT)}} with {{len(names)}} modules")
