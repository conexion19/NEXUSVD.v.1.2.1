-- VISUAL PARRY DISTANCE --

local ParryCircleVisual = (function()
    local enabled = false
    local circleObj = nil
    local connection = nil
    local teamListeners = {}

    local function destroyCircle()
        if circleObj then
            pcall(function() circleObj:Destroy() end)
            circleObj = nil
        end
    end

    local function createCircle()
        destroyCircle()
        local p = Instance.new("Part")
        p.Name = "NexusParryCircle"
        p.Anchored = true
        p.CanCollide = false
        p.CanTouch = false
        p.CastShadow = false
        p.Transparency = 0.55              -- полупрозрачный
        p.Color = Color3.fromRGB(0, 255, 80) -- зелёный цвет
        local r = AutoParry.GetRange()
        p.Size = Vector3.new(r * 2, 0.05, r * 2)
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.Cylinder
        mesh.Scale = Vector3.new(1, 1, 1)
        mesh.Parent = p
        pcall(function() p.Parent = workspace end)
        return p
    end

    local function isInDanger()
        local myRoot = Nexus.getRootPart()
        if not myRoot then return false end
        for _, player in ipairs(Nexus.Services.Players:GetPlayers()) do
            if player ~= Nexus.Player and player.Character then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then
                    local isKiller = false
                    if player.Team then
                        isKiller = player.Team.Name:lower():find("killer") ~= nil
                    end
                    if isKiller and (root.Position - myRoot.Position).Magnitude <= AutoParry.GetRange() then
                        return true
                    end
                end
            end
        end
        return false
    end

    local function updateVisual()
        if not enabled or not isSurvivorTeam() then
            destroyCircle()
            return
        end
        local myRoot = Nexus.getRootPart()
        if not myRoot then return end
        if not circleObj or not circleObj.Parent then
            circleObj = createCircle()
        end
        local r = AutoParry.GetRange()
        circleObj.Size = Vector3.new(r * 2, 0.05, r * 2)
        circleObj.CFrame = CFrame.new(myRoot.Position.X, myRoot.Position.Y - 2.9, myRoot.Position.Z)
        -- кружок всегда остаётся зелёным
        circleObj.Color = Color3.fromRGB(0, 255, 80)
    end

    local function startLoop()
        if connection then connection:Disconnect(); connection = nil end
        if enabled and isSurvivorTeam() then
            connection = Nexus.Services.RunService.Heartbeat:Connect(updateVisual)
        end
    end

    local function Enable()
        if enabled then return end
        enabled = true
        Nexus.States.ParryCircleEnabled = true
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do Nexus.safeDisconnect(conn) end
            else Nexus.safeDisconnect(listener) end
        end
        teamListeners = {}
        table.insert(teamListeners, setupTeamListener(function()
            if connection then connection:Disconnect(); connection = nil end
            destroyCircle()
            startLoop()
        end))
        startLoop()
    end

    local function Disable()
        if not enabled then return end
        enabled = false
        Nexus.States.ParryCircleEnabled = false
        if connection then connection:Disconnect(); connection = nil end
        destroyCircle()
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do Nexus.safeDisconnect(conn) end
            else Nexus.safeDisconnect(listener) end
        end
        teamListeners = {}
    end

    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end
    }
end)()
