-- SHOW FIRST PAGE
Pages[1].Visible = true
SidebarButtons[1].TextColor3 = Theme.Text
-- FLOATING TOGGLE
-- The circle is independent from the main window and remains visible at all times.
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
AddCorner(FloatingToggle, 18)
AddStroke(FloatingToggle, Theme.Border, 1)

local function GetFloatingToggleBounds()
    local camera = workspace.CurrentCamera
    if not camera then
        return 0, 0
    end
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
    local clampedX, clampedY = ClampFloatingTogglePosition(
        FloatingToggle.AbsolutePosition.X,
        FloatingToggle.AbsolutePosition.Y
    )
    FloatingToggle.Position = UDim2.fromOffset(clampedX, clampedY)
end

local function WatchViewportSize(camera)
    if not camera then return end
    TrackPersistentConnection(camera:GetPropertyChangedSignal("ViewportSize"):Connect(KeepFloatingToggleOnScreen))
end

WatchViewportSize(workspace.CurrentCamera)
TrackPersistentConnection(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    WatchViewportSize(workspace.CurrentCamera)
    KeepFloatingToggleOnScreen()
end))

local function CenterMainWindow()
    local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
    if not viewport then return end
    Main.Position = UDim2.fromOffset(
        math.max(0, (viewport.X - UIConfig.Width * UIScale.Scale) / 2),
        math.max(0, (viewport.Y - UIConfig.Height * UIScale.Scale) / 2)
    )
end

local function ToggleMainWindow()
    if Main.Visible then
        Main.Visible = false
    else
        -- Reopen at the last position; only the first launch uses the centered default.
        Main.Visible = true
    end
end

-- CLOSE hides the window only. The floating toggle remains available.
CloseButton.MouseButton1Click:Connect(function()
    Main.Visible = false
end)

-- WINDOW DRAGGING
local WindowDragging = false
local WindowDragStart
local WindowStartPosition
local WindowStartAbsolutePosition

-- No edge clamp: the main window can be dragged over Roblox's
-- top bar, chat, menu, and every other CoreGui area.
local function ClampMainWindowPosition(x, y)
    return x, y
end

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        WindowDragging = true
        WindowDragStart = input.Position
        WindowStartPosition = Main.Position
        local absolutePosition = Main.AbsolutePosition
        WindowStartAbsolutePosition = Vector2.new(absolutePosition.X, absolutePosition.Y)
    end
end)

local CircleDragging = false
local CircleDragInput
local CircleDragStart
local CircleStartAbsolutePosition
local CircleMoved = false
local CircleDragThreshold = 6

FloatingToggle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        CircleDragging = true
        CircleDragInput = input
        CircleDragStart = input.Position
        CircleStartAbsolutePosition = FloatingToggle.AbsolutePosition
        CircleMoved = false
    end
end)

TrackPersistentConnection(UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or (CircleDragInput and input == CircleDragInput) then
        if CircleDragging then
            local delta = input.Position - CircleDragStart
            if delta.Magnitude > CircleDragThreshold then
                CircleMoved = true
            end
            if CircleMoved then
                local targetX = CircleStartAbsolutePosition.X + delta.X
                local targetY = CircleStartAbsolutePosition.Y + delta.Y
                local clampedX, clampedY = ClampFloatingTogglePosition(targetX, targetY)
                FloatingToggle.Position = UDim2.fromOffset(clampedX, clampedY)
            end
        end
    end

    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        if WindowDragging then
            -- Apply only this movement step. At a screen edge the window stops,
            -- and the drag origin follows the pointer so reversing direction
            -- moves the window immediately without snapping or bouncing.
            local delta = input.Position - WindowDragStart
            local targetX = WindowStartAbsolutePosition.X + delta.X
            local targetY = WindowStartAbsolutePosition.Y + delta.Y
            -- No edge clamp: let the window travel freely over all Roblox UI.
            -- Preserve the original scale components to avoid a first-drag jump.
            Main.Position = UDim2.new(
                WindowStartPosition.X.Scale,
                WindowStartPosition.X.Offset + delta.X,
                WindowStartPosition.Y.Scale,
                WindowStartPosition.Y.Offset + delta.Y
            )
        end
    end
end))

TrackPersistentConnection(UserInputService.InputEnded:Connect(function(input)
    if CircleDragging and (
        input.UserInputType == Enum.UserInputType.MouseButton1
        or input == CircleDragInput
    ) then
        local wasDragged = CircleMoved
        CircleDragging = false
        CircleDragInput = nil
        CircleMoved = false
        if not wasDragged then
            ToggleMainWindow()
        end
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        WindowDragging = false
    end
end))
