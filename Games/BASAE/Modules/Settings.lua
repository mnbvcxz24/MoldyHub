-- ORIGINAL BASAE SETTINGS PAGE
return function(Context)
    local index = 6
    local name = "Settings"
    local Page = CreatePage(index, name)
    local ScaleCard = CreateCard(Page, "Interface Scale", "Adjust the size of the entire interface.")
    local ScaleOptions = {"50%", "75%", "100%"}
    if type(SavedConfig.UIScale) == "number" then
        UIScale.Scale = math.clamp(SavedConfig.UIScale, 50 / 75, 100 / 75)
    end
    if type(SavedConfig.Theme) == "string" and ThemePresets[SavedConfig.Theme] then
        ApplyTheme(SavedConfig.Theme)
    end
    CreateDropdown(ScaleCard, "UI Scale", ScaleOptions, function(scaleOption)
        local scalePercent = tonumber(string.gsub(scaleOption, "%%", ""))
        if not scalePercent then return end
        local oldSize = Main.AbsoluteSize
        UIScale.Scale = scalePercent / 75
        local newSize = Main.AbsoluteSize
        Main.Position = UDim2.new(
            Main.Position.X.Scale,
            Main.Position.X.Offset + (oldSize.X - newSize.X) / 2,
            Main.Position.Y.Scale,
            Main.Position.Y.Offset + (oldSize.Y - newSize.Y) / 2
        )
    end)
    
    local AntiAFKCard = CreateCard(Page, "️  Anti AFK", "")
    AntiAFKCard.Size = UDim2.new(1, 0, 0, 72)
    local AntiAFKEnabled = true
    local AntiAFKStatus = Create("TextLabel", {
        Parent = AntiAFKCard,
        Position = UDim2.fromOffset(11, 47),
        Size = UDim2.new(1, -82, 0, 14),
        BackgroundTransparency = 1,
        Text = "Status: Enabled",
        TextColor3 = Theme.Accent,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    local SavedAntiAFK = true
    if type(SavedConfig.Toggles) == "table" and type(SavedConfig.Toggles.AntiAFK_Main) == "boolean" then
        SavedAntiAFK = SavedConfig.Toggles.AntiAFK_Main
    end
    local AntiAFKToggle = CreateToggle(AntiAFKCard, "", SavedAntiAFK, function(enabled)
        AntiAFKEnabled = enabled
        AntiAFKStatus.Text = "Status: " .. (enabled and "Enabled" or "Disabled")
        AntiAFKStatus.TextColor3 = enabled and Theme.Accent or Theme.Gray
    end)
    AntiAFKToggle.Position = UDim2.new(1, -58, 0, 7)
    AntiAFKToggle.Size = UDim2.fromOffset(48, 24)
    local AntiAFKTitle = AntiAFKCard:FindFirstChildWhichIsA("TextLabel")
    if AntiAFKTitle then AntiAFKTitle.Size = UDim2.new(1, -78, 0, 22) end
    local AntiAFKConnection = LocalPlayer.Idled:Connect(function()
        if not AntiAFKEnabled or Runtime.Stopped then return end
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end)
    Runtime.PersistentConnections = Runtime.PersistentConnections or {}
    table.insert(Runtime.PersistentConnections, AntiAFKConnection)
    
    local ConfigSaveCard = CreateCard(Page, "Config Save", "Save feature toggles, farm filters, and interface preferences.")
    ConfigSaveCard.Size = UDim2.new(1, 0, 0, 122)
    local ConfigStatus = Create("TextLabel", {
        Parent = ConfigSaveCard,
        Position = UDim2.fromOffset(11, 51),
        Size = UDim2.new(1, -22, 0, 14),
        BackgroundTransparency = 1,
        Text = ConfigStorageAvailable and "Status: Ready" or "Status: Executor file API unavailable",
        TextColor3 = ConfigStorageAvailable and Theme.Gray or Color3.fromRGB(235, 120, 100),
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    local ConfigSaveButton = CreateButton(ConfigSaveCard, "Save Config", function()
        if not ConfigStorageAvailable then
            ConfigStatus.Text = "Status: Executor file API unavailable"
            ConfigStatus.TextColor3 = Color3.fromRGB(235, 120, 100)
            return
        end
        local config = {
            Version = 1,
            SavedAt = os.time(),
            Theme = ActiveThemeName,
            UIScale = UIScale.Scale,
            Toggles = {},
            Farm = type(GetFarmConfigSnapshot) == "function" and GetFarmConfigSnapshot() or nil
        }
        for key, controller in pairs(ConfigToggleControllers) do
            if controller and type(controller.GetEnabled) == "function" then
                config.Toggles[key] = controller.GetEnabled()
            end
        end
        local ok, err = pcall(function()
            if type(isfolder) == "function" and not isfolder("MoldyHub") and type(makefolder) == "function" then
                makefolder("MoldyHub")
            end
            writefile(ConfigFilePath, game:GetService("HttpService"):JSONEncode(config))
        end)
        if ok then
            SavedConfig = config
            ConfigStatus.Text = "Status: Config saved"
            ConfigStatus.TextColor3 = Theme.Accent
        else
            ConfigStatus.Text = "Status: Save failed - " .. tostring(err):sub(1, 70)
            ConfigStatus.TextColor3 = Color3.fromRGB(235, 120, 100)
        end
    end)
    ConfigSaveButton.Position = UDim2.fromOffset(11, 82)
    ConfigSaveButton.Size = UDim2.new(1, -22, 0, 27)
    
    local AutoExecuteCard = CreateCard(Page, "Auto Execute", "Create or remove the MoldyHub auto-execute file.")
    AutoExecuteCard.Size = UDim2.new(1, 0, 0, 132)
    local AutoExecutePath = "../Autoexecute/MoldyHub_Execute.lua"
    local AutoExecuteSource = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/MoldyHub/Skrip/refs/heads/main/Loader.lua"))()'
    local AutoExecuteStatus = Create("TextLabel", {
        Parent = AutoExecuteCard,
        Position = UDim2.fromOffset(11, 43),
        Size = UDim2.new(1, -22, 0, 14),
        BackgroundTransparency = 1,
        Text = "Status: Ready",
        TextColor3 = Theme.Gray,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    local function SetAutoExecuteStatus(message, success)
        AutoExecuteStatus.Text = "Status: " .. message
        AutoExecuteStatus.TextColor3 = success and Color3.fromRGB(125, 220, 135) or Color3.fromRGB(235, 120, 100)
    end
    local function CreateAutoExecuteButton(buttonText, position, color, hoverColor, callback)
        local Button = Create("TextButton", {
            Parent = AutoExecuteCard,
            Size = UDim2.new(1, -22, 0, 27),
            Position = position,
            BackgroundColor3 = color,
            Text = buttonText,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Font = Enum.Font.GothamMedium,
            TextSize = 9,
            BorderSizePixel = 0,
            AutoButtonColor = false
        })
        AddCorner(Button, 6)
        Button.MouseEnter:Connect(function()
            Tween(Button, {BackgroundColor3 = hoverColor})
        end)
        Button.MouseLeave:Connect(function()
            Tween(Button, {BackgroundColor3 = color})
        end)
        Button.MouseButton1Click:Connect(callback)
        return Button
    end
    CreateAutoExecuteButton(
        "Load Auto Execute",
        UDim2.fromOffset(11, 63),
        Color3.fromRGB(38, 145, 76),
        Color3.fromRGB(48, 175, 91),
        function()
            if type(writefile) ~= "function" then
                SetAutoExecuteStatus("Executor writefile API unavailable", false)
                return
            end
            local ok, err = pcall(function()
                writefile(AutoExecutePath, AutoExecuteSource)
            end)
            if ok then
                SetAutoExecuteStatus("Created MoldyHub_Execute.lua", true)
            else
                SetAutoExecuteStatus("Load failed - " .. tostring(err):sub(1, 65), false)
            end
        end
    )
    CreateAutoExecuteButton(
        "Unload Auto Execute",
        UDim2.fromOffset(11, 96),
        Color3.fromRGB(165, 55, 55),
        Color3.fromRGB(200, 65, 65),
        function()
            if type(delfile) ~= "function" then
                SetAutoExecuteStatus("Executor delfile API unavailable", false)
                return
            end
            local ok, err = pcall(function()
                if type(isfile) == "function" and not isfile(AutoExecutePath) then
                    error("Auto-execute file does not exist")
                end
                delfile(AutoExecutePath)
            end)
            if ok then
                SetAutoExecuteStatus("Unloaded MoldyHub_Execute.lua", true)
            else
                SetAutoExecuteStatus("Unload failed - " .. tostring(err):sub(1, 65), false)
            end
        end
    )
    
end
