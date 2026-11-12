-- ORIGINAL BASAE MISC PAGE
return function(Context)
    local index = 4
    local name = "Misc. feature"
    local Page = CreatePage(index, name)
    local ESPCardsRow = Create("Frame", {
        Name = "ESPFeatureCardsRow",
        Parent = Page,
        Position = UDim2.fromOffset(10, 10),
        Size = UDim2.new(1, -20, 0, 76),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = 0
    })
    local ESPCard = CreateCard(ESPCardsRow, "Egg ESP", "Displays egg stats.")
    ESPCard.Position = UDim2.new(0, 0, 0, 0)
    ESPCard.Size = UDim2.fromOffset(180, 76)
    ESPCard.LayoutOrder = 1
    local ESPStatus = Create("TextLabel", {
        Parent = ESPCard,
        Position = UDim2.fromOffset(11, 49),
        Size = UDim2.new(1, -22, 0, 18),
        BackgroundTransparency = 1,
        Text = "ESP is off",
        TextColor3 = Theme.Gray,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top
    })
    local ESPEnabled = false
    local ESPObjects = {}
    local ESPFolder = Create("Folder", {Name = "MoldyHub_BASAE_EggESP", Parent = LocalPlayer:WaitForChild("PlayerGui")})
    local function ClearEggESP(egg)
        local gui = ESPObjects[egg]
        if gui then
            gui:Destroy()
            ESPObjects[egg] = nil
        end
    end
    local function GetESPValue(object, names)
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
    local function GetEggESPInfo(egg)
        local eggModel = egg:FindFirstChild("Egg") or egg
        local info = eggModel:FindFirstChild("EggInfoUi", true)
        local luck = GetESPValue(eggModel, {"LuckMulti", "Luck", "LuckMultiplier"})
            or GetESPValue(info, {"LuckMulti", "Luck", "LuckMultiplier"})
        if not luck and info then
            local luckList = info:FindFirstChild("LuckMultiList", true)
            local luckLabel = luckList and luckList:FindFirstChild("LuckMulti", true)
            if luckLabel and (luckLabel:IsA("TextLabel") or luckLabel:IsA("TextButton")) then
                luck = luckLabel.Text
            end
        end
        local weightKG = GetESPValue(eggModel, {"WeightKg"})
            or GetESPValue(info, {"WeightKg"})
        local category = GetESPValue(eggModel, {"WeightBracket"})
            or GetESPValue(info, {"WeightBracket"})
        return luck or "?", weightKG or "?", category or "?"
    end
    local function UpdateEggESP()
        local build = workspace:FindFirstChild("Build")
        local zones = build and build:FindFirstChild("ZoneBuilds")
        if not zones then
            ESPStatus.Text = "Waiting for egg zones..."
            return
        end
        local seen = {}
        local count = 0
        for _, zone in ipairs(zones:GetChildren()) do
            local eggsFolder = zone:FindFirstChild("Eggs")
            if eggsFolder then
                for _, egg in ipairs(eggsFolder:GetChildren()) do
                    if (egg:IsA("Model") or egg:IsA("BasePart")) and egg.Name:lower():find("egg", 1, true) then
                        local adornee = egg:IsA("BasePart") and egg or egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart", true)
                        if adornee then
                            seen[egg] = true
                            count += 1
                            local gui = ESPObjects[egg]
                            if not gui or not gui.Parent then
                                gui = Instance.new("BillboardGui")
                                gui.Name = "EggESP"
                                gui.Adornee = adornee
                                gui.Size = UDim2.fromOffset(180, 44)
                                gui.StudsOffset = Vector3.new(0, 3, 0)
                                gui.AlwaysOnTop = true
                                gui.MaxDistance = 250
                                gui.Parent = ESPFolder
                                local label = Instance.new("TextLabel")
                                label.Name = "Info"
                                label.Size = UDim2.fromScale(1, 1)
                                label.BackgroundTransparency = 1
                                label.BackgroundTransparency = 1
                                label.BorderSizePixel = 0
                                label.TextColor3 = Color3.fromRGB(255, 255, 255)
                                label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                                label.TextStrokeTransparency = 0.25
                                label.Font = Enum.Font.GothamBold
                                label.TextSize = 11
                                label.TextWrapped = true
                                label.Parent = gui
                                ESPObjects[egg] = gui
                            end
                            gui.Adornee = adornee
                            local luck, weightKG, category = GetEggESPInfo(egg)
                            gui.Size = UDim2.fromOffset(205, 58)
                            gui.Info.Text = egg.Name .. "\nLuck: " .. luck .. " | KG: " .. weightKG .. "\nCategory: " .. category
                        end
                    end
                end
            end
        end
        for egg in pairs(ESPObjects) do
            if not seen[egg] or not egg.Parent then
                ClearEggESP(egg)
            end
        end
        ESPStatus.Text = "ESP " .. (ESPEnabled and "ON" or "OFF") .. " | Eggs: " .. count
    end
    CreateToggle(ESPCard, "", false, function(enabled)
        ESPEnabled = enabled
        if enabled then
            ESPStatus.Text = "Scanning eggs..."
            task.spawn(function()
                while not Runtime.Stopped and ESPEnabled and not ScriptShuttingDown do
                    UpdateEggESP()
                    task.wait(0.75)
                end
            end)
        else
            for egg in pairs(ESPObjects) do
                ClearEggESP(egg)
            end
            ESPStatus.Text = "ESP is off"
        end
    end)
    local ESPToggle = ESPCard:FindFirstChildWhichIsA("TextButton")
    if ESPToggle then
        ESPToggle.Position = UDim2.new(1, -61, 0, 5)
        ESPToggle.Size = UDim2.fromOffset(48, 24)
    end
    local ESPTitle = ESPCard:FindFirstChildWhichIsA("TextLabel")
    if ESPTitle then ESPTitle.Size = UDim2.new(1, -78, 0, 22) end
    ESPCard.Size = UDim2.fromOffset(180, 76)
    
    local BackpackESPCard = CreateCard(ESPCardsRow, "Backpack ESP", "Shows larger $/s and KG on inventory cards.")
    BackpackESPCard.Position = UDim2.new(1/3, 2.5, 0, 0)
    BackpackESPCard.Size = UDim2.fromOffset(180, 76)
    BackpackESPCard.LayoutOrder = 2
    local BackpackESPStatus = Create("TextLabel", {
        Parent = BackpackESPCard,
        Position = UDim2.fromOffset(11, 49),
        Size = UDim2.new(1, -22, 0, 18),
        BackgroundTransparency = 1,
        Text = "ESP is off",
        TextColor3 = Theme.Gray,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top
    })
    local BackpackESPEnabled = false
    local BackpackESPObjects = {}
    local BackpackESPConnections = {}
    local BackpackESPFolder = Create("Folder", {
        Name = "MoldyHub_BASAE_BackpackESP",
        Parent = LocalPlayer:WaitForChild("PlayerGui")
    })
    local BackpackESPRefs = {}
    local function ClearBackpackESP(card)
        local overlay = BackpackESPObjects[card]
        if overlay then
            overlay:Destroy()
            BackpackESPObjects[card] = nil
        end
        local overlayRef = BackpackESPRefs[card]
        if overlayRef then
            overlayRef:Destroy()
            BackpackESPRefs[card] = nil
        end
    end
    local function GetBackpackESPInfo(tool)
        local model = tool:FindFirstChild("AnimalModel")
        local root = model and model:FindFirstChild("RootPart")
        local attachment = root and root:FindFirstChild("AnimalOverheadAttachment")
        local overhead = attachment and attachment:FindFirstChild("AnimalOverhead")
        local cashFolder = overhead and overhead:FindFirstChild("CashPerSecond")
        local cashLabel = cashFolder and cashFolder:FindFirstChild("CashPerSecond")
        if not cashLabel then return "" end
        if cashLabel:IsA("TextLabel") or cashLabel:IsA("TextButton") or cashLabel:IsA("TextBox") then
            return cashLabel.Text
        elseif cashLabel:IsA("ValueBase") then
            return tostring(cashLabel.Value)
        end
        return ""
    end
    local function NormalizeAnimalName(value)
        value = tostring(value or ""):lower()
        value = value:gsub("%s*%b()%s*$", "")
        value = value:gsub("%s+", " ")
        return value:match("^%s*(.-)%s*$")
    end
    local function GetAnimalComparisonKey(value)
        return NormalizeAnimalName(value):gsub("[^%a%d]", "")
    end
    local function ParseAnimalWeight(value)
        if value == nil then return nil end
        local cleaned = tostring(value):gsub(",", "")
        cleaned = cleaned:gsub("%s*[Kk][Gg]%s*$", "")
        cleaned = cleaned:match("^%s*(.-)%s*$")
        return tonumber(cleaned)
    end
    local function NormalizeAnimalWeight(value)
        local weight = ParseAnimalWeight(value)
        if not weight then return nil end
        return math.floor(weight + 0.5)
    end
    local function AnimalWeightMatches(actualValue, displayedValue)
        local actualWeight = ParseAnimalWeight(actualValue)
        local displayedWeight = ParseAnimalWeight(displayedValue)
        if not actualWeight or not displayedWeight then return false end
    
        local lowerWeight = math.floor(actualWeight)
        local fraction = actualWeight - lowerWeight
        if math.abs(fraction - 0.5) < 0.000001 then
            return displayedWeight == lowerWeight or displayedWeight == lowerWeight + 1
        end
        return displayedWeight == math.floor(actualWeight + 0.5)
    end
    local function GetInventoryCardInfo(card)
        local container = card:FindFirstChild("Container")
        local infoList = container and container:FindFirstChild("InfoList")
        local nameLabel = infoList and infoList:FindFirstChild("Name")
        if not nameLabel or not (nameLabel:IsA("TextLabel") or nameLabel:IsA("TextButton") or nameLabel:IsA("TextBox")) then
            return nil
        end
        local text = tostring(nameLabel.Text or "")
        local animalName, weightText = text:match("^%s*(.-)%s*%(([%d,%.]+)%s*[Kk][Gg]%)%s*$")
        if not animalName or not weightText then return nil end
        local weight = ParseAnimalWeight(weightText)
        if not weight then return nil end
        animalName = NormalizeAnimalName(animalName)
        if animalName == "" then return nil end
        return animalName, weightText, container, weight
    end
    local function FindInventoryCards()
        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        local mobile = playerGui and playerGui:FindFirstChild("MobileScatchel")
        local hotbar = mobile and mobile:FindFirstChild("HotBarUi")
        local inventory = hotbar and hotbar:FindFirstChild("Inventory")
        local scrolling = inventory and inventory:FindFirstChild("ScrollingFrame")
        if not scrolling then return {} end
    
        local cards = {}
        for _, descendant in ipairs(scrolling:GetDescendants()) do
            if descendant:FindFirstChild("Container") then
                local container = descendant:FindFirstChild("Container")
                local infoList = container and container:FindFirstChild("InfoList")
                local nameLabel = infoList and infoList:FindFirstChild("Name")
                if nameLabel and (nameLabel:IsA("TextLabel") or nameLabel:IsA("TextButton") or nameLabel:IsA("TextBox")) then
                    table.insert(cards, descendant)
                end
            end
        end
        return cards
    end
    local function UpdateBackpackESP()
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if not backpack then
            BackpackESPStatus.Text = "Waiting for backpack..."
            return
        end
    
        local animals = {}
        local totalTools = 0
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local animalName = tool:GetAttribute("AnimalName")
                local weight = ParseAnimalWeight(tool:GetAttribute("WeightKg"))                if typeof(animalName) == "string" and animalName ~= "" and weight then
                    totalTools += 1
                    table.insert(animals, {
                        Tool = tool,
                        Key = GetAnimalComparisonKey(animalName),
                        Weight = weight,
                        CPS = GetBackpackESPInfo(tool),
                    })
                end
            end
        end
    
        local inventoryCards = FindInventoryCards()
        local parsedCards = 0
        local seen = {}
        local count = 0
        for _, card in ipairs(inventoryCards) do
            local animalName, weightText, container, cardWeight = GetInventoryCardInfo(card)
            if animalName and container then
                parsedCards += 1
                local cardKey = GetAnimalComparisonKey(animalName)
                local match
                for _, animal in ipairs(animals) do
                    if animal.Key == cardKey
                        and AnimalWeightMatches(animal.Weight, cardWeight) then
                        match = animal
                        break
                    end
                end
    
                if match then
                    seen[card] = true
                    count += 1
                    local overlay = BackpackESPObjects[card]
                    if not overlay or not overlay.Parent then
                        overlay = Instance.new("Frame")
                        overlay.Name = "MoldyHub_BASAE_InventoryStatsOverlay"
                        overlay.BackgroundTransparency = 1
                        overlay.BorderSizePixel = 0
                        overlay.AnchorPoint = Vector2.new(0, 1)
                        overlay.Position = UDim2.new(0, 0, 1, -4)
                        overlay.Size = UDim2.new(1, 0, 0, 22)
                        overlay.ZIndex = 20
                        overlay.Parent = container
                        local overlayRef = Instance.new("ObjectValue")
                        overlayRef.Name = "InventoryOverlay"
                        overlayRef.Value = overlay
                        overlayRef.Parent = BackpackESPFolder
                        BackpackESPRefs[card] = overlayRef
    
                        local cashText = Instance.new("TextLabel")
                        cashText.Name = "CashPerSecond"
                        cashText.BackgroundTransparency = 1
                        cashText.BorderSizePixel = 0
                        cashText.Position = UDim2.new(0, 1, 0, 0)
                        cashText.Size = UDim2.new(1, -2, 0, 12)
                        cashText.Font = Enum.Font.GothamBold
                        cashText.TextSize = 9
                        cashText.TextColor3 = Color3.fromRGB(99, 255, 145)
                        cashText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                        cashText.TextStrokeTransparency = 0.35
                        cashText.TextXAlignment = Enum.TextXAlignment.Center
                        cashText.TextTruncate = Enum.TextTruncate.AtEnd
                        cashText.ZIndex = 21
                        cashText.Parent = overlay
    
                        local weightLabel = Instance.new("TextLabel")
                        weightLabel.Name = "Weight"
                        weightLabel.BackgroundTransparency = 1
                        weightLabel.BorderSizePixel = 0
                        weightLabel.Position = UDim2.new(0, 1, 0, 11)
                        weightLabel.Size = UDim2.new(1, -2, 0, 10)
                        weightLabel.Font = Enum.Font.GothamBold
                        weightLabel.TextSize = 8
                        weightLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                        weightLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                        weightLabel.TextStrokeTransparency = 0.35
                        weightLabel.TextXAlignment = Enum.TextXAlignment.Center
                        weightLabel.TextTruncate = Enum.TextTruncate.AtEnd
                        weightLabel.ZIndex = 21
                        weightLabel.Parent = overlay
                        BackpackESPObjects[card] = overlay
                    end
    
                    overlay.CashPerSecond.Text = match.CPS ~= "" and tostring(match.CPS):gsub("[%$]", "") or "—"
                    overlay.Weight.Text = weightText:gsub(",", ""):gsub("%s*[Kk][Gg]%s*$", "") .. "kg"
                end
            end
        end
    
        for card in pairs(BackpackESPObjects) do
            if not seen[card] or not card.Parent then
                ClearBackpackESP(card)
            end
        end
        BackpackESPStatus.Text = "ESP " .. (BackpackESPEnabled and "ON" or "OFF") .. " | Matched: " .. count
    end
    CreateToggle(BackpackESPCard, "", false, function(enabled)
        BackpackESPEnabled = enabled
        if enabled then
            BackpackESPStatus.Text = "Matching inventory cards..."
            task.spawn(function()
                while not Runtime.Stopped and BackpackESPEnabled and not ScriptShuttingDown do
                    pcall(UpdateBackpackESP)
                    task.wait(0.75)
                end
            end)
        else
            for card in pairs(BackpackESPObjects) do
                ClearBackpackESP(card)
            end
            for card in pairs(BackpackESPRefs) do
                ClearBackpackESP(card)
            end
            BackpackESPStatus.Text = "ESP is off"
        end
    end)
    local BackpackESPToggle = BackpackESPCard:FindFirstChildWhichIsA("TextButton")
    if BackpackESPToggle then
        BackpackESPToggle.Position = UDim2.new(1, -61, 0, 5)
        BackpackESPToggle.Size = UDim2.fromOffset(48, 24)
    end
    local BackpackESPTitle = BackpackESPCard:FindFirstChildWhichIsA("TextLabel")
    if BackpackESPTitle then BackpackESPTitle.Size = UDim2.new(1, -78, 0, 22) end
    
    local AntiPaloCard = CreateCard(ESPCardsRow, "️  Anti Knockback", "Prevents knockback and fling.")
    AntiPaloCard.Position = UDim2.new(2/3, 5, 0, 0)
    AntiPaloCard.Size = UDim2.fromOffset(180, 76)
    AntiPaloCard.LayoutOrder = 1
    local AntiPaloBusy = false
    local AntiPaloStatus = Create("TextLabel", {
        Parent = AntiPaloCard,
        Position = UDim2.fromOffset(11, 49),
        Size = UDim2.new(1, -22, 0, 16),
        BackgroundTransparency = 1,
        Text = "Status: OFF",
        TextColor3 = Theme.Gray,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    local AntiPaloToggle
    AntiPaloToggle = CreateToggle(AntiPaloCard, "", false, function(enabled)
        if AntiPaloBusy then
            local controller = ToggleControllers[AntiPaloToggle]
            if controller then controller.SetEnabled(AntiPaloEnabled, false) end
            return
        end
        AntiPaloBusy = true
        AntiPaloEnabled = enabled
        AntiPaloStatus.Text = enabled and "Status: ON • Fling Release" or "Status: OFF"
        AntiPaloStatus.TextColor3 = enabled and Theme.Accent or Theme.Gray
        AddDebugLog("[Anti Knockback] Fling release " .. (enabled and "enabled" or "disabled") .. ".")
        task.delay(0.25, function()
            AntiPaloBusy = false
        end)
    end)
    AntiPaloToggle.Position = UDim2.new(1, -58, 0, 7)
    AntiPaloToggle.Size = UDim2.fromOffset(48, 24)
    
    local AnimalAutomationRow = Create("Frame", {
        Name = "AnimalAutomationCardsRow",
        Parent = Page,
        Position = UDim2.fromOffset(10, 94),
        Size = UDim2.new(1, -20, 0, 76),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = 2
    })

    local AuraCard = CreateCard(AnimalAutomationRow, "️  Auto Boink", "Boink any enemy nearby.")
    AuraCard.Position = UDim2.new(0, 0, 0, 0)
    AuraCard.Size = UDim2.fromOffset(180, 76)
    AuraCard.LayoutOrder = 2
    local AuraStatus = Create("TextLabel", {
        Parent = AuraCard,
        Position = UDim2.fromOffset(11, 49),
        Size = UDim2.new(1, -22, 0, 22),
        BackgroundTransparency = 1,
        Text = "Status: OFF",
        TextColor3 = Theme.Gray,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top
    })
    local AuraEnabled = false
    local AuraWasNearby = false
    local function GetNearbyPlayers()
        local nearby = {}
        local myCharacter = LocalPlayer.Character
        local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
        if not myRoot then
            return nearby, "Waiting for your character..."
        end
        for _, targetPlayer in ipairs(Players:GetPlayers()) do
            if targetPlayer ~= LocalPlayer then
                local character = workspace:FindFirstChild(targetPlayer.Name)
                local root = character and character:FindFirstChild("HumanoidRootPart")
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
                    local distance = (root.Position - myRoot.Position).Magnitude
                    if distance <= 20 then
                        table.insert(nearby, {Name = targetPlayer.Name, Distance = distance})
                    end
                end
            end
        end
        table.sort(nearby, function(a, b)
            return a.Distance < b.Distance
        end)
        if #nearby == 0 then
            return nearby, "No players within 20 studs"
        end
        local names = {}
        for i = 1, math.min(#nearby, 2) do
            table.insert(names, nearby[i].Name .. " (" .. string.format("%.1f", nearby[i].Distance) .. ")")
        end
        if #nearby > 2 then
            table.insert(names, "+" .. tostring(#nearby - 2) .. " more")
        end
        return nearby, "Nearby: " .. table.concat(names, ", ")
    end
    local function SelectAuraHotbarSlot(slot)
        local key = slot == 1 and Enum.KeyCode.One or slot == 2 and Enum.KeyCode.Two
        if not key then
            return false, "Unsupported hotbar slot: " .. tostring(slot)
        end
        local ok, err = pcall(function()
            local virtualInput = game:GetService("VirtualInputManager")
            virtualInput:SendKeyEvent(true, key, false, game)
            task.wait(0.05)
            virtualInput:SendKeyEvent(false, key, false, game)
        end)
        if not ok then
            return false, tostring(err)
        end
        return true
    end
    local function RunAuraNiBai(targetName)
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then
            AddDebugLog("[Auto Boink] Cannot boink: character or humanoid is unavailable.")
            return
        end
        local remote = game:GetService("ReplicatedStorage"):FindFirstChild("BatHitRequest", true)
        if not remote or not remote:IsA("RemoteEvent") then
            AddDebugLog("[Auto Boink] BatHitRequest RemoteEvent not found.")
            return
        end
        local selectedTwo, selectTwoError = SelectAuraHotbarSlot(2)
        if selectedTwo then
            AddDebugLog("[Auto Boink] Selected hotbar slot 2.")
            task.wait(0.15)
        else
            AddDebugLog("[Auto Boink] Could not select hotbar slot 2: " .. tostring(selectTwoError))
        end
        local fired, fireError = pcall(function()
            remote:FireServer(game:GetService("Players"):FindFirstChild(targetName))
        end)
        if fired then
            AddDebugLog("[Auto Boink] BatHitRequest:FireServer() called for " .. targetName .. ".")
        else
            AddDebugLog("[Auto Boink] BatHitRequest call failed: " .. tostring(fireError))
        end
        task.wait(0.15)
        if LocalPlayer.Character == character then
            local selectedOne, selectOneError = SelectAuraHotbarSlot(1)
            if selectedOne then
                AddDebugLog("[Auto Boink] Returned to hotbar slot 1.")
            else
                AddDebugLog("[Auto Boink] Could not return to hotbar slot 1: " .. tostring(selectOneError))
            end
        end
    end
    local AuraActionRunning = false
    local AuraPendingTarget = nil
    local function QueueAuraAction(targetName)
        if not targetName or not AuraEnabled or Runtime.Stopped then return end
        if AuraActionRunning then
            AuraPendingTarget = targetName
            return
        end
        AuraActionRunning = true
        task.spawn(function()
            local nextTarget = targetName
            while nextTarget and AuraEnabled and not Runtime.Stopped do
                local ok, err = xpcall(function()
                    RunAuraNiBai(nextTarget)
                end, debug.traceback)
                if not ok then
                    AddDebugLog("[Auto Boink] Action failed: " .. tostring(err):gsub("[%r\\n]+", " "):sub(1, 180))
                end
                nextTarget = AuraEnabled and AuraPendingTarget or nil
                AuraPendingTarget = nil
            end
            AuraActionRunning = false
            if AuraEnabled and AuraPendingTarget and not Runtime.Stopped then                local pending = AuraPendingTarget
                AuraPendingTarget = nil
                QueueAuraAction(pending)
            end
        end)
    end
    local AuraToggle = CreateToggle(AuraCard, "", false, function(enabled)
        AuraEnabled = enabled
        if not enabled then
            AuraWasNearby = false
            AuraPendingTarget = nil
            AuraStatus.Text = "Status: OFF"
            AuraStatus.TextColor3 = Theme.Gray
            AddDebugLog("[Auto Boink] Proximity tracking disabled.")
            return
        end
        AuraStatus.Text = "Tracking players within 20 studs..."
        AuraStatus.TextColor3 = Theme.Accent
        AddDebugLog("[Auto Boink] Proximity tracking enabled (20 studs).")
        task.spawn(function()
            while AuraEnabled and not Runtime.Stopped and ScreenGui.Parent do
                local nearby, nearbyText = GetNearbyPlayers()
                if #nearby > 0 then
                    AuraStatus.Text = nearbyText
                    AuraStatus.TextColor3 = Theme.Accent
                    if not AuraWasNearby then
                        AddDebugLog("[Auto Boink] Detected " .. nearby[1].Name .. " within 20 studs (" .. string.format("%.1f", nearby[1].Distance) .. " studs).")
                        QueueAuraAction(nearby[1].Name)
                    end
                    AuraWasNearby = true
                else
                    AuraWasNearby = false
                    AuraStatus.Text = nearbyText
                    AuraStatus.TextColor3 = Theme.Accent
                end
                task.wait(0.25)
            end
        end)
    end)
    AuraToggle.Position = UDim2.new(1, -58, 0, 7)
    AuraToggle.Size = UDim2.fromOffset(48, 24)

    local function CompactCardDescription(card)
        local titleFound = false
        for _, child in ipairs(card:GetChildren()) do
            if child:IsA("TextLabel") then
                if not titleFound then
                    titleFound = true
                elseif child.Position.Y.Offset == 29 then
                    child.Size = UDim2.new(1, -22, 0, 18)
                    break
                end
            end
        end
    end
    CompactCardDescription(ESPCard)
    CompactCardDescription(BackpackESPCard)
    CompactCardDescription(AntiPaloCard)
    CompactCardDescription(AuraCard)

    local AutoMountBestAnimalCard = CreateCard(
        AnimalAutomationRow,
        "Auto Mount Best Animal",
        "Mounts your fastest rideable animal."
    )
    AutoMountBestAnimalCard.Position = UDim2.new(0, 0, 0, 0)
    AutoMountBestAnimalCard.Size = UDim2.fromOffset(180, 76)
    AutoMountBestAnimalCard.LayoutOrder = 1
    local AutoMountBestAnimalStatus = Create("TextLabel", {
        Name = "BestMountStatus",
        Parent = AutoMountBestAnimalCard,
        Position = UDim2.fromOffset(11, 49),
        Size = UDim2.new(1, -22, 0, 18),
        BackgroundTransparency = 1,
        Text = "Best: scanning rideable mounts...",
        TextColor3 = Theme.Gray,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextWrapped = false,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center
    })
    local AutoMountBestAnimalEnabled = false
    local AutoMountBestAnimalLastRequest = nil
    local AutoMountBestAnimalLastRequestAt = 0

    local function ReadMountSpeed(speedObject)
        if not speedObject then return nil end
        local raw
        if speedObject:IsA("ValueBase") then
            raw = tostring(speedObject.Value)
        elseif speedObject:IsA("TextLabel") or speedObject:IsA("TextButton") or speedObject:IsA("TextBox") then
            raw = speedObject.Text
        else
            local value = speedObject:GetAttribute("Speed")
            if value ~= nil then raw = tostring(value) end
        end
        if raw == nil then return nil end
        raw = tostring(raw):gsub(",", "")
        local numberText = raw:match("[-+]?%d+%.?%d*")
        return numberText and tonumber(numberText) or nil
    end

    local function GetBestRideableMount()
        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not playerGui then return nil, nil, "Waiting for player GUI..." end

        -- Support both inventory GUI variants used by the game.
        local inventoryRoots = {
            playerGui:FindFirstChild("MobileScatchel"),
            playerGui:FindFirstChild("Scatchel")
        }

        local scrolling
        for _, root in ipairs(inventoryRoots) do
            local hotbar = root and root:FindFirstChild("HotBarUi")
            local inventory = hotbar and hotbar:FindFirstChild("Inventory")
            local candidate = inventory and inventory:FindFirstChild("ScrollingFrame")
            if candidate then
                scrolling = candidate
                break
            end
        end

        if not scrolling then
            return nil, nil, "Waiting for mount inventory..."
        end

        local mountEntries = {}
        for _, descendant in ipairs(scrolling:GetDescendants()) do
            if descendant.Name:sub(1, 6) == "Mount_" then
                table.insert(mountEntries, descendant)
            end
        end
        for _, child in ipairs(scrolling:GetChildren()) do
            if child.Name:sub(1, 6) == "Mount_" then
                local found = false
                for _, entry in ipairs(mountEntries) do
                    if entry == child then found = true break end
                end
                if not found then table.insert(mountEntries, child) end
            end
        end

        if #mountEntries == 0 then
            return nil, nil, "Waiting for mount entries..."
        end

        local bestName, bestSpeed
        for _, mountEntry in ipairs(mountEntries) do
            local container = mountEntry:FindFirstChild("Container")
            local speedObject = container and container:FindFirstChild("Speed")
            local speed = ReadMountSpeed(speedObject)
            if speed and (bestSpeed == nil or speed > bestSpeed) then
                bestName = mountEntry.Name:sub(7)
                bestSpeed = speed
            end
        end
        if not bestName then
            return nil, nil, "Waiting for mount speed data..."
        end
        return bestName, bestSpeed
    end

    local function UpdateAutoMountBestAnimal()
        local bestName, bestSpeed, scanMessage = GetBestRideableMount()
        if not bestName then
            AutoMountBestAnimalStatus.Text = scanMessage
            AutoMountBestAnimalStatus.TextColor3 = Theme.Gray
            return
        end

        AutoMountBestAnimalStatus.Text = string.format("Best: %s | Speed: %s", bestName, tostring(bestSpeed))
        AutoMountBestAnimalStatus.TextColor3 = Theme.Accent

        local rideMounts = workspace:FindFirstChild("RideMounts")
        if rideMounts and #rideMounts:GetChildren() > 0 then
            AutoMountBestAnimalLastRequest = nil
            AutoMountBestAnimalLastRequestAt = 0
            return
        end

        local now = os.clock()
        if AutoMountBestAnimalLastRequest ~= bestName or now - AutoMountBestAnimalLastRequestAt >= 3 then
            local rideRemote = game:GetService("ReplicatedStorage"):FindFirstChild("RideRemote")
            if rideRemote and rideRemote:IsA("RemoteEvent") then
                local ok, err = pcall(function()
                    rideRemote:FireServer("Mount", bestName)
                end)
                if ok then
                    AutoMountBestAnimalLastRequest = bestName
                    AutoMountBestAnimalLastRequestAt = now
                    AddDebugLog("[Auto Mount Best Animal] Requested mount: " .. bestName .. " (Speed: " .. tostring(bestSpeed) .. ").")
                else
                    AddDebugLog("[Auto Mount Best Animal] Mount request failed: " .. tostring(err))
                end
            else
                AddDebugLog("[Auto Mount Best Animal] RideRemote RemoteEvent not found.")
            end
        end
    end

    local AutoMountBestAnimalToggle = CreateToggle(AutoMountBestAnimalCard, "", false, function(enabled)
        AutoMountBestAnimalEnabled = enabled
        if not enabled then
            AutoMountBestAnimalStatus.Text = "Auto mount is off"
            AutoMountBestAnimalStatus.TextColor3 = Theme.Gray
            AutoMountBestAnimalLastRequest = nil
            AutoMountBestAnimalLastRequestAt = 0
            return
        end

        AutoMountBestAnimalStatus.Text = "Scanning rideable mounts..."
        task.spawn(function()
            while AutoMountBestAnimalEnabled and not Runtime.Stopped and not ScriptShuttingDown and ScreenGui.Parent do
                local ok, err = pcall(UpdateAutoMountBestAnimal)
                if not ok then
                    AutoMountBestAnimalStatus.Text = "Mount scan error"
                    AutoMountBestAnimalStatus.TextColor3 = Theme.Gray
                    AddDebugLog("[Auto Mount Best Animal] " .. tostring(err):gsub("[%r\\n]+", " "):sub(1, 180))
                end
                task.wait(1)
            end
        end)
    end)
    AutoMountBestAnimalToggle.Position = UDim2.new(1, -58, 0, 7)
    AutoMountBestAnimalToggle.Size = UDim2.fromOffset(48, 24)
    local AutoMountBestAnimalTitle = AutoMountBestAnimalCard:FindFirstChildWhichIsA("TextLabel")
    if AutoMountBestAnimalTitle then
        AutoMountBestAnimalTitle.Size = UDim2.new(1, -78, 0, 22)
    end

    local AutoPlaceBestAnimalCard = CreateCard(
        AnimalAutomationRow,
        "Auto Place Best Animal",
        "Equips the best backpack animal when it beats your lowest placed $/s."
    )
    AutoPlaceBestAnimalCard.Position = UDim2.new(2/3, 5, 0, 0)
    AutoPlaceBestAnimalCard.Size = UDim2.fromOffset(180, 76)
    AutoPlaceBestAnimalCard.LayoutOrder = 2
    local AutoPlaceBestAnimalStatus = Create("TextLabel", {
        Name = "AutoPlaceBestAnimalStatus",
        Parent = AutoPlaceBestAnimalCard,
        Position = UDim2.fromOffset(11, 49),
        Size = UDim2.new(1, -22, 0, 18),
        BackgroundTransparency = 1,
        Text = "Status: OFF",
        TextColor3 = Theme.Gray,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextWrapped = false,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center
    })
    local AutoPlaceBestAnimalEnabled = false
    local AutoPlaceBestAnimalRequestPending = false
    local AutoPlaceBestAnimalLastRequestAt = 0

    local function ParseAutoPlaceCPS(display)
        if type(display) ~= "string" then return -1 end
        local cleaned = display:gsub(",", ""):gsub("%s+", ""):gsub("%$", "")
        cleaned = cleaned:gsub("/[sS]$", "")
        local numberText, suffix = cleaned:match("^([%d%.]+)([%a]*)$")
        local number = tonumber(numberText)
        local scales = {k = 1e3, m = 1e6, b = 1e9, t = 1e12, qa = 1e15, q = 1e15, qi = 1e18}
        local scale = scales[(suffix or ""):lower()]
        if number and number >= 0 and (not suffix or suffix == "" or scale) then
            return number * (scale or 1)
        end
        return -1
    end

    local function ReadAutoPlaceModelCPS(model)
        if not model then return -1 end
        local root = model:FindFirstChild("RootPart")
        local attachment = root and root:FindFirstChild("AnimalOverheadAttachment")
        local overhead = attachment and attachment:FindFirstChild("AnimalOverhead")
        local cashFolder = overhead and overhead:FindFirstChild("CashPerSecond")
        local cashLabel = cashFolder and cashFolder:FindFirstChild("CashPerSecond")
        if cashLabel then
            if cashLabel:IsA("TextLabel") or cashLabel:IsA("TextButton") or cashLabel:IsA("TextBox") then
                local value = ParseAutoPlaceCPS(cashLabel.Text)
                if value >= 0 then return value end
            elseif cashLabel:IsA("ValueBase") then
                local value = ParseAutoPlaceCPS(tostring(cashLabel.Value))
                if value >= 0 then return value end
            end
        end

        for _, node in ipairs(model:GetDescendants()) do
            if node.Name == "CashPerSecond" then
                if node:IsA("TextLabel") or node:IsA("TextButton") or node:IsA("TextBox") then
                    local value = ParseAutoPlaceCPS(node.Text)
                    if value >= 0 then return value end
                elseif node:IsA("ValueBase") then
                    local value = ParseAutoPlaceCPS(tostring(node.Value))
                    if value >= 0 then return value end
                end
                for _, child in ipairs(node:GetDescendants()) do
                    if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                        local value = ParseAutoPlaceCPS(child.Text)
                        if value >= 0 then return value end
                    elseif child:IsA("ValueBase") then
                        local value = ParseAutoPlaceCPS(tostring(child.Value))
                        if value >= 0 then return value end
                    end
                end
            end
        end
        return -1
    end

    local function GetAutoPlaceLowestPlacedCPS()
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
                        local value = ReadAutoPlaceModelCPS(animal)
                        if value >= 0 and value < lowest then
                            lowest = value
                        end
                    end
                end
                return lowest < math.huge and lowest or -1
            end
        end
        return -1
    end

    local function GetAutoPlaceBestBackpackAnimal(lowestPlacedCPS)
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if not backpack then return nil, -1 end
        local bestTool, bestCPS
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local model = tool:FindFirstChild("AnimalModel")
                local value = ReadAutoPlaceModelCPS(model)
                if value > lowestPlacedCPS and (bestCPS == nil or value > bestCPS) then
                    bestTool = tool
                    bestCPS = value
                end
            end
        end
        return bestTool, bestCPS or -1
    end

    local function UpdateAutoPlaceBestAnimal()
        local lowestPlacedCPS = GetAutoPlaceLowestPlacedCPS()
        if lowestPlacedCPS < 0 then
            AutoPlaceBestAnimalRequestPending = false
            AutoPlaceBestAnimalStatus.Text = "No placed animal $/s to compare"
            AutoPlaceBestAnimalStatus.TextColor3 = Theme.Gray
            return
        end

        local bestTool, bestCPS = GetAutoPlaceBestBackpackAnimal(lowestPlacedCPS)
        if not bestTool then
            AutoPlaceBestAnimalRequestPending = false
            AutoPlaceBestAnimalStatus.Text = "No better backpack animal"
            AutoPlaceBestAnimalStatus.TextColor3 = Theme.Gray
            return
        end

        if AutoPlaceBestAnimalRequestPending then
            AutoPlaceBestAnimalStatus.Text = string.format("Better found: %s | Waiting for update", bestTool.Name)
            AutoPlaceBestAnimalStatus.TextColor3 = Theme.Accent
            return
        end

        local now = os.clock()
        if now - AutoPlaceBestAnimalLastRequestAt < 3 then return end
        local remote = game:GetService("ReplicatedStorage"):FindFirstChild("PetsInventoryRemote")
        if not remote or not remote:IsA("RemoteEvent") then
            AutoPlaceBestAnimalStatus.Text = "PetsInventoryRemote not found"
            AutoPlaceBestAnimalStatus.TextColor3 = Theme.Gray
            return
        end

        local ok, err = pcall(function()
            remote:FireServer("EquipBest", nil)
        end)
        AutoPlaceBestAnimalLastRequestAt = now
        if ok then
            AutoPlaceBestAnimalRequestPending = true
            AutoPlaceBestAnimalStatus.Text = string.format("EquipBest sent | Better: %s", bestTool.Name)
            AutoPlaceBestAnimalStatus.TextColor3 = Theme.Accent
            AddDebugLog(string.format("[Auto Place Best Animal] EquipBest sent: backpack $/s %s > lowest placed $/s %s.", tostring(bestCPS), tostring(lowestPlacedCPS)))
        else
            AutoPlaceBestAnimalStatus.Text = "EquipBest request failed"
            AutoPlaceBestAnimalStatus.TextColor3 = Theme.Gray
            AddDebugLog("[Auto Place Best Animal] EquipBest failed: " .. tostring(err):gsub("[%r\\n]+", " "):sub(1, 180))
        end
    end

    local AutoPlaceBestAnimalToggle = CreateToggle(AutoPlaceBestAnimalCard, "", false, function(enabled)
        AutoPlaceBestAnimalEnabled = enabled
        AutoPlaceBestAnimalRequestPending = false
        AutoPlaceBestAnimalLastRequestAt = 0
        if not enabled then
            AutoPlaceBestAnimalStatus.Text = "Status: OFF"
            AutoPlaceBestAnimalStatus.TextColor3 = Theme.Gray
            return
        end

        AutoPlaceBestAnimalStatus.Text = "Scanning backpack $/s..."
        AutoPlaceBestAnimalStatus.TextColor3 = Theme.Accent
        task.spawn(function()
            while AutoPlaceBestAnimalEnabled and not Runtime.Stopped and not ScriptShuttingDown and ScreenGui.Parent do
                local ok, err = pcall(UpdateAutoPlaceBestAnimal)
                if not ok then
                    AutoPlaceBestAnimalStatus.Text = "Scan error"
                    AutoPlaceBestAnimalStatus.TextColor3 = Theme.Gray
                    AddDebugLog("[Auto Place Best Animal] " .. tostring(err):gsub("[%r\\n]+", " "):sub(1, 180))
                end
                task.wait(1)
            end
        end)
    end)
    AutoPlaceBestAnimalToggle.Position = UDim2.new(1, -58, 0, 7)
    AutoPlaceBestAnimalToggle.Size = UDim2.fromOffset(48, 24)
    local AutoPlaceBestAnimalTitle = AutoPlaceBestAnimalCard:FindFirstChildWhichIsA("TextLabel")
    if AutoPlaceBestAnimalTitle then
        AutoPlaceBestAnimalTitle.Size = UDim2.new(1, -78, 0, 22)
    end
    CompactCardDescription(AutoMountBestAnimalCard)
    CompactCardDescription(AutoPlaceBestAnimalCard)

    -- THREE-COLUMN EQUAL CARD LAYOUT
    -- Keep every Misc card the same size; fit text within each card.
    local MiscCardsLayout = Create("Frame", {
        Name = "MiscFeatureCardsLayout",
        Parent = Page,
        Position = UDim2.fromOffset(10, 10),
        Size = UDim2.new(1, -20, 0, 162),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = 0
    })

    local miscCards = {
        ESPCard,
        BackpackESPCard,
        AntiPaloCard,
        AuraCard,
        AutoMountBestAnimalCard,
        AutoPlaceBestAnimalCard
    }

    for _, card in ipairs(miscCards) do
        card.Parent = MiscCardsLayout
    end
    ESPCardsRow:Destroy()
    AnimalAutomationRow:Destroy()

    local function FitMiscCardText(card, cardWidth)
        local titleFound = false
        for _, child in ipairs(card:GetChildren()) do
            if child:IsA("TextLabel") then
                if not titleFound and child.Position.Y.Offset == 8 then
                    titleFound = true
                    child.Size = UDim2.new(1, -78, 0, 22)
                    child.TextWrapped = false
                    child.TextTruncate = Enum.TextTruncate.AtEnd
                elseif child.Position.Y.Offset == 29 then
                    child.Position = UDim2.fromOffset(11, 29)
                    child.Size = UDim2.new(1, -22, 0, 18)
                    child.TextWrapped = true
                    child.TextTruncate = Enum.TextTruncate.AtEnd
                    child.TextYAlignment = Enum.TextYAlignment.Top
                end
            end
        end
    end

    local function RefreshMiscCardLayout()
        local availableWidth = MiscCardsLayout.AbsoluteSize.X
        if availableWidth <= 0 then return end

        local columns = 3
        local horizontalGap = 10
        local verticalGap = 10
        local cardHeight = 76
        local cardWidth = math.floor((availableWidth - horizontalGap * (columns - 1)) / columns)

        for index, card in ipairs(miscCards) do
            local column = (index - 1) % columns
            local row = math.floor((index - 1) / columns)
            card.Position = UDim2.fromOffset(column * (cardWidth + horizontalGap), row * (cardHeight + verticalGap))
            card.Size = UDim2.fromOffset(cardWidth, cardHeight)
            FitMiscCardText(card, cardWidth)
        end

        local rows = math.ceil(#miscCards / columns)
        MiscCardsLayout.Size = UDim2.new(1, -20, 0, rows * cardHeight + (rows - 1) * verticalGap)
    end

    MiscCardsLayout:GetPropertyChangedSignal("AbsoluteSize"):Connect(RefreshMiscCardLayout)
    Page:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        task.defer(RefreshMiscCardLayout)
    end)
    task.defer(RefreshMiscCardLayout)
end
