-- CREATE ALL PAGES
for index, name in ipairs(UIConfig.SidebarNames) do
    local Page = CreatePage(index, name)
    if index == 1 then
        -- MAIN PAGE DASHBOARD
        -- Use the same padded two-column card layout as every other page.
        -- The page itself supplies the 12px outer margin; the column layout
        -- supplies the shared 8px inter-card gap.
        local MainPageColumns = PageColumnMap[Page]
        local StatsCard = CreateCard(Page, "Stats", "")
        StatsCard.Parent = MainPageColumns.Left
        StatsCard.Position = UDim2.new(0, 0, 0, 0)
        StatsCard.Size = UDim2.new(1, 0, 0, 190)
        StatsCard.LayoutOrder = 1

        local MasteryCard = CreateCard(Page, "Mastery", "")
        MasteryCard.Parent = MainPageColumns.Right
        MasteryCard.Position = UDim2.new(0, 0, 0, 0)
        MasteryCard.Size = UDim2.new(1, 0, 0, 190)
        MasteryCard.LayoutOrder = 1

        -- Keep all stat tiles inside a content area inset evenly from the card edges.
        local StatsContent = Create("Frame", {
            Name = "StatsContent",
            Parent = StatsCard,
            Position = UDim2.fromOffset(9, 36),
            Size = UDim2.new(1, -18, 1, -44),
            BackgroundTransparency = 1,
            BorderSizePixel = 0
        })
        Create("UIGridLayout", {
            Parent = StatsContent,
            CellSize = UDim2.new(0.5, -4, 0, 42),
            CellPadding = UDim2.fromOffset(8, 6),
            FillDirection = Enum.FillDirection.Horizontal,
            FillDirectionMaxCells = 2,
            SortOrder = Enum.SortOrder.LayoutOrder
        })

        local function CreateStatTile(name, caption, layoutOrder)
            local tile = Create("Frame", {
                Name = name:gsub("[^%w]", "") .. "Tile",
                Parent = StatsContent,
                Size = UDim2.new(0.5, -4, 0, 42),
                BackgroundColor3 = Theme.SurfaceInput,
                BorderSizePixel = 0,
                LayoutOrder = layoutOrder
            })
            AddCorner(tile, 6)
            AddStroke(tile, Theme.Border, 1)

            do
                local accent = Create("Frame", {
                    Name = "Accent",
                    Parent = tile,
                    Position = UDim2.fromOffset(0, 8),
                    Size = UDim2.new(0, 2, 1, -16),
                    BackgroundColor3 = Theme.Accent,
                    BorderSizePixel = 0
                })
                AddCorner(accent, 2)
            end

            Create("TextLabel", {
                Name = "Caption",
                Parent = tile,
                Position = UDim2.fromOffset(10, 5),
                Size = UDim2.new(1, -18, 0, 11),
                BackgroundTransparency = 1,
                Text = caption,
                TextColor3 = Theme.Gray,
                Font = Enum.Font.GothamMedium,
                TextSize = 7,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd
            })
            local value = Create("TextLabel", {
                Name = "Value",
                Parent = tile,
                Position = UDim2.fromOffset(10, 18),
                Size = UDim2.new(1, -18, 0, 18),
                BackgroundTransparency = 1,
                Text = "—",
                TextColor3 = Theme.Text,
                Font = Enum.Font.GothamSemibold,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd
            })
            return value
        end

        local CashPerSecondValue = CreateStatTile("CashPerSecond", "CASH / S", 1)
        local HighestCashAnimalValue = CreateStatTile("HighestCashAnimal", "TOP CASH / S ANIMAL", 2)
        local PickaxeDamageValue = CreateStatTile("PickaxeDamage", "PICKAXE DAMAGE", 3)
        local CashValue = CreateStatTile("Cash", "CASH", 4)
        local SpeedValue = CreateStatTile("Speed", "SPEED", 5)
        local DiamondsValue = CreateStatTile("Diamonds", "DIAMONDS", 6)

        -- Fixed mastery grid: three compact columns, matching the Stats tile sizing.
        local MasteryContent = Create("Frame", {
            Name = "MasteryContent",
            Parent = MasteryCard,
            Position = UDim2.fromOffset(9, 36),
            Size = UDim2.new(1, -18, 1, -44),
            BackgroundTransparency = 1,
            BorderSizePixel = 0
        })
        local MasteryListLayout = Create("UIGridLayout", {
            Parent = MasteryContent,
            CellSize = UDim2.new(1 / 3, -4, 0, 42),
            CellPadding = UDim2.fromOffset(6, 6),
            FillDirection = Enum.FillDirection.Horizontal,
            FillDirectionMaxCells = 3,
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        local MasteryRows = {}

        local function RefreshMasteryRows()
            local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            local mainGui = playerGui and playerGui:FindFirstChild("MainGUI")
            local frames = mainGui and mainGui:FindFirstChild("Frames")
            local mastery = frames and frames:FindFirstChild("Mastery")
            local masteryList = mastery and mastery:FindFirstChild("MasteryList")
            if not masteryList then return end

            local found = {}
            for _, masteryFrame in ipairs(masteryList:GetChildren()) do
                if masteryFrame:IsA("Frame") and masteryFrame.Name:sub(1, 8) == "Mastery_" then
                    local container = masteryFrame:FindFirstChild("Container")
                    local nameLabel = container and container:FindFirstChild("Title")
                    local levelLabel = container and container:FindFirstChild("LevelNumber")
                    if nameLabel and levelLabel and nameLabel:IsA("TextLabel") and levelLabel:IsA("TextLabel") then
                        table.insert(found, {
                            Key = masteryFrame.Name,
                            Name = nameLabel.Text,
                            Level = levelLabel.Text
                        })
                    end
                end
            end
            table.sort(found, function(a, b) return a.Name < b.Name end)

            local activeKeys = {}
            for index, item in ipairs(found) do
                activeKeys[item.Key] = true
                local row = MasteryRows[item.Key]
                if not row then
                    row = Create("Frame", {
                        Name = "MasteryRow_" .. tostring(index),
                        Parent = MasteryContent,
                        Size = UDim2.new(1 / 3, -4, 0, 42),
                        BackgroundColor3 = Theme.SurfaceInput,
                        BorderSizePixel = 0,
                        LayoutOrder = index
                    })
                    AddCorner(row, 5)
                    AddStroke(row, Theme.Border, 1)
                    local accent = Create("Frame", {
                        Name = "Accent",
                        Parent = row,
                        Position = UDim2.fromOffset(0, 8),
                        Size = UDim2.new(0, 2, 1, -16),
                        BackgroundColor3 = Theme.Accent,
                        BorderSizePixel = 0
                    })
                    AddCorner(accent, 2)
                    local title = Create("TextLabel", {
                        Name = "MasteryName",
                        Parent = row,
                        Position = UDim2.fromOffset(6, 21),
                        Size = UDim2.new(1, -12, 0, 16),
                        BackgroundTransparency = 1,
                        TextColor3 = Theme.Text,
                        Font = Enum.Font.GothamMedium,
                        TextSize = 8,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextTruncate = Enum.TextTruncate.AtEnd
                    })
                    local level = Create("TextLabel", {
                        Name = "MasteryLevel",
                        Parent = row,
                        Position = UDim2.fromOffset(6, 3),
                        Size = UDim2.new(1, -12, 0, 16),
                        BackgroundTransparency = 1,
                        TextColor3 = Theme.Accent,
                        Font = Enum.Font.GothamSemibold,
                        TextSize = 9,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextTruncate = Enum.TextTruncate.AtEnd
                    })
                    row:SetAttribute("MasteryKey", item.Key)
                    MasteryRows[item.Key] = row
                end
                row.LayoutOrder = index
                local title = row:FindFirstChild("MasteryName")
                local level = row:FindFirstChild("MasteryLevel")
                if title then title.Text = item.Name end
                if level then level.Text = "LEVEL " .. item.Level end
            end

            for key, row in pairs(MasteryRows) do
                if not activeKeys[key] then
                    row:Destroy()
                    MasteryRows[key] = nil
                end
            end
        end

        local function FormatCompactStat(value)
            if value == nil then return "—" end

            local raw = tostring(value)
            local cleaned = raw:gsub(",", ""):gsub("%s+", "")
            local numberText, suffix = cleaned:match("^([%d%.]+)([%a]*)$")
            local number = tonumber(numberText)
            if not number then return raw end

            local scales = {
                k = 1e3,
                m = 1e6,
                b = 1e9,
                t = 1e12,
                qa = 1e15,
                q = 1e15,
                qi = 1e18
            }
            local existingScale = scales[(suffix or ""):lower()]
            if suffix and suffix ~= "" then
                if not existingScale then return raw end
                number *= existingScale
            end

            local divisor, compactSuffix
            if number >= 1e18 then
                divisor, compactSuffix = 1e18, "Qi"
            elseif number >= 1e15 then
                divisor, compactSuffix = 1e15, "Qa"
            elseif number >= 1e12 then
                divisor, compactSuffix = 1e12, "T"
            elseif number >= 1e9 then
                divisor, compactSuffix = 1e9, "B"
            else
                return raw
            end

            local compact = string.format("%.2f", number / divisor)
                :gsub("0+$", "")
                :gsub("%.$", "")
            return compact .. compactSuffix
        end

        local function ReadPlayerStatAttribute(attributeName)
            local value = LocalPlayer:GetAttribute(attributeName)
            if value == nil then return "—" end
            return tostring(value)
        end

        local function FindOwnedPlot()
            local plots = workspace:FindFirstChild("Plots")
            if not plots then return nil end

            -- Prefer the owner attribute, but also support the game's visible
            -- "Your Base" marker in case userID is missing or stored differently.
            for baseIndex = 1, 7 do
                local base = plots:FindFirstChild("Base_" .. tostring(baseIndex))
                if base then
                    local ownerUserId = base:GetAttribute("userID")
                    if tonumber(ownerUserId) == LocalPlayer.UserId then
                        return base
                    end
                    local hitbox = base:FindFirstChild("Hitbox")
                    local playerInfo = hitbox and hitbox:FindFirstChild("PlayerInfoUi")
                    local nameLabel = playerInfo and playerInfo:FindFirstChild("Name")
                    if nameLabel and nameLabel:IsA("TextLabel") and nameLabel.Text == "Your Base" then
                        return base
                    end
                end
            end
            return nil
        end

        local function ReadPlacedAnimalCPS(animal)
            -- Exact placed-animal hierarchy:
            -- RootPart.AnimalOverheadAttachment.AnimalOverhead.CashPerSecond.CashPerSecond
            local rootPart = animal and animal:FindFirstChild("RootPart")
            local attachment = rootPart and rootPart:FindFirstChild("AnimalOverheadAttachment")
            local overhead = attachment and attachment:FindFirstChild("AnimalOverhead")
            local cpsContainer = overhead and overhead:FindFirstChild("CashPerSecond")
            local cpsLabel = cpsContainer and cpsContainer:FindFirstChild("CashPerSecond")

            if cpsLabel and (cpsLabel:IsA("TextLabel") or cpsLabel:IsA("TextButton") or cpsLabel:IsA("TextBox")) then
                local display = cpsLabel.Text
                local numericValue = ParseCPS(display)
                if numericValue >= 0 then
                    return numericValue, display
                end
            end

            -- Keep the general reader as a fallback for alternate animal layouts.
            if type(GetPetCPS) == "function" then
                return GetPetCPS(animal)
            end
            return -1, nil
        end

        local function ReadHighestPlacedAnimal()
            local ownedBase = FindOwnedPlot()
            local placedAnimals = ownedBase and ownedBase:FindFirstChild("PlacedAnimals")
            if not placedAnimals then return "—" end

            local highestValue = -1
            local highestDisplay = nil

            for _, animal in ipairs(placedAnimals:GetChildren()) do
                local cashPerSecond, display = ReadPlacedAnimalCPS(animal)
                if type(cashPerSecond) == "number" and cashPerSecond > highestValue then
                    highestValue = cashPerSecond
                    highestDisplay = display
                end
            end

            if highestValue < 0 then return "—" end
            return highestDisplay and tostring(highestDisplay) or tostring(highestValue)
        end

        task.spawn(function()
            while not Runtime.Stopped and ScreenGui.Parent and StatsCard.Parent do
                CashValue.Text = FormatCompactStat(LocalPlayer:GetAttribute("Cash"))
                CashPerSecondValue.Text = FormatCompactStat(LocalPlayer:GetAttribute("CashPerSecond"))
                DiamondsValue.Text = ReadPlayerStatAttribute("Diamonds")
                SpeedValue.Text = FormatCompactStat(LocalPlayer:GetAttribute("SpeedPower"))

                -- Refresh Mastery independently so a Stats reader error cannot stop it.
                pcall(RefreshMasteryRows)

                -- Top Cash Animal is isolated from the rest of the dashboard update loop.
                local success, highestAnimal = pcall(ReadHighestPlacedAnimal)
                HighestCashAnimalValue.Text = success and tostring(highestAnimal) or "—"

                -- Pickaxe damage is intentionally left as "—" until its value is provided.
                task.wait(0.5)
            end
        end)
    elseif index == 2 then
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
        AutoPickupCard.Size = UDim2.new(0.5, -5, 0, 316)
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
        local RarityOptions = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Cosmic", "Secret", "Eternal", "Divine", "Celestial", "Inferno", "Void", "Omega", "Spectral", "Ethereal"}
        local SelectedRarities = {}
        local SelectedPickupZones = {}
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
        local KGThresholdAmount = 0
        local KGThresholdUnit = "K"
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
            Text = "",
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
        KGUnitButton = CreateButton(AutoPickupCard, "K ▼", function()
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
        local CPSFilter = {amount = 0, unit = "K", options = {"K", "M", "B", "T", "Qa"}, open = false}
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
            Text = "",
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
        CPSFilter.button = CreateButton(AutoPickupCard, "K ▼", function()
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
        local function CreatePickupCheckbox(parent, labelText, yPosition, callback)
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
            return Checkbox
        end
        local HighestCashEnabled = false
        local HighestCashToggle = CreatePickupCheckbox(AutoPickupCard, "Steal above your lowest $/s", 205, function(enabled)
            HighestCashEnabled = enabled
            AddDebugLog("[Auto Pickup] " .. (enabled and "Lowest placed CPS filter ON." or "Lowest placed CPS filter OFF."))
        end)
        local UnindexedOnlyEnabled = false
        local UnindexedOnlyToggle = CreatePickupCheckbox(AutoPickupCard, "Steal not Index Animals", 231, function(enabled)
            UnindexedOnlyEnabled = enabled
            AddDebugLog("[Auto Pickup] " .. (enabled and "Unindexed-only verification ON." or "Unindexed-only verification OFF."))
        end)
        local DropInZone1Enabled = false
        local DropInZone1Toggle = CreatePickupCheckbox(AutoPickupCard, "Drop the animal in Zone 1", 257, function(enabled)
            DropInZone1Enabled = enabled
            AddDebugLog("[Auto Pickup] Drop in Zone 1 " .. (enabled and "ON." or "OFF."))
        end)
        local PickUpWithMutationEnabled = false
        local PickUpWithMutationToggle = CreatePickupCheckbox(AutoPickupCard, "Steal animal with mutation", 283, function(enabled)
            PickUpWithMutationEnabled = enabled
            AddDebugLog("[Auto Pickup] With Mutation " .. (enabled and "ON." or "OFF."))
        end)
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
        local SelectedZones = {}
        local SelectedEggs = {}
        local PreferredZoneName = nil
        local SortOrder = "Highest Luck"
        local SortFrame
        local ZoneFilterButton
        local EggFilterButton
        local SortLargestButton
        local SortSmallestButton
        local ZoneBuilds = workspace:WaitForChild("Build"):WaitForChild("ZoneBuilds")
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
        local PriorityFilterButton = CreateButton(SortFrame, "Highest Luck ▼", function()
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
