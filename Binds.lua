-- Binds.lua - Модуль для привязок клавиш
local Nexus = require(script.Parent.NexusMain)

local BindsModule = {}

function BindsModule.Initialize(nexus)
    -- Этот модуль загружается только для десктопных устройств
    if not nexus.IS_DESKTOP then
        return BindsModule
    end
    
    local Tabs = nexus.Tabs
    local Options = nexus.Options
    local SafeCallback = nexus.SafeCallback
    
    local UserInputService = nexus.Services.UserInputService
    local RunService = nexus.Services.RunService
    
    -- ========== CURSOR UNLOCK ==========
    local CursorUnlock = {
        Enabled = false,
        Connection = nil
    }

    function CursorUnlock:Toggle(state)
        if state then
            if not self.Connection then
                self.Connection = RunService.Heartbeat:Connect(function()
                    SafeCallback(function()
                        if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default or
                           UserInputService.MouseIconEnabled ~= true then
                            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                            UserInputService.MouseIconEnabled = true
                        end
                    end)
                end)
            end
            nexus.Window:Notify({
                Title = "Cursor Unlock",
                Content = "Cursor unlocked and visible",
                Duration = 2
            })
            print("Cursor unlocked - cursor visible")
        else
            if self.Connection then
                self.Connection:Disconnect()
                self.Connection = nil
            end
            SafeCallback(function()
                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
                UserInputService.MouseIconEnabled = false
            end)
            nexus.Window:Notify({
                Title = "Cursor Unlock", 
                Content = "Cursor locked and hidden",
                Duration = 2
            })
            print("Cursor locked - cursor hidden")
        end
        self.Enabled = state
    end

    local function resetCursorState()
        if CursorUnlock.Connection then
            CursorUnlock.Connection:Disconnect()
            CursorUnlock.Connection = nil
        end
        CursorUnlock.Enabled = false
        
        SafeCallback(function()
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled = true
        end)
        print("Cursor state reset to default")
    end

    task.spawn(resetCursorState)

    nexus.Player.CharacterAdded:Connect(function()
        task.wait(1)
        resetCursorState()
    end)
    
    -- ========== СОЗДАНИЕ ЭЛЕМЕНТОВ ИНТЕРФЕЙСА ==========
    
    -- Cursor Toggle Keybind
    local CursorToggleKeybind = Tabs.Binds:AddKeybind("CursorToggleKeybind", {
        Title = "Cursor Toggle Keybind",
        Description = "Press to toggle cursor lock/unlock",
        Default = "",
        Callback = function()
            SafeCallback(function()
                CursorUnlock:Toggle(not CursorUnlock.Enabled)
            end)
        end,
        ChangedCallback = function(newKey)
            SafeCallback(function()
                nexus.Window:Notify({
                    Title = "Keybind Updated",
                    Content = "Cursor toggle key set to: " .. tostring(newKey),
                    Duration = 2
                })
            end)
        end
    })

    -- Survivor Keybinds
    Tabs.Binds:AddSection("Binds Survivor")

    local AutoParryKeybind = Tabs.Binds:AddKeybind("AutoParryKeybind", {
        Title = "AutoParry",
        Mode = "Toggle",
        Default = "",
        Callback = function(Value)
            SafeCallback(function()
                local currentState = Options.AutoParry.Value
                Options.AutoParry:SetValue(not currentState)
            end)
        end,
        ChangedCallback = function(New)
            SafeCallback(function()
                print("AutoParry keybind changed to:", New)
            end)
        end
    })

    local AutoParryV2Keybind = Tabs.Binds:AddKeybind("AutoParryV2Keybind", {
        Title = "AutoParry (Anti-Stun)",
        Mode = "Toggle",
        Default = "",
        Callback = function(Value)
            SafeCallback(function()
                local currentState = Options.AutoParryV2.Value
                Options.AutoParryV2:SetValue(not currentState)
            end)
        end,
        ChangedCallback = function(New)
            SafeCallback(function()
                print("AutoParryV2 keybind changed to:", New)
            end)
        end
    })

    local HealKeybindBinds = Tabs.Binds:AddKeybind("HealKeybindBinds", {
        Title = "Heal",
        Mode = "Toggle",
        Default = "",
        Callback = function(Value)
            SafeCallback(function()
                local currentState = Options.Heal.Value
                Options.Heal:SetValue(not currentState)
            end)
        end,
        ChangedCallback = function(New)
            SafeCallback(function()
                print("Heal keybind changed to:", New)
            end)
        end
    })

    local InstantHealKeybind = Tabs.Binds:AddKeybind("InstantHealKeybind", {
        Title = "Instant Heal",
        Mode = "Toggle",
        Default = "",
        Callback = function(Value)
            SafeCallback(function()
                local currentState = Options.InstantHeal.Value
                Options.InstantHeal:SetValue(not currentState)
            end)
        end,
        ChangedCallback = function(New)
            SafeCallback(function()
                print("InstantHeal keybind changed to:", New)
            end)
        end
    })

    local SilentHealKeybind = Tabs.Binds:AddKeybind("SilentHealKeybind", {
        Title = "Silent Heal",
        Mode = "Toggle",
        Default = "",
        Callback = function(Value)
            SafeCallback(function()
                local currentState = Options.SilentHeal.Value
                Options.SilentHeal:SetValue(not currentState)
            end)
        end,
        ChangedCallback = function(New)
            SafeCallback(function()
                print("SilentHeal keybind changed to:", New)
            end)
        end
    })

    local GateToolKeybind = Tabs.Binds:AddKeybind("GateToolKeybind", {
        Title = "Gate Tool",
        Mode = "Toggle",
        Default = "",
        Callback = function(Value)
            SafeCallback(function()
                local currentState = Options.GateTool.Value
                Options.GateTool:SetValue(not currentState)
            end)
        end,
        ChangedCallback = function(New)
            SafeCallback(function()
                print("GateTool keybind changed to:", New)
            end)
        end
    })

    local NoHitboxKeybind = Tabs.Binds:AddKeybind("NoHitboxKeybind", {
        Title = "No Hitbox",
        Mode = "Toggle",
        Default = "",
        Callback = function(Value)
            SafeCallback(function()
                local currentState = Options.NoHitbox.Value
                Options.NoHitbox:SetValue(not currentState)
            end)
        end,
        ChangedCallback = function(New)
            SafeCallback(function()
                print("NoHitbox keybind changed to:", New)
            end)
        end
    })

    local AntiFailKeybind = Tabs.Binds:AddKeybind("AntiFailKeybind", {
        Title = "Anti-Fail Generator",
        Mode = "Toggle",
        Default = "",
        Callback = function(Value)
            SafeCallback(function()
                local currentState = Options.AntiFailGenerator.Value
                Options.AntiFailGenerator:SetValue(not currentState)
            end)
        end,
        ChangedCallback = function(New)
            SafeCallback(function()
                print("AntiFailGenerator keybind changed to:", New)
            end)
        end
    })

    local AutoSkillKeybind = Tabs.Binds:AddKeybind("AutoSkillKeybind", {
        Title = "Auto Perfect Skill Check",
        Mode = "Toggle",
        Default = "",
        Callback = function(Value)
            SafeCallback(function()
                local currentState = Options.AutoPerfectSkill.Value
                Options.AutoPerfectSkill:SetValue(not currentState)
            end)
        end,
        ChangedCallback = function(New)
            SafeCallback(function()
                print("AutoPerfectSkill keybind changed to:", New)
            end)
        end
    })

    -- Killer Keybinds
    Tabs.Binds:AddSection("Killer Binds")

    local OneHitKillKeybind = Tabs.Binds:AddKeybind("OneHitKillKeybind", {
        Title = "OneHitKill",
        Mode = "Toggle",
        Default = "",
        Callback = function(Value)
            SafeCallback(function()
                local currentState = Options.OneHitKill.Value
                Options.OneHitKill:SetValue(not currentState)
            end)
        end,
        ChangedCallback = function(New)
            SafeCallback(function()
                print("OneHitKill keybind changed to:", New)
            end)
        end
    })

    local AntiBlindKeybind = Tabs.Binds:AddKeybind("AntiBlindKeybind", {
        Title = "Anti Blind",
        Mode = "Toggle",
        Default = "",
        Callback = function(Value)
            SafeCallback(function()
                local currentState = Options.AntiBlind.Value
                Options.AntiBlind:SetValue(not currentState)
            end)
        end,
        ChangedCallback = function(New)
            SafeCallback(function()
                print("AntiBlind keybind changed to:", New)
            end)
        end
    })

    -- Movement Keybinds
    Tabs.Binds:AddSection("Movement Binds")

    local InfiniteLungeKeybind = Tabs.Binds:AddKeybind("InfiniteLungeKeybind", {
        Title = "Infinite Lunge",
        Mode = "Toggle",
        Default = "",
        Callback = function(Value)
            SafeCallback(function()
                local currentState = Options.InfiniteLunge.Value
                Options.InfiniteLunge:SetValue(not currentState)
            end)
        end,
        ChangedCallback = function(New)
            SafeCallback(function()
                print("InfiniteLunge keybind changed to:", New)
            end)
        end
    })

    local WalkSpeedKeybind = Tabs.Binds:AddKeybind("WalkSpeedKeybind", {
        Title = "Walk Speed",
        Mode = "Toggle",
        Default = "",
        Callback = function(Value)
            SafeCallback(function()
                local currentState = Options.WalkSpeed.Value
                Options.WalkSpeed:SetValue(not currentState)
            end)
        end,
        ChangedCallback = function(New)
            SafeCallback(function()
                print("WalkSpeed keybind changed to:", New)
            end)
        end
    })

    local NoclipKeybind = Tabs.Binds:AddKeybind("NoclipKeybind", {
        Title = "Noclip",
        Mode = "Toggle",
        Default = "",
        Callback = function(Value)
            SafeCallback(function()
                local currentState = Options.Noclip.Value
                Options.Noclip:SetValue(not currentState)
            end)
        end,
        ChangedCallback = function(New)
            SafeCallback(function()
                print("Noclip keybind changed to:", New)
            end)
        end
    })

    local FOVKeybind = Tabs.Binds:AddKeybind("FOVKeybind", {
        Title = "FOV Changer",
        Mode = "Toggle",
        Default = "",
        Callback = function(Value)
            SafeCallback(function()
                local currentState = Options.FOVChanger.Value
                Options.FOVChanger:SetValue(not currentState)
            end)
        end,
        ChangedCallback = function(New)
            SafeCallback(function()
                print("FOVChanger keybind changed to:", New)
            end)
        end
    })

    local FlyKeybind = Tabs.Binds:AddKeybind("FlyKeybind", {
        Title = "Fly",
        Mode = "Toggle",
        Default = "",
        Callback = function(Value)
            SafeCallback(function()
                local currentState = Options.Fly.Value
                Options.Fly:SetValue(not currentState)
            end)
        end,
        ChangedCallback = function(New)
            SafeCallback(function()
                print("Fly keybind changed to:", New)
            end)
        end
    })

    local FreeCameraKeybind = Tabs.Binds:AddKeybind("FreeCameraKeybind", {
        Title = "Free Camera",
        Mode = "Toggle",
        Default = "",
        Callback = function(Value)
            SafeCallback(function()
                local currentState = Options.FreeCamera.Value
                Options.FreeCamera:SetValue(not currentState)
            end)
        end,
        ChangedCallback = function(New)
            SafeCallback(function()
                print("FreeCamera keybind changed to:", New)
            end)
        end
    })

    -- Visual Keybinds
    Tabs.Binds:AddSection("Visual Binds")

    local NoShadowKeybind = Tabs.Binds:AddKeybind("NoShadowKeybind", {
        Title = "No Shadow",
        Mode = "Toggle",
        Default = "",
        Callback = function(Value)
            SafeCallback(function()
                local currentState = Options.NoShadow.Value
                Options.NoShadow:SetValue(not currentState)
            end)
        end,
        ChangedCallback = function(New)
            SafeCallback(function()
                print("NoShadow keybind changed to:", New)
            end)
        end
    })

    local NoFogKeybind = Tabs.Binds:AddKeybind("NoFogKeybind", {
        Title = "No Fog",
        Mode = "Toggle",
        Default = "",
        Callback = function(Value)
            SafeCallback(function()
                local currentState = Options.NoFog.Value
                Options.NoFog:SetValue(not currentState)
            end)
        end,
        ChangedCallback = function(New)
            SafeCallback(function()
                print("NoFog keybind changed to:", New)
            end)
        end
    })

    local FullBrightKeybind = Tabs.Binds:AddKeybind("FullBrightKeybind", {
        Title = "FullBright",
        Mode = "Toggle",
        Default = "",
        Callback = function(Value)
            SafeCallback(function()
                local currentState = Options.FullBright.Value
                Options.FullBright:SetValue(not currentState)
            end)
        end,
        ChangedCallback = function(New)
            SafeCallback(function()
                print("FullBright keybind changed to:", New)
            end)
        end
    })

    local TimeChangerKeybind = Tabs.Binds:AddKeybind("TimeChangerKeybind", {
        Title = "Time Changer",
        Mode = "Toggle",
        Default = "",
        Callback = function(Value)
            SafeCallback(function()
                local currentState = Options.TimeChanger.Value
                Options.TimeChanger:SetValue(not currentState)
            end)
        end,
        ChangedCallback = function(New)
            SafeCallback(function()
                print("TimeChanger keybind changed to:", New)
            end)
        end
    })

    -- ESP Keybinds
    local ESPSurvivorsKeybind = Tabs.Binds:AddKeybind("ESPSurvivorsKeybind", {
        Title = "Survivors ESP",
        Mode = "Toggle",
        Default = "",
        Callback = function(Value)
            SafeCallback(function()
                local currentState = Options.ESPSurvivors.Value
                Options.ESPSurvivors:SetValue(not currentState)
            end)
        end,
        ChangedCallback = function(New)
            SafeCallback(function()
                print("ESPSurvivors keybind changed to:", New)
            end)
        end
    })

    local ESPKillersKeybind = Tabs.Binds:AddKeybind("ESPKillersKeybind", {
        Title = "Killers ESP",
        Mode = "Toggle",
        Default = "",
        Callback = function(Value)
            SafeCallback(function()
                local currentState = Options.ESPKillers.Value
                Options.ESPKillers:SetValue(not currentState)
            end)
        end,
        ChangedCallback = function(New)
            SafeCallback(function()
                print("ESPKillers keybind changed to:", New)
            end)
        end
    })

    local ESPHooksKeybind = Tabs.Binds:AddKeybind("ESPHooksKeybind", {
        Title = "Hooks ESP",
        Mode = "Toggle",
        Default = "",
        Callback = function(Value)
            SafeCallback(function()
                local currentState = Options.ESPHooks.Value
                Options.ESPHooks:SetValue(not currentState)
            end)
        end,
        ChangedCallback = function(New)
            SafeCallback(function()
                print("ESPHooks keybind changed to:", New)
            end)
        end
    })

    local ESPGeneratorsKeybind = Tabs.Binds:AddKeybind("ESPGeneratorsKeybind", {
        Title = "Generators ESP",
        Mode = "Toggle",
        Default = "",
        Callback = function(Value)
            SafeCallback(function()
                local currentState = Options.ESPGenerators.Value
                Options.ESPGenerators:SetValue(not currentState)
            end)
        end,
        ChangedCallback = function(New)
            SafeCallback(function()
                print("ESPGenerators keybind changed to:", New)
            end)
        end
    })

    local ESPPalletsKeybind = Tabs.Binds:AddKeybind("ESPPalletsKeybind", {
        Title = "Pallets ESP",
        Mode = "Toggle",
        Default = "",
        Callback = function(Value)
            SafeCallback(function()
                local currentState = Options.ESPPallets.Value
                Options.ESPPallets:SetValue(not currentState)
            end)
        end,
        ChangedCallback = function(New)
            SafeCallback(function()
                print("ESPPallets keybind changed to:", New)
            end)
        end
    })

    local ESPGatesKeybind = Tabs.Binds:AddKeybind("ESPGatesKeybind", {
        Title = "Exit Gates ESP",
        Mode = "Toggle",
        Default = "",
        Callback = function(Value)
            SafeCallback(function()
                local currentState = Options.ESPGates.Value
                Options.ESPGates:SetValue(not currentState)
            end)
        end,
        ChangedCallback = function(New)
            SafeCallback(function()
                print("ESPGates keybind changed to:", New)
            end)
        end
    })

    local ESPWindowsKeybind = Tabs.Binds:AddKeybind("ESPWindowsKeybind", {
        Title = "Windows ESP",
        Mode = "Toggle",
        Default = "",
        Callback = function(Value)
            SafeCallback(function()
                local currentState = Options.ESPWindows.Value
                Options.ESPWindows:SetValue(not currentState)
            end)
        end,
        ChangedCallback = function(New)
            SafeCallback(function()
                print("ESPWindows keybind changed to:", New)
            end)
        end
    })
    
    -- Сохраняем функции в Nexus
    nexus.Functions.CursorUnlock = CursorUnlock
    nexus.Functions.resetCursorState = resetCursorState
    
    return BindsModule
end

return BindsModule
