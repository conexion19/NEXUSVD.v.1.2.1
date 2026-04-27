local Nexus = _G.Nexus

local Binds = {
    KeyStates = {}
}

local KEYBINDS_CONFIG = {
    Survivor = {
        { id = "AutoParryKeybind", title = "AutoParry", optionName = "AutoParry" },
        { id = "NoSlowdownKeybind", title = "No Slowdown", optionName = "NoSlowdown" },
        { id = "InstantHealKeybind", title = "Instant Heal", optionName = "InstantHeal" },
        { id = "SilentHealKeybind", title = "Silent Heal", optionName = "SilentHeal" },
        { id = "GateToolKeybind", title = "Gate Tool", optionName = "GateTool" },
        { id = "NoHitboxKeybind", title = "No Hitbox", optionName = "NoHitbox" },
        { id = "AutoSkillKeybind", title = "Auto Perfect Skill", optionName = "AutoPerfectSkill" },
        { id = "NoFallKeybind", title = "No Fall", optionName = "NoFall" },
        { id = "FakeParryKeybind", title = "Fake Parry", optionName = "FakeParry" },
        { id = "HealKeybind", title = "Gamemode", optionName = "Heal" },
        { id = "CrosshairKeybind", title = "Crosshair", optionName = "Crosshair" },
        { id = "RainbowCrosshairKeybind", title = "Rainbow Crosshair", optionName = "RainbowCrosshair" },
        { id = "AutoVictoryKeybind", title = "Auto Victory", optionName = "AutoVictory" }
    },
    Killer = {
        { id = "DestroyPalletsKeybind", title = "Destroy Pallets", optionName = "DestroyPallets" },
        { id = "KillerNoSlowdownKeybind", title = "Killer No Slowdown", optionName = "NoSlowdownKiller" },
        { id = "HitboxKeybind", title = "Hitbox Expand", optionName = "Hitbox" },
        { id = "BreakGeneratorKeybind", title = "Break Generator", optionName = "BreakGenerator" },
        { id = "ThirdPersonKeybind", title = "Third Person", optionName = "ThirdPerson" },
        { id = "NoPalletStunKeybind", title = "No Pallet Stun", optionName = "NoPalletStun" },
        { id = "DoubleTapKeybind", title = "Double Tap", optionName = "DoubleTap" },
        { id = "SpamHookKeybind", title = "Spam Hook", optionName = "SpamHook" },
        { id = "BeatGameKeybind", title = "Beat Game (Killer)", optionName = "BeatGame" },
        { id = "AntiBlindKeybind", title = "Anti Blind", optionName = "AntiBlind" },
        { id = "SpearCrosshairKeybind", title = "Spear Crosshair", optionName = "SpearCrosshair" }
    },
    Movement = {
        { id = "InfiniteLungeKeybind", title = "Infinite Lunge", optionName = "InfiniteLunge" },
        { id = "WalkSpeedKeybind", title = "Walk Speed", optionName = "WalkSpeed" },
        { id = "NoclipKeybind", title = "Noclip", optionName = "Noclip" },
        { id = "FOVKeybind", title = "FOV Changer", optionName = "FOVChanger" },
        { id = "FlyKeybind", title = "Fly", optionName = "Fly" },
        { id = "FreeCameraKeybind", title = "Free Camera", optionName = "FreeCamera" }
    }
}

function Binds.ToggleOption(optionName)
    local option = Nexus.Options[optionName]
    if option then
        option:SetValue(not option.Value)
    end
end

function Binds.UpdateKeyState(funcName)
    local option = Nexus.Options[funcName]
    Binds.KeyStates[funcName] = option and option.Value or not (Binds.KeyStates[funcName] or false)
end

function Binds.ResetAllBinds()
    for idx, option in pairs(Nexus.Options) do
        if option.Type == "Keybind" and idx ~= "MenuKeybind" then
            if option.Toggled then
                option.Toggled = false
                option:DoClick()
            end
            option:SetValue("", option.Mode)
        end
    end
    Binds.KeyStates = {}
end

function Binds.Init(nxs)
    Nexus = nxs
    if not Nexus.IS_DESKTOP then return end
    
    local Tabs = Nexus.Tabs
    if not Tabs.Binds then return end
    
    Tabs.Binds:AddButton({
        Title = "Reset All Binds",
        Description = "Reset all assigned keys",
        Callback = function()
            Binds.ResetAllBinds()
            Nexus.Notify("Binds", "All keybinds have been reset", 3)
        end
    })
    
    for sectionName, keybindsList in pairs(KEYBINDS_CONFIG) do
        Tabs.Binds:AddSection(sectionName .. (sectionName == "Survivor" and "" or " Binds"))
        
        for _, config in ipairs(keybindsList) do
            Tabs.Binds:AddKeybind(config.id, {
                Title = config.title,
                Mode = "Toggle",
                Default = "",
                Callback = function()
                    Binds.ToggleOption(config.optionName)
                    Binds.UpdateKeyState(config.optionName)
                end
            })
        end
    end
end

function Binds.Cleanup()
    Binds.ResetAllBinds()
    Binds.KeyStates = {}
    Binds.Keybinds = {}
end

return Binds
