-- Movement.lua - Модуль для функций движения
local Nexus = require(script.Parent.NexusMain)

local MovementModule = {}

function MovementModule.Initialize(nexus)
    local Tabs = nexus.Tabs
    local Options = nexus.Options
    local SafeCallback = nexus.SafeCallback
    
    local player = nexus.Player
    local UserInputService = nexus.Services.UserInputService
    local RunService = nexus.Services.RunService
    local Workspace = nexus.Services.Workspace
    local TweenService = nexus.Services.TweenService
    local camera = nexus.Camera
    
    -- ========== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ==========
    local function getCharacter()
        return player.Character
    end
    
    local function getHumanoid()
        local char = getCharacter()
        return char and char:FindFirstChildOfClass("Humanoid")
    end
    
    local function getRootPart()
        local char = getCharacter()
        return char and char:FindFirstChild("HumanoidRootPart")
    end
    
    -- ========== TELEPORT ФУНКЦИИ ==========
    local function findRootForDesc(desc)
        if not desc then return nil end
        if desc:IsA("BasePart") or desc:IsA("MeshPart") then
            return desc
        end
        if desc:IsA("Model") then
            return desc.PrimaryPart or desc:FindFirstChildWhichIsA("BasePart") or desc:FindFirstChildWhichIsA("MeshPart")
        end
        return nil
    end

    local generatorNames = {
        ["generator"] = true,
        ["generator_old"] = true,
        ["gene"] = true
    }
    local hookNames = {
        ["hookpoint"] = true,
        ["hook"] = true,
        ["hookmeat"] = true
    }

    local generatorPrefix = "ge"
    local hookPrefix = "ho"

    local function collectGenerators()
        local matches = {}
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("Model") then
                local nameLower = string.lower(obj.Name)
                if generatorNames[nameLower] or string.sub(nameLower, 1, #generatorPrefix) == generatorPrefix then
                    local root = findRootForDesc(obj) or obj
                    if root and root.Parent then
                        table.insert(matches, root)
                    end
                end
            end
        end
        return matches
    end

    local function collectHooks()
        local matches = {}
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("Model") then
                local nameLower = string.lower(obj.Name)
                if hookNames[nameLower] or string.sub(nameLower, 1, #hookPrefix) == hookPrefix then
                    local root = findRootForDesc(obj) or obj
                    if root and root.Parent then
                        table.insert(matches, root)
                    end
                end
            end
        end
        return matches
    end

    local function collectPlayers()
        local pool = {}
        for _, pl in ipairs(game:GetService("Players"):GetPlayers()) do
            if pl ~= player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(pool, pl)
            end
        end
        return pool
    end

    local function safeTeleportTo(part)
        local char = player.Character
        if not char or not part then return false end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        
        if not part or not part.Parent then return false end
        
        SafeCallback(function()
            hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
        end)
        return true
    end

    local function teleportToRandomGenerator()
        local matches = collectGenerators()
        if #matches > 0 then 
            return safeTeleportTo(matches[math.random(1, #matches)])
        end
        return false
    end

    local function teleportToRandomHook()
        local matches = collectHooks()
        if #matches > 0 then 
            return safeTeleportTo(matches[math.random(1, #matches)])
        end
        return false
    end

    local function teleportToRandomPlayer()
        local pool = collectPlayers()
        if #pool > 0 then
            local target = pool[math.random(1, #pool)]
            local hrp = target.Character:FindFirstChild("HumanoidRootPart")
            if hrp then return safeTeleportTo(hrp) end
        end
        return false
    end

    local function teleportToNearestGenerator()
        local matches = collectGenerators()
        if #matches == 0 then return false end
        
        local char = player.Character
        if not char then return false end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        
        local nearestGenerator = nil
        local nearestDistance = math.huge
        
        for _, generator in ipairs(matches) do
            local distance = (hrp.Position - generator.Position).Magnitude
            if distance < nearestDistance then
                nearestDistance = distance
                nearestGenerator = generator
            end
        end
        
        if nearestGenerator then
            return safeTeleportTo(nearestGenerator)
        end
        return false
    end

    local function teleportToNearestPlayer()
        local pool = collectPlayers()
        if #pool == 0 then return false end
        
        local char = player.Character
        if not char then return false end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        
        local nearestPlayer = nil
        local nearestDistance = math.huge
        
        for _, target in ipairs(pool) do
            if target.Character then
                local targetHrp = target.Character:FindFirstChild("HumanoidRootPart")
                if targetHrp then
                    local distance = (hrp.Position - targetHrp.Position).Magnitude
                    if distance < nearestDistance then
                        nearestDistance = distance
                        nearestPlayer = target
                    end
                end
            end
        end
        
        if nearestPlayer and nearestPlayer.Character then
            local targetHrp = nearestPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetHrp then
                return safeTeleportTo(targetHrp)
            end
        end
        return false
    end
    
    -- ========== WalkSpeed ФУНКЦИЯ ==========
    local WalkSpeed = (function()
        local WALKSPEED_ENABLED = false
        local currentSpeed = 50
        local speedConnection = nil
        
        local function EnableWalkSpeed()
            if WALKSPEED_ENABLED then return end
            
            WALKSPEED_ENABLED = true
            nexus.FunctionStates.WalkSpeedEnabled = true
            
            speedConnection = RunService.Heartbeat:Connect(function()
                if not WALKSPEED_ENABLED or not player.Character then
                    if speedConnection then
                        speedConnection:Disconnect()
                        speedConnection = nil
                    end
                    return
                end
                
                local character = player.Character
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if not rootPart then return end
                
                local direction = Vector3.new(0, 0, 0)
                local camera = Workspace.CurrentCamera
                
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    direction = direction + camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    direction = direction - camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    direction = direction - camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    direction = direction + camera.CFrame.RightVector
                end
                
                if direction.Magnitude > 0 then
                    direction = direction.Unit
                    local velocity = direction * currentSpeed
                    rootPart.Velocity = Vector3.new(velocity.X, rootPart.Velocity.Y, velocity.Z)
                end
            end)
        end
        
        local function DisableWalkSpeed()
            if not WALKSPEED_ENABLED then return end
            
            WALKSPEED_ENABLED = false
            nexus.FunctionStates.WalkSpeedEnabled = false
            
            if speedConnection then
                SafeCallback(function() speedConnection:Disconnect() end)
                speedConnection = nil
            end
        end
        
        local function SetSpeed(speed)
            currentSpeed = tonumber(speed) or 50
        end
        
        return {
            Enable = EnableWalkSpeed,
            Disable = DisableWalkSpeed,
            SetSpeed = SetSpeed,
            IsEnabled = function() return WALKSPEED_ENABLED end,
            GetSpeed = function() return currentSpeed end
        }
    end)()
    
    -- ========== NoClip ФУНКЦИЯ ==========
    local NoClip = (function()
        local noclipEnabled = false
        local noclipConnection = nil
        local originalCollisions = {}

        local function saveOriginalCollisions(character)
            if not character then return end
            
            originalCollisions = {}
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then 
                    originalCollisions[part] = part.CanCollide
                end
            end
        end

        local function restoreOriginalCollisions(character)
            if not character then return end
            
            for part, canCollide in pairs(originalCollisions) do
                if part and part.Parent then
                    SafeCallback(function()
                        part.CanCollide = canCollide
                    end)
                end
            end
            originalCollisions = {}
        end

        local function EnableNoClip()
            if noclipEnabled then return end
            noclipEnabled = true
            nexus.FunctionStates.noclipEnabled = true
            print("NoClip Enabled")
            
            local character = getCharacter()
            if character then
                saveOriginalCollisions(character)
            end
            
            noclipConnection = RunService.Stepped:Connect(function()
                if not noclipEnabled or not getCharacter() then 
                    if noclipConnection then
                        noclipConnection:Disconnect()
                        noclipConnection = nil
                    end
                    return 
                end
                
                local character = getCharacter()
                if character then
                    for _, part in ipairs(character:GetDescendants()) do
                        if part:IsA("BasePart") then 
                            SafeCallback(function()
                                part.CanCollide = false
                            end)
                        end
                    end
                end
            end)
            
            player.CharacterAdded:Connect(function(newChar)
                if noclipEnabled then
                    task.wait(1)
                    saveOriginalCollisions(newChar)
                    print("NoClip applied to new character")
                end
            end)
        end

        local function DisableNoClip()
            if not noclipEnabled then return end
            
            noclipEnabled = false
            nexus.FunctionStates.noclipEnabled = false
            print("NoClip Disabled")
            
            if noclipConnection then
                noclipConnection:Disconnect()
                noclipConnection = nil
            end
            
            local character = getCharacter()
            if character then
                restoreOriginalCollisions(character)
            end
        end

        return {
            Enable = EnableNoClip,
            Disable = DisableNoClip,
            IsEnabled = function() return noclipEnabled end
        }
    end)()
    
    -- ========== Infinite Lunge ФУНКЦИЯ ==========
    local InfiniteLunge = (function()
        local isLunging = false
        local lungeSpeed = 50
        local lungeConnection = nil
        
        local function EnableInfiniteLunge()
            if nexus.FunctionStates.InfiniteLungeEnabled then return end
            nexus.FunctionStates.InfiniteLungeEnabled = true
            print("Infinite Lunge Enabled")
        end
        
        local function DisableInfiniteLunge()
            nexus.FunctionStates.InfiniteLungeEnabled = false
            isLunging = false
            
            if lungeConnection then
                lungeConnection:Disconnect()
                lungeConnection = nil
            end
        end
        
        local function HandleInput(input, gameProcessed)
            if gameProcessed or not nexus.FunctionStates.InfiniteLungeEnabled then
                return
            end
            
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                if input.UserInputState == Enum.UserInputState.Begin then
                    isLunging = true
                    print("Lunge started")
                    if player.Character then
                        if lungeConnection then
                            lungeConnection:Disconnect()
                        end
                        
                        lungeConnection = RunService.Heartbeat:Connect(function()
                            if not nexus.FunctionStates.InfiniteLungeEnabled or not isLunging or not player.Character then
                                if lungeConnection then
                                    lungeConnection:Disconnect()
                                    lungeConnection = nil
                                end
                                return
                            end
                            
                            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                            
                            if rootPart then
                                local lookVector = rootPart.CFrame.LookVector
                                local velocity = lookVector * lungeSpeed
                                
                                rootPart.Velocity = Vector3.new(velocity.X, rootPart.Velocity.Y, velocity.Z)
                            end
                        end)
                    end
                    
                elseif input.UserInputState == Enum.UserInputState.End then
                    isLunging = false
                    print("Lunge stopped")
                    if lungeConnection then
                        lungeConnection:Disconnect()
                        lungeConnection = nil
                    end
                end
            end
        end
        

        local inputBeganConn = UserInputService.InputBegan:Connect(HandleInput)
        local inputEndedConn = UserInputService.InputEnded:Connect(HandleInput)

        nexus.Connections.InfiniteLungeBegan = inputBeganConn
        nexus.Connections.InfiniteLungeEnded = inputEndedConn
        
        return {
            Enable = EnableInfiniteLunge,
            Disable = DisableInfiniteLunge,
            SetSpeed = function(speed) 
                lungeSpeed = speed 
                print("Lunge speed set to: " .. speed)
            end,
            IsEnabled = function() return nexus.FunctionStates.InfiniteLungeEnabled end
        }
    end)()
    
    -- ========== FLY ФУНКЦИИ ==========
    local flying = false
    local flySpeed = 50
    local bodyVelocity, bodyGyro = nil, nil

    local function enableFly()
        if flying then return end
        flying = true
        nexus.FunctionStates.FlyEnabled = true
        
        local character, humanoid, rootPart = getCharacter(), getHumanoid(), getRootPart()
        if not character or not humanoid or not rootPart then return end
        
        humanoid.PlatformStand = true
        bodyVelocity, bodyGyro = Instance.new("BodyVelocity"), Instance.new("BodyGyro")
        bodyVelocity.Velocity, bodyVelocity.MaxForce, bodyVelocity.Parent = Vector3.new(0, 0, 0), Vector3.new(math.huge, math.huge, math.huge), rootPart
        bodyGyro.MaxTorque, bodyGyro.P, bodyGyro.D, bodyGyro.CFrame, bodyGyro.Parent = Vector3.new(math.huge, math.huge, math.huge), 10000, 500, rootPart.CFrame, rootPart

        nexus.Connections.flyLoop = RunService.Heartbeat:Connect(function()
            if not flying or not bodyVelocity or not bodyGyro or not character or not humanoid or not rootPart then
                if nexus.Connections.flyLoop then
                    nexus.Connections.flyLoop:Disconnect()
                    nexus.Connections.flyLoop = nil
                end
                return
            end
            
            local camera, direction = Workspace.CurrentCamera, Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction = direction + camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction = direction - camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction = direction - camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction = direction + camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction = direction + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then direction = direction + Vector3.new(0, -1, 0) end

            if direction.Magnitude > 0 then direction = direction.Unit * flySpeed end
            if bodyVelocity then bodyVelocity.Velocity = direction end
            if bodyGyro then bodyGyro.CFrame = CFrame.new(rootPart.Position, rootPart.Position + camera.CFrame.LookVector) end
        end)
    end

    local function disableFly()
        if not flying then return end
        flying = false
        nexus.FunctionStates.FlyEnabled = false
        if bodyVelocity then bodyVelocity:Destroy(); bodyVelocity = nil end
        if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
        local character, humanoid = getCharacter(), getHumanoid()
        if humanoid then humanoid.PlatformStand = false end
        
        if nexus.Connections.flyLoop then
            nexus.Connections.flyLoop:Disconnect()
            nexus.Connections.flyLoop = nil
        end
    end
    
    -- ========== FREE CAMERA ФУНКЦИИ ==========
    local freeCameraEnabled = false
    local freeCameraSpeed = 50
    local freeCameraConnection = nil
    local originalCameraType, originalCameraSubject, mouseLocked = camera.CameraType, camera.CameraSubject, false

    local function lockMouse()
        if not freeCameraEnabled then return end
        mouseLocked = true
        UserInputService.MouseBehavior, UserInputService.MouseIconEnabled = Enum.MouseBehavior.LockCenter, false
    end

    local function unlockMouse()
        mouseLocked = false
        UserInputService.MouseBehavior, UserInputService.MouseIconEnabled = Enum.MouseBehavior.Default, true
    end

    local function startFreeCamera()
        if freeCameraEnabled then return end
        freeCameraEnabled = true
        nexus.FunctionStates.FreeCameraEnabled = true
        originalCameraType, originalCameraSubject = camera.CameraType, camera.CameraSubject
        camera.CameraType = Enum.CameraType.Scriptable
        
        local cameraPosition, cameraRotation = camera.CFrame.Position, Vector2.new(0, 0)
        local lookVector = camera.CFrame.LookVector
        cameraRotation = Vector2.new(math.atan2(lookVector.X, lookVector.Z), math.asin(lookVector.Y))
        
        lockMouse()
        
        if getCharacter() then
            local humanoid, rootPart = getHumanoid(), getRootPart()
            if humanoid then humanoid.PlatformStand, humanoid.AutoRotate = false, false end
            if rootPart then rootPart.Anchored = true end
        end
        
        freeCameraConnection = RunService.RenderStepped:Connect(function(delta)
            if not freeCameraEnabled then 
                if freeCameraConnection then
                    freeCameraConnection:Disconnect()
                    freeCameraConnection = nil
                end
                return 
            end
            
            local mouseDelta = UserInputService:GetMouseDelta()
            cameraRotation = cameraRotation + Vector2.new(-mouseDelta.X * 0.003, -mouseDelta.Y * 0.003)
            cameraRotation = Vector2.new(cameraRotation.X, math.clamp(cameraRotation.Y, -math.pi/2 + 0.1, math.pi/2 - 0.1))
            
            local rotationCFrame = CFrame.Angles(0, cameraRotation.X, 0) * CFrame.Angles(cameraRotation.Y, 0, 0)
            local moveDirection = Vector3.new(0, 0, 0)
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + rotationCFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - rotationCFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - rotationCFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + rotationCFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.E) or UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveDirection = moveDirection + Vector3.new(0, -1, 0) end
            
            if moveDirection.Magnitude > 0 then moveDirection = moveDirection.Unit * freeCameraSpeed; cameraPosition = cameraPosition + moveDirection * delta end
            camera.CFrame = CFrame.new(cameraPosition) * rotationCFrame
        end)
    end

    local function stopFreeCamera()
        if not freeCameraEnabled then return end
        freeCameraEnabled = false
        nexus.FunctionStates.FreeCameraEnabled = false
        unlockMouse()
        
        if freeCameraConnection then
            freeCameraConnection:Disconnect()
            freeCameraConnection = nil
        end
        
        camera.CameraType, camera.CameraSubject = originalCameraType, originalCameraSubject
        
        if getCharacter() then
            local humanoid, rootPart = getHumanoid(), getRootPart()
            if humanoid then humanoid.PlatformStand, humanoid.AutoRotate = false, true end
            if rootPart then rootPart.Anchored = false end
        end
    end
    
    -- ========== FOV CHANGER ==========
    local FOVSettings = {
        Enabled = false,
        Value = 95,
        TargetValue = 95,
        TweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        CurrentTween = nil
    }

    local function ApplyFOV()
        if camera and FOVSettings.Enabled then
            FOVSettings.TargetValue = FOVSettings.Value
            
            if FOVSettings.CurrentTween then
                FOVSettings.CurrentTween:Cancel()
            end
            
            FOVSettings.CurrentTween = TweenService:Create(camera, FOVSettings.TweenInfo, {FieldOfView = FOVSettings.TargetValue})
            FOVSettings.CurrentTween:Play()
        elseif camera then
            if FOVSettings.CurrentTween then
                FOVSettings.CurrentTween:Cancel()
                FOVSettings.CurrentTween = nil
            end
            camera.FieldOfView = 70
        end
    end

    Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        task.wait(0.1)
        camera = Workspace.CurrentCamera
        ApplyFOV()
    end)

    if RunService.RenderStepped then
        nexus.Connections.FOVUpdater = RunService.RenderStepped:Connect(function()
            if FOVSettings.Enabled and camera and math.abs(camera.FieldOfView - FOVSettings.TargetValue) > 0.1 then
                ApplyFOV()
            end
        end)
    end
    
    -- ========== СОЗДАНИЕ ЭЛЕМЕНТОВ ИНТЕРФЕЙСА ==========
    
    -- Телепортационные кнопки
    Tabs.Movement:AddButton({
        Title = "Teleport to Random Generator", 
        Description = "Teleport to a random generator on the map",
        Callback = function()
            SafeCallback(function()
                teleportToRandomGenerator()
            end)
        end
    })

    Tabs.Movement:AddButton({
        Title = "Teleport to Random Hook", 
        Description = "Teleport to a random hook on the map",
        Callback = function()
            SafeCallback(function()
                teleportToRandomHook()
            end)
        end
    })

    Tabs.Movement:AddButton({
        Title = "Teleport to Random Player", 
        Description = "Teleport to a random player on the map",
        Callback = function()
            SafeCallback(function()
                teleportToRandomPlayer()
            end)
        end
    })

    Tabs.Movement:AddButton({
        Title = "Teleport to Nearest Generator", 
        Description = "Teleport to the closest generator",
        Callback = function()
            SafeCallback(function()
                teleportToNearestGenerator()
            end)
        end
    })

    Tabs.Movement:AddButton({
        Title = "Teleport to Nearest Player", 
        Description = "Teleport to the closest player",
        Callback = function()
            SafeCallback(function()
                teleportToNearestPlayer()
            end)
        end
    })

    -- Infinite Lunge (только для десктопа)
    if nexus.IS_DESKTOP then
        local InfiniteLungeToggle = Tabs.Movement:AddToggle("InfiniteLunge", {
            Title = "Infinite Lunge", 
            Description = "Hold LMB to lunge forward", 
            Default = false
        })

        InfiniteLungeToggle:OnChanged(function(v) 
            SafeCallback(function()
                if v then 
                    InfiniteLunge.Enable() 
                else 
                    InfiniteLunge.Disable() 
                end 
            end)
        end)

        local LungeSpeedSlider = Tabs.Movement:AddSlider("LungeSpeed", {
            Title = "Lunge Speed", 
            Description = "", 
            Default = 50, 
            Min = 10, 
            Max = 200, 
            Rounding = 0, 
            Callback = function(value) 
                SafeCallback(function()
                    InfiniteLunge.SetSpeed(value)
                end)
            end
        })
    end

    -- Walk Speed
    local WalkSpeedToggle = Tabs.Movement:AddToggle("WalkSpeed", {
        Title = "Walk Speed", 
        Description = "", 
        Default = false
    })

    WalkSpeedToggle:OnChanged(function(v) 
        SafeCallback(function()
            if v then 
                WalkSpeed.Enable() 
            else 
                WalkSpeed.Disable() 
            end 
        end)
    end)

    local WalkSpeedSlider = Tabs.Movement:AddSlider("WalkSpeedValue", {
        Title = "Walk Speed Value", 
        Description = "0-200", 
        Default = 16, 
        Min = 0, 
        Max = 200, 
        Rounding = 0, 
        Callback = function(value) 
            SafeCallback(function()
                WalkSpeed.SetSpeed(value)
            end)
        end
    })

    -- Noclip
    local NoclipToggle = Tabs.Movement:AddToggle("Noclip", {
        Title = "Noclip",
        Description = "",
        Default = false
    })

    NoclipToggle:OnChanged(function(value)
        SafeCallback(function()
            if value then 
                NoClip.Enable() 
            else 
                NoClip.Disable()
            end 
        end)
    end)

    -- FOV Changer
    local FOVToggle = Tabs.Movement:AddToggle("FOVChanger", {
        Title = "FOV Changer", 
        Description = "", 
        Default = false
    })

    FOVToggle:OnChanged(function(v)
        SafeCallback(function()
            FOVSettings.Enabled = v
            ApplyFOV()
        end)
    end)

    local FOVSlider = Tabs.Movement:AddSlider("FOVValue", {
        Title = "FOV Value", 
        Description = "0-120",
        Default = 95,
        Min = 0,
        Max = 120,
        Rounding = 0,
        Callback = function(value)
            SafeCallback(function()
                FOVSettings.Value = value
                ApplyFOV()
            end)
        end
    })

    -- Fly (только для десктопа)
    if nexus.IS_DESKTOP then
        local FlyToggle = Tabs.Movement:AddToggle("Fly", {
            Title = "Fly", 
            Description = "Allows flying in any direction", 
            Default = false
        })

        FlyToggle:OnChanged(function(value) 
            SafeCallback(function()
                if value then 
                    enableFly() 
                else 
                    disableFly() 
                end 
            end)
        end)

        local FlySpeedSlider = Tabs.Movement:AddSlider("FlySpeed", {
            Title = "Fly Speed", 
            Description = "0-200", 
            Default = 50, 
            Min = 0, 
            Max = 200, 
            Rounding = 0, 
            Callback = function(value) 
                SafeCallback(function()
                    flySpeed = value
                end)
            end
        })

        -- Free Camera
        local FreeCameraToggle = Tabs.Movement:AddToggle("FreeCamera", {
            Title = "Free Camera", 
            Description = "", 
            Default = false
        })

        FreeCameraToggle:OnChanged(function(value) 
            SafeCallback(function()
                if value then 
                    startFreeCamera() 
                else 
                    stopFreeCamera() 
                end 
            end)
        end)

        local FreeCameraSpeedSlider = Tabs.Movement:AddSlider("FreeCameraSpeed", {
            Title = "Free Camera Speed", 
            Description = "0-100", 
            Default = 50, 
            Min = 0, 
            Max = 100, 
            Rounding = 0, 
            Callback = function(value) 
                SafeCallback(function()
                    freeCameraSpeed = value
                end)
            end
        })
    end
    
    -- Сохраняем функции в Nexus
    nexus.Functions.WalkSpeed = WalkSpeed
    nexus.Functions.NoClip = NoClip
    nexus.Functions.InfiniteLunge = InfiniteLunge
    nexus.Functions.enableFly = enableFly
    nexus.Functions.disableFly = disableFly
    nexus.Functions.startFreeCamera = startFreeCamera
    nexus.Functions.stopFreeCamera = stopFreeCamera
    nexus.Functions.FOVSettings = FOVSettings
    nexus.Functions.ApplyFOV = ApplyFOV
    
    return MovementModule
end

return MovementModule
