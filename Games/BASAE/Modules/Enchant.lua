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
    Create("UIGridLayout", {
        Parent = List,
        SortOrder = Enum.SortOrder.LayoutOrder,
        FillDirection = Enum.FillDirection.Vertical,
        FillDirectionMaxCells = 9,
        CellSize = UDim2.new(0.5, -4, 0, 28),
        CellPadding = UDim2.fromOffset(8, 4)
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

        local function CreateRow(animalName, enchantValue, order, isHeader)
            local row = Create("Frame", {
                Name = isHeader and "EnchantHeader" or "AnimalEnchantRow",
                Parent = List,
                Size = UDim2.new(1, 0, 0, isHeader and 22 or 28),
                BackgroundColor3 = isHeader and Theme.LightGray or Theme.SurfaceInput,
                BorderSizePixel = 0,
                LayoutOrder = order
            })
            AddCorner(row, 5)
            if not isHeader then AddStroke(row, Theme.Border, 1) end

            Create("TextLabel", {
                Parent = row,
                Position = UDim2.fromOffset(8, 0),
                Size = UDim2.new(0.58, -8, 1, 0),
                BackgroundTransparency = 1,
                Text = animalName,
                TextColor3 = isHeader and Theme.Gray or Theme.Text,
                Font = isHeader and Enum.Font.GothamSemibold or Enum.Font.Gotham,
                TextSize = 8,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd
            })
            Create("TextLabel", {
                Parent = row,
                Position = UDim2.new(0.58, 0, 0, 0),
                Size = UDim2.new(0.42, -8, 1, 0),
                BackgroundTransparency = 1,
                Text = enchantValue,
                TextColor3 = isHeader and Theme.Gray or Theme.Accent,
                Font = Enum.Font.GothamSemibold,
                TextSize = 8,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextTruncate = Enum.TextTruncate.AtEnd
            })
        end

        CreateRow("ANIMAL", "ENCHANT", 1, true)
        if #animals == 0 then
            CreateRow(hasPlacedFolder and "No placed animals found" or "Your plot was not found", "—", 2, false)
        else
            for index, animal in ipairs(animals) do
                CreateRow(animal.Name, animal.Enchant == nil and "None" or tostring(animal.Enchant), index + 1, false)
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
