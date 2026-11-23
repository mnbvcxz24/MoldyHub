-- BASAE ENCHANT PAGE
-- Read-only list of each placed animal and its Enchant attribute.
return function(Context)
    local index = 4
    local name = "Enchant"
    local Page = CreatePage(index, name)
    local EnchantCard = CreateCard(Page, "Placed Animal Enchants", "Shows the Enchant attribute for every animal placed on your plot.")

    local Status = Create("TextLabel", {
        Name = "EnchantStatus",
        Parent = EnchantCard,
        Position = UDim2.fromOffset(11, 59),
        Size = UDim2.new(1, -22, 0, 16),
        BackgroundTransparency = 1,
        Text = "Scanning placed animals...",
        TextColor3 = Theme.Gray,
        Font = Enum.Font.Gotham,
        TextSize = 8,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local List = Create("Frame", {
        Name = "EnchantAnimalList",
        Parent = EnchantCard,
        Position = UDim2.fromOffset(11, 80),
        Size = UDim2.new(1, -22, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    })
    Create("UIListLayout", {
        Parent = List,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4)
    })

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

    local function ReadPlacedAnimals()
        local plot = FindOwnedPlot()
        local placedAnimals = plot and plot:FindFirstChild("PlacedAnimals")
        local animals = {}

        if placedAnimals then
            for _, animal in ipairs(placedAnimals:GetChildren()) do
                table.insert(animals, {
                    Name = animal.Name,
                    Enchant = animal:GetAttribute("Enchant")
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
            table.insert(signatureParts, animal.Name .. "\31" .. tostring(animal.Enchant))
        end
        local signature = table.concat(signatureParts, "\30")
        if signature == List:GetAttribute("DataSignature") then return end
        List:SetAttribute("DataSignature", signature)

        for _, child in ipairs(List:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
        end

        Status.Text = tostring(#animals) .. " placed animal" .. (#animals == 1 and "" or "s")

        local function CreateEntry(parent, animalName, enchantValue, order)
            local entry = Create("Frame", {
                Name = "AnimalEnchantEntry",
                Parent = parent,
                Size = UDim2.new(0.5, -3, 0, 28),
                BackgroundColor3 = Theme.SurfaceInput,
                BorderSizePixel = 0,
                LayoutOrder = order
            })
            AddCorner(entry, 5)
            AddStroke(entry, Theme.Border, 1)

            Create("TextLabel", {
                Parent = entry,
                Position = UDim2.fromOffset(7, 0),
                Size = UDim2.new(1, -14, 1, 0),
                BackgroundTransparency = 1,
                Text = animalName .. " - " .. enchantValue,
                TextColor3 = Theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 8,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd
            })
        end

        local function CreateEntryRow(order)
            local row = Create("Frame", {
                Name = "EnchantEntryRow",
                Parent = List,
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                LayoutOrder = order
            })
            local layout = Create("UIListLayout", {
                Parent = row,
                FillDirection = Enum.FillDirection.Horizontal,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6)
            })
            layout.VerticalAlignment = Enum.VerticalAlignment.Center
            return row
        end

        if #animals == 0 then
            local row = CreateEntryRow(1)
            local empty = Create("TextLabel", {
                Name = "EnchantEmptyState",
                Parent = row,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Theme.SurfaceInput,
                Text = hasPlacedFolder and "No placed animals found" or "Your plot was not found",
                TextColor3 = Theme.Gray,
                Font = Enum.Font.Gotham,
                TextSize = 8,
                TextXAlignment = Enum.TextXAlignment.Center,
                BorderSizePixel = 0
            })
            AddCorner(empty, 5)
            return
        end

        for index = 1, #animals, 2 do
            local row = CreateEntryRow(math.ceil(index / 2))
            local first = animals[index]
            CreateEntry(row, first.Name, first.Enchant == nil and "None" or tostring(first.Enchant), 1)

            local second = animals[index + 1]
            if second then
                CreateEntry(row, second.Name, second.Enchant == nil and "None" or tostring(second.Enchant), 2)
            end
        end
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
