-- BASAE EVENTS PAGE
return function(Context)
    local index = 3
    local name = "Events"
    local Page = CreatePage(index, name)

    -- Existing candy placeholder.
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

    -- AUTO MERGE
    local Players = game:GetService("Players")
    local CollectionService = game:GetService("CollectionService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = Players.LocalPlayer
    local MergeRemote = ReplicatedStorage:WaitForChild("MergeMachineRemote")

    local MergeCard = CreateCard(Page, "Auto Merge", "Automatically merge 3 owned animals with the same name.")
    MergeCard.Size = UDim2.new(1, 0, 0, 178)

    local MergeEnabled = false
    local MergeGeneration = 0
    local SelectedAnimalName = "All animals"
    local WeightOrder = "Highest KG first"
    local MergeBusy = false
    local MergeStatus

    local MergeToggle = CreateToggle(MergeCard, "", false, function(enabled)
        MergeEnabled = enabled
        if MergeStatus then
            MergeStatus.Text = enabled and "Running — scanning for 3 matching animals." or "Off — automation stopped."
        end
        MergeGeneration += 1
        local generation = MergeGeneration
        if enabled then
            task.spawn(function()
                while MergeEnabled and generation == MergeGeneration do
                    if MergeBusy then
                        task.wait(0.25)
                        continue
                    end
                    MergeBusy = true

                    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
                    local character = LocalPlayer.Character
                    local groups = {}

                    local function parseWeight(value)
                        if value == nil then return nil end
                        local cleaned = tostring(value):gsub(",", "")
                        cleaned = cleaned:gsub("%s*[Kk][Gg]%s*$", "")
                        return tonumber(cleaned:match("^%s*(.-)%s*$"))
                    end

                    for _, tool in ipairs(CollectionService:GetTagged("AnimalTool")) do
                        local owned = tool:IsA("Tool") and (
                            (backpack and tool:IsDescendantOf(backpack))
                            or (character and tool:IsDescendantOf(character))
                        )
                        if owned then
                            local animalName = tool:GetAttribute("AnimalName")
                            local weight = parseWeight(tool:GetAttribute("WeightKg"))
                            if typeof(animalName) == "string" and animalName ~= "" and weight then
                                if SelectedAnimalName == "All animals" or animalName == SelectedAnimalName then
                                    groups[animalName] = groups[animalName] or {}
                                    table.insert(groups[animalName], {Tool = tool, Weight = weight})
                                end
                            end
                        end
                    end

                    local chosenName, chosenGroup
                    for animalName, animals in pairs(groups) do
                        if #animals >= 3 then
                            table.sort(animals, function(a, b)
                                if WeightOrder == "Highest KG first" then
                                    return a.Weight > b.Weight
                                end
                                return a.Weight < b.Weight
                            end)
                            if not chosenGroup or #animals > #chosenGroup then
                                chosenName, chosenGroup = animalName, animals
                            end
                        end
                    end

                    if not chosenGroup then
                        MergeBusy = false
                        task.wait(1)
                    else
                        local mergeList = {}
                        for slot = 1, 3 do
                            local item = chosenGroup[slot]
                            if not item or not item.Tool.Parent then
                                mergeList = {}
                                break
                            end
                            table.insert(mergeList, item.Tool)
                        end

                        if #mergeList == 3 and MergeEnabled and generation == MergeGeneration then
                            local before = {}
                            for _, tool in ipairs(mergeList) do before[tool] = true end
                            local ok, err = pcall(function()
                                MergeRemote:FireServer("Merge", mergeList)
                            end)
                            if not ok then
                                warn("[BASAE Auto Merge] Remote call failed:", err)
                                MergeEnabled = false
                                MergeGeneration += 1
                                if MergeStatus then MergeStatus.Text = "Stopped — remote call failed. Check the console." end
                            else
                                print("[BASAE Auto Merge] Merge request sent:", chosenName,
                                    mergeList[1]:GetAttribute("WeightKg"),
                                    mergeList[2]:GetAttribute("WeightKg"),
                                    mergeList[3]:GetAttribute("WeightKg"))
                                -- Wait for the server to consume/update at least one selected tool.
                                local changed = false
                                for _ = 1, 30 do
                                    if not MergeEnabled or generation ~= MergeGeneration then break end
                                    task.wait(0.1)
                                    for tool in pairs(before) do
                                        if not tool.Parent
                                            or not ((backpack and tool:IsDescendantOf(backpack))
                                                or (LocalPlayer.Character and tool:IsDescendantOf(LocalPlayer.Character))) then
                                            changed = true
                                            break
                                        end
                                    end
                                    if changed then break end
                                end
                                if not changed and MergeEnabled and generation == MergeGeneration then
                                    warn("[BASAE Auto Merge] No inventory change detected; stopping to avoid repeated requests.")
                                    MergeEnabled = false
                                    MergeGeneration += 1
                                    if MergeStatus then MergeStatus.Text = "Stopped — no inventory change detected after the request." end
                                end
                            end
                        end
                        MergeBusy = false
                        task.wait(0.5)
                    end
                end
                MergeBusy = false
            end)
        end
    end)
    MergeToggle.Position = UDim2.new(1, -58, 0, 7)
    MergeToggle.Size = UDim2.fromOffset(48, 24)
    local MergeTitle = MergeCard:FindFirstChildWhichIsA("TextLabel")
    if MergeTitle then MergeTitle.Size = UDim2.new(1, -78, 0, 22) end

    Create("TextLabel", {
        Parent = MergeCard,
        Position = UDim2.fromOffset(11, 39),
        Size = UDim2.new(1, -22, 0, 13),
        BackgroundTransparency = 1,
        Text = "Animal name filter",
        TextColor3 = Theme.Gray,
        Font = Enum.Font.GothamMedium,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local AnimalFilterButton = CreateButton(MergeCard, "Animal: All animals ▼", function()
        local list = MergeCard:FindFirstChild("AnimalFilterList")
        if list then
            list:Destroy()
            return
        end

        local names = {}
        local seen = {}
        for _, tool in ipairs(CollectionService:GetTagged("AnimalTool")) do
            local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
            local character = LocalPlayer.Character
            local owned = tool:IsA("Tool") and (
                (backpack and tool:IsDescendantOf(backpack))
                or (character and tool:IsDescendantOf(character))
            )
            local animalName = owned and tool:GetAttribute("AnimalName")
            if typeof(animalName) == "string" and animalName ~= "" and not seen[animalName] then
                seen[animalName] = true
                table.insert(names, animalName)
            end
        end
        table.sort(names)

        local options = {"All animals"}
        for _, animalName in ipairs(names) do table.insert(options, animalName) end

        local list = Create("ScrollingFrame", {
            Name = "AnimalFilterList",
            Parent = MergeCard,
            Position = UDim2.fromOffset(11, 91),
            Size = UDim2.new(1, -22, 0, math.min(112, #options * 24)),
            BackgroundColor3 = Theme.SurfaceInput,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            CanvasSize = UDim2.fromOffset(0, #options * 24),
            ZIndex = 300
        })
        AddCorner(list, 6)
        AddStroke(list, Theme.Border, 1)
        Create("UIListLayout", {Parent = list, SortOrder = Enum.SortOrder.LayoutOrder})
        for optionIndex, option in ipairs(options) do
            local button = Create("TextButton", {
                Parent = list,
                Size = UDim2.new(1, -4, 0, 24),
                BackgroundTransparency = 1,
                Text = option,
                TextColor3 = Theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 9,
                BorderSizePixel = 0,
                LayoutOrder = optionIndex,
                ZIndex = 301
            })
            button.MouseButton1Click:Connect(function()
                SelectedAnimalName = option
                AnimalFilterButton.Text = "Animal: " .. option .. " ▼"
                list:Destroy()
            end)
        end
    end)
    AnimalFilterButton.Position = UDim2.fromOffset(11, 55)
    AnimalFilterButton.Size = UDim2.new(1, -22, 0, 24)

    Create("TextLabel", {
        Parent = MergeCard,
        Position = UDim2.fromOffset(11, 86),
        Size = UDim2.new(1, -22, 0, 13),
        BackgroundTransparency = 1,
        Text = "Weight priority",
        TextColor3 = Theme.Gray,
        Font = Enum.Font.GothamMedium,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    local WeightOrderButton
    WeightOrderButton = CreateButton(MergeCard, "Highest KG first ▼", function()
        WeightOrder = WeightOrder == "Highest KG first" and "Lowest KG first" or "Highest KG first"
        WeightOrderButton.Text = WeightOrder .. " ▼"
    end)
    WeightOrderButton.Position = UDim2.fromOffset(11, 102)
    WeightOrderButton.Size = UDim2.new(1, -22, 0, 24)

    MergeStatus = Create("TextLabel", {
        Parent = MergeCard,
        Position = UDim2.fromOffset(11, 134),
        Size = UDim2.new(1, -22, 0, 30),
        BackgroundTransparency = 1,
        Text = "Off — choose an animal filter and weight priority.",
        TextColor3 = Theme.Gray,
        Font = Enum.Font.Gotham,
        TextSize = 8,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top
    })

    -- Keep the status informative without adding a polling connection.
    MergeToggle:GetPropertyChangedSignal("Visible"):Connect(function()
        if not MergeToggle.Visible then
            MergeEnabled = false
            MergeGeneration += 1
        end
    end)
end
