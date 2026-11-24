-- BASAE ENCHANT PAGE
-- Read-only list of each placed animal and its Enchant attribute.
return function(Context)
    local index = 4
    local name = "Enchant"
    local Page = CreatePage(index, name)
    local EnchantCard = CreateCard(Page, "Placed Animal Enchants", "Shows the Enchant attribute for every animal placed on your plot.")
    -- This is the only card on the Enchant page, so span the full page width.
    EnchantCard.Parent = Page
    EnchantCard.Position = UDim2.fromOffset(10, 10)
    EnchantCard.Size = UDim2.new(1, -20, 0, EnchantCard.Size.Y.Offset)

    -- Find the card description so the summary can sit just beneath its rendered text.
    local DescriptionLabel
    for _, child in ipairs(EnchantCard:GetChildren()) do
        if child:IsA("TextLabel") and child.Text == "Shows the Enchant attribute for every animal placed on your plot." then
            DescriptionLabel = child
            break
        end
    end

    local function GetSummaryTop()
        if not DescriptionLabel then return 62 end
        local renderedHeight = math.min(DescriptionLabel.Size.Y.Offset, DescriptionLabel.TextBounds.Y)
        return DescriptionLabel.Position.Y.Offset + renderedHeight + 5
    end

    -- Aggregate enchant effects from every placed animal and show them directly below the description.
    local Summary = Create("Frame", {
        Name = "EnchantEffectSummary",
        Parent = EnchantCard,
        Position = UDim2.fromOffset(11, GetSummaryTop()),
        Size = UDim2.new(1, -22, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    })
    local SummaryLayout = Create("UIListLayout", {
        Parent = Summary,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Wraps = true
    })

    local function GetEnchantDefinitions()
        local definitions = {}
        local replicatedStorage = game:GetService("ReplicatedStorage")
        local shared = replicatedStorage:FindFirstChild("Shared")
        local configModule = shared and shared:FindFirstChild("EnchantConfig")
        if not configModule then
            warn("[BASAE Enchant] EnchantConfig module not found")
            return definitions
        end

        local ok, config = pcall(require, configModule)
        if not ok or type(config) ~= "table" then
            warn("[BASAE Enchant] Failed to require EnchantConfig:", config)
            return definitions
        end

        -- Each section (AnimalCash, AnimalLuck, etc.) contains the actual
        -- enchant entries in its Enchants array. Index those individual entries,
        -- not the section itself, and include only sections for Animals.
        for _, section in pairs(config.Sections or {}) do
            if type(section) == "table"
                and section.Kind == "Animals"
                and type(section.Enchants) == "table" then
                for _, enchant in ipairs(section.Enchants) do
                    if type(enchant) == "table"
                        and enchant.Id ~= nil
                        and type(enchant.Tiers) == "table" then
                        definitions[tostring(enchant.Id)] = enchant
                    end
                end
            end
        end
        local ids = {}
        for id in pairs(definitions) do
            ids[#ids + 1] = id
        end
        table.sort(ids)
        print("[BASAE Enchant] Loaded", #ids, "enchant definitions:", table.concat(ids, ", "))
        return definitions
    end

    local EnchantDefinitions = GetEnchantDefinitions()

    -- UI-only Auto Enchant planner. It stores the requested tier and count per enchant;
    -- no enchant remote or automation is triggered by these controls.
    local AutoEnchantCard
    AutoEnchantCard = CreateCard(Page, "Auto Enchant", "Choose the tier and how many placed animals should receive each enchant.")
    AutoEnchantCard.Parent = Page
    AutoEnchantCard.Position = UDim2.fromOffset(10, EnchantCard.Position.Y.Offset + EnchantCard.Size.Y.Offset + 10)
    AutoEnchantCard.Size = UDim2.new(1, -20, 0, 100)

    local PlannerLimit = 0
    local PlannerSelections = {}
    local PlannerRows = {}
    local PlannerTotalLabel
    local PlannerLimitLabel
    local PlannerRowsFrame
    local PlannerRowHeight = 38

    local function GetTierData(definition, requestedTier)
        local tiers = definition and definition.Tiers
        if type(tiers) ~= "table" then return nil end
        return tiers[requestedTier]
    end

    local function GetTierNumbers(definition)
        local tiers = {}
        local tierData = definition and definition.Tiers
        if type(tierData) == "table" then
            for tierNumber, value in ipairs(tierData) do
                if type(value) == "table" then
                    tiers[#tiers + 1] = tierNumber
                end
            end
        end
        return tiers
    end

    local function GetPlannerTotal()
        local total = 0
        for _, selection in pairs(PlannerSelections) do
            total = total + (selection.Count or 0)
        end
        return total
    end

    local function RefreshPlannerSummary()
        local total = GetPlannerTotal()
        if PlannerLimitLabel then
            PlannerLimitLabel.Text = "Placed Animals: " .. tostring(PlannerLimit)
        end
        if PlannerTotalLabel then
            PlannerTotalLabel.Text = "Total Enchants: " .. tostring(total) .. " / " .. tostring(PlannerLimit)
            PlannerTotalLabel.TextColor3 = total > PlannerLimit and Color3.fromRGB(255, 105, 105) or Theme.Accent
        end
    end

    local function MakeAdjustButton(parent, text, x, callback)
        local button = Create("TextButton", {
            Parent = parent,
            Position = UDim2.fromOffset(x, 0),
            Size = UDim2.fromOffset(20, 20),
            BackgroundColor3 = Theme.Selected,
            Text = text,
            TextColor3 = Theme.SelectedText,
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            BorderSizePixel = 0,
            AutoButtonColor = true
        })
        AddCorner(button, 4)
        button.MouseButton1Click:Connect(callback)
        return button
    end

    -- Both controls share identical centered spacing and alignment.
    local function MakePlannerControlGroup(parent, labelText, valueText, onDecrease, onIncrease)
        local controls = Create("Frame", {
            Parent = parent,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(116, 20),
            BackgroundTransparency = 1
        })
        Create("TextLabel", {
            Parent = controls,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromOffset(40, 20),
            BackgroundTransparency = 1,
            Text = labelText,
            TextColor3 = Theme.Gray,
            Font = Enum.Font.Gotham,
            TextSize = 8,
            TextXAlignment = Enum.TextXAlignment.Right
        })
        MakeAdjustButton(controls, "-", 44, onDecrease)
        local valueLabel = Create("TextLabel", {
            Parent = controls,
            Position = UDim2.fromOffset(68, 0),
            Size = UDim2.fromOffset(22, 20),
            BackgroundTransparency = 1,
            Text = valueText,
            TextColor3 = Theme.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Center
        })
        MakeAdjustButton(controls, "+", 94, onIncrease)
        return valueLabel
    end
    local function BuildPlannerRows()
        for _, child in ipairs(PlannerRowsFrame:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
        end
        table.clear(PlannerRows)

        local ids = {}
        for id in pairs(EnchantDefinitions) do ids[#ids + 1] = id end
        table.sort(ids, function(a, b) return a:lower() < b:lower() end)

        for order, enchantId in ipairs(ids) do
            local definition = EnchantDefinitions[enchantId]
            local tiers = GetTierNumbers(definition)
            if #tiers > 0 then
                local selection = PlannerSelections[enchantId]
                if not selection then
                    selection = {Tier = tiers[1], Count = 0}
                    PlannerSelections[enchantId] = selection
                end
                if not table.find(tiers, selection.Tier) then selection.Tier = tiers[1] end

                local row = Create("Frame", {
                    Name = "AutoEnchant_" .. enchantId,
                    Parent = PlannerRowsFrame,
                    Position = UDim2.fromOffset(0, (order - 1) * PlannerRowHeight),
                    Size = UDim2.new(1, 0, 0, PlannerRowHeight - 3),
                    BackgroundColor3 = Theme.SurfaceInput,
                    BorderSizePixel = 0,
                    ClipsDescendants = true,
                    LayoutOrder = order
                })
                AddCorner(row, 5)
                AddStroke(row, Theme.Border, 1)

                Create("TextLabel", {
                    Parent = row,
                    Position = UDim2.fromOffset(8, 0),
                    Size = UDim2.new(0.40, -16, 1, 0),
                    BackgroundTransparency = 1,
                    Text = tostring(definition.Name or enchantId),
                    TextColor3 = Theme.Text,
                    Font = Enum.Font.GothamSemibold,
                    TextSize = 8,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd
                })

                local tierGroup = Create("Frame", {
                    Parent = row,
                    Position = UDim2.new(0.40, 0, 0, 0),
                    Size = UDim2.new(0.30, 0, 1, 0),
                    BackgroundTransparency = 1
                })
                local tierValue
                tierValue = MakePlannerControlGroup(tierGroup, "Tier", tostring(selection.Tier), function()
                    local currentIndex = table.find(tiers, selection.Tier) or 1
                    selection.Tier = tiers[math.max(1, currentIndex - 1)]
                    tierValue.Text = tostring(selection.Tier)
                end, function()
                    local currentIndex = table.find(tiers, selection.Tier) or 1
                    selection.Tier = tiers[math.min(#tiers, currentIndex + 1)]
                    tierValue.Text = tostring(selection.Tier)
                end)

                local countGroup = Create("Frame", {
                    Parent = row,
                    Position = UDim2.new(0.70, 0, 0, 0),
                    Size = UDim2.new(0.30, 0, 1, 0),
                    BackgroundTransparency = 1
                })
                local countValue
                local function SetCount(nextCount)
                    local otherTotal = GetPlannerTotal() - selection.Count
                    local maximum = math.max(0, PlannerLimit - otherTotal)
                    selection.Count = math.clamp(nextCount, 0, maximum)
                    countValue.Text = tostring(selection.Count)
                    RefreshPlannerSummary()
                end
                countValue = MakePlannerControlGroup(countGroup, "Enchant", tostring(selection.Count), function()
                    SetCount(selection.Count - 1)
                end, function()
                    SetCount(selection.Count + 1)
                end)

                PlannerRows[enchantId] = {Tier = tierValue, Count = countValue}
            end
        end

        PlannerRowsFrame.Size = UDim2.new(1, 0, 0, #PlannerRowsFrame:GetChildren() * PlannerRowHeight)
        AutoEnchantCard.Size = UDim2.new(1, -20, 0, 94 + PlannerRowsFrame.Size.Y.Offset)
        RefreshPlannerSummary()
        -- Layout is refreshed after UpdateEnchantLayout is declared and the animal list exists.
    end

    PlannerLimitLabel = Create("TextLabel", {
        Name = "PlacedAnimalLimit",
        Parent = AutoEnchantCard,
        Position = UDim2.fromOffset(11, 62),
        Size = UDim2.new(0.5, -11, 0, 16),
        BackgroundTransparency = 1,
        Text = "Placed Animals: 0",
        TextColor3 = Theme.Gray,
        Font = Enum.Font.GothamSemibold,
        TextSize = 8,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    PlannerTotalLabel = Create("TextLabel", {
        Name = "AutoEnchantTotal",
        Parent = AutoEnchantCard,
        Position = UDim2.new(0.5, 0, 0, 62),
        Size = UDim2.new(0.5, -11, 0, 16),
        BackgroundTransparency = 1,
        Text = "Total Enchants: 0 / 0",
        TextColor3 = Theme.Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 8,
        TextXAlignment = Enum.TextXAlignment.Right
    })
    PlannerRowsFrame = Create("Frame", {
        Name = "AutoEnchantRows",
        Parent = AutoEnchantCard,
        Position = UDim2.fromOffset(11, 84),
        Size = UDim2.new(1, -22, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    })
    BuildPlannerRows()

    local function CollectAnimalEnchantEffects(enchantValue, totals, animalName)
        if type(enchantValue) ~= "string" or enchantValue == "" then
            return
        end

        local entries = {}
        local decoded
        if enchantValue:sub(1, 1) == "{" or enchantValue:sub(1, 1) == "[" then
            local ok, result = pcall(function()
                return game:GetService("HttpService"):JSONDecode(enchantValue)
            end)
            if ok then
                decoded = result
            else
                warn("[BASAE Enchant] JSON decode failed for", animalName, enchantValue, result)
            end
        end

        local function AddEntry(id, tier)
            local numericTier = tonumber(tier)
            if id == nil or not numericTier then return end
            entries[#entries + 1] = {
                Id = tostring(id),
                Tier = math.floor(numericTier)
            }
        end

        local function ReadDecoded(value)
            if type(value) ~= "table" then return end
            if value.Id ~= nil and (value.Tier ~= nil or value.Level ~= nil) then
                AddEntry(value.Id, value.Tier or value.Level)
                return
            end
            for key, item in pairs(value) do
                if type(item) == "table" then
                    ReadDecoded(item)
                elseif type(item) == "number" or type(item) == "string" then
                    AddEntry(key, item)
                end
            end
        end

        if decoded then
            ReadDecoded(decoded)
        else
            for id, tier in enchantValue:gmatch("([%w_%-]+)%s*:%s*(%d+)") do
                AddEntry(id, tier)
            end
        end

        if #entries == 0 then
            warn("[BASAE Enchant] No enchant entries parsed for", animalName, "raw:", enchantValue)
            return
        end

        for _, entry in ipairs(entries) do
            local definition = EnchantDefinitions[entry.Id]
            local tierData = GetTierData(definition, entry.Tier)

            if type(tierData) == "table" then
                print("[BASAE Enchant] Matched", animalName, entry.Id .. ":" .. entry.Tier)
                for effectName, effectValue in pairs(tierData) do
                    if effectName ~= "Chance" and type(effectValue) == "number" then
                        totals[tostring(effectName)] = (totals[tostring(effectName)] or 0) + effectValue
                        print("[BASAE Enchant] Added effect:", effectName, effectValue, "from", animalName)
                    end
                end
            else
                warn("[BASAE Enchant] No config match for", animalName, entry.Id .. ":" .. entry.Tier,
                    "definition found:", definition ~= nil)
            end
        end
    end

    local function FormatPercent(value)
        local percent = value * 100
        if math.abs(percent - math.floor(percent + 0.5)) < 0.0001 then
            return tostring(math.floor(percent + 0.5)) .. "%"
        end
        return string.format("%.1f%%", percent)
    end

    local function UpdateSummary(animals)
        for _, child in ipairs(Summary:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
        end

        local totals = {}
        print("[BASAE Enchant] Recalculating totals for", #animals, "placed animals")
        for _, animal in ipairs(animals) do
            -- Animals without enchant data do not contribute to the effect totals.
            local enchantValue = animal.Enchant
            if enchantValue ~= nil and enchantValue ~= "" then
                CollectAnimalEnchantEffects(enchantValue, totals, animal.Name)
            end
        end

        local effectNames = {}
        for effectName in pairs(totals) do
            effectNames[#effectNames + 1] = effectName
        end
        table.sort(effectNames, function(a, b) return a:lower() < b:lower() end)

        for index, effectName in ipairs(effectNames) do
            local hash = 0
            for charIndex = 1, #effectName do
                hash = (hash * 31 + string.byte(effectName, charIndex)) % 360
            end
            local hue = hash / 360
            local chip = Create("Frame", {
                Name = "EnchantEffect_" .. effectName,
                Parent = Summary,
                Size = UDim2.fromOffset(112, 20),
                BackgroundColor3 = Color3.fromHSV(hue, 0.58, 0.28),
                BorderSizePixel = 0,
                LayoutOrder = index
            })
            AddCorner(chip, 5)
            AddStroke(chip, Color3.fromHSV(hue, 0.65, 0.62), 1)
            Create("TextLabel", {
                Parent = chip,
                Position = UDim2.fromOffset(6, 0),
                Size = UDim2.new(1, -12, 1, 0),
                BackgroundTransparency = 1,
                Text = effectName .. " - " .. FormatPercent(totals[effectName]),
                TextColor3 = Color3.fromHSV(hue, 0.35, 1),
                Font = Enum.Font.GothamSemibold,
                TextSize = 8,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextTruncate = Enum.TextTruncate.AtEnd
            })
        end
    end

    local Status, List

    local function UpdateEnchantLayout()
        if not Status or not List or not Status.Parent or not List.Parent then return end

        local summaryTop = GetSummaryTop()
        Summary.Position = UDim2.fromOffset(11, summaryTop)
        local summaryHeight = math.max(20, SummaryLayout.AbsoluteContentSize.Y)
        local statusY = summaryTop + summaryHeight + 5
        Status.Position = UDim2.fromOffset(11, statusY)
        local listY = statusY + 21
        List.Position = UDim2.fromOffset(11, listY)
        EnchantCard.Size = UDim2.new(1, -20, 0, listY + List.Size.Y.Offset + 10)

        if AutoEnchantCard and AutoEnchantCard.Parent then
            AutoEnchantCard.Position = UDim2.fromOffset(10, EnchantCard.Position.Y.Offset + EnchantCard.Size.Y.Offset + 10)
        end
    end
    SummaryLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateEnchantLayout)
    if DescriptionLabel then
        DescriptionLabel:GetPropertyChangedSignal("TextBounds"):Connect(UpdateEnchantLayout)
        DescriptionLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateEnchantLayout)
    end

    Status = Create("TextLabel", {
        Name = "EnchantStatus",
        Parent = EnchantCard,
        Position = UDim2.fromOffset(11, 86),
        Size = UDim2.new(1, -22, 0, 16),
        BackgroundTransparency = 1,
        Text = "Scanning placed animals...",
        TextColor3 = Theme.Gray,
        Font = Enum.Font.Gotham,
        TextSize = 8,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    List = Create("Frame", {
        Name = "EnchantAnimalList",
        Parent = EnchantCard,
        Position = UDim2.fromOffset(11, 107),
        Size = UDim2.new(1, -22, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    })
    local RowHeight = 28
    local RowGap = 4
    local ColumnGap = 8
    -- Start the animal entries directly beneath the status line.
    List.Position = UDim2.fromOffset(11, 80)

    local function FindOwnedPlot()
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return nil end

        for _, plot in ipairs(plots:GetChildren()) do
            local ownerUserId = plot:GetAttribute("userID")
            if tonumber(ownerUserId) == LocalPlayer.UserId then
                return plot
            end

            local hitbox = plot:FindFirstChild("Hitbox")
            local playerInfo = hitbox and hitbox:FindFirstChild("PlayerInfoUi")
            local nameLabel = playerInfo and playerInfo:FindFirstChild("Name")
            if nameLabel and nameLabel:IsA("TextLabel") and nameLabel.Text == "Your Base" then
                return plot
            end
        end
        return nil
    end

    local function ReadAnimalCPS(animal)
        local rootPart = animal and animal:FindFirstChild("RootPart")
        local attachment = rootPart and rootPart:FindFirstChild("AnimalOverheadAttachment")
        local overhead = attachment and attachment:FindFirstChild("AnimalOverhead")
        local cpsContainer = overhead and overhead:FindFirstChild("CashPerSecond")
        local cpsLabel = cpsContainer and cpsContainer:FindFirstChild("CashPerSecond")

        if cpsLabel and (cpsLabel:IsA("TextLabel") or cpsLabel:IsA("TextButton") or cpsLabel:IsA("TextBox")) then
            return cpsLabel.Text
        end
        return "—"
    end

    local function ReadPlacedAnimals()
        local plot = FindOwnedPlot()
        local placedAnimals = plot and plot:FindFirstChild("PlacedAnimals")
        local animals = {}

        if placedAnimals then
            for _, animal in ipairs(placedAnimals:GetChildren()) do
                table.insert(animals, {
                    Name = animal.Name,
                    Enchant = animal:GetAttribute("Enchant"),
                    CashPerSecond = ReadAnimalCPS(animal)
                })
            end
        end

        table.sort(animals, function(a, b)
            if a.Name == b.Name then
                return tostring(a.Enchant or "") < tostring(b.Enchant or "")
            end
            return a.Name:lower() < b.Name:lower()
        end)

        return animals, placedAnimals ~= nil
    end

    local function RefreshList()
        local animals, hasPlacedFolder = ReadPlacedAnimals()
        local signatureParts = {hasPlacedFolder and "folder" or "no-folder"}
        for _, animal in ipairs(animals) do
            table.insert(signatureParts, animal.Name .. "\31" .. tostring(animal.Enchant) .. "\31" .. tostring(animal.CashPerSecond))
        end
        local signature = table.concat(signatureParts, "\30")
        if signature == List:GetAttribute("DataSignature") then return end
        List:SetAttribute("DataSignature", signature)

        for _, child in ipairs(List:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
        end

        Status.Text = tostring(#animals) .. " placed animal" .. (#animals == 1 and "" or "s")
        PlannerLimit = #animals
        local remaining = PlannerLimit
        for _, id in ipairs((function()
            local keys = {}
            for key in pairs(PlannerSelections) do keys[#keys + 1] = key end
            table.sort(keys)
            return keys
        end)()) do
            local selection = PlannerSelections[id]
            selection.Count = math.min(selection.Count or 0, remaining)
            remaining = math.max(0, remaining - selection.Count)
            local rowRefs = PlannerRows[id]
            if rowRefs and rowRefs.Count then rowRefs.Count.Text = tostring(selection.Count) end
        end
        RefreshPlannerSummary()
        UpdateSummary(animals)

        local function CreateRow(animalName, enchantValue, cashPerSecond, order)
            local column = order <= 8 and 0 or 1
            local rowIndex = order <= 8 and (order - 1) or (order - 9)
            local row = Create("Frame", {
                Name = "AnimalEnchantRow",
                Parent = List,
                Position = UDim2.new(column * 0.5, column == 1 and (ColumnGap / 2) or 0, 0, rowIndex * (RowHeight + RowGap)),
                Size = UDim2.new(0.5, -(ColumnGap / 2), 0, RowHeight),
                BackgroundColor3 = Theme.SurfaceInput,
                BorderSizePixel = 0,
                LayoutOrder = order
            })
            AddCorner(row, 5)
            AddStroke(row, Theme.Border, 1)

            Create("TextLabel", {
                Parent = row,
                Position = UDim2.fromOffset(8, 0),
                Size = UDim2.new(0.42, -8, 1, 0),
                BackgroundTransparency = 1,
                Text = animalName,
                TextColor3 = Theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 8,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd
            })
            Create("TextLabel", {
                Parent = row,
                Position = UDim2.new(0.42, 0, 0, 0),
                Size = UDim2.new(0.32, -4, 1, 0),
                BackgroundTransparency = 1,
                Text = enchantValue,
                TextColor3 = Theme.Accent,
                Font = Enum.Font.GothamSemibold,
                TextSize = 8,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextTruncate = Enum.TextTruncate.AtEnd
            })
            Create("TextLabel", {
                Parent = row,
                Position = UDim2.new(0.74, 0, 0, 0),
                Size = UDim2.new(0.26, -8, 1, 0),
                BackgroundTransparency = 1,
                Text = cashPerSecond,
                TextColor3 = Theme.Text,
                Font = Enum.Font.GothamSemibold,
                TextSize = 8,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextTruncate = Enum.TextTruncate.AtEnd
            })
        end

        if #animals == 0 then
            CreateRow(hasPlacedFolder and "No placed animals found" or "Your plot was not found", "—", "—", 1)
        else
            for index, animal in ipairs(animals) do
                CreateRow(animal.Name, animal.Enchant == nil and "None" or tostring(animal.Enchant), animal.CashPerSecond or "—", index)
            end
        end

        local visibleRows = math.max(8, #animals > 8 and (#animals - 8) or 0, #animals == 0 and 1 or 0)
        List.Size = UDim2.new(1, -22, 0, visibleRows * RowHeight + math.max(0, visibleRows - 1) * RowGap)
        task.defer(UpdateEnchantLayout)
    end

    task.spawn(function()
        while not Runtime.Stopped and Page.Parent do
            local success, err = pcall(RefreshList)
            if not success then
                Status.Text = "Unable to read placed animals"
                warn("[BASAE Enchant] Refresh failed:", err)
            end
            task.wait(0.5)
        end
    end)
end
