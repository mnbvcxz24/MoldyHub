-- BASAE EVENTS PAGE
return function(Context)
    local index = 3
    local name = "Eggs"
    local Page = CreatePage(index, name)

    -- AUTO MERGE
    local Players = game:GetService("Players")
    local CollectionService = game:GetService("CollectionService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = Players.LocalPlayer
    local MergeRemote = ReplicatedStorage:WaitForChild("MergeMachineRemote")

    local MergeCard = CreateCard(Page, "Auto Merge", "")
    MergeCard.Size = UDim2.new(1, 0, 0, 178)

    -- AUTO PLACE EGGS UI (automation will be added separately)
    local AutoPlaceEggsCard = CreateCard(Page, "Auto place eggs", "")
    AutoPlaceEggsCard.Size = UDim2.new(1, 0, 0, 110)

    local MergeEnabled = false
    local MergeGeneration = 0
    local SelectedAnimalName = "All animals"
    local WeightOrder = "Highest KG first"
    local MergeBusy = false
    local MergeStatus

    local function getOwnedTools()
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        local character = LocalPlayer.Character
        local tools = {}
        local seen = {}

        for _, tool in ipairs(CollectionService:GetTagged("AnimalTool")) do
            local owned = tool:IsA("Tool") and (
                (backpack and tool:IsDescendantOf(backpack))
                or (character and tool:IsDescendantOf(character))
            )
            if owned and not seen[tool] then
                seen[tool] = true
                table.insert(tools, tool)
            end
        end

        return tools, backpack
    end

    local function readWeight(tool)
        local attributeNames = {"WeightKg", "WeightKG", "weightKg", "weightKG", "Weight", "weight"}
        for _, attributeName in ipairs(attributeNames) do
            local value = tool:GetAttribute(attributeName)
            if value ~= nil then
                local cleaned = tostring(value):gsub(",", "")
                cleaned = cleaned:gsub("%s*[Kk][Gg]%s*$", "")
                local number = tonumber(cleaned:match("^%s*(.-)%s*$"))
                if number then return number end
            end
        end

        for _, childName in ipairs(attributeNames) do
            local valueObject = tool:FindFirstChild(childName, true)
            if valueObject and (valueObject:IsA("NumberValue") or valueObject:IsA("IntValue") or valueObject:IsA("StringValue")) then
                local cleaned = tostring(valueObject.Value):gsub(",", "")
                cleaned = cleaned:gsub("%s*[Kk][Gg]%s*$", "")
                local number = tonumber(cleaned:match("^%s*(.-)%s*$"))
                if number then return number end
            end
        end
        return nil
    end

    local function scanGroups()
        local tools = getOwnedTools()
        local groups = {}
        local totalOwned = 0

        for _, tool in ipairs(tools) do
            totalOwned += 1
            local animalName = tool:GetAttribute("AnimalName")
            if typeof(animalName) == "string" and animalName ~= "" then
                if SelectedAnimalName == "All animals" or animalName == SelectedAnimalName then
                    groups[animalName] = groups[animalName] or {}
                    table.insert(groups[animalName], {
                        Tool = tool,
                        Weight = readWeight(tool)
                    })
                end
            end
        end

        return groups, totalOwned
    end

    local MergeToggle = CreateToggle(MergeCard, "", false, function(enabled)
        MergeEnabled = enabled
        MergeGeneration += 1
        local generation = MergeGeneration

        if not enabled then
            if MergeStatus then MergeStatus.Text = "Off — automation stopped." end
            return
        end

        if MergeStatus then
            MergeStatus.Text = "Running — scanning owned animals..."
        end

        task.spawn(function()
            while MergeEnabled and generation == MergeGeneration do
                if MergeBusy then
                    task.wait(0.2)
                    continue
                end

                MergeBusy = true
                local groups, totalOwned = scanGroups()
                local chosenName, chosenGroup

                for animalName, animals in pairs(groups) do
                    if #animals >= 3 then
                        table.sort(animals, function(a, b)
                            -- Animals without readable KG stay behind known weights.
                            if a.Weight == nil then return false end
                            if b.Weight == nil then return true end
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
                    if MergeStatus then
                        local matchingCount = 0
                        for _, animals in pairs(groups) do
                            matchingCount = math.max(matchingCount, #animals)
                        end
                        MergeStatus.Text = string.format(
                            "Scanning — %d owned animals, largest matching group: %d/3.",
                            totalOwned,
                            matchingCount
                        )
                    end
                    MergeBusy = false
                    task.wait(1)
                else
                    local mergeList = {}
                    local _, backpack = getOwnedTools()
                    local character = LocalPlayer.Character

                    for slot = 1, 3 do
                        local item = chosenGroup[slot]
                        local tool = item and item.Tool
                        local stillOwned = tool and tool:IsA("Tool") and (
                            (backpack and tool:IsDescendantOf(backpack))
                            or (character and tool:IsDescendantOf(character))
                        )
                        if not stillOwned then
                            table.clear(mergeList)
                            break
                        end
                        table.insert(mergeList, tool)
                    end

                    if #mergeList == 3 and MergeEnabled and generation == MergeGeneration then
                        if MergeStatus then
                            MergeStatus.Text = "Merging 3 " .. chosenName .. "..."
                        end

                        local before = {}
                        for _, tool in ipairs(mergeList) do before[tool] = true end

                        local ok, err = pcall(function()
                            MergeRemote:FireServer("Merge", mergeList)
                        end)

                        if not ok then
                            warn("[BASAE Auto Merge] Remote call failed:", err)
                            MergeEnabled = false
                            MergeGeneration += 1
                            if MergeStatus then MergeStatus.Text = "Stopped — remote call failed. Check console." end
                        else
                            print("[BASAE Auto Merge] Merge request sent:", chosenName)
                            local changed = false

                            for _ = 1, 40 do
                                if not MergeEnabled or generation ~= MergeGeneration then break end
                                task.wait(0.1)

                                local currentTools = getOwnedTools()
                                local currentSet = {}
                                for _, tool in ipairs(currentTools) do currentSet[tool] = true end

                                for tool in pairs(before) do
                                    if not currentSet[tool] then
                                        changed = true
                                        break
                                    end
                                end
                                if changed then break end
                            end

                            if not changed and MergeEnabled and generation == MergeGeneration then
                                warn("[BASAE Auto Merge] No inventory change detected after merge request.")
                                MergeEnabled = false
                                MergeGeneration += 1
                                if MergeStatus then
                                    MergeStatus.Text = "Stopped — merge request sent, but inventory did not update."
                                end
                            elseif changed and MergeEnabled and generation == MergeGeneration then
                                if MergeStatus then MergeStatus.Text = "Merge confirmed — scanning for next group..." end
                            end
                        end
                    end

                    MergeBusy = false
                    task.wait(0.5)
                end
            end
            MergeBusy = false
        end)
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

    -- Use a dedicated high-ZIndex popup on ScreenGui so the options are not
    -- hidden behind the Events page columns or clipped by the card.
    local AnimalFilterButton = Create("TextButton", {
        Parent = MergeCard,
        Position = UDim2.fromOffset(11, 55),
        Size = UDim2.new(1, -22, 0, 28),
        BackgroundColor3 = Theme.SurfaceInput,
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
        ZIndex = 20
    })
    AddCorner(AnimalFilterButton, 6)
    AddStroke(AnimalFilterButton, Theme.Border, 1)

    local AnimalFilterCurrent = Create("TextLabel", {
        Parent = AnimalFilterButton,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -35, 1, 0),
        BackgroundTransparency = 1,
        Text = "Animal: All animals",
        TextColor3 = Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 21
    })
    Create("TextLabel", {
        Parent = AnimalFilterButton,
        Position = UDim2.new(1, -25, 0, 0),
        Size = UDim2.fromOffset(20, 28),
        BackgroundTransparency = 1,
        Text = "v",
        TextColor3 = Theme.Gray,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        ZIndex = 21
    })

    local FilterPopup

    local function closeAnimalFilter()
        if FilterPopup then
            FilterPopup:Destroy()
            FilterPopup = nil
        end
    end

    AnimalFilterButton.MouseButton1Click:Connect(function()
        if FilterPopup then
            closeAnimalFilter()
            return
        end

        local names = {}
        local seen = {}
        local tools = getOwnedTools()
        for _, tool in ipairs(tools) do
            local animalName = tool:GetAttribute("AnimalName")
            if typeof(animalName) == "string" and animalName ~= "" and not seen[animalName] then
                seen[animalName] = true
                table.insert(names, animalName)
            end
        end
        table.sort(names)

        local options = {"All animals"}
        for _, animalName in ipairs(names) do
            table.insert(options, animalName)
        end

        local buttonPosition = AnimalFilterButton.AbsolutePosition
        local buttonSize = AnimalFilterButton.AbsoluteSize
        FilterPopup = Create("ScrollingFrame", {
            Name = "BASAEAnimalFilterPopup",
            Parent = ScreenGui,
            Position = UDim2.fromOffset(buttonPosition.X, buttonPosition.Y + buttonSize.Y + 5),
            Size = UDim2.fromOffset(buttonSize.X, math.min(160, #options * 26)),
            BackgroundColor3 = Theme.SurfaceInput,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Theme.Gray,
            CanvasSize = UDim2.fromOffset(0, #options * 26),
            ZIndex = 500,
            Active = true
        })
        AddCorner(FilterPopup, 6)
        AddStroke(FilterPopup, Theme.Border, 1)

        for optionIndex, option in ipairs(options) do
            local optionButton = Create("TextButton", {
                Parent = FilterPopup,
                Position = UDim2.fromOffset(0, (optionIndex - 1) * 26),
                Size = UDim2.new(1, -4, 0, 26),
                BackgroundTransparency = 1,
                Text = option,
                TextColor3 = Theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 9,
                BorderSizePixel = 0,
                LayoutOrder = optionIndex,
                ZIndex = 501,
                Active = true,
                AutoButtonColor = true
            })
            optionButton.MouseButton1Click:Connect(function()
                SelectedAnimalName = option
                AnimalFilterCurrent.Text = "Animal: " .. option
                closeAnimalFilter()
                if MergeStatus and not MergeEnabled then
                    MergeStatus.Text = "Off — selected filter: " .. option
                end
            end)
        end
    end)

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

    MergeToggle:GetPropertyChangedSignal("Visible"):Connect(function()
        if not MergeToggle.Visible then
            MergeEnabled = false
            MergeGeneration += 1
            closeAnimalFilter()
        end
    end)
end
