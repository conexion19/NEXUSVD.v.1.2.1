-- ========== ПРЕДВАРИТЕЛЬНЫЙ ЭКРАН ЗАГРУЗКИ ==========
do
    -- Создаем GUI для предзагрузки
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NexusPreload"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false
    screenGui.Parent = game:GetService("CoreGui")

    -- Фон (темный с легкой прозрачностью)
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(10, 10, 25)
    background.BackgroundTransparency = 1
    background.BorderSizePixel = 0
    background.Parent = screenGui

    -- Контейнер для всей анимации
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(0, 600, 0, 400)
    container.Position = UDim2.new(0.5, -300, 0.5, -200)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Parent = background

    -- Функция для создания части крыла (пера)
    local function createFeather(size, position, rotation, parent)
        local feather = Instance.new("Frame")
        feather.Size = UDim2.new(0, size.X, 0, size.Y)
        feather.Position = position
        feather.Rotation = rotation
        feather.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        feather.BackgroundTransparency = 1
        feather.BorderSizePixel = 0
        feather.Parent = parent
        
        -- Создаем UIGradient для красивого перехода
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.7, Color3.fromRGB(230, 230, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 255))
        }
        gradient.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.3, 0.3),
            NumberSequenceKeypoint.new(1, 0)
        }
        gradient.Rotation = 45
        gradient.Parent = feather
        
        -- Скругление краев (имитация пера)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = feather
        
        return feather
    end

    -- Создаем левое крыло
    local leftWingContainer = Instance.new("Frame")
    leftWingContainer.Name = "LeftWingContainer"
    leftWingContainer.Size = UDim2.new(0, 250, 0, 300)
    leftWingContainer.Position = UDim2.new(0.2, -125, 0.5, -150)
    leftWingContainer.BackgroundTransparency = 1
    leftWingContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    leftWingContainer.Parent = container

    -- Создаем перья для левого крыла
    local leftFeathers = {}
    
    -- Большие перья (основа крыла)
    for i = 1, 8 do
        local feather = createFeather(
            Vector2.new(80, 15),
            UDim2.new(0, 70 - i * 8, 0, 40 + i * 15),
            -30 - i * 5,
            leftWingContainer
        )
        feather.ZIndex = i
        table.insert(leftFeathers, feather)
    end
    
    -- Средние перья
    for i = 1, 6 do
        local feather = createFeather(
            Vector2.new(60, 12),
            UDim2.new(0, 100 - i * 10, 0, 30 + i * 18),
            -40 - i * 8,
            leftWingContainer
        )
        feather.ZIndex = 10 + i
        table.insert(leftFeathers, feather)
    end
    
    -- Маленькие перья (верх крыла)
    for i = 1, 4 do
        local feather = createFeather(
            Vector2.new(40, 10),
            UDim2.new(0, 130 - i * 15, 0, 20 + i * 20),
            -50 - i * 10,
            leftWingContainer
        )
        feather.ZIndex = 20 + i
        table.insert(leftFeathers, feather)
    end

    -- Создаем правое крыло
    local rightWingContainer = Instance.new("Frame")
    rightWingContainer.Name = "RightWingContainer"
    rightWingContainer.Size = UDim2.new(0, 250, 0, 300)
    rightWingContainer.Position = UDim2.new(0.8, -125, 0.5, -150)
    rightWingContainer.BackgroundTransparency = 1
    rightWingContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    rightWingContainer.Parent = container

    -- Создаем перья для правого крыла (зеркально)
    local rightFeathers = {}
    
    -- Большие перья (основа крыла)
    for i = 1, 8 do
        local feather = createFeather(
            Vector2.new(80, 15),
            UDim2.new(0, 70 + i * 8, 0, 40 + i * 15),
            30 + i * 5,
            rightWingContainer
        )
        feather.ZIndex = i
        table.insert(rightFeathers, feather)
    end
    
    -- Средние перья
    for i = 1, 6 do
        local feather = createFeather(
            Vector2.new(60, 12),
            UDim2.new(0, 100 + i * 10, 0, 30 + i * 18),
            40 + i * 8,
            rightWingContainer
        )
        feather.ZIndex = 10 + i
        table.insert(rightFeathers, feather)
    end
    
    -- Маленькие перья (верх крыла)
    for i = 1, 4 do
        local feather = createFeather(
            Vector2.new(40, 10),
            UDim2.new(0, 130 + i * 15, 0, 20 + i * 20),
            50 + i * 10,
            rightWingContainer
        )
        feather.ZIndex = 20 + i
        table.insert(rightFeathers, feather)
    end

    -- Создаем центральный эффект сияния
    local glowEffect = Instance.new("Frame")
    glowEffect.Name = "GlowEffect"
    glowEffect.Size = UDim2.new(0, 100, 0, 100)
    glowEffect.Position = UDim2.new(0.5, -50, 0.5, -50)
    glowEffect.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    glowEffect.BackgroundTransparency = 1
    glowEffect.BorderSizePixel = 0
    glowEffect.Parent = container
    
    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(1, 0)
    glowCorner.Parent = glowEffect
    
    local glowGradient = Instance.new("UIGradient")
    glowGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 150, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 220, 255))
    }
    glowGradient.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.8),
        NumberSequenceKeypoint.new(1, 1)
    }
    glowGradient.Parent = glowEffect

    -- Текст Nexus Script
    local textContainer = Instance.new("Frame")
    textContainer.Name = "TextContainer"
    textContainer.Size = UDim2.new(0.8, 0, 0, 120)
    textContainer.Position = UDim2.new(0.1, 0, 0.7, 0)
    textContainer.BackgroundTransparency = 1
    textContainer.Parent = container

    -- Основной текст
    local mainText = Instance.new("TextLabel")
    mainText.Name = "MainText"
    mainText.Size = UDim2.new(1, 0, 0.6, 0)
    mainText.Position = UDim2.new(0, 0, 0, 0)
    mainText.BackgroundTransparency = 1
    mainText.Text = "NEXUS"
    mainText.Font = Enum.Font.GothamBlack
    mainText.TextSize = 56
    mainText.TextColor3 = Color3.fromRGB(255, 255, 255)
    mainText.TextTransparency = 1
    mainText.TextStrokeTransparency = 0.7
    mainText.TextStrokeColor3 = Color3.fromRGB(80, 120, 255)
    mainText.ZIndex = 50
    mainText.Parent = textContainer

    -- Подзаголовок
    local subText = Instance.new("TextLabel")
    subText.Name = "SubText"
    subText.Size = UDim2.new(1, 0, 0.4, 0)
    subText.Position = UDim2.new(0, 0, 0.6, 0)
    subText.BackgroundTransparency = 1
    subText.Text = "Violence District"
    subText.Font = Enum.Font.GothamMedium
    subText.TextSize = 24
    subText.TextColor3 = Color3.fromRGB(200, 200, 255)
    subText.TextTransparency = 1
    subText.TextStrokeTransparency = 0.8
    subText.TextStrokeColor3 = Color3.fromRGB(60, 80, 180)
    subText.ZIndex = 50
    subText.Parent = textContainer

    -- Эффект частиц (опционально)
    local particleContainer = Instance.new("Frame")
    particleContainer.Name = "ParticleContainer"
    particleContainer.Size = UDim2.new(1, 0, 1, 0)
    particleContainer.BackgroundTransparency = 1
    particleContainer.Parent = container

    -- Анимация появления
    local tweenService = game:GetService("TweenService")
    
    local function createParticle()
        local particle = Instance.new("Frame")
        particle.Size = UDim2.new(0, 4, 0, 4)
        particle.Position = UDim2.new(math.random(), 0, math.random(), 0)
        particle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        particle.BackgroundTransparency = 0.7
        particle.BorderSizePixel = 0
        particle.Parent = particleContainer
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = particle
        
        return particle
    end
    
    local function showAnimation()
        -- Появление фона
        local bgTween = tweenService:Create(background, TweenInfo.new(0.8), {BackgroundTransparency = 0.4})
        bgTween:Play()
        
        task.wait(0.5)
        
        -- Появление центрального свечения
        local glowTween = tweenService:Create(glowEffect, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.7,
            Size = UDim2.new(0, 150, 0, 150),
            Position = UDim2.new(0.5, -75, 0.5, -75)
        })
        glowTween:Play()
        
        -- Появление крыльев (последовательно перья)
        for i, feather in ipairs(leftFeathers) do
            local tween = tweenService:Create(feather, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.2,
                Position = UDim2.new(
                    feather.Position.X.Scale,
                    feather.Position.X.Offset + 20,
                    feather.Position.Y.Scale,
                    feather.Position.Y.Offset
                )
            })
            tween:Play()
            task.wait(0.05)
        end
        
        for i, feather in ipairs(rightFeathers) do
            local tween = tweenService:Create(feather, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.2,
                Position = UDim2.new(
                    feather.Position.X.Scale,
                    feather.Position.X.Offset - 20,
                    feather.Position.Y.Scale,
                    feather.Position.Y.Offset
                )
            })
            tween:Play()
            task.wait(0.05)
        end
        
        -- Легкая анимация крыльев (дыхание)
        task.spawn(function()
            while true do
                local breathTween1 = tweenService:Create(leftWingContainer, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Rotation = 3
                })
                local breathTween2 = tweenService:Create(rightWingContainer, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Rotation = -3
                })
                
                breathTween1:Play()
                breathTween2:Play()
                task.wait(1.5)
                
                breathTween1 = tweenService:Create(leftWingContainer, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Rotation = -3
                })
                breathTween2 = tweenService:Create(rightWingContainer, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Rotation = 3
                })
                
                breathTween1:Play()
                breathTween2:Play()
                task.wait(1.5)
            end
        end)
        
        task.wait(0.5)
        
        -- Появление текста с эффектом
        local mainTextTween = tweenService:Create(mainText, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            TextTransparency = 0,
            TextStrokeTransparency = 0.5
        })
        
        task.wait(0.3)
        
        local subTextTween = tweenService:Create(subText, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            TextTransparency = 0,
            TextStrokeTransparency = 0.6
        })
        
        mainTextTween:Play()
        task.wait(0.2)
        subTextTween:Play()
        
        -- Эффект мерцания текста
        task.spawn(function()
            for _ = 1, 4 do
                local pulseTween = tweenService:Create(mainText, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    TextColor3 = Color3.fromRGB(220, 230, 255),
                    TextStrokeColor3 = Color3.fromRGB(100, 140, 255)
                })
                pulseTween:Play()
                task.wait(0.3)
                
                pulseTween = tweenService:Create(mainText, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextStrokeColor3 = Color3.fromRGB(80, 120, 255)
                })
                pulseTween:Play()
                task.wait(0.3)
            end
        end)
        
        -- Создаем частицы
        for _ = 1, 20 do
            local particle = createParticle()
            local particleTween = tweenService:Create(particle, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(particle.Position.X.Scale, particle.Position.X.Offset, 1.2, 0),
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 8, 0, 8)
            })
            particleTween:Play()
            game:GetService("Debris"):AddItem(particle, 2.5)
            task.wait(0.1)
        end
        
        -- Ждем 2 секунды
        task.wait(2)
        
        -- Исчезновение с эффектом
        local fadeOutInfo = TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        
        -- Исчезает текст
        local fadeOutMainText = tweenService:Create(mainText, fadeOutInfo, {
            TextTransparency = 1,
            TextStrokeTransparency = 1,
            Position = UDim2.new(0, 0, -0.1, 0)
        })
        
        local fadeOutSubText = tweenService:Create(subText, fadeOutInfo, {
            TextTransparency = 1,
            TextStrokeTransparency = 1,
            Position = UDim2.new(0, 0, 0.7, 0)
        })
        
        -- Исчезают крылья
        for i, feather in ipairs(leftFeathers) do
            local featherTween = tweenService:Create(feather, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                BackgroundTransparency = 1,
                Position = UDim2.new(
                    feather.Position.X.Scale,
                    feather.Position.X.Offset - 50,
                    feather.Position.Y.Scale,
                    feather.Position.Y.Offset
                )
            })
            featherTween:Play()
        end
        
        for i, feather in ipairs(rightFeathers) do
            local featherTween = tweenService:Create(feather, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                BackgroundTransparency = 1,
                Position = UDim2.new(
                    feather.Position.X.Scale,
                    feather.Position.X.Offset + 50,
                    feather.Position.Y.Scale,
                    feather.Position.Y.Offset
                )
            })
            featherTween:Play()
        end
        
        -- Исчезает свечение
        local fadeOutGlow = tweenService:Create(glowEffect, fadeOutInfo, {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        })
        
        -- Исчезает фон
        local fadeOutBg = tweenService:Create(background, TweenInfo.new(0.8), {
            BackgroundTransparency = 1
        })
        
        -- Запускаем анимацию исчезновения
        fadeOutMainText:Play()
        fadeOutSubText:Play()
        fadeOutGlow:Play()
        
        task.wait(0.3)
        fadeOutBg:Play()
        
        -- Удаляем GUI после анимации
        task.wait(1.5)
        screenGui:Destroy()
    end
    
    -- Запускаем анимацию в отдельном потоке
    task.spawn(showAnimation)
    
    -- Ждем завершения анимации перед загрузкой библиотек
    task.wait(4)
end

-- ========== ЗАГРУЗКА БИБЛИОТЕК ==========
local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/zawerex/govno435345/refs/heads/main/g"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Сервисы
local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    Lighting = game:GetService("Lighting"),
    Workspace = game:GetService("Workspace"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    VirtualInputManager = game:GetService("VirtualInputManager"),
    TweenService = game:GetService("TweenService")
}

-- Платформа
local IS_MOBILE = (Services.UserInputService.TouchEnabled and not Services.UserInputService.KeyboardEnabled)
local IS_DESKTOP = (Services.UserInputService.KeyboardEnabled and not Services.UserInputService.TouchEnabled)

-- Основные переменные
local Player = Services.Players.LocalPlayer
local Camera = Services.Workspace.CurrentCamera

-- Глобальный Nexus
_G.Nexus = {
    Player = Player,
    Camera = Camera,
    Services = Services,
    IS_MOBILE = IS_MOBILE,
    IS_DESKTOP = IS_DESKTOP,
    Fluent = Fluent,
    Options = Fluent.Options,
    Modules = {},
    States = {
        InstantHealRunning = false,
        SilentHealRunning = false,
        autoHealEnabled = false,
        autoSkillEnabled = false,
        NoSlowdownEnabled = false,
        antiFailEnabled = false,
        noclipEnabled = false,
        fullbrightEnabled = false,
        AutoParryEnabled = false,
        AutoParryV2Enabled = false,
        KillerAntiBlindEnabled = false,
        GateToolEnabled = false,
        InfiniteLungeEnabled = false,
        FlyEnabled = false,
        FreeCameraEnabled = false,
        WalkSpeedEnabled = false,
        OneHitKillEnabled = false,
        DestroyPalletsEnabled = false,
        BreakGeneratorEnabled = false,
        NoFallEnabled = false,
        NoTurnLimitEnabled = false
    }
}

-- ========== ПОЛЕЗНЫЕ ФУНКЦИИ (из Helpers) ==========

-- Основные функции персонажа
_G.Nexus.getCharacter = function()
    return Player.Character
end

_G.Nexus.getHumanoid = function()
    local char = Player.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

_G.Nexus.getRootPart = function()
    local char = Player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- Безопасные функции
_G.Nexus.SafeCallback = function(callback, ...)
    if type(callback) == "function" then
        local success, result = pcall(callback, ...)
        if not success then
            warn("Callback error:", result)
        end
        return success
    end
    return false
end

_G.Nexus.safeDisconnect = function(conn)
    if conn and typeof(conn) == "RBXScriptConnection" then
        pcall(function() 
            conn:Disconnect() 
        end)
    end
    return nil
end

-- Проверка ролей (нужны для модулей)
_G.Nexus.IsKiller = function(targetPlayer)
    targetPlayer = targetPlayer or Player
    if not targetPlayer.Team then return false end
    local teamName = targetPlayer.Team.Name:lower()
    return teamName:find("killer") or teamName == "killer"
end

_G.Nexus.IsSurvivor = function(targetPlayer)
    if not targetPlayer or not targetPlayer.Team then return false end
    local teamName = targetPlayer.Team.Name:lower()
    return teamName:find("survivor") or teamName == "survivors" or teamName == "survivor"
end

_G.Nexus.GetRole = function(targetPlayer)
    targetPlayer = targetPlayer or Player
    if targetPlayer.Team and targetPlayer.Team.Name then
        local n = targetPlayer.Team.Name:lower()
        if n:find("killer") then return "Killer" end
        if n:find("survivor") then return "Survivor" end
    end
    return "Survivor"
end

-- Утилиты (если используются)
_G.Nexus.Notify = function(title, content, duration)
    Fluent:Notify({
        Title = title,
        Content = content,
        Duration = duration or 3
    })
end

_G.Nexus.FindRemote = function(path)
    local current = Services.ReplicatedStorage
    for _, part in ipairs(path:split("/")) do
        current = current:WaitForChild(part)
    end
    return current
end

_G.Nexus.GetDistance = function(pos1, pos2)
    if not pos1 or not pos2 then return math.huge end
    return (pos1 - pos2).Magnitude
end

_G.Nexus.Clamp = function(value, min, max)
    return math.max(min, math.min(max, value))
end

-- ========== СОЗДАНИЕ UI ==========

local function createUI()
    local windowSize = _G.Nexus.IS_MOBILE and UDim2.fromOffset(350, 200) or UDim2.fromOffset(580,550)
    
    -- Создаем главное окно
    _G.Nexus.Window = Fluent:CreateWindow({
        Title = "NEXUS",
        SubTitle = "Violence District",
        Search = false,
        Icon = "",
        TabWidth = 120,
        Size = windowSize,  
        Acrylic = false,
        Theme = "Darker",
        MinimizeKey = Enum.KeyCode.LeftControl,
        UserInfo = true,
        UserInfoTop = false,
        UserInfoTitle = _G.Nexus.Player.DisplayName,
        UserInfoSubtitle = "user",
        UserInfoSubtitleColor = Color3.fromRGB(255, 250, 250)
    })
    
    -- Создаем вкладки
    _G.Nexus.Tabs = {}
    _G.Nexus.Tabs.Main = _G.Nexus.Window:AddTab({ Title = "Survivor", Icon = "snowflake" })
    _G.Nexus.Tabs.Killer = _G.Nexus.Window:AddTab({ Title = "Killer", Icon = "snowflake" })
    _G.Nexus.Tabs.Movement = _G.Nexus.Window:AddTab({ Title = "Movement", Icon = "snowflake" })
    _G.Nexus.Tabs.Fun = _G.Nexus.Window:AddTab({ Title = "Other", Icon = "snowflake" })
    _G.Nexus.Tabs.Visual = _G.Nexus.Window:AddTab({ Title = "Visual & ESP", Icon = "snowflake" })
    
    if _G.Nexus.IS_DESKTOP then
        _G.Nexus.Tabs.Binds = _G.Nexus.Window:AddTab({ Title = "Binds", Icon = "snowflake" })
    end
    
    return true
end

-- ========== ЗАГРУЗКА МОДУЛЕЙ ==========

local ModuleUrls = {
    Survivor = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/Survivor%20Module.lua",
    Killer = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/Killer.lua",
    Movement = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/Movement.lua",
    Fun = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/Fun.lua",
    Visual = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/Visual.lua"
}

if IS_DESKTOP then
    ModuleUrls.Binds = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/Binds.lua"
end

local function loadModule(url)
    local success, module = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if success then
        return module
    end
    return nil
end

-- Параллельная загрузка
local loaded = 0
local total = 0
for name, url in pairs(ModuleUrls) do
    total = total + 1
    task.spawn(function()
        local module = loadModule(url)
        if module then
            _G.Nexus.Modules[name] = module
            loaded = loaded + 1
        end
    end)
end

-- Ожидание загрузки
while loaded < total do
    Services.RunService.Heartbeat:Wait()
end

-- ========== ИНИЦИАЛИЗАЦИЯ ==========

-- Сначала создаем UI
createUI()

local function initModule(name)
    local module = _G.Nexus.Modules[name]
    if module and module.Init then
        return pcall(module.Init, _G.Nexus)
    end
    return false
end

-- Порядок инициализации (UI уже создан, остальные модули)
local initOrder = {"Survivor", "Killer", "Movement", "Fun", "Visual", "Binds"}

for _, name in ipairs(initOrder) do
    if _G.Nexus.Modules[name] then
        initModule(name)
    end
end

-- ========== НАСТРОЙКА СОХРАНЕНИЯ ==========

-- Настройка сохранения
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/violence-district")

-- Вкладка Settings
if _G.Nexus.Window then
    _G.Nexus.Tabs.Settings = _G.Nexus.Window:AddTab({ Title = "Settings", Icon = "settings" })
    
    InterfaceManager:BuildInterfaceSection(_G.Nexus.Tabs.Settings)
    SaveManager:BuildConfigSection(_G.Nexus.Tabs.Settings)
    
    _G.Nexus.Window:SelectTab(1)
    SaveManager:LoadAutoloadConfig()
end

-- ========== ЗАВЕРШЕНИЕ ==========

-- Уведомление
local notificationContent = IS_MOBILE and "Nexus loaded (Mobile)" or "Nexus loaded"
Fluent:Notify({
    Title = "Nexus",
    Content = notificationContent,
    Duration = 3
})

-- Функция очистки
local function cleanup()
    for _, module in pairs(_G.Nexus.Modules) do
        if module and type(module.Cleanup) == "function" then
            pcall(module.Cleanup)
        end
    end
end

-- Очистка при выходе
Services.Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == Player then
        cleanup()
    end
end)

-- Для отладки можно добавить в глобальный объект
_G.Nexus.Cleanup = cleanup

return _G.Nexus
