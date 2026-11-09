                return
            end
            local character = LocalPlayer.Character
            local characterDeadline = os.clock() + 10
            while not character and os.clock() < characterDeadline
                and not Runtime.Stopped and AutoBreakEnabled and startGeneration == AutoBreakGeneration do
                task.wait(0.1)
                character = LocalPlayer.Character
            end
            if not character or Runtime.Stopped or ScriptShuttingDown
                or not AutoBreakEnabled or startGeneration ~= AutoBreakGeneration then
                TouchAutomationProgress("IDLE")
                return
            end
            local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
            local root = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5)
            if not humanoid or not root or not AutoBreakEnabled or startGeneration ~= AutoBreakGeneration then
                TouchAutomationProgress("IDLE")
                SetTrackerStatus("Auto Break cancelled: character parts were unavailable or the toggle changed while waiting.")
                return
            end
            CurrentTarget = target
            local targetEggsFolder = target.Parent
            local targetZone = targetEggsFolder and targetEggsFolder.Parent
            if targetZone and targetZone.Parent == ZoneBuilds then
                PreferredZoneName = targetZone.Name
            end
            ArrivedAtTarget = false
            WaitingForPickup = false
            table.clear(BaselinePickups)
            if AnimalPickups then
                for _, pickup in ipairs(AnimalPickups:GetChildren()) do
                    BaselinePickups[pickup] = true
                end
            else
                SetTrackerStatus("AnimalPickups folder not created yet; waiting for it to appear.")
            end
            SetTrackerStatus("Moving to target: " .. target:GetFullName())
            local movementWaypoints = nil
            local movementWaypointIndex = 1
            local pathComputePending = false
            local lastRootPosition = root.Position
            local lastMovementProgressAt = os.clock()

            -- Compute the first route inline; avoid adding helper/async functions
            -- because this script is close to the executor's function limit.
            pcall(function()
                local path = PathfindingService:CreatePath({
                    AgentRadius = 2,
                    AgentHeight = 5,
                    AgentCanJump = true,
                    WaypointSpacing = 5
                })
                path:ComputeAsync(root.Position, target:GetPivot().Position)
                if path.Status == Enum.PathStatus.Success then
                    movementWaypoints = path:GetWaypoints()
                    movementWaypointIndex = (#movementWaypoints > 1) and 2 or 1
                end
            end)

            MovementConnection = RunService.RenderStepped:Connect(function()
                -- Animal pickup/return movement always owns the character over egg movement.
                if PickupRequested or ReturningAfterPickup then
                    if MovementConnection then
                        MovementConnection:Disconnect()
                        MovementConnection = nil
                    end
                    return
                end
                if CurrentTarget ~= target or not IsEggAvailable(target) or not character.Parent
                or humanoid.Health <= 0 then
                    if CurrentTarget == target and not IsEggAvailable(target) then
                        CompletedEggs[target] = true
                        SetTrackerStatus("Target egg is no longer available or its HP reached 0; refreshing the egg list.")
                        StopAutoBreak()
                        task.defer(function()
                            task.wait(0.2)
                            if AutoBreakEnabled and not PickupRequested and not ReturningAfterPickup then
                                StartAutoBreak()
                            end
                        end)
                    else
                        StopAutoBreak("Movement stopped: target/character unavailable.", CurrentTarget == target and IsEggAvailable(target))
                    end
                    return
                end

                local targetPosition = target:GetPivot().Position
                local targetOffset = Vector3.new(
                    targetPosition.X - root.Position.X,
                    0,
                    targetPosition.Z - root.Position.Z
                )
                if targetOffset.Magnitude <= 4 then
                    humanoid:Move(Vector3.zero, false)
                    MovementConnection:Disconnect()
                    MovementConnection = nil
                    ArrivedAtTarget = true
                    LastEggHPTarget = target
                    LastEggHPValue = nil
                    LastEggHPProgressAt = os.clock()
                    SetTrackerStatus("ARRIVED | " .. target:GetFullName()
                        .. " | tracking matching EggHitConfirmed events now.")
                    local hpWatchdogTarget = target
                    local hpWatchdogStarted = os.clock()
                    task.spawn(function()
                        while not Runtime.Stopped and AutoBreakEnabled and CurrentTarget == hpWatchdogTarget
                            and ArrivedAtTarget and not PickupRequested and not ReturningAfterPickup
                            and os.clock() - math.max(hpWatchdogStarted, LastEggHPProgressAt) < 8 do
                            task.wait(0.25)
                        end
                        if Runtime.Stopped or not AutoBreakEnabled or CurrentTarget ~= hpWatchdogTarget
                            or not ArrivedAtTarget or PickupRequested or ReturningAfterPickup then
                            return
                        end
                        if os.clock() - math.max(hpWatchdogStarted, LastEggHPProgressAt) >= 8 then
                            SetTrackerStatus("EGG HP WATCHDOG: no HP progress for 8s at " .. hpWatchdogTarget:GetFullName()
                                .. "; equipping pickaxe and restarting Auto Break.")
                            ArrivedAtTarget = false
                            if MovementConnection then MovementConnection:Disconnect(); MovementConnection = nil end
                            task.spawn(function()
                                EquipHotbarOne()
                                task.wait(0.2)
                                if AutoBreakEnabled and CurrentTarget == hpWatchdogTarget
                                    and not PickupRequested and not ReturningAfterPickup and not WaitingForPickup then
                                    StartAutoBreak(true)
                                end
                            end)
                        end
                    end)
                    return
                end

                if (root.Position - lastRootPosition).Magnitude > 0.75 then
                    lastRootPosition = root.Position
                    lastMovementProgressAt = os.clock()
                elseif os.clock() - lastMovementProgressAt > 1.75 and not pathComputePending then
                    -- Recalculate in this existing callback when an obstruction is detected.
                    pathComputePending = true
                    pcall(function()
                        local path = PathfindingService:CreatePath({
                            AgentRadius = 2,
                            AgentHeight = 5,
                            AgentCanJump = true,
                            WaypointSpacing = 5
                        })
                        path:ComputeAsync(root.Position, target:GetPivot().Position)
                        if path.Status == Enum.PathStatus.Success then
                            movementWaypoints = path:GetWaypoints()
                            movementWaypointIndex = (#movementWaypoints > 1) and 2 or 1
                        else
                            movementWaypoints = nil
                        end
                    end)
                    pathComputePending = false
                    lastMovementProgressAt = os.clock()
                end

                if not movementWaypoints or movementWaypointIndex > #movementWaypoints then
                    humanoid:Move(targetOffset.Unit, false)
                    return
                end

                local waypoint = movementWaypoints[movementWaypointIndex]
                local waypointOffset = Vector3.new(
                    waypoint.Position.X - root.Position.X,
                    0,
                    waypoint.Position.Z - root.Position.Z
                )
                if waypointOffset.Magnitude <= 3 then
                    movementWaypointIndex += 1
                    if waypoint.Action == Enum.PathWaypointAction.Jump then
                        humanoid.Jump = true
                    end
                elseif waypointOffset.Magnitude > 0.05 then
                    humanoid:Move(waypointOffset.Unit, false)
                end
            end)
        end
        -- Target selection is intentionally scan-once and lock-until-complete.
        -- Do not periodically rescan or replace a live target based on changing metadata.
        task.spawn(function()
            while not Runtime.Stopped and not ScriptShuttingDown do
                task.wait(1)
                -- Fling recovery has its own bounded approach timeouts; do not let the generic
                -- 20-second watchdog cancel a valid recovery movement phase.
                local active = not FlingRecoveryActive and (PickupRequested
                    or (not ReturningAfterPickup and AutoBreakEnabled and (CurrentTarget ~= nil or WaitingForPickup or ArrivedAtTarget
                        or AutomationProgressStage:find("^AUTO_BREAK:") ~= nil)))
                if active and not AutomationWatchdogBusy
                    and os.clock() - LastAutomationProgressAt >= 20 then
                    AutomationWatchdogBusy = true
                    AutoBreakGeneration += 1
                    SetTrackerStatus("STUCK WATCHDOG: no automation progress for 20s during "
                        .. tostring(AutomationProgressStage) .. "; clearing stale waits/locks and restarting Auto Break.")
                    if StopPickupAutomation then
                        StopPickupAutomation("20s stuck watchdog recovery")
                    end
                    if MovementConnection then MovementConnection:Disconnect(); MovementConnection = nil end
                    if PickupMovementConnection then PickupMovementConnection:Disconnect(); PickupMovementConnection = nil end
                    if ReturnMovementConnection then ReturnMovementConnection:Disconnect(); ReturnMovementConnection = nil end
                    local character = LocalPlayer.Character
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                    if humanoid then humanoid:Move(Vector3.zero, false) end
                    WaitingForPickup = false
                    ArrivedAtTarget = false
                    FlingRecoveryActive = false
                    TouchAutomationProgress("WATCHDOG_RECOVERY")
                    task.spawn(function()
                        EquipHotbarOne()
                        task.wait(0.2)
                        if AutoBreakEnabled and not ScriptShuttingDown then
                            AutomationWatchdogBusy = false
                            StartAutoBreak(true)
                        else
                            AutomationWatchdogBusy = false
                        end
                    end)
                end
            end
        end)
        RefreshEggFilters = function()
            if not AutoBreakEnabled then return end
            if CurrentTarget and IsEggAvailable(CurrentTarget) then
                AddDebugLog("[Auto Break] Filter changed; current egg remains locked until its HP reaches 0.")
                return
            end
            if FlingRecoveryActive or PickupRequested or ReturningAfterPickup or WaitingForPickup then
                AddDebugLog("[Auto Break] Filter changed; will apply after the current pickup/recovery finishes.")
                return
            end
            AddDebugLog("[Auto Break] No active target; scanning with the updated egg filters.")
            task.defer(function()
                if AutoBreakEnabled and not CurrentTarget and not FlingRecoveryActive
                    and not PickupRequested and not ReturningAfterPickup and not WaitingForPickup then
                    StartAutoBreak()
                end
            end)
        end
    elseif index == 5 then
        local ThemeCard = CreateCard(Page, "Theme Settings", "Choose a color palette for the interface.")
        local ThemeOptions = {
            "Midnight Blue + Cyan",
            "Black + Purple",
            "Dark Gray + Green",
            "Black + Electric Blue",
            "OLED Black + Amber",
            "Obsidian + Crimson",
            "Deep Ocean + Teal",
            "Graphite + Orange",
            "Dark Plum + Rose",
            "Forest Night + Lime"
        }
        local ThemeRows = {}
        local RowHeight = 34
        local ColumnGap = 8
        local ThemeRowCount = math.ceil(#ThemeOptions / 2)
        ThemeCard.Size = UDim2.new(1, 0, 0, 48 + (ThemeRowCount * RowHeight) + 8)

        for i, themeName in ipairs(ThemeOptions) do
            local palette = ThemePresets[themeName]
            local column = i > ThemeRowCount and 2 or 1
            local rowIndex = column == 1 and i or (i - ThemeRowCount)
            local rowWidth = (1 - 0.0) / 2
            local rowXScale = column == 1 and 0 or 0.5
            local Row = Create("TextButton", {
                Name = "ThemeOption_" .. tostring(i),
                Parent = ThemeCard,
                Position = UDim2.new(rowXScale, column == 1 and 10 or 4, 0, 42 + ((rowIndex - 1) * RowHeight)),
                Size = UDim2.new(0.5, column == 1 and -14 or -14, 0, 30),
                BackgroundColor3 = Theme.SurfaceInput,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                ZIndex = 2
            })
            AddCorner(Row, 5)
            AddStroke(Row, Theme.Border, 1)

            local RadioOuter = Create("Frame", {
                Parent = Row,
                Position = UDim2.fromOffset(6, 7),
                Size = UDim2.fromOffset(13, 13),
                BackgroundColor3 = Theme.SurfaceInput,
                BorderSizePixel = 0,
                ZIndex = 3
            })
            AddCorner(RadioOuter, 20)
            AddStroke(RadioOuter, Theme.Gray, 1)

            local RadioInner = Create("Frame", {
                Parent = RadioOuter,
                Position = UDim2.fromOffset(3, 3),
                Size = UDim2.fromOffset(7, 7),
                BackgroundColor3 = palette.Accent,
                BorderSizePixel = 0,
                Visible = themeName == ActiveThemeName,
                ZIndex = 4
            })
            AddCorner(RadioInner, 20)

            local Swatch = Create("Frame", {
                Parent = Row,
                Position = UDim2.fromOffset(24, 7),
                Size = UDim2.fromOffset(30, 16),
                BackgroundColor3 = palette.Background,
                BorderSizePixel = 0,
                ZIndex = 3
            })
            AddCorner(Swatch, 4)
            AddStroke(Swatch, palette.Border, 1)

            Create("Frame", {
                Parent = Swatch,
                Position = UDim2.fromOffset(3, 4),
                Size = UDim2.fromOffset(7, 8),
                BackgroundColor3 = palette.Card,
                BorderSizePixel = 0,
                ZIndex = 4
            })
            Create("Frame", {
                Parent = Swatch,
                Position = UDim2.fromOffset(12, 4),
                Size = UDim2.fromOffset(7, 8),
                BackgroundColor3 = palette.Accent,
                BorderSizePixel = 0,
                ZIndex = 4
            })
            Create("Frame", {
                Parent = Swatch,
                Position = UDim2.fromOffset(21, 4),
                Size = UDim2.fromOffset(6, 8),
                BackgroundColor3 = palette.Selected,
                BorderSizePixel = 0,
                ZIndex = 4
            })

            Create("TextLabel", {
                Parent = Row,
                Position = UDim2.fromOffset(59, 1),
                Size = UDim2.new(1, -64, 1, -2),
                BackgroundTransparency = 1,
                Text = themeName,
                TextColor3 = Theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 8,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 3
            })

            ThemeRows[#ThemeRows + 1] = {
                Name = themeName,
                Row = Row,
                RadioInner = RadioInner,
                Swatch = Swatch,
                Palette = palette
            }

            Row.MouseButton1Click:Connect(function()
                ApplyTheme(themeName)
                for _, item in ipairs(ThemeRows) do
                    item.RadioInner.Visible = item.Name == themeName
                    item.RadioInner.BackgroundColor3 = item.Palette.Accent
                    item.Swatch.BackgroundColor3 = item.Palette.Background
                    local swatchStroke = item.Swatch:FindFirstChildOfClass("UIStroke")
                    if swatchStroke then swatchStroke.Color = item.Palette.Border end
                    local swatchFrames = {}
                    for _, child in ipairs(item.Swatch:GetChildren()) do
                        if child:IsA("Frame") then
                            swatchFrames[#swatchFrames + 1] = child
                        end
                    end
                    if swatchFrames[1] then swatchFrames[1].BackgroundColor3 = item.Palette.Card end
                    if swatchFrames[2] then swatchFrames[2].BackgroundColor3 = item.Palette.Accent end
                    if swatchFrames[3] then swatchFrames[3].BackgroundColor3 = item.Palette.Selected end
                    item.Row.BackgroundColor3 = item.Name == themeName and item.Palette.Selected or Theme.SurfaceInput
                end
            end)
        end

        for _, item in ipairs(ThemeRows) do
            item.Row.BackgroundColor3 = item.Name == ActiveThemeName and Theme.Selected or Theme.SurfaceInput
        end

    elseif index == 6 then
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

        local ConfigSaveCard = CreateCard(Page, "Config Save", "Save toggle states and interface preferences.")
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
                Toggles = {}
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

        local AutoExecuteCard = CreateCard(Page, "Auto Execute", "Manage the auto-execute entry.")
        AutoExecuteCard.Size = UDim2.new(1, 0, 0, 112)
        local AutoExecuteLoadButton = CreateButton(AutoExecuteCard, "Load Auto Execute", nil)
        AutoExecuteLoadButton.Position = UDim2.fromOffset(11, 43)
        AutoExecuteLoadButton.Size = UDim2.new(1, -22, 0, 27)
        local AutoExecuteUnloadButton = CreateButton(AutoExecuteCard, "Unload Auto Execute", nil)
        AutoExecuteUnloadButton.Position = UDim2.fromOffset(11, 76)
        AutoExecuteUnloadButton.Size = UDim2.new(1, -22, 0, 27)

    elseif index == 3 then
        local CandyCard = CreateCard(Page, "Auto collect candies", "UNDER DEVELOPMENT")
        CandyCard.Size = UDim2.new(1, 0, 0, 110)
        local CandyInfo = Create("TextLabel", {
            Parent = CandyCard,
            Position = UDim2.fromOffset(12, 42),
            Size = UDim2.new(1, -24, 0, 38),
            BackgroundTransparency = 1,
            Text = "UNDER DEVELOPMENT — Auto candy collection is disabled in Deploy.",
            TextColor3 = Theme.Gray,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top
        })
        MarkUnderDevelopment(CandyCard)

    elseif index == 4 then
        local ESPCardsRow = Create("Frame", {
            Name = "ESPFeatureCardsRow",
            Parent = Page,
            Position = UDim2.fromOffset(10, 10),
            Size = UDim2.new(1, -20, 0, 100),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = 0
        })
        local ESPCard = CreateCard(ESPCardsRow, "Egg ESP", "Displays egg stats.")
        ESPCard.Position = UDim2.new(0, 0, 0, 0)
        ESPCard.Size = UDim2.new(0.5, -5, 0, 100)
        ESPCard.LayoutOrder = 1
        local ESPStatus = Create("TextLabel", {
            Parent = ESPCard,
            Position = UDim2.fromOffset(11, 61),
            Size = UDim2.new(1, -22, 0, 16),
            BackgroundTransparency = 1,
            Text = "ESP is off",
            TextColor3 = Theme.Gray,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top
        })
        local ESPEnabled = false
        local ESPObjects = {}
        local ESPFolder = Create("Folder", {Name = "MoldyHub_BASAE_EggESP", Parent = LocalPlayer:WaitForChild("PlayerGui")})
        local function ClearEggESP(egg)
            local gui = ESPObjects[egg]
            if gui then
                gui:Destroy()
                ESPObjects[egg] = nil
            end
        end
        local function GetESPValue(object, names)
            if not object then return nil end
            local nodes = {object}
            for _, descendant in ipairs(object:GetDescendants()) do
                table.insert(nodes, descendant)
            end
            for _, name in ipairs(names) do
                for _, node in ipairs(nodes) do
                    local value = node:GetAttribute(name)
                    if value ~= nil then return tostring(value) end
                    if node.Name == name then
                        if node:IsA("ValueBase") then return tostring(node.Value) end
                        if (node:IsA("TextLabel") or node:IsA("TextButton") or node:IsA("TextBox")) and node.Text ~= "" then
                            return node.Text
                        end
                    end
                end
            end
            return nil
        end
        local function GetEggESPInfo(egg)
            local eggModel = egg:FindFirstChild("Egg") or egg
            local info = eggModel:FindFirstChild("EggInfoUi", true)
            local luck = GetESPValue(eggModel, {"LuckMulti", "Luck", "LuckMultiplier"})
                or GetESPValue(info, {"LuckMulti", "Luck", "LuckMultiplier"})
            if not luck and info then
                local luckList = info:FindFirstChild("LuckMultiList", true)
                local luckLabel = luckList and luckList:FindFirstChild("LuckMulti", true)
                if luckLabel and (luckLabel:IsA("TextLabel") or luckLabel:IsA("TextButton")) then
                    luck = luckLabel.Text
                end
            end
            local weightKG = GetESPValue(eggModel, {"WeightKg"})
                or GetESPValue(info, {"WeightKg"})
            local category = GetESPValue(eggModel, {"WeightBracket"})
                or GetESPValue(info, {"WeightBracket"})
            return luck or "?", weightKG or "?", category or "?"
        end
        local function UpdateEggESP()
            local build = workspace:FindFirstChild("Build")
            local zones = build and build:FindFirstChild("ZoneBuilds")
            if not zones then
                ESPStatus.Text = "Waiting for egg zones..."
                return
            end
            local seen = {}
            local count = 0
            for _, zone in ipairs(zones:GetChildren()) do
                local eggsFolder = zone:FindFirstChild("Eggs")
                if eggsFolder then
                    for _, egg in ipairs(eggsFolder:GetChildren()) do
                        if (egg:IsA("Model") or egg:IsA("BasePart")) and egg.Name:lower():find("egg", 1, true) then
                            local adornee = egg:IsA("BasePart") and egg or egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart", true)
                            if adornee then
                                seen[egg] = true
                                count += 1
                                local gui = ESPObjects[egg]
                                if not gui or not gui.Parent then
                                    gui = Instance.new("BillboardGui")
                                    gui.Name = "EggESP"
                                    gui.Adornee = adornee
                                    gui.Size = UDim2.fromOffset(180, 44)
                                    gui.StudsOffset = Vector3.new(0, 3, 0)
                                    gui.AlwaysOnTop = true
                                    gui.MaxDistance = 250
                                    gui.Parent = ESPFolder
                                    local label = Instance.new("TextLabel")
                                    label.Name = "Info"
                                    label.Size = UDim2.fromScale(1, 1)
                                    label.BackgroundTransparency = 1
                                    label.BackgroundTransparency = 1
                                    label.BorderSizePixel = 0
                                    label.TextColor3 = Color3.fromRGB(255, 255, 255)
                                    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                                    label.TextStrokeTransparency = 0.25
                                    label.Font = Enum.Font.GothamBold
                                    label.TextSize = 11
                                    label.TextWrapped = true
                                    label.Parent = gui
                                    ESPObjects[egg] = gui
                                end
                                gui.Adornee = adornee
                                local luck, weightKG, category = GetEggESPInfo(egg)
                                gui.Size = UDim2.fromOffset(205, 58)
                                gui.Info.Text = egg.Name .. "\nLuck: " .. luck .. " | KG: " .. weightKG .. "\nCategory: " .. category
                            end
                        end
                    end
                end
            end
            for egg in pairs(ESPObjects) do
                if not seen[egg] or not egg.Parent then
                    ClearEggESP(egg)
                end
            end
            ESPStatus.Text = "ESP " .. (ESPEnabled and "ON" or "OFF") .. " | Eggs: " .. count
        end
        CreateToggle(ESPCard, "", false, function(enabled)
            ESPEnabled = enabled
            if enabled then
                ESPStatus.Text = "Scanning eggs..."
                task.spawn(function()
                    while not Runtime.Stopped and ESPEnabled and not ScriptShuttingDown do
                        UpdateEggESP()
                        task.wait(0.75)
                    end
                end)
            else
                for egg in pairs(ESPObjects) do
                    ClearEggESP(egg)
                end
                ESPStatus.Text = "ESP is off"
            end
        end)
        local ESPToggle = ESPCard:FindFirstChildWhichIsA("TextButton")
        if ESPToggle then
            ESPToggle.Position = UDim2.new(1, -61, 0, 5)
            ESPToggle.Size = UDim2.fromOffset(48, 24)
        end
        local ESPTitle = ESPCard:FindFirstChildWhichIsA("TextLabel")
        if ESPTitle then ESPTitle.Size = UDim2.new(1, -78, 0, 22) end
        ESPCard.Size = UDim2.new(0.5, -5, 0, 100)

        local BackpackESPCard = CreateCard(ESPCardsRow, "Backpack ESP", "Shows larger $/s and KG on inventory cards.")
        BackpackESPCard.Position = UDim2.new(0.5, 5, 0, 0)
        BackpackESPCard.Size = UDim2.new(0.5, -5, 0, 100)
        BackpackESPCard.LayoutOrder = 2
        local BackpackESPStatus = Create("TextLabel", {
            Parent = BackpackESPCard,
            Position = UDim2.fromOffset(11, 61),
            Size = UDim2.new(1, -22, 0, 22),
            BackgroundTransparency = 1,
            Text = "ESP is off",
            TextColor3 = Theme.Gray,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top
        })
        local BackpackESPEnabled = false
        local BackpackESPObjects = {}
        local BackpackESPConnections = {}
        local BackpackESPFolder = Create("Folder", {
            Name = "MoldyHub_BASAE_BackpackESP",
            Parent = LocalPlayer:WaitForChild("PlayerGui")
        })
        local BackpackESPRefs = {}
        local function ClearBackpackESP(card)
            local overlay = BackpackESPObjects[card]
            if overlay then
                overlay:Destroy()
                BackpackESPObjects[card] = nil
            end
            local overlayRef = BackpackESPRefs[card]
            if overlayRef then
                overlayRef:Destroy()
                BackpackESPRefs[card] = nil
            end
        end
        local function GetBackpackESPInfo(tool)
            local model = tool:FindFirstChild("AnimalModel")
            local root = model and model:FindFirstChild("RootPart")
            local attachment = root and root:FindFirstChild("AnimalOverheadAttachment")
            local overhead = attachment and attachment:FindFirstChild("AnimalOverhead")
            local cashFolder = overhead and overhead:FindFirstChild("CashPerSecond")
            local cashLabel = cashFolder and cashFolder:FindFirstChild("CashPerSecond")
            if not cashLabel then return "" end
            if cashLabel:IsA("TextLabel") or cashLabel:IsA("TextButton") or cashLabel:IsA("TextBox") then
                return cashLabel.Text
            elseif cashLabel:IsA("ValueBase") then
                return tostring(cashLabel.Value)
            end
            return ""
        end
        local function NormalizeAnimalName(value)
            value = tostring(value or ""):lower()
            value = value:gsub("%s*%b()%s*$", "")
            value = value:gsub("%s+", " ")
            return value:match("^%s*(.-)%s*$")
        end
        local function GetAnimalComparisonKey(value)
            return NormalizeAnimalName(value):gsub("[^%a%d]", "")
        end
        local function ParseAnimalWeight(value)
            if value == nil then return nil end
            local cleaned = tostring(value):gsub(",", "")
            cleaned = cleaned:gsub("%s*[Kk][Gg]%s*$", "")
            cleaned = cleaned:match("^%s*(.-)%s*$")
            return tonumber(cleaned)
        end
        local function NormalizeAnimalWeight(value)
            local weight = ParseAnimalWeight(value)
            if not weight then return nil end
            return math.floor(weight + 0.5)
        end
        local function AnimalWeightMatches(actualValue, displayedValue)
            local actualWeight = ParseAnimalWeight(actualValue)
            local displayedWeight = ParseAnimalWeight(displayedValue)
            if not actualWeight or not displayedWeight then return false end

            local lowerWeight = math.floor(actualWeight)
            local fraction = actualWeight - lowerWeight
            if math.abs(fraction - 0.5) < 0.000001 then
                return displayedWeight == lowerWeight or displayedWeight == lowerWeight + 1
            end
            return displayedWeight == math.floor(actualWeight + 0.5)
        end
        local function GetInventoryCardInfo(card)
            local container = card:FindFirstChild("Container")
            local infoList = container and container:FindFirstChild("InfoList")
            local nameLabel = infoList and infoList:FindFirstChild("Name")
            if not nameLabel or not (nameLabel:IsA("TextLabel") or nameLabel:IsA("TextButton") or nameLabel:IsA("TextBox")) then
                return nil
            end
            local text = tostring(nameLabel.Text or "")
            local animalName, weightText = text:match("^%s*(.-)%s*%(([%d,%.]+)%s*[Kk][Gg]%)%s*$")
            if not animalName or not weightText then return nil end
            local weight = ParseAnimalWeight(weightText)
            if not weight then return nil end
            animalName = NormalizeAnimalName(animalName)
            if animalName == "" then return nil end
            return animalName, weightText, container, weight
        end
        local function FindInventoryCards()
            local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            local mobile = playerGui and playerGui:FindFirstChild("MobileScatchel")
            local hotbar = mobile and mobile:FindFirstChild("HotBarUi")
            local inventory = hotbar and hotbar:FindFirstChild("Inventory")
            local scrolling = inventory and inventory:FindFirstChild("ScrollingFrame")
            if not scrolling then return {} end

            local cards = {}
            for _, descendant in ipairs(scrolling:GetDescendants()) do
                if descendant:FindFirstChild("Container") then
                    local container = descendant:FindFirstChild("Container")
                    local infoList = container and container:FindFirstChild("InfoList")
                    local nameLabel = infoList and infoList:FindFirstChild("Name")
                    if nameLabel and (nameLabel:IsA("TextLabel") or nameLabel:IsA("TextButton") or nameLabel:IsA("TextBox")) then
                        table.insert(cards, descendant)
                    end
                end
            end
            return cards
        end
        local function UpdateBackpackESP()
            local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
            if not backpack then
                BackpackESPStatus.Text = "Waiting for backpack..."
                return
            end

            local animals = {}
            local totalTools = 0
            for _, tool in ipairs(backpack:GetChildren()) do
                if tool:IsA("Tool") then
                    local animalName = tool:GetAttribute("AnimalName")
                    local weight = ParseAnimalWeight(tool:GetAttribute("WeightKg"))
                    if typeof(animalName) == "string" and animalName ~= "" and weight then
                        totalTools += 1
                        table.insert(animals, {
                            Tool = tool,
                            Key = GetAnimalComparisonKey(animalName),
                            Weight = weight,
                            CPS = GetBackpackESPInfo(tool),
                        })
                    end
                end
            end

            local inventoryCards = FindInventoryCards()
            local parsedCards = 0
            local seen = {}
            local count = 0
            for _, card in ipairs(inventoryCards) do
                local animalName, weightText, container, cardWeight = GetInventoryCardInfo(card)
                if animalName and container then
                    parsedCards += 1
                    local cardKey = GetAnimalComparisonKey(animalName)
                    local match
                    for _, animal in ipairs(animals) do
                        if animal.Key == cardKey
                            and AnimalWeightMatches(animal.Weight, cardWeight) then
                            match = animal
                            break
                        end
                    end

                    if match then
                        seen[card] = true
                        count += 1
                        local overlay = BackpackESPObjects[card]
                        if not overlay or not overlay.Parent then
                            overlay = Instance.new("Frame")
                            overlay.Name = "MoldyHub_BASAE_InventoryStatsOverlay"
                            overlay.BackgroundTransparency = 1
                            overlay.BorderSizePixel = 0
                            overlay.AnchorPoint = Vector2.new(0, 1)
                            overlay.Position = UDim2.new(0, 0, 1, -4)
                            overlay.Size = UDim2.new(1, 0, 0, 22)
                            overlay.ZIndex = 20
                            overlay.Parent = container
                            local overlayRef = Instance.new("ObjectValue")
                            overlayRef.Name = "InventoryOverlay"
                            overlayRef.Value = overlay
                            overlayRef.Parent = BackpackESPFolder
                            BackpackESPRefs[card] = overlayRef

                            local cashText = Instance.new("TextLabel")
                            cashText.Name = "CashPerSecond"
                            cashText.BackgroundTransparency = 1
                            cashText.BorderSizePixel = 0
                            cashText.Position = UDim2.new(0, 1, 0, 0)
                            cashText.Size = UDim2.new(1, -2, 0, 12)
                            cashText.Font = Enum.Font.GothamBold
                            cashText.TextSize = 9
                            cashText.TextColor3 = Color3.fromRGB(99, 255, 145)
                            cashText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                            cashText.TextStrokeTransparency = 0.35
                            cashText.TextXAlignment = Enum.TextXAlignment.Center
                            cashText.TextTruncate = Enum.TextTruncate.AtEnd
                            cashText.ZIndex = 21
                            cashText.Parent = overlay

                            local weightLabel = Instance.new("TextLabel")
                            weightLabel.Name = "Weight"
                            weightLabel.BackgroundTransparency = 1
                            weightLabel.BorderSizePixel = 0
                            weightLabel.Position = UDim2.new(0, 1, 0, 11)
                            weightLabel.Size = UDim2.new(1, -2, 0, 10)
                            weightLabel.Font = Enum.Font.GothamBold
                            weightLabel.TextSize = 8
                            weightLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                            weightLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                            weightLabel.TextStrokeTransparency = 0.35
                            weightLabel.TextXAlignment = Enum.TextXAlignment.Center
                            weightLabel.TextTruncate = Enum.TextTruncate.AtEnd
                            weightLabel.ZIndex = 21
                            weightLabel.Parent = overlay
                            BackpackESPObjects[card] = overlay
                        end

                        overlay.CashPerSecond.Text = match.CPS ~= "" and tostring(match.CPS):gsub("[%$]", "") or "—"
                        overlay.Weight.Text = weightText:gsub(",", ""):gsub("%s*[Kk][Gg]%s*$", "") .. "kg"
                    end
                end
            end

            for card in pairs(BackpackESPObjects) do
                if not seen[card] or not card.Parent then
                    ClearBackpackESP(card)
                end
            end
            BackpackESPStatus.Text = "ESP " .. (BackpackESPEnabled and "ON" or "OFF") .. " | Matched: " .. count
        end
        CreateToggle(BackpackESPCard, "", false, function(enabled)
            BackpackESPEnabled = enabled
            if enabled then
                BackpackESPStatus.Text = "Matching inventory cards..."
                task.spawn(function()
                    while not Runtime.Stopped and BackpackESPEnabled and not ScriptShuttingDown do
                        pcall(UpdateBackpackESP)
                        task.wait(0.75)
                    end
                end)
            else
                for card in pairs(BackpackESPObjects) do
                    ClearBackpackESP(card)
                end
                for card in pairs(BackpackESPRefs) do
                    ClearBackpackESP(card)
                end
                BackpackESPStatus.Text = "ESP is off"
            end
        end)
        local BackpackESPToggle = BackpackESPCard:FindFirstChildWhichIsA("TextButton")
        if BackpackESPToggle then
            BackpackESPToggle.Position = UDim2.new(1, -61, 0, 5)
            BackpackESPToggle.Size = UDim2.fromOffset(48, 24)
        end
        local BackpackESPTitle = BackpackESPCard:FindFirstChildWhichIsA("TextLabel")
        if BackpackESPTitle then BackpackESPTitle.Size = UDim2.new(1, -78, 0, 22) end

        local MiscFeatureRow = Create("Frame", {
            Name = "MiscFeatureCardsRow",
            Parent = Page,
            Position = UDim2.fromOffset(10, 120),
            Size = UDim2.new(1, -20, 0, 110),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = 1
        })
        local AntiPaloCard = CreateCard(MiscFeatureRow, "️  Anti Knockback", "Prevents knockback and fling.")
        AntiPaloCard.Position = UDim2.new(0, 0, 0, 0)
        AntiPaloCard.Size = UDim2.new(0.5, -5, 0, 100)
        AntiPaloCard.LayoutOrder = 1
        local AntiPaloBusy = false
        local AntiPaloStatus = Create("TextLabel", {
            Parent = AntiPaloCard,
            Position = UDim2.fromOffset(11, 62),
            Size = UDim2.new(1, -22, 0, 14),
            BackgroundTransparency = 1,
            Text = "Status: OFF",
            TextColor3 = Theme.Gray,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        local AntiPaloToggle
        AntiPaloToggle = CreateToggle(AntiPaloCard, "", false, function(enabled)
            if AntiPaloBusy then
                local controller = ToggleControllers[AntiPaloToggle]
                if controller then controller.SetEnabled(AntiPaloEnabled, false) end
                return
            end
            AntiPaloBusy = true
            AntiPaloEnabled = enabled
            AntiPaloStatus.Text = enabled and "Status: ON • Fling Release" or "Status: OFF"
            AntiPaloStatus.TextColor3 = enabled and Theme.Accent or Theme.Gray
            AddDebugLog("[Anti Knockback] Fling release " .. (enabled and "enabled" or "disabled") .. ".")
            task.delay(0.25, function()
                AntiPaloBusy = false
            end)
        end)
        AntiPaloToggle.Position = UDim2.new(1, -58, 0, 7)
        AntiPaloToggle.Size = UDim2.fromOffset(48, 24)

        local AuraCard = CreateCard(MiscFeatureRow, "️  Auto Boink", "Boink any enemy nearby.")
        AuraCard.Position = UDim2.new(0.5, 5, 0, 0)
        AuraCard.Size = UDim2.new(0.5, -5, 0, 100)
        AuraCard.LayoutOrder = 2
        local AuraStatus = Create("TextLabel", {
            Parent = AuraCard,
            Position = UDim2.fromOffset(11, 60),
            Size = UDim2.new(1, -22, 0, 27),
            BackgroundTransparency = 1,
            Text = "Status: OFF",
            TextColor3 = Theme.Gray,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top
        })
        local AuraEnabled = false
        local AuraWasNearby = false
        local function GetNearbyPlayers()
            local nearby = {}
            local myCharacter = LocalPlayer.Character
            local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
            if not myRoot then
                return nearby, "Waiting for your character..."
            end
            for _, targetPlayer in ipairs(Players:GetPlayers()) do
                if targetPlayer ~= LocalPlayer then
                    local character = workspace:FindFirstChild(targetPlayer.Name)
                    local root = character and character:FindFirstChild("HumanoidRootPart")
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                    if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
                        local distance = (root.Position - myRoot.Position).Magnitude
                        if distance <= 20 then
                            table.insert(nearby, {Name = targetPlayer.Name, Distance = distance})
                        end
                    end
                end
            end
            table.sort(nearby, function(a, b)
                return a.Distance < b.Distance
            end)
            if #nearby == 0 then
                return nearby, "No players within 20 studs"
            end
            local names = {}
            for i = 1, math.min(#nearby, 2) do
                table.insert(names, nearby[i].Name .. " (" .. string.format("%.1f", nearby[i].Distance) .. ")")
            end
            if #nearby > 2 then
                table.insert(names, "+" .. tostring(#nearby - 2) .. " more")
            end
            return nearby, "Nearby: " .. table.concat(names, ", ")
        end
        local function SelectAuraHotbarSlot(slot)
            local key = slot == 1 and Enum.KeyCode.One or slot == 2 and Enum.KeyCode.Two
            if not key then
                return false, "Unsupported hotbar slot: " .. tostring(slot)
            end
            local ok, err = pcall(function()
                local virtualInput = game:GetService("VirtualInputManager")
                virtualInput:SendKeyEvent(true, key, false, game)
                task.wait(0.05)
                virtualInput:SendKeyEvent(false, key, false, game)
            end)
            if not ok then
                return false, tostring(err)
            end
            return true
        end
        local function RunAuraNiBai(targetName)
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then
                AddDebugLog("[Auto Boink] Cannot boink: character or humanoid is unavailable.")
                return
            end
            local remote = game:GetService("ReplicatedStorage"):FindFirstChild("BatHitRequest", true)
            if not remote or not remote:IsA("RemoteEvent") then
                AddDebugLog("[Auto Boink] BatHitRequest RemoteEvent not found.")
                return
            end
            local selectedTwo, selectTwoError = SelectAuraHotbarSlot(2)
            if selectedTwo then
                AddDebugLog("[Auto Boink] Selected hotbar slot 2.")
                task.wait(0.15)
            else
                AddDebugLog("[Auto Boink] Could not select hotbar slot 2: " .. tostring(selectTwoError))
            end
            local fired, fireError = pcall(function()
                remote:FireServer(game:GetService("Players"):FindFirstChild(targetName))
            end)
            if fired then
                AddDebugLog("[Auto Boink] BatHitRequest:FireServer() called for " .. targetName .. ".")
            else
                AddDebugLog("[Auto Boink] BatHitRequest call failed: " .. tostring(fireError))
            end
            task.wait(0.15)
            if LocalPlayer.Character == character then
                local selectedOne, selectOneError = SelectAuraHotbarSlot(1)
                if selectedOne then
                    AddDebugLog("[Auto Boink] Returned to hotbar slot 1.")
                else
                    AddDebugLog("[Auto Boink] Could not return to hotbar slot 1: " .. tostring(selectOneError))
                end
            end
        end
        local AuraActionRunning = false
        local AuraPendingTarget = nil
        local function QueueAuraAction(targetName)
            if not targetName or not AuraEnabled or Runtime.Stopped then return end
            if AuraActionRunning then
                AuraPendingTarget = targetName
                return
            end
            AuraActionRunning = true
            task.spawn(function()
                local nextTarget = targetName
                while nextTarget and AuraEnabled and not Runtime.Stopped do
                    local ok, err = xpcall(function()
                        RunAuraNiBai(nextTarget)
                    end, debug.traceback)
                    if not ok then
                        AddDebugLog("[Auto Boink] Action failed: " .. tostring(err):gsub("[%r\\n]+", " "):sub(1, 180))
                    end
                    nextTarget = AuraEnabled and AuraPendingTarget or nil
                    AuraPendingTarget = nil
                end
                AuraActionRunning = false
                if AuraEnabled and AuraPendingTarget and not Runtime.Stopped then
                    local pending = AuraPendingTarget
                    AuraPendingTarget = nil
                    QueueAuraAction(pending)
                end
            end)
        end
        local AuraToggle = CreateToggle(AuraCard, "", false, function(enabled)
            AuraEnabled = enabled
            if not enabled then
                AuraWasNearby = false
                AuraPendingTarget = nil
                AuraStatus.Text = "Status: OFF"
                AuraStatus.TextColor3 = Theme.Gray
                AddDebugLog("[Auto Boink] Proximity tracking disabled.")
                return
            end
            AuraStatus.Text = "Tracking players within 20 studs..."
            AuraStatus.TextColor3 = Theme.Accent
            AddDebugLog("[Auto Boink] Proximity tracking enabled (20 studs).")
            task.spawn(function()
                while AuraEnabled and not Runtime.Stopped and ScreenGui.Parent do
                    local nearby, nearbyText = GetNearbyPlayers()
                    if #nearby > 0 then
                        AuraStatus.Text = nearbyText
                        AuraStatus.TextColor3 = Theme.Accent
                        if not AuraWasNearby then
                            AddDebugLog("[Auto Boink] Detected " .. nearby[1].Name .. " within 20 studs (" .. string.format("%.1f", nearby[1].Distance) .. " studs).")
                            QueueAuraAction(nearby[1].Name)
                        end
                        AuraWasNearby = true
                    else
                        AuraWasNearby = false
                        AuraStatus.Text = nearbyText
                        AuraStatus.TextColor3 = Theme.Accent
                    end
                    task.wait(0.25)
                end
            end)
        end)
        AuraToggle.Position = UDim2.new(1, -58, 0, 7)
        AuraToggle.Size = UDim2.fromOffset(48, 24)

    else
        local Card1 = CreateCard(Page, name, "This is a reusable UI page. Backend code is not connected.")
        CreateButton(Card1, "Example Button", function()
            -- Put your actual function here.
        end)
        local Card2 = CreateCard(Page, "Example Settings", "Example controls that only change the UI state.")
        CreateToggle(Card2, "Example Toggle", false, function(state)
            -- state = true / false
        end)
        local Card3 = CreateCard(Page, "️  Example Options", "Dropdown and slider examples.")
        CreateDropdown(Card3, "Mode", {"Option 1", "Option 2", "Option 3"}, function(selection)
            -- selection contains the selected option.
        end)
        CreateSlider(Card3, "Example Slider", 0, 100, 50, function(value)
            -- value contains the current slider value.
        end)
    end
end
-- SHOW FIRST PAGE
Pages[1].Visible = true
SidebarButtons[1].TextColor3 = Theme.Text
-- FLOATING TOGGLE
-- The circle is independent from the main window and remains visible at all times.
local FloatingToggle = Create("TextButton", {
    Name = "FloatingToggle",
    Parent = ScreenGui,
    Position = UDim2.new(1, -52, 0, 16),
    Size = UDim2.fromOffset(36, 36),
    BackgroundColor3 = Theme.Sidebar,
    Text = "B",
    TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    BorderSizePixel = 0,
    AutoButtonColor = true,
    Active = true,
    ZIndex = 100
})
AddCorner(FloatingToggle, 18)
AddStroke(FloatingToggle, Theme.Border, 1)

local function GetFloatingToggleBounds()
    local camera = workspace.CurrentCamera
    if not camera then
        return 0, 0
    end
    local viewport = camera.ViewportSize
    local buttonSize = FloatingToggle.AbsoluteSize
    return math.max(0, viewport.X - buttonSize.X), math.max(0, viewport.Y - buttonSize.Y)
end

local function ClampFloatingTogglePosition(x, y)
    local maxX, maxY = GetFloatingToggleBounds()
    return math.clamp(x, 0, maxX), math.clamp(y, 0, maxY)
end

local function PositionFloatingToggleUpperRight()
    local maxX = GetFloatingToggleBounds()
    FloatingToggle.Position = UDim2.fromOffset(math.max(0, maxX - 16), 16)
end

PositionFloatingToggleUpperRight()

local function KeepFloatingToggleOnScreen()
    local clampedX, clampedY = ClampFloatingTogglePosition(
        FloatingToggle.AbsolutePosition.X,
        FloatingToggle.AbsolutePosition.Y
    )
    FloatingToggle.Position = UDim2.fromOffset(clampedX, clampedY)
end

local function WatchViewportSize(camera)
    if not camera then return end
    TrackPersistentConnection(camera:GetPropertyChangedSignal("ViewportSize"):Connect(KeepFloatingToggleOnScreen))
end

WatchViewportSize(workspace.CurrentCamera)
TrackPersistentConnection(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    WatchViewportSize(workspace.CurrentCamera)
    KeepFloatingToggleOnScreen()
end))

local function CenterMainWindow()
    local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
    if not viewport then return end
    Main.Position = UDim2.fromOffset(
        math.max(0, (viewport.X - UIConfig.Width * UIScale.Scale) / 2),
        math.max(0, (viewport.Y - UIConfig.Height * UIScale.Scale) / 2)
    )
end

local function ToggleMainWindow()
    if Main.Visible then
        Main.Visible = false
    else
        -- Reopen at the last position; only the first launch uses the centered default.
        Main.Visible = true
    end
end

-- CLOSE hides the window only. The floating toggle remains available.
CloseButton.MouseButton1Click:Connect(function()
    Main.Visible = false
end)

-- WINDOW DRAGGING
local WindowDragging = false
local WindowDragStart
local WindowStartPosition
local WindowStartAbsolutePosition

-- No edge clamp: the main window can be dragged over Roblox's
-- top bar, chat, menu, and every other CoreGui area.
local function ClampMainWindowPosition(x, y)
    return x, y
end

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        WindowDragging = true
        WindowDragStart = input.Position
        WindowStartPosition = Main.Position
        local absolutePosition = Main.AbsolutePosition
        WindowStartAbsolutePosition = Vector2.new(absolutePosition.X, absolutePosition.Y)
    end
end)

local CircleDragging = false
local CircleDragInput
local CircleDragStart
local CircleStartAbsolutePosition
local CircleMoved = false
local CircleDragThreshold = 6

FloatingToggle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        CircleDragging = true
        CircleDragInput = input
        CircleDragStart = input.Position
        CircleStartAbsolutePosition = FloatingToggle.AbsolutePosition
        CircleMoved = false
    end
end)

TrackPersistentConnection(UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or (CircleDragInput and input == CircleDragInput) then
        if CircleDragging then
            local delta = input.Position - CircleDragStart
            if delta.Magnitude > CircleDragThreshold then
                CircleMoved = true
            end
            if CircleMoved then
                local targetX = CircleStartAbsolutePosition.X + delta.X
                local targetY = CircleStartAbsolutePosition.Y + delta.Y
                local clampedX, clampedY = ClampFloatingTogglePosition(targetX, targetY)
                FloatingToggle.Position = UDim2.fromOffset(clampedX, clampedY)
            end
        end
    end

    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        if WindowDragging then
            -- Apply only this movement step. At a screen edge the window stops,
            -- and the drag origin follows the pointer so reversing direction
            -- moves the window immediately without snapping or bouncing.
            local delta = input.Position - WindowDragStart
            local targetX = WindowStartAbsolutePosition.X + delta.X
            local targetY = WindowStartAbsolutePosition.Y + delta.Y
            -- No edge clamp: let the window travel freely over all Roblox UI.
            -- Preserve the original scale components to avoid a first-drag jump.
            Main.Position = UDim2.new(
                WindowStartPosition.X.Scale,
                WindowStartPosition.X.Offset + delta.X,
                WindowStartPosition.Y.Scale,
                WindowStartPosition.Y.Offset + delta.Y
            )
        end
    end
end))

TrackPersistentConnection(UserInputService.InputEnded:Connect(function(input)
    if CircleDragging and (
        input.UserInputType == Enum.UserInputType.MouseButton1
        or input == CircleDragInput
    ) then
        local wasDragged = CircleMoved
        CircleDragging = false
        CircleDragInput = nil
        CircleMoved = false
        if not wasDragged then
            ToggleMainWindow()
        end
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        WindowDragging = false
    end
end))
