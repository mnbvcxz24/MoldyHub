-- REUSABLE UI TEMPLATE
-- SERVICES
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local RuntimeEnv = type(getgenv) == "function" and getgenv() or _G
local testver = "v1.1"
local PreviousRuntimeCleanup = RuntimeEnv.__StealAPetAndRideItCleanup
if type(PreviousRuntimeCleanup) == "function" then
    pcall(PreviousRuntimeCleanup)
end
local Runtime = {
    Stopped = false,
    Connections = {}
}
local function TrackConnection(connection)
    table.insert(Runtime.Connections, connection)
    return connection
end
RuntimeEnv.__StealAPetAndRideItCleanup = function()
    Runtime.Stopped = true

    if Runtime.StopNavigation then
        pcall(Runtime.StopNavigation)
    end

    for _, connection in ipairs(Runtime.Connections) do
        if connection.Connected then
            connection:Disconnect()
        end
    end
    table.clear(Runtime.Connections)

    pcall(function()
        local oldUI = game.CoreGui:FindFirstChild("StealAPetAndRideItUI")
        if oldUI then oldUI:Destroy() end
    end)
end
-- UI CONFIGURATION
local UIConfig = {
    Title = "STEAL A PET & RIDE IT",
    Subtitle = "v1.1",
    Width = 480,
    Height = 320,
    SidebarWidth = 108,
    SidebarNames = {
        "Main",
        "Features",
        "Misc. feature",
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
    local oldUI = game.CoreGui:FindFirstChild("StealAPetAndRideItUI")
    if oldUI then oldUI:Destroy() end
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
Theme = ThemePresets["Midnight Blue + Cyan"]
local ActiveThemeName = "Midnight Blue + Cyan"
-- SCREEN GUI
local ScreenGui = Create("ScreenGui", {
    Name = "StealAPetAndRideItUI",
    Parent = game.CoreGui,
    ResetOnSpawn = false,
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
        titleLabel.Text = '<font color="#' .. selectedTheme.Accent:ToHex() .. '">STEAL</font> A PET AND RIDE IT'
    end
end
-- MAIN WINDOW
local Main = Create("Frame", {
    Name = "Main",
    Parent = ScreenGui,
    Size = UDim2.fromOffset(
        UIConfig.Width,
        UIConfig.Height
    ),
    Position = UDim2.new(
        0.5,
        -UIConfig.Width / 2,
        0.5,
        -UIConfig.Height / 2
    ),
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0,
    ClipsDescendants = true
})
local MainCorner = AddCorner(Main, 12)
AddStroke(Main, Theme.Border, 1)
-- TOP BAR
local TopBar = Create("Frame", {
    Name = "TopBar",
    Parent = Main,
    Size = UDim2.new(1, 0, 0, 48),
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0
})
AddCorner(TopBar, 12)
Create("Frame", {
    Name = "TopBarCornerCover",
    Parent = TopBar,
    Position = UDim2.fromOffset(0, 12),
    Size = UDim2.new(1, 0, 1, -12),
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0,
    ZIndex = 0
})
-- Title
local Title = Create("TextLabel", {
    Name = "Title",
    Parent = TopBar,
    Position = UDim2.fromOffset(14, 5),
    Size = UDim2.fromOffset(330, 22),
    BackgroundTransparency = 1,
    Text = '<font color="#' .. Theme.Accent:ToHex() .. '">STEAL</font> A PET AND RIDE IT',
    RichText = true,
    TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left
})
-- Subtitle
local Subtitle = Create("TextLabel", {
    Name = "Subtitle",
    Parent = TopBar,
    Position = UDim2.fromOffset(14, 27),
    Size = UDim2.fromOffset(170, 16),
    BackgroundTransparency = 1,
    Text = UIConfig.Subtitle,
    TextColor3 = Theme.Gray,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left
})
-- Search
local SearchBox = Create("TextBox", {
    Name = "Search",
    Parent = TopBar,
    Position = UDim2.fromOffset(10, 36),
    Size = UDim2.fromOffset(80, 18),
    BackgroundColor3 = Theme.SurfaceInput,
    PlaceholderText = "Search...",
    PlaceholderColor3 = Theme.Gray,
    Visible = false,
    Text = "",
    TextColor3 = Theme.Text,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    ClearTextOnFocus = false,
    BorderSizePixel = 0
})
AddCorner(SearchBox, 8)
AddStroke(SearchBox, Theme.Border, 1)
-- Minimize
local MinimizeButton = Create("TextButton", {
    Name = "Minimize",
    Parent = TopBar,
    Position = UDim2.new(1, -52, 0, 16),
    Size = UDim2.fromOffset(22, 26),
    BackgroundColor3 = Theme.SurfaceInput,
    Text = "-",
    TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    BorderSizePixel = 0
})
AddCorner(MinimizeButton, 8)
AddStroke(MinimizeButton, Theme.Border, 1)
-- Close
local CloseButton = Create("TextButton", {
    Name = "Close",
    Parent = TopBar,
    Position = UDim2.new(1, -27, 0, 16),
    Size = UDim2.fromOffset(22, 26),
    BackgroundColor3 = Theme.SurfaceInput,
    Text = "×",
    TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    BorderSizePixel = 0
})
AddCorner(CloseButton, 8)
AddStroke(CloseButton, Theme.Border, 1)
local RestoreButton = Create("TextButton", {
    Name = "Restore",
    Parent = Main,
    Position = UDim2.fromOffset(0, 0),
    Size = UDim2.fromOffset(36, 36),
    BackgroundColor3 = Theme.Sidebar,
    Text = "S",
    TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 5
})
AddCorner(RestoreButton, 18)
AddStroke(RestoreButton, Theme.Border, 1)
-- SIDEBAR
local Sidebar = Create("Frame", {
    Name = "Sidebar",
    Parent = Main,
    Position = UDim2.fromOffset(0, 48),
    Size = UDim2.new(
        0,
        UIConfig.SidebarWidth,
        1,
        -48
    ),
    BackgroundColor3 = Theme.Sidebar,
    BorderSizePixel = 0
})
AddCorner(Sidebar, 12)
-- Sidebar title
local NavigationTitle = Create("TextLabel", {
    Name = "NavigationTitle",
    Parent = Sidebar,
    Position = UDim2.fromOffset(8, 12),
    Size = UDim2.new(1, -16, 0, 20),
    BackgroundTransparency = 1,
    Text = "NAVIGATION",
    TextColor3 = Theme.Gray,
    Font = Enum.Font.GothamBold,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left
})
-- Sidebar container
local SidebarContainer = Create("ScrollingFrame", {
    Name = "Buttons",
    Parent = Sidebar,
    Position = UDim2.fromOffset(5, 40),
    Size = UDim2.new(1, -10, 1, -60),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = Theme.Gray,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ClipsDescendants = true
})
Create("UIListLayout", {
    Parent = SidebarContainer,
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder
})
-- CONTENT AREA
local Content = Create("Frame", {
    Name = "Content",
    Parent = Main,
    Position = UDim2.fromOffset(
        UIConfig.SidebarWidth,
        48
    ),
    Size = UDim2.new(
        1,
        -UIConfig.SidebarWidth - 12,
        1,
        -60
    ),
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
    local Padding = Create("UIPadding", {
        Parent = Page,
        PaddingTop = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12)
    })
    local Layout = Create("UIListLayout", {
        Parent = Page,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Page.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 24)
    end)
    Pages[pageNumber] = PageClip
    return Page
end
-- CARD
local function CreateCard(parent, title, description)
    local Card = Create("Frame", {
        Name = title:gsub("%s+", ""),
        Parent = parent,
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
    Toggle.MouseButton1Click:Connect(function()
        Enabled = not Enabled
        Update(true)
    end)
    Update(false)
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
        local width = Bar.AbsoluteSize.X
        if width <= 0 then return end
        local Position = math.clamp(
            (input.Position.X - Bar.AbsolutePosition.X) / width,
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
    TrackConnection(UserInputService.InputChanged:Connect(function(input)
        if Dragging then
            if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
                Update(input)
            end
        end
end))
    TrackConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = false
        end
end))
    return Holder
end
-- CREATE SIDEBAR BUTTONS
for index, name in ipairs(UIConfig.SidebarNames) do
    local Button = Create("TextButton", {
        Name = "SidebarButton_" .. index,
        Parent = SidebarContainer,
        Size = UDim2.new(1, -2, 0, 34),
        BackgroundColor3 = Theme.Sidebar,
        Text = name,
        TextColor3 = Theme.DarkGray,
        Font = Enum.Font.GothamMedium,
        TextSize = 9,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        LayoutOrder = index
    })
    AddCorner(Button, 7)
    Button.BackgroundTransparency = 1
    local ActiveLine = Create("Frame", {Name = "ActiveLine", Parent = Button, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -2, 0.5, 0), Size = UDim2.fromOffset(2, 18), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Visible = index == 1})
    AddCorner(ActiveLine, 1)
    local Padding = Create("UIPadding", {
        Parent = Button,
        PaddingLeft = UDim.new(0, 10)
    })
    SidebarButtons[index] = Button
    Button.MouseButton1Click:Connect(function()
        for pageIndex, page in pairs(Pages) do
            page.Visible = pageIndex == index
        end
        for buttonIndex, sidebarButton in pairs(SidebarButtons) do
            local active = buttonIndex == index
            sidebarButton.BackgroundTransparency = 1
            sidebarButton.TextColor3 = active and Theme.Text or Theme.DarkGray
            local line = sidebarButton:FindFirstChild("ActiveLine")
            if line then line.Visible = active end
        end
        CurrentPage = index
    end)
end

-- CREATE TEMPLATE PAGES
local PagesByName = {}
for index, name in ipairs(UIConfig.SidebarNames) do
    local Page = CreatePage(index, name)
    PagesByName[name] = Page
    if name == "Main" then
        local AutoCard = CreateCard(Page, "Auto Steal", "")
        AutoCard.Size = UDim2.new(0.5, -4, 0, 0)
        AutoCard.AutomaticSize = Enum.AutomaticSize.Y

        local HeaderTitle = AutoCard:FindFirstChildWhichIsA("TextLabel")
        if HeaderTitle then
            HeaderTitle.Position = UDim2.fromOffset(15, 10)
            HeaderTitle.Size = UDim2.new(1, -70, 0, 22)
            HeaderTitle.TextSize = 13
        end

        local SelectedPaths = {}
        local SelectedCages = {}
        local MovementMode = "Glide"
        local AutoStealEnabled = false
        local StatusValue
        local StatusDot

        local AutoStealToggle = CreateToggle(AutoCard, "", false, function(enabled)
            AutoStealEnabled = enabled
            Runtime.AutoStealEnabled = enabled
            if StatusValue then
                StatusValue.Text = enabled and "Navigating" or "Disabled"
                StatusValue.TextColor3 = enabled and Theme.Accent or Theme.Gray
            end
            if StatusDot then
                StatusDot.BackgroundColor3 = enabled and Color3.fromRGB(75, 190, 145) or Theme.Gray
            end
            if enabled and Runtime.StartNavigation then
                task.spawn(Runtime.StartNavigation)
            elseif not enabled and Runtime.StopNavigation then
                Runtime.StopNavigation()
            end
        end)
        AutoStealToggle.Position = UDim2.new(1, -55, 0, 9)
        AutoStealToggle.Size = UDim2.fromOffset(40, 24)

        local StatusRow = Create("Frame", {
            Parent = AutoCard,
            Position = UDim2.fromOffset(15, 42),
            Size = UDim2.new(1, -30, 0, 27),
            BackgroundTransparency = 1
        })
        StatusDot = Create("Frame", {
            Parent = StatusRow,
            Position = UDim2.fromOffset(2, 9),
            Size = UDim2.fromOffset(7, 7),
            BackgroundColor3 = Color3.fromRGB(75, 190, 145),
            BorderSizePixel = 0
        })
        AddCorner(StatusDot, 8)
        local StatusLabel = Create("TextLabel", {
            Parent = StatusRow,
            Position = UDim2.fromOffset(18, 0),
            Size = UDim2.new(0.5, -18, 1, 0),
            BackgroundTransparency = 1,
            Text = "Status",
            TextColor3 = Theme.DarkGray,
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        StatusValue = Create("TextLabel", {
            Parent = StatusRow,
            Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.new(0.5, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "Disabled",
            TextColor3 = Theme.Gray,
            Font = Enum.Font.GothamMedium,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Right
        })
        local StatusDivider = Create("Frame", {
            Parent = AutoCard,
            Position = UDim2.fromOffset(15, 73),
            Size = UDim2.new(1, -30, 0, 1),
            BackgroundColor3 = Theme.Border,
            BorderSizePixel = 0
        })

        local function MakeSectionLabel(icon, label, yPosition)
            local Icon = Create("TextLabel", {
                Parent = AutoCard,
                Position = UDim2.fromOffset(15, yPosition + 1),
                Size = UDim2.fromOffset(18, 18),
                BackgroundColor3 = Theme.LightGray,
                Text = icon,
                TextColor3 = Theme.Accent,
                Font = Enum.Font.GothamBold,
                TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Center
            })
            AddCorner(Icon, 5)
            local Label = Create("TextLabel", {
                Parent = AutoCard,
                Position = UDim2.fromOffset(38, yPosition),
                Size = UDim2.new(1, -53, 0, 22),
                BackgroundTransparency = 1,
                Text = label,
                TextColor3 = Theme.DarkGray,
                Font = Enum.Font.GothamMedium,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            return Label, Icon
        end

        local function GetPathFolders()
            local pathsFolder = workspace:FindFirstChild("Paths")
            local results = {}
            if pathsFolder then
                for _, child in ipairs(pathsFolder:GetChildren()) do
                    if child:IsA("Folder") then
                        table.insert(results, child)
                    end
                end
            end
            table.sort(results, function(a, b) return a.Name < b.Name end)
            return results
        end

        local function GetCageModels()
            local results = {}
            local seenInstances = {}
            local paths = {}
            for pathObject in pairs(SelectedPaths) do
                if pathObject and pathObject.Parent then
                    table.insert(paths, pathObject)
                end
            end
            if #paths == 0 then
                return results
            end
            for _, pathObject in ipairs(paths) do
                local cagesFolder = pathObject:FindFirstChild("Cages")
                if cagesFolder then
                    for _, child in ipairs(cagesFolder:GetChildren()) do
                        if child:IsA("Model") and not seenInstances[child] then
                            seenInstances[child] = true
                            table.insert(results, child)
                        end
                    end
                end
            end
            table.sort(results, function(a, b)
                local ap = a.Parent and a.Parent.Parent and a.Parent.Parent.Name or ""
                local bp = b.Parent and b.Parent.Parent and b.Parent.Parent.Name or ""
                return ap .. "/" .. a.Name < bp .. "/" .. b.Name
            end)
            return results
        end

        local function CreateDynamicFilter(label, icon, yPosition, getOptions, selected, onChanged)
            local SectionLabel, SectionIcon = MakeSectionLabel(icon, label, yPosition)
            local Button = Create("TextButton", {
                Parent = AutoCard,
                Position = UDim2.fromOffset(15, yPosition + 21),
                Size = UDim2.new(1, -30, 0, 27),
                BackgroundColor3 = Theme.SurfaceInput,
                Text = "",
                BorderSizePixel = 0,
                AutoButtonColor = false,
                ZIndex = 20
            })
            AddCorner(Button, 7)
            AddStroke(Button, Theme.Border, 1)
            local ButtonText = Create("TextLabel", {
                Parent = Button,
                Position = UDim2.fromOffset(10, 0),
                Size = UDim2.new(1, -35, 1, 0),
                BackgroundTransparency = 1,
                Text = "Select " .. label:lower() .. "...",
                TextColor3 = Theme.Gray,
                Font = Enum.Font.Gotham,
                TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 21
            })
            local Chevron = Create("TextLabel", {
                Parent = Button,
                Position = UDim2.new(1, -25, 0, 0),
                Size = UDim2.fromOffset(18, 27),
                BackgroundTransparency = 1,
                Text = "v",
                TextColor3 = Theme.Accent,
                Font = Enum.Font.GothamBold,
                TextSize = 10,
                ZIndex = 21
            })
            local List = Create("ScrollingFrame", {
                Parent = Button,
                Position = UDim2.new(0, 0, 1, 4),
                Size = UDim2.new(1, 0, 0, 112),
                BackgroundColor3 = Theme.Card,
                BorderSizePixel = 0,
                ScrollBarThickness = 3,
                ScrollBarImageColor3 = Theme.Accent,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                Visible = false,
                ZIndex = 100
            })
            AddCorner(List, 7)
            AddStroke(List, Theme.Border, 1)
            Create("UIPadding", {
                Parent = List,
                PaddingTop = UDim.new(0, 4),
                PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 4),
                PaddingRight = UDim.new(0, 4)
            })
            Create("UIListLayout", {
                Parent = List,
                Padding = UDim.new(0, 3),
                SortOrder = Enum.SortOrder.LayoutOrder
            })
            local function Refresh()
                local count = 0
                for _ in pairs(selected) do count += 1 end
                ButtonText.Text = count > 0 and (label .. " - " .. count .. " selected") or ("Select " .. label:lower() .. "...")
                ButtonText.TextColor3 = count > 0 and Theme.Text or Theme.Gray
            end
            local function Rebuild()
                for _, child in ipairs(List:GetChildren()) do
                    if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
                end
                local options = getOptions()
                if label == "Cage Filter" and next(SelectedPaths) == nil then
                    Create("TextLabel", {
                        Parent = List,
                        Size = UDim2.new(1, -8, 0, 30),
                        BackgroundTransparency = 1,
                        Text = "Select a path first",
                        TextColor3 = Theme.Gray,
                        Font = Enum.Font.GothamMedium,
                        TextSize = 9,
                        ZIndex = 101
                    })
                elseif #options == 0 then
                    Create("TextLabel", {
                        Parent = List,
                        Size = UDim2.new(1, -8, 0, 30),
                        BackgroundTransparency = 1,
                        Text = "No " .. label:lower() .. " found",
                        TextColor3 = Theme.Gray,
                        Font = Enum.Font.Gotham,
                        TextSize = 9,
                        ZIndex = 101
                    })
                end
                for index, option in ipairs(options) do
                    local optionObject = option
                    local isSelected = selected[optionObject] == true
                    local OptionButton = Create("TextButton", {
                        Name = "Option_" .. index,
                        Parent = List,
                        Size = UDim2.new(1, -2, 0, 27),
                        BackgroundColor3 = isSelected and Theme.Selected or Theme.SurfaceInput,
                        Text = "",
                        BorderSizePixel = 0,
                        AutoButtonColor = false,
                        ZIndex = 101
                    })
                    AddCorner(OptionButton, 5)
                    local Check = Create("Frame", {
                        Parent = OptionButton,
                        Position = UDim2.fromOffset(8, 7),
                        Size = UDim2.fromOffset(13, 13),
                        BackgroundColor3 = isSelected and Theme.Accent or Theme.LightGray,
                        BorderSizePixel = 0,
                        ZIndex = 102
                    })
                    AddCorner(Check, 4)
                    if isSelected then
                        Create("Frame", {
                            Parent = Check,
                            Position = UDim2.fromOffset(4, 4),
                            Size = UDim2.fromOffset(5, 5),
                            BackgroundColor3 = Theme.AccentText,
                            BorderSizePixel = 0,
                            ZIndex = 103
                        })
                    end
                    Create("TextLabel", {
                        Parent = OptionButton,
                        Position = UDim2.fromOffset(29, 0),
                        Size = UDim2.new(1, -36, 1, 0),
                        BackgroundTransparency = 1,
                        Text = optionObject.Name,
                        TextColor3 = isSelected and Theme.Text or Theme.DarkGray,
                        Font = Enum.Font.Gotham,
                        TextSize = 9,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 102
                    })
                    OptionButton.MouseButton1Click:Connect(function()
                        selected[optionObject] = not selected[optionObject] and true or nil
                        if onChanged then onChanged() end
                        Rebuild()
                        Refresh()
                    end)
                end
            end
            Button.MouseButton1Click:Connect(function()
                local opening = not List.Visible
                if opening then Rebuild() end
                List.Visible = opening
                Chevron.Text = opening and "^" or "v"
            end)
            Refresh()
            return Button, List, SectionLabel, SectionIcon
        end

        local CageFilterButton, CageFilterList, CageSectionLabel, CageSectionIcon
        CreateDynamicFilter("Path Filter", "P", 82, GetPathFolders, SelectedPaths, function()
            table.clear(SelectedCages)
            local availableCages = GetCageModels()
            for _, cage in ipairs(availableCages) do
                SelectedCages[cage] = true
            end
            if CageFilterList then
                CageFilterList.Visible = false
                local buttonText = CageFilterButton:FindFirstChildWhichIsA("TextLabel")
                if buttonText then
                    buttonText.Text = #availableCages > 0
                        and ("Cage Filter - " .. #availableCages .. " selected")
                        or "Select cage filter..."
                    buttonText.TextColor3 = #availableCages > 0 and Theme.Text or Theme.Gray
                end
            end
        end)
        CageFilterButton, CageFilterList, CageSectionLabel, CageSectionIcon =
            CreateDynamicFilter("Cage Filter", "C", 142, GetCageModels, SelectedCages)

        MakeSectionLabel("M", "Movement", 202)
        local MovementHolder = Create("Frame", {
            Parent = AutoCard,
            Position = UDim2.fromOffset(15, 223),
            Size = UDim2.new(1, -30, 0, 27),
            BackgroundColor3 = Theme.SurfaceInput,
            BorderSizePixel = 0
        })
        AddCorner(MovementHolder, 7)
        AddStroke(MovementHolder, Theme.Border, 1)
        local MovementButtons = {}
        local function SetMovement(mode)
            MovementMode = mode
            Runtime.MovementMode = mode
            for name, button in pairs(MovementButtons) do
                local active = name == mode
                button.BackgroundColor3 = active and Theme.Accent or Theme.SurfaceInput
                button.TextColor3 = active and Theme.AccentText or Theme.DarkGray
            end
        end
        for _, mode in ipairs({"Glide", "Walk"}) do
            local Button = Create("TextButton", {
                Parent = MovementHolder,
                Size = UDim2.new(0.5, -2, 1, -4),
                Position = UDim2.new(mode == "Walk" and 0.5 or 0, 2, 0, 2),
                BackgroundColor3 = mode == "Glide" and Theme.Accent or Theme.SurfaceInput,
                Text = mode,
                TextColor3 = mode == "Glide" and Theme.AccentText or Theme.DarkGray,
                Font = Enum.Font.GothamMedium,
                TextSize = 10,
                BorderSizePixel = 0,
                AutoButtonColor = false
            })
            AddCorner(Button, 6)
            MovementButtons[mode] = Button
            Button.MouseButton1Click:Connect(function()
                SetMovement(mode)
            end)
        end
        Runtime.MovementMode = MovementMode

        MakeSectionLabel("S", "Glide Speed", 260)
        local SpeedHolder = Create("Frame", {
            Parent = AutoCard,
            Position = UDim2.fromOffset(15, 281),
            Size = UDim2.new(1, -30, 0, 54),
            BackgroundTransparency = 1
        })
        local SpeedValue = Create("TextLabel", {
            Parent = SpeedHolder,
            Position = UDim2.new(1, -78, 0, 0),
            Size = UDim2.fromOffset(78, 18),
            BackgroundTransparency = 1,
            Text = "50",
            TextColor3 = Theme.Text,
            Font = Enum.Font.GothamMedium,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Right
        })
        local SpeedBar = Create("Frame", {
            Parent = SpeedHolder,
            Position = UDim2.fromOffset(0, 25),
            Size = UDim2.new(1, 0, 0, 6),
            BackgroundColor3 = Theme.LightGray,
            BorderSizePixel = 0
        })
        AddCorner(SpeedBar, 8)
        local SpeedFill = Create("Frame", {
            Parent = SpeedBar,
            Size = UDim2.new(0.5, 0, 1, 0),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0
        })
        AddCorner(SpeedFill, 8)
        local SpeedThumb = Create("Frame", {
            Parent = SpeedBar,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.fromOffset(13, 13),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            ZIndex = 3
        })
        AddCorner(SpeedThumb, 10)
        AddStroke(SpeedThumb, Theme.Card, 1)
        local SpeedMinLabel = Create("TextLabel", {
            Parent = SpeedHolder,
            Position = UDim2.fromOffset(0, 39),
            Size = UDim2.fromOffset(35, 16),
            BackgroundTransparency = 1,
            Text = "10",
            TextColor3 = Theme.Gray,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        local SpeedMaxLabel = Create("TextLabel", {
            Parent = SpeedHolder,
            Position = UDim2.new(1, -35, 0, 39),
            Size = UDim2.fromOffset(35, 16),
            BackgroundTransparency = 1,
            Text = "100",
            TextColor3 = Theme.Gray,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Right
        })
        local GlideSpeed = 50
        local GlideMaxSpeed = 100
        local DraggingSpeed = false
        local function RefreshSpeed()
            local currentPosition = (GlideSpeed - 10) / (GlideMaxSpeed - 10)
            SpeedThumb.Position = UDim2.new(currentPosition, 0, 0.5, 0)
            SpeedFill.Size = UDim2.new(currentPosition, 0, 1, 0)
            SpeedValue.Text = tostring(GlideSpeed)
            SpeedMaxLabel.Text = tostring(GlideMaxSpeed)
            Runtime.GlideSpeed = GlideSpeed
            Runtime.GlideMaxSpeed = GlideMaxSpeed
        end
        local function UpdateSpeed(input)
            local width = SpeedBar.AbsoluteSize.X
            if width <= 0 then return end
            local position = math.clamp(
                (input.Position.X - SpeedBar.AbsolutePosition.X) / width,
                0,
                1
            )
            GlideSpeed = math.floor(10 + position * (GlideMaxSpeed - 10) + 0.5)
            RefreshSpeed()
        end
        local function BeginSpeedDrag(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
            DraggingSpeed = true
            UpdateSpeed(input)
        end
        SpeedBar.InputBegan:Connect(BeginSpeedDrag)
        SpeedThumb.InputBegan:Connect(BeginSpeedDrag)
        TrackConnection(UserInputService.InputChanged:Connect(function(input)
            if DraggingSpeed and (
                input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
            ) then
                UpdateSpeed(input)
            end
end))
        TrackConnection(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                DraggingSpeed = false
            end
end))
        RefreshSpeed()

        Runtime.SelectedPaths = SelectedPaths
        Runtime.SelectedCages = SelectedCages

        local navigationToken = 0
        local activeNavigationTween

        local function SetNavigationStatus(message)
            if StatusValue then
                StatusValue.Text = message
                StatusValue.TextColor3 = Theme.Accent
            end
        end

        local function SetAutoStealEnabled(enabled)
            AutoStealEnabled = enabled
            Runtime.AutoStealEnabled = enabled

            local controller = ToggleControllers[AutoStealToggle]
            if controller then
                controller.SetEnabled(enabled, false)
            end

            if StatusDot then
                StatusDot.BackgroundColor3 = enabled
                    and Color3.fromRGB(75, 190, 145)
                    or Theme.Gray
            end
        end

        local function CancelActiveMovement()
            if activeNavigationTween then
                activeNavigationTween:Cancel()
                activeNavigationTween = nil
            end

            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local root = character and character:FindFirstChild("HumanoidRootPart")

            if humanoid then
                if root then
                    humanoid:MoveTo(root.Position)
                end
                humanoid:Move(Vector3.zero, false)
            end
        end

        local function MoveToPosition(root, humanoid, destination, token)
            if token ~= navigationToken or Runtime.Stopped then
                return false
            end

            if MovementMode == "Walk" then
                local distance = (root.Position - destination).Magnitude
                local speed = math.max(humanoid.WalkSpeed, 1)
                local timeout = os.clock() + math.max(5, distance / speed + 3)

                humanoid:MoveTo(destination)

                while os.clock() < timeout do
                    if token ~= navigationToken or Runtime.Stopped then
                        humanoid:MoveTo(root.Position)
                        humanoid:Move(Vector3.zero, false)
                        return false
                    end

                    if not root.Parent or not humanoid.Parent then
                        return false
                    end

                    if (root.Position - destination).Magnitude <= 3 then
                        return true
                    end

                    RunService.Heartbeat:Wait()
                end

                humanoid:MoveTo(root.Position)
                humanoid:Move(Vector3.zero, false)
                return false
            end

            local glideHeight = humanoid.HipHeight + (root.Size.Y * 0.5)
            local glidePosition = destination + Vector3.new(0, glideHeight, 0)
            local distance = (root.Position - glidePosition).Magnitude
            local speed = math.max(10, Runtime.GlideSpeed or 50)
            local duration = math.max(0.15, distance / speed)
            local target = CFrame.new(glidePosition) * root.CFrame.Rotation
            local tween = TweenService:Create(
                root,
                TweenInfo.new(duration, Enum.EasingStyle.Linear),
                {CFrame = target}
            )

            activeNavigationTween = tween
            tween:Play()
            local state = tween.Completed:Wait()

            if activeNavigationTween == tween then
                activeNavigationTween = nil
            end

            return state == Enum.PlaybackState.Completed
                and token == navigationToken
                and not Runtime.Stopped
        end

        Runtime.StopNavigation = function()
            navigationToken += 1
            CancelActiveMovement()
            SetAutoStealEnabled(false)
            SetNavigationStatus("Stopped")
        end

        Runtime.StartNavigation = function()
            navigationToken += 1
            local token = navigationToken
            CancelActiveMovement()

            if Runtime.Stopped then
                SetAutoStealEnabled(false)
                return
            end

            if next(SelectedPaths) == nil then
                SetNavigationStatus("Select a path")
                SetAutoStealEnabled(false)
                return
            end

            local selectedCages = {}
            for cage, selected in pairs(SelectedCages) do
                if selected and cage and cage.Parent then
                    table.insert(selectedCages, cage)
                end
            end

            table.sort(selectedCages, function(a, b)
                local function getPath(model)
                    local names = {}
                    local current = model
                    while current and current ~= workspace do
                        table.insert(names, 1, current.Name)
                        current = current.Parent
                    end
                    return table.concat(names, "/")
                end
                return getPath(a) < getPath(b)
            end)

            local selectedCage = selectedCages[1]
            if not selectedCage then
                SetNavigationStatus("Select a cage")
                SetAutoStealEnabled(false)
                return
            end

            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local cageRoot = selectedCage:FindFirstChild("Root")
            local stealPrompt = cageRoot and cageRoot:FindFirstChild("StealPrompt")
            local hub = workspace:FindFirstChild("Hub")
            local safeSign = hub and hub:FindFirstChild("SafeZoneSign")

            if not humanoid or not root or not cageRoot
            or not cageRoot:IsA("BasePart")
            or not stealPrompt or not stealPrompt:IsA("ProximityPrompt")
            or not safeSign or not safeSign:IsA("BasePart") then
                SetNavigationStatus("Target unavailable")
                SetAutoStealEnabled(false)
                return
            end

            SetNavigationStatus("Moving to cage")
            local reachedCage = MoveToPosition(root, humanoid, cageRoot.Position, token)
            if not reachedCage then
                if token == navigationToken then
                    SetAutoStealEnabled(false)
                    SetNavigationStatus("Navigation stopped")
                end
                return
            end

            if token ~= navigationToken or Runtime.Stopped then return end

            local cageDistance = (root.Position - cageRoot.Position).Magnitude
            if cageDistance > 8 then
                SetAutoStealEnabled(false)
                SetNavigationStatus("Cage out of reach")
                return
            end

            SetNavigationStatus("Holding steal prompt")
            local holdStarted = false
            local holdCompleted = false
            local holdOk = pcall(function()
                stealPrompt:InputHoldBegin()
                holdStarted = true

                local holdUntil = os.clock() + 1
                while os.clock() < holdUntil do
                    if token ~= navigationToken or Runtime.Stopped then
                        break
                    end
                    task.wait(0.05)
                end

                holdCompleted = token == navigationToken and not Runtime.Stopped
            end)

            if holdStarted then
                pcall(function()
                    stealPrompt:InputHoldEnd()
                end)
            end

            if not holdOk or not holdCompleted then
                if token == navigationToken then
                    SetAutoStealEnabled(false)
                    SetNavigationStatus("Navigation stopped")
                end
                return
            end

            if token ~= navigationToken or Runtime.Stopped then return end

            SetNavigationStatus("Returning to safe zone")
            local reachedSafeZone = MoveToPosition(root, humanoid, safeSign.Position, token)
            if not reachedSafeZone then
                if token == navigationToken then
                    SetAutoStealEnabled(false)
                    SetNavigationStatus("Navigation stopped")
                end
                return
            end

            if token ~= navigationToken or Runtime.Stopped then return end

            local safeZoneDistance = (root.Position - safeSign.Position).Magnitude
            if safeZoneDistance > 8 then
                SetAutoStealEnabled(false)
                SetNavigationStatus("Safe zone not reached")
                return
            end

            if token == navigationToken and not Runtime.Stopped then
                SetNavigationStatus("Returned to safe zone")
                SetAutoStealEnabled(false)
            end
        end
        elseif name == "Features" then
        local ControlsCard = CreateCard(Page, "Feature Template", "Use this card as a starting point for new features.")
        CreateButton(ControlsCard, "Example Action", function()
        end)
        local OptionsCard = CreateCard(Page, "Options", "Example dropdown and slider controls.")
        CreateDropdown(OptionsCard, "Mode", {"Option 1", "Option 2", "Option 3"}, function(selection)
        end)
        CreateSlider(OptionsCard, "Example Slider", 0, 100, 50, function(value)
        end)
    elseif name == "Misc. feature" then
        CreateCard(Page, "Miscellaneous", "Empty content area for future game-specific features.")
    elseif name == "Settings" then
        local AppearanceCard = CreateCard(Page, "Appearance", "Choose a color palette for the interface.")
        local ThemeOptions = {
            "Midnight Blue + Cyan",
            "Black + Purple",
            "Dark Gray + Green",
            "Black + Electric Blue",
            "OLED Black + Amber",
            "Obsidian + Crimson",
            "Deep Ocean + Teal",
            "Graphite + Orange",
            "Dark Plum + Rose",
            "Forest Night + Lime"
        }
        CreateDropdown(AppearanceCard, "Theme", ThemeOptions, function(themeName)
            ApplyTheme(themeName)
        end)
        local AboutCard = CreateCard(Page, "About", "Steal A Pet & Ride It • UI only")
    end
end
-- SHOW FIRST PAGE
Pages[1].Visible = true
SidebarButtons[1].TextColor3 = Theme.Text
-- WINDOW CONTROLS
local Minimized = false
local function SetMinimized(state)
    Minimized = state
    if Minimized then
        Content.Visible = false
        Sidebar.Visible = false
        TopBar.Visible = false
        RestoreButton.Visible = true
        MainCorner.CornerRadius = UDim.new(0, 18)
        Tween(Main, {Size = UDim2.fromOffset(36, 36)})
    else
        RestoreButton.Visible = false
        MainCorner.CornerRadius = UDim.new(0, 12)
        Tween(Main, {Size = UDim2.fromOffset(UIConfig.Width, UIConfig.Height)})
        TopBar.Visible = true
        Content.Visible = true
        Sidebar.Visible = true
    end
end
MinimizeButton.MouseButton1Click:Connect(function()
    SetMinimized(true)
end)
RestoreButton.MouseButton1Click:Connect(function()
    SetMinimized(false)
end)
CloseButton.MouseButton1Click:Connect(function()
    if type(RuntimeEnv.__StealAPetAndRideItCleanup) == "function" then
        RuntimeEnv.__StealAPetAndRideItCleanup()
    else
        Runtime.Stopped = true
        if Runtime.StopNavigation then
            Runtime.StopNavigation()
        end
        ScreenGui:Destroy()
    end
end)
-- WINDOW DRAGGING
local Dragging = false
local DragStart
local StartPosition
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        Dragging = true
        DragStart = input.Position
        StartPosition = Main.Position
    end
end)
RestoreButton.InputBegan:Connect(function(input)
    if Minimized and (input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch) then
        Dragging = true
        DragStart = input.Position
        StartPosition = Main.Position
    end
end)
TrackConnection(UserInputService.InputChanged:Connect(function(input)
    if not Dragging then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
    and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local Delta = input.Position - DragStart
    Main.Position = UDim2.new(
        StartPosition.X.Scale,
        StartPosition.X.Offset + Delta.X,
        StartPosition.Y.Scale,
        StartPosition.Y.Offset + Delta.Y
    )
end))
TrackConnection(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        Dragging = false
    end
end))
