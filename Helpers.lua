-- Helpers Module - Utility functions
local Nexus = _G.Nexus

local Helpers = {}

function Helpers.Init(nxs)
    Nexus = nxs
end

-- Safe callback wrapper
function Helpers.SafeCallback(callback, ...)
    if type(callback) == "function" then
        local success, result = pcall(callback, ...)
        if not success then
            warn("Callback error:", result)
        end
        return success
    end
    return false
end

-- Safe disconnect
function Helpers.safeDisconnect(conn)
    if conn and typeof(conn) == "RBXScriptConnection" then
        pcall(function() 
            conn:Disconnect() 
        end)
    end
    return nil
end

-- Get character
function Helpers.getCharacter()
    return Nexus.Player.Character
end

-- Get humanoid
function Helpers.getHumanoid()
    local char = Helpers.getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- Get root part
function Helpers.getRootPart()
    local char = Helpers.getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- Check if R15
function Helpers.r15(speaker)
    local character = speaker.Character
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    return humanoid.RigType == Enum.HumanoidRigType.R15
end

-- Check if killer
function Helpers.IsKiller()
    if not Nexus.Player.Team then return false end
    local teamName = Nexus.Player.Team.Name:lower()
    return teamName:find("killer") or teamName == "killer"
end

-- Check if survivor
function Helpers.IsSurvivor(targetPlayer)
    if not targetPlayer or not targetPlayer.Team then return false end
    local teamName = targetPlayer.Team.Name:lower()
    return teamName:find("survivor") or teamName == "survivors" or teamName == "survivor"
end

-- Get team role
function Helpers.GetRole(targetPlayer)
    if targetPlayer.Team and targetPlayer.Team.Name then
        local n = targetPlayer.Team.Name:lower()
        if n:find("killer") then return "Killer" end
        if n:find("survivor") then return "Survivor" end
    end
    return "Survivor"
end

-- Find remote in ReplicatedStorage
function Helpers.FindRemote(path)
    local current = Nexus.Services.ReplicatedStorage
    for _, part in ipairs(path:split("/")) do
        current = current:WaitForChild(part)
    end
    return current
end

-- Send notification
function Helpers.Notify(title, content, duration)
    Nexus.Fluent:Notify({
        Title = title,
        Content = content,
        Duration = duration or 5
    })
end

-- Wait for character
function Helpers.WaitForCharacter(timeout)
    timeout = timeout or 10
    local startTime = tick()
    
    while tick() - startTime < timeout do
        if Nexus.Player.Character and Nexus.Player.Character:FindFirstChild("HumanoidRootPart") then
            return Nexus.Player.Character
        end
        task.wait(0.1)
    end
    
    return nil
end

-- Distance between two positions
function Helpers.GetDistance(pos1, pos2)
    if not pos1 or not pos2 then return math.huge end
    return (pos1 - pos2).Magnitude
end

-- Table utilities
function Helpers.DeepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            v = Helpers.DeepCopy(v)
        end
        copy[k] = v
    end
    return copy
end

function Helpers.MergeTables(t1, t2)
    local result = Helpers.DeepCopy(t1)
    for k, v in pairs(t2) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = Helpers.MergeTables(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end

-- String utilities
function Helpers.Trim(str)
    return str:match("^%s*(.-)%s*$")
end

function Helpers.StartsWith(str, start)
    return str:sub(1, #start) == start
end

function Helpers.EndsWith(str, ending)
    return ending == "" or str:sub(-#ending) == ending
end

-- Color utilities
function Helpers.HexToRGB(hex)
    hex = hex:gsub("#","")
    return Color3.fromRGB(
        tonumber("0x"..hex:sub(1,2)),
        tonumber("0x"..hex:sub(3,4)),
        tonumber("0x"..hex:sub(5,6))
    )
end

function Helpers.RGBToHex(color)
    return string.format("#%02X%02X%02X", 
        math.floor(color.R * 255),
        math.floor(color.G * 255),
        math.floor(color.B * 255)
    )
end

-- Math utilities
function Helpers.Round(num, decimalPlaces)
    local multiplier = 10^(decimalPlaces or 0)
    return math.floor(num * multiplier + 0.5) / multiplier
end

function Helpers.Clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

function Helpers.Lerp(a, b, t)
    return a + (b - a) * t
end

-- Debug utilities
function Helpers.PrintTable(tbl, indent)
    indent = indent or 0
    for k, v in pairs(tbl) do
        local formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            print(formatting)
            Helpers.PrintTable(v, indent + 1)
        else
            print(formatting .. tostring(v))
        end
    end
end

function Helpers.DebugLog(message, ...)
    local args = {...}
    local formatted = string.format(message, unpack(args))
    print("[DEBUG] " .. formatted)
end

return Helpers
