        function GetKnownEggHealth(egg)
            if not egg then return nil end
            for _, healthName in ipairs({"Health", "CurrentHealth", "EggHealth", "HP"}) do
                local health = tonumber(GetEggDataValue(egg, healthName))
                if health ~= nil then return health end
            end
            return nil
        end
        function IsEggConfirmedComplete(egg)
            if not egg then return false end
            if not egg.Parent or CompletedEggs[egg] then return true end
            local health = GetKnownEggHealth(egg)
            if health ~= nil then return health <= 0 end
            if LastEggHPTarget == egg then
                local eventHealth = tonumber(LastEggHPValue)
                if eventHealth ~= nil then return eventHealth <= 0 end
            end
            return false
        end
        function IsEggAvailable(egg)
            if not egg or not egg.Parent or CompletedEggs[egg] then return false end
            local eggsFolder = egg.Parent
            if eggsFolder.Name ~= "Eggs" then return false end
            local zone = eggsFolder.Parent
            if not zone or zone.Parent ~= ZoneBuilds then return false end
            if not (egg:IsA("Model") or egg:IsA("BasePart")) then return false end
            if not egg.Name:lower():find("egg", 1, true) then return false end
            for _, healthName in ipairs({"Health", "CurrentHealth", "EggHealth", "HP"}) do
                local rawHealth = GetEggDataValue(egg, healthName)
                local health = tonumber(rawHealth)
                if health and health <= 0 then
                    return false
                end
            end
            return true
        end

        -- Read metadata from the same Egg/EggInfoUi sources used by EggESP.
        -- EggESP uses WeightBracket for the displayed category.
        function GetEggESPValue(object, names)
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

        function GetEggESPMetadata(egg)
            if not egg then return nil, nil, nil end
            -- Match GetEggESPInfo: use the direct child named "Egg", otherwise the outer egg.
            local eggModel = egg:FindFirstChild("Egg") or egg
            local info = eggModel:FindFirstChild("EggInfoUi", true)

            local luck = GetEggESPValue(eggModel, {"LuckMulti", "Luck", "LuckMultiplier"})
                or GetEggESPValue(info, {"LuckMulti", "Luck", "LuckMultiplier"})
            if not luck and info then
                local luckList = info:FindFirstChild("LuckMultiList", true)
                local luckLabel = luckList and luckList:FindFirstChild("LuckMulti", true)
                if luckLabel and (luckLabel:IsA("TextLabel") or luckLabel:IsA("TextButton")) then
                    luck = luckLabel.Text
                end
            end

            local weightKG = GetEggESPValue(eggModel, {"WeightKg"})
                or GetEggESPValue(info, {"WeightKg"})
            local category = GetEggESPValue(eggModel, {"WeightBracket"})
                or GetEggESPValue(info, {"WeightBracket"})

            return luck, weightKG, category
        end

        -- Keep Auto Break weight parsing aligned with the EggESP source paths.
        function GetEggWeightKg(egg)
            local _, rawWeight = GetEggESPMetadata(egg)
            if rawWeight == nil or tostring(rawWeight):match("%S") == nil then return nil end
            return tonumber(tostring(rawWeight):lower():gsub(",", ""):match("[%d%.]+"))
        end

        function GetEggCategory(egg)
            local _, _, category = GetEggESPMetadata(egg)
            if category == nil or tostring(category):match("%S") == nil then return nil end
            return tostring(category):match("^%s*(.-)%s*$")
        end

        function GetEggLuck(egg)
            local rawLuck = GetEggESPMetadata(egg)
            if rawLuck == nil or tostring(rawLuck):match("%S") == nil then return 0 end

            -- Supports displayed values such as x90Qa, x10T, x500.2B and x3.49Qa Luck.
            -- Remove the UI label before parsing so "Luck" is never mistaken for a numeric suffix.
            local text = tostring(rawLuck)
                :lower()
                :gsub("%s*luck%s*", "")
                :gsub("^%s*[x×]%s*", "")
                :gsub(",", "")
                :gsub("%s+", "")

            local suffixScale = {
                k = 1e3, m = 1e6, b = 1e9, t = 1e12,
                qa = 1e15, qd = 1e15, qi = 1e18,
                sx = 1e21, sp = 1e24, oc = 1e27, no = 1e30,
                dc = 1e33, ud = 1e36, dd = 1e39, td = 1e42,
                qag = 1e45, qig = 1e48, sxg = 1e51, spg = 1e54,
                og = 1e57, ng = 1e60
            }

            local function parseLuckNumber(token)
                if not token then return nil end
                token = token:lower():gsub("^[x×]", "")
                local numberText, suffix = token:match("^(%d+%.?%d*)([a-z]*)$")
                if not numberText then
                    numberText, suffix = token:match("^(%.%d+)([a-z]*)$")
                end
                local number = tonumber(numberText)
                if not number then return nil end
                suffix = suffix or ""
                if suffix ~= "" and suffixScale[suffix] == nil then return nil end
                return number * (suffixScale[suffix] or 1)
            end

            local ratioNumerator, ratioDenominator = text:match("^([%d%.]+[a-z]*)/([%d%.]+[a-z]*)$")
            if ratioNumerator and ratioDenominator then
                return parseLuckNumber(ratioDenominator) or parseLuckNumber(ratioNumerator) or 0
            end

            local lastToken
            for token in text:gmatch("%d+%.?%d*[a-z]*") do
                lastToken = token
            end
            if not lastToken then
                lastToken = text:match("%.(%d+[a-z]*)")
                if lastToken then lastToken = "." .. lastToken end
            end

            return parseLuckNumber(lastToken) or 0
        end
        function GetEggRecords()
            local records = {}
            local byName = {}
            for zoneName, selected in pairs(SelectedZones) do
                if selected then
                    local zone = ZoneBuilds:FindFirstChild(zoneName)
                    local eggsFolder = zone and zone:FindFirstChild("Eggs")
                    if eggsFolder then
                        for _, egg in ipairs(eggsFolder:GetChildren()) do
                            if (egg:IsA("Model") or egg:IsA("BasePart"))
                            and egg.Name:lower():find("egg", 1, true) then
                                local eggName = GetEggTypeName(egg.Name)
                                local luck = GetEggLuck(egg)
                                if not byName[eggName] then
                                    byName[eggName] = {name = eggName, luck = luck, kg = GetEggWeightKg(egg) or 0}
                                    table.insert(records, byName[eggName])
                                else
                                    byName[eggName].luck = math.max(byName[eggName].luck or 0, luck)
                                    byName[eggName].kg = math.max(byName[eggName].kg or 0, GetEggWeightKg(egg) or 0)
                                end
                            end
                        end
                    end
                end
            end
            table.sort(records, function(a, b)
                if SortOrder == "Highest Luck" and a.luck ~= b.luck then
                    return a.luck > b.luck
                elseif SortOrder == "Highest Kg" and (a.kg or 0) ~= (b.kg or 0) then
                    return (a.kg or 0) > (b.kg or 0)
                end
                return a.name < b.name
            end)
            return records
        end
        UpdateAutoBreakFilterButtonTexts = function()
            local selectedZones = {}
            for zoneName, enabled in pairs(SelectedZones) do
                if enabled then
                    table.insert(selectedZones, zoneName:match("%d+") or zoneName)
                end
            end
            table.sort(selectedZones, function(a, b)
                local an, bn = tonumber(a), tonumber(b)
                if an and bn then return an > bn end
                if an then return true end
                if bn then return false end
                return a < b
            end)
            local zoneSummary = #selectedZones > 0 and table.concat(selectedZones, ", ") or "None"
            ZoneFilterButton.Text = "Zone: " .. zoneSummary .. (ZoneFilterOpen and " ▲" or " ▼")
            ZoneFilterButton.TextSize = 8
            ZoneFilterButton.TextXAlignment = Enum.TextXAlignment.Center

            local records = GetEggRecords()
            local selectedEggs = {}
            for _, record in ipairs(records) do
                if SelectedEggs[record.name] ~= false then
                    table.insert(selectedEggs, record.name)
                end
            end
            local eggSummary
            if #selectedEggs == #records then
                eggSummary = #records == 0 and "None" or "All"
            elseif #selectedEggs == 0 then
                eggSummary = "None"
            else
                eggSummary = table.concat(selectedEggs, ", ")
            end
            EggFilterButton.Text = "Eggs: " .. eggSummary .. (EggFilterOpen and " ▲" or " ▼")
            EggFilterButton.TextSize = 8
            EggFilterButton.TextXAlignment = Enum.TextXAlignment.Center
        end
        local RefreshEggList
        function RefreshZoneList()
            for _, item in ipairs(ZoneList:GetChildren()) do
                if item:IsA("TextButton") then item:Destroy() end
            end
            local zones = {}
            for _, zone in ipairs(ZoneBuilds:GetChildren()) do
                if zone:IsA("Model") then table.insert(zones, zone) end
            end
            table.sort(zones, function(a, b)
                local aNumber = tonumber(a.Name:match("%d+"))
                local bNumber = tonumber(b.Name:match("%d+"))
                if aNumber and bNumber and aNumber ~= bNumber then return aNumber > bNumber end
                if aNumber and not bNumber then return true end
                if bNumber and not aNumber then return false end
                return a.Name > b.Name
            end)
            local allSelected = #zones > 0
            for _, zone in ipairs(zones) do
                if SelectedZones[zone.Name] ~= true then allSelected = false break end
            end
            local SelectAllButton = Create("TextButton", {
                Name = "SelectAllZones", Parent = ZoneList, Size = UDim2.new(1, -8, 0, 24),
                BackgroundColor3 = allSelected and Theme.Selected or Theme.Card, Text = "",
                BorderSizePixel = 0, LayoutOrder = 0, AutoButtonColor = false, ZIndex = 101
            })
            AddCorner(SelectAllButton, 5)
            Create("TextLabel", {
                Parent = SelectAllButton, Position = UDim2.fromOffset(8, 0),
                Size = UDim2.new(1, -34, 1, 0), BackgroundTransparency = 1,
                Text = allSelected and "All Zones Selected" or "Select All",
                TextColor3 = Theme.Text, Font = Enum.Font.Gotham, TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 102
            })
            Create("TextLabel", {
                Parent = SelectAllButton, Position = UDim2.new(1, -26, 0, 0),
                Size = UDim2.fromOffset(22, 24), BackgroundTransparency = 1,
                Text = allSelected and "✓" or "○",
                TextColor3 = allSelected and Color3.fromRGB(110, 205, 145) or Theme.Gray,
                Font = Enum.Font.GothamBold, TextSize = 12, ZIndex = 102
            })
            SelectAllButton.MouseButton1Click:Connect(function()
                local selectEverything = not allSelected
                for _, zone in ipairs(zones) do SelectedZones[zone.Name] = selectEverything and true or nil end
                RefreshZoneList()
                RefreshEggList()
                if UpdateAutoBreakFilterButtonTexts then UpdateAutoBreakFilterButtonTexts() end
                if RefreshEggFilters then RefreshEggFilters() end
            end)
            for zoneIndex, zone in ipairs(zones) do
                local zoneName = zone.Name
                local selected = SelectedZones[zoneName] == true
                local ZoneButton = Create("TextButton", {
                    Name = "Zone_" .. zoneName,
                    Parent = ZoneList,
                    Size = UDim2.new(1, -8, 0, 24),
                    BackgroundColor3 = selected and Theme.Selected or Theme.Card,
                    Text = "",
                    BorderSizePixel = 0,
                    LayoutOrder = zoneIndex,
                    AutoButtonColor = false,
                    ZIndex = 101
                })
                AddCorner(ZoneButton, 5)
                Create("TextLabel", {
                    Parent = ZoneButton,
                    Position = UDim2.fromOffset(8, 0),
                    Size = UDim2.new(1, -34, 1, 0),
                    BackgroundTransparency = 1,
                    Text = zoneName,
                    TextColor3 = Theme.Text,
                    Font = Enum.Font.Gotham,
                    TextSize = 9,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 102
                })
                local Checkmark = Create("TextLabel", {
                    Parent = ZoneButton,
                    Position = UDim2.new(1, -26, 0, 0),
                    Size = UDim2.fromOffset(22, 24),
                    BackgroundTransparency = 1,
                    Text = selected and "✓" or "○",
                    TextColor3 = selected and Color3.fromRGB(110, 205, 145) or Theme.Gray,
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                    ZIndex = 102
                })
                ZoneButton.MouseButton1Click:Connect(function()
                    SelectedZones[zoneName] = not SelectedZones[zoneName] or nil
                    RefreshZoneList()
                    RefreshEggList()
                    if UpdateAutoBreakFilterButtonTexts then UpdateAutoBreakFilterButtonTexts() end
                    if RefreshEggFilters then RefreshEggFilters() end
                end)
            end
        end
        RefreshEggList = function()
            for _, item in ipairs(EggFilterList:GetChildren()) do
                if item:IsA("TextButton") or item:IsA("TextLabel") then item:Destroy() end
            end
            local records = GetEggRecords()
            local allSelected = #records > 0
            for _, record in ipairs(records) do
                if SelectedEggs[record.name] == false then allSelected = false break end
            end
            local SelectAllEggs = Create("TextButton", {
                Name = "SelectAllEggs", Parent = EggFilterList,
                Size = UDim2.new(1, -8, 0, 24),
                BackgroundColor3 = allSelected and Theme.Selected or Theme.Card,
                Text = "", BorderSizePixel = 0, LayoutOrder = 0,
                AutoButtonColor = false, ZIndex = 101
            })
            AddCorner(SelectAllEggs, 5)
            Create("TextLabel", {
                Parent = SelectAllEggs, Position = UDim2.fromOffset(8, 0),
                Size = UDim2.new(1, -34, 1, 0), BackgroundTransparency = 1,
                Text = allSelected and "All Eggs Selected" or "Select All",
                TextColor3 = Theme.Text, Font = Enum.Font.Gotham, TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 102
            })
            Create("TextLabel", {
                Parent = SelectAllEggs, Position = UDim2.new(1, -26, 0, 0),
                Size = UDim2.fromOffset(22, 24), BackgroundTransparency = 1,
                Text = allSelected and "✓" or "○",
                TextColor3 = allSelected and Color3.fromRGB(110, 205, 145) or Theme.Gray,
                Font = Enum.Font.GothamBold, TextSize = 12, ZIndex = 102
            })
            SelectAllEggs.MouseButton1Click:Connect(function()
                local selectEverything = not allSelected
                for _, record in ipairs(records) do
                    if selectEverything then SelectedEggs[record.name] = nil else SelectedEggs[record.name] = false end
                end
                RefreshEggList()
                if UpdateAutoBreakFilterButtonTexts then UpdateAutoBreakFilterButtonTexts() end
                if RefreshEggFilters then RefreshEggFilters() end
            end)
            if #records == 0 then
                Create("TextLabel", {
                    Parent = EggFilterList,
                    Size = UDim2.new(1, -8, 0, 28),
                    BackgroundTransparency = 1,
                    Text = "Select zones to view eggs",
                    TextColor3 = Theme.Gray,
                    Font = Enum.Font.Gotham,
                    TextSize = 9,
                    ZIndex = 102
                })
                return
            end
            for eggIndex, record in ipairs(records) do
                local eggName = record.name
                local selected = SelectedEggs[eggName] ~= false
                local EggButton = Create("TextButton", {
                    Name = "Egg_" .. eggName:gsub("[^%w_]", ""),
                    Parent = EggFilterList,
                    Size = UDim2.new(1, -8, 0, 24),
                    BackgroundColor3 = selected and Theme.Selected or Theme.Card,
                    Text = "",
                    BorderSizePixel = 0,
                    LayoutOrder = eggIndex,
                    AutoButtonColor = false,
                    ZIndex = 101
                })
                AddCorner(EggButton, 5)
                Create("TextLabel", {
                    Parent = EggButton,
                    Position = UDim2.fromOffset(8, 0),
                    Size = UDim2.new(1, -34, 1, 0),
                    BackgroundTransparency = 1,
                    Text = eggName,
                    TextColor3 = Theme.Text,
                    Font = Enum.Font.Gotham,
                    TextSize = 9,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 102
                })
                local Checkmark = Create("TextLabel", {
                    Parent = EggButton,
                    Position = UDim2.new(1, -26, 0, 0),
                    Size = UDim2.fromOffset(22, 24),
                    BackgroundTransparency = 1,
                    Text = selected and "✓" or "○",
                    TextColor3 = selected and Color3.fromRGB(110, 205, 145) or Theme.Gray,
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                    ZIndex = 102
                })
                EggButton.MouseButton1Click:Connect(function()
                    if SelectedEggs[eggName] == false then
                        SelectedEggs[eggName] = nil
                    else
                        SelectedEggs[eggName] = false
                    end
                    RefreshEggList()
                    if UpdateAutoBreakFilterButtonTexts then UpdateAutoBreakFilterButtonTexts() end
                    if RefreshEggFilters then RefreshEggFilters() end
                end)
            end
        end
        local TitanicPriorityToggle = CreatePickupCheckbox(Card1, "Titanic Priority", AutoBreakControlLayout.TitanicY, function(enabled)
            TitanicPriorityEnabled = enabled
            AddDebugLog("[Auto Break] TITANIC priority " .. (enabled and "ON" or "OFF"))
            if RefreshEggFilters then RefreshEggFilters() end
        end)
        Card1.Size = UDim2.new(0.5, -5, 0, 190)
        AutoPickupCard.Size = UDim2.new(0.5, -5, 0, 316)
        local function UpdateAutoBreakCardHeights()
            local autoBreakBottom = math.max(AutoBreakControlLayout.TitanicY + AutoBreakControlLayout.Height + 12, 190)
            local pickupBottom = 316
            local sharedHeight = math.max(autoBreakBottom, pickupBottom)
            Card1.Size = UDim2.new(0.5, -5, 0, sharedHeight)
            AutoPickupCard.Size = UDim2.new(0.5, -5, 0, sharedHeight)
            AutoRow.Size = UDim2.new(1, -20, 0, sharedHeight + 34)
        end
        UpdateAutoBreakCardHeights()
        function UpdateFilterPanelWithTitanic()
            UpdateFilterPanel()
            PriorityFilterButton.Position = UDim2.fromOffset(0, 0)
            PriorityFilterButton.Size = UDim2.new(1, 0, 0, AutoBreakControlLayout.Height)
            UpdateAutoBreakCardHeights()
        end
        ZoneFilterButton.MouseButton1Click:Connect(UpdateFilterPanelWithTitanic)
        EggFilterButton.MouseButton1Click:Connect(UpdateFilterPanelWithTitanic)
        RefreshZoneList()
        RefreshEggList()
        if UpdateAutoBreakFilterButtonTexts then UpdateAutoBreakFilterButtonTexts() end
        TrackPersistentConnection(ZoneBuilds.ChildAdded:Connect(function()
            RefreshZoneList()
            RefreshEggList()
        end))
        TrackPersistentConnection(ZoneBuilds.ChildRemoved:Connect(function()
            RefreshZoneList()
            RefreshEggList()
        end))
        ZoneLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            ZoneList.CanvasSize = UDim2.new(0, 0, 0, ZoneLayout.AbsoluteContentSize.Y + 8)
        end)
        EggLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            EggFilterList.CanvasSize = UDim2.new(0, 0, 0, EggLayout.AbsoluteContentSize.Y + 8)
        end)
        CurrentTarget = nil
        ArrivedAtTarget = false
        WaitingForPickup = false
        local MovementConnection
        local PickupMovementConnection
        local ReturnMovementConnection
        local BaselinePickups = {}
        PickupRequested = false
        ReturningAfterPickup = false
        local ActivePickup
        local LastAnimalPickupPosition
        local ActivePickupCPS = -1
        local PickupPhase = "IDLE"
        local PickupGeneration = 0
        local PendingAnimalPickups = {}
        local PendingAnimalPickupSet = {}
        local PendingAnimalPickupWorker = false
        local DroppedAnimalSignatures = {}
        local LastEggHPProgressAt = 0
        ScriptShuttingDown = false
        local AnimalFolderConnection
        local FlingRemoteConnection
        FlingRecoveryActive = false
        local FlingAnimalTarget
        local HandleFlingRecovery
        local CarriedAnimalWatch = {}
        local CancelFlingRecovery
        local LastAutomationProgressAt = os.clock()
        local AutomationProgressStage = "INITIALIZING"
        local AutomationWatchdogBusy = false
        TouchAutomationProgress = function(stage)
            if stage and stage ~= AutomationProgressStage then
                AutomationProgressStage = stage
                LastAutomationProgressAt = os.clock()
            elseif not stage then
                LastAutomationProgressAt = os.clock()
            end
        end
        function WaitForCharacterAndParts(timeout, isValid)
            local deadline = os.clock() + timeout
            while not Runtime.Stopped and not ScriptShuttingDown and os.clock() < deadline do
                if isValid and not isValid() then return nil end
                local character = LocalPlayer.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                local root = character and character:FindFirstChild("HumanoidRootPart")
                if character and humanoid and root then
                    return character, humanoid, root
                end
                task.wait(0.1)
            end
            return nil
        end
        function ParseWeightKg(value)
            if typeof(value) == "number" then
                return value
            end
            if value == nil then return nil end
            local textValue = tostring(value):gsub(",", ""):match("^%s*(.-)%s*$")
            if textValue == "" then return nil end
            local numberText, suffix = textValue:match("^([%d%.]+)%s*([%a]*)")
            local number = tonumber(numberText)
            if not number then return tonumber(textValue) end
            suffix = (suffix or ""):lower()
            local scales = {
                k = 1e3, m = 1e6, b = 1e9, t = 1e12,
                qa = 1e15, qi = 1e18, kg = 1
            }
            if suffix == "" then return number end
            local scale = scales[suffix]
            if scale then return number * scale end
            return nil
        end
        function GetPickupWeightKg(pickup)
            if not pickup then return nil end
            local animalPickups = workspace:FindFirstChild("AnimalPickups")
            local animal = pickup
            while animal and animalPickups and animal.Parent ~= animalPickups do
                animal = animal.Parent
            end
            if not animal or not animalPickups or animal.Parent ~= animalPickups then
                animal = pickup
            end
            local names = {"WeightKg", "WeightKG", "weightKg", "weightKG", "Weight", "weight"}
            for _, name in ipairs(names) do
                local weight = ParseWeightKg(animal:GetAttribute(name))
                if weight then return weight end
            end
            for _, node in ipairs(animal:GetDescendants()) do
                for _, name in ipairs(names) do
                    local weight = ParseWeightKg(node:GetAttribute(name))
                    if weight then return weight end
                    if node.Name == name then
                        if node:IsA("ValueBase") then
                            weight = ParseWeightKg(node.Value)
                            if weight then return weight end
                        elseif node:IsA("TextLabel") or node:IsA("TextButton") or node:IsA("TextBox") then
                            weight = ParseWeightKg(node.Text)
                            if weight then return weight end
                        end
                    end
                end
            end
            return nil
        end
        function IsKGFilterMatch(pickup)
            if KGThresholdAmount <= 0 then return false, nil end
            local weight = GetPickupWeightKg(pickup)
            local scale = 1
            if KGThresholdUnit == "K" then scale = 1e3
            elseif KGThresholdUnit == "M" then scale = 1e6
            elseif KGThresholdUnit == "B" then scale = 1e9
            elseif KGThresholdUnit == "T" then scale = 1e12
            elseif KGThresholdUnit == "Qa" then scale = 1e15
            elseif KGThresholdUnit == "Qi" then scale = 1e18 end
            local threshold = KGThresholdAmount * scale
            if not weight then
                AddDebugLog("[KG] " .. pickup.Name .. " weight not detected; threshold=" .. tostring(threshold) .. " KG.")
                return false, nil
            end
            local matches = weight >= threshold
            AddDebugLog("[KG] " .. pickup.Name .. " detected=" .. tostring(weight) .. " KG | minimum=" .. tostring(threshold) .. " KG | match=" .. tostring(matches))
            return matches, weight
        end
        function GetAnimalWeightKg(animal)
            if not animal then return nil end
            local names = {"WeightKg", "WeightKG", "weightKg", "weightKG", "Weight", "weight"}
            for _, name in ipairs(names) do
                local value = animal:GetAttribute(name)
                if value ~= nil then return tostring(value) end
            end
            for _, node in ipairs(animal:GetDescendants()) do
                for _, name in ipairs(names) do
                    local value = node:GetAttribute(name)
                    if value ~= nil then return tostring(value) end
                    if node.Name == name then
                        if node:IsA("ValueBase") then return tostring(node.Value) end
                        if (node:IsA("TextLabel") or node:IsA("TextButton") or node:IsA("TextBox")) and node.Text ~= "" then
                            return tostring(node.Text)
                        end
                    end
                end
            end
            return nil
        end
        local FlingTargetAnimalName
        local FlingTargetWeightKg
        local HitEventConnection
        local SetTrackerStatus
        function SetPickupPhase(phase, message)
            PickupPhase = phase
            TouchAutomationProgress("PICKUP:" .. tostring(phase))
            if message then SetTrackerStatus("PICKUP LOCK [" .. phase .. "]: " .. message) end
        end
        StopPickupAutomation = function(reason)
            PickupGeneration += 1
            PickupRequested = false
            ReturningAfterPickup = false
            ActivePickup = nil
            ActivePickupCPS = -1
            if CancelFlingRecovery then
                local cancelRecovery = CancelFlingRecovery
                CancelFlingRecovery = nil
                pcall(cancelRecovery)
            end
            FlingRecoveryActive = false
            TouchAutomationProgress("IDLE")
            if PickupMovementConnection then PickupMovementConnection:Disconnect(); PickupMovementConnection = nil end
            if ReturnMovementConnection then ReturnMovementConnection:Disconnect(); ReturnMovementConnection = nil end
            if MovementConnection then MovementConnection:Disconnect(); MovementConnection = nil end
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid:Move(Vector3.zero, false) end
            if SetTrackerStatus then SetTrackerStatus(tostring(reason) .. "; all pickup/return movement stopped.") end
        end
        CancelActiveAutomation = function(reason)
            if PickupRequested or ReturningAfterPickup or FlingRecoveryActive then
                StopPickupAutomation(reason or "Automation cancelled")
            end
            WaitingForPickup = false
            ArrivedAtTarget = false
            CurrentTarget = nil
            table.clear(PendingAnimalPickups)
            table.clear(PendingAnimalPickupSet)
            TouchAutomationProgress("IDLE")
        end
        ShutdownAutomation = function()
            ScriptShuttingDown = true
            PickupGeneration += 1
            PickupRequested = false
            ReturningAfterPickup = false
            ActivePickup = nil
            ActivePickupCPS = -1
            AutoBreakEnabled = false
            AutoPickupEnabled = false
            if MovementConnection then MovementConnection:Disconnect(); MovementConnection = nil end
            if PickupMovementConnection then PickupMovementConnection:Disconnect(); PickupMovementConnection = nil end
            if ReturnMovementConnection then ReturnMovementConnection:Disconnect(); ReturnMovementConnection = nil end
            if HitEventConnection then HitEventConnection:Disconnect(); HitEventConnection = nil end
            if FlingRemoteConnection then FlingRemoteConnection:Disconnect(); FlingRemoteConnection = nil end
            if AnimalFolderConnection then AnimalFolderConnection:Disconnect(); AnimalFolderConnection = nil end
            if CarriedAnimalWatch.childAdded then CarriedAnimalWatch.childAdded:Disconnect(); CarriedAnimalWatch.childAdded = nil end
            if CarriedAnimalWatch.childRemoved then CarriedAnimalWatch.childRemoved:Disconnect(); CarriedAnimalWatch.childRemoved = nil end
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid:Move(Vector3.zero, false) end
        end
        local PreviousShutdown = Runtime.Shutdown
        Runtime.Shutdown = function()
            if ShutdownAutomation then
                ShutdownAutomation()
            end
            if type(PreviousShutdown) == "function" then
                PreviousShutdown()
            end
        end
        function ClearPickupLock(token)
            if token and token ~= PickupGeneration then return false end
            PickupRequested = false
            ActivePickup = nil
            ActivePickupCPS = -1
            PickupPhase = "IDLE"
            return true
        end
        local HitEvent = game:GetService("ReplicatedStorage"):WaitForChild("EggHitConfirmed")
        local AnimalPickups = workspace:FindFirstChild("AnimalPickups")
        local function GetSafeZonePosition()
            local build = workspace:FindFirstChild("Build")
            local hitboxes = build and build:FindFirstChild("ZoneHitboxes")
            local safeZone = hitboxes and hitboxes:FindFirstChild("SafeZone")
            if not safeZone then return nil end
            if safeZone:IsA("BasePart") then
                return safeZone.Position
            end
            local ok, pivot = pcall(function()
                return safeZone:GetPivot()
            end)
            return ok and pivot and pivot.Position or nil
        end
        function EquipHotbarOne()
            local Players = game:GetService("Players")
            local currentPlayer = LocalPlayer or Players.LocalPlayer
            if not currentPlayer then
                SetTrackerStatus("Hotbar 1 select failed: LocalPlayer unavailable.")
                return false
            end

            local character = currentPlayer.Character
            if not character then
                local ok, result = pcall(function()
                    return currentPlayer.CharacterAdded:Wait()
                end)
                if ok then character = result end
            end
            if not character then
                SetTrackerStatus("Hotbar 1 select failed: character not loaded.")
                return false
            end

            local humanoid = character:FindFirstChildOfClass("Humanoid")
                or character:WaitForChild("Humanoid", 5)
            if not humanoid then
                SetTrackerStatus("Hotbar 1 select failed: Humanoid not ready.")
                return false
            end
            if humanoid.Health <= 0 then
                SetTrackerStatus("Hotbar 1 select failed: character is dead.")
                return false
            end

            if currentPlayer.Character ~= character or not character.Parent then
                SetTrackerStatus("Hotbar 1 select failed: character changed before selection.")
                return false
            end

            local ok, err = pcall(function()
                local virtualInput = game:GetService("VirtualInputManager")
                virtualInput:SendKeyEvent(true, Enum.KeyCode.One, false, game)
                task.wait(0.05)
                virtualInput:SendKeyEvent(false, Enum.KeyCode.One, false, game)
            end)
            if not ok then
                SetTrackerStatus("Hotbar 1 key selection failed: " .. tostring(err))
                return false
            end

            task.wait(0.15)
            SetTrackerStatus("Selected hotbar slot 1.")
            return true
        end
        local AnimalBankEquipConnections = {}
        function BindAnimalBankEquip(remote)
            if not remote:IsA("RemoteEvent") or AnimalBankEquipConnections[remote] then return end
            local remoteName = remote.Name:lower():gsub("[^%a]", "")
            if not remoteName:find("animalbank", 1, true) and not remoteName:find("bankanimal", 1, true) then return end
            AnimalBankEquipConnections[remote] = TrackPersistentConnection(remote.OnClientEvent:Connect(function()
                task.delay(2, function()
                    if Runtime.Stopped then return end
                    SetTrackerStatus("Animal bank event received; equipping hotbar 1 after 2 seconds.")
                    EquipHotbarOne()
                end)
            end))
        end
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
            BindAnimalBankEquip(remote)
        end
        TrackPersistentConnection(ReplicatedStorage.DescendantAdded:Connect(function(instance)
            BindAnimalBankEquip(instance)
        end))
        local PendingReturnAfterFling = false
        local PendingReturnAfterFlingReason = nil
        function ReturnToPickup(reason)
            if FlingRecoveryActive then
                PendingReturnAfterFling = true
                PendingReturnAfterFlingReason = reason or "Pickup confirmed. Returning to base."
                SetTrackerStatus("Return queued: waiting for fling recovery to release movement.")
                return
            end
            if ReturningAfterPickup then return end
            local useZoneDrop = DropInZone1Enabled == true
            ClearPickupLock()
            ReturningAfterPickup = true
            local returnToken = PickupGeneration
            TouchAutomationProgress("RETURNING_TO_BASE")
            SetTrackerStatus(reason or "Pickup hold completed. Returning to the pickup point.")
            task.spawn(function()
                local character, humanoid, root = WaitForCharacterAndParts(10, function()
                    return PickupGeneration == returnToken and ReturningAfterPickup
                end)
                if not character then
                    if PickupGeneration == returnToken then
                        ReturningAfterPickup = false
                        SetTrackerStatus("Return cancelled: character parts unavailable or return was cancelled.")
                        if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    end
                    return
                end
                SetTrackerStatus(useZoneDrop and "Moving to Zone 1 to drop the animal." or "Returning to workspace.Build.ZoneHitboxes.SafeZone.")
                local moveStarted = os.clock()
                local lastReturnDistance = math.huge
                local connection
                connection = game:GetService("RunService").RenderStepped:Connect(function()
                    if PickupGeneration ~= returnToken then
                        connection:Disconnect()
                        if ReturnMovementConnection == connection then ReturnMovementConnection = nil end
                        connection = nil
                        return
                    end
                    if not ReturningAfterPickup or LocalPlayer.Character ~= character or not character.Parent or not root.Parent or humanoid.Health <= 0 then
                        humanoid:Move(Vector3.zero, false)
                        connection:Disconnect()
                        if ReturnMovementConnection == connection then ReturnMovementConnection = nil end
                        connection = nil
                        ReturningAfterPickup = false
                        SetTrackerStatus("Return movement stopped: character unavailable.")
                        if AutoBreakEnabled and StartAutoBreak then
                            task.delay(0.2, function()
                                if PickupGeneration == returnToken and AutoBreakEnabled and not PickupRequested and not ReturningAfterPickup then StartAutoBreak() end
                            end)
                        end
                        return
                    end
                    local destination = GetSafeZonePosition()
                    if not destination then
                        humanoid:Move(Vector3.zero, false)
                        connection:Disconnect()
                        connection = nil
                        ReturningAfterPickup = false
                        SetTrackerStatus("Return stopped: workspace.Build.ZoneHitboxes.SafeZone was not found or has no readable position.")
                        if AutoBreakEnabled and StartAutoBreak then
                            task.delay(0.2, function()
                                if PickupGeneration == returnToken and AutoBreakEnabled and not PickupRequested and not ReturningAfterPickup then StartAutoBreak() end
                            end)
                        end
                        return
                    end
                    if useZoneDrop then
                        local build = workspace:FindFirstChild("Build")
                        local zoneBuilds = build and build:FindFirstChild("ZoneBuilds")
                        local zone1 = zoneBuilds and zoneBuilds:FindFirstChild("Zone1")
                        if not zone1 then
                            humanoid:Move(Vector3.zero, false)
                            connection:Disconnect()
                            connection = nil
                            ReturningAfterPickup = false
                            SetTrackerStatus("Drop in Zone 1 cancelled: workspace.Build.ZoneBuilds.Zone1 was not found.")
                            if AutoBreakEnabled and StartAutoBreak then task.delay(0.2, function()
                                if PickupGeneration == returnToken and AutoBreakEnabled and not PickupRequested and not ReturningAfterPickup then StartAutoBreak() end
                            end) end
                            return
                        end
                        if zone1:IsA("Model") then
                            destination = zone1:GetPivot().Position
                        elseif zone1:IsA("BasePart") then
                            destination = zone1.Position
                        else
                            local ok, pivot = pcall(function() return zone1:GetPivot() end)
                            if ok and pivot then destination = pivot.Position end
                        end
                    end
                    local horizontalDestination = Vector3.new(destination.X, root.Position.Y, destination.Z)
                    local offset = horizontalDestination - root.Position
                    if offset.Magnitude < lastReturnDistance - 0.5 then
                        lastReturnDistance = offset.Magnitude
                        TouchAutomationProgress()
                    end
                    if offset.Magnitude <= 4 then
                        TouchAutomationProgress(useZoneDrop and "RETURNING_TO_ZONE1:ARRIVED" or "RETURNING_TO_BASE:ARRIVED")
                        humanoid:Move(Vector3.zero, false)
                        connection:Disconnect()
                        connection = nil
                        if useZoneDrop then
                            task.spawn(function()
                                SetTrackerStatus("Reached Zone 1; requesting animal drop.")
                                local carriedFolder = workspace:FindFirstChild("CarriedAnimals")
                                local carriedBefore = CarriedAnimalWatch.model
                                local targetAnimal = FlingAnimalTarget or ActivePickup
                                local targetName = FlingTargetAnimalName or (targetAnimal and targetAnimal.Name)
                                local targetWeight = FlingTargetWeightKg
                                if targetWeight == nil and carriedBefore then targetWeight = GetAnimalWeightKg(carriedBefore) end
                                local signature
                                if targetAnimal then
                                    for _, key in ipairs({"AnimalId", "AnimalID", "UniqueId", "UUID", "Id"}) do
                                        local value = targetAnimal:GetAttribute(key)
                                        if value ~= nil and tostring(value) ~= "" then
                                            signature = "id:" .. tostring(value)
                                            break
                                        end
                                    end
                                    if not signature and targetWeight ~= nil and tostring(targetWeight) ~= "" then
                                        signature = "name:" .. targetAnimal.Name .. "|weight:" .. tostring(targetWeight)
                                    end
                                end
                                local targetRarity = targetAnimal and targetAnimal:GetAttribute("Rarity")
                                if targetRarity == nil and targetAnimal then
                                    local rarityNode = targetAnimal:FindFirstChild("Rarity", true)
                                    if rarityNode then
                                        if rarityNode:IsA("ValueBase") then targetRarity = rarityNode.Value
                                        elseif rarityNode:IsA("TextLabel") then targetRarity = rarityNode.Text end
                                    end
                                end
                                local dropRemote = ReplicatedStorage:FindFirstChild("DropCarriedRemote")
                                local fired, fireError = pcall(function()
                                    if not dropRemote then error("ReplicatedStorage.DropCarriedRemote was not found") end
                                    dropRemote:FireServer()
                                end)
                                if not fired then
                                    ReturningAfterPickup = false
                                    SetTrackerStatus("Zone 1 drop failed: " .. tostring(fireError))
                                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                                    return
                                end
                                local releaseDeadline = os.clock() + 4
                                local released = false
                                while not Runtime.Stopped and not ScriptShuttingDown and os.clock() < releaseDeadline do
                                    local currentFolder = workspace:FindFirstChild("CarriedAnimals")
                                    local currentModel = CarriedAnimalWatch.model
                                    if (carriedBefore and currentModel ~= carriedBefore)
                                        or (not currentModel and (not currentFolder or #currentFolder:GetChildren() == 0)) then
                                        released = true
                                        break
                                    end
                                    task.wait(0.1)
                                end
                                if released then
                                    if signature then DroppedAnimalSignatures[signature] = true end
                                    SetTrackerStatus("Zone 1 drop confirmed" .. (targetName and (": " .. targetName) or "") .. " | rarity=" .. tostring(targetRarity or "Unknown"))
                                else
                                    SetTrackerStatus("Zone 1 drop was requested, but release could not be confirmed.")
                                end
                                task.wait(0.2)
                                local equipped = EquipHotbarOne()
                                ReturningAfterPickup = false
                                if equipped then
                                    SetTrackerStatus(released and "Dropped in Zone 1; hotbar 1 equipped." or "Zone 1 drop unconfirmed; hotbar 1 equipped.")
                                end
                                if AutoBreakEnabled and StartAutoBreak then
                                    task.delay(0.2, function()
                                        if PickupGeneration == returnToken and AutoBreakEnabled and not PickupRequested and not ReturningAfterPickup then StartAutoBreak() end
                                    end)
                                end
                            end)
                        else
                            ReturningAfterPickup = false
                            SetTrackerStatus("Reached base; waiting 2 seconds before equipping hotbar 1.")
                            task.delay(2, function()
                                if not ScriptShuttingDown and PickupGeneration == returnToken and not PickupRequested and not ReturningAfterPickup and AutoPickupEnabled and LocalPlayer.Character == character then
                                    local equipped = EquipHotbarOne()
                                    if equipped then SetTrackerStatus("Returned to base; hotbar 1 tool equipped.") end
                                end
                            end)
                            if AutoBreakEnabled and StartAutoBreak then
                                task.delay(0.2, function()
                                    if PickupGeneration == returnToken and AutoBreakEnabled and not PickupRequested and not ReturningAfterPickup then StartAutoBreak() end
                                end)
                            end
                        end
                        return
                    end
                    if os.clock() - moveStarted >= 60 then
                        humanoid:Move(Vector3.zero, false)
                        connection:Disconnect()
                        connection = nil
                        ReturningAfterPickup = false
                        SetTrackerStatus("Return timed out; horizontal distance="
                            .. math.floor(offset.Magnitude) .. ".")
                        if AutoBreakEnabled and StartAutoBreak then
                            task.delay(0.2, function()
                                if PickupGeneration == returnToken and AutoBreakEnabled and not PickupRequested and not ReturningAfterPickup then StartAutoBreak() end
                            end)
                        end
                        return
                    end
                    humanoid:Move(offset.Unit, false)
                end)
                ReturnMovementConnection = connection
            end)
        end
        function IsTargetReference(reference, target)
            if typeof(reference) ~= "Instance" or typeof(target) ~= "Instance" then
                return false
            end
            return reference == target or reference:IsDescendantOf(target)
        end
        SetTrackerStatus = function(message)
            AddDebugLog("[Egg Tracker] " .. tostring(message))
        end
        HitEventConnection = TrackPersistentConnection(HitEvent.OnClientEvent:Connect(function(eggReference, hitCounter, health)
            local target = CurrentTarget
            if not target or not IsTargetReference(eggReference, target) then
                return
            end
            local numericHealth = tonumber(health)
            if LastEggHPTarget ~= target or numericHealth ~= LastEggHPValue then
                LastEggHPTarget = target
                LastEggHPValue = numericHealth
                LastEggHPProgressAt = os.clock()
                TouchAutomationProgress()
            end
            SetTrackerStatus("MATCH | target=" .. target:GetFullName()
                .. " | counter=" .. tostring(hitCounter)
                .. " | health=" .. tostring(health))
            if numericHealth and numericHealth <= 0 then
                TouchAutomationProgress("EGG_BROKEN")
                CompletedEggs[target] = true
                WaitingForPickup = false
                ArrivedAtTarget = false
                if MovementConnection then MovementConnection:Disconnect(); MovementConnection = nil end
                local character = LocalPlayer.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                if humanoid and not PickupRequested and not ReturningAfterPickup then humanoid:Move(Vector3.zero, false) end
                SetTrackerStatus("Egg broken; Auto Break will continue while Auto Pickup monitors AnimalPickups.")
                task.defer(function()
                    task.wait(0.15)
                    if AutoBreakEnabled and not PickupRequested and not ReturningAfterPickup
                        and not FlingRecoveryActive and not ScriptShuttingDown and StartAutoBreak then
                        StartAutoBreak(true)
                    end
                end)
            end
        end))
        function GetPetRarity(pickup)
            if not pickup then return nil end

            local rootPart = pickup:FindFirstChild("RootPart")
            local attachment = rootPart and rootPart:FindFirstChild("AnimalOverheadAttachment")
            local overhead = attachment and attachment:FindFirstChild("AnimalOverhead")
            local rarity = overhead and overhead:FindFirstChild("Rarity")
            local label = rarity and rarity:FindFirstChild("RarityLabel")

            if label and (label:IsA("TextLabel") or label:IsA("TextButton")) then
                local value = label.Text
                if value and value ~= "" then
                    return value
                end
            end

            local rarityNode = pickup:FindFirstChild("Rarity", true)
            if rarityNode then
                if rarityNode:IsA("StringValue") then
                    return rarityNode.Value
                elseif rarityNode:IsA("TextLabel") or rarityNode:IsA("TextButton") then
                    return rarityNode.Text
                end
            end

            local attribute = pickup:GetAttribute("Rarity")
            return attribute and tostring(attribute) or nil
        end
        function GetPickupMutation(pickup)
            if not pickup then return "No Mutation" end
            local variant = pickup:GetAttribute("Variant")
            if variant ~= nil and tostring(variant) ~= "" then
                return "Mutated"
            end
            return "No Mutation"
        end
        function GetDroppedAnimalSignature(pickup, weight)
            if not pickup then return nil end
            for _, key in ipairs({"AnimalId", "AnimalID", "UniqueId", "UUID", "Id"}) do
                local value = pickup:GetAttribute(key)
                if value ~= nil and tostring(value) ~= "" then return "id:" .. tostring(value) end
            end
            if weight ~= nil and tostring(weight) ~= "" then
                return "name:" .. pickup.Name .. "|weight:" .. tostring(weight)
            end
            return nil
        end
        function IsRecentlyDroppedAnimal(pickup)
            if not pickup then return false end
            local signature = GetDroppedAnimalSignature(pickup, GetAnimalWeightKg(pickup))
            if signature and DroppedAnimalSignatures[signature] then
                DroppedAnimalSignatures[signature] = nil
                SetPickupTracking(pickup, "Skipped: just dropped in Zone 1")
                pickup:SetAttribute("MoldyHub_BASAE_Rarity", tostring(GetPetRarity(pickup) or "Unknown"))
                SetTrackerStatus("Skipped recently dropped animal: " .. pickup.Name .. " | rarity=" .. tostring(GetPetRarity(pickup) or "Unknown"))
                return true
            end
            return false
        end
        function GetPickupZone(pickup)
            local zone = pickup:FindFirstChild("ZoneId", true)
            if zone and zone:IsA("ValueBase") then
                return tostring(zone.Value)
            end
            local attribute = pickup:GetAttribute("ZoneId")
            return attribute and tostring(attribute) or nil
        end
        function ParseCPS(display)
            if type(display) ~= "string" then return -1 end
            local cleaned = display:gsub(",", ""):gsub("%s+", ""):gsub("%$", "")
            cleaned = cleaned:gsub("/[sS]$", "")
            local numberText, suffix = cleaned:match("^([%d%.]+)([%a]*)$")
            local number = tonumber(numberText)
            local scales = {k=1e3, m=1e6, b=1e9, t=1e12, qa=1e15, q=1e15, qi=1e18}
            local scale = scales[(suffix or ""):lower()]
            if number and number >= 0 and (not suffix or suffix == "" or scale) then
                return number * (scale or 1)
            end
            return -1
        end
        function GetPetCPS(pickup)
            if not pickup or not pickup:IsA("Model") then
                return -1, "CPS unavailable: animal model missing"
            end
            local sawCPSNode = false
            local function readTextObject(object)
                if not object then return -1, nil end
                if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
                    local value = ParseCPS(object.Text)
                    if value >= 0 then return value, object.Text end
                end
                for _, childName in ipairs({"Text", "ContentText", "CashPerSecond"}) do
                    local child = object:FindFirstChild(childName, true)
                    if child and (child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox")) then
                        local value = ParseCPS(child.Text)
                        if value >= 0 then return value, child.Text end
                    end
                end
                -- Some overheads nest the actual TextLabel one level deeper:
                -- AnimalOverhead.CashPerSecond.CashPerSecond.
                for _, descendant in ipairs(object:GetDescendants()) do
                    if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
                        local value = ParseCPS(descendant.Text)
                        if value >= 0 then return value, descendant.Text end
                    end
                end
                return -1, nil
            end
            local descendants = pickup:GetDescendants()
            for _, node in ipairs(descendants) do
                if node.Name == "CashPerSecond" then
                    sawCPSNode = true
                    local value, display = readTextObject(node)
                    if value >= 0 then return value, display end
                end
            end
            for _, node in ipairs(descendants) do
                if node.Name == "AnimalOverheadAttachment" or node.Name == "AnimalOverhead" then
                    local value, display = readTextObject(node:FindFirstChild("CashPerSecond", true))
                    if value >= 0 then return value, display end
                end
            end
            if sawCPSNode then
                return -1, "CPS unavailable: CashPerSecond exists but contains no readable numeric Text/ContentText"
            end
            return -1, "CPS unavailable: no CashPerSecond node found in animal model"
        end
        function IsRarityAllowed(pickup)
            local selectedCount = 0
            for _, selected in pairs(SelectedRarities) do
                if selected then selectedCount += 1 end
            end
            if selectedCount == 0 then return false end
            local rarity = GetPetRarity(pickup)
            if not rarity then
                SetTrackerStatus("Cannot filter " .. pickup.Name .. ": Rarity value not found.")
                return false
            end
            for selectedRarity, selected in pairs(SelectedRarities) do
                if selected and selectedRarity:lower() == rarity:lower() then
                    return true
                end
            end
            return false
        end
        function GetLowestPlacedCPS()
            local plots = workspace:FindFirstChild("Plots")
            if not plots then return -1 end
            for _, base in ipairs(plots:GetChildren()) do
                local hitbox = base:FindFirstChild("Hitbox")
                local info = hitbox and hitbox:FindFirstChild("PlayerInfoUi")
                local nameLabel = info and info:FindFirstChild("Name")
                if nameLabel and nameLabel:IsA("TextLabel") and nameLabel.Text == "Your Base" then
                    local placed = base:FindFirstChild("PlacedAnimals")
                    local lowest = math.huge
                    if placed then
                        for _, animal in ipairs(placed:GetChildren()) do
                            local value = GetPetCPS(animal)
                            if value >= 0 and value < lowest then lowest = value end
                        end
                    end
                    return lowest < math.huge and lowest or -1
                end
            end
            return -1
        end
        function RejectPickupAndRestart(message)
            if PickupRequested then
                SetTrackerStatus(message .. " | candidate rejected; active pickup remains in control.")
                return
            end
            if ReturningAfterPickup then
                SetTrackerStatus(message .. " | candidate rejected while returning to base.")
                return
            end
            local hadTarget = CurrentTarget ~= nil and CurrentTarget.Parent ~= nil
            if hadTarget and WaitingForPickup and IsEggConfirmedComplete(CurrentTarget) then
                CompletedEggs[CurrentTarget] = true
            end
            SetTrackerStatus(message .. (hadTarget and WaitingForPickup
                and " | rejected animal; releasing egg wait and resuming Auto Break."
                or " | rejected animal; checking whether Auto Break can resume."))
            task.defer(function()
                if StopAutoBreak then StopAutoBreak("Recovering after rejected animal.", CurrentTarget ~= nil and IsEggAvailable(CurrentTarget)) end
                task.wait(0.2)
                if AutoBreakEnabled and not PickupRequested and not ReturningAfterPickup and StartAutoBreak then
                    StartAutoBreak()
                end
            end)
        end
        function SetPickupTracking(pickup, status, cpsText)
            if not pickup or not pickup.Parent then return end
            pickup:SetAttribute("MoldyHub_BASAE_CPSCheckStatus", tostring(status or "Not checked"))
            if cpsText ~= nil then
                pickup:SetAttribute("MoldyHub_BASAE_CPSCheckValue", tostring(cpsText))
            end
            pickup:SetAttribute("MoldyHub_BASAE_CPSCheckedAt", os.time())
        end
        function GetIndexNameLabel(animalName)
            local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            local mainGui = playerGui and playerGui:FindFirstChild("MainGUI")
            local frames = mainGui and mainGui:FindFirstChild("Frames")
            local index = frames and frames:FindFirstChild("Index")
            local indexList = index and index:FindFirstChild("IndexList")
            local scrollingFrame = indexList and indexList:FindFirstChild("ScrollingFrame")
            if not scrollingFrame then return nil end
            local wanted = tostring(animalName):lower():gsub("[%s_%-]", "")
            for _, zone in ipairs(scrollingFrame:GetChildren()) do
                local animalList = zone:FindFirstChild("AnimalList")
                if animalList then
                    for _, animalEntry in ipairs(animalList:GetChildren()) do
                        local entryName = animalEntry.Name:lower():gsub("[%s_%-]", "")
                        if entryName == wanted then
                            local inner = animalEntry:FindFirstChild("Inner")
                            local nameLabel = inner and inner:FindFirstChild("Name")
                            if nameLabel and (nameLabel:IsA("TextLabel") or nameLabel:IsA("TextButton")) then
                                return nameLabel
                            end
                        end
                    end
                end
            end
            return nil
        end
        function EvaluateUnindexedStatus(pickup)
            local label = GetIndexNameLabel(pickup.Name)
            for attempt = 1, 8 do
                if label and label.Parent then break end
                if not pickup.Parent or not AutoPickupEnabled then
                    return nil, "verification cancelled"
                end
                SetPickupTracking(pickup, string.format("Waiting for Index entry (%d/8)", attempt))
                task.wait(0.25)
                label = GetIndexNameLabel(pickup.Name)
            end
            if not label or not label.Parent then
                return nil, "Index entry unavailable"
            end
            local displayName = tostring(label.Text or ""):match("^%s*(.-)%s*$")
            if displayName == "???" then
                return true, displayName
            end
            if displayName == "" then
                return nil, "Index name is empty"
            end
            return false, displayName
        end
        function EvaluatePickup(pickup)
            local function evaluationCancelled()
                return ScriptShuttingDown or not AutoPickupEnabled or not pickup.Parent
            end
            pickup:SetAttribute("MoldyHub_BASAE_Qualified", false)
            SetPickupTracking(pickup, "Checking")
            if evaluationCancelled() then
                SetPickupTracking(pickup, "Cancelled: automation toggled")
                return
            end
            if ReturningAfterPickup then
                SetPickupTracking(pickup, "Skipped: returning to base")
                SetTrackerStatus("Eligible pet " .. pickup.Name .. " ignored: already returning to base.")
                return
            end
            if IsRecentlyDroppedAnimal(pickup) then return end
            local zoneAllowed, pickupZoneName = IsPickupAllowedByZone(pickup)
            if not zoneAllowed then
                SetPickupTracking(pickup, "Rejected: outside selected pickup zones", tostring(pickupZoneName or "unknown zone"))
                RejectPickupAndRestart("Filtered out " .. pickup.Name .. " | zone " .. tostring(pickupZoneName or "unknown") .. " is not selected.")
                return
            end
            if not AutoPickupEnabled then
                SetPickupTracking(pickup, "Skipped: Auto Pickup OFF")
                if CurrentTarget and IsEggConfirmedComplete(CurrentTarget) then CompletedEggs[CurrentTarget] = true end
                WaitingForPickup = false
                SetTrackerStatus("New pet detected (Auto Pickup OFF): " .. pickup.Name .. " | checking current egg HP before selecting another.")
                task.defer(function()
                    if StopAutoBreak then StopAutoBreak("Auto Pickup is OFF; checking current egg HP.", CurrentTarget ~= nil and IsEggAvailable(CurrentTarget)) end
                    task.wait(0.2)
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                end)
                return
            end
            local forceUnindexedPickup = false
            if UnindexedOnlyEnabled then
                local isUnindexed, indexDisplay = EvaluateUnindexedStatus(pickup)
                if evaluationCancelled() then
                    SetPickupTracking(pickup, "Cancelled: automation toggled")
                    return
                end
                if isUnindexed == nil then
                    SetPickupTracking(pickup, "Rejected: Index verification unavailable", tostring(indexDisplay))
                    RejectPickupAndRestart("Filtered out " .. pickup.Name .. " | Index verification failed: " .. tostring(indexDisplay))
                    return
                elseif isUnindexed then
                    forceUnindexedPickup = true
                    SetPickupTracking(pickup, "Unindexed (???); bypassing filters", "???")
                else
                    SetPickupTracking(pickup, "Already indexed; applying normal filters", tostring(indexDisplay))
                end
            end
            local kgPriorityPickup, pickupWeightKg = false, nil
            local aboveLowestPriorityPickup = false
            local cpsPriorityPickup = false
            local rarityPriorityPickup = false
            local cps, cpsText = -1, "CPS skipped for unindexed animal"
            local pickupPriority = 5
            if not forceUnindexedPickup then
                kgPriorityPickup, pickupWeightKg = IsKGFilterMatch(pickup)
                if kgPriorityPickup then
                    SetPickupTracking(pickup, "KG threshold matched", tostring(pickupWeightKg) .. " KG")
                end
                rarityPriorityPickup = IsRarityAllowed(pickup)
                SetPickupTracking(pickup, "CPS scan 1/2: warming up")
                local _, firstScanText = GetPetCPS(pickup)
                if evaluationCancelled() or not pickup.Parent then
                    SetPickupTracking(pickup, "CPS verification cancelled", firstScanText)
                    return
                end
                task.wait(0.15)
                if evaluationCancelled() or not pickup.Parent then
                    SetPickupTracking(pickup, "CPS verification cancelled", firstScanText)
                    return
                end
                SetPickupTracking(pickup, "CPS scan 2/2: using this result")
                cps, cpsText = GetPetCPS(pickup)
                if cps < 0 then
                    for attempt = 1, 8 do
                        if evaluationCancelled() or not pickup.Parent then break end
                        SetPickupTracking(pickup, string.format("Waiting for valid second CPS scan (%d/8)", attempt), cpsText)
                        task.wait(0.25)
                        if evaluationCancelled() or not pickup.Parent then return end
                        cps, cpsText = GetPetCPS(pickup)
                        if cps >= 0 then break end
                    end
                end
                SetPickupTracking(pickup, cps >= 0 and "CPS checked (second scan)" or "CPS read failed", cpsText)
                if CPSFilter.amount > 0 and cps >= 0 then
                    local scales = {K = 1e3, M = 1e6, B = 1e9, T = 1e12, Qa = 1e15}
