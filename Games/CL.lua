-- CL compact UI
-- Farm automation and Anti AFK controls.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local UI_NAME = "CLMoldyHubUI"
local environment = (getgenv and getgenv()) or _G
local previousCleanup = environment.CLMoldyHubCleanup
if type(previousCleanup) == "function" then
    pcall(previousCleanup)
end

local cleanupCallbacks = {}
local function RegisterCleanup(callback)
    table.insert(cleanupCallbacks, callback)
end

local old = game.CoreGui:FindFirstChild(UI_NAME)
if old then old:Destroy() end
local oldStatusBar = game.CoreGui:FindFirstChild("MoldyHubStatusBarGui")
if oldStatusBar then oldStatusBar:Destroy() end

local Theme = {
    Background = Color3.fromRGB(10, 12, 18),
    Sidebar = Color3.fromRGB(15, 18, 27),
    Card = Color3.fromRGB(23, 27, 39),
    Border = Color3.fromRGB(42, 53, 76),
    Text = Color3.fromRGB(242, 247, 255),
    DarkGray = Color3.fromRGB(202, 214, 232),
    Gray = Color3.fromRGB(146, 163, 190),
    LightGray = Color3.fromRGB(31, 38, 54),
    SurfaceInput = Color3.fromRGB(25, 31, 46),
    Selected = Color3.fromRGB(24, 53, 94),
    SelectedText = Color3.fromRGB(245, 250, 255),
    Accent = Color3.fromRGB(45, 135, 255)
}

local function Create(className, properties)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do
        object[property] = value
    end
    return object
end

local function Corner(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = object
    return c
end

local function Stroke(object, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Border
    s.Thickness = thickness or 1
    s.Parent = object
    return s
end

local function Tween(object, properties)
    TweenService:Create(object, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties):Play()
end

local ScreenGui = Create("ScreenGui", {
    Name = UI_NAME,
    Parent = game.CoreGui,
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999999,
    ZIndexBehavior = Enum.ZIndexBehavior.Global
})

local Main = Create("Frame", {
    Name = "Main",
    Parent = ScreenGui,
    Size = UDim2.fromOffset(360, 320),
    Position = UDim2.new(0.5, -180, 0.5, -160),
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0,
    ClipsDescendants = true
})
Corner(Main, 12)
Stroke(Main, Theme.Border, 1)

local TopBar = Create("Frame", {
    Parent = Main,
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0
})
Corner(TopBar, 12)

local Title = Create("TextLabel", {
    Name = "Title",
    Parent = TopBar,
    Position = UDim2.fromOffset(14, 0),
    Size = UDim2.new(1, -56, 1, 0),
    BackgroundTransparency = 1,
    Text = '<font color="#2D87FF">Moldy</font>Hub <font face="Gotham" size="9" color="#2D87FF">CL</font>',
    RichText = true,
    TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center
})

local CloseButton = Create("TextButton", {
    Parent = TopBar,
    Position = UDim2.new(1, -28, 0, 8),
    Size = UDim2.fromOffset(24, 24),
    BackgroundColor3 = Theme.SurfaceInput,
    Text = "×",
    TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    BorderSizePixel = 0
})
Corner(CloseButton, 8)
Stroke(CloseButton, Theme.Border, 1)
CloseButton.MouseButton1Click:Connect(function()
    Main.Visible = false
end)

-- BASAE-style floating minimize circle. It remains available when the window is hidden.
local FloatingToggle = Create("TextButton", {
    Name = "FloatingToggle",
    Parent = ScreenGui,
    Position = UDim2.new(1, -52, 0, 16),
    Size = UDim2.fromOffset(36, 36),
    BackgroundColor3 = Theme.Sidebar,
    Text = "B",
    TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    BorderSizePixel = 0,
    AutoButtonColor = true,
    Active = true,
    ZIndex = 100
})
Corner(FloatingToggle, 18)
Stroke(FloatingToggle, Theme.Border, 1)

local function GetFloatingToggleBounds()
    local camera = workspace.CurrentCamera
    if not camera then return 0, 0 end
    local viewport = camera.ViewportSize
    local buttonSize = FloatingToggle.AbsoluteSize
    return math.max(0, viewport.X - buttonSize.X), math.max(0, viewport.Y - buttonSize.Y)
end

local function ClampFloatingTogglePosition(x, y)
    local maxX, maxY = GetFloatingToggleBounds()
    return math.clamp(x, 0, maxX), math.clamp(y, 0, maxY)
end

local function PositionFloatingToggleUpperRight()
    local maxX = GetFloatingToggleBounds()
    FloatingToggle.Position = UDim2.fromOffset(math.max(0, maxX - 16), 16)
end
PositionFloatingToggleUpperRight()

local function KeepFloatingToggleOnScreen()
    local x, y = ClampFloatingTogglePosition(FloatingToggle.AbsolutePosition.X, FloatingToggle.AbsolutePosition.Y)
    FloatingToggle.Position = UDim2.fromOffset(x, y)
end

local function WatchFloatingToggleViewport(camera)
    if camera then
        camera:GetPropertyChangedSignal("ViewportSize"):Connect(KeepFloatingToggleOnScreen)
    end
end
WatchFloatingToggleViewport(workspace.CurrentCamera)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    WatchFloatingToggleViewport(workspace.CurrentCamera)
    KeepFloatingToggleOnScreen()
end)

local CircleDragging, CircleDragInput, CircleDragStart, CircleStartPosition, CircleMoved = false, nil, nil, nil, false
FloatingToggle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        CircleDragging = true
        CircleDragInput = input
        CircleDragStart = input.Position
        CircleStartPosition = FloatingToggle.AbsolutePosition
        CircleMoved = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if not CircleDragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input == CircleDragInput then
        local delta = input.Position - CircleDragStart
        if delta.Magnitude > 6 then CircleMoved = true end
        if CircleMoved then
            local x, y = ClampFloatingTogglePosition(CircleStartPosition.X + delta.X, CircleStartPosition.Y + delta.Y)
            FloatingToggle.Position = UDim2.fromOffset(x, y)
        end
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if CircleDragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input == CircleDragInput) then
        local wasDragged = CircleMoved
        CircleDragging, CircleDragInput, CircleMoved = false, nil, false
        if not wasDragged then Main.Visible = not Main.Visible end
    end
end)

local NavigationBar = Create("Frame", {
    Parent = Main,
    Position = UDim2.fromOffset(0, 40),
    Size = UDim2.new(1, 0, 0, 32),
    BackgroundColor3 = Theme.Sidebar,
    BorderSizePixel = 0
})

local Navigation = Create("ScrollingFrame", {
    Parent = NavigationBar,
    Position = UDim2.fromOffset(10, 2),
    Size = UDim2.new(1, -20, 1, -4),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 0,
    ScrollingDirection = Enum.ScrollingDirection.X,
    AutomaticCanvasSize = Enum.AutomaticSize.X,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ClipsDescendants = true
})
Create("UIListLayout", {
    Parent = Navigation,
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 3),
    SortOrder = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Center
})

local Content = Create("Frame", {
    Parent = Main,
    Position = UDim2.fromOffset(0, 72),
    Size = UDim2.new(1, 0, 1, -72),
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0
})

local Pages, NavButtons = {}, {}
local TabNames = {"Farm", "Settings"}

local function CreatePage(index)
    local page = Create("ScrollingFrame", {
        Name = "Page_" .. index,
        Parent = Content,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Gray,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = index == 1
    })
    local left = Create("Frame", {
        Parent = page,
        Position = UDim2.fromOffset(10, 10),
        Size = UDim2.new(1, -20, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    })
    local leftLayout = Create("UIListLayout", {
        Parent = left,
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    local function UpdateCanvas()
        page.CanvasSize = UDim2.new(0, 0, 0, left.AbsolutePosition.Y - page.AbsolutePosition.Y + left.AbsoluteSize.Y + 10)
    end
    leftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)
    page:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateCanvas)
    task.defer(UpdateCanvas)
    return page, left
end

local function CreateCard(parent, title, height)
    local card = Create("Frame", {
        Name = title:gsub("%s+", ""),
        Parent = parent,
        Size = UDim2.new(1, 0, 0, height or 110),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0
    })
    Corner(card, 8)
    Stroke(card, Theme.Border, 1)
    Create("TextLabel", {
        Parent = card,
        Position = UDim2.fromOffset(12, 8),
        Size = UDim2.new(1, -24, 0, 18),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    return card
end

local function CreateToggle(parent, label, y, callback)
    local row = Create("TextButton", {
        Parent = parent,
        Position = UDim2.fromOffset(12, y),
        Size = UDim2.new(1, -24, 0, 24),
        BackgroundTransparency = 1,
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false
    })
    Create("TextLabel", {
        Parent = row,
        Size = UDim2.new(1, -48, 1, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    local switch = Create("Frame", {
        Parent = row,
        Position = UDim2.new(1, -34, 0.5, -7),
        Size = UDim2.fromOffset(30, 14),
        BackgroundColor3 = Color3.fromRGB(49, 67, 82),
        BorderSizePixel = 0
    })
    Corner(switch, 20)
    local knob = Create("Frame", {
        Parent = switch,
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.fromOffset(10, 10),
        BackgroundColor3 = Color3.fromRGB(245, 250, 255),
        BorderSizePixel = 0
    })
    Corner(knob, 20)
    local enabled = false
    local function update()
        Tween(switch, {BackgroundColor3 = enabled and Theme.Accent or Color3.fromRGB(49, 67, 82)})
        Tween(knob, {Position = enabled and UDim2.new(1, -12, 0, 2) or UDim2.fromOffset(2, 2)})
        if callback then callback(enabled) end
    end
    row.MouseButton1Click:Connect(function()
        enabled = not enabled
        update()
    end)
    return row
end

local function CreateCheckbox(parent, label, y, callback)
    local row = Create("TextButton", {
        Parent = parent,
        Position = UDim2.fromOffset(12, y),
        Size = UDim2.new(1, -24, 0, 20),
        BackgroundTransparency = 1,
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false
    })
    local box = Create("Frame", {
        Parent = row,
        Position = UDim2.new(1, -17, 0.5, -7),
        Size = UDim2.fromOffset(14, 14),
        BackgroundColor3 = Theme.SurfaceInput,
        BorderSizePixel = 0
    })
    Corner(box, 3)
    Stroke(box, Theme.Border, 1)
    local mark = Create("TextLabel", {
        Parent = box,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "✓",
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        Visible = false
    })
    Create("TextLabel", {
        Parent = row,
        Size = UDim2.new(1, -30, 1, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = Theme.DarkGray,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    local checked = false
    row.MouseButton1Click:Connect(function()
        checked = not checked
        box.BackgroundColor3 = checked and Theme.Accent or Theme.SurfaceInput
        mark.Visible = checked
        if callback then callback(checked) end
    end)
    return row
end

for index, name in ipairs(TabNames) do
    local button = Create("TextButton", {
        Name = "NavigationButton_" .. index,
        Parent = Navigation,
        Size = UDim2.fromOffset(math.max(48, (#name * 5) + 14), 28),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = index == 1 and Theme.Text or Theme.DarkGray,
        Font = Enum.Font.GothamMedium,
        TextSize = 9,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Center,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        LayoutOrder = index
    })
    local line = Create("Frame", {
        Name = "ActiveLine",
        Parent = button,
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -1),
        Size = UDim2.new(0.62, 0, 0, 2),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Visible = index == 1
    })
    Corner(line, 1)
    NavButtons[index] = button
    button.MouseButton1Click:Connect(function()
        for pageIndex, page in pairs(Pages) do
            page.Visible = pageIndex == index
        end
        for buttonIndex, nav in pairs(NavButtons) do
            local active = buttonIndex == index
            nav.TextColor3 = active and Theme.Text or Theme.DarkGray
            nav.ActiveLine.Visible = active
        end
    end)
end

local floatingHeight = 30

for index, name in ipairs(TabNames) do
    local page, left = CreatePage(index)
    Pages[index] = page
    if index == 1 then
        -- Farm tab: one card, matching BASAE's compact card style.
        local autoFarmEnabled = false
        local useM1Enabled = false
        local m1LoopId = 0
        local skillLoopIds = {C = 0, X = 0, Z = 0, V = 0}
        local skillEnabled = {C = false, X = false, Z = false, V = false}
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local basicAttack = ReplicatedStorage
            :WaitForChild("WK_Remotes")
            :WaitForChild("BasicAttack")
        local castSkill = ReplicatedStorage
            :WaitForChild("WK_Remotes")
            :WaitForChild("CastSkill")
        local SkillsModule = ReplicatedStorage
            :WaitForChild("Shared")
            :WaitForChild("Config")
            :WaitForChild("Skills")
        local SkillsConfig
        local skillsOk, skillsResult = pcall(require, SkillsModule)
        if skillsOk and type(skillsResult) == "table" then
            SkillsConfig = skillsResult
        else
            warn("[CL Auto farm] Unable to load Skills config:", skillsResult)
        end

        local AbilityRail = LocalPlayer:WaitForChild("PlayerGui")
            :WaitForChild("WK_HUD")
            :WaitForChild("Right Column")
            :WaitForChild("Ability Rail")
            :WaitForChild("MainFrame")
            :WaitForChild("Abilities")
            :WaitForChild("Abilities")

        local function findSkillByDisplayName(displayName, slot)
            if not SkillsConfig or type(displayName) ~= "string" or displayName == "" then
                return nil
            end

            for key, skill in pairs(SkillsConfig) do
                if type(skill) == "table"
                    and skill.DisplayName == displayName
                    and tostring(skill.Slot) == slot then
                    return tostring(skill.Id or key), skill
                end
            end
            return nil
        end

        local function getAbilitySkill(slot)
            local slotFrame = AbilityRail:FindFirstChild("Slot_" .. slot)
            local left = slotFrame and slotFrame:FindFirstChild("left")
            local nameLabel = left and left:FindFirstChild("name")
            local displayName = nameLabel and nameLabel.Text
            if not displayName or displayName == "" then return nil end
            return findSkillByDisplayName(displayName, slot)
        end

        local function getClosestEnemy(root, enemies)
            if not root or not enemies then return nil end

            local closestEnemyRoot
            local closestDistance = math.huge

            for _, enemy in ipairs(enemies:GetChildren()) do
                local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")

                if enemyRoot then
                    local distance = (enemyRoot.Position - root.Position).Magnitude
                    if distance < closestDistance then
                        closestDistance = distance
                        closestEnemyRoot = enemyRoot
                    end
                end
            end

            return closestEnemyRoot
        end

        -- Each skill reserves one enemy root during its cooldown.
        -- After casting, it advances to the next available enemy location.
        local skillTargetAssignments = {}
        local skillLastTargets = {}
        local skillAdvancePending = {}

        -- Highlight the selected enemy and point the camera at its root.
        local targetHighlight = Instance.new("Highlight")
        targetHighlight.Name = "CLSelectedEnemyHighlight"
        targetHighlight.FillColor = Color3.fromRGB(45, 135, 255)
        targetHighlight.OutlineColor = Color3.fromRGB(220, 240, 255)
        targetHighlight.FillTransparency = 0.72
        targetHighlight.OutlineTransparency = 0
        targetHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        targetHighlight.Enabled = false
        targetHighlight.Parent = workspace

        local function aimCameraAtEnemy(enemyRoot)
            if not enemyRoot or not enemyRoot.Parent then return nil end

            local camera = workspace.CurrentCamera
            if not camera then return nil end

            targetHighlight.Adornee = enemyRoot.Parent
            targetHighlight.Enabled = true

            local cameraPosition = camera.CFrame.Position
            camera.CFrame = CFrame.lookAt(cameraPosition, enemyRoot.Position)
            return camera.CFrame
        end

        local function clearEnemyAim()
            targetHighlight.Adornee = nil
            targetHighlight.Enabled = false
        end

        local function getAssignedSkillTarget(slot, root, enemies)
            if not root or not enemies then return nil end

            -- Keep the just-used target reserved until this skill is ready again.
            if skillAdvancePending[slot] then
                skillTargetAssignments[slot] = nil
                skillAdvancePending[slot] = nil
            end

            local assigned = skillTargetAssignments[slot]
            if assigned and assigned.Parent and assigned.Parent.Parent == enemies then
                return assigned
            end
            skillTargetAssignments[slot] = nil

            local enemyModels = enemies:GetChildren()
            if #enemyModels == 0 then return nil end

            local reserved = {}
            for otherSlot, targetRoot in pairs(skillTargetAssignments) do
                if targetRoot and targetRoot.Parent and targetRoot.Parent.Parent == enemies then
                    reserved[targetRoot] = true
                else
                    skillTargetAssignments[otherSlot] = nil
                end
            end

            -- Start searching immediately after this skill's previous enemy model.
            local startIndex = 0
            local lastTarget = skillLastTargets[slot]
            if lastTarget then
                for index, enemy in ipairs(enemyModels) do
                    if enemy == lastTarget then
                        startIndex = index
                        break
                    end
                end
            end

            for offset = 1, #enemyModels do
                local index = ((startIndex + offset - 1) % #enemyModels) + 1
                local enemy = enemyModels[index]
                local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")

                if enemyRoot and not reserved[enemyRoot] then
                    skillTargetAssignments[slot] = enemyRoot
                    skillLastTargets[slot] = enemy
                    return enemyRoot
                end
            end

            return nil
        end

        local function startSkillLoop(slot, enabled)
            skillLoopIds[slot] = skillLoopIds[slot] + 1
            local thisLoop = skillLoopIds[slot]
            if not (enabled and autoFarmEnabled) then return end

            task.spawn(function()
                while thisLoop == skillLoopIds[slot] and autoFarmEnabled do
                    local skillId, skillData = getAbilitySkill(slot)
                    local character = LocalPlayer.Character
                    local root = character and character:FindFirstChild("HumanoidRootPart")
                    local enemies = workspace:FindFirstChild("Enemies")

                    if skillId and skillData and root and enemies then
                        if thisLoop ~= skillLoopIds[slot] or not autoFarmEnabled then
                            break
                        end

                        local enemyRoot = getAssignedSkillTarget(slot, root, enemies)
                        if enemyRoot then
                            local aimCFrame = aimCameraAtEnemy(enemyRoot)
                            -- Give the camera one frame to place the selected enemy at screen center.
                            task.wait()
                            if aimCFrame and thisLoop == skillLoopIds[slot] and autoFarmEnabled then
                                local castOk = pcall(function()
                                    castSkill:FireServer(skillId, aimCFrame, nil)
                                end)
                                if castOk then
                                    -- Mark advancement for the next ready cast; reservation stays
                                    -- active throughout this skill's cooldown.
                                    skillAdvancePending[slot] = true
                                end
                            end
                        end

                        task.wait(math.max(tonumber(skillData.Cooldown) or 1, 0.1))
                    else
                        task.wait(0.5)
                    end
                end
            end)
        end

        local function setFarmFloat(enabled)
            local character = LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if not root then return end

            if enabled then
                if not root:GetAttribute("CLAutoFarmOriginalAnchored") then
                    root:SetAttribute("CLAutoFarmOriginalAnchored", root.Anchored)
                end
                if not root:GetAttribute("CLAutoFarmFloatActive") then
                    root:SetAttribute("CLAutoFarmFloatActive", true)
                    root.CFrame = root.CFrame + Vector3.new(0, floatingHeight, 0)
                end
                root.Anchored = true
            else
                local wasActive = root:GetAttribute("CLAutoFarmFloatActive")
                if wasActive then
                    root.Anchored = root:GetAttribute("CLAutoFarmOriginalAnchored") == true
                    root:SetAttribute("CLAutoFarmFloatActive", nil)
                    root:SetAttribute("CLAutoFarmOriginalAnchored", nil)
                end
            end
        end

        local function updateM1Loop()
            m1LoopId = m1LoopId + 1
            local thisLoop = m1LoopId
            if not (autoFarmEnabled and useM1Enabled) then return end

            task.spawn(function()
                while thisLoop == m1LoopId and autoFarmEnabled and useM1Enabled do
                    local character = LocalPlayer.Character
                    local root = character and character:FindFirstChild("HumanoidRootPart")
                    local enemies = workspace:FindFirstChild("Enemies")

                    if root and enemies then
                        if thisLoop == m1LoopId and autoFarmEnabled and useM1Enabled then
                            local enemyRoot = getClosestEnemy(root, enemies)
                            if enemyRoot then
                                pcall(function()
                                    basicAttack:FireServer(
                                        root.CFrame,
                                        nil,
                                        enemyRoot.Position,
                                        0
                                    )
                                end)
                            end
                        end
                    end

                    task.wait(0.5)
                end
            end)
        end

        LocalPlayer.CharacterAdded:Connect(function(character)
            if autoFarmEnabled then
                local root = character:WaitForChild("HumanoidRootPart", 5)
                if root and autoFarmEnabled then
                    root.CFrame = root.CFrame + Vector3.new(0, floatingHeight, 0)
                    root.Anchored = true
                    root:SetAttribute("CLAutoFarmFloatActive", true)
                    root:SetAttribute("CLAutoFarmOriginalAnchored", false)
                end
            end
        end)

        RegisterCleanup(function()
            autoFarmEnabled = false
            useM1Enabled = false
            m1LoopId = m1LoopId + 1
            for _, slot in ipairs({"C", "X", "Z", "V"}) do
                skillEnabled[slot] = false
                skillLoopIds[slot] = skillLoopIds[slot] + 1
                skillTargetAssignments[slot] = nil
                skillLastTargets[slot] = nil
                skillAdvancePending[slot] = nil
            end
            setFarmFloat(false)
            clearEnemyAim()
            targetHighlight:Destroy()
        end)

        local card = CreateCard(left, "Auto farm", 184)
        CreateToggle(card, "Auto farm", 34, function(enabled)
            autoFarmEnabled = enabled
            setFarmFloat(enabled)
            if not enabled then clearEnemyAim() end
            updateM1Loop()
            for _, slot in ipairs({"C", "X", "Z", "V"}) do
                startSkillLoop(slot, enabled and skillEnabled[slot] == true)
            end
        end)
        CreateCheckbox(card, "Use M1", 65, function(checked)
            useM1Enabled = checked
            updateM1Loop()
        end)
        CreateCheckbox(card, "Use C", 87, function(checked)
            skillEnabled.C = checked
            startSkillLoop("C", checked)
        end)
        CreateCheckbox(card, "Use X", 109, function(checked)
            skillEnabled.X = checked
            startSkillLoop("X", checked)
        end)
        CreateCheckbox(card, "Use Z", 131, function(checked)
            skillEnabled.Z = checked
            startSkillLoop("Z", checked)
        end)
        CreateCheckbox(card, "Use V", 153, function(checked)
            skillEnabled.V = checked
            startSkillLoop("V", checked)
        end)
        local heightCard = CreateCard(left, "Movement", 64)
        Create("TextLabel", {
            Parent = heightCard,
            Position = UDim2.fromOffset(12, 34),
            Size = UDim2.new(1, -112, 0, 22),
            BackgroundTransparency = 1,
            Text = "Floating height (studs)",
            TextColor3 = Theme.DarkGray,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        local heightInput = Create("TextBox", {
            Parent = heightCard,
            Position = UDim2.new(1, -88, 0, 32),
            Size = UDim2.fromOffset(76, 26),
            BackgroundColor3 = Theme.SurfaceInput,
            BorderSizePixel = 0,
            Text = tostring(floatingHeight),
            PlaceholderText = "30",
            TextColor3 = Theme.Text,
            PlaceholderColor3 = Theme.Gray,
            Font = Enum.Font.Gotham,
            TextSize = 10,
            ClearTextOnFocus = false
        })
        Corner(heightInput, 5)
        Stroke(heightInput, Theme.Border, 1)
        heightInput.FocusLost:Connect(function()
            local enteredHeight = tonumber(heightInput.Text)
            if enteredHeight and enteredHeight > 0 and enteredHeight <= 500 then
                local previousHeight = floatingHeight
                floatingHeight = enteredHeight
                heightInput.Text = tostring(floatingHeight)

                local character = LocalPlayer.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                if root and root:GetAttribute("CLAutoFarmFloatActive") then
                    root.CFrame = root.CFrame + Vector3.new(0, floatingHeight - previousHeight, 0)
                end
            else
                heightInput.Text = tostring(floatingHeight)
            end
        end)

    elseif index == 2 then
        local antiAfkConnection
        RegisterCleanup(function()
            if antiAfkConnection then
                antiAfkConnection:Disconnect()
                antiAfkConnection = nil
            end
        end)
        local card = CreateCard(left, "Anti AFK", 64)
        CreateToggle(card, "Anti AFK", 34, function(enabled)
            if antiAfkConnection then
                antiAfkConnection:Disconnect()
                antiAfkConnection = nil
            end

            if enabled then
                local VirtualUser = game:GetService("VirtualUser")
                antiAfkConnection = LocalPlayer.Idled:Connect(function()
                    pcall(function()
                        VirtualUser:CaptureController()
                        VirtualUser:ClickButton2(Vector2.new())
                    end)
                end)
            end
        end)
    end
end

-- Drag the window from its title area.
local dragging, dragInput, dragStart, startPosition
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
    end
end)

local function CleanupCLMoldyHub()
    for _, callback in ipairs(cleanupCallbacks) do
        pcall(callback)
    end
    cleanupCallbacks = {}
    local gui = game.CoreGui:FindFirstChild(UI_NAME)
    if gui then gui:Destroy() end
    local statusGui = game.CoreGui:FindFirstChild("MoldyHubStatusBarGui")
    if statusGui then statusGui:Destroy() end
end

environment.CLMoldyHubCleanup = CleanupCLMoldyHub
