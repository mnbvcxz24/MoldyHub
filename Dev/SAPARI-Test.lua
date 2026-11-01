-- REUSABLE UI TEMPLATE
-- SERVICES
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local RuntimeEnv = type(getgenv) == "function" and getgenv() or _G
local testver = "Test ver: 1.85"
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
    Title = "MoldyHub",
    Subtitle = "STEAL A PET AND RIDE IT | " .. testver,
    Width = 480,
    Height = 320,
    SidebarWidth = 100,
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
        titleLabel.Text = '<font color="#' .. selectedTheme.Accent:ToHex() .. '">Moldy</font>Hub'
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
    Text = '<font color="#' .. Theme.Accent:ToHex() .. '">Moldy</font>Hub',
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
    Position = UDim2.new(1, -36, 0, 11),
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
local ResizeHandle = Create("TextButton", {
    Name = "ResizeHandle",
    Parent = Main,
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -3, 1, -3),
    Size = UDim2.fromOffset(18, 18),
    BackgroundColor3 = Theme.Sidebar,
    BackgroundTransparency = 0.15,
    Text = "◢",
    TextColor3 = Theme.Accent,
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    ZIndex = 10
})
AddCorner(ResizeHandle, 5)
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
-- Sidebar container
local SidebarContainer = Create("ScrollingFrame", {
    Name = "Buttons",
    Parent = Sidebar,
    Position = UDim2.fromOffset(5, 12),
    Size = UDim2.new(1, -10, 1, -24),
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
    end)
end

-- CREATE TEMPLATE PAGES
for index, name in ipairs(UIConfig.SidebarNames) do
    local Page = CreatePage(index, name)
    if name == "Main" then
        local AutoCard = CreateCard(Page, "Auto Steal", "")
        AutoCard.Size = UDim2.new(1, -4, 0, 265)
        AutoCard.AutomaticSize = Enum.AutomaticSize.None

        local HeaderTitle = AutoCard:FindFirstChildWhichIsA("TextLabel")
        if HeaderTitle then
            HeaderTitle.Position = UDim2.fromOffset(15, 10)
            HeaderTitle.Size = UDim2.new(1, -70, 0, 22)
            HeaderTitle.TextSize = 13
        end

        local SelectedPaths = {}
        local SelectedRarities = {}
        local function HasSelectedFilter()
            for _, selected in pairs(SelectedPaths) do
                if selected == true then return true end
            end
            for _, selected in pairs(SelectedRarities) do
                if selected == true then return true end
            end
            return false
        end
        local MovementMode = "Walk"
        local AutoStealEnabled = false
        local AutoTreadmillEnabled = false
        local AutoTreadmillStatusValue
        local AutoTreadmillStatusDot
        local StatusValue
        local StatusDot

        local AutoStealToggle = CreateToggle(AutoCard, "", false, function(enabled)
            if enabled and (not Runtime.IsRidingPet or not Runtime.IsRidingPet()) then
                local controller = ToggleControllers[AutoStealToggle]
                if controller then
                    controller.SetEnabled(false, false)
                end
                AutoStealEnabled = false
                Runtime.AutoStealEnabled = false
                if StatusValue then
                    StatusValue.Text = "Please ride in a pet first"
                    StatusValue.TextColor3 = Color3.fromRGB(255, 190, 80)
                end
                if StatusDot then
                    StatusDot.BackgroundColor3 = Color3.fromRGB(255, 190, 80)
                end
                return
            end

            if enabled and not HasSelectedFilter() then
                local controller = ToggleControllers[AutoStealToggle]
                if controller then
                    controller.SetEnabled(false, false)
                end
                AutoStealEnabled = false
                Runtime.AutoStealEnabled = false
                if StatusValue then
                    StatusValue.Text = "Select at least 1 filter"
                    StatusValue.TextColor3 = Color3.fromRGB(255, 190, 80)
                end
                if StatusDot then
                    StatusDot.BackgroundColor3 = Color3.fromRGB(255, 190, 80)
                end
                return
            end

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
            Position = UDim2.fromOffset(15, 36),
            Size = UDim2.new(1, -30, 0, 18),
            BackgroundTransparency = 1
        })
        StatusDot = Create("Frame", {
            Parent = StatusRow,
            Position = UDim2.fromOffset(2, 6),
            Size = UDim2.fromOffset(7, 7),
            BackgroundColor3 = Theme.Gray,
            BorderSizePixel = 0
        })
        AddCorner(StatusDot, 8)
        local StatusLabel = Create("TextLabel", {
            Parent = StatusRow,
            Position = UDim2.fromOffset(18, 0),
            Size = UDim2.fromOffset(34, 18),
            BackgroundTransparency = 1,
            Text = "Status",
            TextColor3 = Theme.DarkGray,
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        StatusValue = Create("TextLabel", {
            Parent = StatusRow,
            Position = UDim2.fromOffset(54, 0),
            Size = UDim2.new(1, -54, 1, 0),
            BackgroundTransparency = 1,
            Text = "Disabled",
            TextColor3 = Theme.Gray,
            Font = Enum.Font.GothamMedium,
            TextSize = 9,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Right
        })
        local StatusDivider = Create("Frame", {
            Parent = AutoCard,
            Position = UDim2.fromOffset(15, 60),
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

        local function NaturalSortKey(value)
            return tostring(value):lower():gsub("%d+", function(number)
                return string.format("%03d", #number) .. number
            end)
        end

        local CachedPathsFolder = workspace:FindFirstChild("Paths")
        local CachedPathFolders = {}
        local CachedActiveWorldFolder
        local CachedSafeZoneSign = workspace:FindFirstChild("SafeZoneSign", true)

        if CachedPathsFolder then
            for _, pathObject in ipairs(CachedPathsFolder:GetChildren()) do
                if pathObject:IsA("Folder") then
                    local pathNumber = tonumber(pathObject.Name:match("^Path(%d+)$"))
                    if pathNumber and pathNumber >= 1 and pathNumber <= 20 then
                        CachedPathFolders[pathNumber] = pathObject
                    end
                end
            end
        end

        if CachedSafeZoneSign then
            CachedActiveWorldFolder = CachedSafeZoneSign:FindFirstAncestor("Hub")
                or CachedSafeZoneSign:FindFirstAncestor("World2")
        end

        if not CachedActiveWorldFolder and CachedPathsFolder then
            local character = LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if root then
                local closestPathNumber
                local closestPathDistance = math.huge

                for pathNumber, pathObject in pairs(CachedPathFolders) do
                    local pathDistance = math.huge
                    for _, descendant in ipairs(pathObject:GetDescendants()) do
                        if descendant:IsA("BasePart") then
                            local localPosition = descendant.CFrame:PointToObjectSpace(root.Position)
                            local halfSize = descendant.Size * 0.5
                            local outsideX = math.max(math.abs(localPosition.X) - halfSize.X, 0)
                            local outsideY = math.max(math.abs(localPosition.Y) - halfSize.Y, 0)
                            local outsideZ = math.max(math.abs(localPosition.Z) - halfSize.Z, 0)
                            local distance = Vector3.new(outsideX, outsideY, outsideZ).Magnitude
                            if distance < pathDistance then
                                pathDistance = distance
                            end
                            if pathDistance == 0 then
                                break
                            end
                        end
                    end

                    if pathDistance < closestPathDistance then
                        closestPathDistance = pathDistance
                        closestPathNumber = pathNumber
                    end
                end

                if closestPathNumber then
                    CachedActiveWorldFolder = {
                        Name = closestPathNumber >= 11 and "World2" or "Hub"
                    }
                end
            end
        end

        local function GetActiveWorldPathsFolder()
            if not CachedPathsFolder or not CachedActiveWorldFolder then
                return nil, nil, nil
            end
            return CachedPathsFolder, CachedActiveWorldFolder, CachedSafeZoneSign
        end

        local function IsPathInActiveWorld(pathObject)
            if not pathObject or not CachedActiveWorldFolder then return false end
            local pathNumber = tonumber(pathObject.Name:match("^Path(%d+)$"))
            if not pathNumber then return false end
            if CachedActiveWorldFolder.Name == "World2" then
                return pathNumber >= 11 and pathNumber <= 20
            end
            if CachedActiveWorldFolder.Name == "Hub" then
                return pathNumber >= 1 and pathNumber <= 10
            end
            return false
        end

        local function GetPathFolders()
            local results = {}
            if not CachedPathsFolder or not CachedActiveWorldFolder then
                return results
            end

            local firstPath = CachedActiveWorldFolder.Name == "World2" and 11 or 1
            local lastPath = CachedActiveWorldFolder.Name == "World2" and 20 or 10

            for pathNumber = firstPath, lastPath do
                local pathObject = CachedPathFolders[pathNumber]
                if pathObject and pathObject.Parent == CachedPathsFolder then
                    table.insert(results, pathObject)
                end
            end

            return results
        end

        local PathDisplayNames = {
            Path1 = "Garden",
            Path2 = "Honey",
            Path3 = "Jungle",
            Path4 = "Dino",
            Path5 = "Snow",
            Path6 = "Desert",
            Path7 = "Candy",
            Path8 = "Volcano",
            Path9 = "Sky",
            Path10 = "Space",
            Path11 = "Moon",
            Path12 = "Mars",
            Path13 = "Ocean",
            Path14 = "Crystal",
            Path15 = "Sun",
            Path16 = "Shadow",
            Path17 = "Toxic",
            Path18 = "Storm",
            Path19 = "Ancient",
            Path20 = "BlackHole"
        }

        local function CreateDynamicFilter(label, icon, yPosition, getOptions, selected, onChanged, getDisplayName)
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
                if #options == 0 then
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
                    AddCorner(Check, 4)                    if isSelected then
                        Create("Frame", {
                            Parent = Check,                            Position = UDim2.fromOffset(4, 4),
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
                        Text = getDisplayName and getDisplayName(optionObject)
                            or (typeof(optionObject) == "Instance" and optionObject.Name or tostring(optionObject)),
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

        local RarityOptions = {
            "Common", "Rare", "Epic", "Legendary", "Mythic", "Cosmic",
            "Secret", "Eternal", "Divine", "Infinity", "Astral", "Omega"
        }
        local function GetRarityOptions()
            return RarityOptions
        end
        local PathFilterButton, PathFilterList, PathSectionLabel, PathSectionIcon =
            CreateDynamicFilter(
                "Path Filter",
                "P",
                68,
                GetPathFolders,
                SelectedPaths,
                nil,
                function(pathObject)
                    return PathDisplayNames[pathObject.Name] or pathObject.Name
                end
            )
        local CageFilterButton, CageFilterList, CageSectionLabel, CageSectionIcon =
            CreateDynamicFilter("Cage Filter", "C", 68, GetRarityOptions, SelectedRarities)

        local FilterColumnWidth = 0.5
        PathSectionLabel.Position = UDim2.fromOffset(38, 69)
        PathSectionLabel.Size = UDim2.new(FilterColumnWidth, -22, 0, 22)
        PathSectionIcon.Position = UDim2.fromOffset(15, 70)
        PathFilterButton.Position = UDim2.fromOffset(15, 90)
        PathFilterButton.Size = UDim2.new(FilterColumnWidth, -22, 0, 29)

        CageSectionLabel.Position = UDim2.fromOffset(38, 133)
        CageSectionLabel.Size = UDim2.new(FilterColumnWidth, -22, 0, 22)
        CageSectionIcon.Position = UDim2.fromOffset(15, 134)
        CageFilterButton.Position = UDim2.fromOffset(15, 154)
        CageFilterButton.Size = UDim2.new(FilterColumnWidth, -22, 0, 29)

        local MovementLabel, MovementIcon = MakeSectionLabel("M", "Movement", 133)
        MovementLabel.Position = UDim2.fromOffset(38, 197)
        MovementLabel.Size = UDim2.new(FilterColumnWidth, -22, 0, 22)
        MovementIcon.Position = UDim2.fromOffset(15, 198)
        local MovementHolder = Create("Frame", {
            Parent = AutoCard,
            Position = UDim2.fromOffset(15, 219),
            Size = UDim2.new(1, -30, 0, 29),
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
                BackgroundColor3 = mode == MovementMode and Theme.Accent or Theme.SurfaceInput,
                Text = mode == "Glide" and "Jump" or mode,
                TextColor3 = mode == MovementMode and Theme.AccentText or Theme.DarkGray,
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

        local SpeedLabel, SpeedIcon = MakeSectionLabel("J", "Jump Speed", 69)
        SpeedLabel.Position = UDim2.new(FilterColumnWidth, 30, 0, 69)
        SpeedLabel.Size = UDim2.new(FilterColumnWidth, -22, 0, 22)
        SpeedIcon.Position = UDim2.new(FilterColumnWidth, 7, 0, 70)
        local SpeedHolder = Create("Frame", {
            Parent = AutoCard,
            Position = UDim2.new(FilterColumnWidth, 7, 0, 91),
            Size = UDim2.new(FilterColumnWidth, -22, 0, 54),
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
        Create("TextLabel", {
            Parent = SpeedHolder,
            Position = UDim2.fromOffset(0, 0),
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
            Text = "300",
            TextColor3 = Theme.Gray,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Right
        })
        local GlideSpeed = 275
        local GlideMaxSpeed = 300
        local DraggingSpeed = false
        local function RefreshSpeed()
            local currentPosition = (GlideSpeed - 10) / (GlideMaxSpeed - 10)
            SpeedThumb.Position = UDim2.new(currentPosition, 0, 0.5, 0)
            SpeedFill.Size = UDim2.new(currentPosition, 0, 1, 0)
            SpeedValue.Text = tostring(GlideSpeed)
            SpeedMaxLabel.Text = tostring(GlideMaxSpeed)
            Runtime.GlideSpeed = GlideSpeed
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
        TrackConnection(UserInputService.InputChanged:Connect(function(input)            if DraggingSpeed and (
                input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
            ) then                UpdateSpeed(input)
            end
end))
        TrackConnection(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                DraggingSpeed = false
            end
end))
        RefreshSpeed()

        local JumpDistanceLabel, JumpDistanceIcon = MakeSectionLabel("J", "Jump Distance", 220)
        JumpDistanceLabel.Position = UDim2.new(FilterColumnWidth, 30, 0, 133)
        JumpDistanceLabel.Size = UDim2.new(FilterColumnWidth, -22, 0, 22)
        JumpDistanceIcon.Position = UDim2.new(FilterColumnWidth, 7, 0, 134)

        local JumpDistanceHolder = Create("Frame", {
            Parent = AutoCard,
            Position = UDim2.new(FilterColumnWidth, 7, 0, 155),
            Size = UDim2.new(FilterColumnWidth, -22, 0, 54),
            BackgroundTransparency = 1
        })
        local JumpDistanceValue = Create("TextLabel", {
            Parent = JumpDistanceHolder,
            Position = UDim2.new(1, -78, 0, 0),
            Size = UDim2.fromOffset(78, 18),
            BackgroundTransparency = 1,
            Text = "50",
            TextColor3 = Theme.Text,
            Font = Enum.Font.GothamMedium,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Right
        })
        local JumpDistanceBar = Create("Frame", {
            Parent = JumpDistanceHolder,
            Position = UDim2.fromOffset(0, 25),
            Size = UDim2.new(1, 0, 0, 6),
            BackgroundColor3 = Theme.LightGray,
            BorderSizePixel = 0
        })
        AddCorner(JumpDistanceBar, 8)
        local JumpDistanceFill = Create("Frame", {
            Parent = JumpDistanceBar,
            Size = UDim2.new((50 - 10) / (100 - 10), 0, 1, 0),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0
        })
        AddCorner(JumpDistanceFill, 8)
        local JumpDistanceThumb = Create("Frame", {
            Parent = JumpDistanceBar,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new((50 - 10) / (100 - 10), 0, 0.5, 0),
            Size = UDim2.fromOffset(13, 13),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            ZIndex = 3
        })
        AddCorner(JumpDistanceThumb, 10)
        AddStroke(JumpDistanceThumb, Theme.Card, 1)
        Create("TextLabel", {
            Parent = JumpDistanceHolder,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromOffset(35, 16),
            BackgroundTransparency = 1,
            Text = "10",
            TextColor3 = Theme.Gray,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        local JumpDistanceMaxLabel = Create("TextLabel", {
            Parent = JumpDistanceHolder,
            Position = UDim2.new(1, -35, 0, 39),
            Size = UDim2.fromOffset(35, 16),
            BackgroundTransparency = 1,
            Text = "100",
            TextColor3 = Theme.Gray,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Right
        })

        local GlideJumpDistance = 80
        local GlideMaxJumpDistance = 100
        local DraggingJumpDistance = false
        local function RefreshJumpDistance()
            local currentPosition = (GlideJumpDistance - 10) / (GlideMaxJumpDistance - 10)
            JumpDistanceThumb.Position = UDim2.new(currentPosition, 0, 0.5, 0)
            JumpDistanceFill.Size = UDim2.new(currentPosition, 0, 1, 0)
            JumpDistanceValue.Text = tostring(GlideJumpDistance) .. " studs"
            JumpDistanceMaxLabel.Text = tostring(GlideMaxJumpDistance)
            Runtime.GlideJumpDistance = GlideJumpDistance
        end
        local function UpdateJumpDistance(input)
            local width = JumpDistanceBar.AbsoluteSize.X
            if width <= 0 then return end
            local position = math.clamp(
                (input.Position.X - JumpDistanceBar.AbsolutePosition.X) / width,
                0,
                1
            )
            GlideJumpDistance = math.floor(10 + position * (GlideMaxJumpDistance - 10) + 0.5)
            RefreshJumpDistance()
        end
        local function BeginJumpDistanceDrag(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
            DraggingJumpDistance = true
            UpdateJumpDistance(input)
        end
        JumpDistanceBar.InputBegan:Connect(BeginJumpDistanceDrag)
        JumpDistanceThumb.InputBegan:Connect(BeginJumpDistanceDrag)
        TrackConnection(UserInputService.InputChanged:Connect(function(input)
            if DraggingJumpDistance and (
                input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
            ) then
                UpdateJumpDistance(input)
            end
        end))
        TrackConnection(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                DraggingJumpDistance = false
            end
        end))
        RefreshJumpDistance()

        Runtime.SelectedPaths = SelectedPaths
        Runtime.SelectedRarities = SelectedRarities

        local navigationToken = 0
        local treadmillToken = 0
        local treadmillStatus = "Disabled"
        local activeNavigationTween
        local nightTimerConnection
        local nightTimerAddedConnection
        local bossCaughtConnection
        local bossCaughtDetected = false
        local nightDetected = false
        local floatingRoot
        local floatingOriginalAnchored

        local function SetFloating(root, enabled)
            if enabled then
                if floatingRoot and floatingRoot ~= root then
                    floatingRoot.Anchored = floatingOriginalAnchored or false
                end
                if floatingRoot ~= root then
                    floatingRoot = root
                    floatingOriginalAnchored = root.Anchored
                end
                root.Anchored = true
            elseif floatingRoot == root then
                root.Anchored = floatingOriginalAnchored or false
                floatingRoot = nil
                floatingOriginalAnchored = nil
            end
        end

        local function RestoreFloating()
            if floatingRoot then
                pcall(function()
                    floatingRoot.Anchored = floatingOriginalAnchored or false
                end)
                floatingRoot = nil
                floatingOriginalAnchored = nil
            end
        end

        local function IsLocalPlayerPlot(ownerName)
            return ownerName == LocalPlayer.Name
                or ownerName == LocalPlayer.DisplayName
        end

        local function GetRidingPetRoot(root)
            local hub = workspace:FindFirstChild("Hub")
            local plots = hub and hub:FindFirstChild("Plots")
            if not plots or not root then
                return nil
            end

            for _, plot in ipairs(plots:GetChildren()) do
                local ownerDisplay = plot:FindFirstChild("OwnerDisplay")
                local gui = ownerDisplay and ownerDisplay:FindFirstChild("Gui")
                local playerName = gui and gui:FindFirstChild("PlayerName")

                if playerName and playerName:IsA("TextLabel")
                and IsLocalPlayerPlot(playerName.Text) then
                    local pets = plot:FindFirstChild("Pets")
                    if not pets then
                        return nil
                    end

                    for _, pet in ipairs(pets:GetChildren()) do
                        local petRoot = pet:FindFirstChild("Root")
                        local riderWeld = petRoot and petRoot:FindFirstChild("RiderWeld")

                        if petRoot and petRoot:IsA("BasePart")
                        and riderWeld and riderWeld:IsA("Weld")
                        and ((riderWeld.Part0 == root and riderWeld.Part1 == petRoot)
                        or (riderWeld.Part1 == root and riderWeld.Part0 == petRoot)) then
                            return petRoot
                        end
                    end
                end
            end

            return nil
        end

        local function IsRidingPet(root)
            return GetRidingPetRoot(root) ~= nil
        end

        Runtime.IsRidingPet = function()
            local character = LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            return root ~= nil and GetRidingPetRoot(root) ~= nil
        end

        local function GetOwnedPlotPosition()
            local hub = workspace:FindFirstChild("Hub")
            local plots = hub and hub:FindFirstChild("Plots")
            if not plots then return nil end

            for _, plot in ipairs(plots:GetChildren()) do
                local ownerDisplay = plot:FindFirstChild("OwnerDisplay")
                local gui = ownerDisplay and ownerDisplay:FindFirstChild("Gui")
                local playerName = gui and gui:FindFirstChild("PlayerName")

                if playerName and playerName:IsA("TextLabel")
                and IsLocalPlayerPlot(playerName.Text) then
                    if ownerDisplay:IsA("BasePart") then
                        return ownerDisplay.Position
                    end
                    if ownerDisplay:IsA("Model") then
                        return ownerDisplay:GetPivot().Position
                    end
                    local displayPart = ownerDisplay:FindFirstChildWhichIsA("BasePart", true)
                    return displayPart and displayPart.Position or nil
                end
            end

            return nil
        end

        local function GetOwnedTreadmill()
            local hub = workspace:FindFirstChild("Hub")
            local plots = hub and hub:FindFirstChild("Plots")
            if not plots then return nil end

            for _, plot in ipairs(plots:GetChildren()) do
                local ownerDisplay = plot:FindFirstChild("OwnerDisplay")
                local gui = ownerDisplay and ownerDisplay:FindFirstChild("Gui")
                local playerName = gui and gui:FindFirstChild("PlayerName")

                if playerName and playerName:IsA("TextLabel")
                and IsLocalPlayerPlot(playerName.Text) then
                    local treadmill = plot:FindFirstChild("Treadmill", true)
                    if treadmill and treadmill:IsA("BasePart") then
                        return treadmill
                    end
                    if treadmill and treadmill:IsA("Model") then
                        return treadmill.PrimaryPart or treadmill:FindFirstChildWhichIsA("BasePart", true)
                    end
                    return nil
                end
            end

            return nil
        end

        local function GetNavigationRoot(root)
            return GetRidingPetRoot(root) or root
        end

        local function GetPromptWorldPosition(prompt)
            local current = prompt and prompt.Parent
            while current and current ~= workspace do
                if current:IsA("Attachment") then
                    return current.WorldPosition
                end
                if current:IsA("BasePart") then
                    return current.Position
                end
                current = current.Parent
            end
            return nil
        end

        local function GetHumanoidMoveDestination(root, navigationRoot, destination)
            return destination + (root.Position - navigationRoot.Position)
        end

        local function IsNavigationAtDestination(navigationRoot, destination, horizontalTolerance)
            if not navigationRoot or not navigationRoot.Parent then
                return false
            end

            local delta = destination - navigationRoot.Position
            local horizontal = Vector3.new(delta.X, 0, delta.Z)
            local verticalTolerance = 4
            local petModel = navigationRoot:FindFirstAncestorOfClass("Model")
            if petModel then
                local ok, bounds = pcall(function()
                    return petModel:GetExtentsSize()
                end)
                if ok and bounds then
                    verticalTolerance = math.max(verticalTolerance, bounds.Y * 0.5 + 2)
                end
            end

            return horizontal.Magnitude <= (horizontalTolerance or 4)
                and math.abs(delta.Y) <= verticalTolerance
        end

        local function ShouldWalk(root)
            return MovementMode == "Walk"
        end

        local function SetNavigationStatus(message)
            if StatusValue then
                StatusValue.Text = message
                StatusValue.TextColor3 = Theme.Accent
            end
        end

        local function SetAutoStealEnabled(enabled)
            if enabled and not HasSelectedFilter() then
                enabled = false
                if StatusValue then
                    StatusValue.Text = "Select at least 1 filter"
                    StatusValue.TextColor3 = Color3.fromRGB(255, 190, 80)
                end
            end

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

        local function BrakeAtDestination(root, humanoid, token)
            if token ~= navigationToken or Runtime.Stopped
            or not root or not root.Parent
            or not humanoid or not humanoid.Parent then
                return
            end

            local navigationRoot = GetNavigationRoot(root)
            if not navigationRoot or not navigationRoot.Parent then
                return
            end

            humanoid:MoveTo(root.Position)
            humanoid:Move(Vector3.zero, false)

            if not navigationRoot.Anchored then
                local velocity = navigationRoot.AssemblyLinearVelocity
                local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
                local speed = horizontalVelocity.Magnitude

                if speed >= 2 then
                    local attachment = Instance.new("Attachment")
                    attachment.Name = "SAPARIBrakeAttachment"
                    attachment.Parent = navigationRoot

                    local brake = Instance.new("VectorForce")
                    brake.Name = "SAPARIMomentumBrake"
                    brake.Attachment0 = attachment
                    brake.RelativeTo = Enum.ActuatorRelativeTo.World
                    brake.ApplyAtCenterOfMass = true
                    brake.Force = -horizontalVelocity.Unit
                        * navigationRoot.AssemblyMass
                        * math.clamp(speed / 0.18, 0, 220)
                    brake.Parent = navigationRoot

                    local brakeUntil = os.clock() + 0.18
                    while os.clock() < brakeUntil do
                        if token ~= navigationToken or Runtime.Stopped
                        or not root.Parent or not humanoid.Parent
                        or not navigationRoot.Parent then
                            break
                        end
                        RunService.Heartbeat:Wait()
                    end

                    brake:Destroy()
                    attachment:Destroy()
                end
            end

            if humanoid.Parent then
                humanoid:Move(Vector3.zero, false)
                humanoid:MoveTo(root.Position)
            end
        end
        local function MoveToPosition(root, humanoid, destination, token, forceWalk, startWithWalk)
            if token ~= navigationToken or Runtime.Stopped then
                return false
            end

            local navigationRoot = GetNavigationRoot(root)
            if not navigationRoot or not navigationRoot.Parent then
                return false
            end

            if forceWalk or MovementMode == "Walk" then
                local ridingOffset = navigationRoot ~= root
                    and (root.Position - navigationRoot.Position)
                    or Vector3.zero
                local moveDestination = destination + ridingOffset
                local distance = (navigationRoot.Position - destination).Magnitude
                local speed = math.max(humanoid.WalkSpeed, 1)
                local timeout = os.clock() + math.max(5, distance / speed + 5)
                local nextMoveRefresh = 0

                while os.clock() < timeout do
                    if bossCaughtDetected then
                        humanoid:MoveTo(root.Position)
                        RestoreFloating()
                        return false
                    end

                    if nightDetected then
                        humanoid:MoveTo(root.Position)
                        RestoreFloating()
                        return false
                    end

                    if token ~= navigationToken or Runtime.Stopped then
                        humanoid:MoveTo(root.Position)
                        return false
                    end

                    if not root.Parent or not humanoid.Parent
                    or not navigationRoot.Parent then
                        return false
                    end

                    if IsNavigationAtDestination(navigationRoot, destination) then
                        BrakeAtDestination(root, humanoid, token)
                        return true
                    end

                    if os.clock() >= nextMoveRefresh then
                        humanoid:MoveTo(moveDestination)
                        nextMoveRefresh = os.clock() + 1.5
                    end

                    RunService.Heartbeat:Wait()
                end

                humanoid:MoveTo(root.Position)
                if not navigationRoot.Parent then return false end
                return IsNavigationAtDestination(navigationRoot, destination)
            end

            local speed = math.max(10, Runtime.GlideSpeed or 50)
            local glideHeight = humanoid.HipHeight + (navigationRoot.Size.Y * 0.5)
            local finalGlideStop = 12
            local alternatingWalkDuration = 1
            local walkDuration = alternatingWalkDuration

            if startWithWalk then
                local ridingOffset = root.Position - navigationRoot.Position
                humanoid:MoveTo(destination + ridingOffset)

                local initialWalkUntil = os.clock() + alternatingWalkDuration
                local nextMoveRefresh = os.clock() + 1
                while os.clock() < initialWalkUntil do
                    if bossCaughtDetected then
                        humanoid:MoveTo(root.Position)
                        RestoreFloating()
                        return false
                    end

                    if nightDetected then
                        humanoid:MoveTo(root.Position)
                        RestoreFloating()
                        return false
                    end

                    if token ~= navigationToken or Runtime.Stopped then
                        humanoid:MoveTo(root.Position)
                        return false
                    end

                    navigationRoot = GetNavigationRoot(root)
                    if not root.Parent or not humanoid.Parent
                    or not navigationRoot or not navigationRoot.Parent then
                        humanoid:MoveTo(root.Position)
                        return false
                    end

                    if IsNavigationAtDestination(navigationRoot, destination) then
                        BrakeAtDestination(root, humanoid, token)
                        return true
                    end

                    if os.clock() >= nextMoveRefresh then
                        ridingOffset = root.Position - navigationRoot.Position
                        humanoid:MoveTo(destination + ridingOffset)
                        nextMoveRefresh = os.clock() + 1
                    end

                    RunService.Heartbeat:Wait()
                end

                humanoid:MoveTo(root.Position)
            end

            while token == navigationToken and not Runtime.Stopped do
                navigationRoot = GetNavigationRoot(root)
                if not root.Parent or not humanoid.Parent
                or not navigationRoot or not navigationRoot.Parent then
                    RestoreFloating()
                    return false
                end

                local routeTarget = destination
                local remaining = routeTarget - navigationRoot.Position
                local horizontal = Vector3.new(remaining.X, 0, remaining.Z)
                local horizontalDistance = horizontal.Magnitude

                if IsNavigationAtDestination(navigationRoot, destination) then
                    BrakeAtDestination(root, humanoid, token)
                    SetFloating(navigationRoot, false)
                    return true
                end

                if horizontalDistance > finalGlideStop then
                    local jumpDistance = math.clamp(Runtime.GlideJumpDistance or 50, 10, 150)
                    local glideDistance = math.min(jumpDistance, horizontalDistance - finalGlideStop)
                    local direction = horizontal.Unit
                    local segmentPosition = navigationRoot.Position + direction * glideDistance
                    segmentPosition = Vector3.new(
                        segmentPosition.X,
                        destination.Y + glideHeight,
                        segmentPosition.Z
                    )

                    local duration = math.max(0.03, glideDistance / speed)
                    local target = CFrame.new(segmentPosition) * navigationRoot.CFrame.Rotation

                    SetFloating(navigationRoot, true)
                    local tween = TweenService:Create(
                        navigationRoot,
                        TweenInfo.new(duration, Enum.EasingStyle.Linear),
                        {CFrame = target}
                    )

                    activeNavigationTween = tween
                    tween:Play()
                    local state = tween.Completed:Wait()

                    if activeNavigationTween == tween then
                        activeNavigationTween = nil
                    end

                    SetFloating(navigationRoot, false)

                    if state ~= Enum.PlaybackState.Completed
                    or token ~= navigationToken or Runtime.Stopped then
                        humanoid:MoveTo(root.Position)
                        return false
                    end
                end

                local ridingOffset = root.Position - navigationRoot.Position
                local moveDestination = destination + ridingOffset
                humanoid:MoveTo(moveDestination)

                local walkUntil = os.clock() + walkDuration
                local nextMoveRefresh = os.clock() + 1
                while os.clock() < walkUntil do
                    if bossCaughtDetected then
                        humanoid:MoveTo(root.Position)
                        RestoreFloating()
                        return false
                    end

                    if nightDetected then
                        humanoid:MoveTo(root.Position)
                        RestoreFloating()
                        return false
                    end

                    if token ~= navigationToken or Runtime.Stopped then
                        humanoid:MoveTo(root.Position)
                        return false
                    end

                    if not root.Parent or not humanoid.Parent
                    or not navigationRoot.Parent then
                        humanoid:MoveTo(root.Position)
                        return false
                    end

                    if IsNavigationAtDestination(navigationRoot, destination) then
                        BrakeAtDestination(root, humanoid, token)
                        return true
                    end

                    if os.clock() >= nextMoveRefresh then
                        ridingOffset = root.Position - navigationRoot.Position
                        humanoid:MoveTo(destination + ridingOffset)
                        nextMoveRefresh = os.clock() + 1
                    end

                    RunService.Heartbeat:Wait()
                end

                humanoid:MoveTo(root.Position)
            end

            SetFloating(GetNavigationRoot(root), false)
            return token == navigationToken and not Runtime.Stopped
        end
        Runtime.StopNavigation = function()
            navigationToken += 1
            if bossCaughtConnection then
                bossCaughtConnection:Disconnect()
                bossCaughtConnection = nil
            end
            if nightTimerConnection then
                nightTimerConnection:Disconnect()
                nightTimerConnection = nil
            end
            if nightTimerAddedConnection then
                nightTimerAddedConnection:Disconnect()
                nightTimerAddedConnection = nil
            end
            CancelActiveMovement()
            RestoreFloating()
            SetAutoStealEnabled(false)
            SetNavigationStatus("Stopped")
            if AutoTreadmillEnabled and not Runtime.Stopped then
                task.defer(function()
                    if Runtime.StartTreadmillIdle then
                        Runtime.StartTreadmillIdle()
                    end
                end)
            end
        end

        Runtime.StopTreadmillIdle = function()
            treadmillToken += 1
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if humanoid and root then
                humanoid:MoveTo(root.Position)
            end
        end

        Runtime.StartTreadmillIdle = function()
            if Runtime.Stopped or not AutoTreadmillEnabled or AutoStealEnabled then
                return
            end

            treadmillToken += 1
            local token = treadmillToken
            task.spawn(function()
                while token == treadmillToken and AutoTreadmillEnabled
                and not AutoStealEnabled and not Runtime.Stopped do
                    local treadmill = GetOwnedTreadmill()
                    local character = LocalPlayer.Character
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                    local root = character and character:FindFirstChild("HumanoidRootPart")

                    if not treadmill then
                        if AutoTreadmillStatusValue then
                            treadmillStatus = "Treadmill unavailable"
                            AutoTreadmillStatusValue.Text = treadmillStatus
                            AutoTreadmillStatusValue.TextColor3 = Color3.fromRGB(255, 190, 80)
                        end
                        if AutoTreadmillStatusDot then
                            AutoTreadmillStatusDot.BackgroundColor3 = Color3.fromRGB(255, 190, 80)
                        end
                        task.wait(1)
                    elseif humanoid and root then
                        local navigationRoot = GetNavigationRoot(root)
                        if not navigationRoot or not navigationRoot.Parent then
                            task.wait(0.25)
                            continue
                        end
                        local distance = (navigationRoot.Position - treadmill.Position).Magnitude
                        if distance <= 4 then
                            humanoid:MoveTo(root.Position)
                            if AutoTreadmillStatusValue then
                                treadmillStatus = "Running"
                                AutoTreadmillStatusValue.Text = treadmillStatus
                                AutoTreadmillStatusValue.TextColor3 = Color3.fromRGB(75, 190, 145)
                            end
                            if AutoTreadmillStatusDot then
                                AutoTreadmillStatusDot.BackgroundColor3 = Color3.fromRGB(75, 190, 145)
                            end
                            task.wait(0.25)
                        else
                            if AutoTreadmillStatusValue then
                                treadmillStatus = "Walking"
                                AutoTreadmillStatusValue.Text = treadmillStatus
                                AutoTreadmillStatusValue.TextColor3 = Theme.Accent
                            end
                            if AutoTreadmillStatusDot then
                                AutoTreadmillStatusDot.BackgroundColor3 = Color3.fromRGB(75, 190, 145)
                            end
                            humanoid:MoveTo(GetHumanoidMoveDestination(root, navigationRoot, treadmill.Position))
                            task.wait(0.75)
                        end
                    else
                        task.wait(0.25)
                    end
                end
            end)
        end

        Runtime.StartNavigation = function()
            navigationToken += 1
            if Runtime.StopTreadmillIdle then
                Runtime.StopTreadmillIdle()
            end
            local token = navigationToken            CancelActiveMovement()

            if Runtime.Stopped then
                SetAutoStealEnabled(false)
                return            end

            local pathsFolder, worldFolder, safeSign = GetActiveWorldPathsFolder()
            if not safeSign or not safeSign:IsA("BasePart")
            or not worldFolder or not pathsFolder then
                SetNavigationStatus("World paths unavailable")
                SetAutoStealEnabled(false)
                return
            end

            if not HasSelectedFilter() then
                SetNavigationStatus("Select at least 1 filter")
                SetAutoStealEnabled(false)
                return
            end

            nightDetected = false
            bossCaughtDetected = false
            if bossCaughtConnection then
                bossCaughtConnection:Disconnect()
                bossCaughtConnection = nil
            end
            if nightTimerConnection then
                nightTimerConnection:Disconnect()
                nightTimerConnection = nil
            end
            if nightTimerAddedConnection then
                nightTimerAddedConnection:Disconnect()
                nightTimerAddedConnection = nil
            end

            local sharedRemotes = ReplicatedStorage:FindFirstChild("Shared")
                and ReplicatedStorage.Shared:FindFirstChild("Remotes")
            local bossCaughtRemote = sharedRemotes and sharedRemotes:FindFirstChild("BossCaught")

            if bossCaughtRemote and bossCaughtRemote:IsA("RemoteEvent") then
                bossCaughtConnection = bossCaughtRemote.OnClientEvent:Connect(function(playerId, bossName, direction)
                    if token ~= navigationToken or Runtime.Stopped then return end
                    if tonumber(playerId) ~= LocalPlayer.UserId then return end
                    if bossCaughtDetected then return end

                    bossCaughtDetected = true

                    if activeNavigationTween then
                        activeNavigationTween:Cancel()
                    end

                    SetNavigationStatus("Boss caught - recovering")
                end)
            end

            local lastAttemptedCagePath
            local lastAttemptedCageSpot
            local prioritizeDroppedCageRecovery = false

            local function WaitForBossCaught()
                if not bossCaughtDetected then return false end

                RestoreFloating()
                SetNavigationStatus("Boss caught - waiting for recovery")

                local recoveryStarted = os.clock()
                local recoveryTimeout = 12
                local stableChecks = 0

                while os.clock() - recoveryStarted < recoveryTimeout do
                    if token ~= navigationToken or Runtime.Stopped then
                        return false
                    end

                    local character = LocalPlayer.Character
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                    local root = character and character:FindFirstChild("HumanoidRootPart")
                    local petRoot = root and GetRidingPetRoot(root)
                    local state = humanoid and humanoid:GetState()

                    local characterRecovered = humanoid
                        and humanoid.Health > 0
                        and root and root.Parent
                        and state ~= Enum.HumanoidStateType.GettingUp
                        and state ~= Enum.HumanoidStateType.FallingDown
                        and state ~= Enum.HumanoidStateType.Freefall
                        and state ~= Enum.HumanoidStateType.Physics
                        and state ~= Enum.HumanoidStateType.PlatformStanding
                        and state ~= Enum.HumanoidStateType.Ragdoll
                        and state ~= Enum.HumanoidStateType.Dead

                    if characterRecovered and petRoot and petRoot.Parent then
                        stableChecks += 1
                        if stableChecks >= 3 then
                            break
                        end
                    else
                        stableChecks = 0
                    end

                    task.wait(0.2)
                end

                if token ~= navigationToken or Runtime.Stopped then
                    return false
                end

                if stableChecks < 3 then
                    bossCaughtDetected = false
                    nightDetected = false
                    SetAutoStealEnabled(false)
                    SetNavigationStatus("Recovery timed out - please ride a pet again")
                    return false
                end

                bossCaughtDetected = false
                nightDetected = false
                prioritizeDroppedCageRecovery = lastAttemptedCagePath ~= nil
                    and lastAttemptedCageSpot ~= nil
                SetNavigationStatus("Recovery complete - checking dropped cage")
                return true
            end
            local nightRecoveryPending = false
            local treadmillCageSafeZonePending = false
            local playerGui = LocalPlayer:WaitForChild("PlayerGui")
            local watchedNightTimer

            local function HandleNightStarted()
                if nightDetected or bossCaughtDetected then
                    return
                end

                nightDetected = true
                nightRecoveryPending = true
                CancelActiveMovement()
                RestoreFloating()
                SetNavigationStatus("Night detected - waiting 12s")
            end

            local function AttachNightTimer(timer)
                if not timer or not (timer:IsA("TextLabel") or timer:IsA("TextButton"))
                or watchedNightTimer == timer then
                    return
                end

                if nightTimerConnection then
                    nightTimerConnection:Disconnect()
                    nightTimerConnection = nil
                end

                watchedNightTimer = timer
                local wasNight = string.find(string.lower(timer.Text), "night", 1, true) ~= nil
                if wasNight then
                    HandleNightStarted()
                end

                nightTimerConnection = timer:GetPropertyChangedSignal("Text"):Connect(function()
                    local isNight = string.find(string.lower(timer.Text), "night", 1, true) ~= nil
                    if isNight and not wasNight then
                        HandleNightStarted()
                    end
                    wasNight = isNight
                end)
            end

            nightTimerAddedConnection = playerGui.DescendantAdded:Connect(function(descendant)
                if descendant.Name == "Timer"
                and descendant.Parent
                and descendant.Parent.Name == "NightHud" then
                    AttachNightTimer(descendant)
                end
            end)

            local nightHud = playerGui:FindFirstChild("NightHud")
            local nightTimer = nightHud and nightHud:FindFirstChild("Timer")
            AttachNightTimer(nightTimer)

            local function WaitForNight()
                if not nightDetected then
                    return false
                end

                CancelActiveMovement()
                RestoreFloating()
                SetNavigationStatus("Night detected - waiting 12s")

                local waitUntil = os.clock() + 12
                while os.clock() < waitUntil do
                    if token ~= navigationToken or Runtime.Stopped then
                        return false
                    end
                    task.wait(math.min(0.1, waitUntil - os.clock()))
                end

                nightDetected = false
                SetNavigationStatus("12s wait complete - restarting cage scan")
                return true
            end

            local function MatchesSelectedKind(cage)
                local kind = string.lower(tostring(cage:GetAttribute("Kind") or ""))

                for selectedKind, selected in pairs(SelectedRarities) do
                    if selected == true
                    and kind ~= ""
                    and kind == string.lower(tostring(selectedKind)) then
                        return true
                    end
                end

                return false
            end
            local function GetMatchingDroppedCage()
                if not prioritizeDroppedCageRecovery then return nil end

                local droppedCagesFolder = workspace:FindFirstChild("DroppedCages")
                local droppedCage = droppedCagesFolder
                    and droppedCagesFolder:FindFirstChild("DroppedCage")

                if not droppedCage or not droppedCage:IsA("Model")
                or not droppedCage:IsDescendantOf(workspace)
                or droppedCage:GetAttribute("Path") ~= lastAttemptedCagePath
                or droppedCage:GetAttribute("Spot") ~= lastAttemptedCageSpot then
                    return nil
                end

                return droppedCage
            end

            local function GetCagePrompt(cageModel)
                if not cageModel or not cageModel.Parent then
                    return nil
                end

                if cageModel.Name == "DroppedCage" then
                    local cageRoot = cageModel:FindFirstChild("Root")
                    local grabPrompt = cageRoot and cageRoot:FindFirstChild("GrabPrompt")
                    if grabPrompt and grabPrompt:IsA("ProximityPrompt") then
                        return grabPrompt
                    end
                    return nil
                end

                local stealPrompt = cageModel:FindFirstChild("StealPrompt", true)
                if stealPrompt and stealPrompt:IsA("ProximityPrompt") then
                    return stealPrompt
                end
                return nil
            end

            local function GetSelectedCages(characterRoot)
                local cages = {}
                if prioritizeDroppedCageRecovery then
                    SetNavigationStatus("Waiting for dropped cage recovery")
                    local recoveryUntil = os.clock() + 12
                    while prioritizeDroppedCageRecovery
                    and os.clock() < recoveryUntil do
                        if token ~= navigationToken or Runtime.Stopped then
                            return cages
                        end

                        local droppedCage = GetMatchingDroppedCage()
                        if droppedCage then
                            prioritizeDroppedCageRecovery = false
                            SetNavigationStatus("Matching dropped cage found - recovering")
                            return { droppedCage }
                        end

                        task.wait(0.1)
                    end

                    prioritizeDroppedCageRecovery = false
                    SetNavigationStatus("Dropped cage not found - resuming scan")
                end

                local hasSelectedPath = false
                local hasSelectedRarity = false

                for _, selected in pairs(SelectedPaths) do
                    if selected == true then
                        hasSelectedPath = true
                        break
                    end
                end
                for _, selected in pairs(SelectedRarities) do
                    if selected == true then
                        hasSelectedRarity = true
                        break
                    end
                end

                local hasFilter = hasSelectedPath or hasSelectedRarity

                if not hasFilter then
                    return cages
                end

                local pathsFolder = GetActiveWorldPathsFolder()
                if not pathsFolder then
                    return cages
                end

                for _, pathObject in ipairs(pathsFolder:GetChildren()) do
                    local pathMatches = IsPathInActiveWorld(pathObject) and SelectedPaths[pathObject] == true
                    local cagesFolder = pathObject:FindFirstChild("Cages")

                    if cagesFolder then
                        local modelCount = 0
                        for _, cage in ipairs(cagesFolder:GetChildren()) do
                            if cage:IsA("Model") then
                                modelCount += 1
                                local rarityMatches = MatchesSelectedKind(cage)
                                local activeWorldPath = IsPathInActiveWorld(pathObject)
                                local matchesSelectedPath = not hasSelectedPath or pathMatches
                                local matchesSelectedRarity = not hasSelectedRarity or rarityMatches
                                local matchesFilters = activeWorldPath
                                    and matchesSelectedPath
                                    and matchesSelectedRarity
                                if matchesFilters then
                                    table.insert(cages, cage)
                                end
                            end
                        end
                    end
                end
                local navigationRoot = characterRoot and GetNavigationRoot(characterRoot)
                if navigationRoot and navigationRoot.Parent then
                    local cageDistances = {}
                    for _, cage in ipairs(cages) do
                        local ok, position = pcall(function()
                            return cage:GetPivot().Position
                        end)
                        if not ok then
                            local part = cage:FindFirstChildWhichIsA("BasePart", true)
                            position = part and part.Position
                        end
                        cageDistances[cage] = position
                            and (position - navigationRoot.Position).Magnitude
                            or math.huge
                    end
                    table.sort(cages, function(a, b)
                        return cageDistances[a] < cageDistances[b]
                    end)
                else
                    local cageSortKeys = {}
                    for _, cage in ipairs(cages) do
                        local names = {}
                        local current = cage
                        while current and current ~= workspace do
                            table.insert(names, 1, current.Name)
                            current = current.Parent
                        end
                        cageSortKeys[cage] = NaturalSortKey(table.concat(names, "/"))
                    end
                    table.sort(cages, function(a, b)
                        return cageSortKeys[a] < cageSortKeys[b]
                    end)
                end
                return cages
            end

            local function Jump(humanoid)
                if not humanoid or humanoid.Health <= 0 then
                    return
                end

                humanoid.Jump = true
                pcall(function()
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end)
                task.wait(0.1)
            end

            local function WaitAtTreadmillUntilCage(root, humanoid, token)
                local treadmill = GetOwnedTreadmill()

                if not treadmill or not treadmill:IsA("BasePart") then
                    treadmillStatus = "Treadmill unavailable"
                    if AutoTreadmillStatusValue then
                        AutoTreadmillStatusValue.Text = treadmillStatus
                        AutoTreadmillStatusValue.TextColor3 = Color3.fromRGB(255, 190, 80)
                    end
                    if AutoTreadmillStatusDot then
                        AutoTreadmillStatusDot.BackgroundColor3 = Color3.fromRGB(255, 190, 80)
                    end
                    return
                end

                local destination = treadmill.Position
                local nextMoveRefresh = 0
                local arrived = false

                treadmillStatus = "Walking"
                if AutoTreadmillStatusValue then
                    AutoTreadmillStatusValue.Text = treadmillStatus
                    AutoTreadmillStatusValue.TextColor3 = Theme.Accent
                end
                if AutoTreadmillStatusDot then
                    AutoTreadmillStatusDot.BackgroundColor3 = Color3.fromRGB(75, 190, 145)
                end

                while token == navigationToken and not Runtime.Stopped
                and AutoTreadmillEnabled and AutoStealEnabled do
                    if bossCaughtDetected or nightDetected then
                        humanoid:MoveTo(root.Position)
                        return
                    end

                    if #GetSelectedCages() > 0 then
                        if treadmillStatus == "Running" then
                            Jump(humanoid)
                        end
                        treadmillCageSafeZonePending = true
                        humanoid:MoveTo(root.Position)
                        if AutoTreadmillStatusValue then
                            treadmillStatus = "Waiting"
                            AutoTreadmillStatusValue.Text = treadmillStatus
                            AutoTreadmillStatusValue.TextColor3 = Color3.fromRGB(255, 190, 80)
                        end
                        if AutoTreadmillStatusDot then
                            AutoTreadmillStatusDot.BackgroundColor3 = Color3.fromRGB(255, 190, 80)
                        end
                        return
                    end

                    if not root.Parent or not humanoid.Parent then
                        return
                    end

                    local navigationRoot = GetNavigationRoot(root)
                    if not navigationRoot or not navigationRoot.Parent then
                        return
                    end
                    local distance = (navigationRoot.Position - destination).Magnitude
                    if distance <= 4 then
                        if not arrived then
                            humanoid:MoveTo(root.Position)
                            arrived = true
                            treadmillStatus = "Running"
                            if AutoTreadmillStatusValue then
                                AutoTreadmillStatusValue.Text = treadmillStatus
                                AutoTreadmillStatusValue.TextColor3 = Color3.fromRGB(75, 190, 145)
                            end
                            if AutoTreadmillStatusDot then
                                AutoTreadmillStatusDot.BackgroundColor3 = Color3.fromRGB(75, 190, 145)
                            end
                        end
                    elseif os.clock() >= nextMoveRefresh then
                        navigationRoot = GetNavigationRoot(root)
                        if not navigationRoot or not navigationRoot.Parent then
                            return
                        end
                        humanoid:MoveTo(GetHumanoidMoveDestination(root, navigationRoot, destination))
                        nextMoveRefresh = os.clock() + 1
                    end

                    RunService.Heartbeat:Wait()
                end

                humanoid:MoveTo(root.Position)
                if not AutoTreadmillEnabled and AutoTreadmillStatusValue then
                    treadmillStatus = "Disabled"
                    AutoTreadmillStatusValue.Text = treadmillStatus
                    AutoTreadmillStatusValue.TextColor3 = Theme.Gray
                    if AutoTreadmillStatusDot then
                        AutoTreadmillStatusDot.BackgroundColor3 = Theme.Gray
                    end
                end
            end

            local function MoveToCage(root, humanoid, destination, token, cageModel)
                local navigationRoot = GetRidingPetRoot(root)
                if not navigationRoot or not navigationRoot.Parent then
                    return false, "Riding pet root unavailable"
                end

                local function IsPetAtCage()
                    local petRoot = GetRidingPetRoot(root)
                    if not petRoot or not petRoot.Parent then
                        return false
                    end

                    local targetPosition = destination
                    if cageModel and cageModel.Parent then
                        local prompt = GetCagePrompt(cageModel)
                        if prompt then
                            targetPosition = GetPromptWorldPosition(prompt) or targetPosition
                        end
                    end

                    local delta = targetPosition - petRoot.Position
                    local horizontalDistance = Vector3.new(delta.X, 0, delta.Z).Magnitude
                    return horizontalDistance <= 12 and math.abs(delta.Y) <= 20
                end
                if IsPetAtCage() then
                    SetNavigationStatus("Cage nearby")
                    return true
                end

                if ShouldWalk(root) then
                    SetNavigationStatus("Walking to cage")
                    local reached = MoveToPosition(root, humanoid, destination, token, true)
                    if reached then
                        return true
                    end

                    if token ~= navigationToken or Runtime.Stopped then
                        return false, "Navigation stopped"
                    end

                    SetNavigationStatus("Rechecking cage position")
                    if IsPetAtCage() then
                        SetNavigationStatus("Cage nearby - checking steal prompt")
                        return true
                    end

                    return false, "Failed to reach cage"
                end

                local ridingOffset = root.Position - navigationRoot.Position
                local approachDirection = Vector3.new(
                    navigationRoot.Position.X - destination.X,
                    0,
                    navigationRoot.Position.Z - destination.Z
                )
                if approachDirection.Magnitude < 0.01 then
                    local look = root.CFrame.LookVector
                    approachDirection = Vector3.new(look.X, 0, look.Z)
                end
                if approachDirection.Magnitude < 0.01 then
                    approachDirection = Vector3.new(0, 0, -1)
                end

                local approachPosition = destination + approachDirection.Unit * 3.5
                local petDestination = approachPosition - ridingOffset
                SetNavigationStatus("Walking to cage")
                if not MoveToPosition(root, humanoid, petDestination, token, false, true) then
                    if IsPetAtCage() then
                        SetNavigationStatus("Cage nearby")
                        return true
                    end
                    return false, "Failed to reach cage"
                end
                SetNavigationStatus("Cage reached")
                return true
            end
            local function WalkToSafeZoneAtStart()
                while token == navigationToken and not Runtime.Stopped do
                    if bossCaughtDetected then
                        return WaitForBossCaught()
                    end
                    if nightDetected and not WaitForNight() then return false end
                    local character = LocalPlayer.Character
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                    local root = character and character:FindFirstChild("HumanoidRootPart")
                    if not humanoid or not root then
                        SetNavigationStatus("Waiting for character")
                        task.wait(0.25)
                    else
                        SetNavigationStatus("Walking to safe zone")
                        local safeZoneDestination = safeSign.Position
                        safeZoneNavigationActive = true
                        local reachedSafeZone = MoveToPosition(root, humanoid, safeZoneDestination, token, true)
                        safeZoneNavigationActive = false
                        if reachedSafeZone then
                            nightRecoveryPending = false
                            SetNavigationStatus("Safe zone reached")
                            return true
                        end
                        RestoreFloating()
                        if bossCaughtDetected then
                            return WaitForBossCaught()
                        end
                        if nightDetected then
                            if not WaitForNight() then return false end
                        else
                            if token == navigationToken then
                                SetAutoStealEnabled(false)
                                SetNavigationStatus("Failed to reach safe zone")
                            end
                            return false
                        end
                    end
                end
                return false
            end
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local skipInitialSafeZone = false
            local navigationRoot = root and GetNavigationRoot(root)
            if safeSign and safeSign:IsA("BasePart")
            and navigationRoot and navigationRoot.Parent then
                for _, cage in ipairs(GetSelectedCages(root)) do
                    local ok, cagePosition = pcall(function()
                        return cage:GetPivot().Position
                    end)
                    if ok and cagePosition
                    and (cagePosition - navigationRoot.Position).Magnitude <= 200 then
                        skipInitialSafeZone = true
                        break
                    end
                end
            end

            local firstCharacter = LocalPlayer.Character
            local firstHumanoid = firstCharacter and firstCharacter:FindFirstChildOfClass("Humanoid")
            Jump(firstHumanoid)

            if skipInitialSafeZone then
                SetNavigationStatus("Selected cage nearby - skipping safe zone")
            elseif not WalkToSafeZoneAtStart() then
                return
            end

            while token == navigationToken and not Runtime.Stopped do
                if bossCaughtDetected then
                    if not WaitForBossCaught() then return end
                end

                if nightDetected then
                    if not WaitForNight() then return end
                end

                if nightRecoveryPending then
                    SetNavigationStatus("Returning to safe zone after night trigger")
                    if not WalkToSafeZoneAtStart() then return end
                    nightRecoveryPending = false
                    continue
                end

                if treadmillCageSafeZonePending then
                    SetNavigationStatus("Cage found - returning to safe zone")
                    if not WalkToSafeZoneAtStart() then return end
                    treadmillCageSafeZonePending = false
                    continue
                end

                local selectedCages = GetSelectedCages(LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))
                if #selectedCages == 0 then
                    if AutoTreadmillEnabled then
                        SetNavigationStatus("Walking to treadmill")
                        local character = LocalPlayer.Character
                        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                        local root = character and character:FindFirstChild("HumanoidRootPart")
                        if humanoid and root then
                            WaitAtTreadmillUntilCage(root, humanoid, token)
                            task.wait(0.25)
                        else
                            task.wait(0.25)
                        end
                        continue
                    end
                    if MovementMode == "Walk" then
                        SetNavigationStatus("Scanning for available cages")
                        task.wait(0.25)
                        continue
                    end
                    SetNavigationStatus("Waiting for cages")
                    task.wait(0.25)
                    continue
                end

                for _, selectedCage in ipairs(selectedCages) do
                    if token ~= navigationToken or Runtime.Stopped then return end
                    if not selectedCage.Parent then continue end

                    lastAttemptedCagePath = selectedCage:GetAttribute("Path")
                    lastAttemptedCageSpot = selectedCage:GetAttribute("Spot")

                    local character = LocalPlayer.Character
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                    local root = character and character:FindFirstChild("HumanoidRootPart")
                    if not humanoid or not root then
                        SetNavigationStatus("Target unavailable")
                        continue
                    end

                    local cagePosition
                    local positionOk = pcall(function()
                        cagePosition = selectedCage:GetPivot().Position
                    end)
                    if not positionOk or not cagePosition then
                        local fallbackPart = selectedCage:FindFirstChildWhichIsA("BasePart", true)
                        cagePosition = fallbackPart and fallbackPart.Position
                    end
                    if not cagePosition then
                        SetNavigationStatus("Invalid cage position - skipping")
                        continue
                    end

                    local stealPrompt

                    if token ~= navigationToken or Runtime.Stopped then
                        RestoreFloating()
                        return
                    end
                    if bossCaughtDetected then
                        if not WaitForBossCaught() then return end
                        break
                    end
                    if nightDetected then
                        if not WaitForNight() then return end
                        break
                    end

                    SetFloating(root, false)
                    local moveOk, reachedCage, navigationFailure = pcall(function()
                        local reached, failure = MoveToCage(root, humanoid, cagePosition, token, selectedCage)
                        return reached, failure
                    end)
                    if not moveOk then
                        RestoreFloating()
                        SetNavigationStatus("Cage navigation error - skipping")
                        continue
                    end
                    if not reachedCage then
                        RestoreFloating()
                        if bossCaughtDetected then
                            if not WaitForBossCaught() then return end
                            break
                        end
                        if nightDetected then
                            if not WaitForNight() then return end
                            break
                        end
                        if token == navigationToken then
                            SetNavigationStatus((navigationFailure or "Cage navigation failed") .. " - skipping cage")
                        end
                        continue
                    end

                    if token ~= navigationToken or Runtime.Stopped then
                        RestoreFloating()
                        return
                    end

                    if bossCaughtDetected then
                        if not WaitForBossCaught() then return end
                        break
                    end

                    if nightDetected then
                        if not WaitForNight() then return end
                        break
                    end

                    SetNavigationStatus("Checking cage prompt")
                    local promptWaitUntil = os.clock() + 8
                    repeat
                        if token ~= navigationToken or Runtime.Stopped
                        or not selectedCage:IsDescendantOf(workspace) then
                            break
                        end

                        local petRoot = GetRidingPetRoot(root)
                        if not petRoot or not petRoot.Parent then
                            SetNavigationStatus("Riding pet root unavailable")
                            break
                        end

                        local promptOk, foundPrompt = pcall(function()
                            return GetCagePrompt(selectedCage)
                        end)
                        if promptOk and foundPrompt
                        and foundPrompt:IsA("ProximityPrompt")
                        and foundPrompt.Enabled then
                            stealPrompt = foundPrompt
                            break
                        end

                        if os.clock() >= promptWaitUntil then
                            break
                        end
                        task.wait(0.1)
                    until stealPrompt

                    if token ~= navigationToken or Runtime.Stopped then
                        RestoreFloating()
                        return
                    end
                    if not stealPrompt or not stealPrompt.Parent or not stealPrompt.Enabled then
                        RestoreFloating()
                        SetNavigationStatus("Cage prompt not available - skipping")
                        continue
                    end

                    local promptPositionOk, promptPosition = pcall(function()
                        return GetPromptWorldPosition(stealPrompt)
                    end)
                    if not promptPositionOk or not promptPosition then
                        RestoreFloating()
                        SetNavigationStatus("Invalid prompt position - skipping")
                        continue
                    end
                    cagePosition = promptPosition

                    local navigationRoot = GetRidingPetRoot(root)
                    if not navigationRoot or not navigationRoot.Parent then
                        RestoreFloating()
                        SetNavigationStatus("Riding pet root unavailable")
                        continue
                    end

                    cagePosition = GetPromptWorldPosition(stealPrompt) or cagePosition
                    local promptDistance = (cagePosition - navigationRoot.Position).Magnitude
                    if promptDistance > stealPrompt.MaxActivationDistance then
                        SetNavigationStatus("Closing in on cage")
                        if not MoveToPosition(root, humanoid, cagePosition, token, true) then
                            RestoreFloating()
                            SetNavigationStatus("Cage out of reach")
                            continue
                        end
                        navigationRoot = GetRidingPetRoot(root)
                        if not navigationRoot or not navigationRoot.Parent then
                            RestoreFloating()
                            SetNavigationStatus("Riding pet root unavailable")
                            continue
                        end
                        cagePosition = GetPromptWorldPosition(stealPrompt) or cagePosition
                        promptDistance = (cagePosition - navigationRoot.Position).Magnitude
                    end

                    if not stealPrompt.Parent or not stealPrompt.Enabled
                    or promptDistance > stealPrompt.MaxActivationDistance then
                        RestoreFloating()
                        SetNavigationStatus("Prompt out of range")
                        continue
                    end

                    SetFloating(root, false)
                    SetNavigationStatus(selectedCage.Name == "DroppedCage"
                        and "Holding grab prompt" or "Holding steal prompt")
                    local holdStarted = false
                    local holdCompleted = false
                    local holdOk = pcall(function()
                        local currentNavigationRoot = GetRidingPetRoot(root)
                        if not stealPrompt.Enabled
                        or not currentNavigationRoot
                        or not currentNavigationRoot.Parent then
                            return
                        end
                        local currentPromptPosition = GetPromptWorldPosition(stealPrompt)
                        if not currentPromptPosition
                        or (currentPromptPosition - currentNavigationRoot.Position).Magnitude
                            > stealPrompt.MaxActivationDistance then
                            return
                        end

                        stealPrompt:InputHoldBegin()
                        holdStarted = true

                        local holdUntil = os.clock() + math.max(0.15, stealPrompt.HoldDuration + 0.25)
                        while os.clock() < holdUntil do
                            if token ~= navigationToken or Runtime.Stopped
                            or bossCaughtDetected then
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

                    if bossCaughtDetected then
                        if not WaitForBossCaught() then return end
                        break
                    end

                    if nightDetected then
                        if not WaitForNight() then return end
                        break
                    end

                    if not holdOk or not holdCompleted then
                        RestoreFloating()
                        if token == navigationToken then
                            SetNavigationStatus("Steal prompt failed - skipping cage")
                        end
                        continue
                    end

                    SetNavigationStatus("Verifying steal")
                    local stealConfirmed = false
                    local verifyUntil = os.clock() + 1.25
                    while os.clock() < verifyUntil do
                        if token ~= navigationToken or Runtime.Stopped
                        or bossCaughtDetected or nightDetected then
                            break
                        end
                        if not selectedCage:IsDescendantOf(workspace)
                        or not stealPrompt.Parent
                        or not stealPrompt.Enabled then
                            stealConfirmed = true
                            break
                        end
                        task.wait(0.1)
                    end

                    if bossCaughtDetected then
                        if not WaitForBossCaught() then return end
                        break
                    end
                    if nightDetected then
                        if not WaitForNight() then return end
                        break
                    end
                    if token ~= navigationToken or Runtime.Stopped then
                        RestoreFloating()
                        return
                    end
                    if not stealConfirmed then
                        RestoreFloating()
                        SetNavigationStatus("Steal not confirmed - skipping cage")
                        continue
                    end

                    if token ~= navigationToken or Runtime.Stopped then
                        RestoreFloating()
                        return
                    end

                    SetNavigationStatus("Waiting before return")
                    task.wait(0.25)
                    if token ~= navigationToken or Runtime.Stopped then
                        RestoreFloating()
                        return
                    end

                    if bossCaughtDetected then
                        if not WaitForBossCaught() then return end
                        break
                    end

                    local reachedSafeZone = false
                    while token == navigationToken and not Runtime.Stopped
                    and not reachedSafeZone do
                        if MovementMode == "Glide" then
                            SetNavigationStatus("Gliding back to safe zone")
                        else
                            SetNavigationStatus("Walking back to safe zone")
                        end

                        safeZoneNavigationActive = true
                        reachedSafeZone = MoveToPosition(
                            root,
                            humanoid,
                            safeSign.Position,
                            token,
                            false,
                            MovementMode == "Glide"
                        )
                        safeZoneNavigationActive = false
                        if not reachedSafeZone then
                            RestoreFloating()
                            if bossCaughtDetected then
                                if not WaitForBossCaught() then return end
                                break
                            end
                            if nightDetected then
                                if not WaitForNight() then return end
                                break
                            end
                            if ShouldWalk(root) then
                                SetNavigationStatus("Retrying walk to safe zone")
                                task.wait(0.5)
                            else
                                if token == navigationToken then
                                    SetAutoStealEnabled(false)
                                    SetNavigationStatus("Return to safe zone failed")
                                end
                                return
                            end
                        end
                    end

                    if token ~= navigationToken or Runtime.Stopped then
                        RestoreFloating()
                        return
                    end
                    if not reachedSafeZone then
                        break
                    end

                    if token ~= navigationToken or Runtime.Stopped then
                        RestoreFloating()
                        return
                    end

                    SetFloating(root, false)
                    SetNavigationStatus("Safe zone reached")

                    SetNavigationStatus("Cooldown 5s")
                    local nextTargetAt = os.clock() + 5
                    while os.clock() < nextTargetAt do
                        if token ~= navigationToken or Runtime.Stopped then
                            return
                        end
                        if nightDetected or bossCaughtDetected then
                            break
                        end
                        task.wait(math.min(0.1, nextTargetAt - os.clock()))
                    end

                    if bossCaughtDetected then
                        if not WaitForBossCaught() then return end
                        break
                    end

                    if nightDetected then
                        if not WaitForNight() then return end
                        break
                    end

                    SetNavigationStatus("Cooldown complete - rescanning cages")
                    if ShouldWalk(root) then
                        break
                    end
                end
            end
        end

        local AutomationRow = Create("Frame", {
            Name = "AutomationCards",
            Parent = Page,
            Size = UDim2.new(1, -4, 0, 96),
            BackgroundTransparency = 1,
            BorderSizePixel = 0
        })

        local function CreateAutomationCard(title, position)
            local Card = Create("Frame", {
                Name = title:gsub("%s+", ""),
                Parent = AutomationRow,
                Position = position,
                Size = UDim2.new(0.5, -4, 1, 0),
                BackgroundColor3 = Theme.Card,
                BorderSizePixel = 0
            })
            AddCorner(Card, 8)
            AddStroke(Card, Theme.Border, 1)

            Create("TextLabel", {
                Parent = Card,
                Position = UDim2.fromOffset(11, 8),
                Size = UDim2.new(1, -48, 0, 18),
                BackgroundTransparency = 1,
                Text = title,
                TextColor3 = Theme.Text,
                Font = Enum.Font.GothamBold,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd
            })

            local StatusRow = Create("Frame", {
                Parent = Card,
                Position = UDim2.fromOffset(11, 35),
                Size = UDim2.new(1, -22, 0, 18),
                BackgroundTransparency = 1
            })
            local StatusDot = Create("Frame", {
                Parent = StatusRow,
                Position = UDim2.fromOffset(2, 6),
                Size = UDim2.fromOffset(7, 7),
                BackgroundColor3 = Theme.Gray,
                BorderSizePixel = 0
            })
            AddCorner(StatusDot, 8)

            Create("TextLabel", {
                Parent = StatusRow,
                Position = UDim2.fromOffset(18, 0),
                Size = UDim2.fromOffset(34, 18),
                BackgroundTransparency = 1,
                Text = "Status",
                TextColor3 = Theme.DarkGray,
                Font = Enum.Font.Gotham,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local StatusValue = Create("TextLabel", {
                Parent = StatusRow,
                Position = UDim2.fromOffset(54, 0),
                Size = UDim2.new(1, -54, 1, 0),
                BackgroundTransparency = 1,
                Text = "Disabled",
                TextColor3 = Theme.Gray,
                Font = Enum.Font.GothamMedium,
                TextSize = 9,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Right
            })

            Create("Frame", {
                Parent = Card,
                Position = UDim2.fromOffset(11, 61),
                Size = UDim2.new(1, -22, 0, 1),
                BackgroundColor3 = Theme.Border,
                BorderSizePixel = 0
            })

            local Toggle = CreateToggle(Card, "", false, function(enabled)
                if title == "Auto Treadmill" then
                    AutoTreadmillEnabled = enabled
                    if not enabled then
                        StatusValue.Text = "Disabled"
                        StatusValue.TextColor3 = Theme.Gray
                        StatusDot.BackgroundColor3 = Theme.Gray
                    elseif AutoStealEnabled then
                        StatusValue.Text = "Waiting for scan"
                        StatusValue.TextColor3 = Theme.Accent
                        StatusDot.BackgroundColor3 = Color3.fromRGB(75, 190, 145)
                    else
                        StatusValue.Text = "Enabled"
                        StatusValue.TextColor3 = Theme.Accent
                        StatusDot.BackgroundColor3 = Color3.fromRGB(75, 190, 145)
                    end
                    AutoTreadmillStatusValue = StatusValue
                    AutoTreadmillStatusDot = StatusDot
                    if enabled and not AutoStealEnabled and Runtime.StartTreadmillIdle then
                        Runtime.StartTreadmillIdle()
                    elseif not enabled and Runtime.StopTreadmillIdle then
                        Runtime.StopTreadmillIdle()
                    end
                else
                    StatusValue.Text = enabled and "Enabled" or "Disabled"
                    StatusValue.TextColor3 = enabled and Theme.Accent or Theme.Gray
                    StatusDot.BackgroundColor3 = enabled and Color3.fromRGB(75, 190, 145) or Theme.Gray
                end
            end)
            Toggle.Position = UDim2.new(1, -49, 0, 6)
            Toggle.Size = UDim2.fromOffset(38, 24)
            if title == "Auto Treadmill" then
                AutoTreadmillStatusValue = StatusValue
                AutoTreadmillStatusDot = StatusDot

                local tapBoostConnection

                local TapBoostToggle = CreateToggle(Card, "Auto Tap Boost", false, function(enabled)
                    if tapBoostConnection then
                        tapBoostConnection:Disconnect()
                        tapBoostConnection = nil
                    end

                    if not enabled then
                        return
                    end

                    local shared = ReplicatedStorage:FindFirstChild("Shared")
                    local remotes = shared and shared:FindFirstChild("Remotes")
                    local tapBoostRemote = remotes and remotes:FindFirstChild("TapBoost")

                    if not tapBoostRemote or not tapBoostRemote:IsA("RemoteEvent") then
                        return
                    end

                    tapBoostConnection = TrackConnection(tapBoostRemote.OnClientEvent:Connect(function(action, offerId)
                        if not enabled or action ~= "Offer" then
                            return
                        end

                        if typeof(offerId) == "number" then
                            tapBoostRemote:FireServer(offerId)
                        end
                    end))
                end)
                TapBoostToggle.Position = UDim2.fromOffset(11, 66)
                TapBoostToggle.Size = UDim2.new(1, -22, 0, 22)
            end
            return Card
        end

        CreateAutomationCard("Auto Treadmill", UDim2.new(0, 0, 0, 0))
        CreateAutomationCard("Auto Fight Boss", UDim2.new(0.5, 4, 0, 0))
    elseif name == "Features" then
        CreateCard(Page, "Feature Template", "Use this card as a starting point for new features.")
    elseif name == "Misc. feature" then
        local AntiAFKCard = CreateCard(Page, "Anti AFK", "Prevents the idle kick while this toggle is enabled.")
        local antiAFKConnection
        local AntiAFKToggle = CreateToggle(AntiAFKCard, "Enable Anti AFK", false, function(enabled)
            if enabled then
                if antiAFKConnection and antiAFKConnection.Connected then
                    antiAFKConnection:Disconnect()
                end
                antiAFKConnection = TrackConnection(LocalPlayer.Idled:Connect(function()
                    pcall(function()
                        VirtualUser:CaptureController()
                        VirtualUser:ClickButton2(Vector2.new(0, 0))
                    end)
                end))
            elseif antiAFKConnection then
                antiAFKConnection:Disconnect()
                antiAFKConnection = nil
            end
        end)
        AntiAFKToggle.Position = UDim2.fromOffset(11, 68)
        AntiAFKToggle.Size = UDim2.new(1, -22, 0, 28)
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
local IsAnimating = false
local ExpandedPosition = Main.Position
local MinimizedSize = UDim2.fromOffset(36, 36)
local MinimizedTopOffset = 11
local AnimationInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function SetMinimized(state)
    if IsAnimating or Minimized == state then return end
    IsAnimating = true

    if state then
        ExpandedPosition = Main.Position
        Minimized = true

        RestoreButton.Position = UDim2.new(1, -RestoreButton.Size.X.Offset, 0, MinimizedTopOffset)
        RestoreButton.Visible = true

        local minimizedPosition = UDim2.new(
            ExpandedPosition.X.Scale,
            ExpandedPosition.X.Offset + UIConfig.Width - MinimizedSize.X.Offset,
            ExpandedPosition.Y.Scale,
            ExpandedPosition.Y.Offset + MinimizedTopOffset
        )

        local mainTween = TweenService:Create(Main, AnimationInfo, {
            Size = MinimizedSize,
            Position = minimizedPosition
        })
        local restoreTween = TweenService:Create(RestoreButton, AnimationInfo, {
            Position = UDim2.fromOffset(0, 0)
        })
        local cornerTween = TweenService:Create(MainCorner, AnimationInfo, {
            CornerRadius = UDim.new(0, 18)
        })

        mainTween:Play()
        restoreTween:Play()
        cornerTween:Play()
        mainTween.Completed:Wait()

        Content.Visible = false
        Sidebar.Visible = false
        TopBar.Visible = false
        ResizeHandle.Visible = false
    else
        Minimized = false

        Content.Visible = true
        Sidebar.Visible = true
        TopBar.Visible = true
        RestoreButton.Visible = true
        ResizeHandle.Visible = true

        local mainTween = TweenService:Create(Main, AnimationInfo, {
            Size = UDim2.fromOffset(UIConfig.Width, UIConfig.Height),
            Position = ExpandedPosition
        })
        local restoreTween = TweenService:Create(RestoreButton, AnimationInfo, {
            Position = UDim2.new(1, -RestoreButton.Size.X.Offset, 0, MinimizedTopOffset)
        })
        local cornerTween = TweenService:Create(MainCorner, AnimationInfo, {
            CornerRadius = UDim.new(0, 12)
        })

        mainTween:Play()
        restoreTween:Play()
        cornerTween:Play()
        mainTween.Completed:Wait()

        RestoreButton.Visible = false
    end

    IsAnimating = false
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
local Resizing = false
local ResizeStart
local ResizeStartSize
local MinWindowWidth = 400
local MinWindowHeight = 280
local MaxWindowWidth = 720
local MaxWindowHeight = 600
ResizeHandle.InputBegan:Connect(function(input)
    if Minimized then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        Resizing = true
        ResizeStart = input.Position
        ResizeStartSize = Main.AbsoluteSize
    end
end)
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
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
    and input.UserInputType ~= Enum.UserInputType.Touch then return end

    if Resizing then
        local delta = input.Position - ResizeStart
        local width = math.clamp(ResizeStartSize.X + delta.X, MinWindowWidth, MaxWindowWidth)
        local height = math.clamp(ResizeStartSize.Y + delta.Y, MinWindowHeight, MaxWindowHeight)
        UIConfig.Width = width
        UIConfig.Height = height
        Main.Size = UDim2.fromOffset(width, height)
    end

    if Dragging then
        local Delta = input.Position - DragStart
        Main.Position = UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + Delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + Delta.Y
        )
    end
end))
TrackConnection(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        Resizing = false
        if Dragging and Minimized then
            ExpandedPosition = UDim2.new(
                Main.Position.X.Scale,
                Main.Position.X.Offset - (UIConfig.Width - MinimizedSize.X.Offset),
                Main.Position.Y.Scale,
                Main.Position.Y.Offset - MinimizedTopOffset
            )
        end
        Dragging = false
    end
end))
