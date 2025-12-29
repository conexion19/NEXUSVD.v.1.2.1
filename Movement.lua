local Nexus = _G.Nexus

local Movement = {
    Connections = {},
    States = {},
    Objects = {}
}

-- ========== UTILITY FUNCTIONS ==========

local function setupCharacterListener(callback)
    -- Отслеживаем появление нового персонажа
    local charAddedConn = Nexus.Player.CharacterAdded:Connect(function(character)
        task.wait(0.5) -- Ждем загрузку персонажа
        callback(character)
    end)
    
    -- Первоначальный вызов если есть персонаж
    local currentChar = Nexus.getCharacter()
    if currentChar then
        task.spawn(function()
            task.wait(0.5)
            callback(currentChar)
        end)
    end
    
    return charAddedConn
end

-- ========== INFINITE LUNGE ==========

local InfiniteLunge = (function()
    local enabled = false
    local characterListeners = {}
    
    local function updateInfiniteLunge()
        if enabled then
            local character = Nexus.getCharacter()
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    -- Проверяем, не ползет ли персонаж
                    local state = humanoid:GetState()
                    local isCrawling = state == Enum.HumanoidStateType.FallingDown or 
                                      state == Enum.HumanoidStateType.GettingUp or
                                      state == Enum.HumanoidStateType.Freefall
                    
                    if not isCrawling then
                        humanoid:SetAttribute("InfiniteLunge", true)
                        humanoid.WalkSpeed = 28  -- Увеличиваем скорость для бесконечного рывка
                    else
                        humanoid:SetAttribute("InfiniteLunge", nil)
                    end
                end
            end
            print("Infinite Lunge: Activated")
        else
            local character = Nexus.getCharacter()
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:SetAttribute("InfiniteLunge", nil)
                    -- Не сбрасываем скорость, игра сама восстановит
                end
            end
        end
    end
    
    local function setupInfiniteLungeForCharacter(character)
        if not enabled then return end
        
        task.wait(1) -- Ждем полной инициализации персонажа
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            -- Устанавливаем скорость
            humanoid:SetAttribute("InfiniteLunge", true)
            humanoid.WalkSpeed = 28
            
            -- Отслеживаем изменения скорости
            humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                if enabled and humanoid.WalkSpeed ~= 28 then
                    task.wait(0.1)
                    humanoid.WalkSpeed = 28
                end
            end)
            
            -- Отслеживаем смерть
            humanoid.Died:Connect(function()
                if enabled then
                    task.wait(2) -- Ждем респавна
                    if Nexus.getCharacter() then
                        setupInfiniteLungeForCharacter(Nexus.getCharacter())
                    end
                end
            end)
        end
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Nexus.States.InfiniteLungeEnabled = true
        print("Infinite Lunge: ON")
        
        -- Очищаем старые слушатели
        for _, listener in ipairs(characterListeners) do
            Nexus.safeDisconnect(listener)
        end
        characterListeners = {}
        
        -- Добавляем слушатель появления персонажа
        table.insert(characterListeners, setupCharacterListener(setupInfiniteLungeForCharacter))
        
        -- Инициализируем для текущего персонажа
        local currentChar = Nexus.getCharacter()
        if currentChar then
            setupInfiniteLungeForCharacter(currentChar)
        end
        
        -- Цикл обновления
        local updateConn = Nexus.Services.RunService.Heartbeat:Connect(updateInfiniteLunge)
        table.insert(characterListeners, updateConn)
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Nexus.States.InfiniteLungeEnabled = false
        print("Infinite Lunge: OFF")
        
        local character = Nexus.getCharacter()
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:SetAttribute("InfiniteLunge", nil)
            end
        end
        
        -- Очищаем слушатели
        for _, listener in ipairs(characterListeners) do
            Nexus.safeDisconnect(listener)
        end
        characterListeners = {}
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end
    }
end)()

-- ========== WALK SPEED ==========

local WalkSpeed = (function()
    local enabled = false
    local targetSpeed = 16
    local characterListeners = {}
    
    local function updateWalkSpeed()
        if enabled then
            local character = Nexus.getCharacter()
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    -- Проверяем, не ползет ли персонаж
                    local state = humanoid:GetState()
                    local isCrawling = state == Enum.HumanoidStateType.FallingDown or 
                                      state == Enum.HumanoidStateType.GettingUp or
                                      state == Enum.HumanoidStateType.Freefall
                    
                    if not isCrawling and humanoid.WalkSpeed ~= targetSpeed then
                        humanoid:SetAttribute("WalkSpeedBoost", true)
                        humanoid.WalkSpeed = targetSpeed
                    end
                end
            end
        else
            local character = Nexus.getCharacter()
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:SetAttribute("WalkSpeedBoost", nil)
                end
            end
        end
    end
    
    local function setupWalkSpeedForCharacter(character)
        if not enabled then return end
        
        task.wait(1) -- Ждем полной инициализации персонажа
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            -- Устанавливаем скорость
            humanoid:SetAttribute("WalkSpeedBoost", true)
            humanoid.WalkSpeed = targetSpeed
            
            -- Отслеживаем изменения скорости
            humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                if enabled and humanoid.WalkSpeed ~= targetSpeed then
                    task.wait(0.1)
                    humanoid.WalkSpeed = targetSpeed
                end
            end)
            
            -- Отслеживаем смерть
            humanoid.Died:Connect(function()
                if enabled then
                    task.wait(2) -- Ждем респавна
                    if Nexus.getCharacter() then
                        setupWalkSpeedForCharacter(Nexus.getCharacter())
                    end
                end
            end)
        end
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Nexus.States.WalkSpeedEnabled = true
        print("Walk Speed: ON (" .. targetSpeed .. ")")
        
        -- Очищаем старые слушатели
        for _, listener in ipairs(characterListeners) do
            Nexus.safeDisconnect(listener)
        end
        characterListeners = {}
        
        -- Добавляем слушатель появления персонажа
        table.insert(characterListeners, setupCharacterListener(setupWalkSpeedForCharacter))
        
        -- Инициализируем для текущего персонажа
        local currentChar = Nexus.getCharacter()
        if currentChar then
            setupWalkSpeedForCharacter(currentChar)
        end
        
        -- Цикл обновления
        local updateConn = Nexus.Services.RunService.Heartbeat:Connect(updateWalkSpeed)
        table.insert(characterListeners, updateConn)
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Nexus.States.WalkSpeedEnabled = false
        print("Walk Speed: OFF")
        
        local character = Nexus.getCharacter()
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:SetAttribute("WalkSpeedBoost", nil)
            end
        end
        
        -- Очищаем слушатели
        for _, listener in ipairs(characterListeners) do
            Nexus.safeDisconnect(listener)
        end
        characterListeners = {}
    end
    
    local function SetSpeed(speed)
        targetSpeed = math.clamp(speed, 16, 100)
        if enabled then
            print("Walk Speed set to: " .. targetSpeed)
            updateWalkSpeed()
        end
    end
    
    local function GetSpeed()
        return targetSpeed
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end,
        SetSpeed = SetSpeed,
        GetSpeed = GetSpeed
    }
end)()

-- ========== NOCLIP ==========

local Noclip = (function()
    local enabled = false
    local characterListeners = {}
    local noclipConnection = nil
    
    local function updateNoclip()
        if not enabled then return end
        
        local character = Nexus.getCharacter()
        if not character then return end
        
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
    
    local function setupNoclipForCharacter(character)
        if not enabled then return end
        
        task.wait(1) -- Ждем полной инициализации персонажа
        
        -- Отключаем коллизию для всех частей
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
        
        -- Отслеживаем новые части
        local function onDescendantAdded(descendant)
            if enabled and descendant:IsA("BasePart") then
                descendant.CanCollide = false
            end
        end
        
        local descendantConn = character.DescendantAdded:Connect(onDescendantAdded)
        
        -- Отслеживаем смерть
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Died:Connect(function()
                if enabled then
                    task.wait(2) -- Ждем респавна
                    if Nexus.getCharacter() then
                        setupNoclipForCharacter(Nexus.getCharacter())
                    end
                end
            end)
        end
        
        return descendantConn
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Nexus.States.NoclipEnabled = true
        print("Noclip: ON")
        
        -- Очищаем старые слушатели
        for _, listener in ipairs(characterListeners) do
            Nexus.safeDisconnect(listener)
        end
        characterListeners = {}
        
        -- Добавляем слушатель появления персонажа
        table.insert(characterListeners, setupCharacterListener(function(character)
            local descendantConn = setupNoclipForCharacter(character)
            if descendantConn then
                table.insert(characterListeners, descendantConn)
            end
        end))
        
        -- Инициализируем для текущего персонажа
        local currentChar = Nexus.getCharacter()
        if currentChar then
            local descendantConn = setupNoclipForCharacter(currentChar)
            if descendantConn then
                table.insert(characterListeners, descendantConn)
            end
        end
        
        -- Цикл обновления
        if noclipConnection then
            noclipConnection:Disconnect()
        end
        noclipConnection = Nexus.Services.RunService.Stepped:Connect(updateNoclip)
        table.insert(characterListeners, noclipConnection)
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Nexus.States.NoclipEnabled = false
        print("Noclip: OFF")
        
        -- Восстанавливаем коллизию
        local character = Nexus.getCharacter()
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
        
        -- Очищаем слушатели
        for _, listener in ipairs(characterListeners) do
            Nexus.safeDisconnect(listener)
        end
        characterListeners = {}
        
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end
    }
end)()

-- ========== FOV CHANGER ==========

local FOVChanger = (function()
    local enabled = false
    local targetFOV = 70
    local currentFOV = 70
    local smoothness = 0.3  -- Плавность изменения (0-1, меньше = плавнее)
    local characterListeners = {}
    local lastCamera = nil
    local isTransitioning = false
    
    local function lerp(a, b, t)
        return a + (b - a) * math.clamp(t, 0, 1)
    end
    
    local function updateFOV()
        if not enabled then return end
        
        local camera = Nexus.Services.Workspace.CurrentCamera
        if not camera then return end
        
        -- Проверяем, не изменилась ли камера (например, при переходе в другую игру)
        if lastCamera and lastCamera ~= camera then
            print("FOV Changer: Camera changed, resetting...")
            currentFOV = camera.FieldOfView
            lastCamera = camera
            isTransitioning = false
        elseif not lastCamera then
            lastCamera = camera
            currentFOV = camera.FieldOfView
        end
        
        -- Плавное изменение FOV
        if math.abs(currentFOV - targetFOV) > 0.5 then
            isTransitioning = true
            currentFOV = lerp(currentFOV, targetFOV, smoothness)
            camera.FieldOfView = currentFOV
        else
            if isTransitioning then
                currentFOV = targetFOV
                camera.FieldOfView = targetFOV
                isTransitioning = false
                print("FOV Changer: Transition completed")
            elseif camera.FieldOfView ~= targetFOV then
                camera.FieldOfView = targetFOV
                currentFOV = targetFOV
            end
        end
    end
    
    local function resetFOV()
        local camera = Nexus.Services.Workspace.CurrentCamera
        if camera then
            camera.FieldOfView = 70
            currentFOV = 70
            lastCamera = nil
            isTransitioning = false
        end
    end
    
    local function setupFOVForCharacter()
        if not enabled then return end
        
        task.wait(0.5) -- Ждем стабилизации камеры
        
        local camera = Nexus.Services.Workspace.CurrentCamera
        if camera then
            lastCamera = camera
            currentFOV = camera.FieldOfView
            isTransitioning = true
            print("FOV Changer: Setting up for new character")
        end
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Nexus.States.FOVChangerEnabled = true
        print("FOV Changer: ON (" .. targetFOV .. ")")
        
        -- Очищаем старые слушатели
        for _, listener in ipairs(characterListeners) do
            Nexus.safeDisconnect(listener)
        end
        characterListeners = {}
        
        -- Добавляем слушатель появления персонажа
        table.insert(characterListeners, setupCharacterListener(setupFOVForCharacter))
        
        -- Отслеживаем изменение камеры
        local cameraChangedConn = Nexus.Services.Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
            if enabled then
                task.wait(0.1)
                setupFOVForCharacter()
            end
        end)
        table.insert(characterListeners, cameraChangedConn)
        
        -- Инициализируем для текущей камеры
        setupFOVForCharacter()
        
        -- Цикл обновления
        local updateConn = Nexus.Services.RunService.RenderStepped:Connect(updateFOV)
        table.insert(characterListeners, updateConn)
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Nexus.States.FOVChangerEnabled = false
        print("FOV Changer: OFF")
        
        resetFOV()
        
        -- Очищаем слушатели
        for _, listener in ipairs(characterListeners) do
            Nexus.safeDisconnect(listener)
        end
        characterListeners = {}
    end
    
    local function SetFOV(fov)
        local newFOV = math.clamp(fov, 1, 200)  -- Максимум 200
        if targetFOV ~= newFOV then
            targetFOV = newFOV
            isTransitioning = true
            print("FOV set to: " .. targetFOV)
            
            if enabled then
                local camera = Nexus.Services.Workspace.CurrentCamera
                if camera then
                    currentFOV = camera.FieldOfView
                end
            end
        end
    end
    
    local function SetSmoothness(value)
        smoothness = math.clamp(value, 0.05, 1)
        print("FOV smoothness set to: " .. smoothness)
    end
    
    local function GetFOV()
        return targetFOV
    end
    
    local function GetCurrentFOV()
        local camera = Nexus.Services.Workspace.CurrentCamera
        return camera and camera.FieldOfView or 70
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end,
        SetFOV = SetFOV,
        SetSmoothness = SetSmoothness,
        GetFOV = GetFOV,
        GetCurrentFOV = GetCurrentFOV
    }
end)()

-- ========== FLY ==========

local Fly = (function()
    local enabled = false
    local flySpeed = 50
    local characterListeners = {}
    local flyConnection = nil
    local controls = {
        W = false,
        A = false,
        S = false,
        D = false,
        Space = false,
        LeftShift = false
    }
    
    local function updateFly()
        if not enabled then return end
        
        local character = Nexus.getCharacter()
        if not character then return end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        
        -- Получаем направление движения
        local direction = Vector3.new(0, 0, 0)
        
        if controls.W then direction = direction + Nexus.Services.Workspace.CurrentCamera.CFrame.LookVector end
        if controls.S then direction = direction - Nexus.Services.Workspace.CurrentCamera.CFrame.LookVector end
        if controls.D then direction = direction + Nexus.Services.Workspace.CurrentCamera.CFrame.RightVector end
        if controls.A then direction = direction - Nexus.Services.Workspace.CurrentCamera.CFrame.RightVector end
        
        if controls.Space then direction = direction + Vector3.new(0, 1, 0) end
        if controls.LeftShift then direction = direction + Vector3.new(0, -1, 0) end
        
        -- Нормализуем направление и применяем скорость
        if direction.Magnitude > 0 then
            direction = direction.Unit * flySpeed
            
            -- Отключаем гравитацию
            humanoid.PlatformStand = true
            
            -- Применяем движение
            humanoidRootPart.Velocity = direction
            
            -- Сохраняем вертикальную скорость
            local currentVelocity = humanoidRootPart.Velocity
            humanoidRootPart.Velocity = Vector3.new(direction.X, direction.Y, direction.Z)
        else
            -- Если нет ввода, останавливаемся
            humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
        end
    end
    
    local function setupControls()
        local inputBeganConn = Nexus.Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed or not enabled then return end
            
            if input.KeyCode == Enum.KeyCode.W then controls.W = true
            elseif input.KeyCode == Enum.KeyCode.A then controls.A = true
            elseif input.KeyCode == Enum.KeyCode.S then controls.S = true
            elseif input.KeyCode == Enum.KeyCode.D then controls.D = true
            elseif input.KeyCode == Enum.KeyCode.Space then controls.Space = true
            elseif input.KeyCode == Enum.KeyCode.LeftShift then controls.LeftShift = true end
        end)
        
        local inputEndedConn = Nexus.Services.UserInputService.InputEnded:Connect(function(input, gameProcessed)
            if gameProcessed or not enabled then return end
            
            if input.KeyCode == Enum.KeyCode.W then controls.W = false
            elseif input.KeyCode == Enum.KeyCode.A then controls.A = false
            elseif input.KeyCode == Enum.KeyCode.S then controls.S = false
            elseif input.KeyCode == Enum.KeyCode.D then controls.D = false
            elseif input.KeyCode == Enum.KeyCode.Space then controls.Space = false
            elseif input.KeyCode == Enum.KeyCode.LeftShift then controls.LeftShift = false end
        end)
        
        return {inputBeganConn, inputEndedConn}
    end
    
    local function resetFlyState()
        controls = {
            W = false,
            A = false,
            S = false,
            D = false,
            Space = false,
            LeftShift = false
        }
        
        local character = Nexus.getCharacter()
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.PlatformStand = false
            end
        end
    end
    
    local function setupFlyForCharacter(character)
        if not enabled then return end
        
        task.wait(1) -- Ждем полной инициализации персонажа
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:SetAttribute("FlyEnabled", true)
            
            -- Отслеживаем смерть
            humanoid.Died:Connect(function()
                if enabled then
                    resetFlyState()
                    task.wait(2) -- Ждем респавна
                    if Nexus.getCharacter() then
                        setupFlyForCharacter(Nexus.getCharacter())
                    end
                end
            end)
        end
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Nexus.States.FlyEnabled = true
        print("Fly: ON (" .. flySpeed .. ")")
        
        -- Очищаем старые слушатели
        for _, listener in ipairs(characterListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do
                    Nexus.safeDisconnect(conn)
                end
            else
                Nexus.safeDisconnect(listener)
            end
        end
        characterListeners = {}
        
        -- Добавляем слушатель появления персонажа
        table.insert(characterListeners, setupCharacterListener(setupFlyForCharacter))
        
        -- Настраиваем управление
        local controlConns = setupControls()
        for _, conn in ipairs(controlConns) do
            table.insert(characterListeners, conn)
        end
        
        -- Инициализируем для текущего персонажа
        local currentChar = Nexus.getCharacter()
        if currentChar then
            setupFlyForCharacter(currentChar)
        end
        
        -- Цикл обновления
        if flyConnection then
            flyConnection:Disconnect()
        end
        flyConnection = Nexus.Services.RunService.Heartbeat:Connect(updateFly)
        table.insert(characterListeners, flyConnection)
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Nexus.States.FlyEnabled = false
        print("Fly: OFF")
        
        resetFlyState()
        
        -- Очищаем слушатели
        for _, listener in ipairs(characterListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do
                    Nexus.safeDisconnect(conn)
                end
            else
                Nexus.safeDisconnect(listener)
            end
        end
        characterListeners = {}
        
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
    end
    
    local function SetSpeed(speed)
        flySpeed = math.clamp(speed, 10, 200)
        print("Fly speed set to: " .. flySpeed)
    end
    
    local function GetSpeed()
        return flySpeed
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end,
        SetSpeed = SetSpeed,
        GetSpeed = GetSpeed
    }
end)()

-- ========== FREE CAMERA ==========

local FreeCamera = (function()
    local enabled = false
    local characterListeners = {}
    local originalCameraType = nil
    local originalCameraSubject = nil
    local cameraLocked = false
    
    local function lockCamera()
        if cameraLocked then return end
        
        local camera = Nexus.Services.Workspace.CurrentCamera
        if not camera then return end
        
        originalCameraType = camera.CameraType
        originalCameraSubject = camera.CameraSubject
        
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CameraSubject = nil
        cameraLocked = true
        
        print("Free Camera: Camera locked")
    end
    
    local function unlockCamera()
        if not cameraLocked then return end
        
        local camera = Nexus.Services.Workspace.CurrentCamera
        if not camera then return end
        
        camera.CameraType = originalCameraType or Enum.CameraType.Custom
        camera.CameraSubject = originalCameraSubject
        
        originalCameraType = nil
        originalCameraSubject = nil
        cameraLocked = false
        
        print("Free Camera: Camera unlocked")
    end
    
    local function setupFreeCameraForCharacter()
        if not enabled then return end
        
        task.wait(0.5) -- Ждем стабилизации камеры
        
        lockCamera()
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Nexus.States.FreeCameraEnabled = true
        print("Free Camera: ON")
        
        -- Очищаем старые слушатели
        for _, listener in ipairs(characterListeners) do
            Nexus.safeDisconnect(listener)
        end
        characterListeners = {}
        
        -- Добавляем слушатель появления персонажа
        table.insert(characterListeners, setupCharacterListener(setupFreeCameraForCharacter))
        
        -- Отслеживаем изменение камеры
        local cameraChangedConn = Nexus.Services.Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
            if enabled then
                task.wait(0.1)
                setupFreeCameraForCharacter()
            end
        end)
        table.insert(characterListeners, cameraChangedConn)
        
        -- Инициализируем для текущей камеры
        setupFreeCameraForCharacter()
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Nexus.States.FreeCameraEnabled = false
        print("Free Camera: OFF")
        
        unlockCamera()
        
        -- Очищаем слушатели
        for _, listener in ipairs(characterListeners) do
            Nexus.safeDisconnect(listener)
        end
        characterListeners = {}
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end
    }
end)()

-- ========== MODULE INITIALIZATION ==========

function Movement.Init(nxs)
    Nexus = nxs
    
    local Tabs = Nexus.Tabs
    local Options = Nexus.Options
    
    -- ========== INFINITE LUNGE ==========
    local InfiniteLungeToggle = Tabs.Movement:AddToggle("InfiniteLunge", {
        Title = "Infinite Lunge", 
        Description = "Unlimited lunge distance and speed", 
        Default = false
    })

    InfiniteLungeToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            if v then 
                InfiniteLunge.Enable() 
            else 
                InfiniteLunge.Disable() 
            end
        end)
    end)

    -- ========== WALK SPEED ==========
    local WalkSpeedToggle = Tabs.Movement:AddToggle("WalkSpeed", {
        Title = "Walk Speed", 
        Description = "Increase walking speed", 
        Default = false
    })

    WalkSpeedToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            if v then 
                WalkSpeed.Enable() 
            else 
                WalkSpeed.Disable() 
            end
        end)
    end)

    local WalkSpeedSlider = Tabs.Movement:AddSlider("WalkSpeedValue", {
        Title = "Walk Speed Value",
        Description = "Adjust walking speed",
        Default = 16,
        Min = 16,
        Max = 100,
        Rounding = 1,
        Callback = function(value)
            Nexus.SafeCallback(function()
                WalkSpeed.SetSpeed(value)
            end)
        end
    })

    -- ========== NOCLIP ==========
    local NoclipToggle = Tabs.Movement:AddToggle("Noclip", {
        Title = "Noclip", 
        Description = "Walk through walls and objects", 
        Default = false
    })

    NoclipToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            if v then 
                Noclip.Enable() 
            else 
                Noclip.Disable() 
            end
        end)
    end)

    -- ========== FOV CHANGER ==========
    local FOVToggle = Tabs.Movement:AddToggle("FOVChanger", {
        Title = "FOV Changer", 
        Description = "Change field of view (1-200)", 
        Default = false
    })

    FOVToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            if v then 
                FOVChanger.Enable() 
            else 
                FOVChanger.Disable() 
            end
        end)
    end)

    local FOVSlider = Tabs.Movement:AddSlider("FOVValue", {
        Title = "FOV Value",
        Description = "Adjust field of view (1-200)",
        Default = 70,
        Min = 1,
        Max = 200,  -- Увеличено до 200
        Rounding = 1,
        Callback = function(value)
            Nexus.SafeCallback(function()
                FOVChanger.SetFOV(value)
            end)
        end
    })

    local FOVSmoothnessSlider = Tabs.Movement:AddSlider("FOVSmoothness", {
        Title = "FOV Smoothness",
        Description = "Adjust smoothness of FOV changes (lower = smoother)",
        Default = 0.3,
        Min = 0.05,
        Max = 1,
        Rounding = 2,
        Callback = function(value)
            Nexus.SafeCallback(function()
                FOVChanger.SetSmoothness(value)
            end)
        end
    })

    -- ========== FLY ==========
    local FlyToggle = Tabs.Movement:AddToggle("Fly", {
        Title = "Fly", 
        Description = "Fly around the map", 
        Default = false
    })

    FlyToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            if v then 
                Fly.Enable() 
            else 
                Fly.Disable() 
            end
        end)
    end)

    local FlySpeedSlider = Tabs.Movement:AddSlider("FlySpeed", {
        Title = "Fly Speed",
        Description = "Adjust flying speed",
        Default = 50,
        Min = 10,
        Max = 200,
        Rounding = 1,
        Callback = function(value)
            Nexus.SafeCallback(function()
                Fly.SetSpeed(value)
            end)
        end
    })

    -- ========== FREE CAMERA ==========
    local FreeCameraToggle = Tabs.Movement:AddToggle("FreeCamera", {
        Title = "Free Camera", 
        Description = "Detach camera from character", 
        Default = false
    })

    FreeCameraToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            if v then 
                FreeCamera.Enable() 
            else 
                FreeCamera.Disable() 
            end
        end)
    end)

    -- ========== CONTROLS INFORMATION ==========
    Tabs.Movement:AddParagraph({
        Title = "Fly Controls",
        Content = "WASD - Move\nSpace - Up\nLeft Shift - Down"
    })

    print("✓ Movement module initialized")
end

-- ========== CLEANUP ==========

function Movement.Cleanup()
    -- Отключаем все функции
    InfiniteLunge.Disable()
    WalkSpeed.Disable()
    Noclip.Disable()
    FOVChanger.Disable()
    Fly.Disable()
    FreeCamera.Disable()
    
    -- Очищаем все соединения
    for key, connection in pairs(Movement.Connections) do
        Nexus.safeDisconnect(connection)
    end
    Movement.Connections = {}
    
    print("Movement module cleaned up")
end

return Movement
