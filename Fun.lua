-- Fun.lua - Модуль для развлекательных функций
local Nexus = require(script.Parent.NexusMain)

local FunModule = {}

function FunModule.Initialize(nexus)
    local Tabs = nexus.Tabs
    local Options = nexus.Options
    local SafeCallback = nexus.SafeCallback
    
    local player = nexus.Player
    local ReplicatedStorage = nexus.Services.ReplicatedStorage
    
    -- ========== EMOTES SYSTEM ==========
    local CurrentEmoteTrack, CurrentSound, CurrentAnimation = nil, nil, nil
    local AvailableEmotes, EmotesFolder = {}, nil

    local function InitializeEmotesSystem()
        if not ReplicatedStorage:FindFirstChild("Emotes") then return false end
        
        EmotesFolder = ReplicatedStorage:WaitForChild("Emotes")
        AvailableEmotes = {}
        
        for _, folder in pairs(EmotesFolder:GetChildren()) do
            if folder:IsA("Folder") then table.insert(AvailableEmotes, folder.Name) end
        end
        
        table.sort(AvailableEmotes)
        return true
    end

    local function PlayEmote(emoteName)
        if CurrentEmoteTrack then CurrentEmoteTrack:Stop(); CurrentEmoteTrack = nil end
        if CurrentSound then CurrentSound:Stop(); CurrentSound:Destroy(); CurrentSound = nil end
        CurrentAnimation = nil
        
        local emoteFolder = EmotesFolder:FindFirstChild(emoteName)
        if not emoteFolder then return false end
        
        local animationId, soundId = emoteFolder:GetAttribute("animationid"), emoteFolder:GetAttribute("Song")
        if not animationId then return false end
        
        local character, humanoid = player.Character, player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if not character or not humanoid then return false end
        
        local animation = Instance.new("Animation")
        animation.AnimationId = animationId
        local animationTrack = humanoid:LoadAnimation(animation)
        animationTrack:Play(0.1, 1, 1)
        CurrentEmoteTrack, CurrentAnimation = animationTrack, animation
        
        if soundId and soundId ~= "" then
            local head = character:FindFirstChild("Head")
            if head then
                local sound = Instance.new("Sound")
                sound.SoundId, sound.Parent = soundId, head
                sound:Play()
                CurrentSound = sound
                sound.Ended:Connect(function()
                    if sound == CurrentSound then sound:Destroy(); CurrentSound = nil end
                end)
            end
        end
        return true
    end

    local StopEmote = function()
        if CurrentEmoteTrack then CurrentEmoteTrack:Stop(); CurrentEmoteTrack = nil end
        if CurrentSound then CurrentSound:Stop(); CurrentSound:Destroy(); CurrentSound = nil end
        CurrentAnimation = nil
    end

    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")
        humanoid.Died:Connect(StopEmote)
    end)

    if player.Character then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.Died:Connect(StopEmote) end
    end
    
    -- ========== JERK FUNCTION ==========
    local function JerkFunction()
        SafeCallback(function()
            local humanoid = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
            local backpack = player:FindFirstChildWhichIsA("Backpack")
            if not humanoid or not backpack then 
                return 
            end

            local tool = Instance.new("Tool")
            tool.Name = "Jerk Off"
            tool.ToolTip = ""
            tool.RequiresHandle = false
            tool.Parent = backpack

            local jorkin = false
            local track = nil

            local function stopTomfoolery()
                jorkin = false
                if track then
                    track:Stop()
                    track = nil
                end
            end

            tool.Equipped:Connect(function() jorkin = true end)
            tool.Unequipped:Connect(stopTomfoolery)
            humanoid.Died:Connect(stopTomfoolery)

            task.spawn(function()
                while task.wait() do
                    if not jorkin then continue end

                    local function r15(speaker)
                        local character = speaker.Character
                        if not character then return false end
                        local humanoid = character:FindFirstChildOfClass("Humanoid")
                        if not humanoid then return false end
                        return humanoid.RigType == Enum.HumanoidRigType.R15
                    end
                    
                    local isR15 = r15(player)
                    if not track then
                        local anim = Instance.new("Animation")
                        anim.AnimationId = not isR15 and "rbxassetid://72042024" or "rbxassetid://698251653"
                        track = humanoid:LoadAnimation(anim)
                    end

                    track:Play()
                    track:AdjustSpeed(isR15 and 0.7 or 0.65)
                    track.TimePosition = 0.6
                    task.wait(0.1)
                    while track and track.TimePosition < (not isR15 and 0.65 or 0.7) do task.wait(0.1) end
                    if track then
                        track:Stop()
                        track = nil
                    end
                end
            end)
        end)
    end
    
    -- ========== СОЗДАНИЕ ЭЛЕМЕНТОВ ИНТЕРФЕЙСА ==========
    
    local emotesInitialized = InitializeEmotesSystem()

    if emotesInitialized then
        local emotesList = {}
        for _, emote in ipairs(AvailableEmotes) do
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
            SafeCallback(function()
                if value and value ~= "" then 
                    if value == "Jerk" then
                        JerkFunction()
                    else
                        PlayEmote(value) 
                    end
                end 
            end)
        end)

        Tabs.Fun:AddButton({
            Title = "Stop Current Emote", 
            Description = "", 
            Callback = function()
                SafeCallback(StopEmote)
            end
        })
    else
        Tabs.Fun:AddButton({
            Title = "Jerk Tool", 
            Description = "Adds Jerk Off tool to your backpack", 
            Callback = function()
                SafeCallback(JerkFunction)
            end
        })
    end
    
    -- Сохраняем функции в Nexus
    nexus.Functions.PlayEmote = PlayEmote
    nexus.Functions.StopEmote = StopEmote
    nexus.Functions.JerkFunction = JerkFunction
    
    return FunModule
end

return FunModule
