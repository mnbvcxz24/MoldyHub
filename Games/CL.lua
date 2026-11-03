-- CL UI
-- BASAE visual layout recreated as a UI-only template.
-- Auto farm controls are visual settings only; no farming automation is connected.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local UI_NAME = "CLMoldyHubUI"
local old = game.CoreGui:FindFirstChild(UI_NAME)
if old then old:Destroy() end

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
    Size = UDim2.fromOffset(480, 320),
    Position = UDim2.new(0.5, -240, 0.5, -160),
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
    ScreenGui:Destroy()
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
local TabNames = {"Main", "Farm", "Events", "Misc. feature", "Settings"}

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
        Size = UDim2.new(0.5, -15, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    })
    local right = Create("Frame", {
        Parent = page,
        Position = UDim2.new(0.5, 5, 0, 10),
        Size = UDim2.new(0.5, -15, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    })
    local leftLayout = Create("UIListLayout", {
        Parent = left,
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    local rightLayout = Create("UIListLayout", {
        Parent = right,
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    local function UpdateCanvas()
        local bottom = math.max(left.AbsolutePosition.Y - page.AbsolutePosition.Y + left.AbsoluteSize.Y,
            right.AbsolutePosition.Y - page.AbsolutePosition.Y + right.AbsoluteSize.Y)
        page.CanvasSize = UDim2.new(0, 0, 0, bottom + 10)
    end
    leftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)
    rightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)
    page:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateCanvas)
    task.defer(UpdateCanvas)
    return page, left, right
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
        Position = UDim2.fromOffset(11, 8),
        Size = UDim2.new(1, -22, 0, 18),
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

for index, name in ipairs(TabNames) do
    local page, left, right = CreatePage(index)
    Pages[index] = page
    if index == 2 then
        -- Farm tab: one card, matching BASAE's compact card style.
        local autoFarmEnabled = false
        local useM1Enabled = false
        local m1LoopId = 0
        local basicAttack = game:GetService("ReplicatedStorage")
            :WaitForChild("WK_Remotes")
            :WaitForChild("BasicAttack")

        local function updateM1Loop()
            m1LoopId = m1LoopId + 1
            local thisLoop = m1LoopId
            if not (autoFarmEnabled and useM1Enabled) then return end

            task.spawn(function()
                while thisLoop == m1LoopId and autoFarmEnabled and useM1Enabled do
                    local character = LocalPlayer.Character
                    local root = character and character:FindFirstChild("HumanoidRootPart")
                    if root then
                        pcall(function()
                            basicAttack:FireServer(root.CFrame)
                        end)
                    end
                    task.wait(0.5)
                end
            end)
        end

        local card = CreateCard(left, "Auto farm", 150)
        CreateToggle(card, "Auto farm", 34, function(enabled)
            autoFarmEnabled = enabled
            updateM1Loop()
        end)
        CreateCheckbox(card, "Use M1", 65, function(checked)
            useM1Enabled = checked
            updateM1Loop()
        end)
        CreateCheckbox(card, "Use C", 87)
        CreateCheckbox(card, "Use X", 109)
        CreateCheckbox(card, "Use Z", 131)
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
