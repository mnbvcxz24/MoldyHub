-- CL UI
-- BASAE visual layout recreated as a UI-only template.
-- Auto farm controls are visual settings only; no farming automation is connected.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local UI_NAME = "CLMoldyHubUI"
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

-- BASAE-style compact game / FPS / brand / ping / runtime status bar.
local StatusBarGui = Create("ScreenGui", {
    Name = "MoldyHubStatusBarGui",
    Parent = game.CoreGui,
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999998,
    ZIndexBehavior = Enum.ZIndexBehavior.Global
})
local StatusBar = Create("Frame", {
    Name = "MoldyHubStatusBar",
    Parent = StatusBarGui,
    Position = UDim2.fromOffset(0, 0),
    Size = UDim2.fromOffset(500, 34),
    BackgroundColor3 = Theme.Card,
    BorderSizePixel = 0,
    Active = true,
    ZIndex = 200
})
Corner(StatusBar, 9)
Stroke(StatusBar, Theme.Border, 1)
local StatusBarScale = Create("UIScale", {Parent = StatusBar, Scale = 0.60})
local function UpdateStatusBarScale()
    local camera = workspace.CurrentCamera
    if camera then
        StatusBarScale.Scale = math.clamp(math.min(0.60, (camera.ViewportSize.X * 0.84) / 500), 0.35, 0.60)
    end
end
local function CenterStatusBarInitially()
    local camera = workspace.CurrentCamera
    local width = camera and camera.ViewportSize.X or 0
    StatusBar.Position = UDim2.fromOffset(math.max(0, (width - StatusBar.AbsoluteSize.X) / 2), 0)
end
UpdateStatusBarScale()
CenterStatusBarInitially()
local accentLine = Create("Frame", {
    Parent = StatusBar,
    Position = UDim2.fromOffset(12, 0),
    Size = UDim2.new(1, -24, 0, 2),
    BackgroundColor3 = Theme.Accent,
    BorderSizePixel = 0,
    ZIndex = 202
})
Corner(accentLine, 2)
local function CreateStatusText(name, position, size, value, color, font, textSize, alignment)
    return Create("TextLabel", {
        Name = name,
        Parent = StatusBar,
        Position = position,
        Size = size,
        BackgroundTransparency = 1,
        Text = value,
        TextColor3 = color,
        Font = font or Enum.Font.GothamMedium,
        TextSize = textSize or 12,
        TextXAlignment = alignment or Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 203
    })
end
local GameNameLabel = CreateStatusText("GameName", UDim2.fromOffset(10, 3), UDim2.fromOffset(112, 28), "Loading game...", Theme.DarkGray, Enum.Font.GothamBold, 10, Enum.TextXAlignment.Left)
GameNameLabel.TextScaled = true
GameNameLabel.TextWrapped = false
local nameConstraint = Instance.new("UITextSizeConstraint")
nameConstraint.MinTextSize = 5
nameConstraint.MaxTextSize = 10
nameConstraint.Parent = GameNameLabel
local function CreateStatusDivider(x)
    Create("Frame", {
        Parent = StatusBar,
        Position = UDim2.fromOffset(x, 9),
        Size = UDim2.fromOffset(1, 16),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        ZIndex = 202
    })
end
CreateStatusDivider(126)
local FPSLabel = CreateStatusText("FPS", UDim2.fromOffset(132, 3), UDim2.fromOffset(58, 28), "0 FPS", Theme.Text, Enum.Font.GothamBold, 10)
CreateStatusDivider(194)
local BrandBadge = Create("Frame", {
    Parent = StatusBar,
    Position = UDim2.fromOffset(201, 5),
    Size = UDim2.fromOffset(102, 24),
    BackgroundColor3 = Theme.Selected,
    BorderSizePixel = 0,
    ZIndex = 202
})
Corner(BrandBadge, 12)
Stroke(BrandBadge, Theme.Border, 1)
Create("TextLabel", {
    Parent = BrandBadge,
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = '<font color="#' .. Theme.Accent:ToHex() .. '">Moldy</font><font color="#' .. Theme.Text:ToHex() .. '">Hub</font>',
    TextColor3 = Theme.Text,
    RichText = true,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    ZIndex = 203
})
CreateStatusDivider(310)
local PingLabel = CreateStatusText("Ping", UDim2.fromOffset(316, 3), UDim2.fromOffset(66, 28), "-- MS", Theme.DarkGray, Enum.Font.GothamBold, 10)
CreateStatusDivider(389)
local DurationLabel = CreateStatusText("Duration", UDim2.fromOffset(395, 3), UDim2.fromOffset(96, 28), "00:00:00", Theme.Text, Enum.Font.GothamBold, 10)
task.spawn(function()
    local ok, info = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    end)
    GameNameLabel.Text = ok and info and type(info.Name) == "string" and info.Name ~= "" and info.Name or (game.Name ~= "" and game.Name or "Roblox Game")
end)
local StatusBarDragging, StatusBarDragInput, StatusBarDragStart, StatusBarStartPosition, StatusBarStartAbsolute = false, nil, nil, nil, nil
StatusBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        StatusBarDragging = true
        StatusBarDragInput = input
        StatusBarDragStart = input.Position
        StatusBarStartPosition = StatusBar.Position
        StatusBarStartAbsolute = StatusBar.AbsolutePosition
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if StatusBarDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input == StatusBarDragInput) then
        local delta = input.Position - StatusBarDragStart
        StatusBar.Position = UDim2.new(StatusBarStartPosition.X.Scale, StatusBarStartPosition.X.Offset + delta.X,
            StatusBarStartPosition.Y.Scale, StatusBarStartPosition.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if StatusBarDragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input == StatusBarDragInput) then
        StatusBarDragging, StatusBarDragInput = false, nil
    end
end)
local FPSFrames, FPSLastUpdate = 0, os.clock()
RunService.RenderStepped:Connect(function()
    FPSFrames = FPSFrames + 1
    local now = os.clock()
    local elapsed = now - FPSLastUpdate
    if elapsed >= 1 then
        FPSLabel.Text = string.format("%d FPS", math.floor(FPSFrames / elapsed + 0.5))
        FPSFrames, FPSLastUpdate = 0, now
    end
end)
local ScriptStartedAt = os.clock()
task.spawn(function()
    local stats = game:GetService("Stats")
    while StatusBarGui.Parent do
        local ping = "--"
        pcall(function()
            local item = stats.Network.ServerStatsItem["Data Ping"]
            local value = item:GetValue()
            if type(value) == "number" then
                ping = tostring(math.floor(value + 0.5))
            else
                local number = string.match(item:GetValueString(), "[%d%.]+")
                if number then ping = tostring(math.floor(tonumber(number) + 0.5)) end
            end
        end)
        PingLabel.Text = ping .. " MS"
        local total = math.max(0, math.floor(os.clock() - ScriptStartedAt))
        DurationLabel.Text = string.format("%02d:%02d:%02d", math.floor(total / 3600), math.floor((total % 3600) / 60), total % 60)
        task.wait(1)
    end
end)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    UpdateStatusBarScale()
end)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    WatchFloatingToggleViewport(workspace.CurrentCamera)
    KeepFloatingToggleOnScreen()
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

for index, name in ipairs(TabNames) do
    local page, left, right = CreatePage(index)
    Pages[index] = page
    if index == 2 then
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
                        for _, enemy in ipairs(enemies:GetChildren()) do
                            if thisLoop ~= skillLoopIds[slot] or not autoFarmEnabled then
                                break
                            end

                            local humanoid = enemy:FindFirstChildOfClass("Humanoid")
                            local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
                            if humanoid and humanoid.Health > 0 and enemyRoot then
                                pcall(function()
                                    castSkill:FireServer(skillId, root.CFrame, enemyRoot.Position)
                                end)
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
                    root.CFrame = root.CFrame + Vector3.new(0, 15, 0)
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
                        for _, enemy in ipairs(enemies:GetChildren()) do
                            if thisLoop ~= m1LoopId or not autoFarmEnabled or not useM1Enabled then
                                break
                            end

                            local humanoid = enemy:FindFirstChildOfClass("Humanoid")
                            local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")

                            if humanoid and humanoid.Health > 0 and enemyRoot then
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
                    root.CFrame = root.CFrame + Vector3.new(0, 15, 0)
                    root.Anchored = true
                    root:SetAttribute("CLAutoFarmFloatActive", true)
                    root:SetAttribute("CLAutoFarmOriginalAnchored", false)
                end
            end
        end)

        local card = CreateCard(left, "Auto farm", 184)
        CreateToggle(card, "Auto farm", 34, function(enabled)
            autoFarmEnabled = enabled
            setFarmFloat(enabled)
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
