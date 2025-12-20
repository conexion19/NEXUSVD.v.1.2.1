-- Killer Module - All killer functions
local Nexus = _G.Nexus

local Killer = {
    Connections = {},
    Abysswalker = {}
}

function Killer.Init(nxs)
    Nexus = nxs
    
    local Tabs = Nexus.Tabs
    local Options = Nexus.Options
    
    -- ========== ONE HIT KILL ==========
    if Nexus.IS_DESKTOP then
        local OneHitKillToggle = Tabs.Killer:AddToggle("OneHitKill", {
            Title = "OneHitKill", 
            Description = "Attack nearby players with one click (Killer only)", 
            Default = false
        })

        OneHitKillToggle:OnChanged(function(v)
            Nexus.SafeCallback(function()
                if v then 
                    Killer.EnableOneHitKill() 
                else 
                    Killer.DisableOneHitKill() 
                end
            end)
        end)
    end

    -- ========== DESTROY PALLETS ==========
    local DestroyPalletsToggle = Tabs.Killer:AddToggle("DestroyPallets", {
        Title = "Destroy Pallets", 
        Description = "smash all the pallets on the map", 
        Default = false
    })

    DestroyPalletsToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            Killer.ToggleDestroyPallets(v)
        end)
    end)

    -- ========== NO SLOWDOWN ==========
    local NoSlowdownToggle = Tabs.Killer:AddToggle("NoSlowdown", {
        Title = "No Slowdown", 
        Description = "Prevents slowdown when attacking", 
        Default = false
    })

    NoSlowdownToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            if v then 
                Killer.EnableNoSlowdown() 
            else 
                Killer.DisableNoSlowdown() 
            end
        end)
    end)

    -- ========== BREAK GENERATOR ==========
    local BreakGeneratorToggle = Tabs.Killer:AddToggle("BreakGenerator", {
        Title = "FullGeneratorBreak", 
        Description = "complete generator failure", 
        Default = false
    })

    BreakGeneratorToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            Killer.ToggleBreakGenerator(v)
        end)
    end)

    -- ========== ABYSSWALKER CORRUPT ==========
    local AbysswalkerCorruptKeybind = Tabs.Killer:AddKeybind("AbysswalkerCorruptKeybind", {
        Title = "Abysswalker Corrupt [NO COOLDOWN]",
        Description = "Activate Abysswalker corrupt ability",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Killer.ActivateAbysswalkerCorrupt()
            end)
        end,
        ChangedCallback = function(newKey)
            -- Optional: handle key change
        end
    })

    -- ========== ANTI BLIND ==========
    local AntiBlindToggle = Tabs.Killer:AddToggle("AntiBlind", {
        Title = "Anti Blind", 
        Description = "prevents you from being blinded by a flashlight", 
        Default = false
    })

    AntiBlindToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            if v then 
                Killer.EnableAntiBlind() 
            else 
                Killer.DisableAntiBlind() 
            end
        end)
    end)

    -- ========== MASK POWERS ==========
    local MaskPowers = Tabs.Killer:AddDropdown("MaskPowers", {
        Title = "Mask Powers",
        Description = "Select mask power to activate immediately",
        Values = {"Alex", "Tony", "Brandon", "Jake", "Richter", "Graham", "Richard"},
        Multi = false,
        Default = ""
    })

    MaskPowers:OnChanged(function(value)
        Nexus.SafeCallback(function()
            if value and value ~= "" then
                Killer.ActivateMaskPower(value)
            end
        end)
    end)

    -- ========== INFORMATION ==========
    Tabs.Killer:AddParagraph({
        Title = "Mask Powers Information",
        Content = "Alex - Chainsaw\nTony - Fists\nBrandon - Speed\nJake - Long lunge\nRichter - Stealth\nGraham - Faster vaults\nRichard - Default mask"
    })

    print("✓ Killer module initialized")
end

-- ========== FUNCTION IMPLEMENTATIONS ==========

-- One Hit Kill
function Killer.EnableOneHitKill()
    if Nexus.States.OneHitKillEnabled then return end
    Nexus.States.OneHitKillEnabled = true
    
    local mouseClickConnection = nil
    local basicAttackRemote = nil

    local function GetBasicAttackRemote()
        if not basicAttackRemote then
            pcall(function()
                basicAttackRemote = Nexus.Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Attacks"):WaitForChild("BasicAttack")
            end)
            
            if not basicAttackRemote then
                for _, remote in ipairs(Nexus.Services.ReplicatedStorage:GetDescendants()) do
                    if remote:IsA("RemoteEvent") and (remote.Name:lower():find("attack") or remote.Name:lower():find("basic")) then
                        basicAttackRemote = remote
                        break
                    end
                end
            end
        end
        return basicAttackRemote
    end

    local function IsKiller()
        if Nexus.Player.Team then
            local teamName = Nexus.Player.Team.Name:lower()
            return teamName:find("killer") == 1 or teamName == "killer"
        end
        return false
    end

    local function IsValidTarget(targetPlayer)
        if not targetPlayer or targetPlayer == Nexus.Player then return false end
        if not targetPlayer.Character then return false end
        
        if targetPlayer.Team then
            local teamName = targetPlayer.Team.Name:lower()
            if teamName:find("killer") then return false end
        end
        
        local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return false end
        
        return true
    end

    local function GetNearestTarget()
        if not IsKiller() then return nil end
        
        local character = Nexus.getCharacter()
        if not character then return nil end
        
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return nil end
        
        local nearestTarget = nil
        local nearestDistance = 20
        
        for _, targetPlayer in ipairs(Nexus.Services.Players:GetPlayers()) do
            if targetPlayer ~= Nexus.Player and IsValidTarget(targetPlayer) then
                local targetCharacter = targetPlayer.Character
                if targetCharacter then
                    local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
                    
                    if targetRoot then
                        local currentDistance = (rootPart.Position - targetRoot.Position).Magnitude
                        
                        if currentDistance < nearestDistance then
                            nearestDistance = currentDistance
                            nearestTarget = targetRoot
                        end
                    end
                end
            end
        end
        
        return nearestTarget
    end

    local function OnMouseClick(input, gameProcessed)
        if gameProcessed or not Nexus.States.OneHitKillEnabled then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not IsKiller() then
                print("OneHitKill: Player is not in Killer team")
                return
            end
            
            local target = GetNearestTarget()
            if target then
                local attackRemote = GetBasicAttackRemote()
                if attackRemote then
                    pcall(function()
                        attackRemote:FireServer(target.Position)
                        print("OneHitKill activated on target at distance: " .. (target.Position - Nexus.Player.Character.HumanoidRootPart.Position).Magnitude)
                    end)
                end
            end
        end
    end

    mouseClickConnection = Nexus.Services.UserInputService.InputBegan:Connect(OnMouseClick)
    Killer.Connections.OneHitKill = mouseClickConnection
    
    print("OneHitKill enabled")
end

function Killer.DisableOneHitKill()
    if not Nexus.States.OneHitKillEnabled then return end
    Nexus.States.OneHitKillEnabled = false
    
    if Killer.Connections.OneHitKill then
        Killer.Connections.OneHitKill:Disconnect()
        Killer.Connections.OneHitKill = nil
    end
    
    print("OneHitKill disabled")
end

-- Destroy Pallets
function Killer.ToggleDestroyPallets(enabled)
    Nexus.States.DestroyPalletsEnabled = enabled
    
    if enabled then
        task.spawn(function()
            while Nexus.States.DestroyPalletsEnabled do
                Killer.DestroyAllPallets()
                task.wait(0.5)
            end
        end)
    end
end

function Killer.DestroyAllPallets()
    local palletsDestroyed = false
    
    if palletsDestroyed then
        return
    end
    
    local DestroyGlobal = Nexus.Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Pallet"):WaitForChild("Jason"):WaitForChild("Destroy-Global")
    
    local character = Nexus.getCharacter()
    local savedPosition = nil
    
    if character and character:FindFirstChild("HumanoidRootPart") then
        savedPosition = character.HumanoidRootPart.CFrame
    end
    
    palletsDestroyed = true
    
    for _, obj in ipairs(Nexus.Services.Workspace:GetDescendants()) do
        if obj.Name:find("PalletPoint") then
            DestroyGlobal:FireServer(obj)
        end
    end
    
    task.delay(3.2, function()
        if savedPosition and character and character:FindFirstChild("HumanoidRootPart") then
            character.HumanoidRootPart.CFrame = savedPosition
        end
    end)
end

-- No Slowdown
function Killer.EnableNoSlowdown()
    if Nexus.States.NoSlowdownEnabled then return end
    Nexus.States.NoSlowdownEnabled = true
    
    local originalSpeed = 16
    
    local function GetRole()
        if not Nexus.Player.Team then return "Survivor" end
        local teamName = Nexus.Player.Team.Name:lower()
        if teamName:find("killer") then 
            return "Killer" 
        end
        return "Survivor"
    end
    
    local character = Nexus.getCharacter()
    local humanoid = Nexus.getHumanoid()
    if humanoid then
        originalSpeed = humanoid.WalkSpeed
    end
    
    Killer.Connections.NoSlowdown = Nexus.Services.RunService.Heartbeat:Connect(function()
        if not Nexus.States.NoSlowdownEnabled then 
            if Killer.Connections.NoSlowdown then
                Killer.Connections.NoSlowdown:Disconnect()
                Killer.Connections.NoSlowdown = nil
            end
            return 
        end
        
        if GetRole() ~= "Killer" then 
            return 
        end
        
        local char = Nexus.getCharacter()
        if not char then return end
        
        local hum = Nexus.getHumanoid()
        if not hum then return end
        
        if hum.WalkSpeed < 16 then
            hum.WalkSpeed = originalSpeed or 16
        end
    end)
    
    Nexus.Player.CharacterAdded:Connect(function(newChar)
        if Nexus.States.NoSlowdownEnabled then
            task.wait(1)
            local newHumanoid = newChar:FindFirstChildOfClass("Humanoid")
            if newHumanoid then
                originalSpeed = newHumanoid.WalkSpeed
            end
        end
    end)
    
    print("NoSlowdown Enabled (Killer Only)")
end

function Killer.DisableNoSlowdown()
    if not Nexus.States.NoSlowdownEnabled then return end
    Nexus.States.NoSlowdownEnabled = false
    
    if Killer.Connections.NoSlowdown then
        Nexus.safeDisconnect(Killer.Connections.NoSlowdown)
        Killer.Connections.NoSlowdown = nil
    end
    
    local humanoid = Nexus.getHumanoid()
    if humanoid then
        humanoid.WalkSpeed = 16
    end
    
    print("NoSlowdown Disabled")
end

-- Break Generator
function Killer.ToggleBreakGenerator(enabled)
    Nexus.States.BreakGeneratorEnabled = enabled
    
    if enabled then
        Nexus.Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not gameProcessed and input.KeyCode == Enum.KeyCode.Space then
                if Nexus.States.BreakGeneratorEnabled then
                    Killer.SpamGeneratorBreak()
                end
            end
        end)
    end
end

function Killer.FullGeneratorBreak()
    if not Killer.IsKiller() then return end
    
    local nearestGenerator, distance = Killer.FindNearestGenerator(10)
    if not nearestGenerator then return end
    
    local progress = Killer.getGeneratorProgress(nearestGenerator)
    if progress <= 0 then return end
    
    local BreakGenEvent = Nexus.Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Generator"):WaitForChild("BreakGenEvent")
    local hitBox = nearestGenerator:FindFirstChild("HitBox")
    
    if hitBox then
        BreakGenEvent:FireServer(hitBox, 0, true)
        return true
    end
    
    return false
end

function Killer.SpamGeneratorBreak()
    local spamInProgress = false
    local maxSpamCount = 1000
    
    if spamInProgress then return end
    
    if not Killer.IsKiller() then return end
    if not Nexus.Player.Character then return end
    
    local nearestGenerator = Killer.FindNearestGenerator(10)
    if not nearestGenerator then return end
    
    spamInProgress = true
    local spamCount = 0
    
    local connection
    connection = Nexus.Services.RunService.Heartbeat:Connect(function()
        if not spamInProgress then
            if connection then connection:Disconnect() end
            return
        end
        
        if not Killer.IsKiller() or not Nexus.Player.Character then
            spamInProgress = false
            if connection then connection:Disconnect() end
            return
        end
        
        local currentGenerator = Killer.FindNearestGenerator(10)
        if not currentGenerator then
            spamInProgress = false
            if connection then connection:Disconnect() end
            return
        end
        
        local progress = Killer.getGeneratorProgress(currentGenerator)
        if progress <= 0 then
            spamInProgress = false
            if connection then connection:Disconnect() end
            return
        end
        
        local hitBox = currentGenerator:FindFirstChild("HitBox")
        if hitBox then
            local BreakGenEvent = Nexus.Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Generator"):WaitForChild("BreakGenEvent")
            BreakGenEvent:FireServer(hitBox, 0, true)
            spamCount = spamCount + 1
            
            if spamCount >= maxSpamCount then
                spamInProgress = false
                if connection then connection:Disconnect() end
                return
            end
        else
            spamInProgress = false
            if connection then connection:Disconnect() end
            return
        end
    end)
    
    local stopConnection
    stopConnection = Nexus.Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.Space then
            if spamInProgress then
                spamInProgress = false
                if connection then connection:Disconnect() end
                if stopConnection then stopConnection:Disconnect() end
            end
        end
    end)
end

function Killer.IsKiller()
    if not Nexus.Player.Team then return false end
    local teamName = Nexus.Player.Team.Name:lower()
    return teamName:find("killer") or teamName == "killer"
end

function Killer.FindNearestGenerator(maxDistance)
    local character = Nexus.getCharacter()
    if not character then return nil end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end
    
    local playerPosition = humanoidRootPart.Position
    local nearestGenerator = nil
    local nearestDistance = math.huge
    
    for _, obj in ipairs(Nexus.Services.Workspace:GetDescendants()) do
        if obj.Name == "Generator" then
            local hitBox = obj:FindFirstChild("HitBox")
            if hitBox then
                local distance = (hitBox.Position - playerPosition).Magnitude
                if distance < nearestDistance and distance <= maxDistance then
                    nearestDistance = distance
                    nearestGenerator = obj
                end
            end
        end
    end
    
    return nearestGenerator, nearestDistance
end

function Killer.getGeneratorProgress(gen)
    local progress = 0
    if gen:GetAttribute("Progress") then
        progress = gen:GetAttribute("Progress")
    elseif gen:GetAttribute("RepairProgress") then
        progress = gen:GetAttribute("RepairProgress")
    else
        for _, child in ipairs(gen:GetDescendants()) do
            if child:IsA("NumberValue") or child:IsA("IntValue") then
                local n = child.Name:lower()
                if n:find("progress") or n:find("repair") or n:find("percent") then
                    progress = child.Value
                    break
                end
            end
        end
    end
    progress = (progress > 1) and progress / 100 or progress
    return math.clamp(progress, 0, 1)
end

-- Abysswalker Corrupt
function Killer.ActivateAbysswalkerCorrupt()
    local success, result = pcall(function()
        local CorruptRemote = Nexus.Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Killers"):WaitForChild("Abysswalker"):WaitForChild("corrupt")
        
        if not Nexus.Player.Team or Nexus.Player.Team.Name ~= "Killer" then
            return false
        end
        
        CorruptRemote:FireServer()
        return true
    end)
    
    if success and result then
        print("Abysswalker corrupt activated")
    else
        print("Failed to activate Abysswalker corrupt")
    end
end

-- Anti Blind
function Killer.EnableAntiBlind()
    if Nexus.States.KillerAntiBlindEnabled then return end
    Nexus.States.KillerAntiBlindEnabled = true
    
    local isAntiBlindEnabled = true
    local hookedRemotes = {}

    local function findFlashlightRemote()
        local ReplicatedStorage = Nexus.Services.ReplicatedStorage
        local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
        
        if remotes then
            local items = remotes:FindFirstChild("Items")
            if items then
                local flashlight = items:FindFirstChild("Flashlight")
                if flashlight then
                    local gotBlinded = flashlight:FindFirstChild("GotBlinded")
                    if gotBlinded and gotBlinded:IsA("RemoteEvent") then
                        return gotBlinded
                    end
                    
                    for _, child in ipairs(flashlight:GetChildren()) do
                        if child:IsA("RemoteEvent") and (child.Name:lower():find("blind") or child.Name:lower():find("flash")) then
                            return child
                        end
                    end
                end
            end
            
            local attacks = remotes:FindFirstChild("Attacks")
            if attacks then
                for _, child in ipairs(attacks:GetDescendants()) do
                    if child:IsA("RemoteEvent") and child.Name:lower():find("blind") then
                        return child
                    end
                end
            end
        end
        
        for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
            if remote:IsA("RemoteEvent") and (remote.Name:lower():find("blind") or remote.Name:lower():find("flashlight")) then
                return remote
            end
        end
        
        return nil
    end

    local function hookRemoteEvent(remote)
        if hookedRemotes[remote] then return end
        
        local originalFireServer = remote.FireServer
        local originalOnClientEvent = remote.OnClientEvent
        
        remote.FireServer = function(self, ...)
            if isAntiBlindEnabled then
                print("AntiBlind blocked: " .. self.Name)
                return nil
            end
            return originalFireServer(self, ...)
        end
        
        if remote:IsA("RemoteEvent") then
            remote.OnClientEvent = function(self, ...)
                if isAntiBlindEnabled then
                    print("AntiBlind blocked: " .. self.Name)
                    return nil
                end
                return originalOnClientEvent(self, ...)
            end
        end
        
        hookedRemotes[remote] = true
        print("AntiBlind hooked: " .. remote:GetFullName())
    end

    local function setupAntiBlind()
        local flashlightRemote = findFlashlightRemote()
        
        if flashlightRemote then
            hookRemoteEvent(flashlightRemote)
            return true
        else
            return false
        end
    end

    setupAntiBlind()
    
    task.spawn(function()
        for i = 1, 5 do
            task.wait(2)
            if isAntiBlindEnabled then
                setupAntiBlind()
            end
        end
    end)
    
    print("AntiBlind Enabled")
end

function Killer.DisableAntiBlind()
    if not Nexus.States.KillerAntiBlindEnabled then return end
    Nexus.States.KillerAntiBlindEnabled = false
    
    print("AntiBlind: Disabled")
end

-- Mask Powers
function Killer.ActivateMaskPower(maskName)
    local success, result = pcall(function()
        local remotes = Nexus.Services.ReplicatedStorage:WaitForChild("Remotes")
        local killers = remotes:WaitForChild("Killers")
        local masked = killers:WaitForChild("Masked")
        local activatePower = masked:WaitForChild("Activatepower")
        
        if not Nexus.Player.Team or Nexus.Player.Team.Name ~= "Killer" then
            return false
        end
        
        activatePower:FireServer(maskName)
        return true
    end)
    
    if success and result then
        print("Mask power activated: " .. maskName)
    else
        print("Failed to activate mask power: " .. maskName)
    end
    
    return success and result
end

function Killer.Cleanup()
    -- Очистка всех соединений
    for key, connection in pairs(Killer.Connections) do
        Nexus.safeDisconnect(connection)
    end
    Killer.Connections = {}
end

return Killer
