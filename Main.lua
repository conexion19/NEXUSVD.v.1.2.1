-- Оптимизированный Nexus Loader
local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/zawerex/govno435345/refs/heads/main/g"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Быстрая инициализация сервисов
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

-- Определение платформы
local IS_MOBILE = (Services.UserInputService.TouchEnabled and not Services.UserInputService.KeyboardEnabled)
local IS_DESKTOP = (Services.UserInputService.KeyboardEnabled and not Services.UserInputService.TouchEnabled)

-- Глобальные переменные
local Player = Services.Players.LocalPlayer
local Camera = Services.Workspace.CurrentCamera

-- Глобальный объект Nexus
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

-- Базовые вспомогательные функции
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

_G.Nexus.SafeCallback = function(callback, ...)
    if type(callback) == "function" then
        return pcall(callback, ...)
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

-- Оптимизированная загрузка модулей
local ModuleUrls = {
    UI = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/UI.lua",
    Survivor = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/Survivor%20Module.lua",
    Killer = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/Killer.lua",
    Movement = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/Movement.lua",
    Fun = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/Fun.lua",
    Visual = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/Visual.lua"
}

-- Добавляем вкладку Binds только для Desktop
if IS_DESKTOP then
    ModuleUrls.Binds = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/Binds.lua"
end

-- Загрузка модулей
local loadedModules = 0
local totalModules = 0

for name, url in pairs(ModuleUrls) do
    totalModules = totalModules + 1
    task.spawn(function()
        local success, module = pcall(function()
            return loadstring(game:HttpGet(url, true))()
        end)
        
        if success and module then
            _G.Nexus.Modules[name] = module
            loadedModules = loadedModules + 1
        end
    end)
end

-- Ждем загрузку всех модулей
while loadedModules < totalModules do
    Services.RunService.Heartbeat:Wait()
end

-- Основная инициализация
local function initializeUI()
    if _G.Nexus.Modules.UI and _G.Nexus.Modules.UI.Init then
        _G.Nexus.Modules.UI.Init(_G.Nexus)
        return true
    end
    return false
end

local function initializeModule(moduleName)
    local module = _G.Nexus.Modules[moduleName]
    if module and module.Init then
        return pcall(module.Init, _G.Nexus)
    end
    return false
end

-- Инициализация по порядку
local initOrder = {"UI", "Survivor", "Killer", "Movement", "Fun", "Visual", "Binds"}

if initializeUI() then
    for _, moduleName in ipairs(initOrder) do
        if _G.Nexus.Modules[moduleName] then
            initializeModule(moduleName)
        end
    end
    
    -- Настройка сохранения
    SaveManager:SetLibrary(Fluent)
    InterfaceManager:SetLibrary(Fluent)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({})
    
    InterfaceManager:SetFolder("FluentScriptHub")
    SaveManager:SetFolder("FluentScriptHub/violence-district")
    
    -- Добавление вкладки Settings
    if _G.Nexus.Window then
        local Tabs = _G.Nexus.Tabs
        Tabs.Settings = _G.Nexus.Window:AddTab({ Title = "Settings", Icon = "settings" })
        
        InterfaceManager:BuildInterfaceSection(Tabs.Settings)
        SaveManager:BuildConfigSection(Tabs.Settings)
        
        _G.Nexus.Window:SelectTab(1)
        SaveManager:LoadAutoloadConfig()
    end
    
    -- Уведомление
    local notificationContent = IS_MOBILE and "Nexus script loaded (Mobile Version)" or "The script has been loaded"
    Fluent:Notify({
        Title = "Nexus",
        Content = notificationContent,
        Duration = 3.5
    })
end

-- Очистка при выходе
Services.Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == Player then
        for _, module in pairs(_G.Nexus.Modules) do
            if module.Cleanup then
                pcall(module.Cleanup)
            end
        end
    end
end)

return _G.Nexus
