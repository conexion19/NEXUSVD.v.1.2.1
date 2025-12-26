-- Binds Module - Keybinds for all functions
local Nexus = _G.Nexus

local Binds = {
    Keybinds = {},
    CursorUnlock = {
        enabled = false,
        connection = nil
    },
    KeyDisplay = {
        gui = nil,
        label = nil,
        timer = nil,
        connection = nil
    }
}

function Binds.Init(nxs)
    Nexus = nxs
    
    if not Nexus.IS_DESKTOP then return end
    
    local Tabs = Nexus.Tabs
    if not Tabs.Binds then return end
    
    -- ========== CREATE KEY DISPLAY GUI ==========
    Binds.CreateKeyDisplay()
    
    -- ========== CURSOR UNLOCK ==========
    Tabs.Binds:AddSection("Cursor Unlock")
    
    local CursorToggleKeybind = Tabs.Binds:AddKeybind("CursorToggleKeybind", {
        Title = "Cursor Toggle Keybind",
        Description = "Press to toggle cursor lock/unlock",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleCursorUnlock()
            end)
        end,
        ChangedCallback = function(newKey)
            Nexus.SafeCallback(function()
                Nexus.Fluent:Notify({
                    Title = "Keybind Updated",
                    Content = "Cursor toggle key set to: " .. tostring(newKey),
                    Duration = 2
                })
                -- Показываем клавишу на экране
                Binds.ShowKeyOnScreen("Cursor Toggle", newKey)
            end)
        end
    })
    
    Binds.Keybinds.CursorToggle = CursorToggleKeybind
    
    -- ========== SURVIVOR BINDS ==========
    Tabs.Binds:AddSection("Survivor Binds")
    
    local AutoParryKeybind = Tabs.Binds:AddKeybind("AutoParryKeybind", {
        Title = "AutoParry",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("AutoParry")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("AutoParry", newKey)
            -- Показываем клавишу на экране
            Binds.ShowKeyOnScreen("AutoParry", newKey)
        end
    })
    
    local AutoParryV2Keybind = Tabs.Binds:AddKeybind("AutoParryV2Keybind", {
        Title = "AutoParry (Anti-Stun)",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("AutoParryV2")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("AutoParryV2", newKey)
            Binds.ShowKeyOnScreen("AutoParryV2", newKey)
        end
    })
    
    local HealKeybindBinds = Tabs.Binds:AddKeybind("HealKeybindBinds", {
        Title = "Heal",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("Heal")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("Heal", newKey)
            Binds.ShowKeyOnScreen("Heal", newKey)
        end
    })
    
    local InstantHealKeybind = Tabs.Binds:AddKeybind("InstantHealKeybind", {
        Title = "Instant Heal",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("InstantHeal")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("InstantHeal", newKey)
            Binds.ShowKeyOnScreen("InstantHeal", newKey)
        end
    })
    
    local SilentHealKeybind = Tabs.Binds:AddKeybind("SilentHealKeybind", {
        Title = "Silent Heal",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("SilentHeal")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("SilentHeal", newKey)
            Binds.ShowKeyOnScreen("SilentHeal", newKey)
        end
    })
    
    local GateToolKeybind = Tabs.Binds:AddKeybind("GateToolKeybind", {
        Title = "Gate Tool",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("GateTool")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("GateTool", newKey)
            Binds.ShowKeyOnScreen("GateTool", newKey)
        end
    })
    
    local NoHitboxKeybind = Tabs.Binds:AddKeybind("NoHitboxKeybind", {
        Title = "No Hitbox",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("NoHitbox")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("NoHitbox", newKey)
            Binds.ShowKeyOnScreen("NoHitbox", newKey)
        end
    })
    
    local AutoSkillKeybind = Tabs.Binds:AddKeybind("AutoSkillKeybind", {
        Title = "Auto Perfect Skill Check",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("AutoPerfectSkill")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("AutoPerfectSkill", newKey)
            Binds.ShowKeyOnScreen("AutoPerfectSkill", newKey)
        end
    })
    
    -- ========== KILLER BINDS ==========
    Tabs.Binds:AddSection("Killer Binds")
    
    local OneHitKillKeybind = Tabs.Binds:AddKeybind("OneHitKillKeybind", {
        Title = "OneHitKill",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("OneHitKill")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("OneHitKill", newKey)
            Binds.ShowKeyOnScreen("OneHitKill", newKey)
        end
    })
    
    local AntiBlindKeybind = Tabs.Binds:AddKeybind("AntiBlindKeybind", {
        Title = "Anti Blind",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("AntiBlind")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("AntiBlind", newKey)
            Binds.ShowKeyOnScreen("AntiBlind", newKey)
        end
    })
    
    local NoSlowdownKeybind = Tabs.Binds:AddKeybind("NoSlowdownKeybind", {
        Title = "No Slowdown",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("NoSlowdown")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("NoSlowdown", newKey)
            Binds.ShowKeyOnScreen("NoSlowdown", newKey)
        end
    })
    
    local DestroyPalletsKeybind = Tabs.Binds:AddKeybind("DestroyPalletsKeybind", {
        Title = "Destroy Pallets",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("DestroyPallets")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("DestroyPallets", newKey)
            Binds.ShowKeyOnScreen("DestroyPallets", newKey)
        end
    })
    
    local BreakGeneratorKeybind = Tabs.Binds:AddKeybind("BreakGeneratorKeybind", {
        Title = "Break Generator",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("BreakGenerator")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("BreakGenerator", newKey)
            Binds.ShowKeyOnScreen("BreakGenerator", newKey)
        end
    })
    
    -- ========== MOVEMENT BINDS ==========
    Tabs.Binds:AddSection("Movement Binds")
    
    local InfiniteLungeKeybind = Tabs.Binds:AddKeybind("InfiniteLungeKeybind", {
        Title = "Infinite Lunge",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("InfiniteLunge")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("InfiniteLunge", newKey)
            Binds.ShowKeyOnScreen("InfiniteLunge", newKey)
        end
    })
    
    local WalkSpeedKeybind = Tabs.Binds:AddKeybind("WalkSpeedKeybind", {
        Title = "Walk Speed",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("WalkSpeed")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("WalkSpeed", newKey)
            Binds.ShowKeyOnScreen("WalkSpeed", newKey)
        end
    })
    
    local NoclipKeybind = Tabs.Binds:AddKeybind("NoclipKeybind", {
        Title = "Noclip",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("Noclip")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("Noclip", newKey)
            Binds.ShowKeyOnScreen("Noclip", newKey)
        end
    })
    
    local FOVKeybind = Tabs.Binds:AddKeybind("FOVKeybind", {
        Title = "FOV Changer",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("FOVChanger")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("FOVChanger", newKey)
            Binds.ShowKeyOnScreen("FOVChanger", newKey)
        end
    })
    
    local FlyKeybind = Tabs.Binds:AddKeybind("FlyKeybind", {
        Title = "Fly",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("Fly")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("Fly", newKey)
            Binds.ShowKeyOnScreen("Fly", newKey)
        end
    })
    
    local FreeCameraKeybind = Tabs.Binds:AddKeybind("FreeCameraKeybind", {
        Title = "Free Camera",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("FreeCamera")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("FreeCamera", newKey)
            Binds.ShowKeyOnScreen("FreeCamera", newKey)
        end
    })
end

-- ========== KEY DISPLAY FUNCTIONS ==========

function Binds.CreateKeyDisplay()
    -- Создаем GUI для отображения клавиши
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "KeybindDisplay"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false
    
    -- Основной фрейм (квадрат)
    local frame = Instance.new("Frame")
    frame.Name = "KeyDisplayFrame"
    frame.Size = UDim2.new(0, 200, 0, 80)
    frame.Position = UDim2.new(0.5, -100, 0.2, 0) -- Центрируем по горизонтали, 20% от верха
    frame.AnchorPoint = Vector2.new(0.5, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(100, 100, 255)
    frame.Visible = false
    
    -- Скругление углов
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame
    
    -- Внутренняя тень
    local shadow = Instance.new("UIStroke")
    shadow.Color = Color3.fromRGB(0, 0, 0)
    shadow.Thickness = 2
    shadow.Transparency = 0.5
    shadow.Parent = frame
    
    -- Заголовок (название функции)
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    titleLabel.Text = "Keybind Assigned"
    titleLabel.Font = Enum.Font.GothamMedium
    titleLabel.TextSize = 16
    titleLabel.TextWrapped = true
    
    -- Отображение клавиши (большой текст)
    local keyLabel = Instance.new("TextLabel")
    keyLabel.Name = "KeyLabel"
    keyLabel.Size = UDim2.new(1, 0, 0, 50)
    keyLabel.Position = UDim2.new(0, 0, 0, 30)
    keyLabel.BackgroundTransparency = 1
    keyLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
    keyLabel.Text = "[KEY]"
    keyLabel.Font = Enum.Font.GothamBold
    keyLabel.TextSize = 24
    keyLabel.TextWrapped = true
    
    -- Размещаем элементы
    titleLabel.Parent = frame
    keyLabel.Parent = frame
    frame.Parent = screenGui
    
    -- Сохраняем ссылки
    Binds.KeyDisplay.gui = screenGui
    Binds.KeyDisplay.label = keyLabel
    Binds.KeyDisplay.titleLabel = titleLabel
    Binds.KeyDisplay.frame = frame
    
    -- Встраиваем GUI в игровое окно
    if Nexus and Nexus.Player then
        screenGui.Parent = Nexus.Player:WaitForChild("PlayerGui")
    else
        screenGui.Parent = game:GetService("CoreGui")
    end
end

function Binds.ShowKeyOnScreen(functionName, key)
    if not Binds.KeyDisplay.gui then
        Binds.CreateKeyDisplay()
    end
    
    if not key or key == "" then
        return
    end
    
    -- Форматируем клавишу для отображения
    local displayKey = tostring(key)
    
    -- Улучшаем отображение для специальных клавиш
    local keyMap = {
        ["LeftControl"] = "L-Ctrl",
        ["RightControl"] = "R-Ctrl",
        ["LeftShift"] = "L-Shift",
        ["RightShift"] = "R-Shift",
        ["LeftAlt"] = "L-Alt",
        ["RightAlt"] = "R-Alt",
        ["Return"] = "Enter",
        ["Escape"] = "Esc",
        ["Backspace"] = "Back",
        ["Space"] = "Space",
        ["Tab"] = "Tab",
        ["CapsLock"] = "Caps",
        ["Insert"] = "Ins",
        ["Delete"] = "Del",
        ["Home"] = "Home",
        ["End"] = "End",
        ["PageUp"] = "PgUp",
        ["PageDown"] = "PgDn",
        ["Up"] = "↑",
        ["Down"] = "↓",
        ["Left"] = "←",
        ["Right"] = "→",
    }
    
    displayKey = keyMap[displayKey] or displayKey
    
    -- Обновляем текст
    Binds.KeyDisplay.titleLabel.Text = functionName
    Binds.KeyDisplay.label.Text = "[" .. displayKey .. "]"
    
    -- Показываем фрейм
    Binds.KeyDisplay.frame.Visible = true
    
    -- Устанавливаем таймер для скрытия
    if Binds.KeyDisplay.timer then
        Binds.KeyDisplay.timer:Disconnect()
    end
    
    if Binds.KeyDisplay.connection then
        Binds.KeyDisplay.connection:Disconnect()
    end
    
    -- Скрываем через 3 секунды
    Binds.KeyDisplay.timer = task.delay(3, function()
        Binds.KeyDisplay.frame.Visible = false
    end)
    
    -- Также скрываем при клике
    Binds.KeyDisplay.connection = Binds.KeyDisplay.frame.MouseButton1Click:Connect(function()
        Binds.KeyDisplay.frame.Visible = false
        if Binds.KeyDisplay.timer then
            Binds.KeyDisplay.timer:Disconnect()
            Binds.KeyDisplay.timer = nil
        end
    end)
    
    print("Key display shown: " .. functionName .. " = " .. displayKey)
end

function Binds.HideKeyDisplay()
    if Binds.KeyDisplay.frame then
        Binds.KeyDisplay.frame.Visible = false
    end
    
    if Binds.KeyDisplay.timer then
        Binds.KeyDisplay.timer:Disconnect()
        Binds.KeyDisplay.timer = nil
    end
    
    if Binds.KeyDisplay.connection then
        Binds.KeyDisplay.connection:Disconnect()
        Binds.KeyDisplay.connection = nil
    end
end

-- ========== CURSOR UNLOCK FUNCTIONS ==========

function Binds.ToggleCursorUnlock()
    if Binds.CursorUnlock.enabled then
        Binds.DisableCursorUnlock()
    else
        Binds.EnableCursorUnlock()
    end
end

function Binds.EnableCursorUnlock()
    if Binds.CursorUnlock.enabled then return end
    Binds.CursorUnlock.enabled = true
    
    if not Binds.CursorUnlock.connection then
        Binds.CursorUnlock.connection = Nexus.Services.RunService.Heartbeat:Connect(function()
            pcall(function()
                if Nexus.Services.UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default or
                   Nexus.Services.UserInputService.MouseIconEnabled ~= true then
                    Nexus.Services.UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                    Nexus.Services.UserInputService.MouseIconEnabled = true
                end
            end)
        end)
    end
    
    Nexus.Fluent:Notify({
        Title = "Cursor Unlock",
        Content = "Cursor unlocked and visible",
        Duration = 2
    })
    print("Cursor unlocked - cursor visible")
end

function Binds.DisableCursorUnlock()
    if not Binds.CursorUnlock.enabled then return end
    Binds.CursorUnlock.enabled = false
    
    if Binds.CursorUnlock.connection then
        Binds.CursorUnlock.connection:Disconnect()
        Binds.CursorUnlock.connection = nil
    end
    
    pcall(function()
        Nexus.Services.UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        Nexus.Services.UserInputService.MouseIconEnabled = false
    end)
    
    Nexus.Fluent:Notify({
        Title = "Cursor Unlock", 
        Content = "Cursor locked and hidden",
        Duration = 2
    })
    print("Cursor locked - cursor hidden")
end

function Binds.ResetCursorState()
    if Binds.CursorUnlock.connection then
        Binds.CursorUnlock.connection:Disconnect()
        Binds.CursorUnlock.connection = nil
    end
    Binds.CursorUnlock.enabled = false
    
    pcall(function()
        Nexus.Services.UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        Nexus.Services.UserInputService.MouseIconEnabled = true
    end)
    print("Cursor state reset to default")
end

-- ========== KEYBIND FUNCTIONS ==========

function Binds.ToggleOption(optionName)
    local option = Nexus.Options[optionName]
    if option then
        local currentState = option.Value
        option:SetValue(not currentState)
        
        Nexus.Fluent:Notify({
            Title = "Keybind",
            Content = optionName .. " " .. (not currentState and "enabled" or "disabled"),
            Duration = 2
        })
    end
end

function Binds.HandleKeybindChange(optionName, newKey)
    print("Keybind changed for " .. optionName .. " to: " .. tostring(newKey))
    
    Nexus.Fluent:Notify({
        Title = "Keybind Updated",
        Content = optionName .. " key set to: " .. tostring(newKey),
        Duration = 2
    })
end

-- ========== CLEANUP ==========

function Binds.Cleanup()
    Binds.DisableCursorUnlock()
    Binds.ResetCursorState()
    Binds.HideKeyDisplay()
    
    -- Удаляем GUI
    if Binds.KeyDisplay.gui then
        Binds.KeyDisplay.gui:Destroy()
        Binds.KeyDisplay.gui = nil
    end
    
    print("Binds module cleaned up")
end

return Binds
