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

-- Глобальный Nexus - СОЗДАЕМ СРАЗУ
_G.Nexus = {
    Player = Player,
    Camera = Camera,
    Services = Services,
    IS_MOBILE = IS_MOBILE,
    IS_DESKTOP = IS_DESKTOP,
    Fluent = Fluent,
    Options = Fluent.Options,
    Modules = {},
    States = {},
    Tabs = {} -- Добавляем пустую таблицу для вкладок
}

-- ========== ПОЛЕЗНЫЕ ФУНКЦИИ (из Helpers) ==========

-- Основные функции персонажа
_G.Nexus.getCharacter = function()
    return _G.Nexus.Player.Character
end

_G.Nexus.getHumanoid = function()
    local char = _G.Nexus.getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

_G.Nexus.getRootPart = function()
    local char = _G.Nexus.getCharacter()
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

-- Инициализация States (важно делать это ДО загрузки модулей!)
_G.Nexus.States = {
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

-- ========== ЗАГРУЗКА МОДУЛЕЙ ==========

local ModuleUrls = {
    UI = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/UI.lua",
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
    else
        warn("Failed to load module from:", url)
        return nil
    end
end

-- Загружаем модули последовательно, а не параллельно
local moduleNames = {"UI", "Survivor", "Killer", "Movement", "Fun", "Visual"}
if IS_DESKTOP then
    table.insert(moduleNames, "Binds")
end

for _, name in ipairs(moduleNames) do
    local url = ModuleUrls[name]
    if url then
        print("Loading module:", name)
        local module = loadModule(url)
        if module then
            _G.Nexus.Modules[name] = module
            print("✓ Module loaded:", name)
        else
            warn("✗ Failed to load module:", name)
        end
    end
end

-- ========== ИНИЦИАЛИЗАЦИЯ МОДУЛЕЙ ==========

local function initModule(name)
    local module = _G.Nexus.Modules[name]
    if module and module.Init then
        local success, err = pcall(function()
            module.Init(_G.Nexus)
        end)
        if success then
            print("✓ Module initialized:", name)
            return true
        else
            warn("✗ Failed to initialize module", name, ":", err)
            return false
        end
    else
        warn("✗ Module", name, "not found or has no Init function")
        return false
    end
end

-- Порядок инициализации (UI должен быть первым!)
local initOrder = {"UI", "Survivor", "Killer", "Movement", "Fun", "Visual"}
if IS_DESKTOP then
    table.insert(initOrder, "Binds")
end

for _, name in ipairs(initOrder) do
    initModule(name)
end

-- ========== НАСТРОЙКА ИНТЕРФЕЙСА ==========

if _G.Nexus.Window then
    -- Вкладка Settings (добавляем только если окно создано)
    _G.Nexus.Tabs.Settings = _G.Nexus.Window:AddTab({ Title = "Settings", Icon = "settings" })
    
    -- Настройка сохранения
    SaveManager:SetLibrary(Fluent)
    InterfaceManager:SetLibrary(Fluent)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({})
    InterfaceManager:SetFolder("FluentScriptHub")
    SaveManager:SetFolder("FluentScriptHub/violence-district")
    
    InterfaceManager:BuildInterfaceSection(_G.Nexus.Tabs.Settings)
    SaveManager:BuildConfigSection(_G.Nexus.Tabs.Settings)
    
    _G.Nexus.Window:SelectTab(1)
    SaveManager:LoadAutoloadConfig()
end

-- Уведомление
local notificationContent = IS_MOBILE and "Nexus loaded (Mobile)" or "Nexus loaded"
Fluent:Notify({
    Title = "Nexus",
    Content = notificationContent,
    Duration = 3
})

-- Очистка при выходе
Services.Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == Player then
        for name, module in pairs(_G.Nexus.Modules) do
            if module and module.Cleanup then
                pcall(module.Cleanup)
            end
        end
    end
end)

print("Nexus script loaded successfully!")
return _G.Nexus
