local Nexus = _G.Nexus

local Visual = {
    Connections = {},
    ESP = {
        lastUpdate = 0,
        UPDATE_INTERVAL = 0.10,
        settings = {
            Survivors  = {Enabled=false, Color=Color3.fromRGB(100,255,100), Colorpicker = nil},
            Killers    = {Enabled=false, Color=Color3.fromRGB(255,100,100), Colorpicker = nil},
            Generators = {Enabled=false, Color=Color3.fromRGB(100,170,255)},
            Pallets    = {Enabled=false, Color=Color3.fromRGB(120,80,40), Colorpicker = nil},
            ExitGates  = {Enabled=false, Color=Color3.fromRGB(200,200,100), Colorpicker = nil},
            Windows    = {Enabled=false, Color=Color3.fromRGB(100,200,200), Colorpicker = nil},
            Hooks      = {Enabled=false, Color=Color3.fromRGB(100, 50, 150), Colorpicker = nil}
        },
        boxESP = {
            enabled = false,
            teamCheck = false,
            color = Color3.fromRGB(255, 255, 255),
            colorpicker = nil
        },
        namesESP = {
            enabled = false,
            color = Color3.fromRGB(255, 255, 255),
            colorpicker = nil
        },
        trackedObjects = {},
        espConnections = {},
        espLoopRunning = false,
        showGeneratorPercent = true,
        boxObjects = {},
        nameLabels = {}
    },
    Effects = {
        noShadowEnabled = false,
        noFogEnabled = false,
        fullbrightEnabled = false,
        timeChangerEnabled = false,
        originalFogEnd = nil,
        originalFogStart = nil,
        originalFogColor = nil,
        fogCache = nil,
        originalClockTime = nil,
        originalAtmosphere = {},
        originalPostEffects = {}
    }
}

function Visual.GetGeneratorProgress(gen)
    local progress = 0
    if gen:GetAttribute("Progress") then
        progress = gen:GetAttribute("Progress")
    elseif gen:GetAttribute("RepairProgress") then
        progress = gen:GetAttribute("RepairProgress")
    else
        for _, child in ipairs(gen:GetDescendants()) do
            if child:IsA("NumberValue") or child:IsA("IntValue") then
                local n = child.Name:lower()
                if n:find("progress") or n:find("repair") or n:find("percent") then
                    progress = child.Value
                    break
                end
            end
        end
    end
    progress = (progress > 1) and progress / 100 or progress
    return math.clamp(progress, 0, 1)
end

function Visual.EnsureHighlight(model, color, isObject)
    if not model then return end
    local hl = model:FindFirstChild("VD_HL")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "VD_HL"
        hl.Adornee = model
        hl.FillColor = color
        hl.FillTransparency = 0.8
        hl.OutlineColor = Color3.fromRGB(0,0,0)
        hl.OutlineTransparency = 0.1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = model
    else
        hl.FillColor = color
        if isObject then
            hl.OutlineColor = Color3.fromRGB(0,0,0)
            hl.FillTransparency = 0.7
            hl.OutlineTransparency = 0.1
        else
            hl.OutlineColor = Color3.fromRGB(0,0,0)
            hl.FillTransparency = 0.7
            hl.OutlineTransparency = 0.1
        end
    end
end

function Visual.ClearHighlight(model)
    if model and model:FindFirstChild("VD_HL") then
        pcall(function() model.VD_HL:Destroy() end)
    end
end

function Visual.EnsureLabel(model, text, isGenerator, textColor)
    if not model then return end
    local lbl = model:FindFirstChild("VD_Label")
    if not lbl then
        lbl = Instance.new("BillboardGui")
        lbl.Name = "VD_Label"
        if isGenerator then
            lbl.Size = UDim2.new(0,100,0,25)
            lbl.StudsOffset = Vector3.new(0,2.5,0)
        else
            lbl.Size = UDim2.new(0,120,0,20)
            lbl.StudsOffset = Vector3.new(0,3,0)
        end
        lbl.AlwaysOnTop = true
        lbl.MaxDistance = 1000
        lbl.Parent = model
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "TextLabel"
        textLabel.Size = UDim2.new(1,0,1,0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextScaled = false
        if isGenerator then
            textLabel.TextSize = 10
        else
            textLabel.TextSize = 10
        end
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.RichText = true
        textLabel.TextStrokeTransparency = 0.1
        textLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0)
        textLabel.TextColor3 = textColor or Color3.fromRGB(255,255,255)
        textLabel.Text = text
        textLabel.Parent = lbl
    else
        local textLabel = lbl:FindFirstChild("TextLabel")
        if textLabel then
            textLabel.RichText = true
            textLabel.Text = text
            if isGenerator then
                textLabel.TextSize = 14
                lbl.StudsOffset = Vector3.new(0,2.5,0)
            else
                textLabel.TextSize = 12
                lbl.StudsOffset = Vector3.new(0,3,0)
            end
            textLabel.TextStrokeTransparency = 0.1
            textLabel.TextColor3 = textColor or Color3.fromRGB(255,255,255)
        end
    end
end

function Visual.ClearLabel(model)
    if model and model:FindFirstChild("VD_Label") then
        pcall(function() model.VD_Label:Destroy() end)
    end
end

function Visual.EnsureGeneratorESP(generator, progress)
    if not generator then return end
    
    local function getGeneratorColor(percent)
        if percent >= 0.999 then
            return Color3.fromRGB(100, 255, 100)
        elseif percent >= 0.5 then
            local factor = (percent - 0.5) * 2
            return Color3.fromRGB(255, 200 + 55 * factor, 100 - 100 * factor)
        else
            local factor = percent * 2
            return Color3.fromRGB(255 - 155 * factor, 100 - 100 * factor, 100 - 100 * factor)
        end
    end
    
    local color = getGeneratorColor(progress)
    local percentText = Visual.ESP.showGeneratorPercent and string.format("%d%%", math.floor(progress * 100)) or ""
    
    local hl = generator:FindFirstChild("VD_HL")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "VD_HL"
        hl.Adornee = generator
        hl.FillColor = color
        hl.FillTransparency = 0.7
        hl.OutlineColor = Color3.fromRGB(0,0,0)
        hl.OutlineTransparency = 0.1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = generator
    else
        hl.FillColor = color
        hl.OutlineColor = Color3.fromRGB(0,0,0)
        hl.FillTransparency = 0.7
        hl.OutlineTransparency = 0.1
    end
    
    if Visual.ESP.showGeneratorPercent then
        Visual.EnsureLabel(generator, percentText, true, color)
    else
        Visual.ClearLabel(generator)
    end
end

function Visual.GetRole(targetPlayer)
    if targetPlayer.Team and targetPlayer.Team.Name then
        local n = targetPlayer.Team.Name:lower()
        if n:find("killer") then return "Killer" end
        if n:find("survivor") then return "Survivor" end
    end
    return "Survivor"
end

function Visual.GetTeamColor(targetPlayer)
    if not Visual.ESP.boxESP.teamCheck then
        return Visual.ESP.boxESP.color
    end
    
    local myRole = Visual.GetRole(Nexus.Player)
    local targetRole = Visual.GetRole(targetPlayer)
    
    if myRole == targetRole then
        return Color3.fromRGB(0, 0, 255)
    else
        return Color3.fromRGB(255, 0, 0)
    end
end

function Visual.AddObjectToTrack(obj)
    local nameLower = obj.Name:lower()
    
    if nameLower:find("generator") then 
        Visual.ESP.trackedObjects[obj] = "Generators"
    elseif nameLower:find("pallet") then
        if Visual.IsValidPallet(obj) then
            Visual.ESP.trackedObjects[obj] = "Pallets"
        end
    elseif nameLower:find("gate") then 
        Visual.ESP.trackedObjects[obj] = "ExitGates"
    elseif nameLower:find("window") then 
        Visual.ESP.trackedObjects[obj] = "Windows"
    elseif nameLower:find("hook") then 
        Visual.ESP.trackedObjects[obj] = "Hooks"
    end
end

function Visual.IsValidPallet(obj)
    if obj.Name:lower():find("palletpoint") then
        return true
    end
    
    for _, child in ipairs(obj:GetChildren()) do
        if child.Name:lower():find("palletpoint") then
            return true
        end
    end
    
    if obj:IsA("Model") and obj.PrimaryPart then
        local primaryName = obj.PrimaryPart.Name:lower()
        if primaryName:find("palletpoint") or primaryName:find("pallet") then
            return true
        end
    end
    
    return false
end

function Visual.CreateBoxESP(character)
    if not character then return nil end
    
    local box = character:FindFirstChild("VD_Box")
    if not box then
        box = Instance.new("BoxHandleAdornment")
        box.Name = "VD_Box"
        box.Adornee = character
        box.AlwaysOnTop = true
        box.ZIndex = 10
        box.Size = Vector3.new(4, 6, 4)
        box.Color3 = Visual.GetTeamColor(Nexus.Services.Players:GetPlayerFromCharacter(character))
        box.Transparency = 0.3
        box.Parent = character
    end
    
    Visual.ESP.boxObjects[character] = box
    return box
end

function Visual.UpdateBoxESP(character)
    if not character then return end
    
    local box = Visual.ESP.boxObjects[character]
    if not box then
        box = Visual.CreateBoxESP(character)
    end
    
    if box then
        local player = Nexus.Services.Players:GetPlayerFromCharacter(character)
        if player then
            box.Color3 = Visual.GetTeamColor(player)
            box.Visible = Visual.ESP.boxESP.enabled
        end
    end
end

function Visual.RemoveBoxESP(character)
    if character and Visual.ESP.boxObjects[character] then
        local box = Visual.ESP.boxObjects[character]
        pcall(function() box:Destroy() end)
        Visual.ESP.boxObjects[character] = nil
    end
end

function Visual.CreateNameESP(character)
    if not character then return nil end
    
    local label = character:FindFirstChild("VD_NameLabel")
    if not label then
        label = Instance.new("BillboardGui")
        label.Name = "VD_NameLabel"
        label.Size = UDim2.new(0, 200, 0, 50)
        label.StudsOffset = Vector3.new(0, 7, 0)
        label.AlwaysOnTop = true
        label.MaxDistance = 1000
        label.Parent = character
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "NameText"
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextSize = 14
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.TextColor3 = Visual.ESP.namesESP.color
        textLabel.TextStrokeTransparency = 0
        textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        textLabel.Parent = label
        
        Visual.ESP.nameLabels[character] = label
    end
    
    return label
end

function Visual.UpdateNameESP(character)
    if not character then return end
    
    local label = Visual.ESP.nameLabels[character]
    if not label then
        label = Visual.CreateNameESP(character)
    end
    
    if label then
        local player = Nexus.Services.Players:GetPlayerFromCharacter(character)
        if player then
            local textLabel = label:FindFirstChild("NameText")
            if textLabel then
                textLabel.Text = player.Name
                textLabel.TextColor3 = Visual.ESP.namesESP.color
                label.Enabled = Visual.ESP.namesESP.enabled
            end
        end
    end
end

function Visual.RemoveNameESP(character)
    if character and Visual.ESP.nameLabels[character] then
        local label = Visual.ESP.nameLabels[character]
        pcall(function() label:Destroy() end)
        Visual.ESP.nameLabels[character] = nil
    end
end

function Visual.TrackObjects()
    Visual.ESP.trackedObjects = {}
    
    for _, obj in ipairs(Nexus.Services.Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            Visual.AddObjectToTrack(obj)
        end
    end
    
    Visual.ESP.espConnections.descendantAdded = Nexus.Services.Workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("Model") then
            Visual.AddObjectToTrack(obj)
        end
    end)
end

function Visual.UpdateESP()
    local currentTime = tick()
    if currentTime - Visual.ESP.lastUpdate < Visual.ESP.UPDATE_INTERVAL then return end
    Visual.ESP.lastUpdate = currentTime
    
    for _, targetPlayer in ipairs(Nexus.Services.Players:GetPlayers()) do
        if targetPlayer ~= Nexus.Player and targetPlayer.Character then
            local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local role = Visual.GetRole(targetPlayer)
                local setting = (role == "Killer") and Visual.ESP.settings.Killers or Visual.ESP.settings.Survivors
                
                if setting and setting.Enabled then
                    local color = setting.Colorpicker and setting.Colorpicker.Value or setting.Color
                    Visual.EnsureHighlight(targetPlayer.Character, color, false)
                else
                    Visual.ClearHighlight(targetPlayer.Character)
                    Visual.ClearLabel(targetPlayer.Character)
                end
                
                if Visual.ESP.boxESP.enabled then
                    Visual.UpdateBoxESP(targetPlayer.Character)
                else
                    Visual.RemoveBoxESP(targetPlayer.Character)
                end
                
                if Visual.ESP.namesESP.enabled then
                    Visual.UpdateNameESP(targetPlayer.Character)
                else
                    Visual.RemoveNameESP(targetPlayer.Character)
                end
            else
                Visual.RemoveBoxESP(targetPlayer.Character)
                Visual.RemoveNameESP(targetPlayer.Character)
            end
        end
    end
    
    for obj, typeName in pairs(Visual.ESP.trackedObjects) do
        if obj and obj.Parent then
            local setting = Visual.ESP.settings[typeName]
            if setting and setting.Enabled then
                if typeName == "Generators" then
                    local progress = Visual.GetGeneratorProgress(obj)
                    Visual.EnsureGeneratorESP(obj, progress)
                else
                    local color = setting.Colorpicker and setting.Colorpicker.Value or setting.Color
                    Visual.EnsureHighlight(obj, color, true)
                    Visual.ClearLabel(obj)
                end
            else
                Visual.ClearHighlight(obj)
                Visual.ClearLabel(obj)
            end
        end
    end
end

function Visual.StartESPLoop()
    Visual.ESP.espConnections.mainLoop = task.spawn(function()
        while Visual.ESP.espLoopRunning do
            Visual.UpdateESP()
            task.wait(Visual.ESP.UPDATE_INTERVAL)
        end
    end)
end

function Visual.StartESP()
    if Visual.ESP.espLoopRunning then return end
    Visual.ESP.espLoopRunning = true
    
    Visual.TrackObjects()
    Visual.StartESPLoop()
end

function Visual.StopESP()
    Visual.ESP.espLoopRunning = false
    
    Visual.ClearAllESP()
    
    for _, connection in pairs(Visual.ESP.espConnections) do
        Nexus.safeDisconnect(connection)
    end
    Visual.ESP.espConnections = {}
end

function Visual.ClearAllESP()
    for _, targetPlayer in ipairs(Nexus.Services.Players:GetPlayers()) do
        if targetPlayer.Character then
            Visual.ClearHighlight(targetPlayer.Character)
            Visual.ClearLabel(targetPlayer.Character)
            Visual.RemoveBoxESP(targetPlayer.Character)
            Visual.RemoveNameESP(targetPlayer.Character)
        end
    end
    
    for character, box in pairs(Visual.ESP.boxObjects) do
        if box then
            pcall(function() box:Destroy() end)
        end
    end
    Visual.ESP.boxObjects = {}
    
    for character, label in pairs(Visual.ESP.nameLabels) do
        if label then
            pcall(function() label:Destroy() end)
        end
    end
    Visual.ESP.nameLabels = {}
    
    for obj, _ in pairs(Visual.ESP.trackedObjects) do
        if obj and obj.Parent then
            Visual.ClearHighlight(obj)
            Visual.ClearLabel(obj)
        end
    end
end

function Visual.ToggleESPSetting(settingName, enabled)
    if Visual.ESP.settings[settingName] then
        Visual.ESP.settings[settingName].Enabled = enabled
        
        local anyEnabled = false
        for _, setting in pairs(Visual.ESP.settings) do
            if setting.Enabled then
                anyEnabled = true
                break
            end
        end
        
        if (anyEnabled or Visual.ESP.boxESP.enabled or Visual.ESP.namesESP.enabled) and not Visual.ESP.espLoopRunning then
            Visual.StartESP()
        elseif not anyEnabled and not Visual.ESP.boxESP.enabled and not Visual.ESP.namesESP.enabled and Visual.ESP.espLoopRunning then
            Visual.StopESP()
        end
    end
end

function Visual.ToggleBoxESP(enabled)
    Visual.ESP.boxESP.enabled = enabled
    
    local anyEnabled = false
    for _, setting in pairs(Visual.ESP.settings) do
        if setting.Enabled then
            anyEnabled = true
            break
        end
    end
    
    if (anyEnabled or Visual.ESP.boxESP.enabled or Visual.ESP.namesESP.enabled) and not Visual.ESP.espLoopRunning then
        Visual.StartESP()
    elseif not anyEnabled and not Visual.ESP.boxESP.enabled and not Visual.ESP.namesESP.enabled and Visual.ESP.espLoopRunning then
        Visual.StopESP()
    else
        Visual.UpdateESP()
    end
end

function Visual.ToggleNamesESP(enabled)
    Visual.ESP.namesESP.enabled = enabled
    
    local anyEnabled = false
    for _, setting in pairs(Visual.ESP.settings) do
        if setting.Enabled then
            anyEnabled = true
            break
        end
    end
    
    if (anyEnabled or Visual.ESP.boxESP.enabled or Visual.ESP.namesESP.enabled) and not Visual.ESP.espLoopRunning then
        Visual.StartESP()
    elseif not anyEnabled and not Visual.ESP.boxESP.enabled and not Visual.ESP.namesESP.enabled and Visual.ESP.espLoopRunning then
        Visual.StopESP()
    else
        Visual.UpdateESP()
    end
end

function Visual.ToggleTeamCheck(enabled)
    Visual.ESP.boxESP.teamCheck = enabled
    Visual.UpdateESP()
end

function Visual.UpdateESPColors()
    if Visual.ESP.espLoopRunning then
        Visual.UpdateESP()
    end
end

function Visual.UpdateESPDisplay()
    if Visual.ESP.espLoopRunning then
        Visual.UpdateESP()
    end
end

function Visual.ToggleNoShadow(enabled)
    Visual.Effects.noShadowEnabled = enabled
    if enabled then
        for _, light in ipairs(Nexus.Services.Lighting:GetDescendants()) do 
            if light:IsA("Light") then 
                light.Shadows = false 
            end 
        end
        Nexus.Services.Lighting.GlobalShadows = false
    else
        for _, light in ipairs(Nexus.Services.Lighting:GetDescendants()) do 
            if light:IsA("Light") then 
                light.Shadows = true 
            end 
        end
        Nexus.Services.Lighting.GlobalShadows = true
    end
end

function Visual.SaveOriginalFogSettings()
    local lighting = Nexus.Services.Lighting
    
    Visual.Effects.originalFogEnd = lighting.FogEnd
    Visual.Effects.originalFogStart = lighting.FogStart
    Visual.Effects.originalFogColor = lighting.FogColor
    Visual.Effects.originalAtmosphere = {}
    Visual.Effects.originalPostEffects = {}
    
    for _, effect in ipairs(lighting:GetChildren()) do
        if effect:IsA("Atmosphere") then
            table.insert(Visual.Effects.originalAtmosphere, effect:Clone())
        elseif effect:IsA("BloomEffect") or effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") then
            table.insert(Visual.Effects.originalPostEffects, effect:Clone())
        end
    end
end

function Visual.RestoreOriginalFogSettings()
    local lighting = Nexus.Services.Lighting
    
    if Visual.Effects.originalFogEnd then
        lighting.FogEnd = Visual.Effects.originalFogEnd
    end
    
    if Visual.Effects.originalFogStart then
        lighting.FogStart = Visual.Effects.originalFogStart
    end
    
    if Visual.Effects.originalFogColor then
        lighting.FogColor = Visual.Effects.originalFogColor
    end
    
    for _, effect in ipairs(Visual.Effects.originalAtmosphere) do
        local newEffect = effect:Clone()
        newEffect.Parent = lighting
    end
    
    for _, effect in ipairs(Visual.Effects.originalPostEffects) do
        local newEffect = effect:Clone()
        newEffect.Parent = lighting
    end
end

function Visual.ToggleNoFog(enabled)
    Visual.Effects.noFogEnabled = enabled
    
    if enabled then
        if not Visual.Effects.originalFogEnd then
            Visual.SaveOriginalFogSettings()
        end
        
        pcall(function()
            local lighting = Nexus.Services.Lighting
            
            for _, effect in ipairs(lighting:GetChildren()) do
                if effect:IsA("Atmosphere") or 
                   effect.Name:lower():find("fog") or 
                   effect.Name:lower():find("bloom") or
                   effect.Name:lower():find("blur") or
                   effect.Name:lower():find("color") then
                    effect:Destroy()
                end
            end
            
            local map = Nexus.Services.Workspace:FindFirstChild("Map")
            if map then
                for _, obj in ipairs(map:GetDescendants()) do
                    if obj:IsA("Atmosphere") or 
                       obj:IsA("BloomEffect") or 
                       obj:IsA("BlurEffect") or 
                       obj:IsA("ColorCorrectionEffect") or
                       obj.Name:lower():find("fog") then
                        obj:Destroy()
                    end
                end
            end
            
            lighting.FogEnd = 10000000
            lighting.FogStart = 0
            lighting.FogDensity = 0
            lighting.GlobalShadows = true
            
            if Visual.ESP.espConnections.noFog then
                Visual.ESP.espConnections.noFog:Disconnect()
            end
            
            Visual.ESP.espConnections.noFog = Nexus.Services.RunService.Heartbeat:Connect(function()
                if Visual.Effects.noFogEnabled then
                    lighting.FogEnd = 10000000
                    lighting.FogStart = 0
                    lighting.FogDensity = 0
                end
            end)
        end)
    else
        if Visual.ESP.espConnections.noFog then
            Visual.ESP.espConnections.noFog:Disconnect()
            Visual.ESP.espConnections.noFog = nil
        end
        
        Visual.RestoreOriginalFogSettings()
    end
end

function Visual.ToggleFullBright(enabled)
    Visual.Effects.fullbrightEnabled = enabled
    Nexus.States.fullbrightEnabled = enabled
    
    if enabled then
        Nexus.Services.Lighting.GlobalShadows = false
        Nexus.Services.Lighting.FogEnd = 100000
        Nexus.Services.Lighting.Brightness = 2
        Nexus.Services.Lighting.ClockTime = 14
    else
        Nexus.Services.Lighting.GlobalShadows = true
        Nexus.Services.Lighting.FogEnd = 1000
        Nexus.Services.Lighting.Brightness = 1
    end
end

function Visual.ToggleTimeChanger(enabled)
    Visual.Effects.timeChangerEnabled = enabled
    
    if enabled then
        if not Visual.Effects.originalClockTime then
            Visual.Effects.originalClockTime = Nexus.Services.Lighting.ClockTime
        end
        
        local currentTime = Nexus.Options.TimeValue.Value
        Nexus.Services.Lighting.ClockTime = currentTime
    else
        if Visual.Effects.originalClockTime then
            Nexus.Services.Lighting.ClockTime = Visual.Effects.originalClockTime
        end
    end
end

function Visual.SetTime(time)
    Nexus.Services.Lighting.ClockTime = time
end

function Visual.Init(nxs)
    Nexus = nxs
    
    local Tabs = Nexus.Tabs
    local Options = Nexus.Options
    
    local NoShadowToggle = Tabs.Visual:AddToggle("NoShadow", {
        Title = "No Shadow", 
        Description = "", 
        Default = false
    })
    NoShadowToggle:OnChanged(function(v) Visual.ToggleNoShadow(v) end)

    local NoFogToggle = Tabs.Visual:AddToggle("NoFog", {
        Title = "No Fog", 
        Description = "", 
        Default = false
    })
    
    NoFogToggle:OnChanged(function(v) 
        Nexus.SafeCallback(function()
            Visual.ToggleNoFog(v)
        end)
    end)

    local FullBrightToggle = Tabs.Visual:AddToggle("FullBright", {
        Title = "FullBright", 
        Description = "", 
        Default = false
    })
    FullBrightToggle:OnChanged(function(v) Visual.ToggleFullBright(v) end)

    local TimeChangerToggle = Tabs.Visual:AddToggle("TimeChanger", {
        Title = "Time Changer", 
        Description = "", 
        Default = false
    })

    local TimeSlider = Tabs.Visual:AddSlider("TimeValue", {
        Title = "Time of Day", 
        Description = "",
        Default = 14,
        Min = 0,
        Max = 24,
        Rounding = 1,
        Callback = function(value)
            if Options.TimeChanger and Options.TimeChanger.Value then
                Visual.SetTime(value)
            end
        end
    })

    TimeChangerToggle:OnChanged(function(v)
        Visual.ToggleTimeChanger(v)
    end)

    task.spawn(function()
        while true do
            task.wait(1)
            if Options.TimeChanger and Options.TimeChanger.Value then
                local currentTime = Options.TimeValue.Value
                Visual.SetTime(currentTime)
            end
        end
    end)

    Tabs.Visual:AddSection("ESP Settings")

    local ShowGeneratorPercentToggle = Tabs.Visual:AddToggle("ESPShowGenPercent", {
        Title = "Show Generator %", 
        Description = "Toggle display of generator percentages", 
        Default = true
    })
    ShowGeneratorPercentToggle:OnChanged(function(v)
        Visual.ESP.showGeneratorPercent = v
        Visual.UpdateESPDisplay()
    end)

    local ESPSurvivorsToggle = Tabs.Visual:AddToggle("ESPSurvivors", {
        Title = "Survivors ESP", 
        Description = "", 
        Default = false
    })
    ESPSurvivorsToggle:OnChanged(function(v)
        Visual.ToggleESPSetting("Survivors", v)
    end)

    local SurvivorColorpicker = Tabs.Visual:AddColorpicker("SurvivorColorpicker", {
        Title = "Survivor Color",
        Default = Color3.fromRGB(100, 255, 100)
    })
    SurvivorColorpicker:OnChanged(function()
        Visual.ESP.settings.Survivors.Color = SurvivorColorpicker.Value
        Visual.UpdateESPColors()
    end)
    SurvivorColorpicker:SetValueRGB(Color3.fromRGB(100, 255, 100))

    local ESPKillersToggle = Tabs.Visual:AddToggle("ESPKillers", {
        Title = "Killers ESP", 
        Description = "", 
        Default = false
    })
    ESPKillersToggle:OnChanged(function(v)
        Visual.ToggleESPSetting("Killers", v)
    end)

    local KillerColorpicker = Tabs.Visual:AddColorpicker("KillerColorpicker", {
        Title = "Killer Color",
        Default = Color3.fromRGB(255, 100, 100)
    })
    KillerColorpicker:OnChanged(function()
        Visual.ESP.settings.Killers.Color = KillerColorpicker.Value
        Visual.UpdateESPColors()
    end)
    KillerColorpicker:SetValueRGB(Color3.fromRGB(255, 100, 100))

    local ESPHooksToggle = Tabs.Visual:AddToggle("ESPHooks", {
        Title = "Hooks ESP", 
        Description = "", 
        Default = false
    })
    ESPHooksToggle:OnChanged(function(v)
        Visual.ToggleESPSetting("Hooks", v)
    end)

    local HookColorpicker = Tabs.Visual:AddColorpicker("HookColorpicker", {
        Title = "Hook Color",
        Default = Color3.fromRGB(100, 50, 150)
    })
    HookColorpicker:OnChanged(function()
        Visual.ESP.settings.Hooks.Color = HookColorpicker.Value
        Visual.UpdateESPColors()
    end)
    HookColorpicker:SetValueRGB(Color3.fromRGB(100, 50, 150))

    local ESPGeneratorsToggle = Tabs.Visual:AddToggle("ESPGenerators", {
        Title = "Generators ESP", 
        Description = "", 
        Default = false
    })
    ESPGeneratorsToggle:OnChanged(function(v)
        Visual.ToggleESPSetting("Generators", v)
    end)

    local ESPPalletsToggle = Tabs.Visual:AddToggle("ESPPallets", {
        Title = "Pallets ESP", 
        Description = "", 
        Default = false
    })
    ESPPalletsToggle:OnChanged(function(v)
        Visual.ToggleESPSetting("Pallets", v)
    end)

    local PalletColorpicker = Tabs.Visual:AddColorpicker("PalletColorpicker", {
        Title = "Pallet Color",
        Default = Color3.fromRGB(120, 80, 40)
    })
    PalletColorpicker:OnChanged(function()
        Visual.ESP.settings.Pallets.Color = PalletColorpicker.Value
        Visual.UpdateESPColors()
    end)
    PalletColorpicker:SetValueRGB(Color3.fromRGB(120, 80, 40))

    local ESPGatesToggle = Tabs.Visual:AddToggle("ESPGates", {
        Title = "Exit Gates ESP", 
        Description = "", 
        Default = false
    })
    ESPGatesToggle:OnChanged(function(v)
        Visual.ToggleESPSetting("ExitGates", v)
    end)

    local GateColorpicker = Tabs.Visual:AddColorpicker("GateColorpicker", {
        Title = "Gate Color",
        Default = Color3.fromRGB(200, 200, 100)
    })
    GateColorpicker:OnChanged(function()
        Visual.ESP.settings.ExitGates.Color = GateColorpicker.Value
        Visual.UpdateESPColors()
    end)
    GateColorpicker:SetValueRGB(Color3.fromRGB(200, 200, 100))

    local ESPWindowsToggle = Tabs.Visual:AddToggle("ESPWindows", {
        Title = "Windows ESP", 
        Description = "", 
        Default = false
    })
    ESPWindowsToggle:OnChanged(function(v)
        Visual.ToggleESPSetting("Windows", v)
    end)

    local WindowColorpicker = Tabs.Visual:AddColorpicker("WindowColorpicker", {
        Title = "Window Color",
        Default = Color3.fromRGB(100, 200, 200)
    })
    WindowColorpicker:OnChanged(function()
        Visual.ESP.settings.Windows.Color = WindowColorpicker.Value
        Visual.UpdateESPColors()
    end)
    WindowColorpicker:SetValueRGB(Color3.fromRGB(100, 200, 200))

    Visual.ESP.settings.Survivors.Colorpicker = SurvivorColorpicker
    Visual.ESP.settings.Killers.Colorpicker = KillerColorpicker
    Visual.ESP.settings.Hooks.Colorpicker = HookColorpicker
    Visual.ESP.settings.Pallets.Colorpicker = PalletColorpicker
    Visual.ESP.settings.ExitGates.Colorpicker = GateColorpicker
    Visual.ESP.settings.Windows.Colorpicker = WindowColorpicker

    Tabs.Visual:AddSection("Player ESP")

    local BoxESPToggle = Tabs.Visual:AddToggle("BoxESP", {
        Title = "Box ESP", 
        Description = "Show/hide player boxes", 
        Default = false
    })
    BoxESPToggle:OnChanged(function(v) Visual.ToggleBoxESP(v) end)

    local BoxColorpicker = Tabs.Visual:AddColorpicker("BoxColorpicker", {
        Title = "Box Color",
        Default = Color3.fromRGB(255, 255, 255)
    })
    BoxColorpicker:OnChanged(function()
        Visual.ESP.boxESP.color = BoxColorpicker.Value
        Visual.UpdateESP()
    end)
    BoxColorpicker:SetValueRGB(Color3.fromRGB(255, 255, 255))
    Visual.ESP.boxESP.colorpicker = BoxColorpicker

    local NamesESPToggle = Tabs.Visual:AddToggle("NamesESP", {
        Title = "Names ESP", 
        Description = "Show/hide player names", 
        Default = false
    })
    NamesESPToggle:OnChanged(function(v) Visual.ToggleNamesESP(v) end)

    local NamesColorpicker = Tabs.Visual:AddColorpicker("NamesColorpicker", {
        Title = "Names Color",
        Default = Color3.fromRGB(255, 255, 255)
    })
    NamesColorpicker:OnChanged(function()
        Visual.ESP.namesESP.color = NamesColorpicker.Value
        Visual.UpdateESP()
    end)
    NamesColorpicker:SetValueRGB(Color3.fromRGB(255, 255, 255))
    Visual.ESP.namesESP.colorpicker = NamesColorpicker

    local TeamCheckToggle = Tabs.Visual:AddToggle("TeamCheck", {
        Title = "Team Check", 
        Description = "Red for enemies, blue for teammates", 
        Default = false
    })
    TeamCheckToggle:OnChanged(function(v) Visual.ToggleTeamCheck(v) end)

    task.spawn(function()
        task.wait(2)
        for _, obj in ipairs(Nexus.Services.Workspace:GetDescendants()) do
            if obj:IsA("Model") then
                Visual.AddObjectToTrack(obj)
            end
        end
        
        Nexus.Services.Workspace.DescendantAdded:Connect(function(obj)
            if obj:IsA("Model") then
                Visual.AddObjectToTrack(obj)
            end
        end)
    end)
end

function Visual.Cleanup()
    Visual.StopESP()
    
    Visual.ToggleNoShadow(false)
    Visual.ToggleNoFog(false)
    Visual.ToggleFullBright(false)
    Visual.ToggleTimeChanger(false)
    
    for _, connection in pairs(Visual.Connections) do
        Nexus.safeDisconnect(connection)
    end
    Visual.Connections = {}
    
    for _, connection in pairs(Visual.ESP.espConnections) do
        Nexus.safeDisconnect(connection)
    end
    Visual.ESP.espConnections = {}
end

return Visual
