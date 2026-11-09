-- REUSABLE UI TEMPLATE
-- SERVICES
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local RuntimeEnv = type(getgenv) == "function" and getgenv() or _G
local ConfigFilePath = "MoldyHub/MoldyHub_BASAE_Config.json"
local LegacyConfigFilePath = "MoldyHub/BASAE_Config.json"
local SavedConfig = {}
local ConfigStorageAvailable = type(readfile) == "function" and type(writefile) == "function"
if ConfigStorageAvailable then
    pcall(function()
        local configReadPath = ConfigFilePath
        if type(isfile) == "function" and not isfile(configReadPath) and isfile(LegacyConfigFilePath) then
            configReadPath = LegacyConfigFilePath
        end
        if type(isfile) == "function" and isfile(configReadPath) then
            local decoded = game:GetService("HttpService"):JSONDecode(readfile(configReadPath))
            if type(decoded) == "table" and decoded.Version == 1 then
                SavedConfig = decoded
            end
        end
    end)
end
local testver = "Deploy ver: 1.4"
local ScriptStartedAt = os.clock()
local PreviousRuntimeCleanup = RuntimeEnv.__MoldyHub_BASAE_Cleanup or RuntimeEnv.__BASAECleanup or RuntimeEnv.__BASAESkripCleanup
if type(PreviousRuntimeCleanup) == "function" then
    pcall(PreviousRuntimeCleanup)
end
local Runtime = {Stopped = false, PersistentConnections = {}, BoundRenderSteps = {}}
local function TrackPersistentConnection(connection)
    if connection then table.insert(Runtime.PersistentConnections, connection) end
    return connection
end
RuntimeEnv.__MoldyHub_BASAE_Cleanup = function()
    Runtime.Stopped = true
    pcall(function()
        if type(Runtime.Shutdown) == "function" then
            Runtime.Shutdown()
        end
    end)
    pcall(function()
        for _, bindName in ipairs(Runtime.BoundRenderSteps or {}) do
            RunService:UnbindFromRenderStep(bindName)
        end
        table.clear(Runtime.BoundRenderSteps or {})
    end)
    pcall(function()
        for _, connection in ipairs(Runtime.PersistentConnections or {}) do
            if connection and connection.Connected then
                connection:Disconnect()
            end
        end
        table.clear(Runtime.PersistentConnections or {})
    end)
    pcall(function()
        local oldUI = game.CoreGui:FindFirstChild("MoldyHub_BASAE_UI") or game.CoreGui:FindFirstChild("BASAESkripUI")
        if oldUI then oldUI:Destroy() end
        local oldStatusBar = game.CoreGui:FindFirstChild("MoldyHubStatusBarGui")
        if oldStatusBar then oldStatusBar:Destroy() end
    end)
    pcall(function()
        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        for _, name in ipairs({"MoldyHub_BASAE_EggESP", "MoldyHub_BASAE_BackpackESP", "BASE_Skrip_EggESP", "BASE_Skrip_BackpackESP"}) do
            local oldESP = playerGui and playerGui:FindFirstChild(name)
            if oldESP then
                if name == "MoldyHub_BASAE_BackpackESP" or name == "BASE_Skrip_BackpackESP" then
                    for _, overlayRef in ipairs(oldESP:GetChildren()) do
                        if overlayRef:IsA("ObjectValue") then
                            local overlay = overlayRef.Value
                            if overlay then
                                pcall(function()
                                    overlay:Destroy()
                                end)
                            end
                        end
                    end
                end
                oldESP:Destroy()
            end
        end
    end)
end
-- UI CONFIGURATION
local UIConfig = {
    Title = "MoldyHub",
    Subtitle = "Steal a pet and ride it",
    Width = 480,
    Height = 320,
    SidebarNames = {
        "Main",
        "Farm",
        "Events",
        "Misc. feature",
        "Theme",
        "Settings"
    }
}
-- THEME
local Theme = {
    Background = Color3.fromRGB(5, 5, 7),
    Sidebar = Color3.fromRGB(10, 10, 12),
    Card = Color3.fromRGB(17, 17, 19),
    Border = Color3.fromRGB(48, 39, 25),
    Text = Color3.fromRGB(250, 247, 239),
    DarkGray = Color3.fromRGB(208, 201, 187),
    Gray = Color3.fromRGB(153, 146, 132),
    LightGray = Color3.fromRGB(28, 27, 24),
    SurfaceInput = Color3.fromRGB(22, 21, 18),
    Selected = Color3.fromRGB(70, 47, 18),
    SelectedText = Color3.fromRGB(255, 248, 230),
    Accent = Color3.fromRGB(255, 181, 55),
    AccentText = Color3.fromRGB(35, 21, 3)
}
-- HELPER FUNCTIONS
local function Create(className, properties)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do
        object[property] = value
    end
    return object
end
local function AddCorner(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = object
    return corner
end
local function AddStroke(object, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.Border
    stroke.Thickness = thickness or 1
    stroke.Parent = object
    return stroke
end
local function Tween(object, properties, duration)
    TweenService:Create(
        object,
        TweenInfo.new(
            duration or 0.2,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ),
        properties
    ):Play()
end
-- REMOVE ANY LEFTOVER UI FROM A PREVIOUS RUN
pcall(function()
    local oldUI = game.CoreGui:FindFirstChild("MoldyHub_BASAE_UI") or game.CoreGui:FindFirstChild("BASAESkripUI")
    if oldUI then oldUI:Destroy() end
    local oldStatusBar = game.CoreGui:FindFirstChild("MoldyHubStatusBarGui")
    if oldStatusBar then oldStatusBar:Destroy() end
end)
pcall(function()
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    for _, name in ipairs({"MoldyHub_BASAE_EggESP", "MoldyHub_BASAE_BackpackESP"}) do
        local oldESP = playerGui and playerGui:FindFirstChild(name)
        if oldESP then oldESP:Destroy() end
    end
end)
-- THEME PRESETS
local ThemePresets = {
    ["Midnight Blue + Cyan"] = {
        Background = Color3.fromRGB(16, 24, 32),
        Sidebar = Color3.fromRGB(19, 31, 42),
        Card = Color3.fromRGB(24, 38, 50),
        Border = Color3.fromRGB(38, 56, 71),
        Text = Color3.fromRGB(241, 245, 249),
        DarkGray = Color3.fromRGB(199, 210, 222),
        Gray = Color3.fromRGB(154, 170, 185),
        LightGray = Color3.fromRGB(35, 52, 66),
        SurfaceInput = Color3.fromRGB(26, 42, 55),
        Selected = Color3.fromRGB(26, 55, 70),
        SelectedText = Color3.fromRGB(241, 245, 249),
        Accent = Color3.fromRGB(56, 214, 232),
        AccentText = Color3.fromRGB(10, 27, 34)
    },
    ["Black + Purple"] = {
        Background = Color3.fromRGB(13, 12, 18),
        Sidebar = Color3.fromRGB(20, 17, 28),
        Card = Color3.fromRGB(29, 24, 39),
        Border = Color3.fromRGB(61, 48, 78),
        Text = Color3.fromRGB(248, 245, 255),
        DarkGray = Color3.fromRGB(220, 211, 235),
        Gray = Color3.fromRGB(166, 153, 188),
        LightGray = Color3.fromRGB(42, 34, 55),
        SurfaceInput = Color3.fromRGB(35, 28, 47),
        Selected = Color3.fromRGB(66, 40, 91),
        SelectedText = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(190, 100, 255),
        AccentText = Color3.fromRGB(25, 12, 35)
    },
    ["Dark Gray + Green"] = {
        Background = Color3.fromRGB(23, 26, 27),
        Sidebar = Color3.fromRGB(30, 34, 35),
        Card = Color3.fromRGB(39, 44, 45),
        Border = Color3.fromRGB(65, 75, 72),
        Text = Color3.fromRGB(245, 248, 246),
        DarkGray = Color3.fromRGB(205, 216, 211),
        Gray = Color3.fromRGB(155, 170, 163),
        LightGray = Color3.fromRGB(49, 57, 54),
        SurfaceInput = Color3.fromRGB(33, 39, 37),
        Selected = Color3.fromRGB(37, 76, 57),
        SelectedText = Color3.fromRGB(245, 255, 248),
        Accent = Color3.fromRGB(90, 230, 145),
        AccentText = Color3.fromRGB(9, 30, 18)
    },
    ["Black + Electric Blue"] = {
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
        Accent = Color3.fromRGB(45, 135, 255),
        AccentText = Color3.fromRGB(7, 17, 35)
    },
    ["OLED Black + Amber"] = {
        Background = Color3.fromRGB(5, 5, 7),
        Sidebar = Color3.fromRGB(10, 10, 12),
        Card = Color3.fromRGB(17, 17, 19),
        Border = Color3.fromRGB(48, 39, 25),
        Text = Color3.fromRGB(250, 247, 239),
        DarkGray = Color3.fromRGB(208, 201, 187),
        Gray = Color3.fromRGB(153, 146, 132),
        LightGray = Color3.fromRGB(28, 27, 24),
        SurfaceInput = Color3.fromRGB(22, 21, 18),
        Selected = Color3.fromRGB(70, 47, 18),
        SelectedText = Color3.fromRGB(255, 248, 230),
        Accent = Color3.fromRGB(255, 181, 55),
        AccentText = Color3.fromRGB(35, 21, 3)
    },
    ["Obsidian + Crimson"] = {
        Background = Color3.fromRGB(8, 7, 10),
        Sidebar = Color3.fromRGB(14, 11, 15),
        Card = Color3.fromRGB(22, 17, 22),
        Border = Color3.fromRGB(66, 32, 42),
        Text = Color3.fromRGB(255, 243, 246),
        DarkGray = Color3.fromRGB(218, 197, 203),
        Gray = Color3.fromRGB(165, 137, 146),
        LightGray = Color3.fromRGB(34, 25, 30),
        SurfaceInput = Color3.fromRGB(28, 20, 25),
        Selected = Color3.fromRGB(82, 25, 42),
        SelectedText = Color3.fromRGB(255, 246, 248),
        Accent = Color3.fromRGB(255, 65, 95),
        AccentText = Color3.fromRGB(38, 4, 12)
    },
    ["Deep Ocean + Teal"] = {
        Background = Color3.fromRGB(5, 13, 17),
        Sidebar = Color3.fromRGB(8, 19, 24),
        Card = Color3.fromRGB(13, 27, 33),
        Border = Color3.fromRGB(24, 57, 63),
        Text = Color3.fromRGB(237, 252, 251),
        DarkGray = Color3.fromRGB(190, 215, 214),
        Gray = Color3.fromRGB(129, 166, 166),
        LightGray = Color3.fromRGB(20, 38, 42),
        SurfaceInput = Color3.fromRGB(16, 33, 38),
        Selected = Color3.fromRGB(15, 68, 69),
        SelectedText = Color3.fromRGB(238, 255, 252),
        Accent = Color3.fromRGB(45, 226, 199),
        AccentText = Color3.fromRGB(3, 31, 29)
    },
    ["Graphite + Orange"] = {
        Background = Color3.fromRGB(12, 12, 13),
        Sidebar = Color3.fromRGB(18, 18, 19),
        Card = Color3.fromRGB(27, 27, 28),
        Border = Color3.fromRGB(60, 45, 32),
        Text = Color3.fromRGB(250, 247, 243),
        DarkGray = Color3.fromRGB(211, 203, 194),
        Gray = Color3.fromRGB(160, 151, 141),
        LightGray = Color3.fromRGB(37, 35, 32),
        SurfaceInput = Color3.fromRGB(31, 29, 26),
        Selected = Color3.fromRGB(77, 43, 19),
        SelectedText = Color3.fromRGB(255, 249, 241),
        Accent = Color3.fromRGB(255, 139, 54),
        AccentText = Color3.fromRGB(38, 18, 4)
    },
    ["Dark Plum + Rose"] = {
        Background = Color3.fromRGB(12, 8, 15),
        Sidebar = Color3.fromRGB(19, 12, 23),
        Card = Color3.fromRGB(28, 18, 33),
        Border = Color3.fromRGB(61, 37, 66),
        Text = Color3.fromRGB(255, 244, 252),
        DarkGray = Color3.fromRGB(218, 199, 215),
        Gray = Color3.fromRGB(165, 139, 162),
        LightGray = Color3.fromRGB(37, 25, 42),
        SurfaceInput = Color3.fromRGB(32, 21, 37),
        Selected = Color3.fromRGB(76, 34, 67),
        SelectedText = Color3.fromRGB(255, 246, 252),
        Accent = Color3.fromRGB(255, 105, 180),
        AccentText = Color3.fromRGB(40, 8, 27)
    },
    ["Forest Night + Lime"] = {
        Background = Color3.fromRGB(6, 12, 9),
        Sidebar = Color3.fromRGB(11, 19, 14),
        Card = Color3.fromRGB(17, 28, 21),
        Border = Color3.fromRGB(37, 58, 42),
        Text = Color3.fromRGB(244, 252, 242),
        DarkGray = Color3.fromRGB(202, 216, 199),
        Gray = Color3.fromRGB(145, 169, 141),
        LightGray = Color3.fromRGB(25, 39, 28),
        SurfaceInput = Color3.fromRGB(21, 34, 24),
        Selected = Color3.fromRGB(36, 72, 36),
        SelectedText = Color3.fromRGB(248, 255, 240),
        Accent = Color3.fromRGB(174, 255, 74),
        AccentText = Color3.fromRGB(19, 35, 4)
    }
}
for key, color in pairs(ThemePresets["Black + Electric Blue"]) do
    Theme[key] = color
end
local ActiveThemeName = "Black + Electric Blue"
-- SCREEN GUI
local ScreenGui = Create("ScreenGui", {
    Name = "MoldyHub_BASAE_UI",
    Enabled = false, -- Keep the main UI hidden until the loader finishes.
    Parent = game.CoreGui,
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999999,
    ZIndexBehavior = Enum.ZIndexBehavior.Global
})
local function ApplyTheme(themeName)
    local selectedTheme = ThemePresets[themeName]
    if not selectedTheme then return end
    local previousTheme = {}
    for key, color in pairs(Theme) do
        previousTheme[key] = color
    end
    for key, color in pairs(selectedTheme) do
        Theme[key] = color
    end
    ActiveThemeName = themeName
    local colorProperties = {"BackgroundColor3", "TextColor3", "TextStrokeColor3", "ImageColor3", "ScrollBarImageColor3", "Color"}
    for _, checkboxBorder in ipairs(ScreenGui:GetDescendants()) do
        if checkboxBorder:IsA("Frame") and checkboxBorder.Name == "PickupOptionCheckboxBorder" then
            checkboxBorder.BackgroundColor3 = selectedTheme.Accent
        end
    end
    for _, object in ipairs(ScreenGui:GetDescendants()) do
        for _, property in ipairs(colorProperties) do
            local ok, currentColor = pcall(function()
                return object[property]
            end)
            if ok and typeof(currentColor) == "Color3" then
                for key, previousColor in pairs(previousTheme) do
                    if currentColor == previousColor then
                        pcall(function()
                            object[property] = selectedTheme[key]
                        end)
                        break
                    end
                end
            end
        end
    end
    local titleLabel = ScreenGui:FindFirstChild("Title", true)
    if titleLabel and titleLabel:IsA("TextLabel") then
        titleLabel.RichText = true
        titleLabel.Text = '<font color="#' .. selectedTheme.Accent:ToHex() .. '">Moldy</font>Hub <font face="Gotham" size="9" color="#' .. selectedTheme.Accent:ToHex() .. '">' .. (string.match(testver, "[%d%.]+") and ("v" .. string.match(testver, "[%d%.]+")) or testver) .. '</font>'
    end

    -- The status bar uses a separate ScreenGui for input priority, so update
    -- its badge explicitly whenever the user changes the theme.
    local statusGui = game.CoreGui:FindFirstChild("MoldyHubStatusBarGui")
    if statusGui then
        local statusBar = statusGui:FindFirstChild("MoldyHubStatusBar", true)
        local brandBadge = statusGui:FindFirstChild("BrandBadge", true)
        local brandText = statusGui:FindFirstChild("BrandText", true)
        local accentLine = statusGui:FindFirstChild("AccentLine", true)
        if statusBar then
            statusBar.BackgroundColor3 = selectedTheme.Card
            local outline = statusBar:FindFirstChildOfClass("UIStroke")
            if outline then outline.Color = selectedTheme.Border end
        end
        if accentLine then
            accentLine.BackgroundColor3 = selectedTheme.Accent
        end
        for _, divider in ipairs(statusGui:GetDescendants()) do
            if divider:IsA("Frame") and divider.Name == "StatusDivider" then
                divider.BackgroundColor3 = selectedTheme.Border
            end
        end
        if brandBadge then
            brandBadge.BackgroundColor3 = selectedTheme.Selected
            local outline = brandBadge:FindFirstChildOfClass("UIStroke")
            if outline then outline.Color = selectedTheme.Border end
        end
        if brandText then
            brandText.RichText = true
            brandText.TextColor3 = selectedTheme.Text
            brandText.Text = '<font color="#' .. selectedTheme.Accent:ToHex() .. '">Moldy</font><font color="#' .. selectedTheme.Text:ToHex() .. '">Hub</font>'
        end
        local gameName = statusGui:FindFirstChild("GameName", true)
        local fps = statusGui:FindFirstChild("FPS", true)
        local ping = statusGui:FindFirstChild("Ping", true)
        local duration = statusGui:FindFirstChild("Duration", true)
        if gameName then gameName.TextColor3 = selectedTheme.DarkGray end
        if fps then fps.TextColor3 = selectedTheme.Text end
        if ping then ping.TextColor3 = selectedTheme.DarkGray end
        if duration then duration.TextColor3 = selectedTheme.Text end
    end
end
-- COMPACT TOP STATUS BAR
-- Separate lower DisplayOrder keeps this decorative/draggable bar from
-- intercepting input intended for the main window when they overlap.
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
    AnchorPoint = Vector2.new(0, 0),
    Position = UDim2.fromOffset(0, 0),
    Size = UDim2.fromOffset(500, 34),
    BackgroundColor3 = Theme.Card,
    BorderSizePixel = 0,
    Active = true,
    ZIndex = 200
})
AddCorner(StatusBar, 9)
local StatusBarStroke = AddStroke(StatusBar, Theme.Border, 1)

-- Scale the entire status bar as one unit so the frame, padding,
-- dividers, badge, and every text label stay aligned inside the border.
local StatusBarUIScale = Create("UIScale", {
    Parent = StatusBar,
    Scale = 0.60
})
local function UpdateStatusBarScale()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewportWidth = camera.ViewportSize.X
    -- Keep a little breathing room from both screen edges.
    StatusBarUIScale.Scale = math.clamp(math.min(0.60, (viewportWidth * 0.84) / 500), 0.35, 0.60)
end
UpdateStatusBarScale()
do
    local camera = workspace.CurrentCamera
    local viewportWidth = camera and camera.ViewportSize.X or 0
    local scaledWidth = StatusBar.AbsoluteSize.X
    StatusBar.Position = UDim2.fromOffset(math.max(0, (viewportWidth - scaledWidth) / 2), 0)
end

local StatusBarAccent = Create("Frame", {
    Name = "AccentLine",
    Parent = StatusBar,
    Position = UDim2.fromOffset(12, 0),
    Size = UDim2.new(1, -24, 0, 2),
    BackgroundColor3 = Theme.Accent,
    BorderSizePixel = 0,
    ZIndex = 202
})
AddCorner(StatusBarAccent, 2)

local StatusBarFontSize = 12

local function CreateStatusText(name, position, size, text, color, font, textSize, alignment)
    return Create("TextLabel", {
        Name = name,
        Parent = StatusBar,
        Position = position,
        Size = size,
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color,
        Font = font or Enum.Font.GothamMedium,
        TextSize = textSize or StatusBarFontSize,
        TextXAlignment = alignment or Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 203
    })
end

local GameNameLabel = CreateStatusText("GameName", UDim2.fromOffset(10, 3), UDim2.fromOffset(112, 28), "Loading game...", Theme.DarkGray, Enum.Font.GothamBold, 10, Enum.TextXAlignment.Left)
GameNameLabel.TextScaled = true
GameNameLabel.TextWrapped = false
-- Keep long game names inside their own slot; scale down first, then truncate
-- rather than allowing the text to overlap the FPS section.
GameNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
local GameNameTextConstraint = Instance.new("UITextSizeConstraint")
GameNameTextConstraint.MinTextSize = 5
GameNameTextConstraint.MaxTextSize = 10
GameNameTextConstraint.Parent = GameNameLabel
local function CreateStatusDivider(x)
    local divider = Create("Frame", {
        Name = "StatusDivider",
        Parent = StatusBar,
        Position = UDim2.fromOffset(x, 9),
        Size = UDim2.fromOffset(1, 16),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        ZIndex = 202
    })
    return divider
end
CreateStatusDivider(126)

local FPSLabel = CreateStatusText("FPS", UDim2.fromOffset(132, 3), UDim2.fromOffset(58, 28), "0 FPS", Theme.Text, Enum.Font.GothamBold, 10)
CreateStatusDivider(194)

local BrandBadge = Create("Frame", {
    Name = "BrandBadge",
    Parent = StatusBar,
    Position = UDim2.fromOffset(201, 5),
    Size = UDim2.fromOffset(102, 24),
    BackgroundColor3 = Theme.Selected,
    BorderSizePixel = 0,
    ZIndex = 202
})
AddCorner(BrandBadge, 12)
local BrandBadgeStroke = AddStroke(BrandBadge, Theme.Border, 1)
local BrandText = Create("TextLabel", {
    Name = "BrandText",
    Parent = BrandBadge,
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = '<font color="#' .. Theme.Accent:ToHex() .. '">Moldy</font><font color="#' .. Theme.Text:ToHex() .. '">Hub</font>',
    TextColor3 = Theme.Text,
    RichText = true,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextScaled = false,
    TextWrapped = false,
    ZIndex = 203
})
CreateStatusDivider(310)

local PingLabel = CreateStatusText("Ping", UDim2.fromOffset(316, 3), UDim2.fromOffset(66, 28), "-- MS", Theme.DarkGray, Enum.Font.GothamBold, 10)
CreateStatusDivider(389)

local DurationLabel = CreateStatusText("Duration", UDim2.fromOffset(395, 3), UDim2.fromOffset(96, 28), "00:00:00", Theme.Text, Enum.Font.GothamBold, 10)

-- Resolve the actual experience name without blocking UI creation.
task.spawn(function()
    local ok, info = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    end)
    if ok and info and type(info.Name) == "string" and info.Name ~= "" then
        GameNameLabel.Text = info.Name
    else
        GameNameLabel.Text = game.Name ~= "" and game.Name or "Roblox Game"
    end
end)

local StatusBarDragging = false
local StatusBarDragInput
local StatusBarDragStart
local StatusBarStartPosition
local StatusBarStartAbsolutePosition
-- The status bar is intentionally unrestricted: it can be dragged over
-- Roblox's top bar, chat, menu, and every other CoreGui area.
local function ClampStatusBarPosition(x, y)
    return x, y
end

StatusBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        StatusBarDragging = true
        StatusBarDragInput = input
        StatusBarDragStart = input.Position
        StatusBarStartPosition = StatusBar.Position
        StatusBarStartAbsolutePosition = StatusBar.AbsolutePosition
    end
end)

local StatusBarInputChanged = UserInputService.InputChanged:Connect(function(input)
    if not StatusBarDragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or (StatusBarDragInput and input == StatusBarDragInput) then
        local delta = input.Position - StatusBarDragStart
        local targetX = StatusBarStartAbsolutePosition.X + delta.X
        local targetY = StatusBarStartAbsolutePosition.Y + delta.Y
        -- No edge clamp: allow dragging across the full screen and over Roblox UI.
        StatusBar.Position = UDim2.new(
            StatusBarStartPosition.X.Scale,
            StatusBarStartPosition.X.Offset + delta.X,
            StatusBarStartPosition.Y.Scale,
            StatusBarStartPosition.Y.Offset + delta.Y
        )
    end
end)
local StatusBarInputEnded = UserInputService.InputEnded:Connect(function(input)
    if StatusBarDragging and (
        input.UserInputType == Enum.UserInputType.MouseButton1
        or input == StatusBarDragInput
    ) then
        StatusBarDragging = false
        StatusBarDragInput = nil
        StatusBarStartPosition = nil
        StatusBarStartAbsolutePosition = nil
    end
end)

local StatusBarViewportConnection
local function KeepStatusBarOnScreen()
    -- Intentionally do not reposition the bar on viewport changes.
    -- Its position is user-controlled and may overlap Roblox CoreGui.
end
local function ConnectStatusBarViewport(camera)
    if StatusBarViewportConnection then
        StatusBarViewportConnection:Disconnect()
        StatusBarViewportConnection = nil
    end
    if camera then
        StatusBarViewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            UpdateStatusBarScale()
            KeepStatusBarOnScreen()
        end)
    end
end
ConnectStatusBarViewport(workspace.CurrentCamera)
local StatusBarCameraConnection = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    ConnectStatusBarViewport(workspace.CurrentCamera)
    KeepStatusBarOnScreen()
end)

local FPSFrames = 0
local FPSLastUpdate = os.clock()
local FPSConnection = RunService.RenderStepped:Connect(function()
    FPSFrames += 1
    local now = os.clock()
    local elapsed = now - FPSLastUpdate
    if elapsed >= 1 then
        FPSLabel.Text = string.format("%d FPS", math.floor(FPSFrames / elapsed + 0.5))
        FPSFrames = 0
        FPSLastUpdate = now
    end
end)

task.spawn(function()
    local stats = game:GetService("Stats")
    while not Runtime.Stopped and ScreenGui.Parent do
        local pingText = "--"
        pcall(function()
            local item = stats.Network.ServerStatsItem["Data Ping"]
            local value = item:GetValue()
            if type(value) == "number" then
                pingText = tostring(math.floor(value + 0.5))
            else
                local formatted = item:GetValueString()
                local number = string.match(formatted, "[%d%.]+")
                if number then pingText = tostring(math.floor(tonumber(number) + 0.5)) end
            end
        end)
        PingLabel.Text = pingText .. " MS"
        local totalSeconds = math.max(0, math.floor(os.clock() - ScriptStartedAt))
        local hours = math.floor(totalSeconds / 3600)
        local minutes = math.floor((totalSeconds % 3600) / 60)
        local seconds = totalSeconds % 60
        DurationLabel.Text = string.format("%02d:%02d:%02d", hours, minutes, seconds)
        task.wait(1)
    end
end)

table.insert(Runtime.PersistentConnections, StatusBarInputChanged)
table.insert(Runtime.PersistentConnections, StatusBarInputEnded)
table.insert(Runtime.PersistentConnections, StatusBarCameraConnection)
table.insert(Runtime.PersistentConnections, FPSConnection)
Runtime.Shutdown = function()
    StatusBarDragging = false
    if StatusBarViewportConnection then
        StatusBarViewportConnection:Disconnect()
        StatusBarViewportConnection = nil
    end
end

-- MAIN WINDOW
local Main = Create("Frame", {
    Name = "Main",
    Parent = ScreenGui,
    Size = UDim2.fromOffset(UIConfig.Width, UIConfig.Height),
    Position = UDim2.new(0.5, -UIConfig.Width / 2, 0.5, -UIConfig.Height / 2),
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0,
    ClipsDescendants = true
})
local MainCorner = AddCorner(Main, 12)
AddStroke(Main, Theme.Border, 1)
local UIScale = Create("UIScale", {
    Parent = Main,
    Scale = 1
})
-- TOP BAR
local TopBar = Create("Frame", {
    Name = "TopBar",
    Parent = Main,
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0
})
AddCorner(TopBar, 12)
local Title = Create("TextLabel", {
    Name = "Title",
    Parent = TopBar,
    Position = UDim2.fromOffset(14, 0),
    Size = UDim2.new(1, -56, 1, 0),
    BackgroundTransparency = 1,
    Text = '<font color="#' .. Theme.Accent:ToHex() .. '">Moldy</font>Hub <font face="Gotham" size="9" color="#' .. Theme.Accent:ToHex() .. '">' .. (string.match(testver, "[%d%.]+") and ("v" .. string.match(testver, "[%d%.]+")) or testver) .. '</font>',
    RichText = true,
    TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center
})
-- Close
local CloseButton = Create("TextButton", {
    Name = "Close",
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
AddCorner(CloseButton, 8)
AddStroke(CloseButton, Theme.Border, 1)
-- HORIZONTAL NAVIGATION
local NavigationBar = Create("Frame", {
    Name = "NavigationBar",
    Parent = Main,
    Position = UDim2.fromOffset(0, 40),
    Size = UDim2.new(1, 0, 0, 32),
    BackgroundColor3 = Theme.Sidebar,
    BorderSizePixel = 0
})
local NavigationContainer = Create("ScrollingFrame", {
    Name = "NavigationButtons",
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
    Parent = NavigationContainer,
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 3),
    SortOrder = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Center
})
-- CONTENT AREA
local Content = Create("Frame", {
    Name = "Content",
    Parent = Main,
    Position = UDim2.fromOffset(0, 72),
    Size = UDim2.new(1, 0, 1, -84),
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0
})
-- PAGE SYSTEM
local Pages = {}
local SidebarButtons = {}
local CurrentPage = 1
-- DEBUG CONSOLE
local DebugConsoleList
local DebugConsoleLayout
local DebugLogCount = 0
local MaxDebugLogs = 100
local function AddDebugLog(message)
    local timestamp = os.date("%H:%M:%S")
    local lineText = "[" .. timestamp .. "] " .. tostring(message)
    if not DebugConsoleList or not DebugConsoleLayout then
        return
    end
    DebugLogCount += 1
    Create("TextLabel", {
        Name = "Log_" .. DebugLogCount,
        Parent = DebugConsoleList,
        Size = UDim2.new(1, -8, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = lineText,
        TextColor3 = Theme.Text,
        Font = Enum.Font.Code,
        TextSize = 9,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        LayoutOrder = DebugLogCount
    })
    local logs = {}
    for _, child in ipairs(DebugConsoleList:GetChildren()) do
        if child:IsA("TextLabel") then
            table.insert(logs, child)
        end
    end
    while #logs > MaxDebugLogs do
        logs[1]:Destroy()
        table.remove(logs, 1)
    end
    task.defer(function()
        if DebugConsoleList and DebugConsoleLayout then
            DebugConsoleList.CanvasSize = UDim2.new(0, 0, 0, DebugConsoleLayout.AbsoluteContentSize.Y + 8)
            DebugConsoleList.CanvasPosition = Vector2.new(0, math.max(0, DebugConsoleLayout.AbsoluteContentSize.Y - DebugConsoleList.AbsoluteSize.Y))
        end
    end)
end
-- CREATE PAGE
local PageColumnMap = {}
local function CreatePage(pageNumber, pageName)
    local PageClip = Create("Frame", {
        Name = "PageClip_" .. pageNumber,
        Parent = Content,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false
    })
    AddCorner(PageClip, 10)
    local function AddCornerMask(name, position, anchorPoint)
        local mask = Create("Frame", {
            Name = name,
            Parent = PageClip,
            AnchorPoint = anchorPoint,
            Position = position,
            Size = UDim2.fromOffset(10, 10),
            BackgroundColor3 = Theme.Background,
            BorderSizePixel = 0,
            ZIndex = 50
        })
        AddCorner(mask, 10)
    end
    AddCornerMask("TopLeftCornerMask", UDim2.fromOffset(0, 0), Vector2.new(0, 0))
    AddCornerMask("TopRightCornerMask", UDim2.new(1, 0, 0, 0), Vector2.new(1, 0))
    AddCornerMask("BottomLeftCornerMask", UDim2.new(0, 0, 1, 0), Vector2.new(0, 1))
    AddCornerMask("BottomRightCornerMask", UDim2.new(1, 0, 1, 0), Vector2.new(1, 1))
    local Page = Create("ScrollingFrame", {
        Name = "Page_" .. pageNumber,
        Parent = PageClip,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Gray,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = true,
        ClipsDescendants = true
    })
    -- Page children are positioned explicitly; avoid UIPadding adding
    -- a second, inconsistent inset to manually positioned feature rows.
    local LeftColumn = Create("Frame", {
        Name = "LeftColumn",
        Parent = Page,
        Position = UDim2.fromOffset(10, 10),
        Size = UDim2.new(0.5, -15, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    })
    local RightColumn = Create("Frame", {
        Name = "RightColumn",
        Parent = Page,
        Position = UDim2.new(0.5, 5, 0, 10),
        Size = UDim2.new(0.5, -15, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    })
    local LeftLayout = Create("UIListLayout", {
        Parent = LeftColumn,
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    local RightLayout = Create("UIListLayout", {
        Parent = RightColumn,
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    PageColumnMap[Page] = {
        Left = LeftColumn,
        Right = RightColumn,
        LeftLayout = LeftLayout,
        RightLayout = RightLayout
    }
    local function UpdateCanvas()
        -- Include both auto-column cards and manually positioned feature rows.
        local contentBottom = 0
        for _, child in ipairs(Page:GetChildren()) do
            if child:IsA("GuiObject") then
                local childBottom =
                    child.Position.Y.Scale * Page.AbsoluteSize.Y
                    + child.Position.Y.Offset
                    + child.AbsoluteSize.Y
                contentBottom = math.max(contentBottom, childBottom)
            end
        end
        -- Children already include the 10px top/side inset; reserve 10px below.
        Page.CanvasSize = UDim2.new(0, 0, 0, contentBottom + 10)
    end
    local function TrackCanvasChild(child)
        if not child:IsA("GuiObject") then return end
        child:GetPropertyChangedSignal("Position"):Connect(function()
            task.defer(UpdateCanvas)
        end)
        child:GetPropertyChangedSignal("Size"):Connect(function()
            task.defer(UpdateCanvas)
        end)
        child:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            task.defer(UpdateCanvas)
        end)
        task.defer(UpdateCanvas)
    end
    for _, child in ipairs(Page:GetChildren()) do
        TrackCanvasChild(child)
    end
    Page.ChildAdded:Connect(TrackCanvasChild)
    Page:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        task.defer(UpdateCanvas)
    end)
    LeftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)
    RightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)
    task.defer(UpdateCanvas)
    Pages[pageNumber] = PageClip
    return Page
end
-- CARD
local function CreateCard(parent, title, description)
    local columns = PageColumnMap and PageColumnMap[parent]
    local targetParent = parent
    if columns then
        targetParent = columns.LeftLayout.AbsoluteContentSize.Y <= columns.RightLayout.AbsoluteContentSize.Y
            and columns.Left or columns.Right
    end
    local Card = Create("Frame", {
        Name = title:gsub("%s+", ""),
        Parent = targetParent,
        Size = UDim2.new(1, 0, 0, 110),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0
    })
    AddCorner(Card, 8)
    AddStroke(Card, Theme.Border, 1)
    Create("TextLabel", {
        Parent = Card,
        Position = UDim2.fromOffset(11, 8),
        Size = UDim2.new(1, -22, 0, 18),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    Create("TextLabel", {
        Parent = Card,
        Position = UDim2.fromOffset(11, 29),
        Size = UDim2.new(1, -22, 0, 30),
        BackgroundTransparency = 1,
        Text = description or "",
        Visible = description ~= nil and description ~= "",
        TextColor3 = Theme.Gray,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top
    })
    return Card
end
-- DISABLED CARD OVERLAY
local function MarkUnderDevelopment(Card)
    local Overlay = Create("Frame", {
        Name = "UnderDevelopmentOverlay",
        Parent = Card,
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        BackgroundColor3 = Theme.Card,
        BackgroundTransparency = 0.18,
        BorderSizePixel = 0,
        Active = true,
        ZIndex = 20
    })
    AddCorner(Overlay, 8)
    Create("Frame", {
        Name = "UnderDevelopmentLine",
        Parent = Overlay,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Gray,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        ZIndex = 21
    })
    Create("TextLabel", {
        Name = "UnderDevelopmentLabel",
        Parent = Overlay,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(0.72, 0, 0, 20),
        BackgroundColor3 = Theme.Card,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Text = "UNDER DEVELOPMENT",
        TextColor3 = Theme.Gray,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 22
    })
end
-- BUTTON
local function CreateButton(parent, text, callback)
    local Button = Create("TextButton", {
        Parent = parent,
        Size = UDim2.new(1, -22, 0, 28),
        Position = UDim2.fromOffset(11, 68),
        BackgroundColor3 = Theme.Selected,
        Text = text,
        TextColor3 = Theme.SelectedText,
        Font = Enum.Font.GothamMedium,
        TextSize = 9,
        BorderSizePixel = 0,
        AutoButtonColor = false
    })
    AddCorner(Button, 6)
    Button.MouseEnter:Connect(function()
        Tween(Button, {
            BackgroundColor3 = Theme.Selected
        })
    end)
    Button.MouseLeave:Connect(function()
        Tween(Button, {
            BackgroundColor3 = Theme.Selected
        })
    end)
    Button.MouseButton1Click:Connect(function()
        if callback then
            callback()
        end
    end)
    return Button
end
-- TOGGLE
local ToggleControllers = setmetatable({}, {__mode = "k"})
local ConfigToggleControllers = {}
local function GetConfigToggleKey(parent, text)
    local parentName = parent and parent.Name or "Toggle"
    local cleanParent = tostring(parentName):gsub("[^%w_%-]", "")
    local cleanText = tostring(text or ""):gsub("[^%w_%-]", "")
    return cleanParent .. (cleanText ~= "" and ("_" .. cleanText) or "_Main")
end
local function CreateToggle(parent, text, default, callback)
    local Compact = text ~= ""
    local Toggle = Create("TextButton", {
        Parent = parent,
        Size = UDim2.new(1, -30, 0, Compact and 22 or 28),
        Position = UDim2.fromOffset(15, 68),
        BackgroundTransparency = 1,
        Text = "",
        BorderSizePixel = 0
    })
    local Label = Create("TextLabel", {
        Parent = Toggle,
        Size = UDim2.new(1, Compact and -42 or -55, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = Compact and 9 or 11,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    local Switch = Create("Frame", {
        Parent = Toggle,
        Position = UDim2.new(1, Compact and -34 or -45, 0.5, Compact and -7 or -9),
        Size = UDim2.fromOffset(Compact and 30 or 38, Compact and 14 or 18),
        BackgroundColor3 = Color3.fromRGB(49, 67, 82),
        BorderSizePixel = 0
    })
    AddCorner(Switch, 20)
    local Circle = Create("Frame", {
        Parent = Switch,
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.fromOffset(Compact and 10 or 14, Compact and 10 or 14),
        BackgroundColor3 = Color3.fromRGB(245, 250, 255),
        BorderSizePixel = 0
    })
    AddCorner(Circle, 20)
    local Enabled = default == true
    local function Update(runCallback)
        if Enabled then
            Tween(Switch, {
                BackgroundColor3 = Theme.Accent
            })
            Tween(Circle, {
                Position = Compact and UDim2.new(1, -12, 0, 2) or UDim2.new(1, -16, 0, 2)
            })
        else
            Tween(Switch, {
                BackgroundColor3 = Color3.fromRGB(49, 67, 82)
            })
            Tween(Circle, {
                Position = UDim2.fromOffset(2, 2)
            })
        end
        if runCallback ~= false and callback then
            callback(Enabled)
        end
    end
    ToggleControllers[Toggle] = {
        SetEnabled = function(value, runCallback)
            Enabled = value == true
            Update(runCallback)
        end,
        GetEnabled = function()
            return Enabled
        end
    }
    local configKey = GetConfigToggleKey(parent, text)
    ConfigToggleControllers[configKey] = ToggleControllers[Toggle]
    if type(SavedConfig.Toggles) == "table" and type(SavedConfig.Toggles[configKey]) == "boolean" then
        Enabled = SavedConfig.Toggles[configKey]
    end
    Toggle.MouseButton1Click:Connect(function()
        Enabled = not Enabled
        Update(true)
    end)
    Update(true)
    return Toggle
end
-- DROPDOWN
local function CreateDropdown(parent, text, options, callback)
    local Dropdown = Create("TextButton", {
        Parent = parent,
        Size = UDim2.new(1, -30, 0, 28),
        Position = UDim2.fromOffset(15, 68),
        BackgroundColor3 = Theme.SurfaceInput,
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
        ZIndex = 100
    })
    AddCorner(Dropdown, 6)
    AddStroke(Dropdown, Theme.Border, 1)
    local Current = Create("TextLabel", {
        Parent = Dropdown,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -35, 1, 0),
        BackgroundTransparency = 1,
        Text = text .. ": " .. tostring(options[1]),
        TextColor3 = Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 101
    })
    Create("TextLabel", {
        Parent = Dropdown,
        Position = UDim2.new(1, -25, 0, 0),
        Size = UDim2.fromOffset(20, 28),
        BackgroundTransparency = 1,
        Text = "v",
        TextColor3 = Theme.Gray,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        ZIndex = 101
    })
    local Open = false
    local List = Create("Frame", {
        Parent = Dropdown,
        Position = UDim2.new(0, 0, 1, 5),
        Size = UDim2.new(1, 0, 0, #options * 26),
        BackgroundColor3 = Theme.SurfaceInput,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 200
    })
    AddCorner(List, 6)
    AddStroke(List, Theme.Border, 1)
    local Layout = Create("UIListLayout", {
        Parent = List,
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    for _, option in ipairs(options) do
        local Option = Create("TextButton", {
            Parent = List,
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = 1,
            Text = tostring(option),
            TextColor3 = Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            BorderSizePixel = 0,
            ZIndex = 201
        })
        Option.MouseButton1Click:Connect(function()
            Current.Text = text .. ": " .. tostring(option)
            List.Visible = false
            Open = false
            if callback then
                callback(option)
            end
        end)
    end
    Dropdown.MouseButton1Click:Connect(function()
        Open = not Open
        List.Visible = Open
    end)
    return Dropdown
end
-- SLIDER
local function CreateSlider(parent, text, minimum, maximum, default, callback)
    local Holder = Create("Frame", {
        Parent = parent,
        Size = UDim2.new(1, -22, 0, 55),
        Position = UDim2.fromOffset(11, 68),
        BackgroundTransparency = 1
    })
    local Label = Create("TextLabel", {
        Parent = Holder,
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    local Value = Create("TextLabel", {
        Parent = Holder,
        Position = UDim2.new(1, -50, 0, 0),
        Size = UDim2.fromOffset(50, 20),
        BackgroundTransparency = 1,
        Text = tostring(default),
        TextColor3 = Theme.Gray,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Right
    })
    local Bar = Create("Frame", {
        Parent = Holder,
        Position = UDim2.fromOffset(0, 28),
        Size = UDim2.new(1, 0, 0, 5),
        BackgroundColor3 = Theme.LightGray,
        BorderSizePixel = 0
    })
    AddCorner(Bar, 10)
    local Fill = Create("Frame", {
        Parent = Bar,
        Size = UDim2.new(
            (default - minimum) / (maximum - minimum),
            0,
            1,
            0
        ),
        BackgroundColor3 = Theme.Selected,
        BorderSizePixel = 0
    })
    AddCorner(Fill, 10)
    local Dragging = false
    local function Update(input)
        local Position = math.clamp(
            (input.Position.X - Bar.AbsolutePosition.X)
                / Bar.AbsoluteSize.X,
            0,
            1
        )
        local Number = math.floor(
            minimum + ((maximum - minimum) * Position)
        )
        Fill.Size = UDim2.new(Position, 0, 1, 0)
        Value.Text = tostring(Number)
        if callback then
            callback(Number)
        end
    end
    Bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            Update(input)
        end
    end)
    TrackPersistentConnection(UserInputService.InputChanged:Connect(function(input)
        if Dragging then
            if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
                Update(input)
            end
        end
    end))
    TrackPersistentConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = false
        end
    end))
    return Holder
end
-- CREATE HORIZONTAL NAVIGATION BUTTONS
for index, name in ipairs(UIConfig.SidebarNames) do
    local Button = Create("TextButton", {
        Name = "NavigationButton_" .. index,
        Parent = NavigationContainer,
        Size = UDim2.fromOffset(math.max(48, (#name * 5) + 14), 28),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Theme.DarkGray,
        Font = Enum.Font.GothamMedium,
        TextSize = 9,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Center,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        LayoutOrder = index
    })
    local ActiveLine = Create("Frame", {
        Name = "ActiveLine",
        Parent = Button,
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -1),
        Size = UDim2.new(0.62, 0, 0, 2),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Visible = index == 1
    })
    AddCorner(ActiveLine, 1)
    SidebarButtons[index] = Button
    Button.MouseButton1Click:Connect(function()
        for pageIndex, page in pairs(Pages) do
            page.Visible = pageIndex == index
        end
        for buttonIndex, navigationButton in pairs(SidebarButtons) do
            local active = buttonIndex == index
            navigationButton.TextColor3 = active and Theme.Text or Theme.DarkGray
            local line = navigationButton:FindFirstChild("ActiveLine")
            if line then line.Visible = active end
        end
        CurrentPage = index
    end)
end
local ShutdownAutomation
local CancelActiveAutomation
local TouchAutomationProgress
local AntiPaloEnabled = false