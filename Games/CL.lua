-- CL compact UI
-- Farm automation and Anti AFK controls.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local UI_NAME = "CLMoldyHubUI"
local deployver = "CL ver 2.16-test"
local displayVersion = "v" .. (string.match(deployver, "[%d%.]+") or "1.1")
local environment = (getgenv and getgenv()) or _G
local previousCleanup = environment.CLMoldyHubCleanup
if type(previousCleanup) == "function" then
    pcall(previousCleanup)
end

local cleanupCallbacks = {}
local managedConnections = {}
local function RegisterCleanup(callback)
    table.insert(cleanupCallbacks, callback)
end
local function ConnectManaged(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(managedConnections, connection)
    return connection
end
RegisterCleanup(function()
    for _, connection in ipairs(managedConnections) do pcall(function() connection:Disconnect() end) end
    table.clear(managedConnections)
end)

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
    Text = '<font color="#2D87FF">Moldy</font>Hub <font face="Gotham" size="9" color="#2D87FF">' .. displayVersion .. '</font>',
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

local floatingViewportConnection
local function WatchFloatingToggleViewport(camera)
    if floatingViewportConnection then floatingViewportConnection:Disconnect(); floatingViewportConnection = nil end
    if camera then floatingViewportConnection = ConnectManaged(camera:GetPropertyChangedSignal("ViewportSize"), KeepFloatingToggleOnScreen) end
end
RegisterCleanup(function()
    if floatingViewportConnection then floatingViewportConnection:Disconnect(); floatingViewportConnection = nil end
end)
WatchFloatingToggleViewport(workspace.CurrentCamera)
ConnectManaged(workspace:GetPropertyChangedSignal("CurrentCamera"), function()
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
ConnectManaged(UserInputService.InputChanged, function(input)
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
ConnectManaged(UserInputService.InputEnded, function(input)
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
    BorderSizePixel = 0,
    ClipsDescendants = true
})
Corner(Content, 12)

local Pages, NavButtons = {}, {}
local TabNames = {"Farm", "Settings", "Webhook"}

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
        Position = UDim2.fromOffset(8, 8),
        Size = UDim2.new(1, -16, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    })
    local leftLayout = Create("UIListLayout", {
        Parent = left,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    local function UpdateCanvas()
        page.CanvasSize = UDim2.new(0, 0, 0, left.AbsolutePosition.Y - page.AbsolutePosition.Y + left.AbsoluteSize.Y + 8)
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
    local function setChecked(value)
        checked = value
        box.BackgroundColor3 = checked and Theme.Accent or Theme.SurfaceInput
        mark.Visible = checked
    end
    row.MouseButton1Click:Connect(function()
        setChecked(not checked)
        if callback then callback(checked) end
    end)
    return row, setChecked
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
        local VirtualInputManager = game:GetService("VirtualInputManager")
        local SkillsConfig, basicAttack
        local basicAttackCheckedAt, skillConfigCheckedAt = 0, 0
        local function FindPath(root, path, timeout)
            local deadline, current = os.clock() + (timeout or 0), root
            for _, childName in ipairs(path) do
                if not current then return nil end
                local child = current:FindFirstChild(childName)
                if not child and timeout and timeout > 0 then child = current:WaitForChild(childName, math.max(0, deadline - os.clock())) end
                if not child then return nil end
                current = child
            end
            return current
        end
        local function getBasicAttackRemote()
            if basicAttack and basicAttack.Parent then return basicAttack end
            if os.clock() - basicAttackCheckedAt < 2 then return nil end
            basicAttackCheckedAt = os.clock()
            local remote = FindPath(ReplicatedStorage, {"Remotes", "BasicAttack"}, 5)
            if remote and remote:IsA("RemoteEvent") then basicAttack = remote end
            return basicAttack
        end
        local function getSkillsConfig()
            if SkillsConfig then return SkillsConfig end
            if os.clock() - skillConfigCheckedAt < 3 then return nil end
            skillConfigCheckedAt = os.clock()
            local module = FindPath(ReplicatedStorage, {"Shared", "Config", "Skills"}, 5)
            if not module or not module:IsA("ModuleScript") then return nil end
            local ok, result = pcall(require, module)
            if ok and type(result) == "table" then SkillsConfig = result
            else warn("[CL Auto farm] Unable to load Skills config:", result) end
            return SkillsConfig
        end
        local function getAbilityRail()
            return FindPath(LocalPlayer, {"PlayerGui", "MainHUD", "Right Column", "Ability Rail", "MainFrame", "Abilities", "Abilities"}, 5)
        end

        local function findSkillByDisplayName(displayName, slot)
            local config = getSkillsConfig()
            if not config or type(displayName) ~= "string" or displayName == "" then return nil end
            for key, skill in pairs(config) do
                if type(skill) == "table"
                    and skill.DisplayName == displayName
                    and tostring(skill.Slot) == slot then
                    return tostring(skill.Id or key), skill
                end
            end
            return nil
        end

        local function getAbilitySkill(slot)
            local abilityRail = getAbilityRail()
            if not abilityRail then return nil end
            local slotFrame = abilityRail:FindFirstChild("Slot_" .. slot)
            local left = slotFrame and slotFrame:FindFirstChild("left")
            local nameLabel = left and left:FindFirstChild("name")
            local displayName = nameLabel and nameLabel.Text
            if not displayName or displayName == "" then return nil end
            return findSkillByDisplayName(displayName, slot)
        end

        local MAX_TARGET_DISTANCE = 200
        local function isValidEnemyRoot(enemyRoot, enemies, playerRoot)
            if not enemyRoot or not enemyRoot:IsA("BasePart") or not enemies then return false end
            local model = enemyRoot.Parent
            if not model or model.Parent ~= enemies then return false end
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health <= 0 then return false end
            if playerRoot and (enemyRoot.Position - playerRoot.Position).Magnitude > MAX_TARGET_DISTANCE then return false end
            return true
        end

        local function getClosestEnemy(root, enemies)
            if not root or not enemies then return nil end

            local closestEnemyRoot
            local closestDistance = math.huge

            for _, enemy in ipairs(enemies:GetChildren()) do
                local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")

                if isValidEnemyRoot(enemyRoot, enemies, root) then
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
        local skillCastBusy = false
        local skillCastBusySince = 0
        local targetClickLoopId = 0

        -- Keep the highlighted target centered after Roblox's normal camera update.
        local RunService = game:GetService("RunService")
        local cameraAimTarget = nil
        local cameraAimBound = true
        local orbitEnabled = false
        local orbitTarget = nil
        local orbitSelectedTarget = nil
        local orbitDistance = 50
        local orbitHeight = 50
        local orbitSpeed = 90
        local orbitAngle = 0
        local orbitHumanoid = nil
        local orbitOriginalPlatformStand = nil

        -- An explicitly selected nearby enemy is a hard lock for every farm action.
        -- Only fall back to automatic target selection after that enemy is no longer valid.
        local function getFarmTarget(root, enemies)
            local selectedTarget = orbitSelectedTarget
            if selectedTarget then
                if isValidEnemyRoot(selectedTarget, enemies, root) then
                    orbitTarget = selectedTarget
                    cameraAimTarget = selectedTarget
                    return selectedTarget
                end
                orbitSelectedTarget = nil
                if orbitTarget == selectedTarget then orbitTarget = nil end
            end

            if orbitEnabled then
                local nextTarget = getClosestEnemy(root, enemies)
                if nextTarget then
                    orbitTarget = nextTarget
                    cameraAimTarget = nextTarget
                end
                return nextTarget
            end

            return getClosestEnemy(root, enemies)
        end

        local targetHighlight = Instance.new("Highlight")
        targetHighlight.Name = "CLSelectedEnemyHighlight"
        targetHighlight.FillColor = Color3.fromRGB(45, 135, 255)
        targetHighlight.OutlineColor = Color3.fromRGB(220, 240, 255)
        targetHighlight.FillTransparency = 0.72
        targetHighlight.OutlineTransparency = 0
        targetHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        targetHighlight.Enabled = false
        targetHighlight.Parent = workspace

        RunService:BindToRenderStep("CLMoldyHubCameraAim", Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
            local target = orbitEnabled and orbitTarget or cameraAimTarget
            local camera = workspace.CurrentCamera

            if orbitEnabled then
                local character = LocalPlayer.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")

                if humanoid and humanoid ~= orbitHumanoid then
                    if orbitHumanoid and orbitOriginalPlatformStand ~= nil then
                        pcall(function() orbitHumanoid.PlatformStand = orbitOriginalPlatformStand end)
                    end
                    orbitHumanoid = humanoid
                    orbitOriginalPlatformStand = humanoid.PlatformStand
                    humanoid.PlatformStand = true
                end

                local enemies = workspace:FindFirstChild("Enemies")
                if orbitSelectedTarget and not isValidEnemyRoot(orbitSelectedTarget, enemies, root) then
                    local invalidTarget = orbitSelectedTarget
                    orbitSelectedTarget = nil
                    if orbitTarget == invalidTarget then orbitTarget = nil end
                end

                if orbitSelectedTarget then
                    orbitTarget = orbitSelectedTarget
                elseif not isValidEnemyRoot(orbitTarget, enemies, root) and root then
                    orbitTarget = getClosestEnemy(root, enemies)
                end

                target = orbitTarget
                if target then
                    targetHighlight.Adornee = target.Parent
                    targetHighlight.Enabled = true
                end

                if orbitTarget and orbitTarget.Parent then
                    target = orbitTarget
                    targetHighlight.Adornee = target.Parent
                    targetHighlight.Enabled = true
                end

                if target and target.Parent and root then
                    orbitAngle = (orbitAngle + math.rad(orbitSpeed) * deltaTime) % (math.pi * 2)
                    local offset = Vector3.new(
                        math.cos(orbitAngle) * orbitDistance,
                        orbitHeight,
                        math.sin(orbitAngle) * orbitDistance
                    )
                    local orbitPosition = target.Position + offset
                    root.CFrame = CFrame.lookAt(orbitPosition, target.Position)
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                end
            end

            if not target or not target.Parent or not camera then return end
            local cameraPosition = camera.CFrame.Position
            local aimPosition = target.Position - Vector3.new(0, 3, 0)
            if (aimPosition - cameraPosition).Magnitude > 0.01 then
                camera.CFrame = CFrame.lookAt(cameraPosition, aimPosition, camera.CFrame.UpVector)
                camera.Focus = CFrame.new(aimPosition)
            end
        end)

        local function aimCameraAtEnemy(enemyRoot)
            local selectedTarget = orbitSelectedTarget
            if selectedTarget and selectedTarget.Parent then
                enemyRoot = selectedTarget
            end
            if not enemyRoot or not enemyRoot.Parent then return false end

            cameraAimTarget = enemyRoot
            if orbitEnabled then orbitTarget = enemyRoot end
            targetHighlight.Adornee = enemyRoot.Parent
            targetHighlight.Enabled = true
            return true
        end

        local function clearEnemyAim()
            cameraAimTarget = nil
            targetHighlight.Adornee = nil
            targetHighlight.Enabled = false
        end

        -- Tap only the screen center while a valid camera-locked target exists.
        -- The camera aim places the selected enemy under the center reticle.
        local function startTargetClickLoop(enabled)
            targetClickLoopId = targetClickLoopId + 1
            local thisLoop = targetClickLoopId
            if not enabled then return end

            task.spawn(function()
                while thisLoop == targetClickLoopId and autoFarmEnabled do
                    -- Send the mouse click only while the main UI is minimized.
                    local target = orbitSelectedTarget or (orbitEnabled and orbitTarget) or cameraAimTarget
                    local camera = workspace.CurrentCamera
                    local character = LocalPlayer.Character
                    local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
                    local enemies = workspace:FindFirstChild("Enemies")
                    if not Main.Visible and camera and isValidEnemyRoot(target, enemies, playerRoot) then
                        local viewport = camera.ViewportSize
                        local centerX = viewport.X * 0.5
                        local centerY = viewport.Y * 0.5
                        -- Click the center reticle, where the camera lock aims the target.
                        local clickX = centerX
                        local mouseDown = pcall(function()
                            VirtualInputManager:SendMouseButtonEvent(clickX, centerY, 0, true, game, 0)
                        end)
                        if mouseDown then
                            task.wait(0.03)
                            pcall(function() VirtualInputManager:SendMouseButtonEvent(clickX, centerY, 0, false, game, 0) end)
                        end
                    end
                    task.wait(0.5)
                end
            end)
        end

        local function getAssignedSkillTarget(slot, root, enemies)
            if not root or not enemies then return nil end

            -- Keep the just-used target reserved until this skill is ready again.
            if skillAdvancePending[slot] then
                skillTargetAssignments[slot] = nil
                skillAdvancePending[slot] = nil
            end

            local assigned = skillTargetAssignments[slot]
            if assigned and assigned.Parent and assigned.Parent.Parent == enemies
                and (assigned.Position - root.Position).Magnitude <= MAX_TARGET_DISTANCE then
                return assigned
            end
            skillTargetAssignments[slot] = nil

            local enemyModels = enemies:GetChildren()
            if #enemyModels == 0 then return nil end

            local reserved = {}
            for otherSlot, targetRoot in pairs(skillTargetAssignments) do
                if targetRoot and targetRoot.Parent and targetRoot.Parent.Parent == enemies
                    and (targetRoot.Position - root.Position).Magnitude <= MAX_TARGET_DISTANCE then
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

                if enemyRoot and not reserved[enemyRoot]
                    and (enemyRoot.Position - root.Position).Magnitude <= MAX_TARGET_DISTANCE then
                    skillTargetAssignments[slot] = enemyRoot
                    skillLastTargets[slot] = enemy
                    return enemyRoot
                end
            end

            -- No unreserved enemy is available: share an existing skill target.
            local sharedTarget
            local sharedDistance = math.huge
            for _, targetRoot in pairs(skillTargetAssignments) do
                if targetRoot and targetRoot.Parent and targetRoot.Parent.Parent == enemies then
                    local distance = (targetRoot.Position - root.Position).Magnitude
                    if distance <= MAX_TARGET_DISTANCE and distance < sharedDistance then
                        sharedTarget = targetRoot
                        sharedDistance = distance
                    end
                end
            end

            if sharedTarget then
                skillTargetAssignments[slot] = sharedTarget
                skillLastTargets[slot] = sharedTarget.Parent
                return sharedTarget
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

                        local enemyRoot
                        if orbitSelectedTarget then
                            enemyRoot = getFarmTarget(root, enemies)
                        elseif orbitEnabled then
                            enemyRoot = getFarmTarget(root, enemies)
                        else
                            enemyRoot = getAssignedSkillTarget(slot, root, enemies)
                        end
                        if enemyRoot then
                            -- Serialize casts so each skill gets a clean camera-aim window.
                            while skillCastBusy and thisLoop == skillLoopIds[slot] and autoFarmEnabled do
                                if os.clock() - skillCastBusySince > 5 then
                                    warn("[CL Auto farm] Skill cast lock timed out; recovering.")
                                    skillCastBusy, skillCastBusySince = false, 0
                                else task.wait(0.05) end
                            end

                            if thisLoop == skillLoopIds[slot] and autoFarmEnabled
                                and enemyRoot.Parent and enemyRoot.Parent.Parent == enemies then
                                skillCastBusy = true
                                skillCastBusySince = os.clock()
                                local aimReady = aimCameraAtEnemy(enemyRoot)
                                -- Let the render-step camera aim run before sending the cast.
                                task.wait()
                                if aimReady and thisLoop == skillLoopIds[slot] and autoFarmEnabled then
                                    local keyCode = Enum.KeyCode[slot]
                                    local keyDownSent = false
                                    local castOk = keyCode and pcall(function()
                                        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
                                        keyDownSent = true
                                        task.wait(0.08)
                                        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
                                        keyDownSent = false
                                    end)
                                    -- Always release the key if activation was interrupted.
                                    if keyDownSent then
                                        pcall(function()
                                            VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
                                        end)
                                    end
                                    if castOk then
                                        -- Mark advancement for the next ready cast; reservation stays
                                        -- active throughout this skill's cooldown.
                                        skillAdvancePending[slot] = true
                                    end
                                end
                                skillCastBusy = false
                                skillCastBusySince = 0
                            end
                        end

                        task.wait(math.max(tonumber(skillData.Cooldown) or 1, 0.1))
                        if skillAdvancePending[slot] then
                            -- Give the skill 2 extra seconds before assigning its next target.
                            task.wait(2)
                        end
                    else
                        task.wait(0.5)
                    end
                end
            end)
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

                    if root and enemies and thisLoop == m1LoopId and autoFarmEnabled and useM1Enabled then
                        local enemyRoot = getFarmTarget(root, enemies)
                        local attackRemote = getBasicAttackRemote()
                        if attackRemote and isValidEnemyRoot(enemyRoot, enemies, root) then
                            pcall(function() attackRemote:FireServer(root.CFrame, nil, enemyRoot.Position, 0) end)
                        end
                    end

                    task.wait(0.5)
                end
            end)
        end

        RegisterCleanup(function()
            targetClickLoopId = targetClickLoopId + 1
            orbitEnabled = false
            if orbitHumanoid and orbitOriginalPlatformStand ~= nil then
                pcall(function() orbitHumanoid.PlatformStand = orbitOriginalPlatformStand end)
            end
            orbitHumanoid = nil
            orbitOriginalPlatformStand = nil
            autoFarmEnabled = false
            useM1Enabled = false
            skillCastBusy, skillCastBusySince = false, 0
            basicAttack = nil
            m1LoopId = m1LoopId + 1
            for _, slot in ipairs({"C", "X", "Z", "V"}) do
                skillEnabled[slot] = false
                skillLoopIds[slot] = skillLoopIds[slot] + 1
                skillTargetAssignments[slot] = nil
                skillLastTargets[slot] = nil
                skillAdvancePending[slot] = nil
            end
            clearEnemyAim()
            if cameraAimBound then
                RunService:UnbindFromRenderStep("CLMoldyHubCameraAim")
                cameraAimBound = false
            end
            targetHighlight:Destroy()
        end)

        local cardsRow = Create("Frame", {
            Parent = left,
            Size = UDim2.new(1, 0, 0, 280),
            BackgroundTransparency = 1
        })
        Create("UIListLayout", {
            Parent = cardsRow,
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder
        })

        local card = CreateCard(cardsRow, "Auto farm", 280)
        card.Size = UDim2.new(0.5, -3, 1, 0)
        CreateToggle(card, "Auto farm", 34, function(enabled)
            autoFarmEnabled = enabled
            if not enabled then clearEnemyAim() end
            startTargetClickLoop(enabled)
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

        -- Orbit movement circles the currently selected enemy target.
        local function setOrbitEnabled(enabled)
            orbitEnabled = enabled
            if not enabled then
                if orbitHumanoid and orbitOriginalPlatformStand ~= nil then
                    pcall(function() orbitHumanoid.PlatformStand = orbitOriginalPlatformStand end)
                end
                orbitHumanoid = nil
                orbitOriginalPlatformStand = nil
                orbitTarget = nil
            else
                local character = LocalPlayer.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                local enemies = workspace:FindFirstChild("Enemies")
                if orbitSelectedTarget and orbitSelectedTarget.Parent
                    and orbitSelectedTarget.Parent.Parent == enemies then
                    orbitTarget = orbitSelectedTarget
                else
                    -- No explicit nearby-list lock: begin with Auto Farm's closest target.
                    orbitSelectedTarget = nil
                    orbitTarget = getClosestEnemy(root, enemies)
                end
                if orbitTarget then
                    aimCameraAtEnemy(orbitTarget)
                end
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    orbitHumanoid = humanoid
                    orbitOriginalPlatformStand = humanoid.PlatformStand
                    humanoid.PlatformStand = true
                end
            end
        end

        local orbitCard = CreateCard(cardsRow, "Enemy Orbit", 280)
        orbitCard.Size = UDim2.new(0.5, -3, 1, 0)
        CreateCheckbox(orbitCard, "Enable Flying Orbit", 34, function(checked)
            setOrbitEnabled(checked)
        end)

        Create("TextLabel", {
            Parent = orbitCard,
            Position = UDim2.fromOffset(12, 59),
            Size = UDim2.new(1, -24, 0, 16),
            BackgroundTransparency = 1,
            Text = "Enemy Nearby",
            TextColor3 = Theme.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        local enemyList = Create("ScrollingFrame", {
            Parent = orbitCard,
            Position = UDim2.fromOffset(12, 78),
            Size = UDim2.new(1, -24, 0, 88),
            BackgroundColor3 = Theme.SurfaceInput,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Gray,
            CanvasSize = UDim2.new(0, 0, 0, 0)
        })
        Corner(enemyList, 5)
        Stroke(enemyList, Theme.Border, 1)
        local enemyListLayout = Create("UIListLayout", {
            Parent = enemyList,
            Padding = UDim.new(0, 3),
            SortOrder = Enum.SortOrder.Name
        })
        enemyListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            enemyList.CanvasSize = UDim2.new(0, 0, 0, enemyListLayout.AbsoluteContentSize.Y + 6)
        end)

        local enemyListStatus = Create("TextLabel", {
            Parent = orbitCard,
            Position = UDim2.fromOffset(12, 169),
            Size = UDim2.new(1, -24, 0, 14),
            BackgroundTransparency = 1,
            Text = "Select an enemy to lock",
            TextColor3 = Theme.DarkGray,
            Font = Enum.Font.Gotham,
            TextSize = 8,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        local function refreshNearbyEnemies()
            for _, child in ipairs(enemyList:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end

            local enemies = workspace:FindFirstChild("Enemies")
            local enemyModels = enemies and enemies:GetChildren() or {}
            local validCount = 0
            local character = LocalPlayer.Character
            local playerRoot = character and character:FindFirstChild("HumanoidRootPart")

            table.sort(enemyModels, function(a, b)
                return a.Name < b.Name
            end)

            for _, enemy in ipairs(enemyModels) do
                local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
                if enemyRoot then
                    validCount = validCount + 1
                    local distance = playerRoot and math.floor((enemyRoot.Position - playerRoot.Position).Magnitude) or 0
                    local isSelected = orbitSelectedTarget == enemyRoot
                    local button = Create("TextButton", {
                        Parent = enemyList,
                        Size = UDim2.new(1, -6, 0, 22),
                        BackgroundColor3 = isSelected and Theme.Accent or Theme.Card,
                        BackgroundTransparency = isSelected and 0.12 or 0,
                        BorderSizePixel = 0,
                        Text = enemy.Name .. "  •  " .. tostring(distance) .. " studs",
                        TextColor3 = Theme.Text,
                        Font = Enum.Font.Gotham,
                        TextSize = 8,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        AutoButtonColor = true
                    })
                    Corner(button, 4)
                    button.MouseButton1Click:Connect(function()
                        local character = LocalPlayer.Character
                        local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
                        if not isValidEnemyRoot(enemyRoot, enemies, playerRoot) then return end

                        if orbitSelectedTarget == enemyRoot then
                            -- Clicking the active lock again unselects it.
                            orbitSelectedTarget = nil
                            if orbitEnabled then
                                local character = LocalPlayer.Character
                                local root = character and character:FindFirstChild("HumanoidRootPart")
                                orbitTarget = getClosestEnemy(root, enemies)
                                if orbitTarget then
                                    aimCameraAtEnemy(orbitTarget)
                                else
                                    clearEnemyAim()
                                end
                            end
                        else
                            orbitSelectedTarget = enemyRoot
                            orbitTarget = enemyRoot
                            cameraAimTarget = enemyRoot
                            aimCameraAtEnemy(enemyRoot)
                        end

                        refreshNearbyEnemies()
                    end)
                end
            end

            if validCount == 0 then
                enemyListStatus.Text = "No enemies found"
            elseif orbitSelectedTarget and orbitSelectedTarget.Parent then
                enemyListStatus.Text = "Locked: " .. orbitSelectedTarget.Parent.Name
            else
                enemyListStatus.Text = tostring(validCount) .. " enemies found • select to lock"
            end
        end

        task.spawn(function()
            while orbitCard.Parent do
                refreshNearbyEnemies()
                task.wait(1)
            end
        end)

        local function createOrbitInput(label, y, defaultValue, minValue, maxValue, setter)
            Create("TextLabel", {
                Parent = orbitCard,
                Position = UDim2.fromOffset(12, y + 2),
                Size = UDim2.fromOffset(78, 18),
                BackgroundTransparency = 1,
                Text = label,
                TextColor3 = Theme.DarkGray,
                Font = Enum.Font.Gotham,
                TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            local input = Create("TextBox", {
                Parent = orbitCard,
                Position = UDim2.new(1, -66, 0, y),
                Size = UDim2.fromOffset(54, 23),
                BackgroundColor3 = Theme.SurfaceInput,
                TextColor3 = Theme.Text,
                PlaceholderColor3 = Theme.Gray,
                PlaceholderText = tostring(defaultValue),
                Text = tostring(defaultValue),
                Font = Enum.Font.Gotham,
                TextSize = 9,
                ClearTextOnFocus = false,
                BorderSizePixel = 0
            })
            Corner(input, 5)
            Stroke(input, Theme.Border, 1)
            input.FocusLost:Connect(function()
                local value = tonumber(input.Text)
                if value then
                    value = math.clamp(value, minValue, maxValue)
                    setter(value)
                    input.Text = tostring(value)
                else
                    input.Text = tostring(defaultValue)
                end
            end)
        end

        createOrbitInput("Distance (studs)", 190, 50, 3, 100, function(value)
            orbitDistance = value
        end)
        createOrbitInput("Flying height (studs)", 219, 50, 0, 100, function(value)
            orbitHeight = value
        end)
        createOrbitInput("Speed (deg/sec)", 248, 90, 10, 360, function(value)
            orbitSpeed = value
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
    elseif index == 3 then
        -- Grimoire notifier UI. The filter list is populated from the shop's
        -- Grimoire filter names come from the shop's Grimoire row frames.
        -- StockShopState is only observed; this script never fires the remote.
        local grimoireNotifierEnabled = false
        local webhookUrl = ""
        local roleId = ""
        local grimoireFilter = {}
        local previousStock = {}
        local stockConnection

        local card = CreateCard(left, "Grimoire Notifier", 360)
        CreateToggle(card, "Grimoire Notifier", 34, function(enabled)
            grimoireNotifierEnabled = enabled
        end)

        local function createNotifierInput(labelText, placeholder, y)
            Create("TextLabel", {
                Parent = card,
                Position = UDim2.fromOffset(12, y),
                Size = UDim2.new(1, -24, 0, 13),
                BackgroundTransparency = 1,
                Text = labelText,
                TextColor3 = Theme.DarkGray,
                Font = Enum.Font.Gotham,
                TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 2
            })
            local input = Create("TextBox", {
                Parent = card,
                Position = UDim2.fromOffset(12, y + 17),
                Size = UDim2.new(1, -24, 0, 24),
                BackgroundColor3 = Theme.SurfaceInput,
                BackgroundTransparency = 0,
                Text = "",
                PlaceholderText = placeholder,
                PlaceholderColor3 = Theme.Gray,
                TextColor3 = Theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                TextEditable = true,
                Active = true,
                BorderSizePixel = 0,
                ZIndex = 2
            })
            Corner(input, 5)
            Create("UIPadding", {
                Parent = input,
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8)
            })
            return input
        end

        local webhookInput = createNotifierInput("Webhook URL", "Paste Discord webhook URL", 63)
        webhookInput.FocusLost:Connect(function()
            webhookUrl = string.gsub(webhookInput.Text, "^%s*(.-)%s*$", "%1")
        end)

        local roleInput = createNotifierInput("Role ID (optional)", "Enter Discord role ID to mention", 110)
        roleInput.FocusLost:Connect(function()
            roleId = string.gsub(roleInput.Text, "^%s*(.-)%s*$", "%1")
            if roleId ~= "" and not string.match(roleId, "^%d+$") then
                roleId = ""
                roleInput.Text = ""
                roleInput.PlaceholderText = "Role ID must contain numbers only"
            end
        end)

        Create("TextLabel", {
            Parent = card,
            Position = UDim2.fromOffset(12, 159),
            Size = UDim2.new(1, -24, 0, 13),
            BackgroundTransparency = 1,
            Text = "Webhook Test",
            TextColor3 = Theme.DarkGray,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 2
        })

        local testWebhookButton = Create("TextButton", {
            Parent = card,
            Position = UDim2.fromOffset(12, 176),
            Size = UDim2.new(1, -24, 0, 24),
            BackgroundColor3 = Theme.Accent,
            Text = "Test Webhook",
            TextColor3 = Theme.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 9,
            BorderSizePixel = 0,
            AutoButtonColor = true,
            ZIndex = 2
        })
        Corner(testWebhookButton, 5)

        Create("TextLabel", {
            Parent = card,
            Position = UDim2.fromOffset(12, 211),
            Size = UDim2.new(1, -24, 0, 13),
            BackgroundTransparency = 1,
            Text = "Grimoire filter",
            TextColor3 = Theme.DarkGray,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 2
        })

        -- BASAE-style dropdown shell with multi-select options.
        local filterDropdown = Create("TextButton", {
            Parent = card,
            Position = UDim2.fromOffset(12, 228),
            Size = UDim2.new(1, -24, 0, 28),
            BackgroundColor3 = Theme.SurfaceInput,
            Text = "",
            BorderSizePixel = 0,
            AutoButtonColor = false,
            ZIndex = 10
        })
        Corner(filterDropdown, 6)

        local filterDropdownText = Create("TextLabel", {
            Parent = filterDropdown,
            Position = UDim2.fromOffset(10, 0),
            Size = UDim2.new(1, -34, 1, 0),
            BackgroundTransparency = 1,
            Text = "Select Grimoires",
            TextColor3 = Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 11
        })
        Create("TextLabel", {
            Parent = filterDropdown,
            Position = UDim2.new(1, -24, 0, 0),
            Size = UDim2.fromOffset(18, 28),
            BackgroundTransparency = 1,
            Text = "v",
            TextColor3 = Theme.Gray,
            Font = Enum.Font.GothamBold,
            TextSize = 9,
            ZIndex = 11
        })

        local filterDropdownOpen = false
        local filterList = Create("ScrollingFrame", {
            Parent = filterDropdown,
            Position = UDim2.new(0, 0, 1, 5),
            Size = UDim2.new(1, 0, 0, 96),
            BackgroundColor3 = Theme.SurfaceInput,
            BorderSizePixel = 0,
            Visible = false,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Gray,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ZIndex = 20
        })
        Corner(filterList, 6)
        local filterLayout = Create("UIListLayout", {
            Parent = filterList,
            Padding = UDim.new(0, 2),
            SortOrder = Enum.SortOrder.Name
        })
        Create("UIPadding", {
            Parent = filterList,
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 5),
            PaddingRight = UDim.new(0, 5)
        })

        filterDropdown.MouseButton1Click:Connect(function()
            filterDropdownOpen = not filterDropdownOpen
            filterList.Visible = filterDropdownOpen
        end)

        local function updateFilterCanvas()
            filterList.CanvasSize = UDim2.new(0, 0, 0, filterLayout.AbsoluteContentSize.Y + 8)
        end
        filterLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateFilterCanvas)

        local function updateFilterDropdownText()
            local selectedNames = {}
            for name, selected in pairs(grimoireFilter) do
                if selected == true then table.insert(selectedNames, name) end
            end
            table.sort(selectedNames)
            if #selectedNames == 0 then
                filterDropdownText.Text = "Select Grimoires"
            elseif #selectedNames == 1 then
                filterDropdownText.Text = selectedNames[1]
            else
                filterDropdownText.Text = tostring(#selectedNames) .. " Grimoires selected"
            end
        end
        local function getGrimoireRows()
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            local shopUI = playerGui and playerGui:FindFirstChild("ShopUI")
            local container = shopUI and shopUI:FindFirstChild("Container")
            local shopPanel = container and container:FindFirstChild("ShopPanel")
            local grimoirePage = shopPanel and shopPanel:FindFirstChild("Page_Grimoire")
            return grimoirePage and grimoirePage:FindFirstChild("Rows")
        end

        local function refreshGrimoireFilter()
            local rows = getGrimoireRows()
            if not rows then return end

            for _, child in ipairs(filterList:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end

            local grimoireNames = {}
            for _, itemFrame in ipairs(rows:GetChildren()) do
                if itemFrame:IsA("Frame") and itemFrame.Name ~= "ShopItem" then
                    grimoireNames[itemFrame.Name] = true
                end
            end

            local sortedNames = {}
            for name in pairs(grimoireNames) do
                table.insert(sortedNames, name)
                if grimoireFilter[name] == nil then
                    grimoireFilter[name] = false
                end
            end
            table.sort(sortedNames)

            for _, grimoireName in ipairs(sortedNames) do
                local selected = grimoireFilter[grimoireName] == true
                local row = Create("TextButton", {
                    Name = grimoireName,
                    Parent = filterList,
                    Size = UDim2.new(1, -2, 0, 22),
                    BackgroundColor3 = Theme.SurfaceInput,
                    BackgroundTransparency = 1,
                    Text = "",
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    ZIndex = 3
                })
                local check = Create("Frame", {
                    Parent = row,
                    Position = UDim2.fromOffset(2, 4),
                    Size = UDim2.fromOffset(14, 14),
                    BackgroundColor3 = selected and Theme.Accent or Theme.Card,
                    BorderSizePixel = 0,
                    ZIndex = 3
                })
                Corner(check, 3)
                local mark = Create("TextLabel", {
                    Parent = check,
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Text = "✓",
                    TextColor3 = Theme.Text,
                    Font = Enum.Font.GothamBold,
                    TextSize = 10,
                    Visible = selected,
                    ZIndex = 4
                })
                Create("TextLabel", {
                    Parent = row,
                    Position = UDim2.fromOffset(23, 0),
                    Size = UDim2.new(1, -27, 1, 0),
                    BackgroundTransparency = 1,
                    Text = grimoireName,
                    TextColor3 = Theme.Text,
                    Font = Enum.Font.Gotham,
                    TextSize = 9,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 4
                })
                row.MouseButton1Click:Connect(function()
                    grimoireFilter[grimoireName] = not grimoireFilter[grimoireName]
                    local isSelected = grimoireFilter[grimoireName]
                    check.BackgroundColor3 = isSelected and Theme.Accent or Theme.Card
                    mark.Visible = isSelected
                    updateFilterDropdownText()
                end)
            end

            updateFilterCanvas()
            updateFilterDropdownText()
        end

        local function getRequestFunction()
            if type(environment.request) == "function" then
                return environment.request
            elseif type(environment.http_request) == "function" then
                return environment.http_request
            elseif type(environment.syn) == "table" and type(environment.syn.request) == "function" then
                return environment.syn.request
            elseif type(environment.http) == "table" and type(environment.http.request) == "function" then
                return environment.http.request
            end
            return nil
        end

        local function sendGrimoireWebhook(grimoireId, price)
            if webhookUrl == "" then
                warn("[MoldyHub] Enter a Discord webhook URL before testing the Grimoire notifier.")
                return
            end
            local requestFunction = getRequestFunction()
            if not requestFunction then
                warn("[MoldyHub] No executor HTTP request function is available; webhook was not sent.")
                return
            end

            local mention = ""
            local allowedMentions = {parse = {}}
            if roleId ~= "" then
                mention = "<@&" .. roleId .. ">"
                allowedMentions.roles = {roleId}
            end

            local payload = {
                content = mention,
                allowed_mentions = allowedMentions,
                embeds = {{
                    title = "✨ Grimoire Stock Alert",
                    description = "**" .. tostring(grimoireId) .. "** is now in stock!",
                    color = 0x2D87FF,
                    fields = {
                        {name = "Status", value = "IN STOCK", inline = true},
                        {name = "Price", value = tostring(price or "Unknown"), inline = true}
                    },
                    footer = {text = "MoldyHub Grimoire Notifier"}
                }}
            }

            local ok, response = pcall(function()
                return requestFunction({
                    Url = webhookUrl,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = HttpService:JSONEncode(payload)
                })
            end)
            if not ok then
                warn("[MoldyHub] Discord webhook request failed: " .. tostring(response))
            end
        end

        local function sendTestWebhook()
            if webhookUrl == "" then
                warn("[MoldyHub] Enter a Discord webhook URL before testing the Grimoire notifier.")
                return
            end

            local selectedGrimoire
            local selectedCount = 0
            for grimoireName, selected in pairs(grimoireFilter) do
                if selected == true then
                    selectedCount = selectedCount + 1
                    selectedGrimoire = grimoireName
                end
            end

            if selectedCount ~= 1 then
                warn("[MoldyHub] Select exactly one Grimoire in the filter list to test the webhook.")
                return
            end

            task.spawn(sendGrimoireWebhook, selectedGrimoire, "Sample")
        end

        testWebhookButton.MouseButton1Click:Connect(sendTestWebhook)

        local function handleStockShopState(data)
            if type(data) ~= "table" or type(data.Items) ~= "table" then return end
            for _, item in pairs(data.Items) do
                if type(item) == "table" and item.GrimoireId ~= nil then
                    local id = tostring(item.GrimoireId)
                    local inStock = item.InStock == true
                    local wasInStock = previousStock[id]
                    previousStock[id] = inStock

                    if grimoireNotifierEnabled and inStock and wasInStock ~= true and grimoireFilter[id] == true then
                        task.spawn(sendGrimoireWebhook, id, item.Price)
                    end
                end
            end
        end

        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local stockShopState = remotes and remotes:FindFirstChild("StockShopState")
        if stockShopState and stockShopState:IsA("RemoteEvent") then
            stockConnection = ConnectManaged(stockShopState.OnClientEvent, handleStockShopState)
        else
            warn("[MoldyHub] StockShopState RemoteEvent was not found under ReplicatedStorage.Remotes.")
        end

        local grimoireRows = getGrimoireRows()
        local rowsAddedConnection, rowsRemovedConnection
        local function watchGrimoireRows(rows)
            if rowsAddedConnection then rowsAddedConnection:Disconnect(); rowsAddedConnection = nil end
            if rowsRemovedConnection then rowsRemovedConnection:Disconnect(); rowsRemovedConnection = nil end
            if not rows then return end
            rowsAddedConnection = rows.ChildAdded:Connect(refreshGrimoireFilter)
            rowsRemovedConnection = rows.ChildRemoved:Connect(refreshGrimoireFilter)
            refreshGrimoireFilter()
        end
        watchGrimoireRows(grimoireRows)
        task.spawn(function()
            while card.Parent do
                local currentRows = getGrimoireRows()
                if currentRows ~= grimoireRows then
                    grimoireRows = currentRows
                    watchGrimoireRows(grimoireRows)
                elseif not grimoireRows then
                    refreshGrimoireFilter()
                end
                task.wait(2)
            end
            if rowsAddedConnection then rowsAddedConnection:Disconnect() end
            if rowsRemovedConnection then rowsRemovedConnection:Disconnect() end
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
ConnectManaged(UserInputService.InputChanged, function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
    end
end)

local function CleanupCLMoldyHub()
    for index = #cleanupCallbacks, 1, -1 do pcall(cleanupCallbacks[index]) end
    cleanupCallbacks = {}
    local gui = game.CoreGui:FindFirstChild(UI_NAME)
    if gui then gui:Destroy() end
    local statusGui = game.CoreGui:FindFirstChild("MoldyHubStatusBarGui")
    if statusGui then statusGui:Destroy() end
end

environment.CLMoldyHubCleanup = CleanupCLMoldyHub
