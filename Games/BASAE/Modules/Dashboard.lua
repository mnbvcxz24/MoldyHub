-- ORIGINAL BASAE DASHBOARD PAGE
return function(Context)
    local index = 1
    local name = "Main"
    local Page = CreatePage(index, name)
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
end
