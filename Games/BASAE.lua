-- REUSABLE UI TEMPLATE
-- SERVICES
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local RuntimeEnv = type(getgenv) == "function" and getgenv() or _G
local testver = "Deploy v1.221"
local PreviousRuntimeCleanup = RuntimeEnv.__BASAESkripCleanup
if type(PreviousRuntimeCleanup) == "function" then
    pcall(PreviousRuntimeCleanup)
end
local Runtime = {Stopped = false}
RuntimeEnv.__BASAESkripCleanup = function()
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
        local oldUI = game.CoreGui:FindFirstChild("BASAESkripUI")
        if oldUI then oldUI:Destroy() end
    end)
    pcall(function()
        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        for _, name in ipairs({"BASE_Skrip_EggESP", "BASE_Skrip_BackpackESP"}) do
            local oldESP = playerGui and playerGui:FindFirstChild(name)
            if oldESP then
                if name == "BASE_Skrip_BackpackESP" then
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
    Title = "SKRIPNIBAI",
    Subtitle = testver,
    Width = 480,
    Height = 320,
    SidebarWidth = 108,
    SidebarNames = {
        "Main",
        "Event",
        "Misc. feature",
        "Pickups",
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
    local oldUI = game.CoreGui:FindFirstChild("BASAESkripUI")
    if oldUI then oldUI:Destroy() end
end)
pcall(function()
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    for _, name in ipairs({"BASE_Skrip_EggESP", "BASE_Skrip_BackpackESP"}) do
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
local ActiveThemeName = "OLED Black + Amber"
-- SCREEN GUI
local ScreenGui = Create("ScreenGui", {
    Name = "BASAESkripUI",
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
        titleLabel.Text = '<font color="#' .. selectedTheme.Accent:ToHex() .. '">SKRIP</font>NIBAI'
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
    Size = UDim2.fromOffset(220, 22),
    BackgroundTransparency = 1,
    Text = '<font color="#' .. Theme.Accent:ToHex() .. '">SKRIP</font>NIBAI',
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
    Text = "B",
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
    UserInputService.InputChanged:Connect(function(input)
        if Dragging then
            if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
                Update(input)
            end
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = false
        end
    end)
    return Holder
end
-- CREATE SIDEBAR BUTTONS
for index, name in ipairs(UIConfig.SidebarNames) do
    local Button = Create("TextButton", {
        Name = "SidebarButton_" .. index,
        Parent = SidebarContainer,
        Size = UDim2.new(1, -2, 0, 34),
        BackgroundColor3 = Theme.Sidebar,
        Text = ({"🏠", "🎉", "✨", "🐾", "⚙️", "🪲"})[index] .. "  " .. name,
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
local ShutdownAutomation
local CancelActiveAutomation
local TouchAutomationProgress
local AntiPaloEnabled = false
-- CREATE ALL PAGES
for index, name in ipairs(UIConfig.SidebarNames) do
    local Page = CreatePage(index, name)
    if index == 1 then
        local AutoRow = Create("Frame", {
            Name = "AutoControlsRow",
            Parent = Page,
            Size = UDim2.new(1, 0, 0, 350),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = 1
        })
        local Card1 = CreateCard(AutoRow, "⚡  Auto Break", "")
        Card1.Position = UDim2.new(0.5, 6, 0, 0)
        Card1.Size = UDim2.new(0.5, -6, 0, 190)
        local StartAutoBreak
        local StopAutoBreak
        local StopPickupAutomation
        local CompletedEggs = {}
        local LastEggHPValue = nil
        local LastEggHPTarget = nil

        local AutoBreakToggleInitialized = false
        local AutoBreakEnabled = false
        local AutoBreakGeneration = 0
        local RefreshTitanicPriority
        local AutoBreakControlLayout = {
            ZoneY = 42,
            EggY = 81,
            HighLuckY = 109,
            TitanicY = 135,
            Height = 22,
            SidePadding = 11
        }
        function SetAutoBreakControl(control, y)
            control.Position = UDim2.fromOffset(AutoBreakControlLayout.SidePadding, y)
            control.Size = UDim2.new(1, -AutoBreakControlLayout.SidePadding * 2, 0, AutoBreakControlLayout.Height)
        end
        local AutoBreakToggle = CreateToggle(Card1, "", false, function(enabled)
            AutoBreakEnabled = enabled
            AutoBreakGeneration += 1
            if TouchAutomationProgress then
                TouchAutomationProgress(enabled and "AUTO_BREAK_ON" or "AUTO_BREAK_OFF")
            end
            if not AutoBreakToggleInitialized then
                AutoBreakToggleInitialized = true
                return
            end
            AddDebugLog("[Auto Break] Toggle " .. (enabled and "ON" or "OFF"))
            if enabled then
                if StartAutoBreak then StartAutoBreak() end
            else
                if StopAutoBreak then StopAutoBreak("Toggle disabled") end
                if CancelActiveAutomation then CancelActiveAutomation("Auto Break disabled") end
            end
        end)
        AutoBreakToggle.Position = UDim2.new(1, -58, 0, 7)
        AutoBreakToggle.Size = UDim2.fromOffset(48, 24)
        local AutoBreakTitle = Card1:FindFirstChildWhichIsA("TextLabel")
        if AutoBreakTitle then AutoBreakTitle.Size = UDim2.new(1, -78, 0, 22) end
        local AutoPickupCard = CreateCard(AutoRow, "🐾  Auto Pickup", "")
        AutoPickupCard.Position = UDim2.new(0, 0, 0, 0)
        AutoPickupCard.Size = UDim2.new(0.5, -6, 0, 316)
        local AutoPickupEnabled = false
        local CurrentTarget, ArrivedAtTarget, WaitingForPickup
        local PickupRequested, ReturningAfterPickup, FlingRecoveryActive, ScriptShuttingDown
        local PickupMonitorSeen = setmetatable({}, {__mode = "k"})
        local AutoPickupToggle = CreateToggle(AutoPickupCard, "", false, function(enabled)
            AutoPickupEnabled = enabled
            table.clear(PickupMonitorSeen)
            AddDebugLog("[Auto Pickup] " .. (enabled and "Monitoring ON." or "Monitoring OFF."))
            if not enabled then
                if StopPickupAutomation then StopPickupAutomation("Auto Pickup disabled") end
                if CurrentTarget and IsEggConfirmedComplete(CurrentTarget) then
                    CompletedEggs[CurrentTarget] = true
                end
                WaitingForPickup = false
                ArrivedAtTarget = false
                task.defer(function()
                    task.wait(0.2)
                    if AutoBreakEnabled and not AutoPickupEnabled and not PickupRequested
                        and not ReturningAfterPickup and not FlingRecoveryActive and not ScriptShuttingDown
                        and StartAutoBreak then
                        StartAutoBreak(true)
                    end
                end)
            end
        end)
        AutoPickupToggle.Position = UDim2.new(1, -58, 0, 7)
        AutoPickupToggle.Size = UDim2.fromOffset(48, 24)
        local AutoPickupTitle = AutoPickupCard:FindFirstChildWhichIsA("TextLabel")
        if AutoPickupTitle then AutoPickupTitle.Size = UDim2.new(1, -78, 0, 22) end
        local AntiFuseRow = Create("Frame", {
            Name = "AntiFuseRow",
            Parent = Page,
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = 2
        })
        local AutoFuseCard = CreateCard(AutoRow, "⚙️  Auto Fuse", "UNDER DEVELOPMENT")
        AutoFuseCard.Position = UDim2.new(0.5, 6, 0, 196)
        AutoFuseCard.Size = UDim2.new(0.5, -6, 0, 150)
        local AutoFuseEnabled = false
        local AutoFuseGeneration = 0
        local AutoFuseRequirements = {}
        local AutoFuseStatus = Create("TextLabel", {
            Name = "AutoFuseStatus",
            Parent = AutoFuseCard,
            Position = UDim2.fromOffset(11, 47),
            Size = UDim2.new(1, -22, 0, 14),
            BackgroundTransparency = 1,
            Text = "Status: OFF",
            TextColor3 = Theme.Gray,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        local AutoFuseRequirementLabels = {}
        for slot = 1, 3 do
            AutoFuseRequirementLabels[slot] = Create("TextLabel", {
                Name = "Requirement" .. slot,
                Parent = AutoFuseCard,
                Position = UDim2.fromOffset(11, 64 + (slot - 1) * 18),
                Size = UDim2.new(1, -22, 0, 16),
                BackgroundTransparency = 1,
                Text = "Animal " .. slot .. ": loading...",
                TextColor3 = Theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd
            })
        end
        function GetAutoFuseRequirement(slot)
            local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            local sciFiUI = playerGui and playerGui:FindFirstChild("SciFi UI")
            local tradeIn = sciFiUI and sciFiUI:FindFirstChild("SciFiTradeInMain")
            local inputs = tradeIn and tradeIn:FindFirstChild("SacrificeInputs")
            local input = inputs and inputs:FindFirstChild("Input" .. slot)
            local empty = input and input:FindFirstChild("Empty")
            local nameLabel = empty and empty:FindFirstChild("Name")
            if not nameLabel or not nameLabel:IsA("TextLabel") then return nil end
            local animalName = nameLabel.Text
            animalName = animalName:match("^%s*(.-)%s*$")
            if animalName == "" then return nil end
            return animalName
        end
        function RefreshAutoFuseRequirements()
            local requirements = {}
            for slot = 1, 3 do
                local animalName = GetAutoFuseRequirement(slot)
                requirements[slot] = animalName
                AutoFuseRequirementLabels[slot].Text = "Animal " .. slot .. ": " .. (animalName or "not detected")
                AutoFuseRequirementLabels[slot].TextColor3 = animalName and Theme.Text or Theme.Gray
            end
            AutoFuseRequirements = requirements
            return requirements
        end
        local AutoFuseToggle
        AutoFuseToggle = CreateToggle(AutoFuseCard, "", false, function(enabled)
            if enabled then
                AddDebugLog("[Auto Fuse] UNDER DEVELOPMENT - disabled in Deploy.")
                task.defer(function()
                    local controller = ToggleControllers[AutoFuseToggle]
                    if controller then controller.SetEnabled(false, false) end
                    AutoFuseStatus.Text = "UNDER DEVELOPMENT"
                    AutoFuseStatus.TextColor3 = Theme.Gray
                end)
                return
            end
            AutoFuseEnabled = false
            AutoFuseGeneration += 1
            AutoFuseStatus.Text = "Status: OFF"
            AutoFuseStatus.TextColor3 = Theme.Gray
            AddDebugLog("[Auto Fuse] disabled.")
        end)
        AutoFuseToggle.Position = UDim2.new(1, -58, 0, 7)
        AutoFuseToggle.Size = UDim2.fromOffset(48, 24)
        task.spawn(function()
            while not Runtime.Stopped and AutoFuseCard.Parent do
                RefreshAutoFuseRequirements()
                task.wait(1)
            end
        end)
        MarkUnderDevelopment(AutoFuseCard)
        local RarityFilterOpen = false
        local RarityOptions = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Cosmic", "Secret", "Eternal", "Divine", "Celestial", "Inferno", "Void", "Omega", "Spectral"}
        local SelectedRarities = {}
        local SelectedPickupZones = {}
        local PickupZoneList
        local PickupZoneButton
        local RarityList
        local RarityFilterButton
        local ZoneFilterOpen = false
        local EggFilterOpen = false
        local ZoneList
        local EggFilterList
        RarityFilterButton = CreateButton(AutoPickupCard, "Rarity ▼", function()
            RarityFilterOpen = not RarityFilterOpen
            ZoneFilterOpen = false
            EggFilterOpen = false
            if RarityFilterOpen then
                RarityList.Position = UDim2.fromOffset(11, RarityFilterButton.Position.Y.Offset + RarityFilterButton.AbsoluteSize.Y + 4)
                RarityList.Size = UDim2.new(1, -22, 0, 140)
            end
            if PickupZoneList then PickupZoneList.Visible = false end
            RarityFilterButton.Text = RarityFilterOpen and "Rarity ▲" or "Rarity ▼"
            RarityList.Visible = RarityFilterOpen
            if ZoneList then ZoneList.Visible = false end
            if EggFilterList then EggFilterList.Visible = false end
        end)
        Create("TextLabel", {
            Name = "RarityFilterLabel",
            Parent = AutoPickupCard,
            Position = UDim2.fromOffset(11, 27),
            Size = UDim2.new(1, -22, 0, 13),
            BackgroundTransparency = 1,
            Text = "Rarity Filter",
            TextColor3 = Theme.Gray,
            Font = Enum.Font.GothamMedium,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        RarityFilterButton.Position = UDim2.fromOffset(11, 43)
        RarityFilterButton.Size = UDim2.new(1, -22, 0, 22)
        PickupZoneButton = CreateButton(AutoPickupCard, "Zone: All ▼", function()
            ZoneFilterOpen = not ZoneFilterOpen
            RarityFilterOpen = false
            EggFilterOpen = false
            RarityList.Visible = false
            if ZoneList then ZoneList.Visible = false end
            if EggFilterList then EggFilterList.Visible = false end
            if PickupZoneList then
                PickupZoneList.Position = UDim2.fromOffset(11, 111)
                PickupZoneList.Size = UDim2.new(1, -22, 0, 140)
                PickupZoneList.Visible = ZoneFilterOpen
            end
            local count = 0
            for _, selected in pairs(SelectedPickupZones) do
                if selected then count += 1 end
            end
            PickupZoneButton.Text = ZoneFilterOpen and "Zone ▲" or (count == 0 and "Zone: All ▼" or string.format("Zone: %d ▼", count))
        end)
        PickupZoneButton.Name = "AutoPickupZoneFilterButton"
        PickupZoneButton.Position = UDim2.fromOffset(11, 85)
        PickupZoneButton.Size = UDim2.new(1, -22, 0, 22)
        local KGThresholdAmount = 0
        local KGThresholdUnit = "K"
        Create("TextLabel", {
            Name = "ZoneFilterLabel",
            Parent = AutoPickupCard,
            Position = UDim2.fromOffset(11, 69),
            Size = UDim2.new(1, -22, 0, 13),
            BackgroundTransparency = 1,
            Text = "Zone filter",
            TextColor3 = Theme.Gray,
            Font = Enum.Font.GothamMedium,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        Create("TextLabel", {
            Name = "KGThresholdLabel",
            Parent = AutoPickupCard,
            Position = UDim2.fromOffset(11, 111),
            Size = UDim2.new(1, -22, 0, 13),
            BackgroundTransparency = 1,
            Text = "Weight Threshold (KG) · Unit",
            TextColor3 = Theme.Gray,
            Font = Enum.Font.GothamMedium,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        local KGThresholdInput = Create("TextBox", {
            Name = "KGThresholdInput",
            Parent = AutoPickupCard,
            Position = UDim2.fromOffset(11, 126),
            Size = UDim2.new(1, -84, 0, 25),
            BackgroundColor3 = Theme.SurfaceInput,
            Text = "",
            PlaceholderText = "e.g. 100",
            PlaceholderColor3 = Theme.Gray,
            TextColor3 = Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            ClearTextOnFocus = false,
            BorderSizePixel = 0
        })
        AddCorner(KGThresholdInput, 5)
        AddStroke(KGThresholdInput, Theme.Border, 1)
        local KGUnitButton
        local KGUnitState = {options = {"K", "M", "B", "T"}, open = false, list = nil}
        KGUnitButton = CreateButton(AutoPickupCard, "KG: K ▼", function()
            KGUnitState.open = not KGUnitState.open
            RarityFilterOpen = false
            ZoneFilterOpen = false
            EggFilterOpen = false
            RarityList.Visible = false
            if ZoneList then ZoneList.Visible = false end
            if EggFilterList then EggFilterList.Visible = false end
            if KGUnitState.list then KGUnitState.list.Visible = KGUnitState.open end
            KGUnitButton.Text = KGUnitState.open and "KG: " .. KGThresholdUnit .. " ▲" or "KG: " .. KGThresholdUnit .. " ▼"
        end)
        KGUnitButton.Name = "KGUnitFilterButton"
        KGUnitButton.Position = UDim2.new(1, -63, 0, 126)
        KGUnitButton.Size = UDim2.fromOffset(52, 25)
        KGUnitState.list = Create("Frame", {
            Name = "KGUnitFilterList",
            Parent = AutoPickupCard,
            Position = UDim2.new(1, -63, 0, 153),
            Size = UDim2.fromOffset(52, #KGUnitState.options * 24 + 8),
            BackgroundColor3 = Theme.SurfaceInput,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 120
        })
        AddCorner(KGUnitState.list, 6)
        AddStroke(KGUnitState.list, Theme.Border, 1)
        Create("UIListLayout", {
            Parent = KGUnitState.list,
            Padding = UDim.new(0, 2),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        Create("UIPadding", {
            Parent = KGUnitState.list,
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 4)
        })
        for index, unit in ipairs(KGUnitState.options) do
            local unitButton = Create("TextButton", {
                Name = "KGUnit_" .. unit,
                Parent = KGUnitState.list,
                Size = UDim2.new(1, -4, 0, 22),
                BackgroundColor3 = unit == KGThresholdUnit and Theme.Selected or Theme.Card,
                Text = unit,
                TextColor3 = Theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 10,
                BorderSizePixel = 0,
                LayoutOrder = index,
                AutoButtonColor = false,
                ZIndex = 121
            })
            AddCorner(unitButton, 4)
            unitButton.MouseButton1Click:Connect(function()
                KGThresholdUnit = unit
                KGUnitButton.Text = "KG: " .. unit .. " ▼"
                KGUnitState.open = false
                KGUnitState.list.Visible = false
                for _, child in ipairs(KGUnitState.list:GetChildren()) do
                    if child:IsA("TextButton") then
                        child.BackgroundColor3 = child.Name == "KGUnit_" .. unit and Theme.Selected or Theme.Card
                    end
                end
                AddDebugLog("[Auto Pickup] KG threshold unit set to " .. unit .. ".")
            end)
        end
        KGThresholdInput.FocusLost:Connect(function()
            local rawAmount = tostring(KGThresholdInput.Text or ""):gsub(",", ""):match("^%s*(.-)%s*$")
            local amount = tonumber(rawAmount)
            KGThresholdAmount = amount and math.max(amount, 0) or 0
            AddDebugLog(KGThresholdAmount > 0
                and string.format("[Auto Pickup] KG priority threshold set to %s %s KG.", tostring(KGThresholdAmount), KGThresholdUnit)
                or "[Auto Pickup] KG priority filter OFF.")
        end)
        local CPSFilter = {amount = 0, unit = "K", options = {"K", "M", "B", "T"}, open = false}
        Create("TextLabel", {
            Name = "CPSFilterLabel",
            Parent = AutoPickupCard,
            Position = UDim2.fromOffset(11, 154),
            Size = UDim2.new(1, -22, 0, 13),
            BackgroundTransparency = 1,
            Text = "Coins per Second Threshold · Unit",
            TextColor3 = Theme.Gray,
            Font = Enum.Font.GothamMedium,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        CPSFilter.input = Create("TextBox", {
            Name = "CPSFilterInput",
            Parent = AutoPickupCard,
            Position = UDim2.fromOffset(11, 169),
            Size = UDim2.new(1, -84, 0, 25),
            BackgroundColor3 = Theme.SurfaceInput,
            Text = "",
            PlaceholderText = "e.g. 100",
            PlaceholderColor3 = Theme.Gray,
            TextColor3 = Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            ClearTextOnFocus = false,
            BorderSizePixel = 0,
            ZIndex = 2
        })
        AddCorner(CPSFilter.input, 5)
        AddStroke(CPSFilter.input, Theme.Border, 1)
        CPSFilter.button = CreateButton(AutoPickupCard, "Unit: K ▼", function()
            CPSFilter.open = not CPSFilter.open
            RarityFilterOpen = false
            ZoneFilterOpen = false
            EggFilterOpen = false
            RarityList.Visible = false
            if ZoneList then ZoneList.Visible = false end
            if EggFilterList then EggFilterList.Visible = false end
            if KGUnitState.list then KGUnitState.list.Visible = false; KGUnitState.open = false end
            CPSFilter.list.Visible = CPSFilter.open
            CPSFilter.button.Text = CPSFilter.open and "Unit: " .. CPSFilter.unit .. " ▲" or "Unit: " .. CPSFilter.unit .. " ▼"
        end)
        CPSFilter.button.Name = "CPSUnitFilterButton"
        CPSFilter.button.Position = UDim2.new(1, -63, 0, 169)
        CPSFilter.button.Size = UDim2.fromOffset(52, 25)
        CPSFilter.list = Create("Frame", {
            Name = "CPSUnitFilterList",
            Parent = AutoPickupCard,
            Position = UDim2.new(1, -63, 0, 196),
            Size = UDim2.fromOffset(52, #CPSFilter.options * 24 + 8),
            BackgroundColor3 = Theme.SurfaceInput,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 122
        })
        AddCorner(CPSFilter.list, 6)
        AddStroke(CPSFilter.list, Theme.Border, 1)
        Create("UIListLayout", {Parent = CPSFilter.list, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder})
        Create("UIPadding", {
            Parent = CPSFilter.list,
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 4)
        })
        for index, unit in ipairs(CPSFilter.options) do
            local unitButton = Create("TextButton", {
                Name = "CPSUnit_" .. unit,
                Parent = CPSFilter.list,
                Size = UDim2.new(1, -4, 0, 22),
                BackgroundColor3 = unit == CPSFilter.unit and Theme.Selected or Theme.Card,
                Text = unit,
                TextColor3 = Theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 10,
                BorderSizePixel = 0,
                LayoutOrder = index,
                AutoButtonColor = false,
                ZIndex = 123
            })
            AddCorner(unitButton, 4)
            unitButton.MouseButton1Click:Connect(function()
                CPSFilter.unit = unit
                CPSFilter.button.Text = "Unit: " .. unit .. " ▼"
                CPSFilter.open = false
                CPSFilter.list.Visible = false
                for _, child in ipairs(CPSFilter.list:GetChildren()) do
                    if child:IsA("TextButton") then
                        child.BackgroundColor3 = child.Name == "CPSUnit_" .. unit and Theme.Selected or Theme.Card
                    end
                end
                AddDebugLog("[Auto Pickup] Coins/second unit set to " .. unit .. ".")
            end)
        end
        CPSFilter.input.FocusLost:Connect(function()
            local rawAmount = tostring(CPSFilter.input.Text or ""):gsub(",", ""):match("^%s*(.-)%s*$")
            local amount = tonumber(rawAmount)
            CPSFilter.amount = amount and math.max(amount, 0) or 0
            AddDebugLog(CPSFilter.amount > 0
                and string.format("[Auto Pickup] Coins/second minimum set to %s %s/s.", tostring(CPSFilter.amount), CPSFilter.unit)
                or "[Auto Pickup] Coins/second filter OFF.")
        end)
        local HighestCashEnabled = false
        local HighestCashToggle = CreateToggle(AutoPickupCard, "Above Lowest $/s", false, function(enabled)
            HighestCashEnabled = enabled
            AddDebugLog("[Auto Pickup] " .. (enabled and "Lowest placed CPS filter ON." or "Lowest placed CPS filter OFF."))
        end)
        HighestCashToggle.Position = UDim2.fromOffset(11, 205)
        HighestCashToggle.Size = UDim2.new(1, -22, 0, 22)
        local UnindexedOnlyEnabled = false
        local UnindexedOnlyToggle = CreateToggle(AutoPickupCard, "Unindexed Animals", false, function(enabled)
            UnindexedOnlyEnabled = enabled
            AddDebugLog("[Auto Pickup] " .. (enabled and "Unindexed-only verification ON." or "Unindexed-only verification OFF."))
        end)
        UnindexedOnlyToggle.Position = UDim2.fromOffset(11, 231)
        UnindexedOnlyToggle.Size = UDim2.new(1, -22, 0, 22)
        local DropInZone1Enabled = false
        local DropInZone1Toggle = CreateToggle(AutoPickupCard, "Drop in Zone 1", false, function(enabled)
            DropInZone1Enabled = enabled
            AddDebugLog("[Auto Pickup] Drop in Zone 1 " .. (enabled and "ON." or "OFF."))
        end)
        DropInZone1Toggle.Position = UDim2.fromOffset(11, 257)
        DropInZone1Toggle.Size = UDim2.new(1, -22, 0, 22)
        local PickUpWithMutationEnabled = false
        local PickUpWithMutationToggle = CreateToggle(AutoPickupCard, "With Mutation", false, function(enabled)
            PickUpWithMutationEnabled = enabled
            AddDebugLog("[Auto Pickup] With Mutation " .. (enabled and "ON." or "OFF."))
        end)
        PickUpWithMutationToggle.Position = UDim2.fromOffset(11, 283)
        PickUpWithMutationToggle.Size = UDim2.new(1, -22, 0, 22)
        RarityList = Create("ScrollingFrame", {
            Name = "RarityFilterContainer",
            Parent = AutoPickupCard,
            Position = UDim2.fromOffset(11, 75),
            Size = UDim2.fromOffset(160, 155),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Gray,
            BackgroundColor3 = Theme.SurfaceInput,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 100
        })
        AddCorner(RarityList, 6)
        PickupZoneList = Create("ScrollingFrame", {
            Name = "AutoPickupZoneFilterList",
            Parent = AutoPickupCard,
            Position = UDim2.fromOffset(11, 111),
            Size = UDim2.new(1, -22, 0, 140),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Gray,
            BackgroundColor3 = Theme.SurfaceInput,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 110
        })
        AddCorner(PickupZoneList, 6)
        local PickupZoneLayout = Create("UIListLayout", {
            Parent = PickupZoneList,
            Padding = UDim.new(0, 3),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        Create("UIPadding", {
            Parent = PickupZoneList,
            PaddingTop = UDim.new(0, 5),
            PaddingBottom = UDim.new(0, 5),
            PaddingLeft = UDim.new(0, 5),
            PaddingRight = UDim.new(0, 5)
        })
        local RarityLayout = Create("UIListLayout", {
            Parent = RarityList,
            Padding = UDim.new(0, 3),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        Create("UIPadding", {
            Parent = RarityList,
            PaddingTop = UDim.new(0, 5),
            PaddingBottom = UDim.new(0, 5),
            PaddingLeft = UDim.new(0, 5),
            PaddingRight = UDim.new(0, 5)
        })
        RarityLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            RarityList.CanvasSize = UDim2.new(0, 0, 0, RarityLayout.AbsoluteContentSize.Y + 10)
        end)
        function RefreshRarityList()
            for _, item in ipairs(RarityList:GetChildren()) do
                if item:IsA("TextButton") then item:Destroy() end
            end
            for rarityIndex, rarityName in ipairs(RarityOptions) do
                local selected = SelectedRarities[rarityName] == true
                local RarityButton = Create("TextButton", {
                    Name = "Rarity_" .. rarityName, Parent = RarityList,
                    Size = UDim2.new(1, -4, 0, 22),
                    BackgroundColor3 = selected and Theme.Selected or Theme.Card,
                    Text = "", BorderSizePixel = 0, LayoutOrder = rarityIndex,
                    AutoButtonColor = false, ZIndex = 101
                })
                AddCorner(RarityButton, 4)
                Create("TextLabel", {
                    Parent = RarityButton, Position = UDim2.fromOffset(7, 0),
                    Size = UDim2.new(1, -28, 1, 0), BackgroundTransparency = 1,
                    Text = rarityName, TextColor3 = Theme.Text,
                    Font = Enum.Font.Gotham, TextSize = 9,
                    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 102
                })
                Create("TextLabel", {
                    Parent = RarityButton, Position = UDim2.new(1, -23, 0, 0),
                    Size = UDim2.fromOffset(20, 22), BackgroundTransparency = 1,
                    Text = selected and "✓" or "○",
                    TextColor3 = selected and Color3.fromRGB(110, 205, 145) or Theme.Gray,
                    Font = Enum.Font.GothamBold, TextSize = 11, ZIndex = 102
                })
                RarityButton.MouseButton1Click:Connect(function()
                    SelectedRarities[rarityName] = not SelectedRarities[rarityName] or nil
                    RefreshRarityList()
                end)
            end
        end
        RefreshRarityList()
        local function RefreshPickupZoneList()
            for _, item in ipairs(PickupZoneList:GetChildren()) do
                if item:IsA("TextButton") then item:Destroy() end
            end
            local build = workspace:FindFirstChild("Build")
            local zoneBuilds = build and build:FindFirstChild("ZoneBuilds")
            local zones = {}
            if zoneBuilds then
                for _, zone in ipairs(zoneBuilds:GetChildren()) do
                    if zone:IsA("Model") then table.insert(zones, zone) end
                end
            end
            table.sort(zones, function(a, b)
                local an = tonumber(a.Name:match("%d+"))
                local bn = tonumber(b.Name:match("%d+"))
                if an and bn and an ~= bn then return an > bn end
                if an and not bn then return true end
                if bn and not an then return false end
                return a.Name > b.Name
            end)
            local selectedCount = 0
            for _, zone in ipairs(zones) do
                if SelectedPickupZones[zone.Name] then selectedCount += 1 end
            end
            local allButton = Create("TextButton", {
                Name = "PickupZone_All",
                Parent = PickupZoneList,
                Size = UDim2.new(1, -4, 0, 22),
                BackgroundColor3 = selectedCount == 0 and Theme.Selected or Theme.Card,
                Text = "",
                BorderSizePixel = 0,
                LayoutOrder = 0,
                AutoButtonColor = false,
                ZIndex = 111
            })
            AddCorner(allButton, 4)
            Create("TextLabel", {
                Parent = allButton, Position = UDim2.fromOffset(6, 0),
                Size = UDim2.new(1, -24, 1, 0), BackgroundTransparency = 1,
                Text = "All Zones (default)", TextColor3 = Theme.Text,
                Font = Enum.Font.Gotham, TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 112
            })
            Create("TextLabel", {
                Parent = allButton, Position = UDim2.new(1, -20, 0, 0),
                Size = UDim2.fromOffset(16, 22), BackgroundTransparency = 1,
                Text = selectedCount == 0 and "✓" or "○",
                TextColor3 = selectedCount == 0 and Color3.fromRGB(110, 205, 145) or Theme.Gray,
                Font = Enum.Font.GothamBold, TextSize = 10, ZIndex = 112
            })
            allButton.MouseButton1Click:Connect(function()
                table.clear(SelectedPickupZones)
                RefreshPickupZoneList()
                PickupZoneButton.Text = "Zone: All ▼"
            end)
            for index, zone in ipairs(zones) do
                local zoneName = zone.Name
                local selected = SelectedPickupZones[zoneName] == true
                local item = Create("TextButton", {
                    Name = "PickupZone_" .. zoneName,
                    Parent = PickupZoneList,
                    Size = UDim2.new(1, -4, 0, 22),
                    BackgroundColor3 = selected and Theme.Selected or Theme.Card,
                    Text = "", BorderSizePixel = 0, LayoutOrder = index,
                    AutoButtonColor = false, ZIndex = 111
                })
                AddCorner(item, 4)
                Create("TextLabel", {
                    Parent = item, Position = UDim2.fromOffset(6, 0),
                    Size = UDim2.new(1, -24, 1, 0), BackgroundTransparency = 1,
                    Text = zoneName, TextColor3 = Theme.Text,
                    Font = Enum.Font.Gotham, TextSize = 9,
                    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 112
                })
                Create("TextLabel", {
                    Parent = item, Position = UDim2.new(1, -20, 0, 0),
                    Size = UDim2.fromOffset(16, 22), BackgroundTransparency = 1,
                    Text = selected and "✓" or "○",
                    TextColor3 = selected and Color3.fromRGB(110, 205, 145) or Theme.Gray,
                    Font = Enum.Font.GothamBold, TextSize = 10, ZIndex = 112
                })
                item.MouseButton1Click:Connect(function()
                    if SelectedPickupZones[zoneName] then
                        SelectedPickupZones[zoneName] = nil
                    else
                        SelectedPickupZones[zoneName] = true
                    end
                    RefreshPickupZoneList()
                    local count = 0
                    for _, enabled in pairs(SelectedPickupZones) do
                        if enabled then count += 1 end
                    end
                    PickupZoneButton.Text = count == 0 and "Zone: All ▼" or string.format("Zone: %d ▼", count)
                end)
            end
            PickupZoneList.CanvasSize = UDim2.new(0, 0, 0, PickupZoneLayout.AbsoluteContentSize.Y + 10)
        end
        RefreshPickupZoneList()
        local SelectedZones = {}
        local SelectedEggs = {}
        local PreferredZoneName = nil
        local SortOrder = "Largest"
        local SortFrame
        local ZoneFilterButton
        local EggFilterButton
        local SortLargestButton
        local SortSmallestButton
        local ZoneBuilds = workspace:WaitForChild("Build"):WaitForChild("ZoneBuilds")
        function GetPickupZoneName(pickup)
            if not pickup or not pickup.Parent then return nil end
            local pickupPosition
            local ok = pcall(function()
                if pickup:IsA("Model") then
                    pickupPosition = pickup:GetPivot().Position
                elseif pickup:IsA("BasePart") then
                    pickupPosition = pickup.Position
                end
            end)
            if not ok or not pickupPosition then return nil end
            local nearestZone, nearestDistance = nil, math.huge
            for _, zone in ipairs(ZoneBuilds:GetChildren()) do
                local eggsFolder = zone:FindFirstChild("Eggs")
                if eggsFolder then
                    for _, egg in ipairs(eggsFolder:GetChildren()) do
                        if egg:IsA("Model") or egg:IsA("BasePart") then
                            local eggPosition
                            local eggOk = pcall(function()
                                if egg:IsA("Model") then
                                    eggPosition = egg:GetPivot().Position
                                else
                                    eggPosition = egg.Position
                                end
                            end)
                            if eggOk and eggPosition then
                                local distance = (pickupPosition - eggPosition).Magnitude
                                if distance < nearestDistance then
                                    nearestDistance = distance
                                    nearestZone = zone.Name
                                end
                            end
                        end
                    end
                end
            end
            return nearestZone
        end
        function IsPickupAllowedByZone(pickup)
            local selectedCount = 0
            for _, selected in pairs(SelectedPickupZones) do
                if selected then selectedCount += 1 end
            end
            if selectedCount == 0 then return true end
            local zoneName = GetPickupZoneName(pickup)
            if not zoneName then
                SetPickupTracking(pickup, "Rejected: pickup zone could not be determined")
                return false, nil
            end
            return SelectedPickupZones[zoneName] == true, zoneName
        end
        function UpdateFilterPanel()
            ZoneList.Visible = ZoneFilterOpen
            EggFilterList.Visible = EggFilterOpen
            RarityList.Visible = RarityFilterOpen
            SortFrame.Visible = true
            if ZoneFilterOpen then
                ZoneList.Position = UDim2.new(0, ZoneFilterButton.Position.X.Offset, 0, ZoneFilterButton.Position.Y.Offset + ZoneFilterButton.AbsoluteSize.Y + 4)
                ZoneList.Size = UDim2.new(1, -22, 0, 140)
            end
            if EggFilterOpen then
                EggFilterList.Position = UDim2.new(0, EggFilterButton.Position.X.Offset, 0, EggFilterButton.Position.Y.Offset + EggFilterButton.AbsoluteSize.Y + 4)
                EggFilterList.Size = UDim2.new(1, -22, 0, 140)
            end
            ZoneFilterButton.Text = ZoneFilterOpen and "Zones ▲" or "Zones ▼"
            EggFilterButton.Text = EggFilterOpen and "Eggs ▲" or "Eggs ▼"
            RarityFilterButton.Text = RarityFilterOpen and "Rarity ▲" or "Rarity ▼"
        end
        Create("TextLabel", {
            Name = "ZoneFilterLabel",
            Parent = Card1,
            Position = UDim2.fromOffset(11, 27),
            Size = UDim2.new(1, -22, 0, 13),
            BackgroundTransparency = 1,
            Text = "Zone Filter",
            TextColor3 = Theme.Gray,
            Font = Enum.Font.GothamMedium,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        Create("TextLabel", {
            Name = "EggFilterLabel",
            Parent = Card1,
            Position = UDim2.fromOffset(11, 66),
            Size = UDim2.new(1, -22, 0, 13),
            BackgroundTransparency = 1,
            Text = "Egg Filter",
            TextColor3 = Theme.Gray,
            Font = Enum.Font.GothamMedium,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        ZoneFilterButton = CreateButton(Card1, "Zones ▼", function()
            ZoneFilterOpen = not ZoneFilterOpen
            EggFilterOpen = false
            RarityFilterOpen = false
            UpdateFilterPanel()
        end)
        SetAutoBreakControl(ZoneFilterButton, AutoBreakControlLayout.ZoneY)
        EggFilterButton = CreateButton(Card1, "Eggs ▼", function()
            EggFilterOpen = not EggFilterOpen
            ZoneFilterOpen = false
            RarityFilterOpen = false
            UpdateFilterPanel()
        end)
        SetAutoBreakControl(EggFilterButton, AutoBreakControlLayout.EggY)
        ZoneList = Create("ScrollingFrame", {
            Name = "ZoneFilterList",
            Parent = Card1,
            Position = UDim2.fromOffset(11, 76),
            Size = UDim2.fromOffset(140, 150),
            BackgroundColor3 = Theme.SurfaceInput,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Gray,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            ZIndex = 100
        })
        AddCorner(ZoneList, 6)
        local ZoneLayout = Create("UIListLayout", {
            Parent = ZoneList,
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        Create("UIPadding", {
            Parent = ZoneList,
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 4)
        })
        EggFilterList = Create("ScrollingFrame", {
            Name = "EggFilterList",
            Parent = Card1,
            Position = UDim2.fromOffset(11, 76),
            Size = UDim2.fromOffset(140, 150),
            BackgroundColor3 = Theme.SurfaceInput,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Gray,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            ZIndex = 100
        })
        AddCorner(EggFilterList, 6)
        local EggLayout = Create("UIListLayout", {
            Parent = EggFilterList,
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        Create("UIPadding", {
            Parent = EggFilterList,
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 4)
        })
        SortFrame = Create("Frame", {
            Name = "EggSortOptions",
            Parent = Card1,
            Position = UDim2.fromOffset(AutoBreakControlLayout.SidePadding, AutoBreakControlLayout.HighLuckY),
            Size = UDim2.new(1, -AutoBreakControlLayout.SidePadding * 2, 0, AutoBreakControlLayout.Height),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = true
        })
        local HighestLuckToggle
        function UpdateSortButtons()
            SortOrder = HighestLuckToggle and ToggleControllers[HighestLuckToggle].GetEnabled() and "Highest Luck" or "Default"
        end
        HighestLuckToggle = CreateToggle(SortFrame, "HighLuck Priority", false, function(enabled)
            SortOrder = enabled and "Highest Luck" or "Default"
            if RefreshEggList then RefreshEggList() end
            AddDebugLog("[Auto Break] Highest Luck first " .. (enabled and "ON" or "OFF"))
        end)
        HighestLuckToggle.Position = UDim2.fromOffset(0, 0)
        HighestLuckToggle.Size = UDim2.new(1, 0, 0, 28)
        SortLargestButton = HighestLuckToggle
        SortSmallestButton = nil
        function GetEggTypeName(name)
            return (name:gsub("^%d+:%s*", ""))
        end
        function GetEggDataValue(egg, variableName)
            local eggModel = egg and (egg:FindFirstChild("Egg") or egg:FindFirstChild("Egg", true) or egg)
            if not eggModel then return nil end
            local function readFrom(object)
                local attribute = object:GetAttribute(variableName)
                if attribute ~= nil then return tostring(attribute) end
                if object.Name == variableName then
                    if object:IsA("ValueBase") then return tostring(object.Value) end
                    if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
                        if object.Text ~= "" then return object.Text end
                    end
                end
                return nil
            end
            local value = readFrom(eggModel)
            if value ~= nil then return value end
            for _, node in ipairs(eggModel:GetDescendants()) do
                value = readFrom(node)
                if value ~= nil then return value end
            end
            return nil
        end
        function GetEggWeightBracket(egg)
            return GetEggDataValue(egg, "WeightBracket")
        end
        function GetEggWeightKg(egg)
            local raw = GetEggDataValue(egg, "weightKg")
                or GetEggDataValue(egg, "WeightKg")
                or GetEggDataValue(egg, "WeightKG")
                or GetEggDataValue(egg, "weightKG")
            if not raw then return nil end
            local value = tonumber(tostring(raw):lower():gsub(",", ""):match("[%d%.]+"))
            return value
        end
        function GetKnownEggHealth(egg)
            if not egg then return nil end
            for _, healthName in ipairs({"Health", "CurrentHealth", "EggHealth", "HP"}) do
                local health = tonumber(GetEggDataValue(egg, healthName))
                if health ~= nil then return health end
            end
            return nil
        end
        function IsEggConfirmedComplete(egg)
            if not egg then return false end
            if not egg.Parent or CompletedEggs[egg] then return true end
            local health = GetKnownEggHealth(egg)
            if health ~= nil then return health <= 0 end
            if LastEggHPTarget == egg then
                local eventHealth = tonumber(LastEggHPValue)
                if eventHealth ~= nil then return eventHealth <= 0 end
            end
            return false
        end
        function IsEggAvailable(egg)
            if not egg or not egg.Parent or CompletedEggs[egg] then return false end
            local eggsFolder = egg.Parent
            if eggsFolder.Name ~= "Eggs" then return false end
            local zone = eggsFolder.Parent
            if not zone or zone.Parent ~= ZoneBuilds then return false end
            if not (egg:IsA("Model") or egg:IsA("BasePart")) then return false end
            if not egg.Name:lower():find("egg", 1, true) then return false end
            for _, healthName in ipairs({"Health", "CurrentHealth", "EggHealth", "HP"}) do
                local rawHealth = GetEggDataValue(egg, healthName)
                local health = tonumber(rawHealth)
                if health and health <= 0 then
                    return false
                end
            end
            return true
        end

        function GetEggLuck(egg)
            local eggModel = egg and (egg:FindFirstChild("Egg") or egg)
            if not eggModel then return 0 end
            local info = eggModel:FindFirstChild("EggInfoUi", true)

            local function isTextObject(node)
                return node and (node:IsA("TextLabel") or node:IsA("TextButton") or node:IsA("TextBox"))
            end

            local function getNamedDisplayText(object, names)
                if not object then return nil end
                local nodes = {object}
                for _, descendant in ipairs(object:GetDescendants()) do
                    table.insert(nodes, descendant)
                end
                for _, name in ipairs(names) do
                    for _, node in ipairs(nodes) do
                        if node.Name == name and isTextObject(node) then
                            local value = tostring(node.Text or "")
                            if value:match("%S") then return value end
                        end
                    end
                end
                return nil
            end

            local function getESPValue(object, names)
                if not object then return nil end
                local nodes = {object}
                for _, descendant in ipairs(object:GetDescendants()) do
                    table.insert(nodes, descendant)
                end
                for _, name in ipairs(names) do
                    for _, node in ipairs(nodes) do
                        if node.Name == name then
                            if isTextObject(node) and tostring(node.Text or ""):match("%S") then
                                return tostring(node.Text)
                            end
                            local value = node:GetAttribute(name)
                            if value ~= nil then return tostring(value) end
                            if node:IsA("ValueBase") then return tostring(node.Value) end
                        end
                        local value = node:GetAttribute(name)
                        if value ~= nil then return tostring(value) end
                    end
                end
                return nil
            end

            -- Prefer the displayed multiplier (for example, "x500.2B") over
            -- raw attributes that may contain only the unscaled number.
            local rawLuck
            if info then
                local luckList = info:FindFirstChild("LuckMultiList", true)
                local luckLabel = luckList and luckList:FindFirstChild("LuckMulti", true)
                if isTextObject(luckLabel) and tostring(luckLabel.Text or ""):match("%S") then
                    rawLuck = luckLabel.Text
                end
                rawLuck = rawLuck or getNamedDisplayText(info, {"LuckMulti", "LuckMultiplier", "Luck"})
            end
            rawLuck = rawLuck
                or getNamedDisplayText(eggModel, {"LuckMulti", "LuckMultiplier", "Luck"})
                or getESPValue(info, {"LuckMulti", "Luck", "LuckMultiplier"})
                or getESPValue(eggModel, {"LuckMulti", "Luck", "LuckMultiplier"})
                or GetEggDataValue(egg, "LuckMulti")
                or GetEggDataValue(egg, "LuckMultiplier")
                or GetEggDataValue(egg, "Luck")

            if rawLuck == nil or tostring(rawLuck):match("%S") == nil then return 0 end

            local text = tostring(rawLuck)
                :gsub("^%s*[xX×]%s*", "")
                :lower()
                :gsub(",", "")
                :gsub("%s+", "")

            local suffixScale = {
                k = 1e3, m = 1e6, b = 1e9, t = 1e12,
                qa = 1e15, qd = 1e15, qi = 1e18,
                sx = 1e21, sp = 1e24, oc = 1e27, no = 1e30,
                dc = 1e33, ud = 1e36, dd = 1e39, td = 1e42,
                qag = 1e45, qig = 1e48, sxg = 1e51, spg = 1e54,
                og = 1e57, ng = 1e60
            }

            local function parseLuckNumber(token)
                if not token then return nil end
                token = token:lower():gsub("^[x×]", "")
                local numberText, suffix = token:match("^(%d+%.?%d*)([a-z]*)$")
                if not numberText then
                    numberText, suffix = token:match("^(%.%d+)([a-z]*)$")
                end
                local number = tonumber(numberText)
                if not number then return nil end
                suffix = suffix or ""
                if suffix ~= "" and suffixScale[suffix] == nil then return nil end
                return number * (suffixScale[suffix] or 1)
            end

            local ratioNumerator, ratioDenominator = text:match("^([%d%.]+[a-z]*)/([%d%.]+[a-z]*)$")
            if ratioNumerator and ratioDenominator then
                return parseLuckNumber(ratioDenominator) or parseLuckNumber(ratioNumerator) or 0
            end

            local lastToken
            for token in text:gmatch("%d+%.?%d*[a-z]*") do
                lastToken = token
            end
            if not lastToken then
                lastToken = text:match("%.(%d+[a-z]*)")
                if lastToken then lastToken = "." .. lastToken end
            end

            return parseLuckNumber(lastToken) or 0
        end
        function GetEggRecords()
            local records = {}
            local byName = {}
            for zoneName, selected in pairs(SelectedZones) do
                if selected then
                    local zone = ZoneBuilds:FindFirstChild(zoneName)
                    local eggsFolder = zone and zone:FindFirstChild("Eggs")
                    if eggsFolder then
                        for _, egg in ipairs(eggsFolder:GetChildren()) do
                            if (egg:IsA("Model") or egg:IsA("BasePart"))
                            and egg.Name:lower():find("egg", 1, true) then
                                local eggName = GetEggTypeName(egg.Name)
                                local luck = GetEggLuck(egg)
                                if not byName[eggName] then
                                    byName[eggName] = {name = eggName, luck = luck}
                                    table.insert(records, byName[eggName])
                                elseif luck > byName[eggName].luck then
                                    byName[eggName].luck = luck
                                end
                            end
                        end
                    end
                end
            end
            table.sort(records, function(a, b)
                if SortOrder == "Highest Luck" and a.luck ~= b.luck then
                    return a.luck > b.luck
                end
                return a.name < b.name
            end)
            return records
        end
        local RefreshEggList
        function RefreshZoneList()
            for _, item in ipairs(ZoneList:GetChildren()) do
                if item:IsA("TextButton") then item:Destroy() end
            end
            local zones = {}
            for _, zone in ipairs(ZoneBuilds:GetChildren()) do
                if zone:IsA("Model") then table.insert(zones, zone) end
            end
            table.sort(zones, function(a, b)
                local aNumber = tonumber(a.Name:match("%d+"))
                local bNumber = tonumber(b.Name:match("%d+"))
                if aNumber and bNumber and aNumber ~= bNumber then return aNumber > bNumber end
                if aNumber and not bNumber then return true end
                if bNumber and not aNumber then return false end
                return a.Name > b.Name
            end)
            local allSelected = #zones > 0
            for _, zone in ipairs(zones) do
                if SelectedZones[zone.Name] ~= true then allSelected = false break end
            end
            local SelectAllButton = Create("TextButton", {
                Name = "SelectAllZones", Parent = ZoneList, Size = UDim2.new(1, -8, 0, 24),
                BackgroundColor3 = allSelected and Theme.Selected or Theme.Card, Text = "",
                BorderSizePixel = 0, LayoutOrder = 0, AutoButtonColor = false, ZIndex = 101
            })
            AddCorner(SelectAllButton, 5)
            Create("TextLabel", {
                Parent = SelectAllButton, Position = UDim2.fromOffset(8, 0),
                Size = UDim2.new(1, -34, 1, 0), BackgroundTransparency = 1,
                Text = allSelected and "All Zones Selected" or "Select All",
                TextColor3 = Theme.Text, Font = Enum.Font.Gotham, TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 102
            })
            Create("TextLabel", {
                Parent = SelectAllButton, Position = UDim2.new(1, -26, 0, 0),
                Size = UDim2.fromOffset(22, 24), BackgroundTransparency = 1,
                Text = allSelected and "✓" or "○",
                TextColor3 = allSelected and Color3.fromRGB(110, 205, 145) or Theme.Gray,
                Font = Enum.Font.GothamBold, TextSize = 12, ZIndex = 102
            })
            SelectAllButton.MouseButton1Click:Connect(function()
                local selectEverything = not allSelected
                for _, zone in ipairs(zones) do SelectedZones[zone.Name] = selectEverything and true or nil end
                RefreshZoneList()
                RefreshEggList()
            end)
            for zoneIndex, zone in ipairs(zones) do
                local zoneName = zone.Name
                local selected = SelectedZones[zoneName] == true
                local ZoneButton = Create("TextButton", {
                    Name = "Zone_" .. zoneName,
                    Parent = ZoneList,
                    Size = UDim2.new(1, -8, 0, 24),
                    BackgroundColor3 = selected and Theme.Selected or Theme.Card,
                    Text = "",
                    BorderSizePixel = 0,
                    LayoutOrder = zoneIndex,
                    AutoButtonColor = false,
                    ZIndex = 101
                })
                AddCorner(ZoneButton, 5)
                Create("TextLabel", {
                    Parent = ZoneButton,
                    Position = UDim2.fromOffset(8, 0),
                    Size = UDim2.new(1, -34, 1, 0),
                    BackgroundTransparency = 1,
                    Text = zoneName,
                    TextColor3 = Theme.Text,
                    Font = Enum.Font.Gotham,
                    TextSize = 9,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 102
                })
                local Checkmark = Create("TextLabel", {
                    Parent = ZoneButton,
                    Position = UDim2.new(1, -26, 0, 0),
                    Size = UDim2.fromOffset(22, 24),
                    BackgroundTransparency = 1,
                    Text = selected and "✓" or "○",
                    TextColor3 = selected and Color3.fromRGB(110, 205, 145) or Theme.Gray,
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                    ZIndex = 102
                })
                ZoneButton.MouseButton1Click:Connect(function()
                    SelectedZones[zoneName] = not SelectedZones[zoneName] or nil
                    RefreshZoneList()
                    RefreshEggList()
                end)
            end
        end
        RefreshEggList = function()
            for _, item in ipairs(EggFilterList:GetChildren()) do
                if item:IsA("TextButton") or item:IsA("TextLabel") then item:Destroy() end
            end
            local records = GetEggRecords()
            local allSelected = #records > 0
            for _, record in ipairs(records) do
                if SelectedEggs[record.name] == false then allSelected = false break end
            end
            local SelectAllEggs = Create("TextButton", {
                Name = "SelectAllEggs", Parent = EggFilterList,
                Size = UDim2.new(1, -8, 0, 24),
                BackgroundColor3 = allSelected and Theme.Selected or Theme.Card,
                Text = "", BorderSizePixel = 0, LayoutOrder = 0,
                AutoButtonColor = false, ZIndex = 101
            })
            AddCorner(SelectAllEggs, 5)
            Create("TextLabel", {
                Parent = SelectAllEggs, Position = UDim2.fromOffset(8, 0),
                Size = UDim2.new(1, -34, 1, 0), BackgroundTransparency = 1,
                Text = allSelected and "All Eggs Selected" or "Select All",
                TextColor3 = Theme.Text, Font = Enum.Font.Gotham, TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 102
            })
            Create("TextLabel", {
                Parent = SelectAllEggs, Position = UDim2.new(1, -26, 0, 0),
                Size = UDim2.fromOffset(22, 24), BackgroundTransparency = 1,
                Text = allSelected and "✓" or "○",
                TextColor3 = allSelected and Color3.fromRGB(110, 205, 145) or Theme.Gray,
                Font = Enum.Font.GothamBold, TextSize = 12, ZIndex = 102
            })
            SelectAllEggs.MouseButton1Click:Connect(function()
                local selectEverything = not allSelected
                for _, record in ipairs(records) do
                    if selectEverything then SelectedEggs[record.name] = nil else SelectedEggs[record.name] = false end
                end
                RefreshEggList()
            end)
            if #records == 0 then
                Create("TextLabel", {
                    Parent = EggFilterList,
                    Size = UDim2.new(1, -8, 0, 28),
                    BackgroundTransparency = 1,
                    Text = "Select zones to view eggs",
                    TextColor3 = Theme.Gray,
                    Font = Enum.Font.Gotham,
                    TextSize = 9,
                    ZIndex = 102
                })
                return
            end
            for eggIndex, record in ipairs(records) do
                local eggName = record.name
                local selected = SelectedEggs[eggName] ~= false
                local EggButton = Create("TextButton", {
                    Name = "Egg_" .. eggName:gsub("[^%w_]", ""),
                    Parent = EggFilterList,
                    Size = UDim2.new(1, -8, 0, 24),
                    BackgroundColor3 = selected and Theme.Selected or Theme.Card,
                    Text = "",
                    BorderSizePixel = 0,
                    LayoutOrder = eggIndex,
                    AutoButtonColor = false,
                    ZIndex = 101
                })
                AddCorner(EggButton, 5)
                Create("TextLabel", {
                    Parent = EggButton,
                    Position = UDim2.fromOffset(8, 0),
                    Size = UDim2.new(1, -34, 1, 0),
                    BackgroundTransparency = 1,
                    Text = eggName,
                    TextColor3 = Theme.Text,
                    Font = Enum.Font.Gotham,
                    TextSize = 9,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 102
                })
                local Checkmark = Create("TextLabel", {
                    Parent = EggButton,
                    Position = UDim2.new(1, -26, 0, 0),
                    Size = UDim2.fromOffset(22, 24),
                    BackgroundTransparency = 1,
                    Text = selected and "✓" or "○",
                    TextColor3 = selected and Color3.fromRGB(110, 205, 145) or Theme.Gray,
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                    ZIndex = 102
                })
                EggButton.MouseButton1Click:Connect(function()
                    if SelectedEggs[eggName] == false then
                        SelectedEggs[eggName] = nil
                    else
                        SelectedEggs[eggName] = false
                    end
                    RefreshEggList()
                end)
            end
        end
        UpdateSortButtons()
        local TitanicPriorityEnabled = false
        local TitanicPriorityToggle = CreateToggle(Card1, "Titanic Priority", false, function(enabled)
            TitanicPriorityEnabled = enabled
            AddDebugLog("[Auto Break] TITANIC priority " .. (enabled and "ON" or "OFF"))
            if RefreshTitanicPriority then
                RefreshTitanicPriority()
            end
        end)
        SetAutoBreakControl(TitanicPriorityToggle, AutoBreakControlLayout.TitanicY)
        Card1.Size = UDim2.new(0.5, -6, 0, 190)
        AutoPickupCard.Size = UDim2.new(0.5, -6, 0, 316)
        AutoRow.Size = UDim2.new(1, 0, 0, 350)
        function UpdateFilterPanelWithTitanic()
            UpdateFilterPanel()
            HighestLuckToggle.Position = UDim2.fromOffset(0, 0)
            HighestLuckToggle.Size = UDim2.new(1, 0, 0, AutoBreakControlLayout.Height)
            SetAutoBreakControl(TitanicPriorityToggle, AutoBreakControlLayout.TitanicY)
        end
        ZoneFilterButton.MouseButton1Click:Connect(UpdateFilterPanelWithTitanic)
        EggFilterButton.MouseButton1Click:Connect(UpdateFilterPanelWithTitanic)
        RefreshZoneList()
        RefreshEggList()
        ZoneBuilds.ChildAdded:Connect(function()
            RefreshZoneList()
            RefreshEggList()
        end)
        ZoneBuilds.ChildRemoved:Connect(function()
            RefreshZoneList()
            RefreshEggList()
        end)
        ZoneLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            ZoneList.CanvasSize = UDim2.new(0, 0, 0, ZoneLayout.AbsoluteContentSize.Y + 8)
        end)
        EggLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            EggFilterList.CanvasSize = UDim2.new(0, 0, 0, EggLayout.AbsoluteContentSize.Y + 8)
        end)
        CurrentTarget = nil
        ArrivedAtTarget = false
        WaitingForPickup = false
        local MovementConnection
        local PickupMovementConnection
        local ReturnMovementConnection
        local BaselinePickups = {}
        PickupRequested = false
        ReturningAfterPickup = false
        local ActivePickup
        local LastAnimalPickupPosition
        local ActivePickupCPS = -1
        local PickupPhase = "IDLE"
        local PickupGeneration = 0
        local PendingAnimalPickups = {}
        local PendingAnimalPickupSet = {}
        local PendingAnimalPickupWorker = false
        local DroppedAnimalSignatures = {}
        local LastEggHPProgressAt = 0
        ScriptShuttingDown = false
        local AnimalFolderConnection
        local FlingRemoteConnection
        FlingRecoveryActive = false
        local FlingAnimalTarget
        local HandleFlingRecovery
        local CarriedAnimalWatch = {}
        local CancelFlingRecovery
        local LastAutomationProgressAt = os.clock()
        local AutomationProgressStage = "INITIALIZING"
        local AutomationWatchdogBusy = false
        TouchAutomationProgress = function(stage)
            if stage and stage ~= AutomationProgressStage then
                AutomationProgressStage = stage
                LastAutomationProgressAt = os.clock()
            elseif not stage then
                LastAutomationProgressAt = os.clock()
            end
        end
        function WaitForCharacterAndParts(timeout, isValid)
            local deadline = os.clock() + timeout
            while not Runtime.Stopped and not ScriptShuttingDown and os.clock() < deadline do
                if isValid and not isValid() then return nil end
                local character = LocalPlayer.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                local root = character and character:FindFirstChild("HumanoidRootPart")
                if character and humanoid and root then
                    return character, humanoid, root
                end
                task.wait(0.1)
            end
            return nil
        end
        function ParseWeightKg(value)
            if typeof(value) == "number" then
                return value
            end
            if value == nil then return nil end
            local textValue = tostring(value):gsub(",", ""):match("^%s*(.-)%s*$")
            if textValue == "" then return nil end
            local numberText, suffix = textValue:match("^([%d%.]+)%s*([%a]*)")
            local number = tonumber(numberText)
            if not number then return tonumber(textValue) end
            suffix = (suffix or ""):lower()
            local scales = {
                k = 1e3, m = 1e6, b = 1e9, t = 1e12,
                qa = 1e15, qi = 1e18, kg = 1
            }
            if suffix == "" then return number end
            local scale = scales[suffix]
            if scale then return number * scale end
            return nil
        end
        function GetPickupWeightKg(pickup)
            if not pickup then return nil end
            local animalPickups = workspace:FindFirstChild("AnimalPickups")
            local animal = pickup
            while animal and animalPickups and animal.Parent ~= animalPickups do
                animal = animal.Parent
            end
            if not animal or not animalPickups or animal.Parent ~= animalPickups then
                animal = pickup
            end
            local names = {"WeightKg", "WeightKG", "weightKg", "weightKG", "Weight", "weight"}
            for _, name in ipairs(names) do
                local weight = ParseWeightKg(animal:GetAttribute(name))
                if weight then return weight end
            end
            for _, node in ipairs(animal:GetDescendants()) do
                for _, name in ipairs(names) do
                    local weight = ParseWeightKg(node:GetAttribute(name))
                    if weight then return weight end
                    if node.Name == name then
                        if node:IsA("ValueBase") then
                            weight = ParseWeightKg(node.Value)
                            if weight then return weight end
                        elseif node:IsA("TextLabel") or node:IsA("TextButton") or node:IsA("TextBox") then
                            weight = ParseWeightKg(node.Text)
                            if weight then return weight end
                        end
                    end
                end
            end
            return nil
        end
        function IsKGFilterMatch(pickup)
            if KGThresholdAmount <= 0 then return false, nil end
            local weight = GetPickupWeightKg(pickup)
            local scale = 1
            if KGThresholdUnit == "K" then scale = 1e3
            elseif KGThresholdUnit == "M" then scale = 1e6
            elseif KGThresholdUnit == "B" then scale = 1e9
            elseif KGThresholdUnit == "T" then scale = 1e12
            elseif KGThresholdUnit == "Qa" then scale = 1e15
            elseif KGThresholdUnit == "Qi" then scale = 1e18 end
            local threshold = KGThresholdAmount * scale
            if not weight then
                AddDebugLog("[KG] " .. pickup.Name .. " weight not detected; threshold=" .. tostring(threshold) .. " KG.")
                return false, nil
            end
            local matches = weight >= threshold
            AddDebugLog("[KG] " .. pickup.Name .. " detected=" .. tostring(weight) .. " KG | minimum=" .. tostring(threshold) .. " KG | match=" .. tostring(matches))
            return matches, weight
        end
        function GetAnimalWeightKg(animal)
            if not animal then return nil end
            local names = {"WeightKg", "WeightKG", "weightKg", "weightKG", "Weight", "weight"}
            for _, name in ipairs(names) do
                local value = animal:GetAttribute(name)
                if value ~= nil then return tostring(value) end
            end
            for _, node in ipairs(animal:GetDescendants()) do
                for _, name in ipairs(names) do
                    local value = node:GetAttribute(name)
                    if value ~= nil then return tostring(value) end
                    if node.Name == name then
                        if node:IsA("ValueBase") then return tostring(node.Value) end
                        if (node:IsA("TextLabel") or node:IsA("TextButton") or node:IsA("TextBox")) and node.Text ~= "" then
                            return tostring(node.Text)
                        end
                    end
                end
            end
            return nil
        end
        local FlingTargetAnimalName
        local FlingTargetWeightKg
        local HitEventConnection
        local SetTrackerStatus
        function SetPickupPhase(phase, message)
            PickupPhase = phase
            TouchAutomationProgress("PICKUP:" .. tostring(phase))
            if message then SetTrackerStatus("PICKUP LOCK [" .. phase .. "]: " .. message) end
        end
        StopPickupAutomation = function(reason)
            PickupGeneration += 1
            PickupRequested = false
            ReturningAfterPickup = false
            ActivePickup = nil
            ActivePickupCPS = -1
            if CancelFlingRecovery then
                local cancelRecovery = CancelFlingRecovery
                CancelFlingRecovery = nil
                pcall(cancelRecovery)
            end
            FlingRecoveryActive = false
            TouchAutomationProgress("IDLE")
            if PickupMovementConnection then PickupMovementConnection:Disconnect(); PickupMovementConnection = nil end
            if ReturnMovementConnection then ReturnMovementConnection:Disconnect(); ReturnMovementConnection = nil end
            if MovementConnection then MovementConnection:Disconnect(); MovementConnection = nil end
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid:Move(Vector3.zero, false) end
            if SetTrackerStatus then SetTrackerStatus(tostring(reason) .. "; all pickup/return movement stopped.") end
        end
        CancelActiveAutomation = function(reason)
            if PickupRequested or ReturningAfterPickup or FlingRecoveryActive then
                StopPickupAutomation(reason or "Automation cancelled")
            end
            WaitingForPickup = false
            ArrivedAtTarget = false
            CurrentTarget = nil
            table.clear(PendingAnimalPickups)
            table.clear(PendingAnimalPickupSet)
            TouchAutomationProgress("IDLE")
        end
        ShutdownAutomation = function()
            ScriptShuttingDown = true
            PickupGeneration += 1
            PickupRequested = false
            ReturningAfterPickup = false
            ActivePickup = nil
            ActivePickupCPS = -1
            AutoBreakEnabled = false
            AutoPickupEnabled = false
            if MovementConnection then MovementConnection:Disconnect(); MovementConnection = nil end
            if PickupMovementConnection then PickupMovementConnection:Disconnect(); PickupMovementConnection = nil end
            if ReturnMovementConnection then ReturnMovementConnection:Disconnect(); ReturnMovementConnection = nil end
            if HitEventConnection then HitEventConnection:Disconnect(); HitEventConnection = nil end
            if FlingRemoteConnection then FlingRemoteConnection:Disconnect(); FlingRemoteConnection = nil end
            if AnimalFolderConnection then AnimalFolderConnection:Disconnect(); AnimalFolderConnection = nil end
            if CarriedAnimalWatch.childAdded then CarriedAnimalWatch.childAdded:Disconnect(); CarriedAnimalWatch.childAdded = nil end
            if CarriedAnimalWatch.childRemoved then CarriedAnimalWatch.childRemoved:Disconnect(); CarriedAnimalWatch.childRemoved = nil end
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid:Move(Vector3.zero, false) end
        end
        Runtime.Shutdown = function()
            if ShutdownAutomation then
                ShutdownAutomation()
            end
        end
        function ClearPickupLock(token)
            if token and token ~= PickupGeneration then return false end
            PickupRequested = false
            ActivePickup = nil
            ActivePickupCPS = -1
            PickupPhase = "IDLE"
            return true
        end
        local HitEvent = game:GetService("ReplicatedStorage"):WaitForChild("EggHitConfirmed")
        local AnimalPickups = workspace:FindFirstChild("AnimalPickups")
        local BaseReturnPosition = Vector3.new(-29.243687, 3.5, -14.755682)
        function EquipHotbarOne()
            local Players = game:GetService("Players")
            local currentPlayer = LocalPlayer or Players.LocalPlayer
            if not currentPlayer then
                SetTrackerStatus("Hotbar 1 select failed: LocalPlayer unavailable.")
                return false
            end

            local character = currentPlayer.Character
            if not character then
                local ok, result = pcall(function()
                    return currentPlayer.CharacterAdded:Wait()
                end)
                if ok then character = result end
            end
            if not character then
                SetTrackerStatus("Hotbar 1 select failed: character not loaded.")
                return false
            end

            local humanoid = character:FindFirstChildOfClass("Humanoid")
                or character:WaitForChild("Humanoid", 5)
            if not humanoid then
                SetTrackerStatus("Hotbar 1 select failed: Humanoid not ready.")
                return false
            end
            if humanoid.Health <= 0 then
                SetTrackerStatus("Hotbar 1 select failed: character is dead.")
                return false
            end

            if currentPlayer.Character ~= character or not character.Parent then
                SetTrackerStatus("Hotbar 1 select failed: character changed before selection.")
                return false
            end

            local ok, err = pcall(function()
                local virtualInput = game:GetService("VirtualInputManager")
                virtualInput:SendKeyEvent(true, Enum.KeyCode.One, false, game)
                task.wait(0.05)
                virtualInput:SendKeyEvent(false, Enum.KeyCode.One, false, game)
            end)
            if not ok then
                SetTrackerStatus("Hotbar 1 key selection failed: " .. tostring(err))
                return false
            end

            task.wait(0.15)
            SetTrackerStatus("Selected hotbar slot 1.")
            return true
        end
        local AnimalBankEquipConnections = {}
        function BindAnimalBankEquip(remote)
            if not remote:IsA("RemoteEvent") or AnimalBankEquipConnections[remote] then return end
            local remoteName = remote.Name:lower():gsub("[^%a]", "")
            if not remoteName:find("animalbank", 1, true) and not remoteName:find("bankanimal", 1, true) then return end
            AnimalBankEquipConnections[remote] = remote.OnClientEvent:Connect(function()
                task.delay(2, function()
                    if Runtime.Stopped then return end
                    SetTrackerStatus("Animal bank event received; equipping hotbar 1 after 2 seconds.")
                    EquipHotbarOne()
                end)
            end)
        end
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
            BindAnimalBankEquip(remote)
        end
        ReplicatedStorage.DescendantAdded:Connect(function(instance)
            BindAnimalBankEquip(instance)
        end)
        local PendingReturnAfterFling = false
        local PendingReturnAfterFlingReason = nil
        function ReturnToPickup(reason)
            if FlingRecoveryActive then
                PendingReturnAfterFling = true
                PendingReturnAfterFlingReason = reason or "Pickup confirmed. Returning to base."
                SetTrackerStatus("Return queued: waiting for fling recovery to release movement.")
                return
            end
            if ReturningAfterPickup then return end
            local useZoneDrop = DropInZone1Enabled == true
            ClearPickupLock()
            ReturningAfterPickup = true
            local returnToken = PickupGeneration
            TouchAutomationProgress("RETURNING_TO_BASE")
            SetTrackerStatus(reason or "Pickup hold completed. Returning to the pickup point.")
            task.spawn(function()
                local character, humanoid, root = WaitForCharacterAndParts(10, function()
                    return PickupGeneration == returnToken and ReturningAfterPickup
                end)
                if not character then
                    if PickupGeneration == returnToken then
                        ReturningAfterPickup = false
                        SetTrackerStatus("Return cancelled: character parts unavailable or return was cancelled.")
                        if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    end
                    return
                end
                SetTrackerStatus(useZoneDrop and "Moving to Zone 1 to drop the animal." or "Moving to static return position.")
                local moveStarted = os.clock()
                local lastReturnDistance = math.huge
                local connection
                connection = game:GetService("RunService").RenderStepped:Connect(function()
                    if PickupGeneration ~= returnToken then
                        connection:Disconnect()
                        if ReturnMovementConnection == connection then ReturnMovementConnection = nil end
                        connection = nil
                        return
                    end
                    if not ReturningAfterPickup or LocalPlayer.Character ~= character or not character.Parent or not root.Parent or humanoid.Health <= 0 then
                        humanoid:Move(Vector3.zero, false)
                        connection:Disconnect()
                        if ReturnMovementConnection == connection then ReturnMovementConnection = nil end
                        connection = nil
                        ReturningAfterPickup = false
                        SetTrackerStatus("Return movement stopped: character unavailable.")
                        if AutoBreakEnabled and StartAutoBreak then
                            task.delay(0.2, function()
                                if PickupGeneration == returnToken and AutoBreakEnabled and not PickupRequested and not ReturningAfterPickup then StartAutoBreak() end
                            end)
                        end
                        return
                    end
                    local destination = BaseReturnPosition
                    if useZoneDrop then
                        local build = workspace:FindFirstChild("Build")
                        local zoneBuilds = build and build:FindFirstChild("ZoneBuilds")
                        local zone1 = zoneBuilds and zoneBuilds:FindFirstChild("Zone1")
                        if not zone1 then
                            humanoid:Move(Vector3.zero, false)
                            connection:Disconnect()
                            connection = nil
                            ReturningAfterPickup = false
                            SetTrackerStatus("Drop in Zone 1 cancelled: workspace.Build.ZoneBuilds.Zone1 was not found.")
                            if AutoBreakEnabled and StartAutoBreak then task.delay(0.2, function()
                                if PickupGeneration == returnToken and AutoBreakEnabled and not PickupRequested and not ReturningAfterPickup then StartAutoBreak() end
                            end) end
                            return
                        end
                        if zone1:IsA("Model") then
                            destination = zone1:GetPivot().Position
                        elseif zone1:IsA("BasePart") then
                            destination = zone1.Position
                        else
                            local ok, pivot = pcall(function() return zone1:GetPivot() end)
                            if ok and pivot then destination = pivot.Position end
                        end
                    end
                    local offset = Vector3.new(destination.X - root.Position.X, 0, destination.Z - root.Position.Z)
                    if offset.Magnitude < lastReturnDistance - 0.5 then
                        lastReturnDistance = offset.Magnitude
                        TouchAutomationProgress()
                    end
                    if offset.Magnitude <= 4 then
                        TouchAutomationProgress(useZoneDrop and "RETURNING_TO_ZONE1:ARRIVED" or "RETURNING_TO_BASE:ARRIVED")
                        humanoid:Move(Vector3.zero, false)
                        connection:Disconnect()
                        connection = nil
                        if useZoneDrop then
                            task.spawn(function()
                                SetTrackerStatus("Reached Zone 1; requesting animal drop.")
                                local carriedFolder = workspace:FindFirstChild("CarriedAnimals")
                                local carriedBefore = CarriedAnimalWatch.model
                                local targetAnimal = FlingAnimalTarget or ActivePickup
                                local targetName = FlingTargetAnimalName or (targetAnimal and targetAnimal.Name)
                                local targetWeight = FlingTargetWeightKg
                                if targetWeight == nil and carriedBefore then targetWeight = GetAnimalWeightKg(carriedBefore) end
                                local signature
                                if targetAnimal then
                                    for _, key in ipairs({"AnimalId", "AnimalID", "UniqueId", "UUID", "Id"}) do
                                        local value = targetAnimal:GetAttribute(key)
                                        if value ~= nil and tostring(value) ~= "" then
                                            signature = "id:" .. tostring(value)
                                            break
                                        end
                                    end
                                    if not signature and targetWeight ~= nil and tostring(targetWeight) ~= "" then
                                        signature = "name:" .. targetAnimal.Name .. "|weight:" .. tostring(targetWeight)
                                    end
                                end
                                local targetRarity = targetAnimal and targetAnimal:GetAttribute("Rarity")
                                if targetRarity == nil and targetAnimal then
                                    local rarityNode = targetAnimal:FindFirstChild("Rarity", true)
                                    if rarityNode then
                                        if rarityNode:IsA("ValueBase") then targetRarity = rarityNode.Value
                                        elseif rarityNode:IsA("TextLabel") then targetRarity = rarityNode.Text end
                                    end
                                end
                                local dropRemote = ReplicatedStorage:FindFirstChild("DropCarriedRemote")
                                local fired, fireError = pcall(function()
                                    if not dropRemote then error("ReplicatedStorage.DropCarriedRemote was not found") end
                                    dropRemote:FireServer()
                                end)
                                if not fired then
                                    ReturningAfterPickup = false
                                    SetTrackerStatus("Zone 1 drop failed: " .. tostring(fireError))
                                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                                    return
                                end
                                local releaseDeadline = os.clock() + 4
                                local released = false
                                while not Runtime.Stopped and not ScriptShuttingDown and os.clock() < releaseDeadline do
                                    local currentFolder = workspace:FindFirstChild("CarriedAnimals")
                                    local currentModel = CarriedAnimalWatch.model
                                    if (carriedBefore and currentModel ~= carriedBefore)
                                        or (not currentModel and (not currentFolder or #currentFolder:GetChildren() == 0)) then
                                        released = true
                                        break
                                    end
                                    task.wait(0.1)
                                end
                                if released then
                                    if signature then DroppedAnimalSignatures[signature] = true end
                                    SetTrackerStatus("Zone 1 drop confirmed" .. (targetName and (": " .. targetName) or "") .. " | rarity=" .. tostring(targetRarity or "Unknown"))
                                else
                                    SetTrackerStatus("Zone 1 drop was requested, but release could not be confirmed.")
                                end
                                task.wait(0.2)
                                local equipped = EquipHotbarOne()
                                ReturningAfterPickup = false
                                if equipped then
                                    SetTrackerStatus(released and "Dropped in Zone 1; hotbar 1 equipped." or "Zone 1 drop unconfirmed; hotbar 1 equipped.")
                                end
                                if AutoBreakEnabled and StartAutoBreak then
                                    task.delay(0.2, function()
                                        if PickupGeneration == returnToken and AutoBreakEnabled and not PickupRequested and not ReturningAfterPickup then StartAutoBreak() end
                                    end)
                                end
                            end)
                        else
                            ReturningAfterPickup = false
                            SetTrackerStatus("Reached base; waiting 2 seconds before equipping hotbar 1.")
                            task.delay(2, function()
                                if not ScriptShuttingDown and PickupGeneration == returnToken and not PickupRequested and not ReturningAfterPickup and AutoPickupEnabled and LocalPlayer.Character == character then
                                    local equipped = EquipHotbarOne()
                                    if equipped then SetTrackerStatus("Returned to base; hotbar 1 tool equipped.") end
                                end
                            end)
                            if AutoBreakEnabled and StartAutoBreak then
                                task.delay(0.2, function()
                                    if PickupGeneration == returnToken and AutoBreakEnabled and not PickupRequested and not ReturningAfterPickup then StartAutoBreak() end
                                end)
                            end
                        end
                        return
                    end
                    if os.clock() - moveStarted >= 25 then
                        humanoid:Move(Vector3.zero, false)
                        connection:Disconnect()
                        connection = nil
                        ReturningAfterPickup = false
                        SetTrackerStatus("Return timed out; horizontal distance="
                            .. math.floor(offset.Magnitude) .. ".")
                        if AutoBreakEnabled and StartAutoBreak then
                            task.delay(0.2, function()
                                if PickupGeneration == returnToken and AutoBreakEnabled and not PickupRequested and not ReturningAfterPickup then StartAutoBreak() end
                            end)
                        end
                        return
                    end
                    humanoid:Move(offset.Unit, false)
                end)
                ReturnMovementConnection = connection
            end)
        end
        function IsTargetReference(reference, target)
            if typeof(reference) ~= "Instance" or typeof(target) ~= "Instance" then
                return false
            end
            return reference == target or reference:IsDescendantOf(target)
        end
        SetTrackerStatus = function(message)
            AddDebugLog("[Egg Tracker] " .. tostring(message))
        end
        HitEventConnection = HitEvent.OnClientEvent:Connect(function(eggReference, hitCounter, health)
            local target = CurrentTarget
            if not target or not IsTargetReference(eggReference, target) then
                return
            end
            local numericHealth = tonumber(health)
            if LastEggHPTarget ~= target or numericHealth ~= LastEggHPValue then
                LastEggHPTarget = target
                LastEggHPValue = numericHealth
                LastEggHPProgressAt = os.clock()
                TouchAutomationProgress()
            end
            SetTrackerStatus("MATCH | target=" .. target:GetFullName()
                .. " | counter=" .. tostring(hitCounter)
                .. " | health=" .. tostring(health))
            if numericHealth and numericHealth <= 0 then
                TouchAutomationProgress("EGG_BROKEN")
                CompletedEggs[target] = true
                WaitingForPickup = false
                ArrivedAtTarget = false
                if MovementConnection then MovementConnection:Disconnect(); MovementConnection = nil end
                local character = LocalPlayer.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                if humanoid and not PickupRequested and not ReturningAfterPickup then humanoid:Move(Vector3.zero, false) end
                SetTrackerStatus("Egg broken; Auto Break will continue while Auto Pickup monitors AnimalPickups.")
                task.defer(function()
                    task.wait(0.15)
                    if AutoBreakEnabled and not PickupRequested and not ReturningAfterPickup
                        and not FlingRecoveryActive and not ScriptShuttingDown and StartAutoBreak then
                        StartAutoBreak(true)
                    end
                end)
            end
        end)
        function GetPetRarity(pickup)
            if not pickup then return nil end

            local rootPart = pickup:FindFirstChild("RootPart")
            local attachment = rootPart and rootPart:FindFirstChild("AnimalOverheadAttachment")
            local overhead = attachment and attachment:FindFirstChild("AnimalOverhead")
            local rarity = overhead and overhead:FindFirstChild("Rarity")
            local label = rarity and rarity:FindFirstChild("RarityLabel")

            if label and (label:IsA("TextLabel") or label:IsA("TextButton")) then
                local value = label.Text
                if value and value ~= "" then
                    return value
                end
            end

            local rarityNode = pickup:FindFirstChild("Rarity", true)
            if rarityNode then
                if rarityNode:IsA("StringValue") then
                    return rarityNode.Value
                elseif rarityNode:IsA("TextLabel") or rarityNode:IsA("TextButton") then
                    return rarityNode.Text
                end
            end

            local attribute = pickup:GetAttribute("Rarity")
            return attribute and tostring(attribute) or nil
        end
        function GetPickupMutation(pickup)
            if not pickup then return "No Mutation" end
            local variant = pickup:GetAttribute("Variant")
            if variant ~= nil and tostring(variant) ~= "" then
                return "Mutated"
            end
            return "No Mutation"
        end
        function GetDroppedAnimalSignature(pickup, weight)
            if not pickup then return nil end
            for _, key in ipairs({"AnimalId", "AnimalID", "UniqueId", "UUID", "Id"}) do
                local value = pickup:GetAttribute(key)
                if value ~= nil and tostring(value) ~= "" then return "id:" .. tostring(value) end
            end
            if weight ~= nil and tostring(weight) ~= "" then
                return "name:" .. pickup.Name .. "|weight:" .. tostring(weight)
            end
            return nil
        end
        function IsRecentlyDroppedAnimal(pickup)
            if not pickup then return false end
            local signature = GetDroppedAnimalSignature(pickup, GetAnimalWeightKg(pickup))
            if signature and DroppedAnimalSignatures[signature] then
                DroppedAnimalSignatures[signature] = nil
                SetPickupTracking(pickup, "Skipped: just dropped in Zone 1")
                pickup:SetAttribute("BASAE_Rarity", tostring(GetPetRarity(pickup) or "Unknown"))
                SetTrackerStatus("Skipped recently dropped animal: " .. pickup.Name .. " | rarity=" .. tostring(GetPetRarity(pickup) or "Unknown"))
                return true
            end
            return false
        end
        function GetPickupZone(pickup)
            local zone = pickup:FindFirstChild("ZoneId", true)
            if zone and zone:IsA("ValueBase") then
                return tostring(zone.Value)
            end
            local attribute = pickup:GetAttribute("ZoneId")
            return attribute and tostring(attribute) or nil
        end
        function ParseCPS(display)
            if type(display) ~= "string" then return -1 end
            local cleaned = display:gsub(",", ""):gsub("%s+", ""):gsub("%$", "")
            cleaned = cleaned:gsub("/[sS]$", "")
            local numberText, suffix = cleaned:match("^([%d%.]+)([%a]*)$")
            local number = tonumber(numberText)
            local scales = {k=1e3, m=1e6, b=1e9, t=1e12, qa=1e15, q=1e15, qi=1e18}
            local scale = scales[(suffix or ""):lower()]
            if number and number >= 0 and (not suffix or suffix == "" or scale) then
                return number * (scale or 1)
            end
            return -1
        end
        function GetPetCPS(pickup)
            if not pickup or not pickup:IsA("Model") then
                return -1, "CPS unavailable: animal model missing"
            end
            local sawCPSNode = false
            local function readTextObject(object)
                if not object then return -1, nil end
                if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
                    local value = ParseCPS(object.Text)
                    if value >= 0 then return value, object.Text end
                end
                for _, childName in ipairs({"Text", "ContentText"}) do
                    local child = object:FindFirstChild(childName, true)
                    if child and (child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox")) then
                        local value = ParseCPS(child.Text)
                        if value >= 0 then return value, child.Text end
                    end
                end
                return -1, nil
            end
            local descendants = pickup:GetDescendants()
            for _, node in ipairs(descendants) do
                if node.Name == "CashPerSecond" then
                    sawCPSNode = true
                    local value, display = readTextObject(node)
                    if value >= 0 then return value, display end
                end
            end
            for _, node in ipairs(descendants) do
                if node.Name == "AnimalOverheadAttachment" or node.Name == "AnimalOverhead" then
                    local value, display = readTextObject(node:FindFirstChild("CashPerSecond", true))
                    if value >= 0 then return value, display end
                end
            end
            if sawCPSNode then
                return -1, "CPS unavailable: CashPerSecond exists but contains no readable numeric Text/ContentText"
            end
            return -1, "CPS unavailable: no CashPerSecond node found in animal model"
        end
        function IsRarityAllowed(pickup)
            local selectedCount = 0
            for _, selected in pairs(SelectedRarities) do
                if selected then selectedCount += 1 end
            end
            if selectedCount == 0 then return false end
            local rarity = GetPetRarity(pickup)
            if not rarity then
                SetTrackerStatus("Cannot filter " .. pickup.Name .. ": Rarity value not found.")
                return false
            end
            for selectedRarity, selected in pairs(SelectedRarities) do
                if selected and selectedRarity:lower() == rarity:lower() then
                    return true
                end
            end
            return false
        end
        function GetLowestPlacedCPS()
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
                            local value = GetPetCPS(animal)
                            if value >= 0 and value < lowest then lowest = value end
                        end
                    end
                    return lowest < math.huge and lowest or -1
                end
            end
            return -1
        end
        function RejectPickupAndRestart(message)
            if PickupRequested then
                SetTrackerStatus(message .. " | candidate rejected; active pickup remains in control.")
                return
            end
            if ReturningAfterPickup then
                SetTrackerStatus(message .. " | candidate rejected while returning to base.")
                return
            end
            local hadTarget = CurrentTarget ~= nil and CurrentTarget.Parent ~= nil
            if hadTarget and WaitingForPickup and IsEggConfirmedComplete(CurrentTarget) then
                CompletedEggs[CurrentTarget] = true
            end
            SetTrackerStatus(message .. (hadTarget and WaitingForPickup
                and " | rejected animal; releasing egg wait and resuming Auto Break."
                or " | rejected animal; checking whether Auto Break can resume."))
            task.defer(function()
                if StopAutoBreak then StopAutoBreak("Recovering after rejected animal.", CurrentTarget ~= nil and IsEggAvailable(CurrentTarget)) end
                task.wait(0.2)
                if AutoBreakEnabled and not PickupRequested and not ReturningAfterPickup and StartAutoBreak then
                    StartAutoBreak()
                end
            end)
        end
        function SetPickupTracking(pickup, status, cpsText)
            if not pickup or not pickup.Parent then return end
            pickup:SetAttribute("BASAE_CPSCheckStatus", tostring(status or "Not checked"))
            if cpsText ~= nil then
                pickup:SetAttribute("BASAE_CPSCheckValue", tostring(cpsText))
            end
            pickup:SetAttribute("BASAE_CPSCheckedAt", os.time())
        end
        function GetIndexNameLabel(animalName)
            local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            local mainGui = playerGui and playerGui:FindFirstChild("MainGUI")
            local frames = mainGui and mainGui:FindFirstChild("Frames")
            local index = frames and frames:FindFirstChild("Index")
            local indexList = index and index:FindFirstChild("IndexList")
            local scrollingFrame = indexList and indexList:FindFirstChild("ScrollingFrame")
            if not scrollingFrame then return nil end
            local wanted = tostring(animalName):lower():gsub("[%s_%-]", "")
            for _, zone in ipairs(scrollingFrame:GetChildren()) do
                local animalList = zone:FindFirstChild("AnimalList")
                if animalList then
                    for _, animalEntry in ipairs(animalList:GetChildren()) do
                        local entryName = animalEntry.Name:lower():gsub("[%s_%-]", "")
                        if entryName == wanted then
                            local inner = animalEntry:FindFirstChild("Inner")
                            local nameLabel = inner and inner:FindFirstChild("Name")
                            if nameLabel and (nameLabel:IsA("TextLabel") or nameLabel:IsA("TextButton")) then
                                return nameLabel
                            end
                        end
                    end
                end
            end
            return nil
        end
        function EvaluateUnindexedStatus(pickup)
            local label = GetIndexNameLabel(pickup.Name)
            for attempt = 1, 8 do
                if label and label.Parent then break end
                if not pickup.Parent or not AutoPickupEnabled then
                    return nil, "verification cancelled"
                end
                SetPickupTracking(pickup, string.format("Waiting for Index entry (%d/8)", attempt))
                task.wait(0.25)
                label = GetIndexNameLabel(pickup.Name)
            end
            if not label or not label.Parent then
                return nil, "Index entry unavailable"
            end
            local displayName = tostring(label.Text or ""):match("^%s*(.-)%s*$")
            if displayName == "???" then
                return true, displayName
            end
            if displayName == "" then
                return nil, "Index name is empty"
            end
            return false, displayName
        end
        function EvaluatePickup(pickup)
            local function evaluationCancelled()
                return ScriptShuttingDown or not AutoPickupEnabled or not pickup.Parent
            end
            pickup:SetAttribute("BASAE_Qualified", false)
            SetPickupTracking(pickup, "Checking")
            if evaluationCancelled() then
                SetPickupTracking(pickup, "Cancelled: automation toggled")
                return
            end
            if ReturningAfterPickup then
                SetPickupTracking(pickup, "Skipped: returning to base")
                SetTrackerStatus("Eligible pet " .. pickup.Name .. " ignored: already returning to base.")
                return
            end
            if IsRecentlyDroppedAnimal(pickup) then return end
            local zoneAllowed, pickupZoneName = IsPickupAllowedByZone(pickup)
            if not zoneAllowed then
                SetPickupTracking(pickup, "Rejected: outside selected pickup zones", tostring(pickupZoneName or "unknown zone"))
                RejectPickupAndRestart("Filtered out " .. pickup.Name .. " | zone " .. tostring(pickupZoneName or "unknown") .. " is not selected.")
                return
            end
            if not AutoPickupEnabled then
                SetPickupTracking(pickup, "Skipped: Auto Pickup OFF")
                if CurrentTarget and IsEggConfirmedComplete(CurrentTarget) then CompletedEggs[CurrentTarget] = true end
                WaitingForPickup = false
                SetTrackerStatus("New pet detected (Auto Pickup OFF): " .. pickup.Name .. " | checking current egg HP before selecting another.")
                task.defer(function()
                    if StopAutoBreak then StopAutoBreak("Auto Pickup is OFF; checking current egg HP.", CurrentTarget ~= nil and IsEggAvailable(CurrentTarget)) end
                    task.wait(0.2)
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                end)
                return
            end
            local forceUnindexedPickup = false
            if UnindexedOnlyEnabled then
                local isUnindexed, indexDisplay = EvaluateUnindexedStatus(pickup)
                if evaluationCancelled() then
                    SetPickupTracking(pickup, "Cancelled: automation toggled")
                    return
                end
                if isUnindexed == nil then
                    SetPickupTracking(pickup, "Rejected: Index verification unavailable", tostring(indexDisplay))
                    RejectPickupAndRestart("Filtered out " .. pickup.Name .. " | Index verification failed: " .. tostring(indexDisplay))
                    return
                elseif isUnindexed then
                    forceUnindexedPickup = true
                    SetPickupTracking(pickup, "Unindexed (???); bypassing filters", "???")
                else
                    SetPickupTracking(pickup, "Already indexed; applying normal filters", tostring(indexDisplay))
                end
            end
            local kgPriorityPickup, pickupWeightKg = false, nil
            local aboveLowestPriorityPickup = false
            local cpsPriorityPickup = false
            local rarityPriorityPickup = false
            local cps, cpsText = -1, "CPS skipped for unindexed animal"
            local pickupPriority = 5
            if not forceUnindexedPickup then
                kgPriorityPickup, pickupWeightKg = IsKGFilterMatch(pickup)
                if kgPriorityPickup then
                    SetPickupTracking(pickup, "KG threshold matched", tostring(pickupWeightKg) .. " KG")
                end
                rarityPriorityPickup = IsRarityAllowed(pickup)
                SetPickupTracking(pickup, "CPS scan 1/2: warming up")
                local _, firstScanText = GetPetCPS(pickup)
                if evaluationCancelled() or not pickup.Parent then
                    SetPickupTracking(pickup, "CPS verification cancelled", firstScanText)
                    return
                end
                task.wait(0.15)
                if evaluationCancelled() or not pickup.Parent then
                    SetPickupTracking(pickup, "CPS verification cancelled", firstScanText)
                    return
                end
                SetPickupTracking(pickup, "CPS scan 2/2: using this result")
                cps, cpsText = GetPetCPS(pickup)
                if cps < 0 then
                    for attempt = 1, 8 do
                        if evaluationCancelled() or not pickup.Parent then break end
                        SetPickupTracking(pickup, string.format("Waiting for valid second CPS scan (%d/8)", attempt), cpsText)
                        task.wait(0.25)
                        if evaluationCancelled() or not pickup.Parent then return end
                        cps, cpsText = GetPetCPS(pickup)
                        if cps >= 0 then break end
                    end
                end
                SetPickupTracking(pickup, cps >= 0 and "CPS checked (second scan)" or "CPS read failed", cpsText)
                if CPSFilter.amount > 0 and cps >= 0 then
                    local scales = {K = 1e3, M = 1e6, B = 1e9, T = 1e12}
                    local minimumCPS = CPSFilter.amount * (scales[CPSFilter.unit] or 1)
                    cpsPriorityPickup = cps >= minimumCPS
                end
                if HighestCashEnabled and cps >= 0 then
                    local lowestPlaced = GetLowestPlacedCPS()
                    aboveLowestPriorityPickup = lowestPlaced >= 0 and cps > lowestPlaced
                end
            end
            if evaluationCancelled() or not pickup.Parent then
                SetPickupTracking(pickup, "Cancelled: automation toggled")
                return
            end
            local selectedRarityCount = 0
            for _, selected in pairs(SelectedRarities) do
                if selected then selectedRarityCount += 1 end
            end
            local anyPickupFilterEnabled = UnindexedOnlyEnabled or HighestCashEnabled
                or KGThresholdAmount > 0 or CPSFilter.amount > 0 or selectedRarityCount > 0
            local mutationPickupMatch = PickUpWithMutationEnabled and GetPickupMutation(pickup) ~= "No Mutation"
            local qualified = not anyPickupFilterEnabled or forceUnindexedPickup
                or aboveLowestPriorityPickup or kgPriorityPickup or cpsPriorityPickup or rarityPriorityPickup
                or mutationPickupMatch
            if not qualified then
                local reason = "no enabled pickup rule matched"
                if HighestCashEnabled and cps < 0 then
                    reason = "CPS unavailable for Above Lowest $/s"
                elseif CPSFilter.amount > 0 and cps < 0 then
                    reason = "CPS unavailable for minimum CPS"
                elseif not rarityPriorityPickup then
                    reason = "rarity mismatch and no CPS/KG priority matched"
                end
                SetPickupTracking(pickup, "Rejected: " .. reason, cpsText)
                RejectPickupAndRestart("Filtered out " .. pickup.Name .. " | " .. reason .. ".")
                return
            end
            if forceUnindexedPickup then
                pickupPriority = 1
            elseif aboveLowestPriorityPickup then
                pickupPriority = 2
            elseif kgPriorityPickup then
                pickupPriority = 3
            elseif cpsPriorityPickup then
                pickupPriority = 4
            else
                pickupPriority = 5
            end
            pickup:SetAttribute("BASAE_Priority", pickupPriority)
            pickup:SetAttribute("BASAE_Qualified", true)
            if PickupRequested then
                local activePriority = ActivePickup and ActivePickup.Parent and (ActivePickup:GetAttribute("BASAE_Priority") or 5) or math.huge
                local activeWeight = ActivePickup and ActivePickup.Parent and GetPickupWeightKg(ActivePickup) or nil
                local shouldPreempt = pickupPriority < activePriority
                if pickupPriority == activePriority then
                    if pickupPriority == 2 or pickupPriority == 4 then
                        shouldPreempt = cps > ActivePickupCPS
                    elseif pickupPriority == 3 then
                        shouldPreempt = pickupWeightKg ~= nil and (activeWeight == nil or pickupWeightKg > activeWeight)
                    end
                end
                if shouldPreempt then
                    SetPickupTracking(pickup, "Replacing lower-priority pickup (priority " .. tostring(pickupPriority) .. ")", cpsText)
                    PickupGeneration += 1
                    PickupRequested = false
                    if PickupMovementConnection then
                        PickupMovementConnection:Disconnect()
                        PickupMovementConnection = nil
                    end
                    local oldPickupName = ActivePickup and ActivePickup.Name or "none"
                    SetTrackerStatus(string.format("PICKUP LOCK PREEMPT: %s (priority %d, %.2f CPS) replaces %s (priority %s, %.2f CPS) during phase %s.", pickup.Name, pickupPriority, cps, oldPickupName, tostring(activePriority), ActivePickupCPS, PickupPhase))
                    local oldCharacter = LocalPlayer.Character
                    local oldHumanoid = oldCharacter and oldCharacter:FindFirstChildOfClass("Humanoid")
                    if oldHumanoid then oldHumanoid:Move(Vector3.zero, false) end
                    task.wait()
                else
                    SetPickupTracking(pickup, "Checked: another pickup has priority", cpsText)
                    SetTrackerStatus(string.format("Eligible pet %s ignored while %s is locked (priority %s vs %d; CPS %.2f vs %.2f).", pickup.Name, tostring(ActivePickup and ActivePickup.Name or "another pickup"), tostring(activePriority), pickupPriority, cps, ActivePickupCPS))
                    return
                end
            end
            PickupGeneration += 1
            local pickupToken = PickupGeneration
            ActivePickup = pickup
            FlingAnimalTarget = pickup
            FlingTargetAnimalName = pickup.Name
            FlingTargetWeightKg = GetAnimalWeightKg(pickup)
            if FlingTargetWeightKg ~= nil then
                SetTrackerStatus("Pickup identity captured: " .. tostring(FlingTargetAnimalName) .. " | WeightKg=" .. tostring(FlingTargetWeightKg))
            end
            task.spawn(function()
                local identityDeadline = os.clock() + 12
                local identityAttempts = 0
                local lastIdentityLog = 0
                while not Runtime.Stopped and PickupGeneration == pickupToken
                    and ActivePickup == pickup and FlingTargetWeightKg == nil
                    and os.clock() < identityDeadline do
                    identityAttempts += 1
                    local identityFolder = workspace:FindFirstChild("AnimalPickups")
                    if identityFolder then
                        for _, candidate in ipairs(identityFolder:GetChildren()) do
                            if candidate == pickup and candidate.Name == FlingTargetAnimalName then
                                local identity = GetAnimalWeightKg(candidate)
                                if identity ~= nil then
                                    FlingTargetWeightKg = identity
                                    SetTrackerStatus("Captured pickup identity: " .. tostring(FlingTargetAnimalName) .. " | WeightKg=" .. tostring(identity) .. " | attempts=" .. tostring(identityAttempts))
                                    break
                                end
                            end
                        end
                    end
                    local now = os.clock()
                    if FlingTargetWeightKg == nil and now - lastIdentityLog >= 1 then
                        lastIdentityLog = now
                        SetTrackerStatus("Searching AnimalPickups | animal=" .. tostring(FlingTargetAnimalName) .. " | WeightKg=waiting | attempts=" .. tostring(identityAttempts))
                    end
                    if FlingTargetWeightKg == nil then task.wait(0.25) end
                end
                if FlingTargetWeightKg == nil and PickupGeneration == pickupToken then
                    SetTrackerStatus("Initial identity search timed out for " .. tostring(FlingTargetAnimalName) .. "; fling recovery will retry.")
                end
            end)
            ActivePickupCPS = cps
            ActivePickup:SetAttribute("BASAE_Priority", pickupPriority)
            PickupPhase = "ANIMAL_APPROACH"
            SetPickupTracking(pickup, "Selected for pickup", cpsText)
            PickupRequested = true
            task.delay(45, function()
                if Runtime.Stopped or PickupGeneration ~= pickupToken or not PickupRequested
                    or ReturningAfterPickup or ActivePickup ~= pickup then
                    return
                end
                SetTrackerStatus("PICKUP WATCHDOG: " .. pickup.Name .. " stayed locked for 45s; releasing stale lock and resuming Auto Break.")
                PickupGeneration += 1
                PickupRequested = false
                ActivePickup = nil
                ActivePickupCPS = -1
                PickupPhase = "IDLE"
                if PickupMovementConnection then PickupMovementConnection:Disconnect(); PickupMovementConnection = nil end
                if ReturnMovementConnection then ReturnMovementConnection:Disconnect(); ReturnMovementConnection = nil end
                if MovementConnection then MovementConnection:Disconnect(); MovementConnection = nil end
                local watchdogCharacter = LocalPlayer.Character
                local watchdogHumanoid = watchdogCharacter and watchdogCharacter:FindFirstChildOfClass("Humanoid")
                if watchdogHumanoid then watchdogHumanoid:Move(Vector3.zero, false) end
                WaitingForPickup = false
                ArrivedAtTarget = false
                task.spawn(function()
                    EquipHotbarOne()
                    task.wait(0.2)
                    if AutoBreakEnabled and not PickupRequested and not ReturningAfterPickup then
                        StartAutoBreak(true)
                    end
                end)
            end)
            if StopAutoBreak then StopAutoBreak("Auto Break paused while Auto Pickup handles " .. pickup.Name .. ".", CurrentTarget ~= nil and IsEggAvailable(CurrentTarget)) end
            if MovementConnection then MovementConnection:Disconnect(); MovementConnection = nil end
            local activeCharacter = LocalPlayer.Character
            local activeHumanoid = activeCharacter and activeCharacter:FindFirstChildOfClass("Humanoid")
            if activeHumanoid then activeHumanoid:Move(Vector3.zero, false) end
            SetPickupPhase("ANIMAL_APPROACH", string.format("%s | %.2f CPS | Auto Break paused; animal target owns movement.", pickup.Name, cps))
            local pickupPosition
            local positionOk, position = pcall(function()
                if pickup:IsA("Model") then return pickup:GetPivot().Position end
                if pickup:IsA("BasePart") then return pickup.Position end
            end)
            if positionOk then
                pickupPosition = position
                LastAnimalPickupPosition = position
            end
            local moveCharacter = LocalPlayer.Character
            local moveHumanoid = moveCharacter and moveCharacter:FindFirstChildOfClass("Humanoid")
            local moveRoot = moveCharacter and moveCharacter:FindFirstChild("HumanoidRootPart")
            if not pickupPosition or not moveHumanoid or not moveRoot then
                if PickupGeneration ~= pickupToken then return end
                PickupRequested = false
                ActivePickup = nil
                ActivePickupCPS = -1
                SetTrackerStatus("Pickup cancelled: animal location or character position unavailable.")
                if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                return
            end
            local animalMoveStarted = os.clock()
            local lastAnimalProgressAt = os.clock()
            local bestAnimalDistance = math.huge
            TouchAutomationProgress("PICKUP:ANIMAL_APPROACH")
            if PickupMovementConnection then
                PickupMovementConnection:Disconnect()
                PickupMovementConnection = nil
            end
            local animalMoveBindName = "BASAE_PickupAnimal_" .. tostring(pickupToken)
            RunService:BindToRenderStep(animalMoveBindName, Enum.RenderPriority.Character.Value + 1, function()
                if not PickupRequested or PickupGeneration ~= pickupToken or not pickup.Parent
                    or LocalPlayer.Character ~= moveCharacter or not moveRoot.Parent
                    or moveHumanoid.Health <= 0 then
                    moveHumanoid:Move(Vector3.zero, false)
                    return
                end
                local ok, currentPosition = pcall(function()
                    if pickup:IsA("Model") then return pickup:GetPivot().Position end
                    if pickup:IsA("BasePart") then return pickup.Position end
                end)
                if ok and currentPosition then
                    local direction = Vector3.new(currentPosition.X - moveRoot.Position.X, 0, currentPosition.Z - moveRoot.Position.Z)
                    if direction.Magnitude > 4 then
                        moveHumanoid:Move(direction.Unit, false)
                    else
                        moveHumanoid:Move(Vector3.zero, false)
                    end
                end
            end)
            local animalMoveConnection = {
                Disconnect = function()
                    pcall(function() RunService:UnbindFromRenderStep(animalMoveBindName) end)
                end
            }
            PickupMovementConnection = animalMoveConnection
            while not Runtime.Stopped and PickupRequested and PickupGeneration == pickupToken and pickup.Parent and moveHumanoid.Health > 0 do
                if LocalPlayer.Character ~= moveCharacter or not moveCharacter.Parent or not moveRoot.Parent then
                    if PickupGeneration ~= pickupToken then return end
                    PickupRequested = false
                    ActivePickup = nil
                    ActivePickupCPS = -1
                    SetTrackerStatus("Pickup cancelled: character changed while moving to animal.")
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    return
                end
                local ok, currentPosition = pcall(function()
                    if pickup:IsA("Model") then return pickup:GetPivot().Position end
                    if pickup:IsA("BasePart") then return pickup.Position end
                end)
                if ok and currentPosition then
                    pickupPosition = currentPosition
                    LastAnimalPickupPosition = currentPosition
                end
                local animalOffset = Vector3.new(pickupPosition.X - moveRoot.Position.X, 0, pickupPosition.Z - moveRoot.Position.Z)
                local animalDistance = animalOffset.Magnitude
                if animalDistance <= 4 then break end
                local now = os.clock()
                if now - animalMoveStarted >= 25 then
                    moveHumanoid:Move(Vector3.zero, false)
                    if PickupGeneration ~= pickupToken then return end
                    PickupRequested = false
                    ActivePickup = nil
                    ActivePickupCPS = -1
                    SetTrackerStatus(string.format("Pickup cancelled: timed out reaching animal location (%.1f studs away).", animalDistance))
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    return
                end
                if animalDistance < bestAnimalDistance - 0.75 then
                    bestAnimalDistance = animalDistance
                    lastAnimalProgressAt = now
                    TouchAutomationProgress()
                elseif now - lastAnimalProgressAt >= 2.5 then
                    lastAnimalProgressAt = now
                    bestAnimalDistance = animalDistance
                    moveHumanoid:Move(Vector3.zero, false)
                    task.wait(0.05)
                    if PickupRequested and PickupGeneration == pickupToken and pickup.Parent
                        and LocalPlayer.Character == moveCharacter and moveRoot.Parent and moveHumanoid.Health > 0 then
                        local refreshedPosition
                        local refreshedOk, refreshed = pcall(function()
                            if pickup:IsA("Model") then return pickup:GetPivot().Position end
                            if pickup:IsA("BasePart") then return pickup.Position end
                        end)
                        if refreshedOk then refreshedPosition = refreshed end
                        if refreshedPosition then
                            local refreshedDirection = Vector3.new(
                                refreshedPosition.X - moveRoot.Position.X, 0,
                                refreshedPosition.Z - moveRoot.Position.Z
                            )
                            if refreshedDirection.Magnitude > 4 then
                                moveHumanoid:Move(refreshedDirection.Unit, false)
                            end
                        end
                    end
                    SetTrackerStatus(string.format("PICKUP MOVEMENT: reset and reinitialized movement toward %s (%.1f studs).", pickup.Name, animalDistance))
                end
                task.wait(0.05)
            end
            if PickupMovementConnection == animalMoveConnection then
                PickupMovementConnection:Disconnect()
                PickupMovementConnection = nil
            end
            if animalMoveConnection then animalMoveConnection:Disconnect(); animalMoveConnection = nil end
            moveHumanoid:Move(Vector3.zero, false)
            if PickupGeneration ~= pickupToken then return end
            if not PickupRequested or not pickup.Parent or not pickupPosition then
                PickupRequested = false
                ActivePickup = nil
                ActivePickupCPS = -1
                SetTrackerStatus("Pickup cancelled: animal disappeared before location verification.")
                if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                return
            end
            local verifiedAnimalDistance = (Vector3.new(pickupPosition.X, moveRoot.Position.Y, pickupPosition.Z) - moveRoot.Position).Magnitude
            if verifiedAnimalDistance > 5 then
                PickupRequested = false
                ActivePickup = nil
                ActivePickupCPS = -1
                SetTrackerStatus(string.format("Pickup cancelled: animal location verification failed (%.1f studs).", verifiedAnimalDistance))
                if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                return
            end
            SetPickupPhase("PROMPT_SEARCH", string.format("%s | animal reached (%.1f studs); finding its nearest matching StealPrompt.", pickup.Name, verifiedAnimalDistance))
            local prompt
            local promptState = "StealPrompt not found"
            local promptDeadline = os.clock() + 5
            local promptMatchRadius = 18
            local function getPromptPosition(candidate)
                local parent = candidate and candidate.Parent
                while parent and parent ~= workspace do
                    if parent:IsA("Attachment") then
                        return parent.WorldPosition
                    elseif parent:IsA("BasePart") then
                        return parent.Position
                    elseif parent:IsA("Model") then
                        local ok, pivot = pcall(function() return parent:GetPivot() end)
                        if ok and pivot then return pivot.Position end
                    end
                    parent = parent.Parent
                end
                return nil
            end
            repeat
                if PickupGeneration ~= pickupToken then return end
                prompt = nil
                local nearestDistance = math.huge
                local totalStealPrompts = 0
                local enabledStealPrompts = 0
                for _, candidate in ipairs(workspace:GetDescendants()) do
                    if candidate:IsA("ProximityPrompt") and candidate.Name == "StealPrompt" then
                        totalStealPrompts += 1
                        if candidate.Enabled then
                            enabledStealPrompts += 1
                            local candidatePosition = getPromptPosition(candidate)
                            if candidatePosition then
                                local distance = (candidatePosition - pickupPosition).Magnitude
                                if distance < nearestDistance and distance <= promptMatchRadius then
                                    nearestDistance = distance
                                    prompt = candidate
                                end
                            end
                        end
                    end
                end
                if prompt then
                    promptState = string.format("nearest enabled StealPrompt: %s (%.2f studs from animal; found %d total/%d enabled)", prompt:GetFullName(), nearestDistance, totalStealPrompts, enabledStealPrompts)
                else
                    promptState = string.format("No enabled StealPrompt within %.0f studs of animal (found %d total/%d enabled)", promptMatchRadius, totalStealPrompts, enabledStealPrompts)
                end
                if prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled then
                    break
                end
                task.wait(0.25)
            until os.clock() >= promptDeadline
            if PickupGeneration ~= pickupToken then return end
            if not prompt or not prompt:IsA("ProximityPrompt") or not prompt.Enabled then
                PickupRequested = false
                ActivePickup = nil
                ActivePickupCPS = -1
                SetTrackerStatus("Eligible pet " .. pickup.Name
                    .. " but pickup prompt unavailable after 5s: " .. promptState .. ".")
                task.delay(2, function()
                    if pickup.Parent and AutoPickupEnabled then PickupMonitorSeen[pickup] = nil end
                end)
                if AutoBreakEnabled and StartAutoBreak then StartAutoBreak(true) end
                return
            end
            SetPickupPhase("PROMPT_APPROACH", pickup.Name .. " | moving to matching StealPrompt; target and movement remain locked.")
            task.spawn(function()
                SetPickupPhase("PROMPT_APPROACH", "Lock held by " .. pickup.Name .. "; moving to its matching prompt.")
                local character, humanoid, root = WaitForCharacterAndParts(10, function()
                    return PickupRequested and PickupGeneration == pickupToken and AutoPickupEnabled
                end)
                if not character then
                    if PickupGeneration == pickupToken then
                        PickupRequested = false
                        ActivePickup = nil
                        ActivePickupCPS = -1
                        SetTrackerStatus("Pickup cancelled: character parts unavailable while approaching prompt.")
                        if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    end
                    return
                end
                local promptPosition = getPromptPosition(prompt)
                if not promptPosition then
                    PickupRequested = false
                    SetTrackerStatus("Pickup cancelled: could not read matched prompt position.")
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    return
                end
                local moveStarted = os.clock()
                local lastPromptProgressAt = os.clock()
                local bestPromptDistance = math.huge
                TouchAutomationProgress("PICKUP:PROMPT_APPROACH")
                if PickupMovementConnection then
                    PickupMovementConnection:Disconnect()
                    PickupMovementConnection = nil
                end
                local promptMoveBindName = "BASAE_PickupPrompt_" .. tostring(pickupToken)
                RunService:BindToRenderStep(promptMoveBindName, Enum.RenderPriority.Character.Value + 1, function()
                    if not PickupRequested or PickupGeneration ~= pickupToken or not pickup.Parent or not prompt.Parent
                        or LocalPlayer.Character ~= character or not root.Parent or humanoid.Health <= 0 then
                        humanoid:Move(Vector3.zero, false)
                        return
                    end
                    local livePosition = getPromptPosition(prompt)
                    if livePosition then promptPosition = livePosition end
                    local direction = Vector3.new(promptPosition.X - root.Position.X, 0, promptPosition.Z - root.Position.Z)
                    local verticalOffset = math.abs(promptPosition.Y - root.Position.Y)
                    local activationRange = math.max(0, prompt.MaxActivationDistance)
                    local horizontalReach = verticalOffset < activationRange
                        and math.sqrt(math.max(0, activationRange * activationRange - verticalOffset * verticalOffset)) - 0.5
                        or 0
                    local stopDistance = math.max(1, horizontalReach)
                    if direction.Magnitude > stopDistance then
                        humanoid:Move(direction.Unit, false)
                    else
                        humanoid:Move(Vector3.zero, false)
                    end
                end)
                local promptMoveConnection = {
                    Disconnect = function()
                        pcall(function() RunService:UnbindFromRenderStep(promptMoveBindName) end)
                    end
                }
                PickupMovementConnection = promptMoveConnection
                while not Runtime.Stopped and PickupRequested and PickupGeneration == pickupToken and pickup.Parent and prompt.Parent and humanoid.Health > 0 do
                    if LocalPlayer.Character ~= character or not character.Parent or not root.Parent then
                        if PickupGeneration ~= pickupToken then return end
                        PickupRequested = false
                        ActivePickup = nil
                        ActivePickupCPS = -1
                        SetTrackerStatus("Pickup cancelled: character changed while moving to animal prompt.")
                        if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                        return
                    end
                    promptPosition = getPromptPosition(prompt) or promptPosition
                    local offset = Vector3.new(promptPosition.X - root.Position.X, 0, promptPosition.Z - root.Position.Z)
                    local promptDistance = offset.Magnitude
                    local verticalOffset = math.abs(promptPosition.Y - root.Position.Y)
                    local activationRange = math.max(0, prompt.MaxActivationDistance)
                    local horizontalReach = verticalOffset < activationRange
                        and math.sqrt(math.max(0, activationRange * activationRange - verticalOffset * verticalOffset)) - 0.5
                        or 0
                    local stopDistance = math.max(1, horizontalReach)
                    if promptDistance <= stopDistance then break end
                    local now = os.clock()
                    if now - moveStarted >= 25 then
                        humanoid:Move(Vector3.zero, false)
                        if PickupGeneration ~= pickupToken then return end
                        PickupRequested = false
                        ActivePickup = nil
                        ActivePickupCPS = -1
                        SetTrackerStatus(string.format("Pickup cancelled: timed out reaching animal prompt (%.1f studs away).", promptDistance))
                        if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                        return
                    end
                    if promptDistance < bestPromptDistance - 0.75 then
                        bestPromptDistance = promptDistance
                        lastPromptProgressAt = now
                        TouchAutomationProgress()
                    elseif now - lastPromptProgressAt >= 2.5 then
                        lastPromptProgressAt = now
                        bestPromptDistance = promptDistance
                        humanoid:Move(Vector3.zero, false)
                        task.wait(0.05)
                        if PickupRequested and PickupGeneration == pickupToken and pickup.Parent and prompt.Parent
                            and LocalPlayer.Character == character and root.Parent and humanoid.Health > 0 then
                            local refreshedPromptPosition = getPromptPosition(prompt)
                            if refreshedPromptPosition then promptPosition = refreshedPromptPosition end
                            local refreshedOffset = Vector3.new(
                                promptPosition.X - root.Position.X, 0,
                                promptPosition.Z - root.Position.Z
                            )
                            local refreshedVerticalOffset = math.abs(promptPosition.Y - root.Position.Y)
                            local refreshedRange = math.max(0, prompt.MaxActivationDistance)
                            local refreshedReach = refreshedVerticalOffset < refreshedRange
                                and math.sqrt(math.max(0, refreshedRange * refreshedRange - refreshedVerticalOffset * refreshedVerticalOffset)) - 0.5
                                or 0
                            if refreshedOffset.Magnitude > math.max(1, refreshedReach) then
                                humanoid:Move(refreshedOffset.Unit, false)
                            end
                        end
                        SetTrackerStatus(string.format("PICKUP MOVEMENT: reset and reinitialized movement toward StealPrompt (%.1f studs).", promptDistance))
                    end
                    task.wait(0.05)
                end
                if PickupMovementConnection == promptMoveConnection then
                    PickupMovementConnection:Disconnect()
                    PickupMovementConnection = nil
                end
                if promptMoveConnection then promptMoveConnection:Disconnect(); promptMoveConnection = nil end
                humanoid:Move(Vector3.zero, false)
                if PickupGeneration ~= pickupToken then return end
                if not PickupRequested or not pickup.Parent then
                    PickupRequested = false
                    ActivePickup = nil
                    ActivePickupCPS = -1
                    SetTrackerStatus("Pickup cancelled: animal disappeared before reaching its prompt.")
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    return
                end
                SetPickupPhase("ACTIVATING", "Reached " .. pickup.Name .. "'s matching StealPrompt; activating immediately when the prompt is ready.")
                if PickupGeneration ~= pickupToken then return end
                if LocalPlayer.Character ~= character or not character.Parent or humanoid.Health <= 0 or not root.Parent then
                    PickupRequested = false
                    ActivePickup = nil
                    ActivePickupCPS = -1
                    SetTrackerStatus("Pickup cancelled: character changed or became unavailable.")
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    return
                end
                if not PickupRequested or not pickup.Parent then
                    PickupRequested = false
                    ActivePickup = nil
                    ActivePickupCPS = -1
                    SetTrackerStatus("Pickup cancelled: animal disappeared before activation.")
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    return
                end
                if PickupGeneration ~= pickupToken then return end
                if not prompt.Parent or not prompt.Enabled then
                    PickupRequested = false
                    ActivePickup = nil
                    ActivePickupCPS = -1
                    SetTrackerStatus("Pickup cancelled: StealPrompt became unavailable before activation.")
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    return
                end
                local latestPromptPosition = getPromptPosition(prompt)
                local latestPromptDistance = latestPromptPosition and (latestPromptPosition - root.Position).Magnitude or math.huge
                if not prompt.Parent or not prompt.Enabled or latestPromptDistance > math.max(4, prompt.MaxActivationDistance) then
                    PickupRequested = false
                    ActivePickup = nil
                    ActivePickupCPS = -1
                    SetTrackerStatus(string.format("Pickup cancelled: prompt range changed before activation (%.1f studs).", latestPromptDistance))
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    return
                end
                local pickupConfirmed = false
                local activationErrors = {}
                local activationDeadline = os.clock() + 15
                local activationAttempt = 0
                while not pickupConfirmed and os.clock() < activationDeadline do
                    if PickupGeneration ~= pickupToken or not PickupRequested or not AutoPickupEnabled then return end
                    if not pickup.Parent then pickupConfirmed = true; break end
                    if not prompt.Parent or not prompt.Enabled then
                        task.wait(0.25)
                    else
                        activationAttempt += 1
                        local currentPromptPosition = getPromptPosition(prompt)
                        local currentPromptDistance = currentPromptPosition and (currentPromptPosition - root.Position).Magnitude or math.huge
                        if currentPromptDistance <= prompt.MaxActivationDistance then
                            local holdOk, holdErr = pcall(function()
                                if typeof(fireproximityprompt) == "function" then
                                    fireproximityprompt(prompt)
                                    if prompt.HoldDuration > 0 then task.wait(prompt.HoldDuration + 0.15) end
                                else
                                    prompt:InputHoldBegin()
                                    task.wait(prompt.HoldDuration + 0.1)
                                    prompt:InputHoldEnd()
                                end
                            end)
                            if not holdOk then
                                table.insert(activationErrors, tostring(holdErr))
                                pcall(function() prompt:InputHoldEnd() end)
                            end
                            local confirmDeadline = os.clock() + 0.75
                            while not Runtime.Stopped and os.clock() < confirmDeadline
                                and PickupGeneration == pickupToken and PickupRequested and pickup.Parent do
                                task.wait(0.05)
                            end
                            if not pickup.Parent then pickupConfirmed = true
                            elseif activationAttempt == 1 or activationAttempt % 3 == 0 then
                                SetTrackerStatus("StealPrompt still unchecked for " .. pickup.Name .. "; retry " .. tostring(activationAttempt) .. ".")
                            end
                        else
                            SetTrackerStatus(string.format("Waiting for StealPrompt range for %s (%.1f/%.1f studs).",
                                pickup.Name, currentPromptDistance, prompt.MaxActivationDistance))
                            task.wait(0.25)
                        end
                    end
                    if not pickupConfirmed then task.wait(0.2) end
                end
                if PickupGeneration ~= pickupToken then return end
                if not pickupConfirmed then
                    PickupRequested = false
                    ActivePickup = nil
                    ActivePickupCPS = -1
                    PickupPhase = "IDLE"
                    local detail = #activationErrors > 0 and (" Activation error: " .. table.concat(activationErrors, " | ")) or ""
                    SetPickupTracking(pickup, "Retry timeout: steal not confirmed", detail)
                    SetTrackerStatus("StealPrompt retry window expired for " .. pickup.Name .. "; released pickup lock." .. detail)
                    PickupMonitorSeen[pickup] = nil
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak(true) end
                    return
                end
                SetPickupTracking(pickup, "Collected", cpsText)
                SetPickupPhase("CONFIRMED", "Collected " .. pickup.Name .. "; releasing target lock and returning to base.")
                ActivePickup = nil
                ActivePickupCPS = -1
                ReturnToPickup("Pickup confirmed. Returning straight to base.")
            end)
        end
        function QueuePendingAnimalPickup(pickup)
            if not pickup or not pickup.Parent or PendingAnimalPickupSet[pickup] then return end
            PendingAnimalPickupSet[pickup] = true
            table.insert(PendingAnimalPickups, pickup)
            SetTrackerStatus("NEW ANIMAL queued: " .. pickup.Name .. " | current pickup/return lock is active; will evaluate when movement is released.")
            if PendingAnimalPickupWorker then return end
            PendingAnimalPickupWorker = true
            task.spawn(function()
                while not Runtime.Stopped and AutoPickupEnabled and #PendingAnimalPickups > 0 do
                    if not PickupRequested and not ReturningAfterPickup and not FlingRecoveryActive then
                        local nextPickup = table.remove(PendingAnimalPickups, 1)
                        PendingAnimalPickupSet[nextPickup] = nil
                        if nextPickup and nextPickup.Parent then
                            local ok, err = xpcall(function()
                                EvaluatePickup(nextPickup)
                            end, debug.traceback)
                            if not ok then
                                SetTrackerStatus("Queued pickup evaluation failed for " .. tostring(nextPickup.Name) .. ": " .. tostring(err):gsub("[%r\n]+", " "):sub(1, 180))
                            end
                            task.wait(0.25)
                        else
                            task.wait()
                        end
                    else
                        task.wait(0.5)
                    end
                end
                PendingAnimalPickupWorker = false
            end)
        end
        function BindAnimalPickups(folder)
            if not folder or not folder:IsA("Folder") and not folder:IsA("Model") then return end
            AnimalPickups = folder
            folder.ChildAdded:Connect(function(pickup)
                PickupMonitorSeen[pickup] = nil
                local pickupRarity = tostring(GetPetRarity(pickup) or "Unknown")
                SetPickupTracking(pickup, "Detected")
                pickup:SetAttribute("BASAE_Rarity", pickupRarity)
                if not AutoPickupEnabled then
                    SetTrackerStatus("NEW ANIMAL: " .. pickup.Name .. " | rarity=" .. pickupRarity .. " | monitoring waits until Auto Pickup is ON.")
                    return
                end
                PickupMonitorSeen[pickup] = true
                QueuePendingAnimalPickup(pickup)
            end)
            folder.ChildRemoved:Connect(function(pickup)
                PickupMonitorSeen[pickup] = nil
                PendingAnimalPickupSet[pickup] = nil
            end)
            SetTrackerStatus("AnimalPickups folder detected; continuous monitoring is ready.")
        end
        if AnimalPickups then BindAnimalPickups(AnimalPickups) end
        task.spawn(function()
            while not Runtime.Stopped and not ScriptShuttingDown do
                if AutoPickupEnabled and AnimalPickups and AnimalPickups.Parent then
                    for _, pickup in ipairs(AnimalPickups:GetChildren()) do
                        if pickup.Parent == AnimalPickups and not PickupMonitorSeen[pickup] then
                            PickupMonitorSeen[pickup] = true
                            QueuePendingAnimalPickup(pickup)
                        end
                    end
                end
                task.wait(0.3)
            end
        end)
        local CatchFlingRemote = game:GetService("ReplicatedStorage"):WaitForChild("CatchFlingRemote")
        HandleFlingRecovery = function(action, flingPosition, duration, strength, carriedAnimalLost)
            if tostring(action):lower() ~= "fling" then return end
            if AntiPaloEnabled and not carriedAnimalLost then
                local released, releaseError = pcall(function()
                    if type(firesignal) ~= "function" then
                        error("firesignal is unavailable in this executor")
                    end
                    firesignal(CatchFlingRemote.OnClientEvent, "release")
                end)
                if released then
                    AddDebugLog("[Anti Knockback] Fling release signal fired.")
                else
                    AddDebugLog("[Anti Knockback] Fling release failed: " .. tostring(releaseError))
                end
            end
            if not AutoPickupEnabled then
                SetTrackerStatus("Fling detected: recovery cancelled because Auto Pickup is OFF.")
                return
            end
            if FlingRecoveryActive then
                SetTrackerStatus("Fling recovery event received while recovery is active; ignoring duplicate trigger.")
                return
            end
            if carriedAnimalLost and not ReturningAfterPickup and not PickupRequested then return end
            if not carriedAnimalLost and not CarriedAnimalWatch.model and not ReturningAfterPickup and not PickupRequested then
                SetTrackerStatus("Fling event ignored: no active animal pickup or carried animal.")
                return
            end
            local flingAnimal = ActivePickup or FlingAnimalTarget
            local targetAnimalName = (flingAnimal and flingAnimal.Name) or FlingTargetAnimalName
            local targetWeightKg = FlingTargetWeightKg
            if not targetAnimalName then
                SetTrackerStatus("Fling recovery skipped: tracked animal name is unavailable.")
                return
            end
            local function findTrackedAnimal()
                local folder = workspace:FindFirstChild("AnimalPickups")
                if not folder or not targetAnimalName then return nil end

                local targetWeight = ParseWeightKg(targetWeightKg)
                if flingAnimal and flingAnimal.Parent == folder and flingAnimal.Name == targetAnimalName then
                    local liveWeight = ParseWeightKg(GetAnimalWeightKg(flingAnimal))
                    if targetWeight == nil or liveWeight == nil or math.abs(liveWeight - targetWeight) <= math.max(0.001, math.abs(targetWeight) * 0.000001) then
                        return flingAnimal
                    end
                end

                local character = LocalPlayer.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                local bestMatch, bestDistance
                local nearestNameMatch, nearestNameDistance
                local hasReadableWeight = false

                for _, candidate in ipairs(folder:GetChildren()) do
                    if candidate.Name == targetAnimalName then
                        local candidateWeight = ParseWeightKg(GetAnimalWeightKg(candidate))
                        local ok, position = pcall(function()
                            if candidate:IsA("Model") then return candidate:GetPivot().Position end
                            if candidate:IsA("BasePart") then return candidate.Position end
                        end)
                        if ok and position then
                            local distance = root and (position - root.Position).Magnitude or 0
                            if not nearestNameDistance or distance < nearestNameDistance then
                                nearestNameMatch, nearestNameDistance = candidate, distance
                            end
                            if candidateWeight ~= nil then
                                hasReadableWeight = true
                            end
                            if targetWeight ~= nil and candidateWeight ~= nil then
                                local tolerance = math.max(0.001, math.abs(targetWeight) * 0.000001)
                                if math.abs(candidateWeight - targetWeight) <= tolerance then
                                    if not bestDistance or distance < bestDistance then
                                        bestMatch, bestDistance = candidate, distance
                                    end
                                end
                            end
                        end
                    end
                end

                if bestMatch then
                    flingAnimal = bestMatch
                    return bestMatch
                end
                if targetWeight ~= nil and hasReadableWeight then
                    return nil
                end
                if nearestNameMatch then flingAnimal = nearestNameMatch end
                return nearestNameMatch
            end
            local function getTrackedAnimalPosition()
                local animal = findTrackedAnimal()
                if not animal then return nil end
                local ok, position = pcall(function()
                    if animal:IsA("Model") then return animal:GetPivot().Position end
                    if animal:IsA("BasePart") then return animal.Position end
                end)
                return ok and position or nil
            end

            if ReturnMovementConnection then
                ReturnMovementConnection:Disconnect()
                ReturnMovementConnection = nil
            end
            if PickupMovementConnection then
                PickupMovementConnection:Disconnect()
                PickupMovementConnection = nil
            end
            if MovementConnection then
                MovementConnection:Disconnect()
                MovementConnection = nil
            end
            ReturningAfterPickup = false
            local interruptedCharacter = LocalPlayer.Character
            local interruptedHumanoid = interruptedCharacter and interruptedCharacter:FindFirstChildOfClass("Humanoid")
            if interruptedHumanoid then interruptedHumanoid:Move(Vector3.zero, false) end

            FlingRecoveryActive = true
            local recoverySearchToken = PickupGeneration
            TouchAutomationProgress("FLING_RECOVERY:FIND_DROPPED_ANIMAL")
            if not FlingRecoveryActive or PickupGeneration ~= recoverySearchToken then
                return
            end
            if PickupMovementConnection then PickupMovementConnection:Disconnect(); PickupMovementConnection = nil end
            if MovementConnection then MovementConnection:Disconnect(); MovementConnection = nil end
            if ReturnMovementConnection then ReturnMovementConnection:Disconnect(); ReturnMovementConnection = nil end
            ReturningAfterPickup = false
            PickupGeneration += 1
            local flingToken = PickupGeneration
            ActivePickup = nil
            ActivePickupCPS = -1
            PickupRequested = true
            if StopAutoBreak then StopAutoBreak("Auto Break paused for fling recovery.", CurrentTarget ~= nil and IsEggAvailable(CurrentTarget)) end
            if MovementConnection then MovementConnection:Disconnect(); MovementConnection = nil end
            SetTrackerStatus("Base return paused. FLING RECOVERY locating dropped " .. tostring(targetAnimalName) .. " in AnimalPickups.")
            task.spawn(function()
                local recoveryMoveBindName
                local recoveryHumanoid
                local originalAutoRotate
                local function cleanupFlingRecovery()
                    if recoveryHumanoid and recoveryHumanoid.Parent and originalAutoRotate ~= nil then
                        recoveryHumanoid.AutoRotate = originalAutoRotate
                        originalAutoRotate = nil
                    end
                    if recoveryMoveBindName then
                        pcall(function()
                            game:GetService("RunService"):UnbindFromRenderStep(recoveryMoveBindName)
                        end)
                        recoveryMoveBindName = nil
                    end
                    FlingRecoveryActive = false
                    if CancelFlingRecovery == cleanupFlingRecovery then
                        CancelFlingRecovery = nil
                    end
                    if PendingReturnAfterFling then
                        local pendingReason = PendingReturnAfterFlingReason
                        PendingReturnAfterFling = false
                        PendingReturnAfterFlingReason = nil
                        ReturnToPickup(pendingReason or "Fling recovery finished. Returning to base.")
                    end
                end
                CancelFlingRecovery = cleanupFlingRecovery
                local function finishFlingRecovery()
                    cleanupFlingRecovery()
                    if AutoBreakEnabled and not PickupRequested and not ReturningAfterPickup and StartAutoBreak then
                        task.delay(0.25, function()
                            if not FlingRecoveryActive and AutoBreakEnabled and not PickupRequested and not ReturningAfterPickup then
                                StartAutoBreak()
                            end
                        end)
                    end
                end
                if PickupGeneration ~= flingToken or not FlingRecoveryActive then
                    finishFlingRecovery()
                    return
                end
                local character, humanoid, root = WaitForCharacterAndParts(10, function()
                    return PickupGeneration == flingToken and PickupRequested and FlingRecoveryActive
                end)
                if not character then
                    if PickupGeneration ~= flingToken or not FlingRecoveryActive then
                        cleanupFlingRecovery()
                        return
                    end
                    PickupRequested = false
                    SetTrackerStatus("FLING RECOVERY cancelled: character parts unavailable.")
                    finishFlingRecovery()
                    return
                end
                recoveryHumanoid = humanoid
                originalAutoRotate = humanoid.AutoRotate
                humanoid.AutoRotate = false
                if PickupGeneration ~= flingToken or not PickupRequested or not AutoPickupEnabled then
                    finishFlingRecovery()
                    return
                end
                local recoveryPosition = getTrackedAnimalPosition()
                if carriedAnimalLost and not recoveryPosition then
                    local animalWaitDeadline = os.clock() + 2.5
                    repeat
                        task.wait(0.1)
                        recoveryPosition = getTrackedAnimalPosition()
                    until recoveryPosition or os.clock() >= animalWaitDeadline
                        or Runtime.Stopped or PickupGeneration ~= flingToken or not FlingRecoveryActive
                end
                if not recoveryPosition then
                    PickupRequested = false
                    SetTrackerStatus("FLING RECOVERY cancelled: dropped animal was not found in AnimalPickups (" .. tostring(targetAnimalName) .. ").")
                    finishFlingRecovery()
                    return
                end
                local function positionOf(candidate)
                    local parent = candidate and candidate.Parent
                    while parent and parent ~= workspace do
                        if parent:IsA("Attachment") then return parent.WorldPosition end
                        if parent:IsA("BasePart") then return parent.Position end
                        if parent:IsA("Model") then return parent:GetPivot().Position end
                        parent = parent.Parent
                    end
                    return nil
                end
                local function findNearbyStealPrompt()
                    local anchor = workspace:FindFirstChild("PromptAnchor")
                    if not anchor then return nil, nil end
                    local nearest = math.huge
                    local bestPrompt, bestPosition
                    for _, candidate in ipairs(anchor:GetDescendants()) do
                        if candidate:IsA("ProximityPrompt") and candidate.Name == "StealPrompt" and candidate.Enabled then
                            local pos = positionOf(candidate)
                            if pos then
                                local distance = (pos - recoveryPosition).Magnitude
                                if distance < nearest and distance <= 12 then
                                    nearest, bestPrompt, bestPosition = distance, candidate, pos
                                end
                            end
                        end
                    end
                    return bestPrompt, bestPosition
                end
                local prompt, promptPosition = findNearbyStealPrompt()
                local promptLogged = prompt ~= nil
                if prompt then
                    SetTrackerStatus(string.format("FLING RECOVERY cached StealPrompt %.1f studs from animal; moving immediately.", (promptPosition - recoveryPosition).Magnitude))
                else
                    SetTrackerStatus("FLING RECOVERY: searching for StealPrompt while moving toward the animal.")
                end
                SetTrackerStatus(string.format(
                    "FLING RECOVERY found dropped %s in AnimalPickups at (%.3f, %.3f, %.3f).",
                    tostring(flingAnimal and flingAnimal.Name or targetAnimalName or "animal"),
                    recoveryPosition.X, recoveryPosition.Y, recoveryPosition.Z
                ))
                local RunService = game:GetService("RunService")
                recoveryMoveBindName = "BASAEFlingRecovery_" .. tostring(flingToken)
                RunService:BindToRenderStep(recoveryMoveBindName, Enum.RenderPriority.Character.Value + 1, function()
                    if Runtime.Stopped or not PickupRequested or PickupGeneration ~= flingToken
                        or LocalPlayer.Character ~= character or not root.Parent or humanoid.Health <= 0 then
                        humanoid:Move(Vector3.zero, false)
                        return
                    end
                    local livePosition = getTrackedAnimalPosition()
                    if livePosition then recoveryPosition = livePosition end
                    local moveOffset = Vector3.new(recoveryPosition.X - root.Position.X, 0, recoveryPosition.Z - root.Position.Z)
                    if moveOffset.Magnitude > 4 then
                        humanoid:Move(moveOffset.Unit, false)
                    else
                        humanoid:Move(Vector3.zero, false)
                    end
                end)
                local moveStarted = os.clock()
                local lastProgressAt = os.clock()
                local bestDistance = math.huge
                TouchAutomationProgress("FLING_RECOVERY:ANIMAL_APPROACH")
                while not Runtime.Stopped and PickupRequested and PickupGeneration == flingToken and humanoid.Health > 0 do
                    if LocalPlayer.Character ~= character or not character.Parent or not root.Parent then
                        PickupRequested = false
                        SetTrackerStatus("FLING RECOVERY cancelled: character changed or root became unavailable.")
                        if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                        finishFlingRecovery()
                        return
                    end
                    local livePosition = getTrackedAnimalPosition()
                    if livePosition then recoveryPosition = livePosition end
                    if not prompt then
                        prompt, promptPosition = findNearbyStealPrompt()
                        if prompt and not promptLogged then
                            promptLogged = true
                            SetTrackerStatus(string.format("FLING RECOVERY found StealPrompt while moving (%.1f studs from animal).", (promptPosition - recoveryPosition).Magnitude))
                        end
                    end
                    local offset = Vector3.new(recoveryPosition.X - root.Position.X, 0, recoveryPosition.Z - root.Position.Z)
                    local distance = offset.Magnitude
                    if distance <= 4 then break end
                    local now = os.clock()
                    if now - moveStarted >= 45 then
                        humanoid:Move(Vector3.zero, false)
                        PickupRequested = false
                        SetTrackerStatus(string.format("FLING RECOVERY cancelled: timed out reaching the animal location (%.1f studs away).", distance))
                        if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                        finishFlingRecovery()
                        return
                    end
                    if distance < bestDistance - 0.75 then
                        bestDistance = distance
                        lastProgressAt = now
                        TouchAutomationProgress()
                    elseif now - lastProgressAt >= 2.5 then
                        local state = humanoid:GetState()
                        if state == Enum.HumanoidStateType.FallingDown
                            or state == Enum.HumanoidStateType.Ragdoll
                            or state == Enum.HumanoidStateType.Physics
                            or state == Enum.HumanoidStateType.PlatformStanding then
                            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                        end
                        lastProgressAt = now
                        bestDistance = distance
                        if humanoid.PlatformStand then humanoid.PlatformStand = false end
                        if root.Anchored then
                            SetTrackerStatus(string.format("FLING RECOVERY blocked: HumanoidRootPart is anchored (%.1f studs away).", distance))
                        else
                            SetTrackerStatus(string.format("FLING RECOVERY: movement input refreshed every frame; no progress yet (%.1f studs away, state=%s).", distance, tostring(state)))
                        end
                    end
                    task.wait(0.1)
                end
                if recoveryMoveBindName then
                    pcall(function() RunService:UnbindFromRenderStep(recoveryMoveBindName) end)
                    recoveryMoveBindName = nil
                end
                humanoid:Move(Vector3.zero, false)
                local arrivalDistance = (Vector3.new(recoveryPosition.X, root.Position.Y, recoveryPosition.Z) - root.Position).Magnitude
                if PickupGeneration ~= flingToken then
                    finishFlingRecovery()
                    return
                end
                if not PickupRequested or humanoid.Health <= 0 or arrivalDistance > 5 then
                    PickupRequested = false
                    SetTrackerStatus(string.format("FLING RECOVERY cancelled: arrival verification failed (%.1f studs).", arrivalDistance))
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    finishFlingRecovery()
                    return
                end
                local searchDeadline = os.clock() + 1.5
                if not prompt then
                    SetTrackerStatus(string.format("FLING RECOVERY arrived near animal (%.1f studs); brief final StealPrompt check.", arrivalDistance))
                    repeat
                        local livePosition = getTrackedAnimalPosition()
                        if livePosition then recoveryPosition = livePosition end
                        prompt, promptPosition = findNearbyStealPrompt()
                        if prompt then break end
                        task.wait(0.1)
                    until os.clock() >= searchDeadline or PickupGeneration ~= flingToken
                end
                if PickupGeneration ~= flingToken then
                    finishFlingRecovery()
                    return
                end
                if not prompt or not prompt.Parent or not prompt.Enabled or not promptPosition then
                    PickupRequested = false
                    SetTrackerStatus("FLING RECOVERY failed: no enabled StealPrompt within 12 studs of the current animal location.")
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    finishFlingRecovery()
                    return
                end
                SetTrackerStatus(string.format("FLING RECOVERY found nearest prompt %.1f studs from the animal; verifying prompt position.", (promptPosition - recoveryPosition).Magnitude))
                local moveStarted = os.clock()
                local bestPromptDistance = math.huge
                TouchAutomationProgress("FLING_RECOVERY:PROMPT_APPROACH")
                while not Runtime.Stopped and PickupRequested and PickupGeneration == flingToken and prompt.Parent and prompt.Enabled and humanoid.Health > 0 do
                    promptPosition = positionOf(prompt) or promptPosition
                    local locationError = (promptPosition - recoveryPosition).Magnitude
                    if locationError > 14 then
                        humanoid:Move(Vector3.zero, false)
                        PickupRequested = false
                        SetTrackerStatus(string.format("FLING RECOVERY cancelled: prompt moved %.1f studs away from the animal location.", locationError))
                        if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                        finishFlingRecovery()
                        return
                    end
                    local offset = Vector3.new(promptPosition.X - root.Position.X, 0, promptPosition.Z - root.Position.Z)
                    local distanceToPrompt = (promptPosition - root.Position).Magnitude
                    if distanceToPrompt < bestPromptDistance - 0.75 then
                        bestPromptDistance = distanceToPrompt
                        TouchAutomationProgress()
                    end
                    if distanceToPrompt <= math.min(prompt.MaxActivationDistance, 5) then break end
                    if os.clock() - moveStarted >= 25 then
                        humanoid:Move(Vector3.zero, false)
                        PickupRequested = false
                        SetTrackerStatus("FLING RECOVERY cancelled: timed out reaching the verified prompt.")
                        if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                        finishFlingRecovery()
                        return
                    end
                    humanoid:Move(offset.Magnitude > 0 and offset.Unit or Vector3.zero, false)
                    task.wait(0.05)
                end
                humanoid:Move(Vector3.zero, false)
                if PickupGeneration ~= flingToken then
                    finishFlingRecovery()
                    return
                end
                if not PickupRequested or not prompt.Parent or not prompt.Enabled or humanoid.Health <= 0 then
                    PickupRequested = false
                    SetTrackerStatus("FLING RECOVERY cancelled: prompt or character became unavailable.")
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    finishFlingRecovery()
                    return
                end
                promptPosition = positionOf(prompt) or promptPosition
                local finalPlayerDistance = (promptPosition - root.Position).Magnitude
                local finalLocationError = (promptPosition - recoveryPosition).Magnitude
                if finalPlayerDistance > math.min(prompt.MaxActivationDistance, 5) or finalLocationError > 14 then
                    PickupRequested = false
                    SetTrackerStatus(string.format("FLING RECOVERY blocked by location verification: player=%.1f studs, animal mismatch=%.1f studs.", finalPlayerDistance, finalLocationError))
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    finishFlingRecovery()
                    return
                end
                task.wait(0.15)
                if PickupGeneration ~= flingToken then
                    finishFlingRecovery()
                    return
                end
                promptPosition = positionOf(prompt) or promptPosition
                if LocalPlayer.Character ~= character or not character.Parent or humanoid.Health <= 0
                    or not prompt.Parent or not prompt.Enabled
                    or (promptPosition - root.Position).Magnitude > math.min(prompt.MaxActivationDistance, 5)
                    or (promptPosition - recoveryPosition).Magnitude > 14 then
                    PickupRequested = false
                    SetTrackerStatus("FLING RECOVERY blocked: prompt moved outside the verified pickup range.")
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    finishFlingRecovery()
                    return
                end
                local ok, err = pcall(function()
                    if typeof(fireproximityprompt) == "function" then
                        fireproximityprompt(prompt)
                    else
                        prompt:InputHoldBegin()
                        task.wait(prompt.HoldDuration + 0.1)
                        prompt:InputHoldEnd()
                    end
                end)
                if PickupGeneration ~= flingToken then
                    finishFlingRecovery()
                    return
                end
                if not ok then
                    pcall(function() prompt:InputHoldEnd() end)
                    PickupRequested = false
                    SetTrackerStatus("FLING RECOVERY pickup failed: " .. tostring(err))
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    finishFlingRecovery()
                    return
                end
                SetTrackerStatus("FLING RECOVERY prompt activated; confirming animal collection.")
                local confirmed = false
                local confirmDeadline = os.clock() + 4
                while not Runtime.Stopped and os.clock() < confirmDeadline and PickupGeneration == flingToken and PickupRequested do
                    local folder = workspace:FindFirstChild("AnimalPickups")
                    local targetStillExists = false
                    if folder then
                        for _, animal in ipairs(folder:GetChildren()) do
                            if animal.Name == targetAnimalName then
                                targetStillExists = true
                                break
                            end
                        end
                        if not targetStillExists then confirmed = true; break end
                    end
                    task.wait(0.1)
                end
                if PickupGeneration ~= flingToken then
                    finishFlingRecovery()
                    return
                end
                if not confirmed then
                    PickupRequested = false
                    SetTrackerStatus("FLING RECOVERY: prompt activated but collection was not confirmed; staying in place.")
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    finishFlingRecovery()
                    return
                end
                SetTrackerStatus("FLING RECOVERY collection confirmed; resuming base return to the saved base position.")
                finishFlingRecovery()
                ReturnToPickup("Fling recovery pickup confirmed. Returning to saved base position.")
            end)
        end
        FlingRemoteConnection = CatchFlingRemote.OnClientEvent:Connect(HandleFlingRecovery)
        CarriedAnimalWatch.Bind = function(folder)
            if not folder or not folder:IsA("Folder") or CarriedAnimalWatch.folder == folder then return end
            CarriedAnimalWatch.folder = folder
            local function observeCarriedAnimal(model)
                if model and model.Name == "CarriedAnimal" then
                    CarriedAnimalWatch.model = model
                    CarriedAnimalWatch.seen = true
                end
            end
            for _, child in ipairs(folder:GetChildren()) do observeCarriedAnimal(child) end
            CarriedAnimalWatch.childAdded = folder.ChildAdded:Connect(function(child)
                observeCarriedAnimal(child)
            end)
            CarriedAnimalWatch.childRemoved = folder.ChildRemoved:Connect(function(child)
                if child ~= CarriedAnimalWatch.model or not CarriedAnimalWatch.seen then return end
                local removedModel = child
                CarriedAnimalWatch.model = nil
                CarriedAnimalWatch.seen = false
                local carriedWeight = GetAnimalWeightKg(removedModel)
                if FlingTargetWeightKg == nil and carriedWeight ~= nil then
                    FlingTargetWeightKg = carriedWeight
                end
                task.defer(function()
                    if Runtime.Stopped or ScriptShuttingDown or CarriedAnimalWatch.model ~= nil
                        or not AutoPickupEnabled or not AutoBreakEnabled
                        or (not ReturningAfterPickup and not PickupRequested) then return end
                    local character = LocalPlayer.Character
                    local root = character and character:FindFirstChild("HumanoidRootPart")
                    if root and (root.Position - BaseReturnPosition).Magnitude <= 10 then
                        SetTrackerStatus("CarriedAnimal disappeared near base; treating it as a normal bank instead of recovery.")
                        return
                    end
                    SetTrackerStatus("CarriedAnimal disappeared while away from base; starting fast animal-location recovery.")
                    if HandleFlingRecovery then HandleFlingRecovery("fling", nil, nil, nil, true) end
                end)
            end)
            SetTrackerStatus("CarriedAnimals folder connected; watching CarriedAnimal presence.")
        end
        local existingCarriedFolder = workspace:FindFirstChild("CarriedAnimals")
        if existingCarriedFolder then CarriedAnimalWatch.Bind(existingCarriedFolder) end
        AnimalFolderConnection = workspace.ChildAdded:Connect(function(child)
            if child.Name == "AnimalPickups" and not AnimalPickups then
                BindAnimalPickups(child)
            elseif child.Name == "CarriedAnimals" then
                CarriedAnimalWatch.Bind(child)
            end
        end)
        StopAutoBreak = function(reason, preserveTargetState)
            TouchAutomationProgress(AutoBreakEnabled and "AUTO_BREAK_PAUSED" or "AUTO_BREAK_OFF")
            if MovementConnection then
                MovementConnection:Disconnect()
                MovementConnection = nil
            end
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid and not PickupRequested and not ReturningAfterPickup then
                humanoid:Move(Vector3.zero, false)
            end
            ArrivedAtTarget = false
            if not preserveTargetState then
                WaitingForPickup = false
                CurrentTarget = nil
            end
            if reason then
                SetTrackerStatus(reason)
            end
        end
        StartAutoBreak = function(forceRefresh)
            if not AutoBreakEnabled or ScriptShuttingDown then return end
            local startGeneration = AutoBreakGeneration
            TouchAutomationProgress("AUTO_BREAK:SELECTING_TARGET")
            if FlingRecoveryActive then
                SetTrackerStatus("Auto Break paused: fling recovery owns movement until the animal pickup attempt finishes.")
                return
            end
            if not AutoBreakEnabled then
                SetTrackerStatus("Auto Break start ignored: toggle is OFF.")
                return
            end
            if PickupRequested or ReturningAfterPickup then
                SetTrackerStatus("Auto Break start ignored: pickup/return is in progress.")
                return
            end
            if WaitingForPickup then
                SetTrackerStatus("Auto Break start ignored: broken target is waiting for its AnimalPickups entry.")
                return
            end
            local lockedTarget = CurrentTarget
            if lockedTarget and IsEggConfirmedComplete(lockedTarget) then
                CompletedEggs[lockedTarget] = true
                lockedTarget = nil
                SetTrackerStatus("Current egg HP reached 0; releasing target lock.")
            elseif lockedTarget and not IsEggAvailable(lockedTarget) then
                lockedTarget = nil
            end
            if lockedTarget and not forceRefresh and (MovementConnection ~= nil or ArrivedAtTarget) then
                return
            end
            StopAutoBreak(nil, lockedTarget ~= nil)
            local selectedZoneNames = {}
            for zoneName, selected in pairs(SelectedZones) do
                if selected then
                    table.insert(selectedZoneNames, zoneName)
                end
            end
            if #selectedZoneNames == 0 then
                for _, zone in ipairs(ZoneBuilds:GetChildren()) do
                    if zone:IsA("Model") then
                        table.insert(selectedZoneNames, zone.Name)
                    end
                end
            end
            table.sort(selectedZoneNames)
            local target = lockedTarget
            if not target and TitanicPriorityEnabled then
                local titanicCandidates = {}
                for _, zoneName in ipairs(selectedZoneNames) do
                    local zone = ZoneBuilds:FindFirstChild(zoneName)
                    local eggsFolder = zone and zone:FindFirstChild("Eggs")
                    if eggsFolder then
                        for _, egg in ipairs(eggsFolder:GetChildren()) do
                            if (egg:IsA("Model") or egg:IsA("BasePart"))
                                and egg.Name:lower():find("egg", 1, true)
                                and IsEggAvailable(egg) then
                                local eggName = GetEggTypeName(egg.Name)
                                if SelectedEggs[eggName] ~= false then
                                    local category = GetEggWeightBracket(egg)
                                    if category ~= nil and tostring(category):lower():find("titanic", 1, true) then
                                        table.insert(titanicCandidates, egg)
                                    end
                                end
                            end
                        end
                    end
                end
                table.sort(titanicCandidates, function(a, b)
                    return a.Name < b.Name
                end)
                if #titanicCandidates > 0 then
                    target = titanicCandidates[1]
                    SetTrackerStatus("TITANIC PRIORITY: selected " .. target.Name
                        .. " | category=TITANIC before the normal egg route.")
                    AddDebugLog("[Auto Break] Titanic category detected: " .. target.Name .. "; prioritizing by category only.")
                else
                    SetTrackerStatus("TITANIC PRIORITY is ON, but no eligible egg with TITANIC category was found in the selected zones.")
                end
            end
            if not target and SortOrder == "Highest Luck" then
                local luckCandidates = {}
                local unreadableLuckCount = 0
                for _, zoneName in ipairs(selectedZoneNames) do
                    local zone = ZoneBuilds:FindFirstChild(zoneName)
                    local eggsFolder = zone and zone:FindFirstChild("Eggs")
                    if eggsFolder then
                        for _, egg in ipairs(eggsFolder:GetChildren()) do
                            if (egg:IsA("Model") or egg:IsA("BasePart"))
                                and egg.Name:lower():find("egg", 1, true)
                                and IsEggAvailable(egg) then
                                local eggName = GetEggTypeName(egg.Name)
                                if SelectedEggs[eggName] ~= false then
                                    local luck = GetEggLuck(egg)
                                    if luck > 0 then
                                        local weightBracket = GetEggWeightBracket(egg)
                                        local weightKg = GetEggWeightKg(egg)
                                        local bracketText = weightBracket ~= nil and tostring(weightBracket) or ""
                                        local isTitanic = bracketText:lower():find("titanic", 1, true) ~= nil
                                        table.insert(luckCandidates, {
                                            egg = egg,
                                            luck = luck,
                                            weightKg = weightKg or 0,
                                            isTitanic = isTitanic
                                        })
                                    else
                                        unreadableLuckCount += 1
                                    end
                                end
                            end
                        end
                    end
                end
                table.sort(luckCandidates, function(a, b)
                    if a.luck ~= b.luck then return a.luck > b.luck end
                    if TitanicPriorityEnabled and a.isTitanic ~= b.isTitanic then
                        return a.isTitanic
                    end
                    if TitanicPriorityEnabled and a.weightKg ~= b.weightKg then
                        return a.weightKg > b.weightKg
                    end
                    return a.egg.Name < b.egg.Name
                end)
                if #luckCandidates > 0 then
                    target = luckCandidates[1].egg
                    SetTrackerStatus("HIGHEST LUCK PRIORITY: selected " .. target.Name
                        .. " | Luck=" .. tostring(luckCandidates[1].luck)
                        .. (TitanicPriorityEnabled and (" | Size tie-break: " .. (luckCandidates[1].isTitanic and "Titanic" or tostring(luckCandidates[1].weightKg) .. " KG")) or "")
                        .. " | readable candidates=" .. tostring(#luckCandidates)
                        .. " | ignored unreadable=" .. tostring(unreadableLuckCount))
                    AddDebugLog("[Auto Break] Selected " .. target.Name .. " | luck=" .. tostring(luckCandidates[1].luck)
                        .. " | sizeKG=" .. tostring(luckCandidates[1].weightKg)
                        .. " | Titanic=" .. tostring(luckCandidates[1].isTitanic)
                        .. " | candidates=" .. tostring(#luckCandidates))
                else
                    SetTrackerStatus("HIGHEST LUCK PRIORITY found no readable values; using the normal Egg Filter selection.")
                    AddDebugLog("[Auto Break] HighLuck values unavailable; falling back to normal filtered egg selection.")
                end
            end
            if not target then
                local normalZoneNames = {}
                local preferredIsSelected = false
                if PreferredZoneName then
                    for _, zoneName in ipairs(selectedZoneNames) do
                        if zoneName == PreferredZoneName then
                            preferredIsSelected = true
                            break
                        end
                    end
                end
                if preferredIsSelected then
                    table.insert(normalZoneNames, PreferredZoneName)
                end
                for _, zoneName in ipairs(selectedZoneNames) do
                    if zoneName ~= PreferredZoneName then
                        table.insert(normalZoneNames, zoneName)
                    end
                end
                for _, zoneName in ipairs(normalZoneNames) do
                    if target then break end
                    local zone = ZoneBuilds:FindFirstChild(zoneName)
                    local eggsFolder = zone and zone:FindFirstChild("Eggs")
                    if eggsFolder then
                        for _, egg in ipairs(eggsFolder:GetChildren()) do
                            if (egg:IsA("Model") or egg:IsA("BasePart"))
                            and egg.Name:lower():find("egg", 1, true) then
                                local eggName = GetEggTypeName(egg.Name)
                                if SelectedEggs[eggName] ~= false and IsEggAvailable(egg) then
                                    target = egg
                                    break
                                end
                            end
                        end
                        if target then break end
                    end
                end
            end
            if not target then
                SetTrackerStatus("No target found. Select a zone and keep at least one egg type enabled.")
                TouchAutomationProgress("IDLE")
                return
            end
            local character = LocalPlayer.Character
            local characterDeadline = os.clock() + 10
            while not character and os.clock() < characterDeadline
                and not Runtime.Stopped and AutoBreakEnabled and startGeneration == AutoBreakGeneration do
                task.wait(0.1)
                character = LocalPlayer.Character
            end
            if not character or Runtime.Stopped or ScriptShuttingDown
                or not AutoBreakEnabled or startGeneration ~= AutoBreakGeneration then
                TouchAutomationProgress("IDLE")
                return
            end
            local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
            local root = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5)
            if not humanoid or not root or not AutoBreakEnabled or startGeneration ~= AutoBreakGeneration then
                TouchAutomationProgress("IDLE")
                SetTrackerStatus("Auto Break cancelled: character parts were unavailable or the toggle changed while waiting.")
                return
            end
            CurrentTarget = target
            local targetEggsFolder = target.Parent
            local targetZone = targetEggsFolder and targetEggsFolder.Parent
            if targetZone and targetZone.Parent == ZoneBuilds then
                PreferredZoneName = targetZone.Name
            end
            ArrivedAtTarget = false
            WaitingForPickup = false
            table.clear(BaselinePickups)
            if AnimalPickups then
                for _, pickup in ipairs(AnimalPickups:GetChildren()) do
                    BaselinePickups[pickup] = true
                end
            else
                SetTrackerStatus("AnimalPickups folder not created yet; waiting for it to appear.")
            end
            SetTrackerStatus("Moving to target: " .. target:GetFullName())
            MovementConnection = game:GetService("RunService").RenderStepped:Connect(function()
                -- Animal pickup/return movement always owns the character over egg movement.
                if PickupRequested or ReturningAfterPickup then
                    if MovementConnection then
                        MovementConnection:Disconnect()
                        MovementConnection = nil
                    end
                    return
                end
                if CurrentTarget ~= target or not IsEggAvailable(target) or not character.Parent
                or humanoid.Health <= 0 then
                    if CurrentTarget == target and not IsEggAvailable(target) then
                        CompletedEggs[target] = true
                        SetTrackerStatus("Target egg is no longer available or its HP reached 0; refreshing the egg list.")
                        StopAutoBreak()
                        task.defer(function()
                            task.wait(0.2)
                            if AutoBreakEnabled and not PickupRequested and not ReturningAfterPickup then
                                StartAutoBreak()
                            end
                        end)
                    else
                        StopAutoBreak("Movement stopped: target/character unavailable.", CurrentTarget == target and IsEggAvailable(target))
                    end
                    return
                end
                local targetPosition = target:GetPivot().Position
                local offset = Vector3.new(
                    targetPosition.X - root.Position.X,
                    0,
                    targetPosition.Z - root.Position.Z
                )
                if offset.Magnitude <= 4 then
                    humanoid:Move(Vector3.zero, false)
                    MovementConnection:Disconnect()
                    MovementConnection = nil
                    ArrivedAtTarget = true
                    LastEggHPTarget = target
                    LastEggHPValue = nil
                    LastEggHPProgressAt = os.clock()
                    SetTrackerStatus("ARRIVED | " .. target:GetFullName()
                        .. " | tracking matching EggHitConfirmed events now.")
                    local hpWatchdogTarget = target
                    local hpWatchdogStarted = os.clock()
                    task.spawn(function()
                        while not Runtime.Stopped and AutoBreakEnabled and CurrentTarget == hpWatchdogTarget
                            and ArrivedAtTarget and not PickupRequested and not ReturningAfterPickup
                            and os.clock() - math.max(hpWatchdogStarted, LastEggHPProgressAt) < 8 do
                            task.wait(0.25)
                        end
                        if Runtime.Stopped or not AutoBreakEnabled or CurrentTarget ~= hpWatchdogTarget
                            or not ArrivedAtTarget or PickupRequested or ReturningAfterPickup then
                            return
                        end
                        if os.clock() - math.max(hpWatchdogStarted, LastEggHPProgressAt) >= 8 then
                            SetTrackerStatus("EGG HP WATCHDOG: no HP progress for 8s at " .. hpWatchdogTarget:GetFullName()
                                .. "; equipping pickaxe and restarting Auto Break.")
                            ArrivedAtTarget = false
                            if MovementConnection then MovementConnection:Disconnect(); MovementConnection = nil end
                            task.spawn(function()
                                EquipHotbarOne()
                                task.wait(0.2)
                                if AutoBreakEnabled and CurrentTarget == hpWatchdogTarget
                                    and not PickupRequested and not ReturningAfterPickup and not WaitingForPickup then
                                    StartAutoBreak(true)
                                end
                            end)
                        end
                    end)
                    return
                end
                humanoid:Move(offset.Unit, false)
            end)
        end
        task.spawn(function()
            while not Runtime.Stopped and not ScriptShuttingDown do
                task.wait(1.5)
                if AutoBreakEnabled and SortOrder == "Highest Luck"
                    and MovementConnection ~= nil and CurrentTarget
                    and IsEggAvailable(CurrentTarget)
                    and not FlingRecoveryActive and not PickupRequested
                    and not ReturningAfterPickup and not WaitingForPickup
                    and not ArrivedAtTarget then
                    local currentLuck = GetEggLuck(CurrentTarget)
                    local zoneNames = {}
                    for zoneName, selected in pairs(SelectedZones) do
                        if selected then
                            table.insert(zoneNames, zoneName)
                        end
                    end
                    if #zoneNames == 0 then
                        for _, zone in ipairs(ZoneBuilds:GetChildren()) do
                            if zone:IsA("Model") then
                                table.insert(zoneNames, zone.Name)
                            end
                        end
                    end
                    table.sort(zoneNames)
                    local bestEgg = nil
                    local bestLuck = currentLuck
                    for _, zoneName in ipairs(zoneNames) do
                        local zone = ZoneBuilds:FindFirstChild(zoneName)
                        local eggsFolder = zone and zone:FindFirstChild("Eggs")
                        if eggsFolder then
                            for _, egg in ipairs(eggsFolder:GetChildren()) do
                                if egg ~= CurrentTarget
                                    and (egg:IsA("Model") or egg:IsA("BasePart"))
                                    and egg.Name:lower():find("egg", 1, true)
                                    and IsEggAvailable(egg) then
                                    local eggName = GetEggTypeName(egg.Name)
                                    if SelectedEggs[eggName] ~= false then
                                        local luck = GetEggLuck(egg)
                                        if luck > bestLuck then
                                            bestLuck = luck
                                            bestEgg = egg
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if bestEgg then
                        AddDebugLog("[Auto Break] Higher luck egg found while moving: "
                            .. bestEgg.Name .. " | Luck=" .. tostring(bestLuck)
                            .. " > current=" .. tostring(currentLuck) .. "; switching target.")
                        CurrentTarget = nil
                        StartAutoBreak(true)
                    end
                end
            end
        end)
        task.spawn(function()
            while not Runtime.Stopped and not ScriptShuttingDown do
                task.wait(1)
                local active = PickupRequested or ReturningAfterPickup or FlingRecoveryActive
                    or (AutoBreakEnabled and (CurrentTarget ~= nil or WaitingForPickup or ArrivedAtTarget
                        or AutomationProgressStage:find("^AUTO_BREAK:") ~= nil))
                if active and not AutomationWatchdogBusy
                    and os.clock() - LastAutomationProgressAt >= 20 then
                    AutomationWatchdogBusy = true
                    AutoBreakGeneration += 1
                    SetTrackerStatus("STUCK WATCHDOG: no automation progress for 20s during "
                        .. tostring(AutomationProgressStage) .. "; clearing stale waits/locks and restarting Auto Break.")
                    if StopPickupAutomation then
                        StopPickupAutomation("20s stuck watchdog recovery")
                    end
                    if MovementConnection then MovementConnection:Disconnect(); MovementConnection = nil end
                    if PickupMovementConnection then PickupMovementConnection:Disconnect(); PickupMovementConnection = nil end
                    if ReturnMovementConnection then ReturnMovementConnection:Disconnect(); ReturnMovementConnection = nil end
                    local character = LocalPlayer.Character
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                    if humanoid then humanoid:Move(Vector3.zero, false) end
                    WaitingForPickup = false
                    ArrivedAtTarget = false
                    FlingRecoveryActive = false
                    TouchAutomationProgress("WATCHDOG_RECOVERY")
                    task.spawn(function()
                        EquipHotbarOne()
                        task.wait(0.2)
                        if AutoBreakEnabled and not ScriptShuttingDown then
                            AutomationWatchdogBusy = false
                            StartAutoBreak(true)
                        else
                            AutomationWatchdogBusy = false
                        end
                    end)
                end
            end
        end)
        RefreshTitanicPriority = function()
            if not AutoBreakEnabled or not CurrentTarget then return end
            if FlingRecoveryActive or PickupRequested or ReturningAfterPickup or WaitingForPickup then
                AddDebugLog("[Auto Break] Priority changed; will apply after the current pickup/recovery finishes.")
                return
            end
            AddDebugLog("[Auto Break] Refreshing target immediately for updated TITANIC priority.")
            task.defer(function()
                if AutoBreakEnabled and not FlingRecoveryActive and not PickupRequested
                    and not ReturningAfterPickup and not WaitingForPickup then
                    StartAutoBreak(true)
                end
            end)
        end
    elseif index == 5 then
        local ThemeCard = CreateCard(Page, "🎨  Theme Settings", "Choose a color palette for the interface.")
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
        local ThemeRows = {}
        local RowHeight = 34
        local ColumnGap = 8
        local ThemeRowCount = math.ceil(#ThemeOptions / 2)
        ThemeCard.Size = UDim2.new(1, 0, 0, 48 + (ThemeRowCount * RowHeight) + 8)

        for i, themeName in ipairs(ThemeOptions) do
            local palette = ThemePresets[themeName]
            local column = i > ThemeRowCount and 2 or 1
            local rowIndex = column == 1 and i or (i - ThemeRowCount)
            local rowWidth = (1 - 0.0) / 2
            local rowXScale = column == 1 and 0 or 0.5
            local Row = Create("TextButton", {
                Name = "ThemeOption_" .. tostring(i),
                Parent = ThemeCard,
                Position = UDim2.new(rowXScale, column == 1 and 10 or 4, 0, 42 + ((rowIndex - 1) * RowHeight)),
                Size = UDim2.new(0.5, column == 1 and -14 or -14, 0, 30),
                BackgroundColor3 = Theme.SurfaceInput,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                ZIndex = 2
            })
            AddCorner(Row, 5)
            AddStroke(Row, Theme.Border, 1)

            local RadioOuter = Create("Frame", {
                Parent = Row,
                Position = UDim2.fromOffset(6, 7),
                Size = UDim2.fromOffset(13, 13),
                BackgroundColor3 = Theme.SurfaceInput,
                BorderSizePixel = 0,
                ZIndex = 3
            })
            AddCorner(RadioOuter, 20)
            AddStroke(RadioOuter, Theme.Gray, 1)

            local RadioInner = Create("Frame", {
                Parent = RadioOuter,
                Position = UDim2.fromOffset(3, 3),
                Size = UDim2.fromOffset(7, 7),
                BackgroundColor3 = palette.Accent,
                BorderSizePixel = 0,
                Visible = themeName == ActiveThemeName,
                ZIndex = 4
            })
            AddCorner(RadioInner, 20)

            local Swatch = Create("Frame", {
                Parent = Row,
                Position = UDim2.fromOffset(24, 7),
                Size = UDim2.fromOffset(30, 16),
                BackgroundColor3 = palette.Background,
                BorderSizePixel = 0,
                ZIndex = 3
            })
            AddCorner(Swatch, 4)
            AddStroke(Swatch, palette.Border, 1)

            Create("Frame", {
                Parent = Swatch,
                Position = UDim2.fromOffset(3, 4),
                Size = UDim2.fromOffset(7, 8),
                BackgroundColor3 = palette.Card,
                BorderSizePixel = 0,
                ZIndex = 4
            })
            Create("Frame", {
                Parent = Swatch,
                Position = UDim2.fromOffset(12, 4),
                Size = UDim2.fromOffset(7, 8),
                BackgroundColor3 = palette.Accent,
                BorderSizePixel = 0,
                ZIndex = 4
            })
            Create("Frame", {
                Parent = Swatch,
                Position = UDim2.fromOffset(21, 4),
                Size = UDim2.fromOffset(6, 8),
                BackgroundColor3 = palette.Selected,
                BorderSizePixel = 0,
                ZIndex = 4
            })

            Create("TextLabel", {
                Parent = Row,
                Position = UDim2.fromOffset(59, 1),
                Size = UDim2.new(1, -64, 1, -2),
                BackgroundTransparency = 1,
                Text = themeName,
                TextColor3 = Theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 8,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 3
            })

            ThemeRows[#ThemeRows + 1] = {
                Name = themeName,
                Row = Row,
                RadioInner = RadioInner,
                Swatch = Swatch,
                Palette = palette
            }

            Row.MouseButton1Click:Connect(function()
                ApplyTheme(themeName)
                for _, item in ipairs(ThemeRows) do
                    item.RadioInner.Visible = item.Name == themeName
                    item.RadioInner.BackgroundColor3 = item.Palette.Accent
                    item.Swatch.BackgroundColor3 = item.Palette.Background
                    local swatchStroke = item.Swatch:FindFirstChildOfClass("UIStroke")
                    if swatchStroke then swatchStroke.Color = item.Palette.Border end
                    local swatchFrames = {}
                    for _, child in ipairs(item.Swatch:GetChildren()) do
                        if child:IsA("Frame") then
                            swatchFrames[#swatchFrames + 1] = child
                        end
                    end
                    if swatchFrames[1] then swatchFrames[1].BackgroundColor3 = item.Palette.Card end
                    if swatchFrames[2] then swatchFrames[2].BackgroundColor3 = item.Palette.Accent end
                    if swatchFrames[3] then swatchFrames[3].BackgroundColor3 = item.Palette.Selected end
                    item.Row.BackgroundColor3 = item.Name == themeName and item.Palette.Selected or Theme.SurfaceInput
                end
            end)
        end

        for _, item in ipairs(ThemeRows) do
            item.Row.BackgroundColor3 = item.Name == ActiveThemeName and Theme.Selected or Theme.SurfaceInput
        end

    elseif index == 2 then
        local CandyCard = CreateCard(Page, "🍬  Auto collect candies", "UNDER DEVELOPMENT")
        CandyCard.Size = UDim2.new(1, 0, 0, 110)
        local CandyInfo = Create("TextLabel", {
            Parent = CandyCard,
            Position = UDim2.fromOffset(12, 42),
            Size = UDim2.new(1, -24, 0, 38),
            BackgroundTransparency = 1,
            Text = "UNDER DEVELOPMENT — Auto candy collection is disabled in Deploy.",
            TextColor3 = Theme.Gray,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top
        })
        MarkUnderDevelopment(CandyCard)

    elseif index == 3 then
        local ESPCardsRow = Create("Frame", {
            Name = "ESPFeatureCardsRow",
            Parent = Page,
            Size = UDim2.new(1, 0, 0, 120),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = 0
        })
        local ESPCard = CreateCard(ESPCardsRow, "🥚  Egg ESP", "Displays egg stats.")
        ESPCard.Position = UDim2.new(0, 0, 0, 0)
        ESPCard.Size = UDim2.new(0.5, -5, 0, 100)
        ESPCard.LayoutOrder = 1
        local ESPStatus = Create("TextLabel", {
            Parent = ESPCard,
            Position = UDim2.fromOffset(11, 61),
            Size = UDim2.new(1, -22, 0, 16),
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
        local ESPFolder = Create("Folder", {Name = "BASE_Skrip_EggESP", Parent = LocalPlayer:WaitForChild("PlayerGui")})
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
        ESPCard.Size = UDim2.new(0.5, -5, 0, 100)

        local BackpackESPCard = CreateCard(ESPCardsRow, "Backpack ESP", "Shows larger $/s and KG on inventory cards.")
        BackpackESPCard.Position = UDim2.new(0.5, 5, 0, 0)
        BackpackESPCard.Size = UDim2.new(0.5, -5, 0, 100)
        BackpackESPCard.LayoutOrder = 2
        local BackpackESPStatus = Create("TextLabel", {
            Parent = BackpackESPCard,
            Position = UDim2.fromOffset(11, 61),
            Size = UDim2.new(1, -22, 0, 22),
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
            Name = "BASE_Skrip_BackpackESP",
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
                    local weight = ParseAnimalWeight(tool:GetAttribute("WeightKg"))
                    if typeof(animalName) == "string" and animalName ~= "" and weight then
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
                            overlay.Name = "BASAEInventoryStatsOverlay"
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

        local MiscFeatureRow = Create("Frame", {
            Name = "MiscFeatureCardsRow",
            Parent = Page,
            Size = UDim2.new(1, 0, 0, 110),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = 1
        })
        local AntiPaloCard = CreateCard(MiscFeatureRow, "🛡️  Anti Knockback", "Prevents knockback and fling.")
        AntiPaloCard.Position = UDim2.new(0, 0, 0, 0)
        AntiPaloCard.Size = UDim2.new(0.5, -5, 0, 100)
        AntiPaloCard.LayoutOrder = 1
        local AntiPaloBusy = false
        local AntiPaloStatus = Create("TextLabel", {
            Parent = AntiPaloCard,
            Position = UDim2.fromOffset(11, 62),
            Size = UDim2.new(1, -22, 0, 14),
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

        local AuraCard = CreateCard(MiscFeatureRow, "⚔️  Auto Boink", "Boink any enemy nearby.")
        AuraCard.Position = UDim2.new(0.5, 5, 0, 0)
        AuraCard.Size = UDim2.new(0.5, -5, 0, 100)
        AuraCard.LayoutOrder = 2
        local AuraStatus = Create("TextLabel", {
            Parent = AuraCard,
            Position = UDim2.fromOffset(11, 60),
            Size = UDim2.new(1, -22, 0, 27),
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
        local AuraToggle = CreateToggle(AuraCard, "", false, function(enabled)
            AuraEnabled = enabled
            if not enabled then
                AuraWasNearby = false
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
                            task.spawn(RunAuraNiBai, nearby[1].Name)
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

    elseif index == 4 then
        local PickupCard = CreateCard(Page, "🐾  Animal Pickups", "")
        PickupCard.Size = UDim2.new(1, 0, 0, 230)
        local pickupTitle = PickupCard:FindFirstChildWhichIsA("TextLabel")
        if pickupTitle then pickupTitle.Position = UDim2.fromOffset(15, 10) end
        local PickupStatus = Create("TextLabel", {
            Parent = PickupCard, Position = UDim2.fromOffset(15, 42),
            Size = UDim2.new(1, -30, 0, 18), BackgroundTransparency = 1,
            Text = "Waiting for AnimalPickups...", TextColor3 = Theme.Gray,
            Font = Enum.Font.Gotham, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left
        })
        local PickupList = Create("ScrollingFrame", {
            Parent = PickupCard, Position = UDim2.fromOffset(10, 64),
            Size = UDim2.new(1, -20, 1, -74), BackgroundColor3 = Theme.SurfaceInput,
            BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Gray,
            CanvasSize = UDim2.new(0, 0, 0, 0)
        })
        AddCorner(PickupList, 6)
        local PickupLayout = Create("UIListLayout", {Parent = PickupList, Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder})
        Create("UIPadding", {Parent = PickupList, PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)})
        local function GetPickupConsoleCPS(pickup)
            local cached = pickup:GetAttribute("BASAE_CPSCheckValue")
            for _, node in ipairs(pickup:GetDescendants()) do
                if node.Name == "CashPerSecond" then
                    if node:IsA("TextLabel") or node:IsA("TextButton") or node:IsA("TextBox") then
                        if node.Text ~= "" then return node.Text end
                    end
                    local textNode = node:FindFirstChild("Text", true) or node:FindFirstChild("ContentText", true)
                    if textNode and (textNode:IsA("TextLabel") or textNode:IsA("TextButton") or textNode:IsA("TextBox")) and textNode.Text ~= "" then
                        return textNode.Text
                    end
                end
            end
            if cached and cached ~= "" then return tostring(cached) end
            return "—"
        end
        local function RefreshAnimalPickups()
            for _, child in ipairs(PickupList:GetChildren()) do
                if child:IsA("TextLabel") or child:IsA("Frame") then child:Destroy() end
            end
            local folder = workspace:FindFirstChild("AnimalPickups")
            if not folder then
                PickupStatus.Text = "Waiting for workspace.AnimalPickups..."
                Create("TextLabel", {
                    Parent = PickupList, Size = UDim2.new(1, -8, 0, 28),
                    BackgroundTransparency = 1, Text = "AnimalPickups folder not found.",
                    TextColor3 = Theme.Gray, Font = Enum.Font.Gotham, TextSize = 9, LayoutOrder = 1
                })
                return
            end
            local records = {}
            local qualifiedCount = 0
            for _, pickup in ipairs(folder:GetChildren()) do
                if pickup:IsA("Model") then
                    local qualified = pickup:GetAttribute("BASAE_Qualified")
                    local weight = pickup:GetAttribute("WeightKg")
                    local qualifiedText = qualified == true and "Yes" or qualified == false and "No" or "Not checked"
                    if qualified == true then qualifiedCount += 1 end
                    table.insert(records, {
                        name = pickup.Name,
                        rarity = tostring(GetPetRarity(pickup) or "Unknown"),
                        mutation = GetPickupMutation(pickup),
                        cps = GetPickupConsoleCPS(pickup),
                        kg = weight ~= nil and tostring(weight) or "—",
                        qualified = qualifiedText
                    })
                end
            end
            table.sort(records, function(a, b)
                return a.name:lower() < b.name:lower()
            end)
            PickupStatus.Text = string.format("%d animals | %d qualified", #records, qualifiedCount)
            if #records == 0 then
                Create("TextLabel", {
                    Parent = PickupList, Size = UDim2.new(1, -8, 0, 28),
                    BackgroundTransparency = 1, Text = "No animal models found in AnimalPickups.",
                    TextColor3 = Theme.Gray, Font = Enum.Font.Gotham, TextSize = 9, LayoutOrder = 1
                })
            end
            for order, record in ipairs(records) do
                local row = Create("TextLabel", {
                    Parent = PickupList, Size = UDim2.new(1, -8, 0, 50),
                    BackgroundColor3 = Theme.Card, BorderSizePixel = 0,
                    Text = "  " .. record.name .. "  |  " .. record.rarity .. "  |  Mutation = " .. record.mutation .. "  |  " .. record.cps .. " |  " .. record.kg .. " KG  |  Qualified = " .. record.qualified,
                    TextColor3 = Theme.Text, Font = Enum.Font.Gotham, TextSize = 9,
                    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
                    TextWrapped = true, TextTruncate = Enum.TextTruncate.None,
                    AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order
                })
                AddCorner(row, 4)
            end
            PickupList.CanvasSize = UDim2.new(0, 0, 0, PickupLayout.AbsoluteContentSize.Y + 10)
        end
        PickupLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            PickupList.CanvasSize = UDim2.new(0, 0, 0, PickupLayout.AbsoluteContentSize.Y + 10)
        end)
        task.spawn(function()
            while not Runtime.Stopped and ScreenGui.Parent and Page.Parent do
                RefreshAnimalPickups()
                task.wait(2)
            end
        end)

    else
        local Card1 = CreateCard(Page, name, "This is a reusable UI page. Backend code is not connected.")
        CreateButton(Card1, "Example Button", function()
            -- Put your actual function here.
        end)
        local Card2 = CreateCard(Page, "🎨  Example Settings", "Example controls that only change the UI state.")
        CreateToggle(Card2, "Example Toggle", false, function(state)
            -- state = true / false
        end)
        local Card3 = CreateCard(Page, "🎛️  Example Options", "Dropdown and slider examples.")
        CreateDropdown(Card3, "Mode", {"Option 1", "Option 2", "Option 3"}, function(selection)
            -- selection contains the selected option.
        end)
        CreateSlider(Card3, "Example Slider", 0, 100, 50, function(value)
            -- value contains the current slider value.
        end)
    end
end
-- SHOW FIRST PAGE
Pages[1].Visible = true
SidebarButtons[1].BackgroundColor3 = Theme.Selected
SidebarButtons[1].TextColor3 = Theme.SelectedText
-- MINIMIZE
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
-- CLOSE
CloseButton.MouseButton1Click:Connect(function()
    Runtime.Stopped = true
    if type(RuntimeEnv.__BASAESkripCleanup) == "function" then
        RuntimeEnv.__BASAESkripCleanup()
    else
        if ShutdownAutomation then ShutdownAutomation() end
        ScreenGui:Destroy()
    end
end)
-- DRAGGING
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
UserInputService.InputChanged:Connect(function(input)
    if not Dragging then
        return
    end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
    and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end
    local Delta = input.Position - DragStart
    Main.Position = UDim2.new(
        StartPosition.X.Scale,
        StartPosition.X.Offset + Delta.X,
        StartPosition.Y.Scale,
        StartPosition.Y.Offset + Delta.Y
    )
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        Dragging = false
    end
end)
