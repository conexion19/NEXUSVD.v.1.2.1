-- Binds Module - Keybinds for all functions
local Nexus = _G.Nexus

local Binds = {
    Keybinds = {},
    CursorUnlock = {
        enabled = false,
        connection = nil
    },
    Display = {
        gui = nil,
        textLabel = nil,
        activeBinds = {} -- {["AutoParry"] = "F1", ["WalkSpeed"] = "F2"}
    }
}

function Binds.Init(nxs)
    Nexus = nxs
    
    if not Nexus.IS_DESKTOP then return end
    
    local Tabs = Nexus.Tabs
    if not Tabs.Binds then return end
    
    -- ========== СОЗДАЕМ ОТОБРАЖЕНИЕ СВЕРХУ ==========
    Binds.CreateTopDisplay()
    
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
                -- Выводим в консоль и обновляем отображение
                print("[BINDS] Cursor Toggle назначен на: " .. tostring(newKey))
                Binds.UpdateDisplay("Cursor Toggle", newKey)
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
            print("[BINDS] AutoParry назначен на: " .. tostring(newKey))
            Binds.UpdateDisplay("AutoParry", newKey)
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
            print("[BINDS] AutoParryV2 назначен на: " .. tostring(newKey))
            Binds.UpdateDisplay("AutoParryV2", newKey)
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
            print("[BINDS] Heal назначен на: " .. tostring(newKey))
            Binds.UpdateDisplay("Heal", newKey)
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
            print("[BINDS] InstantHeal назначен на: " .. tostring(newKey))
            Binds.UpdateDisplay("InstantHeal", newKey)
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
            print("[BINDS] SilentHeal назначен на: " .. tostring(newKey))
            Binds.UpdateDisplay("SilentHeal", newKey)
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
            print("[BINDS] GateTool назначен на: " .. tostring(newKey))
            Binds.UpdateDisplay("GateTool", newKey)
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
            print("[BINDS] NoHitbox назначен на: " .. tostring(newKey))
            Binds.UpdateDisplay("NoHitbox", newKey)
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
            print("[BINDS] AutoPerfectSkill назначен на: " .. tostring(newKey))
            Binds.UpdateDisplay("AutoPerfectSkill", newKey)
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
            print("[BINDS] OneHitKill назначен на: " .. tostring(newKey))
            Binds.UpdateDisplay("OneHitKill", newKey)
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
            print("[BINDS] AntiBlind назначен на: " .. tostring(newKey))
            Binds.UpdateDisplay("AntiBlind", newKey)
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
            print("[BINDS] NoSlowdown назначен на: " .. tostring(newKey))
            Binds.UpdateDisplay("NoSlowdown", newKey)
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
            print("[BINDS] DestroyPallets назначен на: " .. tostring(newKey))
            Binds.UpdateDisplay("DestroyPallets", newKey)
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
            print("[BINDS] BreakGenerator назначен на: " .. tostring(newKey))
            Binds.UpdateDisplay("BreakGenerator", newKey)
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
            print("[BINDS] InfiniteLunge назначен на: " .. tostring(newKey))
            Binds.UpdateDisplay("InfiniteLunge", newKey)
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
            print("[BINDS] WalkSpeed назначен на: " .. tostring(newKey))
            Binds.UpdateDisplay("WalkSpeed", newKey)
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
            print("[BINDS] Noclip назначен на: " .. tostring(newKey))
            Binds.UpdateDisplay("Noclip", newKey)
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
            print("[BINDS] FOVChanger назначен на: " .. tostring(newKey))
            Binds.UpdateDisplay("FOVChanger", newKey)
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
            print("[BINDS] Fly назначен на: " .. tostring(newKey))
            Binds.UpdateDisplay("Fly", newKey)
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
            print("[BINDS] FreeCamera назначен на: " .. tostring(newKey))
            Binds.UpdateDisplay("FreeCamera", newKey)
        end
    })
end

-- ========== DISPLAY FUNCTIONS ==========

function Binds.CreateTopDisplay()
    -- Создаем простой текст сверху экрана
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BindDisplay"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "BindText"
    textLabel.Size = UDim2.new(1, 0, 0, 30)
    textLabel.Position = UDim2.new(0, 0, 0, 10)
    textLabel.BackgroundTransparency = 1 -- Прозрачный фон
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- Белый текст
    textLabel.Text = "Binds: "
    textLabel.Font = Enum.Font.GothamMedium
    textLabel.TextSize = 18
    textLabel.TextWrapped = false
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.TextYAlignment = Enum.TextYAlignment.Top
    
    -- Тень для лучшей читаемости
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 0, 0)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.2
    stroke.Parent = textLabel
    
    textLabel.Parent = screenGui
    
    -- Сохраняем ссылки
    Binds.Display.gui = screenGui
    Binds.Display.textLabel = textLabel
    
    -- Встраиваем GUI
    if Nexus and Nexus.Player then
        screenGui.Parent = Nexus.Player:WaitForChild("PlayerGui")
    else
        screenGui.Parent = game:GetService("CoreGui")
    end
    
    print("[BINDS] Display created at top of screen")
end

function Binds.UpdateDisplay(bindName, key)
    -- Если клавиша пустая, удаляем бинд
    if not key or key == "" then
        Binds.Display.activeBinds[bindName] = nil
    else
        -- Сохраняем бинд
        Binds.Display.activeBinds[bindName] = key
    end
    
    -- Обновляем текст на экране
    Binds.RefreshDisplayText()
end

function Binds.RefreshDisplayText()
    local textLabel = Binds.Display.textLabel
    if not textLabel then return end
    
    -- Собираем все активные бинды
    local displayText = "Binds: "
    local bindCount = 0
    
    local sortedBinds = {}
    for name, key in pairs(Binds.Display.activeBinds) do
        if key and key ~= "" then
            table.insert(sortedBinds, {name = name, key = key})
        end
    end
    
    -- Сортируем по алфавиту
    table.sort(sortedBinds, function(a, b)
        return a.name < b.name
    end)
    
    -- Формируем текст
    for i, bind in ipairs(sortedBinds) do
        if i > 1 then
            displayText = displayText .. " | "
        end
        displayText = displayText .. bind.name .. ": " .. bind.key
        bindCount = bindCount + 1
    end
    
    -- Если нет биндов, скрываем текст
    if bindCount == 0 then
        textLabel.Text = ""
    else
        textLabel.Text = displayText
    end
    
    -- Выводим в консоль текущие бинды
    print("[BINDS] Current binds: " .. displayText)
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
    print("[BINDS] Keybind changed for " .. optionName .. " to: " .. tostring(newKey))
    
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
    
    -- Удаляем GUI
    if Binds.Display.gui then
        Binds.Display.gui:Destroy()
        Binds.Display.gui = nil
    end
    
    -- Очищаем данные
    Binds.Display.activeBinds = {}
    
    print("[BINDS] Binds module cleaned up")
end

return Binds
