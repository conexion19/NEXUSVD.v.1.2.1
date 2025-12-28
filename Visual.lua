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
        trackedObjects = {},
        espConnections = {},
        espLoopRunning = false,
        showGeneratorPercent = true,
        maxRenderDistance = 700
    },
    AdvancedESP = {
        settings = {
            name = {Enabled = true, TextSize = 15},
            distance = {Enabled = true, TextSize = 13},
            healthbar = {Enabled = true},
            box = {Enabled = true},
            boxType = "full",
            bones = {Enabled = true},
            boneColorName = "White",
            tracers = {Enabled = true},
            tracerColorName = "White",
            scale = 1.5,
            healthBarTopColorName = "DarkGreen",
            healthBarMidColorName = "DarkOrange",
            healthBarBottomColorName = "DarkRed",
            stateColorName = "Orange",
            boxColorName = "White",
            boxFill = {Enabled = true},
            boxFillColorName = "White",
            boxFillTransparency = 0.9,
            healthBarLeftOffset = 10,
            maxRenderDistance = 700
        },
        colorMap = {
            Red = Color3.fromRGB(255,0,0),
            DarkRed = Color3.fromRGB(100,0,0),
            Green = Color3.fromRGB(0,255,0),
            DarkGreen = Color3.fromRGB(0,80,0),
            Blue = Color3.fromRGB(0,0,255),
            LightBlue = Color3.fromRGB(200,200,255),
            Yellow = Color3.fromRGB(255,255,0),
            Orange = Color3.fromRGB(255,165,0),
            DarkOrange = Color3.fromRGB(140,70,0),
            Purple = Color3.fromRGB(128,0,128),
            White = Color3.fromRGB(255,255,255),
            Black = Color3.fromRGB(0,0,0)
        },
        connections = {},
        espObjects = {},
        playerConnections = {},
        advancedESPRunning = false,
        cleanupQueue = {}, -- Добавлена очередь для очистки
        cleanupScheduled = false
    },
    Effects = {
        noShadowEnabled = false,
        noFogEnabled = false,
        fullbrightEnabled = false,
        timeChangerEnabled = false,
        originalFogEnd = nil,
        originalFogStart = nil,
        originalFogColor = nil,
        fogCache = {},
        originalClockTime = nil        
    }
}

-- Функция для безопасной очистки Drawing объектов
function Visual.SafeRemoveDrawing(drawingObj)
    if drawingObj and typeof(drawingObj) == "userdata" then
        pcall(function()
            if drawingObj.Visible ~= nil then
                drawingObj.Visible = false
            end
            task.wait()
            if drawingObj.Remove then
                drawingObj:Remove()
            elseif drawingObj.Destroy then
                drawingObj:Destroy()
            end
        end)
    end
end

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

function Visual.TrackObjects()
    Visual.ESP.trackedObjects = {}
    
    for _, obj in ipairs(Nexus.Services.Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            Visual.AddObjectToTrack(obj)
        end
    end
    
    if Visual.ESP.espConnections.descendantAdded then
        Visual.ESP.espConnections.descendantAdded:Disconnect()
    end
    
    Visual.ESP.espConnections.descendantAdded = Nexus.Services.Workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("Model") then
            Visual.AddObjectToTrack(obj)
        end
    end)
end

function Visual.UpdateESP()
    if not Visual.ESP.espLoopRunning then return end
    
    local currentTime = tick()
    if currentTime - Visual.ESP.lastUpdate < Visual.ESP.UPDATE_INTERVAL then return end
    Visual.ESP.lastUpdate = currentTime
    
    local Camera = Nexus.Camera
    local camPos = Camera.CFrame.Position
    local maxDistance = Visual.ESP.maxRenderDistance
    
    -- Обновляем ESP для игроков
    for _, targetPlayer in ipairs(Nexus.Services.Players:GetPlayers()) do
        if targetPlayer ~= Nexus.Player and targetPlayer.Character then
            local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local distance = (hrp.Position - camPos).Magnitude
                if distance <= maxDistance then
                    local role = Visual.GetRole(targetPlayer)
                    local setting = (role == "Killer") and Visual.ESP.settings.Killers or Visual.ESP.settings.Survivors
                    
                    if setting and setting.Enabled then
                        local color = setting.Colorpicker and setting.Colorpicker.Value or setting.Color
                        Visual.EnsureHighlight(targetPlayer.Character, color, false)
                    else
                        Visual.ClearHighlight(targetPlayer.Character)
                        Visual.ClearLabel(targetPlayer.Character)
                    end
                else
                    Visual.ClearHighlight(targetPlayer.Character)
                    Visual.ClearLabel(targetPlayer.Character)
                end
            else
                Visual.ClearHighlight(targetPlayer.Character)
                Visual.ClearLabel(targetPlayer.Character)
            end
        end
    end
    
    -- Обновляем ESP для объектов
    local objectsToRemove = {}
    for obj, typeName in pairs(Visual.ESP.trackedObjects) do
        if obj and obj.Parent then
            local objPosition = obj:GetPivot().Position
            local distance = (objPosition - camPos).Magnitude
            if distance <= maxDistance then
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
            else
                Visual.ClearHighlight(obj)
                Visual.ClearLabel(obj)
            end
        else
            objectsToRemove[obj] = true
        end
    end
    
    -- Удаляем несуществующие объекты
    for obj in pairs(objectsToRemove) do
        Visual.ESP.trackedObjects[obj] = nil
    end
end

function Visual.StartESPLoop()
    if Visual.ESP.espConnections.mainLoop then
        Visual.ESP.espConnections.mainLoop:Disconnect()
    end
    
    Visual.ESP.espConnections.mainLoop = Nexus.Services.RunService.Heartbeat:Connect(function()
        if Visual.ESP.espLoopRunning then
            Visual.UpdateESP()
        end
    end)
end

function Visual.StartESP()
    if Visual.ESP.espLoopRunning then return end
    
    -- Проверяем, есть ли активные настройки
    local anyEnabled = false
    for _, setting in pairs(Visual.ESP.settings) do
        if setting.Enabled then
            anyEnabled = true
            break
        end
    end
    
    if not anyEnabled then return end
    
    Visual.ESP.espLoopRunning = true
    
    Visual.TrackObjects()
    Visual.StartESPLoop()
end

function Visual.StopESP()
    if not Visual.ESP.espLoopRunning then return end
    
    Visual.ESP.espLoopRunning = false
    
    if Visual.ESP.espConnections.mainLoop then
        Visual.ESP.espConnections.mainLoop:Disconnect()
        Visual.ESP.espConnections.mainLoop = nil
    end
    
    Visual.ClearAllESP()
    
    for name, connection in pairs(Visual.ESP.espConnections) do
        if connection and typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    Visual.ESP.espConnections = {}
end

function Visual.ClearAllESP()
    for _, targetPlayer in ipairs(Nexus.Services.Players:GetPlayers()) do
        if targetPlayer.Character then
            Visual.ClearHighlight(targetPlayer.Character)
            Visual.ClearLabel(targetPlayer.Character)
        end
    end
    
    for obj, _ in pairs(Visual.ESP.trackedObjects) do
        if obj and obj.Parent then
            Visual.ClearHighlight(obj)
            Visual.ClearLabel(obj)
        end
    end
end

function Visual.ToggleESPSetting(settingName, enabled)
    if not Visual.ESP.settings[settingName] then return end
    
    Visual.ESP.settings[settingName].Enabled = enabled
    
    -- Проверяем, нужно ли запускать или останавливать ESP
    local anyEnabled = false
    for _, setting in pairs(Visual.ESP.settings) do
        if setting.Enabled then
            anyEnabled = true
            break
        end
    end
    
    if anyEnabled and not Visual.ESP.espLoopRunning then
        Visual.StartESP()
    elseif not anyEnabled and Visual.ESP.espLoopRunning then
        Visual.StopESP()
    else
        -- Принудительное обновление для немедленного применения изменений
        Visual.UpdateESP()
    end
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

function Visual.ClearAdvancedESP(plr)
    local d = Visual.AdvancedESP.espObjects[plr]
    if not d then return end
    
    -- Добавляем объекты в очередь для очистки
    table.insert(Visual.AdvancedESP.cleanupQueue, d)
    
    -- Запускаем очистку, если она еще не запланирована
    if not Visual.AdvancedESP.cleanupScheduled then
        Visual.AdvancedESP.cleanupScheduled = true
        task.spawn(function()
            task.wait(0.1) -- Даем время для завершения текущего кадра
            for _, drawingData in ipairs(Visual.AdvancedESP.cleanupQueue) do
                if drawingData then
                    local drawingObjects = {
                        drawingData.BoxFill, drawingData.Name, drawingData.Distance, 
                        drawingData.Tracer, drawingData.HealthBg, drawingData.HealthBar, 
                        drawingData.HealthMask, drawingData.HealthText, drawingData.Box
                    }
                    
                    for _, obj in ipairs(drawingObjects) do
                        Visual.SafeRemoveDrawing(obj)
                    end
                    
                    for i = 1, 24 do
                        Visual.SafeRemoveDrawing(drawingData["HealthStripe"..i])
                    end
                    
                    if drawingData.Bones then
                        for _, bone in ipairs(drawingData.Bones) do
                            Visual.SafeRemoveDrawing(bone)
                        end
                    end
                end
            end
            Visual.AdvancedESP.cleanupQueue = {}
            Visual.AdvancedESP.cleanupScheduled = false
        end)
    end
    
    Visual.AdvancedESP.espObjects[plr] = nil
    
    if Visual.AdvancedESP.playerConnections[plr] then
        for connName, connection in pairs(Visual.AdvancedESP.playerConnections[plr]) do
            if connection and typeof(connection) == "RBXScriptConnection" then
                connection:Disconnect()
            end
        end
        Visual.AdvancedESP.playerConnections[plr] = nil
    end
end

function Visual.ForceCleanupDrawings()
    -- Очищаем все ESP объекты
    for plr, d in pairs(Visual.AdvancedESP.espObjects) do
        Visual.ClearAdvancedESP(plr)
    end
    
    Visual.AdvancedESP.espObjects = {}
    
    -- Даем время для завершения очистки
    task.wait(0.1)
end

function Visual.CreateAdvancedESP(plr)
    -- Сначала очищаем старые объекты, если они есть
    if Visual.AdvancedESP.espObjects[plr] then
        Visual.ClearAdvancedESP(plr)
        task.wait(0.05) -- Небольшая задержка для очистки
    end
    
    local settings = Visual.AdvancedESP.settings
    local colorMap = Visual.AdvancedESP.colorMap
    
    local boneColor = colorMap[settings.boneColorName] or colorMap.White
    local tracerColor = colorMap[settings.tracerColorName] or colorMap.White
    local boxColor = colorMap[settings.boxColorName] or colorMap.White
    local boxFillColor = colorMap[settings.boxFillColorName] or colorMap.White
    
    local function create(tp, props)
        local o = Drawing.new(tp)
        for i,v in pairs(props) do o[i]=v end
        return o
    end
    
    local d = {
        Bones = {},
        BoxFill = nil,
        Name = nil,
        Distance = nil,
        Tracer = nil,
        HealthBg = nil,
        HealthBar = nil,
        HealthMask = nil,
        HealthText = nil,
        Box = nil
    }
    
    -- Создаем все Drawing объекты
    d.BoxFill = create("Square",{
        Thickness = 0,
        Color = boxFillColor,
        Visible = false,
        Filled = true,
        Transparency = 1 - (settings.boxFillTransparency or 0.9)
    })
    
    d.Name = create("Text",{
        Size = settings.name.TextSize,
        Center = true,
        Outline = true,
        Color = Color3.new(1,1,1),
        Visible = false
    })
    
    d.Distance = create("Text",{
        Size = settings.distance.TextSize,
        Center = true,
        Outline = true,
        Color = Color3.new(0.8,0.8,0.8),
        Visible = false
    })
    
    d.Tracer = create("Line",{
        Thickness = 1.5,
        Color = tracerColor,
        Visible = false
    })
    
    d.HealthBg = create("Square", {
        Visible = false,
        Filled = true,
        Color = Color3.new(0,0,0),
        Transparency = 1
    })
    
    d.HealthBar = create("Square", {
        Visible = false,
        Filled = true,
        Transparency = 1
    })
    
    d.HealthMask = create("Square", {
        Visible = false,
        Filled = true,
        Color = Color3.new(0,0,0),
        Transparency = 0.3
    })
    
    d.HealthText = create("Text",{
        Size = 14,
        Center = true,
        Outline = true,
        Color = Color3.new(1,1,1),
        Visible = false
    })
    
    d.Box = create("Square", {
        Thickness = 1.7,
        Color = boxColor,
        Visible = false,
        Filled = false
    })
    
    for i=1,14 do
        d.Bones[i] = create("Line", {
            Thickness = 1.5,
            Color = boneColor,
            Visible = false
        })
    end
    
    -- Создаем полоски здоровья
    for i=1,24 do
        d["HealthStripe"..i] = create("Square", {
            Filled = true,
            Visible = false,
            Transparency = 1
        })
    end
    
    Visual.AdvancedESP.espObjects[plr] = d
    
    if not Visual.AdvancedESP.playerConnections[plr] then
        Visual.AdvancedESP.playerConnections[plr] = {}
    end
    
    return d
end

function Visual.SetupPlayerAdvancedESP(plr)
    if plr == Nexus.Player then return end
    
    -- Если ESP не запущен, выходим
    if not Visual.AdvancedESP.advancedESPRunning then return end
    
    Visual.CreateAdvancedESP(plr)
    
    local charAddedConnection = plr.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        
        if not Visual.AdvancedESP.advancedESPRunning then 
            Visual.ClearAdvancedESP(plr)
            return 
        end
        
        if not Visual.AdvancedESP.espObjects[plr] then
            Visual.CreateAdvancedESP(plr)
        end
        
        local humanoid = char:WaitForChild("Humanoid", 5)
        if humanoid then
            if Visual.AdvancedESP.playerConnections[plr] then
                if Visual.AdvancedESP.playerConnections[plr].died then
                    Visual.AdvancedESP.playerConnections[plr].died:Disconnect()
                end
                
                Visual.AdvancedESP.playerConnections[plr].died = humanoid.Died:Connect(function()
                    Visual.ClearAdvancedESP(plr)
                end)
            end
        end
    end)
    
    local charRemovingConnection = plr.CharacterRemoving:Connect(function()
        Visual.ClearAdvancedESP(plr)
    end)
    
    if Visual.AdvancedESP.playerConnections[plr] then
        if Visual.AdvancedESP.playerConnections[plr].charAdded then
            Visual.AdvancedESP.playerConnections[plr].charAdded:Disconnect()
        end
        if Visual.AdvancedESP.playerConnections[plr].charRemoving then
            Visual.AdvancedESP.playerConnections[plr].charRemoving:Disconnect()
        end
        
        Visual.AdvancedESP.playerConnections[plr].charAdded = charAddedConnection
        Visual.AdvancedESP.playerConnections[plr].charRemoving = charRemovingConnection
    else
        Visual.AdvancedESP.playerConnections[plr] = {
            charAdded = charAddedConnection,
            charRemoving = charRemovingConnection
        }
    end
    
    if plr.Character then
        task.spawn(function()
            local char = plr.Character
            task.wait(0.5)
            
            if not Visual.AdvancedESP.advancedESPRunning then 
                Visual.ClearAdvancedESP(plr)
                return 
            end
            
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                if Visual.AdvancedESP.playerConnections[plr] then
                    if Visual.AdvancedESP.playerConnections[plr].died then
                        Visual.AdvancedESP.playerConnections[plr].died:Disconnect()
                    end
                    
                    Visual.AdvancedESP.playerConnections[plr].died = humanoid.Died:Connect(function()
                        Visual.ClearAdvancedESP(plr)
                    end)
                end
            end
        end)
    end
end

function Visual.CleanupPlayerAdvancedESP(plr)
    Visual.ClearAdvancedESP(plr)
end

function Visual.GetHealthGradientColor(y, h)
    local settings = Visual.AdvancedESP.settings
    local colorMap = Visual.AdvancedESP.colorMap
    
    local t = 1 - (y / math.max(h, 1))
    if t >= 0.5 then
        local s = (t - 0.5) * 2
        local midColor = colorMap[settings.healthBarMidColorName] or colorMap.DarkOrange
        local topColor = colorMap[settings.healthBarTopColorName] or colorMap.DarkGreen
        return midColor:Lerp(topColor, s)
    else
        local s = t * 2
        local bottomColor = colorMap[settings.healthBarBottomColorName] or colorMap.DarkRed
        local midColor = colorMap[settings.healthBarMidColorName] or colorMap.DarkOrange
        return bottomColor:Lerp(midColor, s)
    end
end

function Visual.IsR6(char)
    return char:FindFirstChild("Torso") and not char:FindFirstChild("UpperTorso")
end

function Visual.UpdateAdvancedESP()
    if not Visual.AdvancedESP.advancedESPRunning then 
        Visual.ForceCleanupDrawings()
        return 
    end
    
    -- Проверяем, есть ли активные компоненты
    local anyComponentEnabled = false
    for _, component in pairs(Visual.AdvancedESP.settings) do
        if type(component) == "table" and component.Enabled then
            anyComponentEnabled = true
            break
        end
    end
    
    if not anyComponentEnabled then 
        Visual.ForceCleanupDrawings()
        return 
    end
    
    local Camera = Nexus.Camera
    local camPos = Camera.CFrame.Position
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    local maxDistance = Visual.AdvancedESP.settings.maxRenderDistance
    
    -- Убираем неактивных игроков
    local activePlayers = {}
    for _, plr in pairs(Nexus.Services.Players:GetPlayers()) do
        if plr ~= Nexus.Player then
            activePlayers[plr] = true
        end
    end
    
    for plr, _ in pairs(Visual.AdvancedESP.espObjects) do
        if not activePlayers[plr] then
            Visual.ClearAdvancedESP(plr)
        end
    end
    
    -- Обновляем ESP для активных игроков
    for plr, d in pairs(Visual.AdvancedESP.espObjects) do
        if not plr or not plr.Parent then
            Visual.ClearAdvancedESP(plr)
        else
            local char = plr.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") and char:FindFirstChildOfClass("Humanoid") then
                local hum = char:FindFirstChildOfClass("Humanoid")
                
                if hum and hum.Health <= 0 then
                    -- Скрываем все, если игрок мертв
                    if d.BoxFill then d.BoxFill.Visible = false end
                    if d.Box then d.Box.Visible = false end
                    if d.Name then d.Name.Visible = false end
                    if d.Distance then d.Distance.Visible = false end
                    if d.HealthBg then d.HealthBg.Visible = false end
                    if d.HealthText then d.HealthText.Visible = false end
                    for i=1,24 do
                        if d["HealthStripe"..i] then d["HealthStripe"..i].Visible = false end
                    end
                    if d.Bones then 
                        for _,line in ipairs(d.Bones) do 
                            line.Visible = false 
                        end 
                    end
                    if d.Tracer then d.Tracer.Visible = false end
                else
                    local root = char.HumanoidRootPart
                    local head = char.Head
                    
                    local playerDistance = (root.Position - camPos).Magnitude
                    local withinDistance = playerDistance <= maxDistance

                    local headPos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                    local footPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 2.5, 0))

                    if onScreen and headPos.Z > 0 and withinDistance then
                        local rawHeight = footPos.Y - headPos.Y
                        local height = rawHeight * Visual.AdvancedESP.settings.scale
                        local width = (height / 2) * Visual.AdvancedESP.settings.scale
                        local x = headPos.X - width / 2
                        local y = headPos.Y - (height - rawHeight) / 2

                        -- Box Fill
                        if d.BoxFill then
                            d.BoxFill.Position = Vector2.new(x, y)
                            d.BoxFill.Size = Vector2.new(width, height)
                            d.BoxFill.Color = Visual.AdvancedESP.colorMap[Visual.AdvancedESP.settings.boxFillColorName] or Visual.AdvancedESP.colorMap.White
                            d.BoxFill.Visible = Visual.AdvancedESP.settings.boxFill.Enabled
                        end

                        -- Box Outline
                        if d.Box then
                            d.Box.Position = Vector2.new(x, y)
                            d.Box.Size = Vector2.new(width, height)
                            d.Box.Color = Visual.AdvancedESP.colorMap[Visual.AdvancedESP.settings.boxColorName] or Visual.AdvancedESP.colorMap.White
                            d.Box.Visible = Visual.AdvancedESP.settings.box.Enabled
                        end

                        -- Name
                        if d.Name then
                            d.Name.Text = plr.Name
                            d.Name.Position = Vector2.new(headPos.X, y - 22)
                            d.Name.Visible = Visual.AdvancedESP.settings.name.Enabled
                        end

                        -- Distance
                        if d.Distance then
                            local dist = math.floor(playerDistance)
                            d.Distance.Text = dist .. "m"
                            d.Distance.Position = Vector2.new(headPos.X, y + height + 6)
                            d.Distance.Visible = Visual.AdvancedESP.settings.distance.Enabled
                        end

                        -- Health Bar
                        if Visual.AdvancedESP.settings.healthbar.Enabled then
                            local barX = x - (Visual.AdvancedESP.settings.healthBarLeftOffset or 10)
                            local barY = y
                            local barWidth = 6
                            local barHeight = height
                            
                            -- Health Bar Background
                            if d.HealthBg then
                                d.HealthBg.Position = Vector2.new(barX, barY)
                                d.HealthBg.Size = Vector2.new(barWidth, barHeight)
                                d.HealthBg.Visible = true
                            end
                            
                            -- Health Stripes
                            local hpPerc = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                            for i = 1, 24 do
                                local stripe = d["HealthStripe"..i]
                                if stripe then
                                    local stripeY = barY + barHeight * (i - 1) / 24
                                    local stripeH = barHeight / 24
                                    local stripeColor = Visual.GetHealthGradientColor(stripeY - barY, barHeight)
                                    stripe.Color = stripeColor
                                    stripe.Position = Vector2.new(barX, stripeY)
                                    stripe.Size = Vector2.new(barWidth, stripeH)
                                    stripe.Visible = (i - 1) / 24 < hpPerc
                                end
                            end
                            
                            -- Health Text
                            if d.HealthText then
                                d.HealthText.Text = tostring(math.floor(hum.Health))
                                d.HealthText.Position = Vector2.new(barX - 14, y + height / 2)
                                d.HealthText.Visible = true
                            end
                        else
                            -- Скрываем health bar если отключен
                            if d.HealthBg then d.HealthBg.Visible = false end
                            for i = 1, 24 do
                                if d["HealthStripe"..i] then
                                    d["HealthStripe"..i].Visible = false
                                end
                            end
                            if d.HealthText then d.HealthText.Visible = false end
                        end

                        -- Bones
                        if d.Bones and Visual.AdvancedESP.settings.bones.Enabled then
                            local bones
                            
                            if Visual.IsR6(char) then
                                bones = {
                                    {char:FindFirstChild("Head"), char:FindFirstChild("Torso")},
                                    {char:FindFirstChild("Torso"), char:FindFirstChild("Left Arm")},
                                    {char:FindFirstChild("Left Arm"), char:FindFirstChild("Left Leg")},
                                    {char:FindFirstChild("Torso"), char:FindFirstChild("Right Arm")},
                                    {char:FindFirstChild("Right Arm"), char:FindFirstChild("Right Leg")},
                                    {char:FindFirstChild("Torso"), char:FindFirstChild("Left Leg")},
                                    {char:FindFirstChild("Torso"), char:FindFirstChild("Right Leg")}
                                }
                            else
                                bones = {
                                    {char:FindFirstChild("Head"), char:FindFirstChild("Neck")},
                                    {char:FindFirstChild("Neck"), char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")},
                                    {char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"), char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")},
                                    {char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm"), char:FindFirstChild("LeftLowerArm") or char:FindFirstChild("Left Forearm")},
                                    {char:FindFirstChild("LeftLowerArm") or char:FindFirstChild("Left Forearm"), char:FindFirstChild("LeftHand") or char:FindFirstChild("Left hand")},
                                    {char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"), char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")},
                                    {char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm"), char:FindFirstChild("RightLowerArm") or char:FindFirstChild("Right Forearm")},
                                    {char:FindFirstChild("RightLowerArm") or char:FindFirstChild("Right Forearm"), char:FindFirstChild("RightHand") or char:FindFirstChild("Right hand")},
                                    {char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"), char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg")},
                                    {char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg"), char:FindFirstChild("LeftLowerLeg") or char:FindFirstChild("Left Shin")},
                                    {char:FindFirstChild("LeftLowerLeg") or char:FindFirstChild("Left Shin"), char:FindFirstChild("LeftFoot") or char:FindFirstChild("Left foot")},
                                    {char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"), char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg")},
                                    {char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg"), char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("Right Shin")},
                                    {char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("Right Shin"), char:FindFirstChild("RightFoot") or char:FindFirstChild("Right foot")}
                                }
                            end
                            
                            for i = 1, 14 do
                                local line = d.Bones[i]
                                if bones[i] and bones[i][1] and bones[i][2] then
                                    local p1, p1OnScreen = Camera:WorldToViewportPoint(bones[i][1].Position)
                                    local p2, p2OnScreen = Camera:WorldToViewportPoint(bones[i][2].Position)
                                    if p1OnScreen and p2OnScreen and p1.Z > 0 and p2.Z > 0 then
                                        line.From = Vector2.new(p1.X, p1.Y)
                                        line.To = Vector2.new(p2.X, p2.Y)
                                        line.Color = Visual.AdvancedESP.colorMap[Visual.AdvancedESP.settings.boneColorName] or Visual.AdvancedESP.colorMap.White
                                        line.Visible = true
                                    else
                                        line.Visible = false
                                    end
                                else
                                    line.Visible = false
                                end
                            end
                        elseif d.Bones then
                            for _, line in ipairs(d.Bones) do
                                line.Visible = false
                            end
                        end

                        -- Tracer
                        if d.Tracer then
                            d.Tracer.From = screenCenter
                            d.Tracer.To = Vector2.new(headPos.X, headPos.Y)
                            d.Tracer.Color = Visual.AdvancedESP.colorMap[Visual.AdvancedESP.settings.tracerColorName] or Visual.AdvancedESP.colorMap.White
                            d.Tracer.Visible = Visual.AdvancedESP.settings.tracers.Enabled
                        end
                    else
                        -- Скрываем все, если игрок не на экране
                        if d.BoxFill then d.BoxFill.Visible = false end
                        if d.Box then d.Box.Visible = false end
                        if d.Name then d.Name.Visible = false end
                        if d.Distance then d.Distance.Visible = false end
                        if d.HealthBg then d.HealthBg.Visible = false end
                        if d.HealthText then d.HealthText.Visible = false end
                        for i = 1, 24 do
                            if d["HealthStripe"..i] then d["HealthStripe"..i].Visible = false end
                        end
                        if d.Bones then 
                            for _, line in ipairs(d.Bones) do 
                                line.Visible = false 
                            end 
                        end
                        if d.Tracer then d.Tracer.Visible = false end
                    end
                end
            else
                Visual.ClearAdvancedESP(plr)
            end
        end
    end
end

function Visual.StartAdvancedESP()
    if Visual.AdvancedESP.advancedESPRunning then return end
    
    -- Проверяем, есть ли активные компоненты
    local anyComponentEnabled = false
    for _, component in pairs(Visual.AdvancedESP.settings) do
        if type(component) == "table" and component.Enabled then
            anyComponentEnabled = true
            break
        end
    end
    
    if not anyComponentEnabled then return end
    
    Visual.AdvancedESP.advancedESPRunning = true
    
    -- Очищаем старые соединения
    if Visual.AdvancedESP.connections.playerAdded then
        Visual.AdvancedESP.connections.playerAdded:Disconnect()
    end
    if Visual.AdvancedESP.connections.playerRemoving then
        Visual.AdvancedESP.connections.playerRemoving:Disconnect()
    end
    if Visual.AdvancedESP.connections.renderStepped then
        Visual.AdvancedESP.connections.renderStepped:Disconnect()
    end
    
    -- Настраиваем отслеживание новых игроков
    Visual.AdvancedESP.connections.playerAdded = Nexus.Services.Players.PlayerAdded:Connect(function(plr)
        Visual.SetupPlayerAdvancedESP(plr)
    end)
    
    Visual.AdvancedESP.connections.playerRemoving = Nexus.Services.Players.PlayerRemoving:Connect(function(plr)
        Visual.CleanupPlayerAdvancedESP(plr)
    end)
    
    -- Настраиваем ESP для существующих игроков
    for _, plr in pairs(Nexus.Services.Players:GetPlayers()) do
        if plr ~= Nexus.Player then
            Visual.SetupPlayerAdvancedESP(plr)
        end
    end
    
    -- Запускаем цикл обновления
    Visual.AdvancedESP.connections.renderStepped = Nexus.Services.RunService.RenderStepped:Connect(function()
        Visual.UpdateAdvancedESP()
    end)
end

function Visual.StopAdvancedESP()
    if not Visual.AdvancedESP.advancedESPRunning then return end
    Visual.AdvancedESP.advancedESPRunning = false
    
    -- Отключаем все соединения
    if Visual.AdvancedESP.connections.renderStepped then
        Visual.AdvancedESP.connections.renderStepped:Disconnect()
        Visual.AdvancedESP.connections.renderStepped = nil
    end
    
    if Visual.AdvancedESP.connections.playerAdded then
        Visual.AdvancedESP.connections.playerAdded:Disconnect()
        Visual.AdvancedESP.connections.playerAdded = nil
    end
    
    if Visual.AdvancedESP.connections.playerRemoving then
        Visual.AdvancedESP.connections.playerRemoving:Disconnect()
        Visual.AdvancedESP.connections.playerRemoving = nil
    end
    
    -- Очищаем ESP для всех игроков
    local playersToClear = {}
    for plr, _ in pairs(Visual.AdvancedESP.espObjects) do
        table.insert(playersToClear, plr)
    end
    
    for _, plr in ipairs(playersToClear) do
        Visual.ClearAdvancedESP(plr)
    end
    
    -- Очищаем соединения игроков
    for plr, connections in pairs(Visual.AdvancedESP.playerConnections) do
        for name, connection in pairs(connections) do
            if connection and typeof(connection) == "RBXScriptConnection" then
                connection:Disconnect()
            end
        end
    end
    
    Visual.AdvancedESP.espObjects = {}
    Visual.AdvancedESP.playerConnections = {}
    Visual.AdvancedESP.connections = {}
end

-- Остальные функции (ToggleNoShadow, ToggleNoFog и т.д.) остаются без изменений
-- ...

function Visual.ToggleAdvancedESPComponent(componentName, enabled)
    if not Visual.AdvancedESP.settings[componentName] then return end
    
    Visual.AdvancedESP.settings[componentName].Enabled = enabled
    
    -- Проверяем, нужно ли запускать или останавливать Advanced ESP
    local anyComponentEnabled = false
    for _, component in pairs(Visual.AdvancedESP.settings) do
        if type(component) == "table" and component.Enabled then
            anyComponentEnabled = true
            break
        end
    end
    
    if anyComponentEnabled and not Visual.AdvancedESP.advancedESPRunning then
        Visual.StartAdvancedESP()
    elseif not anyComponentEnabled and Visual.AdvancedESP.advancedESPRunning then
        Visual.StopAdvancedESP()
    end
end

function Visual.Init(nxs)
    Nexus = nxs
    
    local Tabs = Nexus.Tabs
    local Options = Nexus.Options
    
    -- ... (остальной код инициализации без изменений)
    -- При создании тогглов для Advanced ESP используйте ToggleAdvancedESPComponent:
    
    local ESPBoxToggle = Tabs.Visual:AddToggle("ESPBox", {
        Title = "Player Boxes", 
        Description = "Show/hide player boxes", 
        Default = true
    })
    ESPBoxToggle:OnChanged(function(v)
        Visual.ToggleAdvancedESPComponent("box", v)
    end)
    
    -- Аналогично для других компонентов...
end

function Visual.Cleanup()
    Visual.StopESP()
    Visual.StopAdvancedESP()
    
    Visual.ForceCleanupDrawings()
    
    Visual.ToggleNoShadow(false)
    Visual.ToggleNoFog(false)
    Visual.ToggleFullBright(false)
    Visual.ToggleTimeChanger(false)
    
    for _, connection in pairs(Visual.Connections) do
        if connection then
            connection:Disconnect()
        end
    end
    Visual.Connections = {}
    
    for name, connection in pairs(Visual.ESP.espConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    Visual.ESP.espConnections = {}
    
    for name, connection in pairs(Visual.AdvancedESP.connections) do
        if connection then
            connection:Disconnect()
        end
    end
    Visual.AdvancedESP.connections = {}
    
    for plr, connections in pairs(Visual.AdvancedESP.playerConnections) do
        for name, connection in pairs(connections) do
            if connection then
                connection:Disconnect()
            end
        end
    end
    Visual.AdvancedESP.playerConnections = {}
    
    Visual.AdvancedESP.espObjects = {}
    
    task.wait(0.1)
    collectgarbage()
end

return Visual
