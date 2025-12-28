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
        showGeneratorPercent = true
    },
    AdvancedESP = {
        settings = {
            name = {Enabled = true, TextSize = 15},
            distance = {Enabled = false, TextSize = 13},
            healthbar = {Enabled = true},
            box = {Enabled = false},
            boxType = "full",
            bones = {Enabled = false},
            boneColorName = "White",
            tracers = {Enabled = false},
            tracerColorName = "White",
            scale = 1.5,
            healthBarTopColorName = "DarkGreen",
            healthBarMidColorName = "DarkOrange",
            healthBarBottomColorName = "DarkRed",
            stateColorName = "Orange",
            boxOutline = {Enabled = true, Thickness = 0.4},
            boxOutlineColorName = "Black",
            boxColorName = "White",
            boxFill = {Enabled = false},
            boxFillColorName = "White",
            boxFillTransparency = 0.9,
            healthBarLeftOffset = 10
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
        advancedESPRunning = false
    },
    NewESP = {
        enabled = false,
        boxes = {},
        names = {},
        healthbars = {},
        connections = {},
        settings = {
            Box_Color = Color3.fromRGB(255, 0, 0),
            Box_Thickness = 2,
            Team_Check = false,
            Team_Color = false,
            Autothickness = true,
            Show_Names = true,
            Show_HealthBar = true,
            HealthBar_Width = 6,
            HealthBar_Offset = 10
        }
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

-- Новая система ESP
function Visual.NewESP:CreateBoxLibrary()
    local function NewLine(color, thickness)
        local line = Drawing.new("Line")
        line.Visible = false
        line.From = Vector2.new(0, 0)
        line.To = Vector2.new(0, 0)
        line.Color = color
        line.Thickness = thickness
        line.Transparency = 1
        return line
    end
    
    local Library = {
        TL1 = NewLine(self.settings.Box_Color, self.settings.Box_Thickness),
        TL2 = NewLine(self.settings.Box_Color, self.settings.Box_Thickness),
        TR1 = NewLine(self.settings.Box_Color, self.settings.Box_Thickness),
        TR2 = NewLine(self.settings.Box_Color, self.settings.Box_Thickness),
        BL1 = NewLine(self.settings.Box_Color, self.settings.Box_Thickness),
        BL2 = NewLine(self.settings.Box_Color, self.settings.Box_Thickness),
        BR1 = NewLine(self.settings.Box_Color, self.settings.Box_Thickness),
        BR2 = NewLine(self.settings.Box_Color, self.settings.Box_Thickness)
    }
    
    -- Создаем элементы для имени и хилбара
    local NameLabel = Drawing.new("Text")
    NameLabel.Visible = false
    NameLabel.Color = Color3.fromRGB(255, 255, 255)
    NameLabel.Size = 15
    NameLabel.Center = true
    NameLabel.Outline = true
    NameLabel.OutlineColor = Color3.fromRGB(0, 0, 0)
    
    local HealthBarBg = Drawing.new("Square")
    HealthBarBg.Visible = false
    HealthBarBg.Filled = true
    HealthBarBg.Color = Color3.fromRGB(0, 0, 0)
    HealthBarBg.Transparency = 0.5
    
    local HealthBar = Drawing.new("Square")
    HealthBar.Visible = false
    HealthBar.Filled = true
    HealthBar.Color = Color3.fromRGB(0, 255, 0)
    
    return {
        BoxLines = Library,
        Name = NameLabel,
        HealthBarBg = HealthBarBg,
        HealthBar = HealthBar,
        HealthText = nil,
        oripart = nil
    }
end

function Visual.NewESP:GetHealthColor(healthPercent)
    if healthPercent >= 0.7 then
        return Color3.fromRGB(0, 255, 0)
    elseif healthPercent >= 0.4 then
        return Color3.fromRGB(255, 165, 0)
    else
        return Color3.fromRGB(255, 0, 0)
    end
end

function Visual.NewESP:SetupPlayer(plr)
    if plr == Nexus.Player or self.boxes[plr] then return end
    
    repeat wait() until plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character:FindFirstChild("HumanoidRootPart")
    
    local boxData = self:CreateBoxLibrary()
    
    -- Создаем орпарт для расчета бокса
    local oripart = Instance.new("Part")
    oripart.Parent = workspace
    oripart.Transparency = 1
    oripart.CanCollide = false
    oripart.Size = Vector3.new(1, 1, 1)
    oripart.Position = Vector3.new(0, 0, 0)
    oripart.Anchored = true
    
    boxData.oripart = oripart
    
    self.boxes[plr] = boxData
    self.names[plr] = plr.Name
    self.healthbars[plr] = plr.Character:FindFirstChildOfClass("Humanoid")
    
    -- Подписываемся на изменения
    local function updateConnection()
        if not self.connections[plr] then
            self.connections[plr] = {}
        end
        
        -- Подписка на смерть персонажа
        self.connections[plr].died = plr.Character:FindFirstChildOfClass("Humanoid").Died:Connect(function()
            self:RemovePlayer(plr)
        end)
        
        -- Подписка на удаление персонажа
        self.connections[plr].removing = plr.CharacterRemoving:Connect(function()
            self:RemovePlayer(plr)
        end)
    end
    
    if plr.Character then
        updateConnection()
    end
    
    plr.CharacterAdded:Connect(function(char)
        wait(0.5)
        if char then
            updateConnection()
            self.healthbars[plr] = char:FindFirstChildOfClass("Humanoid")
        end
    end)
end

function Visual.NewESP:RemovePlayer(plr)
    local boxData = self.boxes[plr]
    if boxData then
        -- Удаляем линии бокса
        for _, line in pairs(boxData.BoxLines) do
            if line and line.Remove then
                pcall(function() line:Remove() end)
            end
        end
        
        -- Удаляем текст имени
        if boxData.Name and boxData.Name.Remove then
            pcall(function() boxData.Name:Remove() end)
        end
        
        -- Удаляем хилбар
        if boxData.HealthBarBg and boxData.HealthBarBg.Remove then
            pcall(function() boxData.HealthBarBg:Remove() end)
        end
        
        if boxData.HealthBar and boxData.HealthBar.Remove then
            pcall(function() boxData.HealthBar:Remove() end)
        end
        
        -- Удаляем орпарт
        if boxData.oripart then
            pcall(function() boxData.oripart:Destroy() end)
        end
    end
    
    -- Удаляем соединения
    if self.connections[plr] then
        for _, conn in pairs(self.connections[plr]) do
            pcall(function() conn:Disconnect() end)
        end
        self.connections[plr] = nil
    end
    
    self.boxes[plr] = nil
    self.names[plr] = nil
    self.healthbars[plr] = nil
end

function Visual.NewESP:Update()
    if not self.enabled then return end
    
    local Camera = workspace.CurrentCamera
    local Player = Nexus.Player
    
    for plr, boxData in pairs(self.boxes) do
        if not plr or not plr.Parent then
            self:RemovePlayer(plr)
            continue
        end
        
        local char = plr.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then
            for _, line in pairs(boxData.BoxLines) do
                line.Visible = false
            end
            if boxData.Name then boxData.Name.Visible = false end
            if boxData.HealthBarBg then boxData.HealthBarBg.Visible = false end
            if boxData.HealthBar then boxData.HealthBar.Visible = false end
            continue
        end
        
        local hum = char:FindFirstChild("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        
        if hum and hum.Health <= 0 then
            for _, line in pairs(boxData.BoxLines) do
                line.Visible = false
            end
            if boxData.Name then boxData.Name.Visible = false end
            if boxData.HealthBarBg then boxData.HealthBarBg.Visible = false end
            if boxData.HealthBar then boxData.HealthBar.Visible = false end
            continue
        end
        
        local humPos, vis = Camera:WorldToViewportPoint(hrp.Position)
        
        if vis then
            -- Обновляем орпарт
            local oripart = boxData.oripart
            if oripart then
                oripart.Size = Vector3.new(hrp.Size.X, hrp.Size.Y * 1.5, hrp.Size.Z)
                oripart.CFrame = CFrame.new(hrp.CFrame.Position, Camera.CFrame.Position)
            end
            
            -- Получаем координаты углов бокса
            if oripart then
                local SizeX = oripart.Size.X
                local SizeY = oripart.Size.Y
                
                local TL = Camera:WorldToViewportPoint((oripart.CFrame * CFrame.new(SizeX, SizeY, 0)).p)
                local TR = Camera:WorldToViewportPoint((oripart.CFrame * CFrame.new(-SizeX, SizeY, 0)).p)
                local BL = Camera:WorldToViewportPoint((oripart.CFrame * CFrame.new(SizeX, -SizeY, 0)).p)
                local BR = Camera:WorldToViewportPoint((oripart.CFrame * CFrame.new(-SizeX, -SizeY, 0)).p)
                
                local ratio = (Camera.CFrame.p - hrp.Position).magnitude
                local offset = math.clamp(1/ratio*750, 2, 300)
                
                -- Устанавливаем позиции линий
                boxData.BoxLines.TL1.From = Vector2.new(TL.X, TL.Y)
                boxData.BoxLines.TL1.To = Vector2.new(TL.X + offset, TL.Y)
                boxData.BoxLines.TL2.From = Vector2.new(TL.X, TL.Y)
                boxData.BoxLines.TL2.To = Vector2.new(TL.X, TL.Y + offset)
                
                boxData.BoxLines.TR1.From = Vector2.new(TR.X, TR.Y)
                boxData.BoxLines.TR1.To = Vector2.new(TR.X - offset, TR.Y)
                boxData.BoxLines.TR2.From = Vector2.new(TR.X, TR.Y)
                boxData.BoxLines.TR2.To = Vector2.new(TR.X, TR.Y + offset)
                
                boxData.BoxLines.BL1.From = Vector2.new(BL.X, BL.Y)
                boxData.BoxLines.BL1.To = Vector2.new(BL.X + offset, BL.Y)
                boxData.BoxLines.BL2.From = Vector2.new(BL.X, BL.Y)
                boxData.BoxLines.BL2.To = Vector2.new(BL.X, BL.Y - offset)
                
                boxData.BoxLines.BR1.From = Vector2.new(BR.X, BR.Y)
                boxData.BoxLines.BR1.To = Vector2.new(BR.X - offset, BR.Y)
                boxData.BoxLines.BR2.From = Vector2.new(BR.X, BR.Y)
                boxData.BoxLines.BR2.To = Vector2.new(BR.X, BR.Y - offset)
                
                -- Показываем линии
                for _, line in pairs(boxData.BoxLines) do
                    line.Visible = true
                    
                    -- Автотолщина
                    if self.settings.Autothickness then
                        local distance = (Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and 
                                         (Player.Character.HumanoidRootPart.Position - hrp.Position).magnitude) or 100
                        local value = math.clamp(1/distance*100, 1, 4)
                        line.Thickness = value
                    else
                        line.Thickness = self.settings.Box_Thickness
                    end
                    
                    -- Цвет команды
                    if self.settings.Team_Check then
                        if plr.TeamColor == Player.TeamColor then
                            line.Color = Color3.fromRGB(0, 255, 0)
                        else
                            line.Color = Color3.fromRGB(255, 0, 0)
                        end
                    elseif self.settings.Team_Color then
                        line.Color = plr.TeamColor.Color
                    else
                        line.Color = self.settings.Box_Color
                    end
                end
                
                -- Имя игрока
                if self.settings.Show_Names and boxData.Name then
                    boxData.Name.Text = plr.Name
                    boxData.Name.Position = Vector2.new(humPos.X, TL.Y - 20)
                    boxData.Name.Visible = true
                elseif boxData.Name then
                    boxData.Name.Visible = false
                end
                
                -- Хилбар
                if self.settings.Show_HealthBar and hum then
                    local healthPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    local barHeight = (BL.Y - TL.Y) * healthPercent
                    local barY = TL.Y + (BL.Y - TL.Y - barHeight)
                    
                    -- Фон хилбара
                    boxData.HealthBarBg.Position = Vector2.new(TR.X + self.settings.HealthBar_Offset, TL.Y)
                    boxData.HealthBarBg.Size = Vector2.new(self.settings.HealthBar_Width, BL.Y - TL.Y)
                    boxData.HealthBarBg.Visible = true
                    
                    -- Сам хилбар
                    boxData.HealthBar.Position = Vector2.new(TR.X + self.settings.HealthBar_Offset, barY)
                    boxData.HealthBar.Size = Vector2.new(self.settings.HealthBar_Width, barHeight)
                    boxData.HealthBar.Color = self:GetHealthColor(healthPercent)
                    boxData.HealthBar.Visible = true
                else
                    if boxData.HealthBarBg then boxData.HealthBarBg.Visible = false end
                    if boxData.HealthBar then boxData.HealthBar.Visible = false end
                end
            end
        else
            -- Скрываем все если игрок не на экране
            for _, line in pairs(boxData.BoxLines) do
                line.Visible = false
            end
            if boxData.Name then boxData.Name.Visible = false end
            if boxData.HealthBarBg then boxData.HealthBarBg.Visible = false end
            if boxData.HealthBar then boxData.HealthBar.Visible = false end
        end
    end
end

function Visual.NewESP:Start()
    if self.enabled then return end
    self.enabled = true
    
    -- Очищаем старые данные
    self:Stop()
    
    -- Подписываемся на добавление игроков
    game:GetService("Players").PlayerAdded:Connect(function(plr)
        if self.enabled then
            self:SetupPlayer(plr)
        end
    end)
    
    -- Подписываемся на удаление игроков
    game:GetService("Players").PlayerRemoving:Connect(function(plr)
        self:RemovePlayer(plr)
    end)
    
    -- Добавляем существующих игроков
    for _, plr in pairs(game:GetService("Players"):GetPlayers()) do
        if plr ~= Nexus.Player then
            self:SetupPlayer(plr)
        end
    end
    
    -- Запускаем цикл обновления
    self.updateConnection = game:GetService("RunService").RenderStepped:Connect(function()
        self:Update()
    end)
end

function Visual.NewESP:Stop()
    self.enabled = false
    
    -- Отключаем соединение обновления
    if self.updateConnection then
        pcall(function() self.updateConnection:Disconnect() end)
        self.updateConnection = nil
    end
    
    -- Удаляем всех игроков
    local playersToRemove = {}
    for plr, _ in pairs(self.boxes) do
        table.insert(playersToRemove, plr)
    end
    
    for _, plr in ipairs(playersToRemove) do
        self:RemovePlayer(plr)
    end
    
    -- Очищаем таблицы
    table.clear(self.boxes)
    table.clear(self.names)
    table.clear(self.healthbars)
    
    -- Очищаем соединения
    for plr, connections in pairs(self.connections) do
        for _, conn in pairs(connections) do
            pcall(function() conn:Disconnect() end)
        end
    end
    table.clear(self.connections)
end

function Visual.NewESP:Toggle(enabled)
    if enabled then
        self:Start()
    else
        self:Stop()
    end
end

-- УДАЛЕННЫЕ ФУНКЦИИ (оригинальные функции AdvancedESP оставлены, но не используются)

-- Остальные функции остаются без изменений (ESP система, Effects и т.д.)
-- ... (остальной код остается без изменений, включая функции Visual.GetGeneratorProgress, Visual.EnsureHighlight и т.д.)

function Visual.UpdateESP()
    -- ... (без изменений)
end

function Visual.StartESPLoop()
    -- ... (без изменений)
end

function Visual.StartESP()
    -- ... (без изменений)
end

function Visual.StopESP()
    -- ... (без изменений)
end

function Visual.ToggleESPSetting(settingName, enabled)
    -- ... (без изменений)
end

function Visual.UpdateESPColors()
    -- ... (без изменений)
end

function Visual.UpdateESPDisplay()
    -- ... (без изменений)
end

function Visual.ClearAdvancedESP(plr)
    -- ... (без изменений, но можно оставить)
end

function Visual.ForceCleanupDrawings()
    -- ... (без изменений)
end

function Visual.CreateAdvancedESP(plr)
    -- ... (без изменений, но не будет использоваться)
end

function Visual.SetupPlayerAdvancedESP(plr)
    -- ... (без изменений, но не будет использоваться)
end

function Visual.CleanupPlayerAdvancedESP(plr)
    -- ... (без изменений, но не будет использоваться)
end

function Visual.GetHealthGradientColor(y, h)
    -- ... (без изменений, но не будет использоваться)
end

function Visual.IsR6(char)
    -- ... (без изменений, но не будет использоваться)
end

function Visual.UpdateAdvancedESP()
    -- ... (без изменений, но не будет использоваться)
end

function Visual.StartAdvancedESP()
    -- ... (без изменений, но не будет использоваться)
end

function Visual.StopAdvancedESP()
    -- ... (без изменений, но не будет использоваться)
end

function Visual.ToggleNoShadow(enabled)
    -- ... (без изменений)
end

function Visual.ToggleNoFog(enabled)
    -- ... (без изменений)
end

function Visual.ToggleFullBright(enabled)
    -- ... (без изменений)
end

function Visual.ToggleTimeChanger(enabled)
    -- ... (без изменений)
end

function Visual.SetTime(time)
    -- ... (без изменений)
end

function Visual.Init(nxs)
    Nexus = nxs
    
    local Tabs = Nexus.Tabs
    local Options = Nexus.Options

    Tabs.Visual:AddSection("ESP All", "snowflake")  

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

    -- НОВАЯ СИСТЕМА ESP (боксы с углами)
    Tabs.Visual:AddSection("Advanced ESP", "users")
    
    -- Тоггл включения новой ESP
    local NewESPToggle = Tabs.Visual:AddToggle("NewESPEnabled", {
        Title = "New ESP", 
        Description = "Включить/выключить новую систему ESP", 
        Default = false
    })
    
    NewESPToggle:OnChanged(function(v)
        Visual.NewESP:Toggle(v)
    end)
    
    -- Настройки новой ESP
    local BoxColorPicker = Tabs.Visual:AddColorpicker("BoxColor", {
        Title = "Box Color",
        Default = Color3.fromRGB(255, 0, 0)
    })
    
    BoxColorPicker:OnChanged(function(color)
        Visual.NewESP.settings.Box_Color = color
    end)
    
    local BoxThicknessSlider = Tabs.Visual:AddSlider("BoxThickness", {
        Title = "Box Thickness",
        Description = "",
        Default = 2,
        Min = 1,
        Max = 5,
        Rounding = 0,
        Callback = function(value)
            Visual.NewESP.settings.Box_Thickness = value
        end
    })
    
    local TeamCheckToggle = Tabs.Visual:AddToggle("TeamCheck", {
        Title = "Team Check", 
        Description = "Разные цвета для своей/чужой команды", 
        Default = false
    })
    TeamCheckToggle:OnChanged(function(v)
        Visual.NewESP.settings.Team_Check = v
    end)
    
    local TeamColorToggle = Tabs.Visual:AddToggle("TeamColor", {
        Title = "Team Color", 
        Description = "Цвет по команде", 
        Default = false
    })
    TeamColorToggle:OnChanged(function(v)
        Visual.NewESP.settings.Team_Color = v
    end)
    
    local AutoThicknessToggle = Tabs.Visual:AddToggle("AutoThickness", {
        Title = "Auto Thickness", 
        Description = "Автотолщина по расстоянию", 
        Default = true
    })
    AutoThicknessToggle:OnChanged(function(v)
        Visual.NewESP.settings.Autothickness = v
    end)
    
    local ShowNamesToggle = Tabs.Visual:AddToggle("ShowNames", {
        Title = "Player Names", 
        Description = "Показывать имена игроков", 
        Default = true
    })
    ShowNamesToggle:OnChanged(function(v)
        Visual.NewESP.settings.Show_Names = v
    end)
    
    local ShowHealthBarToggle = Tabs.Visual:AddToggle("ShowHealthBar", {
        Title = "Health Bar", 
        Description = "Показывать здоровье", 
        Default = true
    })
    ShowHealthBarToggle:OnChanged(function(v)
        Visual.NewESP.settings.Show_HealthBar = v
    end)
    
    local HealthBarWidthSlider = Tabs.Visual:AddSlider("HealthBarWidth", {
        Title = "Health Bar Width",
        Description = "",
        Default = 6,
        Min = 3,
        Max = 12,
        Rounding = 0,
        Callback = function(value)
            Visual.NewESP.settings.HealthBar_Width = value
        end
    })
    
    local HealthBarOffsetSlider = Tabs.Visual:AddSlider("HealthBarOffset", {
        Title = "Health Bar Offset",
        Description = "",
        Default = 10,
        Min = 5,
        Max = 20,
        Rounding = 0,
        Callback = function(value)
            Visual.NewESP.settings.HealthBar_Offset = value
        end
    })

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
    Visual.StopAdvancedESP()
    Visual.NewESP:Stop()  -- Останавливаем новую ESP
    
    Visual.ForceCleanupDrawings()
    
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
    
    for _, connection in pairs(Visual.AdvancedESP.connections) do
        Nexus.safeDisconnect(connection)
    end
    Visual.AdvancedESP.connections = {}
    
    task.wait(0.1)
    pcall(function() game:GetService("RunService"):RenderStepped():Wait() end)
    collectgarbage()
end

return Visual
