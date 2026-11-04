-- CL compact UI
-- Farm automation and Anti AFK controls.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local UI_NAME = "CLMoldyHubUI"
local deployver = "CL ver 2.7"
local displayVersion = "v" .. (string.match(deployver, "[%d%.]+") or "1.1")
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
        local SkillsConfig
        local skillsConfigWarningShown = false

        -- Resolve game dependencies only when the related feature actually needs them.
        local function getBasicAttackRemote()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            return remotes and remotes:FindFirstChild("BasicAttack")
        end

        local function getSkillsConfig()
            if SkillsConfig then return SkillsConfig end

            -- Retry on later skill-loop cycles if the module is not ready yet
            -- or require fails temporarily; do not permanently disable skills.
            local shared = ReplicatedStorage:FindFirstChild("Shared")
            local config = shared and shared:FindFirstChild("Config")
            local skillsModule = config and config:FindFirstChild("Skills")
            if not skillsModule then return nil end

            local skillsOk, skillsResult = pcall(require, skillsModule)
            if skillsOk and type(skillsResult) == "table" then
                SkillsConfig = skillsResult
                return SkillsConfig
            end

            if not skillsConfigWarningShown then
                warn("[CL Auto farm] Unable to load Skills config; will retry:", skillsResult)
                skillsConfigWarningShown = true
            end
            return nil
        end

        local function getAbilityRail()
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            local hud = playerGui and playerGui:FindFirstChild("WK_HUD")
            local rightColumn = hud and hud:FindFirstChild("Right Column")
            local abilityRail = rightColumn and rightColumn:FindFirstChild("Ability Rail")
            local mainFrame = abilityRail and abilityRail:FindFirstChild("MainFrame")
            local abilities = mainFrame and mainFrame:FindFirstChild("Abilities")
            return abilities and abilities:FindFirstChild("Abilities")
        end

        local function findSkillByDisplayName(displayName, slot)
            local skillsConfig = getSkillsConfig()
            if not skillsConfig or type(displayName) ~= "string" or displayName == "" then
                return nil
            end

            for key, skill in pairs(skillsConfig) do
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

        local function getClosestEnemy(root, enemies)
            if not root or not enemies then return nil end

            local closestEnemyRoot
            local closestDistance = math.huge

            for _, enemy in ipairs(enemies:GetChildren()) do
                local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")

                if enemyRoot then
                    local distance = (enemyRoot.Position - root.Position).Magnitude
                    if distance <= MAX_TARGET_DISTANCE and distance < closestDistance then
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
        local targetClickLoopId = 0

        -- Keep the highlighted target centered after Roblox's normal camera update.
        local RunService = game:GetService("RunService")
        local cameraAimTarget = nil
        local cameraAimBound = true
        local orbitEnabled = false
        local orbitTarget = nil
        local orbitSelectedTarget = nil
        local orbitDistance = 12
        local orbitHeight = 5
        local orbitSpeed = 90
        local orbitAngle = 0
        local orbitHumanoid = nil
        local orbitOriginalPlatformStand = nil
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

                if (not orbitTarget or not orbitTarget.Parent) and root then
                    local enemies = workspace:FindFirstChild("Enemies")
                    if orbitSelectedTarget and orbitSelectedTarget.Parent
                        and orbitSelectedTarget.Parent.Parent == enemies then
                        orbitTarget = orbitSelectedTarget
                    else
                        orbitSelectedTarget = nil
                        orbitTarget = getClosestEnemy(root, enemies)
                    end
                    target = orbitTarget
                    if target then
                        targetHighlight.Adornee = target.Parent
                        targetHighlight.Enabled = true
                    end
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
            if not enemyRoot or not enemyRoot.Parent then return false end

            cameraAimTarget = enemyRoot
            targetHighlight.Adornee = enemyRoot.Parent
            targetHighlight.Enabled = true
            return true
        end

        local function clearEnemyAim()
            cameraAimTarget = nil
            targetHighlight.Adornee = nil
            targetHighlight.Enabled = false
        end

        -- Click the currently highlighted skill target at its on-screen position every 0.5s.
        local function startTargetClickLoop(enabled)
            targetClickLoopId = targetClickLoopId + 1
            local thisLoop = targetClickLoopId
            if not enabled then return end

            task.spawn(function()
                while thisLoop == targetClickLoopId and autoFarmEnabled do
                    -- Keep clicking the active aim/orbit target even between skill casts.
                    local target = cameraAimTarget
                    if not (target and target.Parent) then
                        target = orbitEnabled and orbitTarget or orbitSelectedTarget
                    end

                    local camera = workspace.CurrentCamera
                    if target and target.Parent and camera then
                        local screenPoint, onScreen = camera:WorldToViewportPoint(target.Position)
                        if onScreen and screenPoint.Z > 0 then
                            -- Always attempt mouse-up separately so a failed press cannot
                            -- leave the synthetic mouse button held down.
                            pcall(function()
                                VirtualInputManager:SendMouseButtonEvent(screenPoint.X, screenPoint.Y, 0, true, game, 0)
                            end)
                            task.wait(0.03)
                            pcall(function()
                                VirtualInputManager:SendMouseButtonEvent(screenPoint.X, screenPoint.Y, 0, false, game, 0)
                            end)
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

                        local enemyRoot = getAssignedSkillTarget(slot, root, enemies)
                        if enemyRoot then
                            -- Serialize casts so each skill gets a clean camera-aim window.
                            while skillCastBusy and thisLoop == skillLoopIds[slot] and autoFarmEnabled do
                                task.wait()
                            end

                            if thisLoop == skillLoopIds[slot] and autoFarmEnabled
                                and enemyRoot.Parent and enemyRoot.Parent.Parent == enemies then
                                skillCastBusy = true
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

                    if root and enemies then
                        if thisLoop == m1LoopId and autoFarmEnabled and useM1Enabled then
                            local enemyRoot = getClosestEnemy(root, enemies)
                            if enemyRoot then
                                pcall(function()
                                    local basicAttack = getBasicAttackRemote()
                                    if not basicAttack then return end
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

        local card = CreateCard(left, "Auto farm", 184)
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

        local orbitCard = CreateCard(left, "Enemy Orbit", 280)
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
                        AutoButtonColor = true
                    })
                    Corner(button, 4)
                    button.MouseButton1Click:Connect(function()
                        if not enemyRoot.Parent or enemyRoot.Parent.Parent ~= enemies then return end
                        orbitSelectedTarget = enemyRoot
                        if orbitEnabled then orbitTarget = enemyRoot end
                        aimCameraAtEnemy(enemyRoot)
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
                Size = UDim2.fromOffset(120, 18),
                BackgroundTransparency = 1,
                Text = label,
                TextColor3 = Theme.DarkGray,
                Font = Enum.Font.Gotham,
                TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            local input = Create("TextBox", {
                Parent = orbitCard,
                Position = UDim2.new(1, -82, 0, y),
                Size = UDim2.fromOffset(70, 23),
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

        createOrbitInput("Distance (studs)", 190, 12, 3, 100, function(value)
            orbitDistance = value
        end)
        createOrbitInput("Flying height (studs)", 219, 5, 0, 100, function(value)
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
