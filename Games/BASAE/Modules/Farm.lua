-- ORIGINAL BASAE FARM PAGE
-- Isolated in its own initializer to keep its local-register usage separate from Core.
return function(Context)
    local index = 2
    local name = "Farm"
    local Page = CreatePage(index, name)
    local AutoRow = Create("Frame", {
        Name = "AutoControlsRow",
        Parent = Page,
        Position = UDim2.fromOffset(10, 10),
        Size = UDim2.new(1, -20, 0, 350),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = 1
    })
    local Card1 = CreateCard(AutoRow, "Auto Break", "")
    Card1.Position = UDim2.new(0.5, 5, 0, 0)
    Card1.Size = UDim2.new(0.5, -5, 0, 190)
    local StartAutoBreak
    local StopAutoBreak
    local StopPickupAutomation
    local CompletedEggs = {}
    local LastEggHPValue = nil
    local LastEggHPTarget = nil
    
    local AutoBreakToggleInitialized = false
    local AutoBreakEnabled = false
    local AutoBreakGeneration = 0
    local RefreshEggFilters
    local UpdateAutoBreakFilterButtonTexts
    local TitanicPriorityEnabled = false
    local AutoBreakControlLayout = {
        ZoneY = 42,
        EggY = 81,
        HighLuckY = 126,
        TitanicY = 157,
        Height = 22,
        SidePadding = 11
    }
    function SetAutoBreakControl(control, y)
        control.Position = UDim2.fromOffset(AutoBreakControlLayout.SidePadding, y)
        control.Size = UDim2.new(1, -AutoBreakControlLayout.SidePadding * 2, 0, AutoBreakControlLayout.Height)
    end
    local AutoBreakToggle = CreateToggle(Card1, "", false, function(enabled)
        AutoBreakEnabled = enabled
        AutoBreakGeneration += 1
        if TouchAutomationProgress then
            TouchAutomationProgress(enabled and "AUTO_BREAK_ON" or "AUTO_BREAK_OFF")
        end
        if not AutoBreakToggleInitialized then
            AutoBreakToggleInitialized = true
            return
        end
        AddDebugLog("[Auto Break] Toggle " .. (enabled and "ON" or "OFF"))
        if enabled then
            if StartAutoBreak then StartAutoBreak() end
        else
            if StopAutoBreak then StopAutoBreak("Toggle disabled") end
            if CancelActiveAutomation then CancelActiveAutomation("Auto Break disabled") end
        end
    end)
    AutoBreakToggle.Position = UDim2.new(1, -58, 0, 7)
    AutoBreakToggle.Size = UDim2.fromOffset(48, 24)
    local AutoBreakTitle = Card1:FindFirstChildWhichIsA("TextLabel")
    if AutoBreakTitle then AutoBreakTitle.Size = UDim2.new(1, -78, 0, 22) end
    local AutoPickupCard = CreateCard(AutoRow, "Auto Steal", "")
    AutoPickupCard.Position = UDim2.new(0, 0, 0, 0)
    AutoPickupCard.Size = UDim2.new(0.5, -5, 0, 340)
    local AutoPickupEnabled = false
    local CurrentTarget, ArrivedAtTarget, WaitingForPickup
    local PickupRequested, ReturningAfterPickup, FlingRecoveryActive, ScriptShuttingDown
    local PickupMonitorSeen = setmetatable({}, {__mode = "k"})
    local AutoPickupToggle = CreateToggle(AutoPickupCard, "", false, function(enabled)
        AutoPickupEnabled = enabled
        table.clear(PickupMonitorSeen)
        AddDebugLog("[Auto Pickup] " .. (enabled and "Monitoring ON." or "Monitoring OFF."))
        if not enabled then
            if StopPickupAutomation then StopPickupAutomation("Auto Pickup disabled") end
            if CurrentTarget and IsEggConfirmedComplete(CurrentTarget) then
                CompletedEggs[CurrentTarget] = true
            end
            WaitingForPickup = false
            ArrivedAtTarget = false
            task.defer(function()
                task.wait(0.2)
                if AutoBreakEnabled and not AutoPickupEnabled and not PickupRequested
                    and not ReturningAfterPickup and not FlingRecoveryActive and not ScriptShuttingDown
                    and StartAutoBreak then
                    StartAutoBreak(true)
                end
            end)
        end
    end)
    AutoPickupToggle.Position = UDim2.new(1, -58, 0, 7)
    AutoPickupToggle.Size = UDim2.fromOffset(48, 24)
    local AutoPickupTitle = AutoPickupCard:FindFirstChildWhichIsA("TextLabel")
    if AutoPickupTitle then AutoPickupTitle.Size = UDim2.new(1, -78, 0, 22) end
    -- Auto Fuse removed: card, polling loop, toggles, and requirement scanning are intentionally disabled.
    local RarityFilterOpen = false
    local RarityOptions = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Cosmic", "Secret", "Eternal", "Divine", "Celestial", "Inferno", "Void", "Omega", "Spectral", "Ethereal", "Primordial"}
    local SavedFarmConfig = type(SavedConfig.Farm) == "table" and SavedConfig.Farm or {}
    local function RestoreNameSet(values)
        local result = {}
        if type(values) == "table" then
            for _, value in ipairs(values) do
                if type(value) == "string" and value ~= "" then result[value] = true end
            end
        end
        return result
    end
    local SelectedRarities = {}
    local SelectedMutationRarities = {}
    if type(SavedFarmConfig.MutationRarities) == "table" then
        for rarity, enabled in pairs(SavedFarmConfig.MutationRarities) do
            if type(rarity) == "string" and enabled == true then SelectedMutationRarities[rarity] = true end
        end
    end
    if type(SavedFarmConfig.Rarities) == "table" then
        for rarity, enabled in pairs(SavedFarmConfig.Rarities) do
            if type(rarity) == "string" and enabled == true then SelectedRarities[rarity] = true end
        end
    end
    local SelectedPickupZones = RestoreNameSet(SavedFarmConfig.PickupZones)
    local PickupZoneList
    local PickupZoneButton
    local RarityList
    local RarityFilterButton
    local UpdateRarityFilterButtonText, UpdatePickupZoneButtonText
    local ZoneFilterOpen = false
    local EggFilterOpen = false
    local ZoneList
    local EggFilterList
    RarityFilterButton = CreateButton(AutoPickupCard, "Rarity ▼", function()
        RarityFilterOpen = not RarityFilterOpen
        ZoneFilterOpen = false
        EggFilterOpen = false
        if RarityFilterOpen then
            RarityList.Position = UDim2.fromOffset(11, RarityFilterButton.Position.Y.Offset + RarityFilterButton.AbsoluteSize.Y + 4)
            RarityList.Size = UDim2.new(1, -22, 0, 140)
        end
        if PickupZoneList then PickupZoneList.Visible = false end
        if UpdateRarityFilterButtonText then UpdateRarityFilterButtonText() end
        RarityList.Visible = RarityFilterOpen
        if ZoneList then ZoneList.Visible = false end
        if EggFilterList then EggFilterList.Visible = false end
    end)
    Create("TextLabel", {
        Name = "RarityFilterLabel",
        Parent = AutoPickupCard,
        Position = UDim2.fromOffset(11, 27),
        Size = UDim2.new(1, -22, 0, 13),
        BackgroundTransparency = 1,
        Text = "Rarity Filter",
        TextColor3 = Theme.Gray,
        Font = Enum.Font.GothamMedium,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    RarityFilterButton.Position = UDim2.fromOffset(11, 43)
    RarityFilterButton.Size = UDim2.new(1, -22, 0, 22)
    PickupZoneButton = CreateButton(AutoPickupCard, "Zone: All ▼", function()
        ZoneFilterOpen = not ZoneFilterOpen
        RarityFilterOpen = false
        EggFilterOpen = false
        RarityList.Visible = false
        if ZoneList then ZoneList.Visible = false end
        if EggFilterList then EggFilterList.Visible = false end
        if PickupZoneList then
            PickupZoneList.Position = UDim2.fromOffset(11, 111)
            PickupZoneList.Size = UDim2.new(1, -22, 0, 140)
            PickupZoneList.Visible = ZoneFilterOpen
        end
        if UpdatePickupZoneButtonText then UpdatePickupZoneButtonText() end
    end)
    PickupZoneButton.Name = "AutoPickupZoneFilterButton"
    PickupZoneButton.Position = UDim2.fromOffset(11, 85)
    PickupZoneButton.Size = UDim2.new(1, -22, 0, 22)
    local KGThresholdAmount = type(SavedFarmConfig.KGThresholdAmount) == "number" and math.max(SavedFarmConfig.KGThresholdAmount, 0) or 0
    local KGThresholdUnit = ({K = true, M = true, B = true, T = true, Qa = true})[SavedFarmConfig.KGThresholdUnit] and SavedFarmConfig.KGThresholdUnit or "K"
    Create("TextLabel", {
        Name = "ZoneFilterLabel",
        Parent = AutoPickupCard,
        Position = UDim2.fromOffset(11, 69),
        Size = UDim2.new(1, -22, 0, 13),
        BackgroundTransparency = 1,
        Text = "Zone filter",
        TextColor3 = Theme.Gray,
        Font = Enum.Font.GothamMedium,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    Create("TextLabel", {
        Name = "KGUnitLabel",
        Parent = AutoPickupCard,
        Position = UDim2.new(1, -63, 0, 111),
        Size = UDim2.fromOffset(52, 13),
        BackgroundTransparency = 1,
        Text = "Unit",
        TextColor3 = Theme.Gray,
        Font = Enum.Font.GothamMedium,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Center
    })
    Create("TextLabel", {
        Name = "KGThresholdLabel",
        Parent = AutoPickupCard,
        Position = UDim2.fromOffset(11, 111),
        Size = UDim2.new(1, -22, 0, 13),
        BackgroundTransparency = 1,
        Text = "Weight Threshold",
        TextColor3 = Theme.Gray,
        Font = Enum.Font.GothamMedium,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    local KGThresholdInput = Create("TextBox", {
        Name = "KGThresholdInput",
        Parent = AutoPickupCard,
        Position = UDim2.fromOffset(11, 126),
        Size = UDim2.new(1, -84, 0, 25),
        BackgroundColor3 = Theme.SurfaceInput,
        Text = KGThresholdAmount > 0 and tostring(KGThresholdAmount) or "",
        PlaceholderText = "e.g. 100",
        PlaceholderColor3 = Theme.Gray,
        TextColor3 = Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        ClearTextOnFocus = false,
        BorderSizePixel = 0
    })
    AddCorner(KGThresholdInput, 5)
    AddStroke(KGThresholdInput, Theme.Border, 1)
    local KGUnitButton
    local KGUnitState = {options = {"K", "M", "B", "T", "Qa"}, open = false, list = nil}
    KGUnitButton = CreateButton(AutoPickupCard, KGThresholdUnit .. " ▼", function()
        KGUnitState.open = not KGUnitState.open
        RarityFilterOpen = false
        ZoneFilterOpen = false
        EggFilterOpen = false
        RarityList.Visible = false
        if ZoneList then ZoneList.Visible = false end
        if EggFilterList then EggFilterList.Visible = false end
        if KGUnitState.list then KGUnitState.list.Visible = KGUnitState.open end
        KGUnitButton.Text = KGUnitState.open and KGThresholdUnit .. " ▲" or KGThresholdUnit .. " ▼"
    end)
    KGUnitButton.Name = "KGUnitFilterButton"
    KGUnitButton.Position = UDim2.new(1, -63, 0, 126)
    KGUnitButton.Size = UDim2.fromOffset(52, 25)
    KGUnitState.list = Create("Frame", {
        Name = "KGUnitFilterList",
        Parent = AutoPickupCard,
        Position = UDim2.new(1, -63, 0, 153),
        Size = UDim2.fromOffset(52, #KGUnitState.options * 24 + 8),
        BackgroundColor3 = Theme.SurfaceInput,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 120
    })
    AddCorner(KGUnitState.list, 6)
    AddStroke(KGUnitState.list, Theme.Border, 1)
    Create("UIListLayout", {
        Parent = KGUnitState.list,
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    Create("UIPadding", {
        Parent = KGUnitState.list,
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4)
    })
    for index, unit in ipairs(KGUnitState.options) do
        local unitButton = Create("TextButton", {
            Name = "KGUnit_" .. unit,
            Parent = KGUnitState.list,
            Size = UDim2.new(1, -4, 0, 22),
            BackgroundColor3 = unit == KGThresholdUnit and Theme.Selected or Theme.Card,
            Text = unit,
            TextColor3 = Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 10,
            BorderSizePixel = 0,
            LayoutOrder = index,
            AutoButtonColor = false,
            ZIndex = 121
        })
        AddCorner(unitButton, 4)
        unitButton.MouseButton1Click:Connect(function()
            KGThresholdUnit = unit
            KGUnitButton.Text = unit .. " ▼"
            KGUnitState.open = false
            KGUnitState.list.Visible = false
            for _, child in ipairs(KGUnitState.list:GetChildren()) do
                if child:IsA("TextButton") then
                    child.BackgroundColor3 = child.Name == "KGUnit_" .. unit and Theme.Selected or Theme.Card
                end
            end
            AddDebugLog("[Auto Pickup] KG threshold unit set to " .. unit .. ".")
        end)
    end
    KGThresholdInput.FocusLost:Connect(function()
        local rawAmount = tostring(KGThresholdInput.Text or ""):gsub(",", ""):match("^%s*(.-)%s*$")
        local amount = tonumber(rawAmount)
        KGThresholdAmount = amount and math.max(amount, 0) or 0
        AddDebugLog(KGThresholdAmount > 0
            and string.format("[Auto Pickup] KG priority threshold set to %s %s KG.", tostring(KGThresholdAmount), KGThresholdUnit)
            or "[Auto Pickup] KG priority filter OFF.")
    end)
    local CPSFilter = {amount = type(SavedFarmConfig.CPSAmount) == "number" and math.max(SavedFarmConfig.CPSAmount, 0) or 0, unit = ({K = true, M = true, B = true, T = true, Qa = true})[SavedFarmConfig.CPSUnit] and SavedFarmConfig.CPSUnit or "K", options = {"K", "M", "B", "T", "Qa"}, open = false}
    Create("TextLabel", {
        Name = "CPSUnitLabel",
        Parent = AutoPickupCard,
        Position = UDim2.new(1, -63, 0, 154),
        Size = UDim2.fromOffset(52, 13),
        BackgroundTransparency = 1,
        Text = "Unit",
        TextColor3 = Theme.Gray,
        Font = Enum.Font.GothamMedium,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Center
    })
    Create("TextLabel", {
        Name = "CPSFilterLabel",
        Parent = AutoPickupCard,
        Position = UDim2.fromOffset(11, 154),
        Size = UDim2.new(1, -22, 0, 13),
        BackgroundTransparency = 1,
        Text = "Coins per Second Threshold",
        TextColor3 = Theme.Gray,
        Font = Enum.Font.GothamMedium,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    CPSFilter.input = Create("TextBox", {
        Name = "CPSFilterInput",
        Parent = AutoPickupCard,
        Position = UDim2.fromOffset(11, 169),
        Size = UDim2.new(1, -84, 0, 25),
        BackgroundColor3 = Theme.SurfaceInput,
        Text = CPSFilter.amount > 0 and tostring(CPSFilter.amount) or "",
        PlaceholderText = "e.g. 100",
        PlaceholderColor3 = Theme.Gray,
        TextColor3 = Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        ClearTextOnFocus = false,
        BorderSizePixel = 0,
        ZIndex = 2
    })
    AddCorner(CPSFilter.input, 5)
    AddStroke(CPSFilter.input, Theme.Border, 1)
    CPSFilter.button = CreateButton(AutoPickupCard, CPSFilter.unit .. " ▼", function()
        CPSFilter.open = not CPSFilter.open
        RarityFilterOpen = false
        ZoneFilterOpen = false
        EggFilterOpen = false
        RarityList.Visible = false
        if ZoneList then ZoneList.Visible = false end
        if EggFilterList then EggFilterList.Visible = false end
        if KGUnitState.list then KGUnitState.list.Visible = false; KGUnitState.open = false end
        CPSFilter.list.Visible = CPSFilter.open
        CPSFilter.button.Text = CPSFilter.open and CPSFilter.unit .. " ▲" or CPSFilter.unit .. " ▼"
    end)
    CPSFilter.button.Name = "CPSUnitFilterButton"
    CPSFilter.button.Position = UDim2.new(1, -63, 0, 169)
    CPSFilter.button.Size = UDim2.fromOffset(52, 25)
    CPSFilter.list = Create("Frame", {
        Name = "CPSUnitFilterList",
        Parent = AutoPickupCard,
        Position = UDim2.new(1, -63, 0, 196),
        Size = UDim2.fromOffset(52, #CPSFilter.options * 24 + 8),
        BackgroundColor3 = Theme.SurfaceInput,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 122
    })
    AddCorner(CPSFilter.list, 6)
    AddStroke(CPSFilter.list, Theme.Border, 1)
    Create("UIListLayout", {Parent = CPSFilter.list, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder})
    Create("UIPadding", {
        Parent = CPSFilter.list,
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4)
    })
    for index, unit in ipairs(CPSFilter.options) do
        local unitButton = Create("TextButton", {
            Name = "CPSUnit_" .. unit,
            Parent = CPSFilter.list,
            Size = UDim2.new(1, -4, 0, 22),
            BackgroundColor3 = unit == CPSFilter.unit and Theme.Selected or Theme.Card,
            Text = unit,
            TextColor3 = Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 10,
            BorderSizePixel = 0,
            LayoutOrder = index,
            AutoButtonColor = false,
            ZIndex = 123
        })
        AddCorner(unitButton, 4)
        unitButton.MouseButton1Click:Connect(function()
            CPSFilter.unit = unit
            CPSFilter.button.Text = unit .. " ▼"
            CPSFilter.open = false
            CPSFilter.list.Visible = false
            for _, child in ipairs(CPSFilter.list:GetChildren()) do
                if child:IsA("TextButton") then
                    child.BackgroundColor3 = child.Name == "CPSUnit_" .. unit and Theme.Selected or Theme.Card
                end
            end
            AddDebugLog("[Auto Pickup] Coins/second unit set to " .. unit .. ".")
        end)
    end
    CPSFilter.input.FocusLost:Connect(function()
        local rawAmount = tostring(CPSFilter.input.Text or ""):gsub(",", ""):match("^%s*(.-)%s*$")
        local amount = tonumber(rawAmount)
        CPSFilter.amount = amount and math.max(amount, 0) or 0
        AddDebugLog(CPSFilter.amount > 0
            and string.format("[Auto Pickup] Coins/second minimum set to %s %s/s.", tostring(CPSFilter.amount), CPSFilter.unit)
            or "[Auto Pickup] Coins/second filter OFF.")
    end)
    local function CreatePickupCheckbox(parent, labelText, yPosition, callback, defaultEnabled)
        local CheckboxBorder = Create("Frame", {
            Parent = parent,
            Name = "PickupOptionCheckboxBorder",
            Position = UDim2.new(1, -32, 0, yPosition + 2),
            Size = UDim2.fromOffset(18, 18),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            ZIndex = 2
        })
        AddCorner(CheckboxBorder, 4)
        local Checkbox = Create("TextButton", {
            Parent = CheckboxBorder,
            Name = "PickupOptionCheckbox",
            Position = UDim2.fromOffset(2, 2),
            Size = UDim2.fromOffset(14, 14),
            BackgroundColor3 = Theme.SurfaceInput,
            Text = "",
            BorderSizePixel = 0,
            AutoButtonColor = false,
            ZIndex = 3
        })
        AddCorner(Checkbox, 3)
        local CheckIcon = Create("TextLabel", {
            Parent = Checkbox,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = Theme.Text,
            TextStrokeTransparency = 1,
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            BorderSizePixel = 0,
            ZIndex = 4
        })
        local Label = Create("TextButton", {
            Parent = parent,
            Position = UDim2.fromOffset(11, yPosition),
            Size = UDim2.new(1, -55, 0, 22),
            BackgroundTransparency = 1,
            Text = labelText,
            TextColor3 = Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left,
            BorderSizePixel = 0,
            AutoButtonColor = false
        })
        local Enabled = false
        local function SetEnabled(value)
            Enabled = value
            CheckIcon.Text = Enabled and "✓" or ""
            Checkbox.BackgroundColor3 = Enabled and Theme.Accent or Theme.SurfaceInput
            Checkbox.TextColor3 = Theme.Text
            if callback then callback(Enabled) end
        end
        local function Toggle()
            SetEnabled(not Enabled)
        end
        Checkbox.MouseButton1Click:Connect(Toggle)
        Label.MouseButton1Click:Connect(Toggle)
        if defaultEnabled == true then SetEnabled(true) end
        return Checkbox
    end
    local HighestCashEnabled = SavedFarmConfig.HighestCash == true
    local HighestCashToggle = CreatePickupCheckbox(AutoPickupCard, "Steal above your lowest $/s", 205, function(enabled)
        HighestCashEnabled = enabled
        AddDebugLog("[Auto Pickup] " .. (enabled and "Lowest placed CPS filter ON." or "Lowest placed CPS filter OFF."))
    end, HighestCashEnabled)
    local UnindexedOnlyEnabled = SavedFarmConfig.UnindexedOnly == true
    local UnindexedOnlyToggle = CreatePickupCheckbox(AutoPickupCard, "Steal not Index Animals", 231, function(enabled)
        UnindexedOnlyEnabled = enabled
        AddDebugLog("[Auto Pickup] " .. (enabled and "Unindexed-only verification ON." or "Unindexed-only verification OFF."))
    end, UnindexedOnlyEnabled)
    local DropInZone1Enabled = SavedFarmConfig.DropInZone1 == true
    local DropInZone1Toggle = CreatePickupCheckbox(AutoPickupCard, "Drop the animal in Zone 1", 257, function(enabled)
        DropInZone1Enabled = enabled
        AddDebugLog("[Auto Pickup] Drop in Zone 1 " .. (enabled and "ON." or "OFF."))
    end, DropInZone1Enabled)
    local PickUpWithMutationEnabled = SavedFarmConfig.PickUpWithMutation == true
    local PickUpWithMutationToggle = CreatePickupCheckbox(AutoPickupCard, "Steal animal with mutation", 283, function(enabled)
        PickUpWithMutationEnabled = enabled
        AddDebugLog("[Auto Pickup] With Mutation " .. (enabled and "ON." or "OFF."))
    end, PickUpWithMutationEnabled)
    local MutationRarityFilterOpen = false
    local MutationRarityList
    local UpdateMutationRarityFilterButtonText
    local MutationRarityFilterButton
    MutationRarityFilterButton = CreateButton(AutoPickupCard, "Mutation Rarity: All ▼", function()
        MutationRarityFilterOpen = not MutationRarityFilterOpen
        RarityFilterOpen = false
        ZoneFilterOpen = false
        EggFilterOpen = false
        RarityList.Visible = false
        if PickupZoneList then PickupZoneList.Visible = false end
        if ZoneList then ZoneList.Visible = false end
        if EggFilterList then EggFilterList.Visible = false end
        if MutationRarityList then
            local listHeight = 140
            local buttonY = MutationRarityFilterButton.Position.Y.Offset
            local buttonBottom = buttonY + MutationRarityFilterButton.AbsoluteSize.Y
            local availableBelow = AutoPickupCard.AbsoluteSize.Y - buttonBottom
            local listY = availableBelow >= listHeight + 4
                and buttonBottom + 4
                or buttonY - listHeight - 4
            MutationRarityList.Position = UDim2.fromOffset(11, listY)
            MutationRarityList.Size = UDim2.new(1, -22, 0, listHeight)
            MutationRarityList.Visible = MutationRarityFilterOpen
        end
        UpdateMutationRarityFilterButtonText()
    end)
    MutationRarityFilterButton.Name = "MutationRarityFilterButton"
    MutationRarityFilterButton.Position = UDim2.fromOffset(11, 307)
    MutationRarityFilterButton.Size = UDim2.new(1, -22, 0, 22)
    MutationRarityFilterButton.TextSize = 8
    -- Keep this control above the other filter widgets created later in the card.
    MutationRarityFilterButton.ZIndex = 130
    MutationRarityFilterButton.Active = true
    MutationRarityFilterButton.Selectable = true
    RarityList = Create("ScrollingFrame", {
        Name = "RarityFilterContainer",
        Parent = AutoPickupCard,
        Position = UDim2.fromOffset(11, 75),
        Size = UDim2.fromOffset(160, 155),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Gray,
        BackgroundColor3 = Theme.SurfaceInput,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 100
    })
    AddCorner(RarityList, 6)
    PickupZoneList = Create("ScrollingFrame", {
        Name = "AutoPickupZoneFilterList",
        Parent = AutoPickupCard,
        Position = UDim2.fromOffset(11, 111),
        Size = UDim2.new(1, -22, 0, 140),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Gray,
        BackgroundColor3 = Theme.SurfaceInput,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 110
    })
    AddCorner(PickupZoneList, 6)
    local PickupZoneLayout = Create("UIListLayout", {
        Parent = PickupZoneList,
        Padding = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    Create("UIPadding", {
        Parent = PickupZoneList,
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5)
    })
    local RarityLayout = Create("UIListLayout", {
        Parent = RarityList,
        Padding = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    Create("UIPadding", {
        Parent = RarityList,
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5)
    })
    RarityLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        RarityList.CanvasSize = UDim2.new(0, 0, 0, RarityLayout.AbsoluteContentSize.Y + 10)
    end)
    function RefreshRarityList()
        for _, item in ipairs(RarityList:GetChildren()) do
            if item:IsA("TextButton") then item:Destroy() end
        end
        for rarityIndex, rarityName in ipairs(RarityOptions) do
            local selected = SelectedRarities[rarityName] == true
            local RarityButton = Create("TextButton", {
                Name = "Rarity_" .. rarityName, Parent = RarityList,
                Size = UDim2.new(1, -4, 0, 22),
                BackgroundColor3 = selected and Theme.Selected or Theme.Card,
                Text = "", BorderSizePixel = 0, LayoutOrder = rarityIndex,
                AutoButtonColor = false, ZIndex = 101
            })
            AddCorner(RarityButton, 4)
            Create("TextLabel", {
                Parent = RarityButton, Position = UDim2.fromOffset(7, 0),
                Size = UDim2.new(1, -28, 1, 0), BackgroundTransparency = 1,
                Text = rarityName, TextColor3 = Theme.Text,
                Font = Enum.Font.Gotham, TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 102
            })
            Create("TextLabel", {
                Parent = RarityButton, AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -7, 0.5, 0),
                Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1,
                Text = selected and "✓" or "○",
                TextColor3 = selected and Theme.Accent or Theme.Gray,
                Font = Enum.Font.GothamBold, TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center, ZIndex = 102
            })
            RarityButton.MouseButton1Click:Connect(function()
                SelectedRarities[rarityName] = not SelectedRarities[rarityName] or nil
                if UpdateRarityFilterButtonText then UpdateRarityFilterButtonText() end
                RefreshRarityList()
            end)
        end
    end
    RefreshRarityList()
    MutationRarityList = Create("ScrollingFrame", {
        Name = "MutationRarityFilterContainer", Parent = AutoPickupCard,
        Position = UDim2.fromOffset(11, 333), Size = UDim2.new(1, -22, 0, 140),
        CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Gray, BackgroundColor3 = Theme.SurfaceInput,
        BorderSizePixel = 0, Visible = false, ZIndex = 140,
        Active = true
    })
    AddCorner(MutationRarityList, 6)
    local MutationRarityLayout = Create("UIListLayout", {
        Parent = MutationRarityList, Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder
    })
    Create("UIPadding", {
        Parent = MutationRarityList, PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5),
        PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)
    })
    MutationRarityLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        MutationRarityList.CanvasSize = UDim2.new(
            0, 0, 0, MutationRarityLayout.AbsoluteContentSize.Y + 10
        )
    end)
    UpdateMutationRarityFilterButtonText = function()
        local selected = {}
        for _, rarityName in ipairs(RarityOptions) do
            if SelectedMutationRarities[rarityName] then table.insert(selected, rarityName) end
        end
        local summary = #selected > 0 and table.concat(selected, ", ") or "All"
        MutationRarityFilterButton.Text = "Mutation Rarity: " .. summary .. (MutationRarityFilterOpen and " ▲" or " ▼")
        MutationRarityFilterButton.TextSize = 8
    end
    local function RefreshMutationRarityList()
        for _, item in ipairs(MutationRarityList:GetChildren()) do
            if item:IsA("TextButton") then item:Destroy() end
        end
        for rarityIndex, rarityName in ipairs(RarityOptions) do
            local selected = SelectedMutationRarities[rarityName] == true
            local rarityButton = Create("TextButton", {
                Name = "MutationRarity_" .. rarityName, Parent = MutationRarityList,
                Size = UDim2.new(1, -4, 0, 22),
                BackgroundColor3 = selected and Theme.Selected or Theme.Card,
                Text = "", BorderSizePixel = 0, LayoutOrder = rarityIndex,
                AutoButtonColor = false, ZIndex = 141,
                Active = true, Selectable = true
            })
            AddCorner(rarityButton, 4)
            Create("TextLabel", {
                Parent = rarityButton, Position = UDim2.fromOffset(7, 0),
                Size = UDim2.new(1, -28, 1, 0), BackgroundTransparency = 1,
                Text = rarityName, TextColor3 = Theme.Text, Font = Enum.Font.Gotham,
                TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 142,
                Active = false
            })
            Create("TextLabel", {
                Parent = rarityButton, AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -7, 0.5, 0), Size = UDim2.fromOffset(14, 14),
                BackgroundTransparency = 1, Text = selected and "✓" or "○",
                TextColor3 = selected and Theme.Accent or Theme.Gray,
                Font = Enum.Font.GothamBold, TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 142, Active = false
            })
            rarityButton.MouseButton1Click:Connect(function()
                SelectedMutationRarities[rarityName] = not SelectedMutationRarities[rarityName] or nil
                UpdateMutationRarityFilterButtonText()
                RefreshMutationRarityList()
            end)
        end
        MutationRarityList.CanvasSize = UDim2.new(0, 0, 0, MutationRarityLayout.AbsoluteContentSize.Y + 10)
    end
    RefreshMutationRarityList()
    UpdateMutationRarityFilterButtonText()
    UpdateRarityFilterButtonText = function()
        local selected = {}
        for _, rarityName in ipairs(RarityOptions) do
            if SelectedRarities[rarityName] then
                table.insert(selected, rarityName)
            end
        end
        local summary = #selected > 0 and table.concat(selected, ", ") or "All"
        RarityFilterButton.Text = "Rarity: " .. summary .. (RarityFilterOpen and " ▲" or " ▼")
        RarityFilterButton.TextSize = 8
        RarityFilterButton.TextXAlignment = Enum.TextXAlignment.Center
    end
    UpdatePickupZoneButtonText = function()
        local selected = {}
        for zoneName, enabled in pairs(SelectedPickupZones) do
            if enabled then
                local zoneNumber = zoneName:match("%d+")
                table.insert(selected, zoneNumber or zoneName)
            end
        end
        table.sort(selected, function(a, b)
            local an, bn = tonumber(a), tonumber(b)
            if an and bn then return an > bn end
            if an then return true end
            if bn then return false end
            return a < b
        end)
        local summary = #selected > 0 and table.concat(selected, ", ") or "All"
        PickupZoneButton.Text = "Zone: " .. summary .. (ZoneFilterOpen and " ▲" or " ▼")
        PickupZoneButton.TextSize = 8
        PickupZoneButton.TextXAlignment = Enum.TextXAlignment.Center
    end
    local function RefreshPickupZoneList()
        for _, item in ipairs(PickupZoneList:GetChildren()) do
            if item:IsA("TextButton") then item:Destroy() end
        end
        local build = workspace:FindFirstChild("Build")
        local zoneBuilds = build and build:FindFirstChild("ZoneBuilds")
        local zones = {}
        if zoneBuilds then
            for _, zone in ipairs(zoneBuilds:GetChildren()) do
                if zone:IsA("Model") then table.insert(zones, zone) end
            end
        end
        table.sort(zones, function(a, b)
            local an = tonumber(a.Name:match("%d+"))
            local bn = tonumber(b.Name:match("%d+"))
            if an and bn and an ~= bn then return an > bn end
            if an and not bn then return true end
            if bn and not an then return false end
            return a.Name > b.Name
        end)
        local selectedCount = 0
        for _, zone in ipairs(zones) do
            if SelectedPickupZones[zone.Name] then selectedCount += 1 end
        end
        local allButton = Create("TextButton", {
            Name = "PickupZone_All",
            Parent = PickupZoneList,
            Size = UDim2.new(1, -4, 0, 22),
            BackgroundColor3 = selectedCount == 0 and Theme.Selected or Theme.Card,
            Text = "",
            BorderSizePixel = 0,
            LayoutOrder = 0,
            AutoButtonColor = false,
            ZIndex = 111
        })
        AddCorner(allButton, 4)
        Create("TextLabel", {
            Parent = allButton, Position = UDim2.fromOffset(6, 0),
            Size = UDim2.new(1, -24, 1, 0), BackgroundTransparency = 1,
            Text = "All Zones (default)", TextColor3 = Theme.Text,
            Font = Enum.Font.Gotham, TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 112
        })
        Create("TextLabel", {
            Parent = allButton, Position = UDim2.new(1, -20, 0, 0),
            Size = UDim2.fromOffset(16, 22), BackgroundTransparency = 1,
            Text = selectedCount == 0 and "✓" or "○",
            TextColor3 = selectedCount == 0 and Color3.fromRGB(110, 205, 145) or Theme.Gray,
            Font = Enum.Font.GothamBold, TextSize = 10, ZIndex = 112
        })
        allButton.MouseButton1Click:Connect(function()
            table.clear(SelectedPickupZones)
            RefreshPickupZoneList()
            if UpdatePickupZoneButtonText then UpdatePickupZoneButtonText() end
        end)
        for index, zone in ipairs(zones) do
            local zoneName = zone.Name
            local selected = SelectedPickupZones[zoneName] == true
            local item = Create("TextButton", {
                Name = "PickupZone_" .. zoneName,
                Parent = PickupZoneList,
                Size = UDim2.new(1, -4, 0, 22),
                BackgroundColor3 = selected and Theme.Selected or Theme.Card,
                Text = "", BorderSizePixel = 0, LayoutOrder = index,
                AutoButtonColor = false, ZIndex = 111
            })
            AddCorner(item, 4)
            Create("TextLabel", {
                Parent = item, Position = UDim2.fromOffset(6, 0),
                Size = UDim2.new(1, -24, 1, 0), BackgroundTransparency = 1,
                Text = zoneName, TextColor3 = Theme.Text,
                Font = Enum.Font.Gotham, TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 112
            })
            Create("TextLabel", {
                Parent = item, Position = UDim2.new(1, -20, 0, 0),
                Size = UDim2.fromOffset(16, 22), BackgroundTransparency = 1,
                Text = selected and "✓" or "○",
                TextColor3 = selected and Color3.fromRGB(110, 205, 145) or Theme.Gray,
                Font = Enum.Font.GothamBold, TextSize = 10, ZIndex = 112
            })
            item.MouseButton1Click:Connect(function()
                if SelectedPickupZones[zoneName] then
                    SelectedPickupZones[zoneName] = nil
                else
                    SelectedPickupZones[zoneName] = true
                end
                RefreshPickupZoneList()
                if UpdatePickupZoneButtonText then UpdatePickupZoneButtonText() end
            end)
        end
        PickupZoneList.CanvasSize = UDim2.new(0, 0, 0, PickupZoneLayout.AbsoluteContentSize.Y + 10)
    end
    RefreshPickupZoneList()
    local SelectedZones = RestoreNameSet(SavedFarmConfig.Zones)
    local SelectedEggs = {}
    for eggName in pairs(RestoreNameSet(SavedFarmConfig.DisabledEggs)) do
        SelectedEggs[eggName] = false
    end
    local PreferredZoneName = nil
    local SortOrder = SavedFarmConfig.SortOrder == "Highest Kg" and "Highest Kg" or "Highest Luck"
    local SortFrame
    local ZoneFilterButton
    local EggFilterButton
    local SortLargestButton
    local SortSmallestButton
    local ZoneBuilds = workspace:WaitForChild("Build"):WaitForChild("ZoneBuilds")
    -- Resolve the gate from the live workspace hierarchy; do not hardcode coordinates.
    local function GetZone13GatePosition()
        local zone12 = ZoneBuilds:FindFirstChild("Zone12")
        local castleMap = zone12 and zone12:FindFirstChild("CastleMap")
        local limit = castleMap and castleMap:FindFirstChild("Limit")
        local gate = limit and limit:FindFirstChild("CastleGATE")
        if not gate then return nil end
        local ok, position = pcall(function()
            if gate:IsA("BasePart") then return gate.Position end
            return gate:GetPivot().Position
        end)
        return ok and position or nil
    end
    local function IsInsideZone13(position)
        local zone13 = ZoneBuilds:FindFirstChild("Zone13")
        if not zone13 or not position then return false end
        local ok, cf, size = pcall(function()
            local boxCFrame, boxSize = zone13:GetBoundingBox()
            return boxCFrame, boxSize
        end)
        if not ok or not cf or not size then return false end
        local localPosition = cf:PointToObjectSpace(position)
        return math.abs(localPosition.X) <= size.X * 0.5 + 6
            and math.abs(localPosition.Z) <= size.Z * 0.5 + 6
    end
    function GetPickupZoneName(pickup)
        if not pickup or not pickup.Parent then return nil end
        local pickupPosition
        local ok = pcall(function()
            if pickup:IsA("Model") then
                pickupPosition = pickup:GetPivot().Position
            elseif pickup:IsA("BasePart") then
                pickupPosition = pickup.Position
            end
        end)
        if not ok or not pickupPosition then return nil end
        local nearestZone, nearestDistance = nil, math.huge
        for _, zone in ipairs(ZoneBuilds:GetChildren()) do
            local eggsFolder = zone:FindFirstChild("Eggs")
            if eggsFolder then
                for _, egg in ipairs(eggsFolder:GetChildren()) do
                    if egg:IsA("Model") or egg:IsA("BasePart") then
                        local eggPosition
                        local eggOk = pcall(function()
                            if egg:IsA("Model") then
                                eggPosition = egg:GetPivot().Position
                            else
                                eggPosition = egg.Position
                            end
                        end)
                        if eggOk and eggPosition then
                            local distance = (pickupPosition - eggPosition).Magnitude
                            if distance < nearestDistance then
                                nearestDistance = distance
                                nearestZone = zone.Name
                            end
                        end
                    end
                end
            end
        end
        return nearestZone
    end
    function IsPickupAllowedByZone(pickup)
        local selectedCount = 0
        for _, selected in pairs(SelectedPickupZones) do
            if selected then selectedCount += 1 end
        end
        if selectedCount == 0 then return true end
        local zoneName = GetPickupZoneName(pickup)
        if not zoneName then
            SetPickupTracking(pickup, "Rejected: pickup zone could not be determined")
            return false, nil
        end
        return SelectedPickupZones[zoneName] == true, zoneName
    end
    function UpdateFilterPanel()
        ZoneList.Visible = ZoneFilterOpen
        EggFilterList.Visible = EggFilterOpen
        RarityList.Visible = RarityFilterOpen
        SortFrame.Visible = true
        if ZoneFilterOpen then
            ZoneList.Position = UDim2.new(0, ZoneFilterButton.Position.X.Offset, 0, ZoneFilterButton.Position.Y.Offset + ZoneFilterButton.AbsoluteSize.Y + 4)
            ZoneList.Size = UDim2.new(1, -22, 0, 140)
        end
        if EggFilterOpen then
            EggFilterList.Position = UDim2.new(0, EggFilterButton.Position.X.Offset, 0, EggFilterButton.Position.Y.Offset + EggFilterButton.AbsoluteSize.Y + 4)
            EggFilterList.Size = UDim2.new(1, -22, 0, 140)
        end
        if UpdateAutoBreakFilterButtonTexts then UpdateAutoBreakFilterButtonTexts() end
        RarityFilterButton.Text = RarityFilterOpen and "Rarity ▲" or "Rarity ▼"
    end
    Create("TextLabel", {
        Name = "ZoneFilterLabel",
        Parent = Card1,
        Position = UDim2.fromOffset(11, 27),
        Size = UDim2.new(1, -22, 0, 13),
        BackgroundTransparency = 1,
        Text = "Zone Filter",
        TextColor3 = Theme.Gray,
        Font = Enum.Font.GothamMedium,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    Create("TextLabel", {
        Name = "EggFilterLabel",
        Parent = Card1,
        Position = UDim2.fromOffset(11, 66),
        Size = UDim2.new(1, -22, 0, 13),
        BackgroundTransparency = 1,
        Text = "Egg Filter",
        TextColor3 = Theme.Gray,
        Font = Enum.Font.GothamMedium,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    ZoneFilterButton = CreateButton(Card1, "Zones ▼", function()
        ZoneFilterOpen = not ZoneFilterOpen
        EggFilterOpen = false
        RarityFilterOpen = false
        UpdateFilterPanel()
    end)
    SetAutoBreakControl(ZoneFilterButton, AutoBreakControlLayout.ZoneY)
    ZoneFilterButton.TextSize = 9
    ZoneFilterButton.Font = Enum.Font.GothamMedium
    ZoneFilterButton.BackgroundColor3 = Theme.Selected
    EggFilterButton = CreateButton(Card1, "Eggs ▼", function()
        EggFilterOpen = not EggFilterOpen
        ZoneFilterOpen = false
        RarityFilterOpen = false
        UpdateFilterPanel()
    end)
    SetAutoBreakControl(EggFilterButton, AutoBreakControlLayout.EggY)
    EggFilterButton.TextSize = 9
    EggFilterButton.Font = Enum.Font.GothamMedium
    EggFilterButton.BackgroundColor3 = Theme.Selected
    ZoneList = Create("ScrollingFrame", {
        Name = "ZoneFilterList",
        Parent = Card1,
        Position = UDim2.fromOffset(11, 76),
        Size = UDim2.fromOffset(140, 150),
        BackgroundColor3 = Theme.SurfaceInput,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Gray,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        ZIndex = 100
    })
    AddCorner(ZoneList, 6)
    local ZoneLayout = Create("UIListLayout", {
        Parent = ZoneList,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    Create("UIPadding", {
        Parent = ZoneList,
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4)
    })
    EggFilterList = Create("ScrollingFrame", {
        Name = "EggFilterList",
        Parent = Card1,
        Position = UDim2.fromOffset(11, 76),
        Size = UDim2.fromOffset(140, 150),
        BackgroundColor3 = Theme.SurfaceInput,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Gray,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        ZIndex = 100
    })
    AddCorner(EggFilterList, 6)
    local EggLayout = Create("UIListLayout", {
        Parent = EggFilterList,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    Create("UIPadding", {
        Parent = EggFilterList,
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4)
    })
    Create("TextLabel", {
        Name = "PriorityFilterLabel",
        Parent = Card1,
        Position = UDim2.fromOffset(AutoBreakControlLayout.SidePadding, AutoBreakControlLayout.HighLuckY - 16),
        Size = UDim2.new(1, -AutoBreakControlLayout.SidePadding * 2, 0, 13),
        BackgroundTransparency = 1,
        Text = "Priority",
        TextColor3 = Theme.Gray,
        Font = Enum.Font.GothamMedium,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    SortFrame = Create("Frame", {
        Name = "EggSortOptions",
        Parent = Card1,
        Position = UDim2.fromOffset(AutoBreakControlLayout.SidePadding, AutoBreakControlLayout.HighLuckY),
        Size = UDim2.new(1, -AutoBreakControlLayout.SidePadding * 2, 0, 22),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = true
    })
    local PriorityOptions = {"Highest Luck", "Highest Kg"}
    local PriorityOpen = false
    local PriorityOptionsFrame
    local PriorityFilterButton = CreateButton(SortFrame, SortOrder .. " ▼", function()
        PriorityOpen = not PriorityOpen
        if PriorityOptionsFrame then
            PriorityOptionsFrame.Visible = PriorityOpen
        end
    end)
    PriorityFilterButton.Position = UDim2.fromOffset(0, 0)
    PriorityFilterButton.Size = UDim2.new(1, 0, 0, AutoBreakControlLayout.Height)
    PriorityFilterButton.TextSize = 9
    PriorityFilterButton.Font = Enum.Font.GothamMedium
    PriorityFilterButton.BackgroundColor3 = Theme.Selected
    PriorityFilterButton.ZIndex = 100
    PriorityOptionsFrame = Create("Frame", {
        Name = "PriorityOptions",
        Parent = Card1,
        Position = UDim2.fromOffset(AutoBreakControlLayout.SidePadding, AutoBreakControlLayout.HighLuckY + AutoBreakControlLayout.Height + 4),
        Size = UDim2.new(1, -AutoBreakControlLayout.SidePadding * 2, 0, #PriorityOptions * 28 + 8),
        BackgroundColor3 = Theme.SurfaceInput,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 200
    })
    AddCorner(PriorityOptionsFrame, 6)
    local PriorityOptionsLayout = Create("UIListLayout", {
        Parent = PriorityOptionsFrame,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    Create("UIPadding", {
        Parent = PriorityOptionsFrame,
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4)
    })
    for optionIndex, option in ipairs(PriorityOptions) do
        local optionButton = Create("TextButton", {
            Parent = PriorityOptionsFrame,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.new(1, -8, 0, 24),
            BackgroundColor3 = SortOrder == option and Theme.Selected or Theme.Card,
            Text = option,
            TextColor3 = Theme.Text,
            Font = Enum.Font.GothamMedium,
            TextSize = 9,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            LayoutOrder = optionIndex,
            ZIndex = 201
        })
        AddCorner(optionButton, 5)
        optionButton.MouseEnter:Connect(function()
            if SortOrder ~= option then
                Tween(optionButton, {BackgroundColor3 = Theme.Selected})
            end
        end)
        optionButton.MouseLeave:Connect(function()
            if SortOrder ~= option then
                Tween(optionButton, {BackgroundColor3 = Theme.Card})
            end
        end)
        optionButton.MouseButton1Click:Connect(function()
            SortOrder = option
            PriorityFilterButton.Text = option .. " ▼"
            for _, child in ipairs(PriorityOptionsFrame:GetChildren()) do
                if child:IsA("TextButton") then
                    child.BackgroundColor3 = child == optionButton and Theme.Selected or Theme.Card
                end
            end
            PriorityOptionsFrame.Visible = false
            PriorityOpen = false
            if RefreshEggList then RefreshEggList() end
            if RefreshEggFilters then RefreshEggFilters() end
            AddDebugLog("[Auto Break] Priority set to " .. tostring(option))
        end)
    end
    SortLargestButton = PriorityFilterButton
    SortSmallestButton = nil
    function GetEggTypeName(name)
        return (name:gsub("^%d+:%s*", ""))
    end
    function GetEggDataValue(egg, variableName)
        if not egg then return nil end
        -- Egg metadata can be stored on the outer zone model OR on its nested Egg model.
        -- Search the full instance tree so Category/Luck/weight attributes are not missed.
        local function readFrom(object)
            local attribute = object:GetAttribute(variableName)
            if attribute ~= nil then return tostring(attribute) end
            if object.Name == variableName then
                if object:IsA("ValueBase") then return tostring(object.Value) end
                if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
                    if object.Text ~= "" then return object.Text end
                end
            end
            return nil
        end
        local value = readFrom(egg)
        if value ~= nil then return value end
        for _, node in ipairs(egg:GetDescendants()) do
            value = readFrom(node)
            if value ~= nil then return value end
        end
        return nil
    end
    function GetEggWeightKg(egg)
        local raw = GetEggDataValue(egg, "weightKg")
            or GetEggDataValue(egg, "WeightKg")
            or GetEggDataValue(egg, "WeightKG")
            or GetEggDataValue(egg, "weightKG")
        if not raw then return nil end
        local value = tonumber(tostring(raw):lower():gsub(",", ""):match("[%d%.]+"))
        return value
    end
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
    end, SavedFarmConfig.TitanicPriority == true)
    Card1.Size = UDim2.new(0.5, -5, 0, 190)
    AutoPickupCard.Size = UDim2.new(0.5, -5, 0, 340)
    local function UpdateAutoBreakCardHeights()
        local autoBreakBottom = math.max(AutoBreakControlLayout.TitanicY + AutoBreakControlLayout.Height + 12, 190)
        local pickupBottom = 340
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
            local returnGateWaypoint = IsInsideZone13(root.Position) and GetZone13GatePosition() or nil
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
                local activeDestination = returnGateWaypoint or destination
                local horizontalDestination = Vector3.new(activeDestination.X, root.Position.Y, activeDestination.Z)
                local offset = horizontalDestination - root.Position
                if offset.Magnitude < lastReturnDistance - 0.5 then
                    lastReturnDistance = offset.Magnitude
                    TouchAutomationProgress()
                end
                if offset.Magnitude <= 4 then
                    if returnGateWaypoint then
                        returnGateWaypoint = nil
                        lastReturnDistance = math.huge
                        TouchAutomationProgress("RETURNING_FROM_ZONE13:EXITED")
                        SetTrackerStatus("Exited Zone 13 through CastleGATE; continuing to the normal return destination.")
                    else
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

        local function HasMutationValue(value)
            if value == nil then return false end
            if type(value) == "boolean" then return value end
            local text = tostring(value):match("^%s*(.-)%s*$"):lower()
            return text ~= "" and text ~= "false" and text ~= "none" and text ~= "nil"
        end

        -- Variant may be stored on the pickup wrapper or on its nested animal model.
        local variant = pickup:GetAttribute("Variant")
        if HasMutationValue(variant) then return "Mutated" end

        for _, node in ipairs(pickup:GetDescendants()) do
            if node:GetAttribute("Variant") ~= nil and HasMutationValue(node:GetAttribute("Variant")) then
                return "Mutated"
            end

            -- The animal model can expose its mutations through an AuraMutations
            -- container instead of the pickup wrapper's Variant attribute.
            if node.Name == "AuraMutations" then
                if node:IsA("ValueBase") then
                    if HasMutationValue(node.Value) then return "Mutated" end
                else
                    for attributeName, attributeValue in pairs(node:GetAttributes()) do
                        if HasMutationValue(attributeValue) then return "Mutated" end
                    end
                    for _, mutation in ipairs(node:GetDescendants()) do
                        if mutation:IsA("ValueBase") then
                            if HasMutationValue(mutation.Value) then return "Mutated" end
                        elseif mutation:IsA("TextLabel") or mutation:IsA("TextButton") or mutation:IsA("TextBox") then
                            if HasMutationValue(mutation.Text) then return "Mutated" end
                        else
                            for attributeName, attributeValue in pairs(mutation:GetAttributes()) do
                                if HasMutationValue(attributeValue) then return "Mutated" end
                            end
                        end
                    end
                    -- Named mutation entries are commonly represented by empty
                    -- marker folders/instances, so their presence also counts.
                    if #node:GetChildren() > 0 then return "Mutated" end
                end
            end
        end

        return "No Mutation"
    end
    function GetPickupMutationNames(pickup)
        if not pickup then return "No Mutation" end
        local names = {}
        local seen = {}
        local function addName(value)
            if value == nil then return end
            local text = tostring(value):match("^%s*(.-)%s*$")
            if text == "" or text:lower() == "false" or text:lower() == "none" or text:lower() == "nil" then
                return
            end
            if not seen[text:lower()] then
                seen[text:lower()] = true
                table.insert(names, text)
            end
        end

        addName(pickup:GetAttribute("Variant"))
        for _, node in ipairs(pickup:GetDescendants()) do
            local variant = node:GetAttribute("Variant")
            if variant ~= nil then addName(variant) end

            if node.Name == "AuraMutations" then
                if node:IsA("ValueBase") then
                    if node:IsA("BoolValue") then
                        if node.Value then addName(node.Name) end
                    else
                        addName(node.Value)
                    end
                else
                    for attributeName, attributeValue in pairs(node:GetAttributes()) do
                        if type(attributeValue) == "boolean" then
                            if attributeValue then addName(attributeName) end
                        elseif attributeValue ~= nil then
                            addName(attributeName)
                        end
                    end
                    for _, mutation in ipairs(node:GetDescendants()) do
                        if mutation:IsA("BoolValue") then
                            if mutation.Value then addName(mutation.Name) end
                        elseif mutation:IsA("ValueBase") then
                            addName(mutation.Value)
                        elseif mutation:IsA("TextLabel") or mutation:IsA("TextButton") or mutation:IsA("TextBox") then
                            addName(mutation.Text)
                        else
                            for attributeName, attributeValue in pairs(mutation:GetAttributes()) do
                                if type(attributeValue) == "boolean" then
                                    if attributeValue then addName(attributeName) end
                                elseif attributeValue ~= nil then
                                    addName(attributeName)
                                end
                            end
                            if #mutation:GetChildren() == 0 then
                                addName(mutation.Name)
                            end
                        end
                    end
                    if #node:GetChildren() > 0 and #names == 0 then
                        for _, child in ipairs(node:GetChildren()) do addName(child.Name) end
                    end
                end
            end
        end

        table.sort(names)
        return #names > 0 and table.concat(names, ", ") or "No Mutation"
    end
    function UpdatePickupMutationAttributes(pickup)
        if not pickup or not pickup.Parent then return end
        local mutationNames = GetPickupMutationNames(pickup)
        local mutationDetected = GetPickupMutation(pickup) ~= "No Mutation"
        pickup:SetAttribute("MoldyHub_BASAE_Mutation", mutationDetected and mutationNames or "No Mutation")
        pickup:SetAttribute("MoldyHub_BASAE_MutationDetected", mutationDetected)
        pickup:SetAttribute("MoldyHub_BASAE_MutationCheckedAt", os.time())
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
    function IsMutationRarityAllowed(pickup)
        local selectedCount = 0
        for _, selected in pairs(SelectedMutationRarities) do
            if selected then selectedCount += 1 end
        end
        if selectedCount == 0 then return true end
        local rarity = GetPetRarity(pickup)
        if not rarity then
            SetTrackerStatus("Cannot mutation-filter " .. pickup.Name .. ": Rarity value not found.")
            return false
        end
        for selectedRarity, selected in pairs(SelectedMutationRarities) do
            if selected and selectedRarity:lower() == rarity:lower() then return true end
        end
        return false
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
        local trackingStatus = tostring(status or "Not checked")
        pickup:SetAttribute("MoldyHub_BASAE_CPSCheckStatus", trackingStatus)
        if cpsText ~= nil and ParseCPS(tostring(cpsText)) >= 0 then
            pickup:SetAttribute("MoldyHub_BASAE_CPSCheckValue", tostring(cpsText))
            pickup:SetAttribute("MoldyHub_BASAE_CPSCheckNumericValue", ParseCPS(tostring(cpsText)))
        elseif trackingStatus:lower():find("cps", 1, true)
            and (trackingStatus:lower():find("failed", 1, true)
                or trackingStatus:lower():find("unavailable", 1, true)) then
            pickup:SetAttribute("MoldyHub_BASAE_CPSCheckValue", nil)
            pickup:SetAttribute("MoldyHub_BASAE_CPSCheckNumericValue", nil)
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
        local wantedName = tostring(animalName)
        for zoneNumber = 1, 12 do
            local zone = scrollingFrame:FindFirstChild("Zone" .. tostring(zoneNumber))
            local animalList = zone and zone:FindFirstChild("AnimalList")
            local animalEntry = animalList and animalList:FindFirstChild(wantedName)
            if animalEntry then
                local inner = animalEntry:FindFirstChild("Inner")
                local nameLabel = inner and inner:FindFirstChild("Name")
                if nameLabel and (nameLabel:IsA("TextLabel") or nameLabel:IsA("TextButton")) then
                    return nameLabel
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
        if displayName == tostring(pickup.Name) then
            return false, displayName
        end
        return nil, "Index name mismatch: " .. tostring(displayName)
    end
    function EvaluatePickup(pickup)
        local function evaluationCancelled()
            return ScriptShuttingDown or not AutoPickupEnabled or not pickup.Parent
        end
        pickup:SetAttribute("MoldyHub_BASAE_Qualified", false)
        pickup:SetAttribute("MoldyHub_BASAE_PickupReason", "Evaluating")
        pickup:SetAttribute("MoldyHub_BASAE_DetectedCPS", nil)
        pickup:SetAttribute("MoldyHub_BASAE_CPSMinimum", CPSFilter.amount > 0 and (CPSFilter.amount * (({K = 1e3, M = 1e6, B = 1e9, T = 1e12, Qa = 1e15})[CPSFilter.unit] or 1)) or 0)
        pickup:SetAttribute("MoldyHub_BASAE_CPSPassed", false)
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
        local cps, cpsText = -1, "CPS scan pending"
        local pickupPriority = 5
        if forceUnindexedPickup then
            -- Keep the unindexed override behavior, but still record the animal's real CPS for diagnostics.
            cps, cpsText = GetPetCPS(pickup)
            SetPickupTracking(pickup, cps >= 0 and "CPS checked (unindexed override)" or "CPS read failed (unindexed override)", cpsText)
        else
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
                local minimumCPS = CPSFilter.amount * (scales[CPSFilter.unit] or 1)
                cpsPriorityPickup = cps >= minimumCPS
            end
            if HighestCashEnabled and cps >= 0 then
                local lowestPlaced = GetLowestPlacedCPS()
                aboveLowestPriorityPickup = lowestPlaced >= 0 and cps > lowestPlaced
            end
        end
        if evaluationCancelled() or not pickup.Parent then
            SetPickupTracking(pickup, "Cancelled: automation toggled")
            return
        end
        local selectedRarityCount = 0
        for _, selected in pairs(SelectedRarities) do
            if selected then selectedRarityCount += 1 end
        end
        local anyPickupFilterEnabled = UnindexedOnlyEnabled or HighestCashEnabled
            or KGThresholdAmount > 0 or CPSFilter.amount > 0 or selectedRarityCount > 0
            or PickUpWithMutationEnabled
        local mutationPickupMatch = PickUpWithMutationEnabled
            and GetPickupMutation(pickup) ~= "No Mutation"
            and IsMutationRarityAllowed(pickup)
        local qualified = not anyPickupFilterEnabled or forceUnindexedPickup
            or aboveLowestPriorityPickup or kgPriorityPickup or cpsPriorityPickup or rarityPriorityPickup
            or mutationPickupMatch
        local cpsScales = {K = 1e3, M = 1e6, B = 1e9, T = 1e12, Qa = 1e15}
        local minimumCPS = CPSFilter.amount > 0 and (CPSFilter.amount * (cpsScales[CPSFilter.unit] or 1)) or 0
        pickup:SetAttribute("MoldyHub_BASAE_DetectedCPS", cps >= 0 and cps or nil)
        pickup:SetAttribute("MoldyHub_BASAE_CPSMinimum", minimumCPS)
        pickup:SetAttribute("MoldyHub_BASAE_CPSPassed", CPSFilter.amount <= 0 or (cps >= 0 and cps >= minimumCPS))
        local pickupReason = "No pickup rule matched"
        if forceUnindexedPickup then
            pickupReason = "Unindexed override (bypassed normal filters)"
        elseif aboveLowestPriorityPickup then
            pickupReason = "Above lowest placed CPS"
        elseif kgPriorityPickup then
            pickupReason = "KG threshold matched"
        elseif cpsPriorityPickup then
            pickupReason = "Minimum CPS threshold matched"
        elseif rarityPriorityPickup then
            pickupReason = "Selected rarity matched"
        elseif mutationPickupMatch then
            pickupReason = "Selected mutation matched"
        elseif not anyPickupFilterEnabled then
            pickupReason = "No filters enabled (default pickup)"
        end
        pickup:SetAttribute("MoldyHub_BASAE_PickupReason", qualified and pickupReason or ("Rejected: " .. pickupReason))
        if not qualified then
            local reason = "no enabled pickup rule matched"
            if HighestCashEnabled and cps < 0 then
                reason = "CPS unavailable for Above Lowest $/s"
            elseif CPSFilter.amount > 0 and cps < 0 then
                reason = "CPS unavailable for minimum CPS"
            elseif not rarityPriorityPickup then
                reason = "rarity mismatch and no CPS/KG priority matched"
            end
            SetPickupTracking(pickup, "Rejected: " .. reason, cpsText)
            RejectPickupAndRestart("Filtered out " .. pickup.Name .. " | " .. reason .. ".")
            return
        end
        if forceUnindexedPickup then
            pickupPriority = 1
        elseif aboveLowestPriorityPickup then
            pickupPriority = 2
        elseif kgPriorityPickup then
            pickupPriority = 3
        elseif cpsPriorityPickup then
            pickupPriority = 4
        else
            pickupPriority = 5
        end
        pickup:SetAttribute("MoldyHub_BASAE_Priority", pickupPriority)
        pickup:SetAttribute("MoldyHub_BASAE_Qualified", true)
        if PickupRequested then
            local activePriority = ActivePickup and ActivePickup.Parent and (ActivePickup:GetAttribute("MoldyHub_BASAE_Priority") or 5) or math.huge
            local activeWeight = ActivePickup and ActivePickup.Parent and GetPickupWeightKg(ActivePickup) or nil
            local shouldPreempt = pickupPriority < activePriority
            if pickupPriority == activePriority then
                if pickupPriority == 2 or pickupPriority == 4 then
                    shouldPreempt = cps > ActivePickupCPS
                elseif pickupPriority == 3 then
                    shouldPreempt = pickupWeightKg ~= nil and (activeWeight == nil or pickupWeightKg > activeWeight)
                end
            end
            if shouldPreempt then
                SetPickupTracking(pickup, "Replacing lower-priority pickup (priority " .. tostring(pickupPriority) .. ")", cpsText)
                PickupGeneration += 1
                PickupRequested = false
                if PickupMovementConnection then
                    PickupMovementConnection:Disconnect()
                    PickupMovementConnection = nil
                end
                local oldPickupName = ActivePickup and ActivePickup.Name or "none"
                SetTrackerStatus(string.format("PICKUP LOCK PREEMPT: %s (priority %d, %.2f CPS) replaces %s (priority %s, %.2f CPS) during phase %s.", pickup.Name, pickupPriority, cps, oldPickupName, tostring(activePriority), ActivePickupCPS, PickupPhase))
                local oldCharacter = LocalPlayer.Character
                local oldHumanoid = oldCharacter and oldCharacter:FindFirstChildOfClass("Humanoid")
                if oldHumanoid then oldHumanoid:Move(Vector3.zero, false) end
                task.wait()
            else
                SetPickupTracking(pickup, "Checked: another pickup has priority", cpsText)
                SetTrackerStatus(string.format("Eligible pet %s ignored while %s is locked (priority %s vs %d; CPS %.2f vs %.2f).", pickup.Name, tostring(ActivePickup and ActivePickup.Name or "another pickup"), tostring(activePriority), pickupPriority, cps, ActivePickupCPS))
                return
            end
        end
        PickupGeneration += 1
        local pickupToken = PickupGeneration
        ActivePickup = pickup
        FlingAnimalTarget = pickup
        FlingTargetAnimalName = pickup.Name
        FlingTargetWeightKg = GetAnimalWeightKg(pickup)
        if FlingTargetWeightKg ~= nil then
            SetTrackerStatus("Pickup identity captured: " .. tostring(FlingTargetAnimalName) .. " | WeightKg=" .. tostring(FlingTargetWeightKg))
        end
        task.spawn(function()
            local identityDeadline = os.clock() + 12
            local identityAttempts = 0
            local lastIdentityLog = 0
            while not Runtime.Stopped and PickupGeneration == pickupToken
                and ActivePickup == pickup and FlingTargetWeightKg == nil
                and os.clock() < identityDeadline do
                identityAttempts += 1
                local identityFolder = workspace:FindFirstChild("AnimalPickups")
                if identityFolder then
                    for _, candidate in ipairs(identityFolder:GetChildren()) do
                        if candidate == pickup and candidate.Name == FlingTargetAnimalName then
                            local identity = GetAnimalWeightKg(candidate)
                            if identity ~= nil then
                                FlingTargetWeightKg = identity
                                SetTrackerStatus("Captured pickup identity: " .. tostring(FlingTargetAnimalName) .. " | WeightKg=" .. tostring(identity) .. " | attempts=" .. tostring(identityAttempts))
                                break
                            end
                        end
                    end
                end
                local now = os.clock()
                if FlingTargetWeightKg == nil and now - lastIdentityLog >= 1 then
                    lastIdentityLog = now
                    SetTrackerStatus("Searching AnimalPickups | animal=" .. tostring(FlingTargetAnimalName) .. " | WeightKg=waiting | attempts=" .. tostring(identityAttempts))
                end
                if FlingTargetWeightKg == nil then task.wait(0.25) end
            end
            if FlingTargetWeightKg == nil and PickupGeneration == pickupToken then
                SetTrackerStatus("Initial identity search timed out for " .. tostring(FlingTargetAnimalName) .. "; fling recovery will retry.")
            end
        end)
        ActivePickupCPS = cps
        ActivePickup:SetAttribute("MoldyHub_BASAE_Priority", pickupPriority)
        PickupPhase = "ANIMAL_APPROACH"
        SetPickupTracking(pickup, "Selected for pickup", cpsText)
        PickupRequested = true
        task.delay(45, function()
            if Runtime.Stopped or PickupGeneration ~= pickupToken or not PickupRequested
                or ReturningAfterPickup or ActivePickup ~= pickup then
                return
            end
            SetTrackerStatus("PICKUP WATCHDOG: " .. pickup.Name .. " stayed locked for 45s; releasing stale lock and resuming Auto Break.")
            PickupGeneration += 1
            PickupRequested = false
            ActivePickup = nil
            ActivePickupCPS = -1
            PickupPhase = "IDLE"
            if PickupMovementConnection then PickupMovementConnection:Disconnect(); PickupMovementConnection = nil end
            if ReturnMovementConnection then ReturnMovementConnection:Disconnect(); ReturnMovementConnection = nil end
            if MovementConnection then MovementConnection:Disconnect(); MovementConnection = nil end
            local watchdogCharacter = LocalPlayer.Character
            local watchdogHumanoid = watchdogCharacter and watchdogCharacter:FindFirstChildOfClass("Humanoid")
            if watchdogHumanoid then watchdogHumanoid:Move(Vector3.zero, false) end
            WaitingForPickup = false
            ArrivedAtTarget = false
            task.spawn(function()
                EquipHotbarOne()
                task.wait(0.2)
                if AutoBreakEnabled and not PickupRequested and not ReturningAfterPickup then
                    StartAutoBreak(true)
                end
            end)
        end)
        if StopAutoBreak then StopAutoBreak("Auto Break paused while Auto Pickup handles " .. pickup.Name .. ".", CurrentTarget ~= nil and IsEggAvailable(CurrentTarget)) end
        if MovementConnection then MovementConnection:Disconnect(); MovementConnection = nil end
        local activeCharacter = LocalPlayer.Character
        local activeHumanoid = activeCharacter and activeCharacter:FindFirstChildOfClass("Humanoid")
        if activeHumanoid then activeHumanoid:Move(Vector3.zero, false) end
        SetPickupPhase("ANIMAL_APPROACH", string.format("%s | %.2f CPS | Auto Break paused; animal target owns movement.", pickup.Name, cps))
        local pickupPosition
        local positionOk, position = pcall(function()
            if pickup:IsA("Model") then return pickup:GetPivot().Position end
            if pickup:IsA("BasePart") then return pickup.Position end
        end)
        if positionOk then
            pickupPosition = position
            LastAnimalPickupPosition = position
        end
        local moveCharacter = LocalPlayer.Character
        local moveHumanoid = moveCharacter and moveCharacter:FindFirstChildOfClass("Humanoid")
        local moveRoot = moveCharacter and moveCharacter:FindFirstChild("HumanoidRootPart")
        if not pickupPosition or not moveHumanoid or not moveRoot then
            if PickupGeneration ~= pickupToken then return end
            PickupRequested = false
            ActivePickup = nil
            ActivePickupCPS = -1
            SetTrackerStatus("Pickup cancelled: animal location or character position unavailable.")
            if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
            return
        end
        local pickupZoneName = GetPickupZoneName(pickup)
        local pickupGateWaypoint = pickupZoneName == "Zone13" and not IsInsideZone13(moveRoot.Position)
            and GetZone13GatePosition() or nil
        local animalMoveStarted = os.clock()
        local lastAnimalProgressAt = os.clock()
        local bestAnimalDistance = math.huge
        TouchAutomationProgress("PICKUP:ANIMAL_APPROACH")
        if PickupMovementConnection then
            PickupMovementConnection:Disconnect()
            PickupMovementConnection = nil
        end
        local animalMoveBindName = "MoldyHub_BASAE_PickupAnimal_" .. tostring(pickupToken)
        RunService:BindToRenderStep(animalMoveBindName, Enum.RenderPriority.Character.Value + 1, function()
            if not PickupRequested or PickupGeneration ~= pickupToken or not pickup.Parent
                or LocalPlayer.Character ~= moveCharacter or not moveRoot.Parent
                or moveHumanoid.Health <= 0 then
                moveHumanoid:Move(Vector3.zero, false)
                return
            end
            local ok, currentPosition = pcall(function()
                if pickup:IsA("Model") then return pickup:GetPivot().Position end
                if pickup:IsA("BasePart") then return pickup.Position end
            end)
            if ok and currentPosition then
                local moveTarget = pickupGateWaypoint or currentPosition
                local direction = Vector3.new(moveTarget.X - moveRoot.Position.X, 0, moveTarget.Z - moveRoot.Position.Z)
                if direction.Magnitude <= 4 and pickupGateWaypoint then
                    pickupGateWaypoint = nil
                    direction = Vector3.new(currentPosition.X - moveRoot.Position.X, 0, currentPosition.Z - moveRoot.Position.Z)
                end
                if direction.Magnitude > 4 then
                    moveHumanoid:Move(direction.Unit, false)
                else
                    moveHumanoid:Move(Vector3.zero, false)
                end
            end
        end)
        local animalMoveConnection = {
            Disconnect = function()
                pcall(function() RunService:UnbindFromRenderStep(animalMoveBindName) end)
            end
        }
        PickupMovementConnection = animalMoveConnection
        while not Runtime.Stopped and PickupRequested and PickupGeneration == pickupToken and pickup.Parent and moveHumanoid.Health > 0 do
            if LocalPlayer.Character ~= moveCharacter or not moveCharacter.Parent or not moveRoot.Parent then
                if PickupGeneration ~= pickupToken then return end
                PickupRequested = false
                ActivePickup = nil
                ActivePickupCPS = -1
                SetTrackerStatus("Pickup cancelled: character changed while moving to animal.")
                if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                return
            end
            local ok, currentPosition = pcall(function()
                if pickup:IsA("Model") then return pickup:GetPivot().Position end
                if pickup:IsA("BasePart") then return pickup.Position end
            end)
            if ok and currentPosition then
                pickupPosition = currentPosition
                LastAnimalPickupPosition = currentPosition
            end
            local activePickupTarget = pickupGateWaypoint or pickupPosition
            local animalOffset = Vector3.new(activePickupTarget.X - moveRoot.Position.X, 0, activePickupTarget.Z - moveRoot.Position.Z)
            local animalDistance = animalOffset.Magnitude
            if animalDistance <= 4 and pickupGateWaypoint then
                pickupGateWaypoint = nil
                animalOffset = Vector3.new(pickupPosition.X - moveRoot.Position.X, 0, pickupPosition.Z - moveRoot.Position.Z)
                animalDistance = animalOffset.Magnitude
            end
            if animalDistance <= 4 then break end
            local now = os.clock()
            if now - animalMoveStarted >= 25 then
                moveHumanoid:Move(Vector3.zero, false)
                if PickupGeneration ~= pickupToken then return end
                PickupRequested = false
                ActivePickup = nil
                ActivePickupCPS = -1
                SetTrackerStatus(string.format("Pickup cancelled: timed out reaching animal location (%.1f studs away).", animalDistance))
                if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                return
            end
            if animalDistance < bestAnimalDistance - 0.75 then
                bestAnimalDistance = animalDistance
                lastAnimalProgressAt = now
                TouchAutomationProgress()
            elseif now - lastAnimalProgressAt >= 2.5 then
                lastAnimalProgressAt = now
                bestAnimalDistance = animalDistance
                moveHumanoid:Move(Vector3.zero, false)
                task.wait(0.05)
                if PickupRequested and PickupGeneration == pickupToken and pickup.Parent
                    and LocalPlayer.Character == moveCharacter and moveRoot.Parent and moveHumanoid.Health > 0 then
                    local refreshedPosition
                    local refreshedOk, refreshed = pcall(function()
                        if pickup:IsA("Model") then return pickup:GetPivot().Position end
                        if pickup:IsA("BasePart") then return pickup.Position end
                    end)
                    if refreshedOk then refreshedPosition = refreshed end
                    if refreshedPosition then
                        local refreshedDirection = Vector3.new(
                            refreshedPosition.X - moveRoot.Position.X, 0,
                            refreshedPosition.Z - moveRoot.Position.Z
                        )
                        if refreshedDirection.Magnitude > 4 then
                            moveHumanoid:Move(refreshedDirection.Unit, false)
                        end
                    end
                end
                SetTrackerStatus(string.format("PICKUP MOVEMENT: reset and reinitialized movement toward %s (%.1f studs).", pickup.Name, animalDistance))
            end
            task.wait(0.05)
        end
        if PickupMovementConnection == animalMoveConnection then
            PickupMovementConnection:Disconnect()
            PickupMovementConnection = nil
        end
        if animalMoveConnection then animalMoveConnection:Disconnect(); animalMoveConnection = nil end
        moveHumanoid:Move(Vector3.zero, false)
        if PickupGeneration ~= pickupToken then return end
        if not PickupRequested or not pickup.Parent or not pickupPosition then
            PickupRequested = false
            ActivePickup = nil
            ActivePickupCPS = -1
            SetTrackerStatus("Pickup cancelled: animal disappeared before location verification.")
            if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
            return
        end
        local verifiedAnimalDistance = (Vector3.new(pickupPosition.X, moveRoot.Position.Y, pickupPosition.Z) - moveRoot.Position).Magnitude
        if verifiedAnimalDistance > 5 then
            PickupRequested = false
            ActivePickup = nil
            ActivePickupCPS = -1
            SetTrackerStatus(string.format("Pickup cancelled: animal location verification failed (%.1f studs).", verifiedAnimalDistance))
            if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
            return
        end
        SetPickupPhase("PROMPT_SEARCH", string.format("%s | animal reached (%.1f studs); finding its nearest matching StealPrompt.", pickup.Name, verifiedAnimalDistance))
        local prompt
        local promptState = "StealPrompt not found"
        local promptDeadline = os.clock() + 5
        local promptMatchRadius = 18
        local function getPromptPosition(candidate)
            local parent = candidate and candidate.Parent
            while parent and parent ~= workspace do
                if parent:IsA("Attachment") then
                    return parent.WorldPosition
                elseif parent:IsA("BasePart") then
                    return parent.Position
                elseif parent:IsA("Model") then
                    local ok, pivot = pcall(function() return parent:GetPivot() end)
                    if ok and pivot then return pivot.Position end
                end
                parent = parent.Parent
            end
            return nil
        end
        repeat
            if PickupGeneration ~= pickupToken then return end
            prompt = nil
            local nearestDistance = math.huge
            local totalStealPrompts = 0
            local enabledStealPrompts = 0
            for _, candidate in ipairs(workspace:GetDescendants()) do
                if candidate:IsA("ProximityPrompt") and candidate.Name == "StealPrompt" then
                    totalStealPrompts += 1
                    if candidate.Enabled then
                        enabledStealPrompts += 1
                        local candidatePosition = getPromptPosition(candidate)
                        if candidatePosition then
                            local distance = (candidatePosition - pickupPosition).Magnitude
                            if distance < nearestDistance and distance <= promptMatchRadius then
                                nearestDistance = distance
                                prompt = candidate
                            end
                        end
                    end
                end
            end
            if prompt then
                promptState = string.format("nearest enabled StealPrompt: %s (%.2f studs from animal; found %d total/%d enabled)", prompt:GetFullName(), nearestDistance, totalStealPrompts, enabledStealPrompts)
            else
                promptState = string.format("No enabled StealPrompt within %.0f studs of animal (found %d total/%d enabled)", promptMatchRadius, totalStealPrompts, enabledStealPrompts)
            end
            if prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled then
                break
            end
            task.wait(0.25)
        until os.clock() >= promptDeadline
        if PickupGeneration ~= pickupToken then return end
        if not prompt or not prompt:IsA("ProximityPrompt") or not prompt.Enabled then
            PickupRequested = false
            ActivePickup = nil
            ActivePickupCPS = -1
            SetTrackerStatus("Eligible pet " .. pickup.Name
                .. " but pickup prompt unavailable after 5s: " .. promptState .. ".")
            task.delay(2, function()
                if pickup.Parent and AutoPickupEnabled then PickupMonitorSeen[pickup] = nil end
            end)
            if AutoBreakEnabled and StartAutoBreak then StartAutoBreak(true) end
            return
        end
        SetPickupPhase("PROMPT_APPROACH", pickup.Name .. " | moving to matching StealPrompt; target and movement remain locked.")
        task.spawn(function()
            SetPickupPhase("PROMPT_APPROACH", "Lock held by " .. pickup.Name .. "; moving to its matching prompt.")
            local character, humanoid, root = WaitForCharacterAndParts(10, function()
                return PickupRequested and PickupGeneration == pickupToken and AutoPickupEnabled
            end)
            if not character then
                if PickupGeneration == pickupToken then
                    PickupRequested = false
                    ActivePickup = nil
                    ActivePickupCPS = -1
                    SetTrackerStatus("Pickup cancelled: character parts unavailable while approaching prompt.")
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                end
                return
            end
            local promptPosition = getPromptPosition(prompt)
            if not promptPosition then
                PickupRequested = false
                SetTrackerStatus("Pickup cancelled: could not read matched prompt position.")
                if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                return
            end
            local moveStarted = os.clock()
            local lastPromptProgressAt = os.clock()
            local bestPromptDistance = math.huge
            TouchAutomationProgress("PICKUP:PROMPT_APPROACH")
            if PickupMovementConnection then
                PickupMovementConnection:Disconnect()
                PickupMovementConnection = nil
            end
            local promptMoveBindName = "MoldyHub_BASAE_PickupPrompt_" .. tostring(pickupToken)
            RunService:BindToRenderStep(promptMoveBindName, Enum.RenderPriority.Character.Value + 1, function()
                if not PickupRequested or PickupGeneration ~= pickupToken or not pickup.Parent or not prompt.Parent
                    or LocalPlayer.Character ~= character or not root.Parent or humanoid.Health <= 0 then
                    humanoid:Move(Vector3.zero, false)
                    return
                end
                local livePosition = getPromptPosition(prompt)
                if livePosition then promptPosition = livePosition end
                local direction = Vector3.new(promptPosition.X - root.Position.X, 0, promptPosition.Z - root.Position.Z)
                local verticalOffset = math.abs(promptPosition.Y - root.Position.Y)
                local activationRange = math.max(0, prompt.MaxActivationDistance)
                local horizontalReach = verticalOffset < activationRange
                    and math.sqrt(math.max(0, activationRange * activationRange - verticalOffset * verticalOffset)) - 0.5
                    or 0
                local stopDistance = math.max(1, horizontalReach)
                if direction.Magnitude > stopDistance then
                    humanoid:Move(direction.Unit, false)
                else
                    humanoid:Move(Vector3.zero, false)
                end
            end)
            local promptMoveConnection = {
                Disconnect = function()
                    pcall(function() RunService:UnbindFromRenderStep(promptMoveBindName) end)
                end
            }
            PickupMovementConnection = promptMoveConnection
            while not Runtime.Stopped and PickupRequested and PickupGeneration == pickupToken and pickup.Parent and prompt.Parent and humanoid.Health > 0 do
                if LocalPlayer.Character ~= character or not character.Parent or not root.Parent then
                    if PickupGeneration ~= pickupToken then return end
                    PickupRequested = false
                    ActivePickup = nil
                    ActivePickupCPS = -1
                    SetTrackerStatus("Pickup cancelled: character changed while moving to animal prompt.")
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    return
                end
                promptPosition = getPromptPosition(prompt) or promptPosition
                local offset = Vector3.new(promptPosition.X - root.Position.X, 0, promptPosition.Z - root.Position.Z)
                local promptDistance = offset.Magnitude
                local verticalOffset = math.abs(promptPosition.Y - root.Position.Y)
                local activationRange = math.max(0, prompt.MaxActivationDistance)
                local horizontalReach = verticalOffset < activationRange
                    and math.sqrt(math.max(0, activationRange * activationRange - verticalOffset * verticalOffset)) - 0.5
                    or 0
                local stopDistance = math.max(1, horizontalReach)
                if promptDistance <= stopDistance then break end
                local now = os.clock()
                if now - moveStarted >= 25 then
                    humanoid:Move(Vector3.zero, false)
                    if PickupGeneration ~= pickupToken then return end
                    PickupRequested = false
                    ActivePickup = nil
                    ActivePickupCPS = -1
                    SetTrackerStatus(string.format("Pickup cancelled: timed out reaching animal prompt (%.1f studs away).", promptDistance))
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    return
                end
                if promptDistance < bestPromptDistance - 0.75 then
                    bestPromptDistance = promptDistance
                    lastPromptProgressAt = now
                    TouchAutomationProgress()
                elseif now - lastPromptProgressAt >= 2.5 then
                    lastPromptProgressAt = now
                    bestPromptDistance = promptDistance
                    humanoid:Move(Vector3.zero, false)
                    task.wait(0.05)
                    if PickupRequested and PickupGeneration == pickupToken and pickup.Parent and prompt.Parent
                        and LocalPlayer.Character == character and root.Parent and humanoid.Health > 0 then
                        local refreshedPromptPosition = getPromptPosition(prompt)
                        if refreshedPromptPosition then promptPosition = refreshedPromptPosition end
                        local refreshedOffset = Vector3.new(
                            promptPosition.X - root.Position.X, 0,
                            promptPosition.Z - root.Position.Z
                        )
                        local refreshedVerticalOffset = math.abs(promptPosition.Y - root.Position.Y)
                        local refreshedRange = math.max(0, prompt.MaxActivationDistance)
                        local refreshedReach = refreshedVerticalOffset < refreshedRange
                            and math.sqrt(math.max(0, refreshedRange * refreshedRange - refreshedVerticalOffset * refreshedVerticalOffset)) - 0.5
                            or 0
                        if refreshedOffset.Magnitude > math.max(1, refreshedReach) then
                            humanoid:Move(refreshedOffset.Unit, false)
                        end
                    end
                    SetTrackerStatus(string.format("PICKUP MOVEMENT: reset and reinitialized movement toward StealPrompt (%.1f studs).", promptDistance))
                end
                task.wait(0.05)
            end
            if PickupMovementConnection == promptMoveConnection then
                PickupMovementConnection:Disconnect()
                PickupMovementConnection = nil
            end
            if promptMoveConnection then promptMoveConnection:Disconnect(); promptMoveConnection = nil end
            humanoid:Move(Vector3.zero, false)
            if PickupGeneration ~= pickupToken then return end
            if not PickupRequested or not pickup.Parent then
                PickupRequested = false
                ActivePickup = nil
                ActivePickupCPS = -1
                SetTrackerStatus("Pickup cancelled: animal disappeared before reaching its prompt.")
                if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                return
            end
            SetPickupPhase("ACTIVATING", "Reached " .. pickup.Name .. "'s matching StealPrompt; activating immediately when the prompt is ready.")
            if PickupGeneration ~= pickupToken then return end
            if LocalPlayer.Character ~= character or not character.Parent or humanoid.Health <= 0 or not root.Parent then
                PickupRequested = false
                ActivePickup = nil
                ActivePickupCPS = -1
                SetTrackerStatus("Pickup cancelled: character changed or became unavailable.")
                if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                return
            end
            if not PickupRequested or not pickup.Parent then
                PickupRequested = false
                ActivePickup = nil
                ActivePickupCPS = -1
                SetTrackerStatus("Pickup cancelled: animal disappeared before activation.")
                if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                return
            end
            if PickupGeneration ~= pickupToken then return end
            if not prompt.Parent or not prompt.Enabled then
                PickupRequested = false
                ActivePickup = nil
                ActivePickupCPS = -1
                SetTrackerStatus("Pickup cancelled: StealPrompt became unavailable before activation.")
                if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                return
            end
            local latestPromptPosition = getPromptPosition(prompt)
            local latestPromptDistance = latestPromptPosition and (latestPromptPosition - root.Position).Magnitude or math.huge
            if not prompt.Parent or not prompt.Enabled or latestPromptDistance > math.max(4, prompt.MaxActivationDistance) then
                PickupRequested = false
                ActivePickup = nil
                ActivePickupCPS = -1
                SetTrackerStatus(string.format("Pickup cancelled: prompt range changed before activation (%.1f studs).", latestPromptDistance))
                if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                return
            end
            local pickupConfirmed = false
            local activationErrors = {}
            local activationDeadline = os.clock() + 15
            local activationAttempt = 0
            while not pickupConfirmed and os.clock() < activationDeadline do
                if PickupGeneration ~= pickupToken or not PickupRequested or not AutoPickupEnabled then return end
                if not pickup.Parent then pickupConfirmed = true; break end
                if not prompt.Parent or not prompt.Enabled then
                    task.wait(0.25)
                else
                    activationAttempt += 1
                    local currentPromptPosition = getPromptPosition(prompt)
                    local currentPromptDistance = currentPromptPosition and (currentPromptPosition - root.Position).Magnitude or math.huge
                    if currentPromptDistance <= prompt.MaxActivationDistance then
                        local holdOk, holdErr = pcall(function()
                            if typeof(fireproximityprompt) == "function" then
                                fireproximityprompt(prompt)
                                if prompt.HoldDuration > 0 then task.wait(prompt.HoldDuration + 0.15) end
                            else
                                prompt:InputHoldBegin()
                                task.wait(prompt.HoldDuration + 0.1)
                                prompt:InputHoldEnd()
                            end
                        end)
                        if not holdOk then
                            table.insert(activationErrors, tostring(holdErr))
                            pcall(function() prompt:InputHoldEnd() end)
                        end
                        local confirmDeadline = os.clock() + 0.75
                        while not Runtime.Stopped and os.clock() < confirmDeadline
                            and PickupGeneration == pickupToken and PickupRequested and pickup.Parent do
                            task.wait(0.05)
                        end
                        if not pickup.Parent then pickupConfirmed = true
                        elseif activationAttempt == 1 or activationAttempt % 3 == 0 then
                            SetTrackerStatus("StealPrompt still unchecked for " .. pickup.Name .. "; retry " .. tostring(activationAttempt) .. ".")
                        end
                    else
                        SetTrackerStatus(string.format("Waiting for StealPrompt range for %s (%.1f/%.1f studs).",
                            pickup.Name, currentPromptDistance, prompt.MaxActivationDistance))
                        task.wait(0.25)
                    end
                end
                if not pickupConfirmed then task.wait(0.2) end
            end
            if PickupGeneration ~= pickupToken then return end
            if not pickupConfirmed then
                PickupRequested = false
                ActivePickup = nil
                ActivePickupCPS = -1
                PickupPhase = "IDLE"
                local detail = #activationErrors > 0 and (" Activation error: " .. table.concat(activationErrors, " | ")) or ""
                SetPickupTracking(pickup, "Retry timeout: steal not confirmed", detail)
                SetTrackerStatus("StealPrompt retry window expired for " .. pickup.Name .. "; released pickup lock." .. detail)
                PickupMonitorSeen[pickup] = nil
                if AutoBreakEnabled and StartAutoBreak then StartAutoBreak(true) end
                return
            end
            SetPickupTracking(pickup, "Collected", cpsText)
            SetPickupPhase("CONFIRMED", "Collected " .. pickup.Name .. "; releasing target lock and returning to base.")
            ActivePickup = nil
            ActivePickupCPS = -1
            ReturnToPickup("Pickup confirmed. Returning straight to base.")
        end)
    end
    function QueuePendingAnimalPickup(pickup)
        if not pickup or not pickup.Parent or PendingAnimalPickupSet[pickup] then return end
        PendingAnimalPickupSet[pickup] = true
        table.insert(PendingAnimalPickups, pickup)
        SetTrackerStatus("NEW ANIMAL queued: " .. pickup.Name .. " | current pickup/return lock is active; will evaluate when movement is released.")
        if PendingAnimalPickupWorker then return end
        PendingAnimalPickupWorker = true
        task.spawn(function()
            while not Runtime.Stopped and not ScriptShuttingDown and #PendingAnimalPickups > 0 do
                if not AutoPickupEnabled then
                    -- Keep the queue and its de-duplication markers intact while disabled.
                    task.wait(0.25)
                elseif not PickupRequested and not ReturningAfterPickup and not FlingRecoveryActive then
                    local nextPickup = table.remove(PendingAnimalPickups, 1)
                    if nextPickup then PendingAnimalPickupSet[nextPickup] = nil end
                    if nextPickup and nextPickup.Parent then
                        local ok, err = xpcall(function()
                            EvaluatePickup(nextPickup)
                        end, debug.traceback)
                        if not ok then
                            SetTrackerStatus("Queued pickup evaluation failed for " .. tostring(nextPickup.Name) .. ": " .. tostring(err):gsub("[%r\n]+", " "):sub(1, 180))
                        end
                        task.wait(0.25)
                    else
                        task.wait()
                    end
                else
                    task.wait(0.5)
                end
            end
            PendingAnimalPickupWorker = false
        end)
    end
    function BindAnimalPickups(folder)
        if not folder or not folder:IsA("Folder") and not folder:IsA("Model") then return end
        AnimalPickups = folder
        for _, existingPickup in ipairs(folder:GetChildren()) do
            if existingPickup:IsA("Model") then
                existingPickup:SetAttribute("MoldyHub_BASAE_Rarity", tostring(GetPetRarity(existingPickup) or "Unknown"))
                UpdatePickupMutationAttributes(existingPickup)
            end
        end
        TrackPersistentConnection(folder.ChildAdded:Connect(function(pickup)
            PickupMonitorSeen[pickup] = nil
            local pickupRarity = tostring(GetPetRarity(pickup) or "Unknown")
            SetPickupTracking(pickup, "Detected")
            pickup:SetAttribute("MoldyHub_BASAE_Rarity", pickupRarity)
            UpdatePickupMutationAttributes(pickup)
            if not AutoPickupEnabled then
                SetTrackerStatus("NEW ANIMAL: " .. pickup.Name .. " | rarity=" .. pickupRarity .. " | monitoring waits until Auto Pickup is ON.")
                return
            end
            PickupMonitorSeen[pickup] = true
            QueuePendingAnimalPickup(pickup)
        end))
        TrackPersistentConnection(folder.ChildRemoved:Connect(function(pickup)
            PickupMonitorSeen[pickup] = nil
            PendingAnimalPickupSet[pickup] = nil
        end))
        SetTrackerStatus("AnimalPickups folder detected; continuous monitoring is ready.")
    end
    if AnimalPickups then BindAnimalPickups(AnimalPickups) end
    task.spawn(function()
        while not Runtime.Stopped and not ScriptShuttingDown do
            if AutoPickupEnabled and AnimalPickups and AnimalPickups.Parent then
                for _, pickup in ipairs(AnimalPickups:GetChildren()) do
                    if pickup.Parent == AnimalPickups and not PickupMonitorSeen[pickup] then
                        PickupMonitorSeen[pickup] = true
                        QueuePendingAnimalPickup(pickup)
                    end
                end
            end
            task.wait(0.3)
        end
    end)
    local CatchFlingRemote = game:GetService("ReplicatedStorage"):WaitForChild("CatchFlingRemote")
    HandleFlingRecovery = function(action, flingPosition, duration, strength, carriedAnimalLost)
        if tostring(action):lower() ~= "fling" then return end
        if AntiPaloEnabled and not carriedAnimalLost then
            local released, releaseError = pcall(function()
                if type(firesignal) ~= "function" then
                    error("firesignal is unavailable in this executor")
                end
                firesignal(CatchFlingRemote.OnClientEvent, "release")
            end)
            if released then
                AddDebugLog("[Anti Knockback] Fling release signal fired.")
            else
                AddDebugLog("[Anti Knockback] Fling release failed: " .. tostring(releaseError))
            end
        end
        if not AutoPickupEnabled then
            SetTrackerStatus("Fling detected: recovery cancelled because Auto Pickup is OFF.")
            return
        end
        if FlingRecoveryActive then
            SetTrackerStatus("Fling recovery event received while recovery is active; ignoring duplicate trigger.")
            return
        end
        if carriedAnimalLost and not ReturningAfterPickup and not PickupRequested then return end
        if not carriedAnimalLost and not CarriedAnimalWatch.model and not ReturningAfterPickup and not PickupRequested then
            SetTrackerStatus("Fling event ignored: no active animal pickup or carried animal.")
            return
        end
        local flingAnimal = ActivePickup or FlingAnimalTarget
        local targetAnimalName = (flingAnimal and flingAnimal.Name) or FlingTargetAnimalName
        local targetWeightKg = FlingTargetWeightKg
        if not targetAnimalName then
            SetTrackerStatus("Fling recovery skipped: tracked animal name is unavailable.")
            return
        end
        local function findTrackedAnimal()
            local folder = workspace:FindFirstChild("AnimalPickups")
            if not folder or not targetAnimalName then return nil end
    
            local targetWeight = ParseWeightKg(targetWeightKg)
            if flingAnimal and flingAnimal.Parent == folder and flingAnimal.Name == targetAnimalName then
                local liveWeight = ParseWeightKg(GetAnimalWeightKg(flingAnimal))
                if targetWeight == nil or liveWeight == nil or math.abs(liveWeight - targetWeight) <= math.max(0.001, math.abs(targetWeight) * 0.000001) then
                    return flingAnimal
                end
            end
    
            local character = LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local bestMatch, bestDistance
            local nearestNameMatch, nearestNameDistance
            local hasReadableWeight = false
    
            for _, candidate in ipairs(folder:GetChildren()) do
                if candidate.Name == targetAnimalName then
                    local candidateWeight = ParseWeightKg(GetAnimalWeightKg(candidate))
                    local ok, position = pcall(function()
                        if candidate:IsA("Model") then return candidate:GetPivot().Position end
                        if candidate:IsA("BasePart") then return candidate.Position end
                    end)
                    if ok and position then
                        local distance = root and (position - root.Position).Magnitude or 0
                        if not nearestNameDistance or distance < nearestNameDistance then
                            nearestNameMatch, nearestNameDistance = candidate, distance
                        end
                        if candidateWeight ~= nil then
                            hasReadableWeight = true
                        end
                        if targetWeight ~= nil and candidateWeight ~= nil then
                            local tolerance = math.max(0.001, math.abs(targetWeight) * 0.000001)
                            if math.abs(candidateWeight - targetWeight) <= tolerance then
                                if not bestDistance or distance < bestDistance then
                                    bestMatch, bestDistance = candidate, distance
                                end
                            end
                        end
                    end
                end
            end
    
            if bestMatch then
                flingAnimal = bestMatch
                return bestMatch
            end
            if targetWeight ~= nil and hasReadableWeight then
                return nil
            end
            if nearestNameMatch then flingAnimal = nearestNameMatch end
            return nearestNameMatch
        end
        local function getTrackedAnimalPosition()
            local animal = findTrackedAnimal()
            if not animal then return nil end
            local ok, position = pcall(function()
                if animal:IsA("Model") then return animal:GetPivot().Position end
                if animal:IsA("BasePart") then return animal.Position end
            end)
            return ok and position or nil
        end
    
        if ReturnMovementConnection then
            ReturnMovementConnection:Disconnect()
            ReturnMovementConnection = nil
        end
        if PickupMovementConnection then
            PickupMovementConnection:Disconnect()
            PickupMovementConnection = nil
        end
        if MovementConnection then
            MovementConnection:Disconnect()
            MovementConnection = nil
        end
        ReturningAfterPickup = false
        local interruptedCharacter = LocalPlayer.Character
        local interruptedHumanoid = interruptedCharacter and interruptedCharacter:FindFirstChildOfClass("Humanoid")
        if interruptedHumanoid then interruptedHumanoid:Move(Vector3.zero, false) end
    
        FlingRecoveryActive = true
        local recoverySearchToken = PickupGeneration
        TouchAutomationProgress("FLING_RECOVERY:FIND_DROPPED_ANIMAL")
        if not FlingRecoveryActive or PickupGeneration ~= recoverySearchToken then
            return
        end
        if PickupMovementConnection then PickupMovementConnection:Disconnect(); PickupMovementConnection = nil end
        if MovementConnection then MovementConnection:Disconnect(); MovementConnection = nil end
        if ReturnMovementConnection then ReturnMovementConnection:Disconnect(); ReturnMovementConnection = nil end
        ReturningAfterPickup = false
        PickupGeneration += 1
        local flingToken = PickupGeneration
        ActivePickup = nil
        ActivePickupCPS = -1
        PickupRequested = true
        if StopAutoBreak then StopAutoBreak("Auto Break paused for fling recovery.", CurrentTarget ~= nil and IsEggAvailable(CurrentTarget)) end
        if MovementConnection then MovementConnection:Disconnect(); MovementConnection = nil end
        SetTrackerStatus("Base return paused. FLING RECOVERY locating dropped " .. tostring(targetAnimalName) .. " in AnimalPickups.")
        task.spawn(function()
            local recoveryMoveBindName
            local recoveryHumanoid
            local originalAutoRotate
            local function cleanupFlingRecovery()
                if recoveryHumanoid and recoveryHumanoid.Parent and originalAutoRotate ~= nil then
                    recoveryHumanoid.AutoRotate = originalAutoRotate
                    originalAutoRotate = nil
                end
                if recoveryMoveBindName then
                    pcall(function()
                        game:GetService("RunService"):UnbindFromRenderStep(recoveryMoveBindName)
                    end)
                    recoveryMoveBindName = nil
                end
                FlingRecoveryActive = false
                if CancelFlingRecovery == cleanupFlingRecovery then
                    CancelFlingRecovery = nil
                end
                if PendingReturnAfterFling then
                    local pendingReason = PendingReturnAfterFlingReason
                    PendingReturnAfterFling = false
                    PendingReturnAfterFlingReason = nil
                    ReturnToPickup(pendingReason or "Fling recovery finished. Returning to base.")
                end
            end
            CancelFlingRecovery = cleanupFlingRecovery
            local function finishFlingRecovery()
                cleanupFlingRecovery()
                if AutoBreakEnabled and not PickupRequested and not ReturningAfterPickup and StartAutoBreak then
                    task.delay(0.25, function()
                        if not FlingRecoveryActive and AutoBreakEnabled and not PickupRequested and not ReturningAfterPickup then
                            StartAutoBreak()
                        end
                    end)
                end
            end
            if PickupGeneration ~= flingToken or not FlingRecoveryActive then
                finishFlingRecovery()
                return
            end
            local character, humanoid, root = WaitForCharacterAndParts(10, function()
                return PickupGeneration == flingToken and PickupRequested and FlingRecoveryActive
            end)
            if not character then
                if PickupGeneration ~= flingToken or not FlingRecoveryActive then
                    cleanupFlingRecovery()
                    return
                end
                PickupRequested = false
                SetTrackerStatus("FLING RECOVERY cancelled: character parts unavailable.")
                finishFlingRecovery()
                return
            end
            recoveryHumanoid = humanoid
            originalAutoRotate = humanoid.AutoRotate
            humanoid.AutoRotate = false
            if PickupGeneration ~= flingToken or not PickupRequested or not AutoPickupEnabled then
                finishFlingRecovery()
                return
            end
            local recoveryPosition = getTrackedAnimalPosition()
            if carriedAnimalLost and not recoveryPosition then
                local animalWaitDeadline = os.clock() + 2.5
                repeat
                    task.wait(0.1)
                    recoveryPosition = getTrackedAnimalPosition()
                until recoveryPosition or os.clock() >= animalWaitDeadline
                    or Runtime.Stopped or PickupGeneration ~= flingToken or not FlingRecoveryActive
            end
            if not recoveryPosition then
                PickupRequested = false
                SetTrackerStatus("FLING RECOVERY cancelled: dropped animal was not found in AnimalPickups (" .. tostring(targetAnimalName) .. ").")
                finishFlingRecovery()
                return
            end
            local function positionOf(candidate)
                local parent = candidate and candidate.Parent
                while parent and parent ~= workspace do
                    if parent:IsA("Attachment") then return parent.WorldPosition end
                    if parent:IsA("BasePart") then return parent.Position end
                    if parent:IsA("Model") then return parent:GetPivot().Position end
                    parent = parent.Parent
                end
                return nil
            end
            local function findNearbyStealPrompt()
                local anchor = workspace:FindFirstChild("PromptAnchor")
                if not anchor then return nil, nil end
                local nearest = math.huge
                local bestPrompt, bestPosition
                for _, candidate in ipairs(anchor:GetDescendants()) do
                    if candidate:IsA("ProximityPrompt") and candidate.Name == "StealPrompt" and candidate.Enabled then
                        local pos = positionOf(candidate)
                        if pos then
                            local distance = (pos - recoveryPosition).Magnitude
                            if distance < nearest and distance <= 12 then
                                nearest, bestPrompt, bestPosition = distance, candidate, pos
                            end
                        end
                    end
                end
                return bestPrompt, bestPosition
            end
            local prompt, promptPosition = findNearbyStealPrompt()
            local promptLogged = prompt ~= nil
            if prompt then
                SetTrackerStatus(string.format("FLING RECOVERY cached StealPrompt %.1f studs from animal; moving immediately.", (promptPosition - recoveryPosition).Magnitude))
            else
                SetTrackerStatus("FLING RECOVERY: searching for StealPrompt while moving toward the animal.")
            end
            SetTrackerStatus(string.format(
                "FLING RECOVERY found dropped %s in AnimalPickups at (%.3f, %.3f, %.3f).",
                tostring(flingAnimal and flingAnimal.Name or targetAnimalName or "animal"),
                recoveryPosition.X, recoveryPosition.Y, recoveryPosition.Z
            ))
            local RunService = game:GetService("RunService")
            recoveryMoveBindName = "MoldyHub_BASAE_FlingRecovery_" .. tostring(flingToken)
            RunService:BindToRenderStep(recoveryMoveBindName, Enum.RenderPriority.Character.Value + 1, function()
                if Runtime.Stopped or not PickupRequested or PickupGeneration ~= flingToken
                    or LocalPlayer.Character ~= character or not root.Parent or humanoid.Health <= 0 then
                    humanoid:Move(Vector3.zero, false)
                    return
                end
                local livePosition = getTrackedAnimalPosition()
                if livePosition then recoveryPosition = livePosition end
                local moveOffset = Vector3.new(recoveryPosition.X - root.Position.X, 0, recoveryPosition.Z - root.Position.Z)
                if moveOffset.Magnitude > 4 then
                    humanoid:Move(moveOffset.Unit, false)
                else
                    humanoid:Move(Vector3.zero, false)
                end
            end)
            local moveStarted = os.clock()
            local lastProgressAt = os.clock()
            local bestDistance = math.huge
            TouchAutomationProgress("FLING_RECOVERY:ANIMAL_APPROACH")
            while not Runtime.Stopped and PickupRequested and PickupGeneration == flingToken and humanoid.Health > 0 do
                if LocalPlayer.Character ~= character or not character.Parent or not root.Parent then
                    PickupRequested = false
                    SetTrackerStatus("FLING RECOVERY cancelled: character changed or root became unavailable.")
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    finishFlingRecovery()
                    return
                end
                local livePosition = getTrackedAnimalPosition()
                if livePosition then recoveryPosition = livePosition end
                if not prompt then
                    prompt, promptPosition = findNearbyStealPrompt()
                    if prompt and not promptLogged then
                        promptLogged = true
                        SetTrackerStatus(string.format("FLING RECOVERY found StealPrompt while moving (%.1f studs from animal).", (promptPosition - recoveryPosition).Magnitude))
                    end
                end
                local offset = Vector3.new(recoveryPosition.X - root.Position.X, 0, recoveryPosition.Z - root.Position.Z)
                local distance = offset.Magnitude
                if distance <= 4 then break end
                local now = os.clock()
                if now - moveStarted >= 45 then
                    humanoid:Move(Vector3.zero, false)
                    PickupRequested = false
                    SetTrackerStatus(string.format("FLING RECOVERY cancelled: timed out reaching the animal location (%.1f studs away).", distance))
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    finishFlingRecovery()
                    return
                end
                if distance < bestDistance - 0.75 then
                    bestDistance = distance
                    lastProgressAt = now
                    TouchAutomationProgress()
                elseif now - lastProgressAt >= 2.5 then
                    local state = humanoid:GetState()
                    if state == Enum.HumanoidStateType.FallingDown
                        or state == Enum.HumanoidStateType.Ragdoll
                        or state == Enum.HumanoidStateType.Physics
                        or state == Enum.HumanoidStateType.PlatformStanding then
                        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                    end
                    lastProgressAt = now
                    bestDistance = distance
                    if humanoid.PlatformStand then humanoid.PlatformStand = false end
                    if root.Anchored then
                        SetTrackerStatus(string.format("FLING RECOVERY blocked: HumanoidRootPart is anchored (%.1f studs away).", distance))
                    else
                        SetTrackerStatus(string.format("FLING RECOVERY: movement input refreshed every frame; no progress yet (%.1f studs away, state=%s).", distance, tostring(state)))
                    end
                end
                task.wait(0.1)
            end
            if recoveryMoveBindName then
                pcall(function() RunService:UnbindFromRenderStep(recoveryMoveBindName) end)
                recoveryMoveBindName = nil
            end
            humanoid:Move(Vector3.zero, false)
            local arrivalDistance = (Vector3.new(recoveryPosition.X, root.Position.Y, recoveryPosition.Z) - root.Position).Magnitude
            if PickupGeneration ~= flingToken then
                finishFlingRecovery()
                return
            end
            if not PickupRequested or humanoid.Health <= 0 or arrivalDistance > 5 then
                PickupRequested = false
                SetTrackerStatus(string.format("FLING RECOVERY cancelled: arrival verification failed (%.1f studs).", arrivalDistance))
                if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                finishFlingRecovery()
                return
            end
            local searchDeadline = os.clock() + 1.5
            if not prompt then
                SetTrackerStatus(string.format("FLING RECOVERY arrived near animal (%.1f studs); brief final StealPrompt check.", arrivalDistance))
                repeat
                    local livePosition = getTrackedAnimalPosition()
                    if livePosition then recoveryPosition = livePosition end
                    prompt, promptPosition = findNearbyStealPrompt()
                    if prompt then break end
                    task.wait(0.1)
                until os.clock() >= searchDeadline or PickupGeneration ~= flingToken
            end
            if PickupGeneration ~= flingToken then
                finishFlingRecovery()
                return
            end
            if not prompt or not prompt.Parent or not prompt.Enabled or not promptPosition then
                PickupRequested = false
                SetTrackerStatus("FLING RECOVERY failed: no enabled StealPrompt within 12 studs of the current animal location.")
                if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                finishFlingRecovery()
                return
            end
            SetTrackerStatus(string.format("FLING RECOVERY found nearest prompt %.1f studs from the animal; verifying prompt position.", (promptPosition - recoveryPosition).Magnitude))
            local moveStarted = os.clock()
            local bestPromptDistance = math.huge
            TouchAutomationProgress("FLING_RECOVERY:PROMPT_APPROACH")
            while not Runtime.Stopped and PickupRequested and PickupGeneration == flingToken and prompt.Parent and prompt.Enabled and humanoid.Health > 0 do
                promptPosition = positionOf(prompt) or promptPosition
                local locationError = (promptPosition - recoveryPosition).Magnitude
                if locationError > 14 then
                    humanoid:Move(Vector3.zero, false)
                    PickupRequested = false
                    SetTrackerStatus(string.format("FLING RECOVERY cancelled: prompt moved %.1f studs away from the animal location.", locationError))
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    finishFlingRecovery()
                    return
                end
                local offset = Vector3.new(promptPosition.X - root.Position.X, 0, promptPosition.Z - root.Position.Z)
                local distanceToPrompt = (promptPosition - root.Position).Magnitude
                if distanceToPrompt < bestPromptDistance - 0.75 then
                    bestPromptDistance = distanceToPrompt
                    TouchAutomationProgress()
                end
                if distanceToPrompt <= math.min(prompt.MaxActivationDistance, 5) then break end
                if os.clock() - moveStarted >= 25 then
                    humanoid:Move(Vector3.zero, false)
                    PickupRequested = false
                    SetTrackerStatus("FLING RECOVERY cancelled: timed out reaching the verified prompt.")
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    finishFlingRecovery()
                    return
                end
                humanoid:Move(offset.Magnitude > 0 and offset.Unit or Vector3.zero, false)
                task.wait(0.05)
            end
            humanoid:Move(Vector3.zero, false)
            if PickupGeneration ~= flingToken then
                finishFlingRecovery()
                return
            end
            if not PickupRequested or not prompt.Parent or not prompt.Enabled or humanoid.Health <= 0 then
                PickupRequested = false
                SetTrackerStatus("FLING RECOVERY cancelled: prompt or character became unavailable.")
                if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                finishFlingRecovery()
                return
            end
            promptPosition = positionOf(prompt) or promptPosition
            local finalPlayerDistance = (promptPosition - root.Position).Magnitude
            local finalLocationError = (promptPosition - recoveryPosition).Magnitude
            if finalPlayerDistance > math.min(prompt.MaxActivationDistance, 5) or finalLocationError > 14 then
                PickupRequested = false
                SetTrackerStatus(string.format("FLING RECOVERY blocked by location verification: player=%.1f studs, animal mismatch=%.1f studs.", finalPlayerDistance, finalLocationError))
                if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                finishFlingRecovery()
                return
            end
            task.wait(0.15)
            if PickupGeneration ~= flingToken then
                finishFlingRecovery()
                return
            end
            promptPosition = positionOf(prompt) or promptPosition
            if LocalPlayer.Character ~= character or not character.Parent or humanoid.Health <= 0
                or not prompt.Parent or not prompt.Enabled
                or (promptPosition - root.Position).Magnitude > math.min(prompt.MaxActivationDistance, 5)
                or (promptPosition - recoveryPosition).Magnitude > 14 then
                PickupRequested = false
                SetTrackerStatus("FLING RECOVERY blocked: prompt moved outside the verified pickup range.")
                if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                finishFlingRecovery()
                return
            end
            local ok, err = pcall(function()
                if typeof(fireproximityprompt) == "function" then
                    fireproximityprompt(prompt)
                else
                    prompt:InputHoldBegin()
                    task.wait(prompt.HoldDuration + 0.1)
                    prompt:InputHoldEnd()
                end
            end)
            if PickupGeneration ~= flingToken then
                finishFlingRecovery()
                return
            end
            if not ok then
                pcall(function() prompt:InputHoldEnd() end)
                PickupRequested = false
                SetTrackerStatus("FLING RECOVERY pickup failed: " .. tostring(err))
                if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                finishFlingRecovery()
                return
            end
            SetTrackerStatus("FLING RECOVERY prompt activated; confirming animal collection.")
            local confirmed = false
            local confirmDeadline = os.clock() + 4
            while not Runtime.Stopped and os.clock() < confirmDeadline and PickupGeneration == flingToken and PickupRequested do
                local folder = workspace:FindFirstChild("AnimalPickups")
                local targetStillExists = false
                if folder then
                    for _, animal in ipairs(folder:GetChildren()) do
                        if animal.Name == targetAnimalName then
                            targetStillExists = true
                            break
                        end
                    end
                    if not targetStillExists then confirmed = true; break end
                end
                task.wait(0.1)
            end
            if PickupGeneration ~= flingToken then
                finishFlingRecovery()
                return
            end
            if not confirmed then
                PickupRequested = false
                SetTrackerStatus("FLING RECOVERY: prompt activated but collection was not confirmed; staying in place.")
                if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                finishFlingRecovery()
                return
            end
            SetTrackerStatus("FLING RECOVERY collection confirmed; resuming base return to the saved base position.")
            finishFlingRecovery()
            ReturnToPickup("Fling recovery pickup confirmed. Returning to saved base position.")
        end)
    end
    FlingRemoteConnection = TrackPersistentConnection(CatchFlingRemote.OnClientEvent:Connect(HandleFlingRecovery))
    CarriedAnimalWatch.Bind = function(folder)
        if not folder or not folder:IsA("Folder") or CarriedAnimalWatch.folder == folder then return end
        CarriedAnimalWatch.folder = folder
        local function observeCarriedAnimal(model)
            if model and model.Name == "CarriedAnimal" then
                CarriedAnimalWatch.model = model
                CarriedAnimalWatch.seen = true
            end
        end
        for _, child in ipairs(folder:GetChildren()) do observeCarriedAnimal(child) end
        CarriedAnimalWatch.childAdded = TrackPersistentConnection(folder.ChildAdded:Connect(function(child)
            observeCarriedAnimal(child)
        end))
        CarriedAnimalWatch.childRemoved = TrackPersistentConnection(folder.ChildRemoved:Connect(function(child)
            if child ~= CarriedAnimalWatch.model or not CarriedAnimalWatch.seen then return end
            local removedModel = child
            CarriedAnimalWatch.model = nil
            CarriedAnimalWatch.seen = false
            local carriedWeight = GetAnimalWeightKg(removedModel)
            if FlingTargetWeightKg == nil and carriedWeight ~= nil then
                FlingTargetWeightKg = carriedWeight
            end
            task.defer(function()
                if Runtime.Stopped or ScriptShuttingDown or CarriedAnimalWatch.model ~= nil
                    or not AutoPickupEnabled or not AutoBreakEnabled
                    or (not ReturningAfterPickup and not PickupRequested) then return end
                local character = LocalPlayer.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                if root and (root.Position - BaseReturnPosition).Magnitude <= 10 then
                    SetTrackerStatus("CarriedAnimal disappeared near base; treating it as a normal bank instead of recovery.")
                    return
                end
                SetTrackerStatus("CarriedAnimal disappeared while away from base; starting fast animal-location recovery.")
                if HandleFlingRecovery then HandleFlingRecovery("fling", nil, nil, nil, true) end
            end)
        end))
        SetTrackerStatus("CarriedAnimals folder connected; watching CarriedAnimal presence.")
    end
    local existingCarriedFolder = workspace:FindFirstChild("CarriedAnimals")
    if existingCarriedFolder then CarriedAnimalWatch.Bind(existingCarriedFolder) end
    AnimalFolderConnection = TrackPersistentConnection(workspace.ChildAdded:Connect(function(child)
        if child.Name == "AnimalPickups" and not AnimalPickups then
            BindAnimalPickups(child)
        elseif child.Name == "CarriedAnimals" then
            CarriedAnimalWatch.Bind(child)
        end
    end))
    StopAutoBreak = function(reason, preserveTargetState)
        TouchAutomationProgress(AutoBreakEnabled and "AUTO_BREAK_PAUSED" or "AUTO_BREAK_OFF")
        if MovementConnection then
            MovementConnection:Disconnect()
            MovementConnection = nil
        end
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid and not PickupRequested and not ReturningAfterPickup then
            humanoid:Move(Vector3.zero, false)
        end
        ArrivedAtTarget = false
        if not preserveTargetState then
            WaitingForPickup = false
            CurrentTarget = nil
        end
        if reason then
            SetTrackerStatus(reason)
        end
    end
    StartAutoBreak = function(forceRefresh)
        if not AutoBreakEnabled or ScriptShuttingDown then return end
        local startGeneration = AutoBreakGeneration
        TouchAutomationProgress("AUTO_BREAK:SELECTING_TARGET")
        if FlingRecoveryActive then
            SetTrackerStatus("Auto Break paused: fling recovery owns movement until the animal pickup attempt finishes.")
            return
        end
        if not AutoBreakEnabled then
            SetTrackerStatus("Auto Break start ignored: toggle is OFF.")
            return
        end
        if PickupRequested or ReturningAfterPickup then
            SetTrackerStatus("Auto Break start ignored: pickup/return is in progress.")
            return
        end
        if WaitingForPickup then
            SetTrackerStatus("Auto Break start ignored: broken target is waiting for its AnimalPickups entry.")
            return
        end
        local lockedTarget = CurrentTarget
        if lockedTarget and IsEggConfirmedComplete(lockedTarget) then
            CompletedEggs[lockedTarget] = true
            lockedTarget = nil
            SetTrackerStatus("Current egg HP reached 0; releasing target lock.")
        elseif lockedTarget and not IsEggAvailable(lockedTarget) then
            lockedTarget = nil
        end
        if lockedTarget and not forceRefresh and (MovementConnection ~= nil or ArrivedAtTarget) then
            return
        end
        StopAutoBreak(nil, lockedTarget ~= nil)
        local selectedZoneNames = {}
        for zoneName, selected in pairs(SelectedZones) do
            if selected then
                table.insert(selectedZoneNames, zoneName)
            end
        end
        table.sort(selectedZoneNames)
        local target = lockedTarget
        if not target then
            local priorityCandidates = {}
            for _, zoneName in ipairs(selectedZoneNames) do
                local zone = ZoneBuilds:FindFirstChild(zoneName)
                local eggsFolder = zone and zone:FindFirstChild("Eggs")
                if eggsFolder then
                    for _, egg in ipairs(eggsFolder:GetChildren()) do
                        if (egg:IsA("Model") or egg:IsA("BasePart"))
                            and egg.Name:lower():find("egg", 1, true)
                            and IsEggAvailable(egg) then
                            local eggName = GetEggTypeName(egg.Name)
                            if SelectedEggs[eggName] ~= false then
                                local category = GetEggCategory(egg)
                                local isTitanic = category ~= nil
                                    and category:lower() == "titanic"
                                table.insert(priorityCandidates, {
                                    egg = egg,
                                    luck = GetEggLuck(egg),
                                    kg = GetEggWeightKg(egg) or 0,
                                    isTitanic = isTitanic
                                })
                            end
                        end
                    end
                end
            end
            table.sort(priorityCandidates, function(a, b)
                if TitanicPriorityEnabled and a.isTitanic ~= b.isTitanic then
                    return a.isTitanic
                end
                if SortOrder == "Highest Kg" and a.kg ~= b.kg then
                    return a.kg > b.kg
                elseif SortOrder == "Highest Luck" and a.luck ~= b.luck then
                    return a.luck > b.luck
                end
                return a.egg.Name < b.egg.Name
            end)
            if #priorityCandidates > 0 then
                local best = priorityCandidates[1]
                target = best.egg
                SetTrackerStatus("AUTO BREAK PRIORITY: selected " .. target.Name
                    .. " | " .. tostring(SortOrder)
                    .. (TitanicPriorityEnabled and (best.isTitanic and " | Titanic priority matched" or " | No Titanic category match") or ""))
                AddDebugLog("[Auto Break] Selected " .. target.Name
                    .. " | priority=" .. tostring(SortOrder)
                    .. " | luck=" .. tostring(best.luck)
                    .. " | kg=" .. tostring(best.kg)
                    .. " | categoryTitanic=" .. tostring(best.isTitanic)
                    .. " | candidates=" .. tostring(#priorityCandidates))
            end
        end
        if not target then
            local normalZoneNames = {}
            local preferredIsSelected = false
            if PreferredZoneName then
                for _, zoneName in ipairs(selectedZoneNames) do
                    if zoneName == PreferredZoneName then
                        preferredIsSelected = true
                        break
                    end
                end
            end
            if preferredIsSelected then
                table.insert(normalZoneNames, PreferredZoneName)
            end
            for _, zoneName in ipairs(selectedZoneNames) do
                if zoneName ~= PreferredZoneName then
                    table.insert(normalZoneNames, zoneName)
                end
            end
            for _, zoneName in ipairs(normalZoneNames) do
                if target then break end
                local zone = ZoneBuilds:FindFirstChild(zoneName)
                local eggsFolder = zone and zone:FindFirstChild("Eggs")
                if eggsFolder then
                    for _, egg in ipairs(eggsFolder:GetChildren()) do
                        if (egg:IsA("Model") or egg:IsA("BasePart"))
                        and egg.Name:lower():find("egg", 1, true) then
                            local eggName = GetEggTypeName(egg.Name)
                            if SelectedEggs[eggName] ~= false and IsEggAvailable(egg) then
                                target = egg
                                break
                            end
                        end
                    end
                    if target then break end
                end
            end
        end
        if not target then
            local zone13Selected = false
            for _, zoneName in ipairs(selectedZoneNames) do
                if zoneName == "Zone13" then
                    zone13Selected = true
                    break
                end
            end
            local gatePosition = zone13Selected and GetZone13GatePosition() or nil
            if gatePosition then
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
                    SetTrackerStatus("Gate fallback cancelled: character parts were unavailable or Auto Break was disabled.")
                    TouchAutomationProgress("IDLE")
                    return
                end

                SetTrackerStatus("No eligible egg found in selected zones; moving to the Zone13 gate to trigger spawning.")
                AddDebugLog("[Auto Break] No eligible egg found; approaching Zone13 CastleGATE.")
                local lastEggScan = 0
                local lastProgressUpdate = 0
                local gateRescanQueued = false
                MovementConnection = RunService.RenderStepped:Connect(function()
                    if not AutoBreakEnabled or startGeneration ~= AutoBreakGeneration
                        or Runtime.Stopped or ScriptShuttingDown
                        or PickupRequested or ReturningAfterPickup
                        or not character.Parent or humanoid.Health <= 0 then
                        if MovementConnection then
                            MovementConnection:Disconnect()
                            MovementConnection = nil
                        end
                        humanoid:Move(Vector3.zero, false)
                        return
                    end

                    if os.clock() - lastEggScan >= 0.35 then
                        lastEggScan = os.clock()
                        local spawnedEggFound = false
                        for _, zoneName in ipairs(selectedZoneNames) do
                            local zone = ZoneBuilds:FindFirstChild(zoneName)
                            local eggsFolder = zone and zone:FindFirstChild("Eggs")
                            if eggsFolder then
                                for _, egg in ipairs(eggsFolder:GetChildren()) do
                                    if (egg:IsA("Model") or egg:IsA("BasePart"))
                                        and egg.Name:lower():find("egg", 1, true)
                                        and IsEggAvailable(egg) then
                                        local eggName = GetEggTypeName(egg.Name)
                                        if SelectedEggs[eggName] ~= false then
                                            spawnedEggFound = true
                                            break
                                        end
                                    end
                                end
                            end
                            if spawnedEggFound then break end
                        end
                        if spawnedEggFound then
                            if MovementConnection then
                                MovementConnection:Disconnect()
                                MovementConnection = nil
                            end
                            humanoid:Move(Vector3.zero, false)
                            SetTrackerStatus("Egg detected while approaching the Zone13 gate; refreshing target selection.")
                            task.defer(function()
                                if AutoBreakEnabled and startGeneration == AutoBreakGeneration
                                    and not PickupRequested and not ReturningAfterPickup then
                                    StartAutoBreak(true)
                                end
                            end)
                            return
                        end
                    end

                    local gateOffset = Vector3.new(
                        gatePosition.X - root.Position.X,
                        0,
                        gatePosition.Z - root.Position.Z
                    )
                    if gateOffset.Magnitude <= 4 then
                        if MovementConnection then
                            MovementConnection:Disconnect()
                            MovementConnection = nil
                        end
                        humanoid:Move(Vector3.zero, false)
                        if not gateRescanQueued then
                            gateRescanQueued = true
                            SetTrackerStatus("Reached Zone13 gate; rescanning selected zones for newly spawned eggs.")
                            TouchAutomationProgress("AUTO_BREAK:GATE_RESCAN")
                            task.defer(function()
                                task.wait(1)
                                if AutoBreakEnabled and startGeneration == AutoBreakGeneration
                                    and not PickupRequested and not ReturningAfterPickup then
                                    StartAutoBreak(true)
                                end
                            end)
                        end
                        return
                    end

                    humanoid:Move(gateOffset.Unit, false)
                    if os.clock() - lastProgressUpdate >= 1 then
                        lastProgressUpdate = os.clock()
                        TouchAutomationProgress("AUTO_BREAK:MOVING_TO_ZONE13_GATE")
                    end
                end)
                return
            end
            SetTrackerStatus("No target found. Select a zone and keep at least one egg type enabled.")
            TouchAutomationProgress("IDLE")
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
        -- Enter Zone 13 through its live gate only when approaching from outside.
        local movementWaypoints = {}
        if targetZone and targetZone.Name == "Zone13" and not IsInsideZone13(root.Position) then
            local gatePosition = GetZone13GatePosition()
            if gatePosition then table.insert(movementWaypoints, gatePosition) end
        end
        table.insert(movementWaypoints, target:GetPivot().Position)
        local movementWaypointIndex = 1
        SetTrackerStatus("Moving to egg: " .. target:GetFullName())
    
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
    
            local waypoint = movementWaypoints[movementWaypointIndex]
            if not waypoint then
                humanoid:Move(targetOffset.Unit, false)
                return
            end
            local waypointOffset = Vector3.new(
                waypoint.X - root.Position.X,
                0,
                waypoint.Z - root.Position.Z
            )
            if waypointOffset.Magnitude <= 4 then
                movementWaypointIndex += 1
                if movementWaypointIndex > #movementWaypoints then
                    humanoid:Move(Vector3.zero, false)
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
    GetFarmConfigSnapshot = function()
        local pickupZones, zones, disabledEggs = {}, {}, {}
        for zoneName, enabled in pairs(SelectedPickupZones) do
            if enabled then table.insert(pickupZones, zoneName) end
        end
        for zoneName, enabled in pairs(SelectedZones) do
            if enabled then table.insert(zones, zoneName) end
        end
        for eggName, enabled in pairs(SelectedEggs) do
            if enabled == false then table.insert(disabledEggs, eggName) end
        end
        table.sort(pickupZones)
        table.sort(zones)
        table.sort(disabledEggs)
        local rarities = {}
        for rarityName, enabled in pairs(SelectedRarities) do
            if enabled == true then rarities[rarityName] = true end
        end
        return {
            Rarities = rarities,
            PickupZones = pickupZones,
            Zones = zones,
            DisabledEggs = disabledEggs,
            SortOrder = SortOrder,
            TitanicPriority = TitanicPriorityEnabled,
            HighestCash = HighestCashEnabled,
            UnindexedOnly = UnindexedOnlyEnabled,
            DropInZone1 = DropInZone1Enabled,
            PickUpWithMutation = PickUpWithMutationEnabled,
            MutationRarities = (function()
                local selected = {}
                for rarityName, enabled in pairs(SelectedMutationRarities) do
                    if enabled == true then selected[rarityName] = true end
                end
                return selected
            end)(),
            KGThresholdAmount = KGThresholdAmount,
            KGThresholdUnit = KGThresholdUnit,
            CPSAmount = CPSFilter.amount,
            CPSUnit = CPSFilter.unit
        }
    end
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
end
