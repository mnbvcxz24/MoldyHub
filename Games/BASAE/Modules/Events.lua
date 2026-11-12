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

    -- AUTO PLACE EGGS
    local AutoPlaceEggsCard = CreateCard(Page, "Auto place eggs", "")
    AutoPlaceEggsCard.Size = UDim2.new(1, 0, 0, 166)
    local RunService = game:GetService("RunService")
    local AutoPlaceEggsEnabled = false
    local AutoPlaceEggsGeneration = 0
    local AutoPlaceEggsBusy = false
    local EggWeightOrder = "Highest KG first"
    local AutoPlaceEggsStatus = Create("TextLabel", {
        Parent = AutoPlaceEggsCard,
        Position = UDim2.fromOffset(11, 96),
        Size = UDim2.new(1, -22, 0, 58),
        BackgroundTransparency = 1,
        Text = "Off — scans your backpack and places eggs across your plot.",
        TextColor3 = Theme.Gray,
        Font = Enum.Font.Gotham,
        TextSize = 8,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top
    })

    local EggWeightOrderButton
    EggWeightOrderButton = CreateButton(AutoPlaceEggsCard, "Highest KG first ▼", function()
        EggWeightOrder = EggWeightOrder == "Highest KG first" and "Lowest KG first" or "Highest KG first"
        EggWeightOrderButton.Text = EggWeightOrder .. " ▼"
    end)
    EggWeightOrderButton.Position = UDim2.fromOffset(11, 57)
    EggWeightOrderButton.Size = UDim2.new(1, -22, 0, 26)

    local function sortBackpackEggs(eggs)
        table.sort(eggs, function(a, b)
            local weightA = tonumber(a:GetAttribute("WeightKg"))
            local weightB = tonumber(b:GetAttribute("WeightKg"))

            -- Eggs without a readable WeightKg are kept after eggs with a known weight.
            if weightA == nil then return false end
            if weightB == nil then return true end
            if weightA == weightB then return a.Name < b.Name end

            if EggWeightOrder == "Highest KG first" then
                return weightA > weightB
            end
            return weightA < weightB
        end)
        return eggs
    end

    local function getMyEggPlot()
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return nil end
        for _, plot in ipairs(plots:GetChildren()) do
            local hitbox = plot:FindFirstChild("Hitbox")
            local playerInfo = hitbox and hitbox:FindFirstChild("PlayerInfoUi")
            local nameLabel = playerInfo and playerInfo:FindFirstChild("Name")
            if nameLabel and nameLabel:IsA("TextLabel") and nameLabel.Text == "Your Base" then
                return plot, hitbox
            end
        end
        return nil
    end

    local function getBackpackEggs()
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        local eggs = {}
        if not backpack then return eggs end
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and item.Name:lower():find("egg", 1, true) then
                table.insert(eggs, item)
            end
        end
        return eggs
    end

    local function getPlacedEggs(plot)
        local placed = {}
        for _, descendant in ipairs(plot:GetDescendants()) do
            if descendant.Name:sub(1, 9) == "MergeEgg_" and (descendant:IsA("Model") or descendant:IsA("BasePart")) then
                local boundsCFrame, boundsSize
                pcall(function()
                    if descendant:IsA("Model") then
                        boundsCFrame, boundsSize = descendant:GetBoundingBox()
                    else
                        boundsCFrame, boundsSize = descendant.CFrame, descendant.Size
                    end
                end)
                if boundsCFrame and boundsSize then
                    table.insert(placed, {
                        Instance = descendant,
                        Position = boundsCFrame.Position,
                        CFrame = boundsCFrame,
                        Size = boundsSize
                    })
                end
            end
        end
        return placed
    end

    local function getEggFootprint(egg)
        local size
        pcall(function()
            local _, boundsSize = egg:GetBoundingBox()
            size = boundsSize
        end)
        if not size then
            local largestX, largestZ = 0, 0
            for _, descendant in ipairs(egg:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    largestX = math.max(largestX, descendant.Size.X)
                    largestZ = math.max(largestZ, descendant.Size.Z)
                end
            end
            size = Vector3.new(largestX, 0, largestZ)
        end
        return math.max(0.75, size.X * 0.5), math.max(0.75, size.Z * 0.5)
    end

    local function buildEggPositions(hitbox, placed, halfX, halfZ)
        -- Use a fine, consistent grid. Existing large eggs only block their
        -- actual footprint; they no longer make the entire grid excessively coarse.
        local step = 2.5
        local edgeX = math.max(0, hitbox.Size.X * 0.5 - halfX - 0.25)
        local edgeZ = math.max(0, hitbox.Size.Z * 0.5 - halfZ - 0.25)
        local y = hitbox.Position.Y + hitbox.Size.Y * 0.5
        if #placed > 0 then y = placed[1].Position.Y end

        local positions = {}
        local x = -edgeX
        while x <= edgeX + 0.01 do
            local z = -edgeZ
            while z <= edgeZ + 0.01 do
                local worldPosition = hitbox.CFrame:PointToWorldSpace(Vector3.new(x, 0, z))
                table.insert(positions, Vector3.new(worldPosition.X, y, worldPosition.Z))
                z += step
            end
            x += step
        end
        return positions, step
    end

    local function findOpenEggPosition(positions, placed, halfX, halfZ, attempted)
        for _, position in ipairs(positions) do
            local key = string.format("%.2f:%.2f", position.X, position.Z)
            if not attempted[key] then
                local occupied = false
                for _, record in ipairs(placed) do
                    local localPosition = record.CFrame:PointToObjectSpace(position)
                    local occupiedHalfX = record.Size.X * 0.5 + halfX + 0.2
                    local occupiedHalfZ = record.Size.Z * 0.5 + halfZ + 0.2
                    if math.abs(localPosition.X) < occupiedHalfX
                        and math.abs(localPosition.Z) < occupiedHalfZ then
                        occupied = true
                        break
                    end
                end
                if not occupied then return position, key end
            end
        end
        return nil
    end

    local function walkToPlotCenter(plot, hitbox, generation)
        local character = LocalPlayer.Character
        if not character then return false, "Character unavailable." end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local root = character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not root or humanoid.Health <= 0 then
            return false, "Character parts unavailable."
        end

        local center = hitbox.Position
        local startedAt = os.clock()
        local lastProgressAt = startedAt
        local bestDistance = math.huge
        local arrived = false
        local connection

        -- Match Farm.lua: drive Humanoid:Move from RenderStepped in world space.
        connection = RunService.RenderStepped:Connect(function()
            if not AutoPlaceEggsEnabled or generation ~= AutoPlaceEggsGeneration
                or LocalPlayer.Character ~= character or not character.Parent
                or not root.Parent or humanoid.Health <= 0 then
                humanoid:Move(Vector3.zero, false)
                if connection then connection:Disconnect(); connection = nil end
                return
            end

            local offset = Vector3.new(center.X - root.Position.X, 0, center.Z - root.Position.Z)
            local distance = offset.Magnitude
            if distance <= 4 then
                arrived = true
                humanoid:Move(Vector3.zero, false)
                if connection then connection:Disconnect(); connection = nil end
                return
            end

            if distance < bestDistance - 0.5 then
                bestDistance = distance
                lastProgressAt = os.clock()
            end
            humanoid:Move(offset.Unit, false)
        end)

        while AutoPlaceEggsEnabled and generation == AutoPlaceEggsGeneration
            and LocalPlayer.Character == character and character.Parent
            and root.Parent and humanoid.Health > 0 do
            if arrived then break end
            if os.clock() - startedAt >= 60 then break end
            if os.clock() - lastProgressAt >= 8 then break end
            task.wait(0.05)
        end

        if connection then connection:Disconnect(); connection = nil end
        if humanoid.Parent then humanoid:Move(Vector3.zero, false) end
        if not AutoPlaceEggsEnabled or generation ~= AutoPlaceEggsGeneration then
            return false, "Stopped."
        end
        if not arrived then
            return false, string.format("Could not reach plot center (%.1f studs away).", (Vector3.new(center.X - root.Position.X, 0, center.Z - root.Position.Z)).Magnitude)
        end
        return true
    end

    local AutoPlaceEggsToggle = CreateToggle(AutoPlaceEggsCard, "", false, function(enabled)
        AutoPlaceEggsEnabled = enabled
        AutoPlaceEggsGeneration += 1
        local generation = AutoPlaceEggsGeneration
        if not enabled then
            if AutoPlaceEggsStatus then AutoPlaceEggsStatus.Text = "Off — automation stopped." end
            return
        end
        if AutoPlaceEggsBusy then
            AutoPlaceEggsEnabled = false
            AutoPlaceEggsGeneration += 1
            if AutoPlaceEggsStatus then AutoPlaceEggsStatus.Text = "Already running — stopping the duplicate request." end
            return
        end

        task.spawn(function()
            if AutoPlaceEggsBusy then return end
            AutoPlaceEggsBusy = true
            local function finish(message)
                AutoPlaceEggsEnabled = false
                AutoPlaceEggsGeneration += 1
                AutoPlaceEggsBusy = false
                if AutoPlaceEggsStatus then AutoPlaceEggsStatus.Text = message end
            end

            local plot, hitbox = getMyEggPlot()
            if not plot or not hitbox or not hitbox:IsA("BasePart") then
                finish("Stopped — couldn't identify your plot and its Hitbox.")
                return
            end
            local eggs = getBackpackEggs()
            if #eggs == 0 then
                finish("No eggs found in your backpack.")
                return
            end

            AutoPlaceEggsStatus.Text = "Walking to the center of your plot before placing eggs..."
            local reached, movementError = walkToPlotCenter(plot, hitbox, generation)
            if not reached then
                finish("Stopped — " .. tostring(movementError))
                return
            end

            local attempted = {}
            local rejectedPosition = nil
            local notifyConnection
            local notifyRemote = ReplicatedStorage:FindFirstChild("Notify")
            if notifyRemote and notifyRemote:IsA("RemoteEvent") then
                notifyConnection = notifyRemote.OnClientEvent:Connect(function(message)
                    if typeof(message) == "string" and message:lower():find("can't place here", 1, true) then
                        rejectedPosition = true
                    end
                end)
            end

            local placedCount = 0
            local function cleanupNotify()
                if notifyConnection then notifyConnection:Disconnect(); notifyConnection = nil end
            end

            while AutoPlaceEggsEnabled and generation == AutoPlaceEggsGeneration do
                plot, hitbox = getMyEggPlot()
                if not plot or not hitbox or not hitbox:IsA("BasePart") then
                    cleanupNotify()
                    finish("Stopped — your plot could no longer be found.")
                    return
                end
                eggs = sortBackpackEggs(getBackpackEggs())
                if #eggs == 0 then break end

                local egg = eggs[1]
                local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
                if not egg or not backpack or not egg:IsDescendantOf(backpack) then
                    task.wait(0.1)
                    continue
                end

                if not MergeRemote or not MergeRemote:IsA("RemoteEvent") then
                    cleanupNotify()
                    finish("Stopped — ReplicatedStorage.MergeMachineRemote is not a RemoteEvent.")
                    return
                end

                local eggPlaced = false
                while AutoPlaceEggsEnabled and generation == AutoPlaceEggsGeneration and not eggPlaced do
                    plot, hitbox = getMyEggPlot()
                    if not plot or not hitbox or not hitbox:IsA("BasePart") then break end

                    local placed = getPlacedEggs(plot)
                    local candidateHalfX, candidateHalfZ = getEggFootprint(egg)
                    local positions = buildEggPositions(hitbox, placed, candidateHalfX, candidateHalfZ)
                    local position, positionKey = findOpenEggPosition(
                        positions, placed, candidateHalfX, candidateHalfZ, attempted
                    )
                    if not position then
                        AutoPlaceEggsStatus.Text = string.format(
                            "No free position found — %d egg(s) placed; %d remain.",
                            placedCount,
                            #getBackpackEggs()
                        )
                        break
                    end

                    attempted[positionKey] = true
                    rejectedPosition = false
                    AutoPlaceEggsStatus.Text = string.format(
                        "Trying %s at a new position — %d placed...",
                        egg.Name,
                        placedCount
                    )
                    print("[BASAE Auto Place Eggs] Trying position:", egg.Name, position)

                    local beforeInstances = {}
                    for _, record in ipairs(placed) do
                        beforeInstances[record.Instance] = true
                    end

                    local ok, err = pcall(function()
                        MergeRemote:FireServer("PlaceEgg", egg, position)
                    end)
                    if not ok then
                        warn("[BASAE Auto Place Eggs] PlaceEgg FireServer failed:", err)
                        cleanupNotify()
                        finish("Stopped — PlaceEgg FireServer failed: " .. tostring(err))
                        return
                    end

                    -- Wait for a new MergeEgg_ near this request. A different egg
                    -- appearing elsewhere must not count as confirmation.
                    local confirmed = false
                    local checkUntil = os.clock() + 8
                    local confirmRadius = math.max(4, candidateHalfX * 2, candidateHalfZ * 2)
                    while AutoPlaceEggsEnabled and generation == AutoPlaceEggsGeneration and os.clock() < checkUntil do
                        task.wait(0.2)
                        local currentPlaced = getPlacedEggs(plot)
                        for _, record in ipairs(currentPlaced) do
                            if not beforeInstances[record.Instance] then
                                local dx = record.Position.X - position.X
                                local dz = record.Position.Z - position.Z
                                if (dx * dx + dz * dz) <= (confirmRadius * confirmRadius) then
                                    confirmed = true
                                    break
                                end
                            end
                        end
                        if confirmed then break end
                    end

                    if confirmed then
                        placedCount += 1
                        eggPlaced = true
                        print("[BASAE Auto Place Eggs] Placement confirmed:", egg.Name, position)
                        task.wait(0.15)
                    else
                        print("[BASAE Auto Place Eggs] No egg detected at position; retrying same egg:", egg.Name)
                        task.wait(rejectedPosition and 0.1 or 0.2)
                    end
                end

                if not eggPlaced then
                    -- No candidate positions remain, or the feature was disabled.
                    break
                end
            end

            cleanupNotify()
            if generation ~= AutoPlaceEggsGeneration then
                AutoPlaceEggsBusy = false
                return
            end
            local remaining = #getBackpackEggs()
            if remaining == 0 then
                finish(string.format("Done — placed %d egg(s). Your backpack is empty.", placedCount))
            elseif not AutoPlaceEggsEnabled then
                AutoPlaceEggsBusy = false
            else
                finish(string.format("Finished scanning — placed %d egg(s); %d egg(s) remain.", placedCount, remaining))
            end
        end)
    end)
    AutoPlaceEggsToggle.Position = UDim2.new(1, -58, 0, 7)
    AutoPlaceEggsToggle.Size = UDim2.fromOffset(48, 24)
    local AutoPlaceEggsTitle = AutoPlaceEggsCard:FindFirstChildWhichIsA("TextLabel")
    if AutoPlaceEggsTitle then AutoPlaceEggsTitle.Size = UDim2.new(1, -78, 0, 22) end
    AutoPlaceEggsToggle:GetPropertyChangedSignal("Visible"):Connect(function()
        if not AutoPlaceEggsToggle.Visible then
            AutoPlaceEggsEnabled = false
            AutoPlaceEggsGeneration += 1
        end
    end)

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
