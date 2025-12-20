--Fun.lua
-- Fun Module - Emotes and other fun functions
local Nexus = _G.Nexus

local Fun = {
    CurrentEmoteTrack = nil,
    CurrentSound = nil,
    CurrentAnimation = nil,
    AvailableEmotes = {},
    EmotesFolder = nil,
    JerkTool = {
        active = false,
        tool = nil,
        track = nil
    }
}

function Fun.Init(nxs)
    Nexus = nxs
    
    local Tabs = Nexus.Tabs
    
    -- ========== EMOTES SYSTEM ==========
    local emotesInitialized = Fun.InitializeEmotesSystem()
    
    if emotesInitialized then
        local emotesList = {}
        for _, emote in ipairs(Fun.AvailableEmotes) do
            table.insert(emotesList, emote)
        end
        table.insert(emotesList, "Jerk")
        
        local SelectedEmote = Tabs.Fun:AddDropdown("SelectedEmote", {
            Title = "Select Emote", 
            Description = "", 
            Values = emotesList, 
            Multi = false, 
            Default = ""
        })
        
        SelectedEmote:OnChanged(function(value) 
            Nexus.SafeCallback(function()
                if value and value ~= "" then 
                    if value == "Jerk" then
                        Fun.StartJerk()
                    else
                        Fun.PlayEmote(value) 
                    end
                end 
            end)
        end)

        Tabs.Fun:AddButton({
            Title = "Stop Current Emote", 
            Description = "", 
            Callback = function()
                Nexus.SafeCallback(Fun.StopEmote)
            end
        })
    else
        Tabs.Fun:AddButton({
            Title = "Jerk Tool", 
            Description = "Adds Jerk Off tool to your backpack", 
            Callback = function()
                Nexus.SafeCallback(Fun.StartJerk)
            end
        })
    end
    
    -- ========== ADDITIONAL FUNCTIONS ==========
    Tabs.Fun:AddButton({
        Title = "Reset Character", 
        Description = "Resets your character", 
        Callback = function()
            Nexus.SafeCallback(Fun.ResetCharacter)
        end
    })
    
    Tabs.Fun:AddButton({
        Title = "Rejoin Game", 
        Description = "Rejoins the current game", 
        Callback = function()
            Nexus.SafeCallback(Fun.RejoinGame)
        end
    })
    
    Tabs.Fun:AddSection("Fun Settings")
    
    local AutoDanceToggle = Tabs.Fun:AddToggle("AutoDance", {
        Title = "Auto Dance", 
        Description = "Automatically dances when idle", 
        Default = false
    })
    
    AutoDanceToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            Fun.ToggleAutoDance(v)
        end)
    end)

    print("✓ Fun module initialized")
end

-- ========== EMOTES FUNCTIONS ==========

function Fun.InitializeEmotesSystem()
    if not Nexus.Services.ReplicatedStorage:FindFirstChild("Emotes") then 
        return false 
    end
    
    Fun.EmotesFolder = Nexus.Services.ReplicatedStorage:WaitForChild("Emotes")
    Fun.AvailableEmotes = {}
    
    for _, folder in pairs(Fun.EmotesFolder:GetChildren()) do
        if folder:IsA("Folder") then 
            table.insert(Fun.AvailableEmotes, folder.Name) 
        end
    end
    
    table.sort(Fun.AvailableEmotes)
    return true
end

function Fun.PlayEmote(emoteName)
    -- Останавливаем предыдущий эмот
    Fun.StopEmote()
    
    local emoteFolder = Fun.EmotesFolder:FindFirstChild(emoteName)
    if not emoteFolder then 
        Nexus.Fluent:Notify({
            Title = "Emote Error",
            Content = "Emote not found: " .. emoteName,
            Duration = 3
        })
        return false 
    end
    
    local animationId = emoteFolder:GetAttribute("animationid")
    local soundId = emoteFolder:GetAttribute("Song")
    
    if not animationId then 
        Nexus.Fluent:Notify({
            Title = "Emote Error",
            Content = "No animation found for emote",
            Duration = 3
        })
        return false 
    end
    
    local character = Nexus.getCharacter()
    local humanoid = Nexus.getHumanoid()
    if not character or not humanoid then return false end
    
    -- Создаем анимацию
    local animation = Instance.new("Animation")
    animation.AnimationId = animationId
    Fun.CurrentAnimation = animation
    
    -- Загружаем и воспроизводим трек
    local animationTrack = humanoid:LoadAnimation(animation)
    animationTrack:Play(0.1, 1, 1)
    Fun.CurrentEmoteTrack = animationTrack
    
    -- Воспроизводим звук если есть
    if soundId and soundId ~= "" then
        local head = character:FindFirstChild("Head")
        if head then
            local sound = Instance.new("Sound")
            sound.SoundId = soundId
            sound.Parent = head
            sound:Play()
            Fun.CurrentSound = sound
            
            sound.Ended:Connect(function()
                if sound == Fun.CurrentSound then 
                    sound:Destroy()
                    Fun.CurrentSound = nil 
                end
            end)
        end
    end
    
    Nexus.Fluent:Notify({
        Title = "Emote",
        Content = "Playing: " .. emoteName,
        Duration = 2
    })
    
    return true
end

function Fun.StopEmote()
    if Fun.CurrentEmoteTrack then 
        Fun.CurrentEmoteTrack:Stop()
        Fun.CurrentEmoteTrack = nil 
    end
    
    if Fun.CurrentSound then 
        Fun.CurrentSound:Stop()
        Fun.CurrentSound:Destroy()
        Fun.CurrentSound = nil 
    end
    
    Fun.CurrentAnimation = nil
end

-- ========== JERK FUNCTION ==========

function Fun.StartJerk()
    Nexus.SafeCallback(function()
        local humanoid = Nexus.getHumanoid()
        local backpack = Nexus.Player:FindFirstChildWhichIsA("Backpack")
        if not humanoid or not backpack then 
            Nexus.Fluent:Notify({
                Title = "Error",
                Content = "Character not found",
                Duration = 3
            })
            return 
        end

        -- Удаляем старый инструмент если есть
        if Fun.JerkTool.tool then
            Fun.StopJerk()
        end

        -- Создаем новый инструмент
        local tool = Instance.new("Tool")
        tool.Name = "Jerk Off"
        tool.ToolTip = ""
        tool.RequiresHandle = false
        tool.Parent = backpack

        Fun.JerkTool.tool = tool
        Fun.JerkTool.active = true

        -- Функция для остановки
        local function stopTomfoolery()
            Fun.JerkTool.active = false
            if Fun.JerkTool.track then
                Fun.JerkTool.track:Stop()
                Fun.JerkTool.track = nil
            end
        end

        -- Подключаем события
        tool.Equipped:Connect(function() 
            Fun.JerkTool.active = true 
        end)
        
        tool.Unequipped:Connect(stopTomfoolery)
        
        humanoid.Died:Connect(stopTomfoolery)

        -- Основной цикл
        task.spawn(function()
            while task.wait() do
                if not Fun.JerkTool.active then continue end

                local function r15(speaker)
                    local character = speaker.Character
                    if not character then return false end
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    if not humanoid then return false end
                    return humanoid.RigType == Enum.HumanoidRigType.R15
                end
                
                local isR15 = r15(Nexus.Player)
                
                if not Fun.JerkTool.track then
                    local anim = Instance.new("Animation")
                    anim.AnimationId = not isR15 and "rbxassetid://72042024" or "rbxassetid://698251653"
                    Fun.JerkTool.track = humanoid:LoadAnimation(anim)
                end

                Fun.JerkTool.track:Play()
                Fun.JerkTool.track:AdjustSpeed(isR15 and 0.7 or 0.65)
                Fun.JerkTool.track.TimePosition = 0.6
                
                task.wait(0.1)
                
                while Fun.JerkTool.track and Fun.JerkTool.track.TimePosition < (not isR15 and 0.65 or 0.7) do 
                    task.wait(0.1) 
                end
                
                if Fun.JerkTool.track then
                    Fun.JerkTool.track:Stop()
                    Fun.JerkTool.track = nil
                end
            end
        end)
        
        Nexus.Fluent:Notify({
            Title = "Jerk Tool",
            Content = "Tool added to backpack",
            Duration = 3
        })
    end)
end

function Fun.StopJerk()
    if Fun.JerkTool.track then
        Fun.JerkTool.track:Stop()
        Fun.JerkTool.track = nil
    end
    
    if Fun.JerkTool.tool then
        Fun.JerkTool.tool:Destroy()
        Fun.JerkTool.tool = nil
    end
    
    Fun.JerkTool.active = false
end

-- ========== ADDITIONAL FUNCTIONS ==========

function Fun.ResetCharacter()
    local character = Nexus.getCharacter()
    if character then
        local humanoid = Nexus.getHumanoid()
        if humanoid then
            humanoid.Health = 0
            Nexus.Fluent:Notify({
                Title = "Reset",
                Content = "Character reset",
                Duration = 2
            })
        end
    end
end

function Fun.RejoinGame()
    local TeleportService = game:GetService("TeleportService")
    local placeId = game.PlaceId
    local jobId = game.JobId
    
    TeleportService:TeleportToPlaceInstance(placeId, jobId, Nexus.Player)
end

function Fun.ToggleAutoDance(enabled)
    if enabled then
        Nexus.Fluent:Notify({
            Title = "Auto Dance",
            Content = "Auto dance enabled",
            Duration = 2
        })
        -- Реализация авто-танца
    else
        -- Отключение авто-танца
    end
end

-- ========== CLEANUP ==========

function Fun.Cleanup()
    Fun.StopEmote()
    Fun.StopJerk()
    
    print("Fun module cleaned up")
end

return Fun
