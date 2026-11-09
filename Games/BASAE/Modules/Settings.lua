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
    
    local ConfigSaveCard = CreateCard(Page, "Config Save", "Save named configs, load one on rerun, or restore defaults.")
    ConfigSaveCard.Size = UDim2.new(1, 0, 0, 190)
    local ConfigNameInput = Create("TextBox", {
        Parent = ConfigSaveCard,
        Position = UDim2.fromOffset(11, 62),
        Size = UDim2.new(1, -22, 0, 26),
        BackgroundColor3 = Theme.SurfaceInput,
        Text = ActiveConfigName or "",
        PlaceholderText = "Enter config name",
        PlaceholderColor3 = Theme.Gray,
        TextColor3 = Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        ClearTextOnFocus = false,
        BorderSizePixel = 0
    })
    AddCorner(ConfigNameInput, 6)
    AddStroke(ConfigNameInput, Theme.Border, 1)

    local ConfigDropdown = Create("TextButton", {
        Parent = ConfigSaveCard,
        Position = UDim2.fromOffset(11, 94),
        Size = UDim2.new(1, -75, 0, 26),
        BackgroundColor3 = Theme.SurfaceInput,
        Text = "",
        TextColor3 = Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        ZIndex = 110
    })
    AddCorner(ConfigDropdown, 6)
    AddStroke(ConfigDropdown, Theme.Border, 1)
    local SelectedConfigName = ActiveConfigName
    local ConfigDropdownLabel = Create("TextLabel", {
        Parent = ConfigDropdown,
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -24, 1, 0),
        BackgroundTransparency = 1,
        Text = SelectedConfigName or "Select saved config",
        TextColor3 = Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 111
    })
    Create("TextLabel", {
        Parent = ConfigDropdown,
        Position = UDim2.new(1, -20, 0, 0),
        Size = UDim2.fromOffset(16, 26),
        BackgroundTransparency = 1,
        Text = "v",
        TextColor3 = Theme.Gray,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        ZIndex = 111
    })
    local ConfigList = Create("Frame", {
        Parent = ConfigDropdown,
        Position = UDim2.new(0, 0, 1, 3),
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = Theme.SurfaceInput,
        BorderSizePixel = 0,
        Visible = false,
        ClipsDescendants = true,
        ZIndex = 220
    })
    AddCorner(ConfigList, 6)
    AddStroke(ConfigList, Theme.Border, 1)
    local ConfigListLayout = Create("UIListLayout", {
        Parent = ConfigList,
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    local ConfigOptions = {}
    local function RefreshConfigOptions()
        for _, child in ipairs(ConfigList:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        ConfigOptions = {}
        if type(listfiles) == "function" then
            local ok, files = pcall(function() return listfiles(ConfigFolderPath) end)
            if ok and type(files) == "table" then
                for _, filePath in ipairs(files) do
                    local fileName = tostring(filePath):match("[/\\]([^/\\]+)%.json$")
                    if fileName and fileName:match("^[%w_%-]+$") then
                        table.insert(ConfigOptions, fileName)
                    end
                end
            end
        end
        table.sort(ConfigOptions, function(left, right) return string.lower(left) < string.lower(right) end)
        if SelectedConfigName then
            local found = false
            for _, configName in ipairs(ConfigOptions) do
                if configName == SelectedConfigName then found = true break end
            end
            if not found then SelectedConfigName = nil end
        end
        ConfigDropdownLabel.Text = SelectedConfigName or (#ConfigOptions > 0 and "Select saved config" or "No saved configs found")
        for index, configName in ipairs(ConfigOptions) do
            local option = Create("TextButton", {
                Parent = ConfigList,
                Size = UDim2.new(1, 0, 0, 24),
                BackgroundTransparency = 1,
                Text = configName,
                TextColor3 = Theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 9,
                BorderSizePixel = 0,
                LayoutOrder = index,
                ZIndex = 221
            })
            option.MouseButton1Click:Connect(function()
                SelectedConfigName = configName
                ConfigDropdownLabel.Text = configName
                ConfigNameInput.Text = configName
                ConfigList.Visible = false
            end)
        end
        ConfigList.Size = UDim2.new(1, 0, 0, math.min(#ConfigOptions, 5) * 24)
    end
    ConfigDropdown.MouseButton1Click:Connect(function()
        if #ConfigOptions == 0 then RefreshConfigOptions() end
        ConfigList.Visible = not ConfigList.Visible
    end)
    local ConfigRefreshButton = Create("TextButton", {
        Parent = ConfigSaveCard,
        Position = UDim2.new(1, -55, 0, 94),
        Size = UDim2.fromOffset(44, 26),
        BackgroundColor3 = Theme.SurfaceInput,
        Text = "Refresh",
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 8,
        BorderSizePixel = 0,
        AutoButtonColor = false
    })
    AddCorner(ConfigRefreshButton, 6)
    AddStroke(ConfigRefreshButton, Theme.Border, 1)
    ConfigRefreshButton.MouseButton1Click:Connect(RefreshConfigOptions)

    local ConfigStatus = Create("TextLabel", {
        Parent = ConfigSaveCard,
        Position = UDim2.fromOffset(11, 125),
        Size = UDim2.new(1, -22, 0, 14),
        BackgroundTransparency = 1,
        Text = ConfigStorageAvailable and (ActiveConfigName and ("Status: Active config - " .. ActiveConfigName) or "Status: Default config") or "Status: Executor file API unavailable",
        TextColor3 = ConfigStorageAvailable and Theme.Gray or Color3.fromRGB(235, 120, 100),
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    local function SetConfigStatus(message, success)
        ConfigStatus.Text = "Status: " .. message
        ConfigStatus.TextColor3 = success and Theme.Accent or Color3.fromRGB(235, 120, 100)
    end
    local function GetSafeConfigName()
        local rawName = tostring(ConfigNameInput.Text or "")
        local safeName = rawName:gsub("[^%w_%-]", "")
        if safeName == "" then return nil end
        return safeName
    end
    local function EnsureConfigFolder()
        if type(isfolder) == "function" and isfolder(ConfigFolderPath) then return end
        if type(makefolder) == "function" then
            if type(isfolder) ~= "function" or not isfolder(ConfigRootPath) then
                makefolder(ConfigRootPath)
            end
            if type(isfolder) ~= "function" or not isfolder(ConfigFolderPath) then
                makefolder(ConfigFolderPath)
            end
        else
            error("Delta folder API unavailable")
        end
    end
    local function CreateConfigActionButton(label, xScale, xOffset, color, hoverColor, callback)
        local button = Create("TextButton", {
            Parent = ConfigSaveCard,
            Position = UDim2.new(xScale, xOffset, 0, 149),
            Size = UDim2.new(1 / 3, -12, 0, 27),
            BackgroundColor3 = color,
            Text = label,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Font = Enum.Font.GothamMedium,
            TextSize = 8,
            BorderSizePixel = 0,
            AutoButtonColor = false
        })
        AddCorner(button, 6)
        button.MouseEnter:Connect(function() Tween(button, {BackgroundColor3 = hoverColor}) end)
        button.MouseLeave:Connect(function() Tween(button, {BackgroundColor3 = color}) end)
        button.MouseButton1Click:Connect(callback)
        return button
    end
    CreateConfigActionButton("Save Config", 0, 11, Color3.fromRGB(38, 145, 76), Color3.fromRGB(48, 175, 91), function()
        if not ConfigStorageAvailable then
            SetConfigStatus("Executor file API unavailable", false)
            return
        end
        local configName = GetSafeConfigName()
        if not configName then
            SetConfigStatus("Enter a valid config name", false)
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
        local configPath = ConfigFolderPath .. "/" .. configName .. ".json"
        local ok, err = pcall(function()
            EnsureConfigFolder()
            writefile(configPath, game:GetService("HttpService"):JSONEncode(config))
            writefile(ActiveConfigPath, configName)
        end)
        if ok then
            SavedConfig = config
            ActiveConfigName = configName
            SelectedConfigName = configName
            ConfigDropdownLabel.Text = configName
            RefreshConfigOptions()
            SetConfigStatus("Saved and selected - " .. configName, true)
        else
            SetConfigStatus("Save failed - " .. tostring(err):sub(1, 65), false)
        end
    end)
    CreateConfigActionButton("Load Selected", 1 / 3, 5, Color3.fromRGB(48, 105, 165), Color3.fromRGB(60, 130, 195), function()
        if not SelectedConfigName then
            SetConfigStatus("Select a saved config first", false)
            return
        end
        local configPath = ConfigFolderPath .. "/" .. SelectedConfigName .. ".json"
        local ok, result = pcall(function()
            if type(isfile) == "function" and not isfile(configPath) then error("Config file not found") end
            local decoded = game:GetService("HttpService"):JSONDecode(readfile(configPath))
            if type(decoded) ~= "table" or decoded.Version ~= 1 then error("Invalid config file") end
            writefile(ActiveConfigPath, SelectedConfigName)
            return decoded
        end)
        if ok then
            SavedConfig = result
            ActiveConfigName = SelectedConfigName
            SetConfigStatus("Selected " .. SelectedConfigName .. "; rerun BASAE to apply", true)
        else
            SetConfigStatus("Load failed - " .. tostring(result):sub(1, 65), false)
        end
    end)
    CreateConfigActionButton("Unload Config", 2 / 3, 0, Color3.fromRGB(165, 95, 45), Color3.fromRGB(190, 115, 55), function()
        if type(writefile) ~= "function" then
            SetConfigStatus("Executor writefile API unavailable", false)
            return
        end
        local ok, err = pcall(function()
            EnsureConfigFolder()
            writefile(ActiveConfigPath, "DEFAULT")
        end)
        if ok then
            ActiveConfigName = nil
            SelectedConfigName = nil
            ConfigDropdownLabel.Text = #ConfigOptions > 0 and "Select saved config" or "No saved configs found"
            SetConfigStatus("Default config selected; rerun BASAE to apply", true)
        else
            SetConfigStatus("Unload failed - " .. tostring(err):sub(1, 65), false)
        end
    end)
    RefreshConfigOptions()

    local AutoExecuteCard = CreateCard(Page, "Auto Execute", "Store or remove the MoldyHub loader in MoldyHub/autoexec. This folder alone does not enable automatic launch.")
    AutoExecuteCard.Size = UDim2.new(1, 0, 0, 132)
    local AutoExecuteFolderPath = "MoldyHub/autoexec"
    local AutoExecutePath = AutoExecuteFolderPath .. "/MoldyHub_Execute.lua"
    local function EnsureAutoExecuteFolder()
        if type(makefolder) ~= "function" then error("Executor makefolder API unavailable") end
        if type(isfolder) ~= "function" or not isfolder(ConfigRootPath) then
            makefolder(ConfigRootPath)
        end
        if type(isfolder) ~= "function" or not isfolder(AutoExecuteFolderPath) then
            makefolder(AutoExecuteFolderPath)
        end
    end
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
                EnsureAutoExecuteFolder()
                writefile(AutoExecutePath, AutoExecuteSource)
            end)
            if ok then
                SetAutoExecuteStatus("Created MoldyHub_Execute.lua", true)
            else
                SetAutoExecuteStatus("Create failed - " .. tostring(err):sub(1, 65), false)
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
