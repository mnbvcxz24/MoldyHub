-- CL compact UI
-- Farm automation and Anti AFK controls.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local UI_NAME = "CLMoldyHubUI"
local deployver = "CL ver 2.44"
local displayVersion = "v" .. (string.match(deployver, "[%d%.]+") or "1.1")
local environment = (getgenv and getgenv()) or _G
local CONFIG_ROOT_PATH = "MoldyHub"
local CONFIG_FOLDER_PATH = CONFIG_ROOT_PATH .. "/config"
local CONFIG_FILE = CONFIG_FOLDER_PATH .. "/moldyhub_cl_config.json"
local CONFIG_READ_PATHS = {
    CONFIG_FILE,
    "MoldyHub_CL_AUTOSAVE_2026.json", -- Previous flat config location.
    "MoldyHub/CL_HARD_SAVE_2026.json",
    "MoldyHub_CL_Config.json"
}
local KEEP_MOLDYHUB_PATH = CONFIG_FOLDER_PATH .. "/keepmoldyhub.txt"
local savedConfig = {}
local configToggleControllers = {}
local configLoadStatus = "Not loaded yet"
local configLoadCompleted = false
-- A new execution invalidates the previous execution's autosave worker.
local runToken = {}
environment.CLMoldyHubRunToken = runToken

local function getFileApi(name)
    local fn = environment and environment[name]
    if type(fn) == "function" then return fn end
    fn = _G and _G[name]
    if type(fn) == "function" then return fn end
    return nil
end

local function readConfigFile(path)
    local readfile = getFileApi("readfile")
    if not readfile then return nil end
    -- Do not trust isfile(): some executors report false for valid files.
    local ok, value = pcall(readfile, path)
    if ok and type(value) == "string" then return value end
    return nil
end

local function loadSavedConfig()
    -- Wait briefly for executor file functions, but never overwrite a file if loading failed.
    local readfile
    for attempt = 1, 20 do
        readfile = getFileApi("readfile")
        if readfile then break end
        task.wait(0.25)
    end
    if not readfile then
        configLoadStatus = "Load blocked: readfile unavailable"
        warn("[MoldyHub] CL config load blocked: readfile unavailable")
        return
    end

    local raw, loadedPath
    for _, path in ipairs(CONFIG_READ_PATHS) do
        local candidate = readConfigFile(path)
        if type(candidate) == "string" and candidate ~= "" then
            raw, loadedPath = candidate, path
            break
        end
    end
    if not raw then
        configLoadStatus = "No saved config found; new config will be created"
        configLoadCompleted = true
        return
    end

    local ok, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok or type(decoded) ~= "table" then
        configLoadStatus = "Load blocked: invalid JSON in " .. tostring(loadedPath)
        warn("[MoldyHub] CL config load blocked: invalid JSON in " .. tostring(loadedPath))
        return
    end
    local settings = type(decoded.Settings) == "table" and decoded.Settings or decoded
    if type(settings) ~= "table" then
        configLoadStatus = "Load blocked: invalid settings in " .. tostring(loadedPath)
        return
    end

    savedConfig = settings
    configLoadStatus = "Loaded settings from " .. tostring(loadedPath)
    configLoadCompleted = true
end
local function ensureConfigFolder()
    if type(environment.makefolder) ~= "function" then
        error("Executor makefolder API unavailable")
    end
    local function ensureFolder(path)
        if type(environment.isfolder) == "function" then
            local ok, exists = pcall(environment.isfolder, path)
            if ok and exists then return end
        end
        pcall(environment.makefolder, path)
        if type(environment.isfolder) == "function" then
            local ok, exists = pcall(environment.isfolder, path)
            if ok and not exists then error("Could not create folder: " .. path) end
        end
    end
    ensureFolder(CONFIG_ROOT_PATH)
    ensureFolder(CONFIG_FOLDER_PATH)
end

local function getConfigSnapshot()
    local snapshot = {}
    for key, value in pairs(savedConfig) do
        snapshot[key] = value
    end
    -- Like BASAE, capture the live UI controller state at save time instead of
    -- trusting only the backing settings table.
    for key, getter in pairs(configToggleControllers) do
        if type(getter) == "function" then
            local ok, value = pcall(getter)
            if ok then snapshot[key] = value == true end
        end
    end
    return {
        Version = 1,
        SavedAt = os.time(),
        Settings = snapshot
    }
end

loadSavedConfig()
-- Auto-save is enabled by default for new CL installs. Users can still explicitly turn it off.
savedConfig.autoSaveConfig = true -- CL config persistence is always enabled.

-- Keep the reconnect flag in sync with the loaded configuration before teleport hooks run.
if type(savedConfig.keepMoldyHub) == "boolean" and type(environment.writefile) == "function" then
    pcall(function()
        ensureConfigFolder()
        environment.writefile(KEEP_MOLDYHUB_PATH, savedConfig.keepMoldyHub and "true" or "false")
    end)
end

-- Auto-save runs independently of the Settings tab, so Farm changes are persisted
-- even when the user never opens Configuration during that session.
local lastAutoSaveSignature
local autoSaveLoopRunning = false
local function saveConfigToDisk(forceSave, expectedRunToken)
    if expectedRunToken and environment.CLMoldyHubRunToken ~= expectedRunToken then
        return false, "Stale script execution"
    end
    if not configLoadCompleted then return false, "Config load has not completed" end
    -- CL settings are always persisted; the legacy toggle is retained for config compatibility.
    local writefile = getFileApi("writefile")
    local readfile = getFileApi("readfile")
    if not writefile or not readfile then
        return false, "Executor readfile/writefile API unavailable"
    end

    local snapshot = getConfigSnapshot()
    local signatureOk, signature = pcall(function()
        return HttpService:JSONEncode(snapshot.Settings)
    end)
    if not signatureOk then return false, "Config encode failed" end
    if not forceSave and signature == lastAutoSaveSignature then return true end

    local ok, err = pcall(function()
        local config = snapshot
        local jsonPayload = HttpService:JSONEncode(config)
        if expectedRunToken and environment.CLMoldyHubRunToken ~= expectedRunToken then
            error("Stale script execution")
        end
        ensureConfigFolder()
        writefile(CONFIG_FILE, jsonPayload)
        local savedPayload = readfile(CONFIG_FILE)
        if savedPayload ~= jsonPayload then error("Config write verification failed") end
        local verified = HttpService:JSONDecode(savedPayload)
        if type(verified) ~= "table"
            or type(verified.Settings) ~= "table"
            or verified.Version ~= 1
            or verified.SavedAt ~= config.SavedAt then
            error("Saved config verification failed")
        end
    end)

    if not ok then return false, tostring(err) end
    lastAutoSaveSignature = signature
    return true
end

local function startAutoSaveLoop()
    if autoSaveLoopRunning then return end
    autoSaveLoopRunning = true
    local thisRunToken = runToken
    task.spawn(function()
        while environment.CLMoldyHubRunToken == thisRunToken do
            task.wait(1)
            -- A rerun replaces the shared token; stop before writing stale UI state.
            if environment.CLMoldyHubRunToken ~= thisRunToken then break end
            local ok, err = saveConfigToDisk(false, thisRunToken)
            if not ok and err ~= "Stale script execution" and configLoadCompleted then
                warn("[MoldyHub] Auto-save failed: " .. tostring(err))
            end
        end
        autoSaveLoopRunning = false
    end)
end
local function persistConfigIfEnabled()
    if environment.CLMoldyHubRunToken ~= runToken then return end
    local ok, err = saveConfigToDisk(true, runToken)
    if not ok then warn("[MoldyHub] Immediate config save failed: " .. tostring(err)) end
end

-- Install reconnect execution immediately; it must not depend on opening Settings.
local listenerEnv = environment
do
    if listenerEnv.MoldyHubCLKeepTeleportListenerConnection then
        pcall(function() listenerEnv.MoldyHubCLKeepTeleportListenerConnection:Disconnect() end)
        listenerEnv.MoldyHubCLKeepTeleportListenerConnection = nil
    end
    local teleportQueue = environment.queue_on_teleport or environment.queueonteleport
        or queue_on_teleport or queueonteleport
    if type(teleportQueue) == "function" then
        local teleportQueued = false
        listenerEnv.MoldyHubCLKeepTeleportListenerConnection = LocalPlayer.OnTeleport:Connect(function()
            if environment.CLMoldyHubRunToken ~= runToken then return end
            if teleportQueued then return end
            local raw = readConfigFile(KEEP_MOLDYHUB_PATH)
            local shouldKeep = raw ~= nil and tostring(raw):lower():match("^%s*true%s*$") ~= nil
            local shouldResumeSpire = savedConfig.autoSpire == true
            if not shouldKeep and not shouldResumeSpire then return end
            -- Persist current settings before the old game session exits.
            local saveOk, saveErr = saveConfigToDisk(true)
            if not saveOk then warn("[MoldyHub] Pre-teleport config save failed: " .. tostring(saveErr)) end
            teleportQueued = true
            local source
            if shouldResumeSpire then
                source = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/mnbvcxz24/MoldyHub/main/Games/CL.lua"))()'
            else
                source = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/mnbvcxz24/MoldyHub/main/MoldyHubLoader"))()'
            end
            local ok, err = pcall(function() teleportQueue(source) end)
            if not ok then
                teleportQueued = false
                warn("[MoldyHub] Teleport queue failed: " .. tostring(err))
            end
        end)
    end
end

startAutoSaveLoop()

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
local TabNames = {"Farm", "Webhook", "Dungeons", "Settings"}

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
        local contentBottom = left.AbsolutePosition.Y - page.AbsolutePosition.Y + left.AbsoluteSize.Y
        -- Keep enough bottom scroll margin to comfortably reach the final item on every tab.
        local canvasHeight = math.max(contentBottom + 50, page.AbsoluteSize.Y + 50)
        page.CanvasSize = UDim2.new(0, 0, 0, canvasHeight)
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
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0
    })
    Create("UIPadding", {
        Parent = card,
        PaddingBottom = UDim.new(0, 8)
    })
    Corner(card, 8)
    Stroke(card, Theme.Border, 1)
    local titleLabel = Create("TextLabel", {
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
    return card, titleLabel
end

local function CreateCardHeaderToggle(card, titleLabel, initialValue, callback, configKey)
    titleLabel.Size = UDim2.new(1, -62, 0, 18)
    local button = Create("TextButton", {
        Parent = card,
        Position = UDim2.new(1, -46, 0, 7),
        Size = UDim2.fromOffset(34, 18),
        BackgroundTransparency = 1,
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false
    })
    local track = Create("Frame", {
        Parent = button,
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.fromOffset(30, 14),
        BackgroundColor3 = Color3.fromRGB(49, 67, 82),
        BorderSizePixel = 0
    })
    Corner(track, 20)
    local knob = Create("Frame", {
        Parent = track,
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.fromOffset(10, 10),
        BackgroundColor3 = Color3.fromRGB(245, 250, 255),
        BorderSizePixel = 0
    })
    Corner(knob, 20)
    local enabled = initialValue == true
    if type(configKey) == "string" then
        configToggleControllers[configKey] = function() return enabled end
    end
    local function update()
        Tween(track, {BackgroundColor3 = enabled and Theme.Accent or Color3.fromRGB(49, 67, 82)})
        Tween(knob, {Position = enabled and UDim2.new(1, -12, 0, 2) or UDim2.fromOffset(2, 2)})
        if callback then callback(enabled) end
        persistConfigIfEnabled()
    end
    button.MouseButton1Click:Connect(function()
        enabled = not enabled
        update()
    end)
    update()
    return function(value)
        enabled = value == true
        update()
    end
end

local function CreateToggle(parent, label, y, callback, configKey)
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
    if type(configKey) == "string" then
        configToggleControllers[configKey] = function() return enabled end
    end
    local function update()
        Tween(switch, {BackgroundColor3 = enabled and Theme.Accent or Color3.fromRGB(49, 67, 82)})
        Tween(knob, {Position = enabled and UDim2.new(1, -12, 0, 2) or UDim2.fromOffset(2, 2)})
        if callback then callback(enabled) end
        persistConfigIfEnabled()
    end
    local function setEnabled(value)
        enabled = value == true
        update()
    end
    row.MouseButton1Click:Connect(function()
        setEnabled(not enabled)
    end)
    return row, setEnabled
end

local function CreateCheckbox(parent, label, y, callback, configKey)
    local row = Create("TextButton", {
        Parent = parent,
        Position = UDim2.fromOffset(12, y),
        Size = UDim2.new(1, -24, 0, 18),
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
    if type(configKey) == "string" then
        configToggleControllers[configKey] = function() return checked end
    end
    local function setChecked(value)
        checked = value == true
        box.BackgroundColor3 = checked and Theme.Accent or Theme.SurfaceInput
        mark.Visible = checked
        if callback then callback(checked) end
        persistConfigIfEnabled()
    end
    row.MouseButton1Click:Connect(function()
        setChecked(not checked)
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

local setLabyrinthAutoAttack, setLabyrinthAutoOrbit

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
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if not playerGui then return nil end

            -- MainHUD is used in the normal area; WK_HUD is used in dungeons.
            local abilityRail = FindPath(playerGui, {"MainHUD", "Right Column", "Ability Rail", "MainFrame", "Abilities", "Abilities"})
            if abilityRail then return abilityRail end

            return FindPath(playerGui, {"WK_HUD", "Right Column", "Ability Rail", "MainFrame", "Abilities", "Abilities"})
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
        local orbitDistance = tonumber(savedConfig.orbitDistance) or 50
        local orbitHeight = tonumber(savedConfig.orbitHeight) or 50
        local orbitSpeed = tonumber(savedConfig.orbitSpeed) or 90
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
                while thisLoop == targetClickLoopId and autoFarmEnabled and useM1Enabled do
                    -- Send the mouse click only while the main UI is minimized.
                    local target = orbitSelectedTarget or (orbitEnabled and orbitTarget) or cameraAimTarget
                    local camera = workspace.CurrentCamera
                    local character = LocalPlayer.Character
                    local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
                    local enemies = workspace:FindFirstChild("Enemies")
                    if useM1Enabled and not Main.Visible and camera and isValidEnemyRoot(target, enemies, playerRoot) then
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
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1
        })
        Create("UIListLayout", {
            Parent = cardsRow,
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        local autoAttackColumn = Create("Frame", {
            Parent = cardsRow,
            Size = UDim2.new(0.5, -5, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1
        })
        Create("UIListLayout", {
            Parent = autoAttackColumn,
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        local orbitColumn = Create("Frame", {
            Parent = cardsRow,
            Size = UDim2.new(0.5, -5, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1
        })
        Create("UIListLayout", {
            Parent = orbitColumn,
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder
        })

        local card, autoAttackTitle = CreateCard(autoAttackColumn, "Auto attack", 280)
        card.Size = UDim2.new(1, 0, 0, 0)
        local setAutoFarm = CreateCardHeaderToggle(card, autoAttackTitle, savedConfig.autoFarm == true, function(enabled)
            autoFarmEnabled = enabled
            savedConfig.autoFarm = enabled
            if not enabled then clearEnemyAim() end
            startTargetClickLoop(enabled)
            updateM1Loop()
            for _, slot in ipairs({"C", "X", "Z", "V"}) do
                startSkillLoop(slot, enabled and skillEnabled[slot] == true)
            end
        end, "autoFarm")
        setLabyrinthAutoAttack = setAutoFarm
        local _, setUseM1 = CreateCheckbox(card, "Use M1", 34, function(checked)
            useM1Enabled = checked
            savedConfig.useM1 = checked
            updateM1Loop()
            startTargetClickLoop(autoFarmEnabled)
        end, "useM1")
        local _, setUseC = CreateCheckbox(card, "Use C", 52, function(checked)
            skillEnabled.C = checked
            savedConfig.skillC = checked
            startSkillLoop("C", checked and autoFarmEnabled)
        end, "skillC")
        local _, setUseX = CreateCheckbox(card, "Use X", 70, function(checked)
            skillEnabled.X = checked
            savedConfig.skillX = checked
            startSkillLoop("X", checked and autoFarmEnabled)
        end, "skillX")
        local _, setUseZ = CreateCheckbox(card, "Use Z", 88, function(checked)
            skillEnabled.Z = checked
            savedConfig.skillZ = checked
            startSkillLoop("Z", checked and autoFarmEnabled)
        end, "skillZ")
        local _, setUseV = CreateCheckbox(card, "Use V", 106, function(checked)
            skillEnabled.V = checked
            savedConfig.skillV = checked
            startSkillLoop("V", checked and autoFarmEnabled)
        end, "skillV")

        setUseM1(savedConfig.useM1 == true)
        setUseC(savedConfig.skillC == true)
        setUseX(savedConfig.skillX == true)
        setUseZ(savedConfig.skillZ == true)
        setUseV(savedConfig.skillV == true)
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
                orbitSelectedTarget = nil
                clearEnemyAim()
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

        local orbitCard, orbitTitle = CreateCard(orbitColumn, "Orbit enemy", 280)
        orbitCard.Size = UDim2.new(1, 0, 0, 0)
        local setOrbitHeaderToggle = CreateCardHeaderToggle(orbitCard, orbitTitle, savedConfig.orbitEnabled == true, function(enabled)
            savedConfig.orbitEnabled = enabled
            setOrbitEnabled(enabled)
        end, "orbitEnabled")
        -- Drive the actual header toggle as well as the orbit logic so its ON state is visible.
        setLabyrinthAutoOrbit = setOrbitHeaderToggle

        Create("TextLabel", {
            Parent = orbitCard,
            Position = UDim2.fromOffset(12, 34),
            Size = UDim2.new(1, -24, 0, 14),
            BackgroundTransparency = 1,
            Text = "Enemy Nearby",
            TextColor3 = Theme.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        local enemyList = Create("ScrollingFrame", {
            Parent = orbitCard,
            Position = UDim2.fromOffset(12, 51),
            Size = UDim2.new(1, -24, 0, 78),
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
            Padding = UDim.new(0, 1),
            SortOrder = Enum.SortOrder.Name
        })
        enemyListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            enemyList.CanvasSize = UDim2.new(0, 0, 0, enemyListLayout.AbsoluteContentSize.Y + 2)
        end)

        local enemyListStatus = Create("TextLabel", {
            Parent = orbitCard,
            Position = UDim2.fromOffset(12, 132),
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
                        Size = UDim2.new(1, -6, 0, 18),
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

        createOrbitInput("Distance (studs)", 157, orbitDistance, 3, 100, function(value)
            orbitDistance = value
            savedConfig.orbitDistance = value
        end)
        createOrbitInput("Flying height (studs)", 181, orbitHeight, 0, 100, function(value)
            orbitHeight = value
            savedConfig.orbitHeight = value
        end)
        createOrbitInput("Speed (deg/sec)", 205, orbitSpeed, 10, 360, function(value)
            orbitSpeed = value
            savedConfig.orbitSpeed = value
        end)

        local bossCard, bossTitle = CreateCard(autoAttackColumn, "Auto spawn boss", 54)
        -- Filter lists overlay the card, so its height only needs to fit the controls.
        bossCard.AutomaticSize = Enum.AutomaticSize.None
        bossCard.Size = UDim2.new(1, 0, 0, 186)
        local bossSpawnLoopId = 0
        local bossSpawnEnabled = false
        -- Forward-declare values used by the spawn functions below.
        local bossKeyLabel
        local bossFilter
        local bossDifficultyFilter
        local bossIdByName = {
            ["Shadow Ronin"] = "YamiSukehiro",
            ["Ember Lord"] = "FuegoleonVermillion"
        }
        local bossKeyCost = {
            Normal = 1,
            Medium = 2,
            Hard = 3,
            Extreme = 5
        }
        local bossSpawnCooldowns = {}

        local function getBossKeyCount()
            local amount = tostring(bossKeyLabel.Text or ""):match("(%d+)")
            return tonumber(amount) or 0
        end

        local function isBossNearby()
            local enemies = workspace:FindFirstChild("Enemies")
            local character = LocalPlayer.Character
            local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
            if not enemies or not playerRoot then
                return false
            end

            for _, enemy in ipairs(enemies:GetChildren()) do
                local enemyName = string.lower(tostring(enemy.Name or ""))
                if string.find(enemyName, "boss", 1, true) then
                    local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
                    if enemyRoot and (enemyRoot.Position - playerRoot.Position).Magnitude <= 200 then
                        local humanoid = enemy:FindFirstChildOfClass("Humanoid")
                        if not humanoid or humanoid.Health > 0 then
                            return true
                        end
                    end
                end
            end
            return false
        end

        local function spawnSelectedBosses()
            local summonRemote = game:GetService("ReplicatedStorage")
                :FindFirstChild("Remotes")
            summonRemote = summonRemote and summonRemote:FindFirstChild("BossSummon")
            if not summonRemote then
                return
            end

            local selectedBosses = {}
            for displayName, bossId in pairs(bossIdByName) do
                if bossFilter[displayName] == true then
                    table.insert(selectedBosses, {name = displayName, id = bossId})
                end
            end
            table.sort(selectedBosses, function(a, b) return a.name < b.name end)

            local selectedDifficulties = {}
            for difficultyName, keyCost in pairs(bossKeyCost) do
                if bossDifficultyFilter[difficultyName] == true then
                    table.insert(selectedDifficulties, {name = difficultyName, cost = keyCost})
                end
            end
            table.sort(selectedDifficulties, function(a, b)
                return a.cost < b.cost
            end)

            for _, boss in ipairs(selectedBosses) do
                for _, difficulty in ipairs(selectedDifficulties) do
                    if not bossSpawnEnabled then
                        return
                    end

                    local cooldownKey = boss.id .. ":" .. difficulty.name
                    local lastSpawn = bossSpawnCooldowns[cooldownKey] or 0
                    if os.clock() - lastSpawn >= 8
                        and getBossKeyCount() >= difficulty.cost
                        and not isBossNearby() then
                        -- Give the spawn request a 2-second delay, then recheck
                        -- the toggle, key balance, and nearby boss before firing.
                        task.wait(2)
                        if not bossSpawnEnabled then
                            return
                        end
                        if getBossKeyCount() < difficulty.cost or isBossNearby() then
                            continue
                        end

                        local ok = pcall(function()
                            summonRemote:FireServer({
                                Difficulty = difficulty.name == "Normal" and "Easy" or difficulty.name,
                                BossId = boss.id,
                                Phase = "Spawn"
                            })
                        end)
                        if ok then
                            bossSpawnCooldowns[cooldownKey] = os.clock()
                            task.wait(0.35)
                        end
                    end
                end
            end
        end

        local setBossSpawnToggle = CreateCardHeaderToggle(bossCard, bossTitle, savedConfig.autoSpawnBoss == true, function(enabled)
            bossSpawnEnabled = enabled
            savedConfig.autoSpawnBoss = enabled
            bossSpawnLoopId = bossSpawnLoopId + 1
            local thisLoop = bossSpawnLoopId
            if enabled then
                task.spawn(function()
                    while bossSpawnEnabled and thisLoop == bossSpawnLoopId and bossCard.Parent do
                        spawnSelectedBosses()
                        task.wait(2)
                    end
                end)
            end
        end)
        RegisterCleanup(function()
            bossSpawnEnabled = false
            bossSpawnLoopId = bossSpawnLoopId + 1
        end)

        bossKeyLabel = Create("TextLabel", {
            Parent = bossCard,
            Position = UDim2.fromOffset(12, 34),
            Size = UDim2.new(0.5, -16, 0, 16),
            BackgroundTransparency = 1,
            Text = "Boss Key: 0",
            TextColor3 = Theme.DarkGray,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        local bossCoinLabel = Create("TextLabel", {
            Parent = bossCard,
            Position = UDim2.new(0.5, 4, 0, 34),
            Size = UDim2.new(0.5, -16, 0, 16),
            BackgroundTransparency = 1,
            Text = "Coins: 0",
            TextColor3 = Theme.DarkGray,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Right
        })

        local function refreshBossCurrencyCounts()
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            local summonUI = playerGui and playerGui:FindFirstChild("BossSummonUI")
            local container = summonUI and summonUI:FindFirstChild("Container")
            local basePanel = container and container:FindFirstChild("BasePanel")
            local balanceRow = basePanel and basePanel:FindFirstChild("BalanceRow")
            local currencies = balanceRow and balanceRow:FindFirstChild("Currencies")
            local keyValueLabel = currencies and currencies:FindFirstChild("KeyValueLabel")
            local coinValueLabel = currencies and currencies:FindFirstChild("CoinValueLabel")
            local keyAmount = keyValueLabel and keyValueLabel.Text or "0"
            local coinAmount = coinValueLabel and coinValueLabel.Text or "0"
            bossKeyLabel.Text = "Boss Key: " .. tostring(keyAmount)
            bossCoinLabel.Text = "Coins: " .. tostring(coinAmount)
        end

        Create("TextLabel", {
            Parent = bossCard,
            Position = UDim2.fromOffset(12, 56),
            Size = UDim2.new(1, -24, 0, 16),
            BackgroundTransparency = 1,
            Text = "Boss filters",
            TextColor3 = Theme.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        Create("TextLabel", {
            Parent = bossCard,
            Position = UDim2.fromOffset(12, 81),
            Size = UDim2.new(1, -24, 0, 16),
            BackgroundTransparency = 1,
            Text = "Boss filter",
            TextColor3 = Theme.DarkGray,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        bossFilter = {}
        if type(savedConfig.bossFilter) == "table" then
            for name, selected in pairs(savedConfig.bossFilter) do
                bossFilter[name] = selected == true
            end
        end

        local bossFilterDropdown = Create("TextButton", {
            Parent = bossCard,
            Position = UDim2.fromOffset(12, 99),
            Size = UDim2.new(1, -24, 0, 23),
            BackgroundColor3 = Theme.SurfaceInput,
            Text = "",
            BorderSizePixel = 0,
            AutoButtonColor = false,
            ZIndex = 10
        })
        Corner(bossFilterDropdown, 5)
        Stroke(bossFilterDropdown, Theme.Border, 1)

        local bossFilterDropdownText = Create("TextLabel", {
            Parent = bossFilterDropdown,
            Position = UDim2.fromOffset(8, 0),
            Size = UDim2.new(1, -26, 1, 0),
            BackgroundTransparency = 1,
            Text = "Select bosses",
            TextColor3 = Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 8,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 11
        })
        Create("TextLabel", {
            Parent = bossFilterDropdown,
            Position = UDim2.new(1, -19, 0, 0),
            Size = UDim2.fromOffset(14, 23),
            BackgroundTransparency = 1,
            Text = "v",
            TextColor3 = Theme.Gray,
            Font = Enum.Font.GothamBold,
            TextSize = 9,
            ZIndex = 11
        })

        local bossFilterList = Create("ScrollingFrame", {
            Parent = bossCard,
            Position = UDim2.fromOffset(12, 126),
            Size = UDim2.new(1, -24, 0, 140),
            BackgroundColor3 = Theme.SurfaceInput,
            BorderSizePixel = 0,
            Visible = false,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Gray,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ZIndex = 30
        })
        Corner(bossFilterList, 5)
        Stroke(bossFilterList, Theme.Border, 1)
        local bossFilterLayout = Create("UIListLayout", {
            Parent = bossFilterList,
            Padding = UDim.new(0, 1),
            SortOrder = Enum.SortOrder.Name
        })
        Create("UIPadding", {
            Parent = bossFilterList,
            PaddingTop = UDim.new(0, 2),
            PaddingBottom = UDim.new(0, 2),
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 4)
        })

        local function updateBossFilterDropdownText()
            local selectedNames = {}
            for name, selected in pairs(bossFilter) do
                if selected == true then
                    table.insert(selectedNames, name)
                end
            end
            table.sort(selectedNames)
            if #selectedNames == 0 then
                bossFilterDropdownText.Text = "Select bosses"
            elseif #selectedNames == 1 then
                bossFilterDropdownText.Text = selectedNames[1]
            else
                bossFilterDropdownText.Text = tostring(#selectedNames) .. " selected"
            end
        end

        local function getBossBasePanel()
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            local summonUI = playerGui and playerGui:FindFirstChild("BossSummonUI")
            local container = summonUI and summonUI:FindFirstChild("Container")
            return container and container:FindFirstChild("BasePanel")
        end

        local function refreshBossFilter()
            local basePanel = getBossBasePanel()
            if not basePanel then
                return
            end

            for _, child in ipairs(bossFilterList:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end

            local bossRows = {}
            for _, child in ipairs(basePanel:GetChildren()) do
                local rowNumber = child.Name:match("^BossRow(%d+)$")
                if rowNumber then
                    local nameLabel = child:FindFirstChild("BossNameLabel")
                    if nameLabel and nameLabel:IsA("TextLabel") then
                        local bossName = tostring(nameLabel.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
                        if bossName ~= "" then
                            table.insert(bossRows, {
                                number = tonumber(rowNumber) or 0,
                                name = bossName
                            })
                        end
                    end
                end
            end
            table.sort(bossRows, function(a, b)
                return a.number < b.number
            end)

            local seenNames = {}
            for _, boss in ipairs(bossRows) do
                local bossName = boss.name
                if not seenNames[bossName] then
                    seenNames[bossName] = true
                    if bossFilter[bossName] == nil then
                        bossFilter[bossName] = type(savedConfig.bossFilter) == "table"
                            and savedConfig.bossFilter[bossName] == true or false
                    end

                    local selected = bossFilter[bossName] == true
                    local option = Create("TextButton", {
                        Name = bossName,
                        Parent = bossFilterList,
                        Size = UDim2.new(1, -2, 0, 18),
                        BackgroundTransparency = 1,
                        Text = "",
                        BorderSizePixel = 0,
                        AutoButtonColor = false,
                        ZIndex = 31
                    })
                    local check = Create("Frame", {
                        Parent = option,
                        Position = UDim2.fromOffset(2, 3),
                        Size = UDim2.fromOffset(12, 12),
                        BackgroundColor3 = selected and Theme.Accent or Theme.Card,
                        BorderSizePixel = 0,
                        ZIndex = 32
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
                        ZIndex = 33
                    })
                    Create("TextLabel", {
                        Parent = option,
                        Position = UDim2.fromOffset(21, 0),
                        Size = UDim2.new(1, -24, 1, 0),
                        BackgroundTransparency = 1,
                        Text = bossName,
                        TextColor3 = Theme.Text,
                        Font = Enum.Font.Gotham,
                        TextSize = 8,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        ZIndex = 33
                    })
                    option.MouseButton1Click:Connect(function()
                        bossFilter[bossName] = not bossFilter[bossName]
                        savedConfig.bossFilter = savedConfig.bossFilter or {}
                        savedConfig.bossFilter[bossName] = bossFilter[bossName]
                        local isSelected = bossFilter[bossName] == true
                        check.BackgroundColor3 = isSelected and Theme.Accent or Theme.Card
                        mark.Visible = isSelected
                        updateBossFilterDropdownText()
                    end)
                end
            end

            bossFilterList.CanvasSize = UDim2.new(0, 0, 0, bossFilterLayout.AbsoluteContentSize.Y + 4)
            updateBossFilterDropdownText()
        end

        local bossFilterOpen = false
        local bossDifficultyOpen = false

        Create("TextLabel", {
            Parent = bossCard,
            Position = UDim2.fromOffset(12, 128),
            Size = UDim2.new(1, -24, 0, 16),
            BackgroundTransparency = 1,
            Text = "Boss difficulty",
            TextColor3 = Theme.DarkGray,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        bossDifficultyFilter = {}
        if type(savedConfig.bossDifficultyFilter) == "table" then
            for name, selected in pairs(savedConfig.bossDifficultyFilter) do
                bossDifficultyFilter[name] = selected == true
            end
        end

        local bossDifficultyDropdown = Create("TextButton", {
            Parent = bossCard,
            Position = UDim2.fromOffset(12, 146),
            Size = UDim2.new(1, -24, 0, 23),
            BackgroundColor3 = Theme.SurfaceInput,
            Text = "",
            BorderSizePixel = 0,
            AutoButtonColor = false,
            ZIndex = 10
        })
        Corner(bossDifficultyDropdown, 5)
        Stroke(bossDifficultyDropdown, Theme.Border, 1)

        local bossDifficultyDropdownText = Create("TextLabel", {
            Parent = bossDifficultyDropdown,
            Position = UDim2.fromOffset(8, 0),
            Size = UDim2.new(1, -26, 1, 0),
            BackgroundTransparency = 1,
            Text = "Select difficulty",
            TextColor3 = Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 8,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 11
        })
        Create("TextLabel", {
            Parent = bossDifficultyDropdown,
            Position = UDim2.new(1, -19, 0, 0),
            Size = UDim2.fromOffset(14, 23),
            BackgroundTransparency = 1,
            Text = "v",
            TextColor3 = Theme.Gray,
            Font = Enum.Font.GothamBold,
            TextSize = 9,
            ZIndex = 11
        })

        local bossDifficultyList = Create("ScrollingFrame", {
            Parent = bossCard,
            Position = UDim2.fromOffset(12, 173),
            Size = UDim2.new(1, -24, 0, 140),
            BackgroundColor3 = Theme.SurfaceInput,
            BorderSizePixel = 0,
            Visible = false,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Gray,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ZIndex = 30
        })
        Corner(bossDifficultyList, 5)
        Stroke(bossDifficultyList, Theme.Border, 1)
        local bossDifficultyLayout = Create("UIListLayout", {
            Parent = bossDifficultyList,
            Padding = UDim.new(0, 1),
            SortOrder = Enum.SortOrder.Name
        })
        Create("UIPadding", {
            Parent = bossDifficultyList,
            PaddingTop = UDim.new(0, 2),
            PaddingBottom = UDim.new(0, 2),
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 4)
        })

        local function updateBossDifficultyDropdownText()
            local selectedNames = {}
            for name, selected in pairs(bossDifficultyFilter) do
                if selected == true then
                    table.insert(selectedNames, name)
                end
            end
            table.sort(selectedNames)
            if #selectedNames == 0 then
                bossDifficultyDropdownText.Text = "Select difficulty"
            elseif #selectedNames == 1 then
                bossDifficultyDropdownText.Text = selectedNames[1]
            else
                bossDifficultyDropdownText.Text = tostring(#selectedNames) .. " selected"
            end
        end

        local function refreshBossDifficultyFilter()
            local basePanel = getBossBasePanel()
            local difficultyRow = basePanel and basePanel:FindFirstChild("DifficultyRow")
            local difficultyGroup = difficultyRow and difficultyRow:FindFirstChild("DifficultyGroup")
            if not difficultyGroup then
                return
            end

            for _, child in ipairs(bossDifficultyList:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end

            local difficultyOptions = {}
            for _, child in ipairs(difficultyGroup:GetChildren()) do
                if child.Name:match("Option$") then
                    local optionName = child.Name:gsub("Option$", "")
                    local optionText = ""
                    if child:IsA("TextButton") or child:IsA("TextLabel") then
                        optionText = tostring(child.Text or "")
                    end
                    optionText = optionText:gsub("^%s+", ""):gsub("%s+$", "")
                    if optionText == "" then
                        optionText = optionName
                    end
                    if optionName ~= "" then
                        table.insert(difficultyOptions, {
                            key = optionName,
                            label = optionText
                        })
                    end
                end
            end
            table.sort(difficultyOptions, function(a, b)
                return a.key < b.key
            end)

            for _, difficulty in ipairs(difficultyOptions) do
                local difficultyName = difficulty.key
                if bossDifficultyFilter[difficultyName] == nil then
                    bossDifficultyFilter[difficultyName] = type(savedConfig.bossDifficultyFilter) == "table"
                        and savedConfig.bossDifficultyFilter[difficultyName] == true or false
                end

                local selected = bossDifficultyFilter[difficultyName] == true
                local option = Create("TextButton", {
                    Name = difficultyName,
                    Parent = bossDifficultyList,
                    Size = UDim2.new(1, -2, 0, 18),
                    BackgroundTransparency = 1,
                    Text = "",
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    ZIndex = 31
                })
                local check = Create("Frame", {
                    Parent = option,
                    Position = UDim2.fromOffset(2, 3),
                    Size = UDim2.fromOffset(12, 12),
                    BackgroundColor3 = selected and Theme.Accent or Theme.Card,
                    BorderSizePixel = 0,
                    ZIndex = 32
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
                    ZIndex = 33
                })
                Create("TextLabel", {
                    Parent = option,
                    Position = UDim2.fromOffset(21, 0),
                    Size = UDim2.new(1, -24, 1, 0),
                    BackgroundTransparency = 1,
                    Text = difficulty.label,
                    TextColor3 = Theme.Text,
                    Font = Enum.Font.Gotham,
                    TextSize = 8,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 33
                })
                option.MouseButton1Click:Connect(function()
                    bossDifficultyFilter[difficultyName] = not bossDifficultyFilter[difficultyName]
                    savedConfig.bossDifficultyFilter = savedConfig.bossDifficultyFilter or {}
                    savedConfig.bossDifficultyFilter[difficultyName] = bossDifficultyFilter[difficultyName]
                    local isSelected = bossDifficultyFilter[difficultyName] == true
                    check.BackgroundColor3 = isSelected and Theme.Accent or Theme.Card
                    mark.Visible = isSelected
                    updateBossDifficultyDropdownText()
                end)
            end

            bossDifficultyList.CanvasSize = UDim2.new(0, 0, 0, bossDifficultyLayout.AbsoluteContentSize.Y + 4)
            updateBossDifficultyDropdownText()
        end

        local function updateBossFilterPanel()
            -- Match BASAE: only the active list is visible, directly below
            -- its button. The list overlays the card instead of resizing it.
            bossFilterList.Visible = bossFilterOpen
            bossDifficultyList.Visible = bossDifficultyOpen

            if bossFilterOpen then
                bossFilterList.Position = UDim2.fromOffset(
                    12,
                    bossFilterDropdown.Position.Y.Offset + bossFilterDropdown.AbsoluteSize.Y + 4
                )
                bossFilterList.Size = UDim2.new(1, -24, 0, 140)
            end

            if bossDifficultyOpen then
                bossDifficultyList.Position = UDim2.fromOffset(
                    12,
                    bossDifficultyDropdown.Position.Y.Offset + bossDifficultyDropdown.AbsoluteSize.Y + 4
                )
                bossDifficultyList.Size = UDim2.new(1, -24, 0, 140)
            end
        end

        bossFilterDropdown.MouseButton1Click:Connect(function()
            bossFilterOpen = not bossFilterOpen
            bossDifficultyOpen = false
            if bossFilterOpen then
                refreshBossFilter()
            end
            updateBossFilterPanel()
        end)

        bossDifficultyDropdown.MouseButton1Click:Connect(function()
            bossDifficultyOpen = not bossDifficultyOpen
            bossFilterOpen = false
            if bossDifficultyOpen then
                refreshBossDifficultyFilter()
            end
            updateBossFilterPanel()
        end)

        refreshBossFilter()
        refreshBossDifficultyFilter()
        updateBossFilterPanel()

        task.defer(function()
            if card.Parent then setAutoFarm(savedConfig.autoFarm == true) end
            if orbitCard.Parent then setOrbitHeaderToggle(savedConfig.orbitEnabled == true) end
        end)

        task.spawn(function()
            while bossCard.Parent do
                refreshBossCurrencyCounts()
                task.wait(1)
            end
        end)

    elseif index == 4 then
        local settingsCard = CreateCard(left, "Configuration", 76)
        local saveStatus = Create("TextLabel", {
            Parent = settingsCard,
            Position = UDim2.fromOffset(12, 34),
            Size = UDim2.new(1, -24, 0, 15),
            BackgroundTransparency = 1,
            Text = configLoadStatus,
            TextColor3 = configLoadCompleted and Color3.fromRGB(95, 220, 140) or Theme.Gray,
            Font = Enum.Font.Gotham,
            TextSize = 8,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        local function setConfigStatus(message, success)
            saveStatus.Text = tostring(message)
            saveStatus.TextColor3 = success and Color3.fromRGB(95, 220, 140) or Color3.fromRGB(240, 110, 110)
        end

        local autoSaveConfigEnabled = true
        local function saveAutoConfig(forceSave)
            local ok, err = saveConfigToDisk(forceSave)
            if ok then
                setConfigStatus(autoSaveConfigEnabled and "Auto-saved current settings" or "Auto Save disabled", true)
                return true
            end
            setConfigStatus("Auto Save failed - " .. tostring(err):sub(1, 55), false)
            return false
        end

        local initializingAutoSaveToggle = true
        local _, setAutoSaveConfig = CreateToggle(settingsCard, "Auto Save Config (Always On)", 52, function(enabled)
            -- CL now always persists settings; do not allow a stale OFF value to disable saving.
            autoSaveConfigEnabled = true
            savedConfig.autoSaveConfig = true
            lastAutoSaveSignature = nil
            if initializingAutoSaveToggle then return end
            saveAutoConfig(true)
            startAutoSaveLoop()
        end, "autoSaveConfig")
        setAutoSaveConfig(true)
        initializingAutoSaveToggle = false
        if autoSaveConfigEnabled then startAutoSaveLoop() end

        local antiAfkCard = CreateCard(left, "Anti AFK", 64)
        local antiAfkConnection
        RegisterCleanup(function()
            if antiAfkConnection then
                antiAfkConnection:Disconnect()
                antiAfkConnection = nil
            end
        end)
        local _, setAntiAfk = CreateToggle(antiAfkCard, "Anti AFK", 34, function(enabled)
            savedConfig.antiAfk = enabled
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
        setAntiAfk(savedConfig.antiAfk == true)

        local autoExecuteCard = CreateCard(left, "Auto Execute", 102)
        local autoExecuteStatus = Create("TextLabel", {
            Parent = autoExecuteCard,
            Position = UDim2.fromOffset(12, 82),
            Size = UDim2.new(1, -24, 0, 14),
            BackgroundTransparency = 1,
            Text = "Reconnect execution is disabled",
            TextColor3 = Theme.Gray,
            Font = Enum.Font.Gotham,
            TextSize = 8,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd
        })
        local AUTO_EXECUTE_FOLDER = CONFIG_ROOT_PATH .. "/autoexec"
        local function ensureAutoExecuteFolders()
            if type(environment.makefolder) ~= "function" then error("Executor makefolder API unavailable") end
            local function ensureFolder(path)
                if type(environment.isfolder) == "function" then
                    local ok, exists = pcall(environment.isfolder, path)
                    if ok and exists then return end
                end
                pcall(environment.makefolder, path)
                if type(environment.isfolder) == "function" then
                    local ok, exists = pcall(environment.isfolder, path)
                    if ok and not exists then error("Could not create folder: " .. path) end
                end
            end
            ensureFolder(CONFIG_ROOT_PATH)
            ensureFolder(AUTO_EXECUTE_FOLDER)
            ensureFolder(CONFIG_FOLDER_PATH)
        end
        local keepMoldyHubEnabled
        if type(savedConfig.keepMoldyHub) == "boolean" then
            keepMoldyHubEnabled = savedConfig.keepMoldyHub
        else
            local keepRaw = readConfigFile(KEEP_MOLDYHUB_PATH)
            keepMoldyHubEnabled = keepRaw and tostring(keepRaw):lower():match("^%s*true%s*$") ~= nil or false
        end
        local _, setKeepMoldyHub = CreateToggle(autoExecuteCard, "Keep MoldyHub after reconnect", 34, function(enabled)
            keepMoldyHubEnabled = enabled
            savedConfig.keepMoldyHub = enabled
            local ok, err = pcall(function()
                if type(environment.writefile) ~= "function" then error("Executor writefile API unavailable") end
                ensureAutoExecuteFolders()
                environment.writefile(KEEP_MOLDYHUB_PATH, enabled and "true" or "false")
            end)
            if ok then
                autoExecuteStatus.Text = enabled and "Reconnect execution is enabled" or "Reconnect execution is disabled"
                autoExecuteStatus.TextColor3 = enabled and Theme.Accent or Theme.Gray
            else
                autoExecuteStatus.Text = "Could not save reconnect setting: " .. tostring(err)
                autoExecuteStatus.TextColor3 = Color3.fromRGB(240, 110, 110)
            end
        end)
        setKeepMoldyHub(keepMoldyHubEnabled)

        local createAutoSpireButton = Create("TextButton", {
            Parent = autoExecuteCard,
            Position = UDim2.fromOffset(12, 34),
            Size = UDim2.new(1, -24, 0, 24),
            BackgroundColor3 = Theme.SurfaceInput,
            BorderSizePixel = 0,
            Text = "Create MoldyHub CL Exec File",
            TextColor3 = Theme.Text,
            Font = Enum.Font.GothamMedium,
            TextSize = 9,
            AutoButtonColor = true
        })
        Corner(createAutoSpireButton, 5)
        Stroke(createAutoSpireButton, Theme.Border, 1)
        createAutoSpireButton.MouseButton1Click:Connect(function()
            createAutoSpireButton.Active = false
            createAutoSpireButton.Text = "Creating..."
            task.spawn(function()
                local ok, err = pcall(function()
                    ensureAutoExecuteFolders()
                    if type(environment.writefile) ~= "function" then
                        error("Executor writefile API unavailable")
                    end
                    local filePath = AUTO_EXECUTE_FOLDER .. "/MoldyHub_CL_Exec.txt"
                    local loader = 'loadstring(game:HttpGet("https://pastefy.app/6oT19oKG/raw"))()'
                    environment.writefile(filePath, loader)
                    if type(environment.isfile) == "function" then
                        local exists = environment.isfile(filePath)
                        if not exists then error("Auto Spire file was not created") end
                    end
                    if type(environment.readfile) == "function" then
                        local saved = environment.readfile(filePath)
                        if saved ~= loader then error("Auto Spire file verification failed") end
                    end
                end)
                if ok then
                    autoExecuteStatus.Text = "Created MoldyHub/autoexec/MoldyHub_CL_Exec.txt"
                    autoExecuteStatus.TextColor3 = Color3.fromRGB(95, 220, 140)
                    createAutoSpireButton.Text = "Recreate MoldyHub CL Exec File"
                else
                    autoExecuteStatus.Text = "Auto Spire file failed: " .. tostring(err):sub(1, 70)
                    autoExecuteStatus.TextColor3 = Color3.fromRGB(240, 110, 110)
                    createAutoSpireButton.Text = "Retry Create MoldyHub CL Exec File"
                end
                createAutoSpireButton.Active = true
            end)
        end)

    elseif index == 2 then
        -- Grimoire notifier UI. The filter list is populated from the shop's
        -- Grimoire row frames.
        local grimoireNotifierEnabled = false
        local webhookUrl = type(savedConfig.webhookUrl) == "string" and savedConfig.webhookUrl or ""
        local roleId = type(savedConfig.roleId) == "string" and savedConfig.roleId or ""
        local mentionType = savedConfig.mentionType == "user" and "user" or "role"
        local grimoireFilter = {}
        local notifiedThisRestock = {}
        local lastWebhookAttemptAt = {}
        local restockCycleArmed = false
        local lastWebhookStatus = "No webhook sent yet"
        local timerStatusLabel
        local triggerStatusLabel
        local lastSendStatusLabel

        local card = CreateCard(left, "Grimoire Notifier", 455)
        local _, setGrimoireNotifier = CreateToggle(card, "Grimoire Notifier", 34, function(enabled)
            grimoireNotifierEnabled = enabled
            savedConfig.grimoireNotifier = enabled
        end)
        setGrimoireNotifier(savedConfig.grimoireNotifier == true)

        local function createNotifierInput(labelText, placeholder, y)
            Create("TextLabel", {
                Parent = card,
                Position = UDim2.fromOffset(11, y),
                Size = UDim2.new(1, -22, 0, 13),
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
                Position = UDim2.fromOffset(11, y + 16),
                Size = UDim2.new(1, -22, 0, 26),
                BackgroundColor3 = Theme.SurfaceInput,
                BackgroundTransparency = 0,
                Text = "",
                PlaceholderText = placeholder,
                PlaceholderColor3 = Theme.Gray,
                TextColor3 = Theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextWrapped = false,
                TextScaled = false,
                MultiLine = false,
                ClearTextOnFocus = false,
                TextEditable = true,
                Active = true,
                ClipsDescendants = true,
                BorderSizePixel = 0,
                ZIndex = 2
            })
            Corner(input, 5)
            Create("UIPadding", {
                Parent = input,
                PaddingLeft = UDim.new(0, 9),
                PaddingRight = UDim.new(0, 9)
            })
            return input
        end

        local webhookInput = createNotifierInput("Webhook URL", "Paste Discord webhook URL", 63)
        webhookInput.Text = webhookUrl
        webhookInput.FocusLost:Connect(function()
            webhookUrl = string.gsub(webhookInput.Text, "^%s*(.-)%s*$", "%1")
            savedConfig.webhookUrl = webhookUrl
        end)

        local roleInput = createNotifierInput("Mention ID (optional)", "Enter Discord user or role ID", 109)
        roleInput.Text = roleId
        roleInput.FocusLost:Connect(function()
            roleId = string.gsub(roleInput.Text, "^%s*(.-)%s*$", "%1")
            if roleId ~= "" and not string.match(roleId, "^%d+$") then
                roleId = ""
                roleInput.Text = ""
                roleInput.PlaceholderText = "Discord IDs must contain numbers only"
            end
            savedConfig.roleId = roleId
        end)

        Create("TextLabel", {
            Parent = card,
            Position = UDim2.fromOffset(12, 155),
            Size = UDim2.new(1, -24, 0, 12),
            BackgroundTransparency = 1,
            Text = "Mention type",
            TextColor3 = Theme.DarkGray,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 2
        })

        local roleButton
        local userButton
        local function createMentionTypeButton(label, value, xOffset)
            local button = Create("TextButton", {
                Parent = card,
                Position = UDim2.fromOffset(xOffset, 170),
                Size = UDim2.new(0.5, -15, 0, 22),
                BackgroundColor3 = mentionType == value and Theme.Accent or Theme.SurfaceInput,
                Text = label,
                TextColor3 = Theme.Text,
                Font = Enum.Font.GothamBold,
                TextSize = 9,
                BorderSizePixel = 0,
                AutoButtonColor = true,
                ZIndex = 2
            })
            Corner(button, 5)
            button.MouseButton1Click:Connect(function()
                mentionType = value
                savedConfig.mentionType = mentionType
                roleButton.BackgroundColor3 = mentionType == "role" and Theme.Accent or Theme.SurfaceInput
                userButton.BackgroundColor3 = mentionType == "user" and Theme.Accent or Theme.SurfaceInput
            end)
            return button
        end
        roleButton = createMentionTypeButton("Role", "role", 12)
        userButton = createMentionTypeButton("User", "user", 12 + (card.AbsoluteSize.X / 2))

        local checkSendButton = Create("TextButton", {
            Parent = card,
            Position = UDim2.fromOffset(12, 198),
            Size = UDim2.new(1, -24, 0, 24),
            BackgroundColor3 = Theme.SurfaceInput,
            Text = "Check & Send",
            TextColor3 = Theme.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 9,
            BorderSizePixel = 0,
            AutoButtonColor = true,
            ZIndex = 2
        })
        Corner(checkSendButton, 5)

        timerStatusLabel = Create("TextLabel", {
            Parent = card,
            Position = UDim2.fromOffset(12, 229),
            Size = UDim2.new(1, -24, 0, 14),
            BackgroundTransparency = 1,
            Text = "Restock timer: Reading...",
            TextColor3 = Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 2
        })
        triggerStatusLabel = Create("TextLabel", {
            Parent = card,
            Position = UDim2.fromOffset(12, 246),
            Size = UDim2.new(1, -24, 0, 14),
            BackgroundTransparency = 1,
            Text = "Auto trigger: Waiting for countdown",
            TextColor3 = Theme.Gray,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 2
        })
        lastSendStatusLabel = Create("TextLabel", {
            Parent = card,
            Position = UDim2.fromOffset(12, 263),
            Size = UDim2.new(1, -24, 0, 22),
            BackgroundTransparency = 1,
            Text = "Last webhook: " .. lastWebhookStatus,
            TextColor3 = Theme.Gray,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 2
        })

        Create("TextLabel", {
            Parent = card,
            Position = UDim2.fromOffset(12, 290),
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
            Position = UDim2.fromOffset(12, 307),
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
            Parent = card,
            Position = UDim2.fromOffset(12, 340),
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
            Padding = UDim.new(0, 1),
            SortOrder = Enum.SortOrder.Name
        })
        Create("UIPadding", {
            Parent = filterList,
            PaddingTop = UDim.new(0, 2),
            PaddingBottom = UDim.new(0, 2),
            PaddingLeft = UDim.new(0, 5),
            PaddingRight = UDim.new(0, 5)
        })

        filterDropdown.MouseButton1Click:Connect(function()
            filterDropdownOpen = not filterDropdownOpen
            filterList.Visible = filterDropdownOpen
        end)

        local function updateFilterCanvas()
            filterList.CanvasSize = UDim2.new(0, 0, 0, filterLayout.AbsoluteContentSize.Y + 4)
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
                    grimoireFilter[name] = type(savedConfig.grimoireFilter) == "table"
                        and savedConfig.grimoireFilter[name] == true or false
                end
            end
            table.sort(sortedNames)

            for _, grimoireName in ipairs(sortedNames) do
                local selected = grimoireFilter[grimoireName] == true
                local row = Create("TextButton", {
                    Name = grimoireName,
                    Parent = filterList,
                    Size = UDim2.new(1, -2, 0, 18),
                    BackgroundColor3 = Theme.SurfaceInput,
                    BackgroundTransparency = 1,
                    Text = "",
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    ZIndex = 21
                })
                local check = Create("Frame", {
                    Parent = row,
                    Position = UDim2.fromOffset(2, 3),
                    Size = UDim2.fromOffset(12, 12),
                    BackgroundColor3 = selected and Theme.Accent or Theme.Card,
                    BorderSizePixel = 0,
                    ZIndex = 22
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
                    ZIndex = 23
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
                    ZIndex = 23
                })
                row.MouseButton1Click:Connect(function()
                    grimoireFilter[grimoireName] = not grimoireFilter[grimoireName]
                    savedConfig.grimoireFilter = savedConfig.grimoireFilter or {}
                    savedConfig.grimoireFilter[grimoireName] = grimoireFilter[grimoireName]
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

        local function setLastWebhookStatus(message)
            lastWebhookStatus = tostring(message)
            if lastSendStatusLabel and lastSendStatusLabel.Parent then
                lastSendStatusLabel.Text = "Last webhook: " .. lastWebhookStatus
            end
        end

        local function sendGrimoireWebhook(grimoireId, price, restockTimer)
            if webhookUrl == "" then
                return false, "Enter a Discord webhook URL first."
            end
            local lowerWebhookUrl = string.lower(string.gsub(webhookUrl, "^%s*(.-)%s*$", "%1"))
            local validWebhookPrefix = false
            for _, prefix in ipairs({
                "https://discord.com/api/webhooks/",
                "https://discordapp.com/api/webhooks/",
                "https://canary.discord.com/api/webhooks/",
                "https://ptb.discord.com/api/webhooks/"
            }) do
                if string.sub(lowerWebhookUrl, 1, #prefix) == prefix then
                    validWebhookPrefix = true
                    break
                end
            end
            if not validWebhookPrefix then
                return false, "Use the full Discord webhook URL copied from Server Settings > Integrations > Webhooks."
            end

            local requestFunction = getRequestFunction()
            if not requestFunction then
                return false, "Executor HTTP request API is unavailable."
            end

            local mention = ""
            local allowedMentions = {parse = {}}
            if roleId ~= "" then
                if mentionType == "user" then
                    mention = "<@" .. roleId .. ">"
                    allowedMentions.users = {roleId}
                else
                    mention = "<@&" .. roleId .. ">"
                    allowedMentions.roles = {roleId}
                end
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
                        {name = "Price", value = tostring(price or "Unknown"), inline = true},
                        {name = "Restock Timer", value = tostring(restockTimer or "Unknown"), inline = true}
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
                return false, tostring(response)
            end

            local statusCode = type(response) == "table"
                and (response.StatusCode or response.status_code)
                or nil
            local numericStatus = tonumber(statusCode)
            local responseBody = type(response) == "table" and response.Body or nil
            if numericStatus and (numericStatus < 200 or numericStatus >= 300) then
                return false, "Discord returned HTTP " .. tostring(statusCode)
                    .. (responseBody and (": " .. tostring(responseBody)) or "")
            end
            if type(response) == "table" and response.Success == false then
                return false, "HTTP request failed" .. (responseBody and (": " .. tostring(responseBody)) or "")
            end

            return true, statusCode and ("HTTP " .. tostring(statusCode)) or "Request sent"
        end

        local function getGrimoirePage()
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            local shopUI = playerGui and playerGui:FindFirstChild("ShopUI")
            local container = shopUI and shopUI:FindFirstChild("Container")
            local shopPanel = container and container:FindFirstChild("ShopPanel")
            return shopPanel and shopPanel:FindFirstChild("Page_Grimoire")
        end

        local function getRestockTimerText()
            local grimoirePage = getGrimoirePage()
            local restockLabel = grimoirePage and grimoirePage:FindFirstChild("RestockLabel")
            if restockLabel and restockLabel:IsA("TextLabel") then
                local timerText = string.gsub(restockLabel.Text or "", "^%s*(.-)%s*$", "%1")
                if timerText ~= "" then return timerText end
            end
            return "Unknown"
        end

        local function getGrimoireStockInfo(itemFrame)
            local coinBuy = itemFrame and itemFrame:FindFirstChild("CoinBuy")
            local costRow = coinBuy and coinBuy:FindFirstChild("CostRow")
            local label = costRow and costRow:FindFirstChild("Label")
            if not label or not label:IsA("TextLabel") then return nil end

            local labelText = string.gsub(label.Text or "", "^%s*(.-)%s*$", "%1")
            local inStock = not string.find(string.upper(labelText), "OUT OF STOCK", 1, true)
            return inStock, labelText ~= "" and labelText or "Available"
        end

        local function checkAndSendSelectedGrimoires()
            webhookUrl = string.gsub(webhookInput.Text or "", "^%s*(.-)%s*$", "%1")
            roleId = string.gsub(roleInput.Text or "", "^%s*(.-)%s*$", "%1")
            savedConfig.webhookUrl = webhookUrl
            savedConfig.roleId = roleId

            local selectedNames = {}
            for grimoireName, selected in pairs(grimoireFilter) do
                if selected == true then table.insert(selectedNames, grimoireName) end
            end
            table.sort(selectedNames)

            if #selectedNames == 0 then
                checkSendButton.Text = "Select a Grimoire"
                task.delay(2, function()
                    if checkSendButton.Parent then checkSendButton.Text = "Check & Send" end
                end)
                return
            end

            checkSendButton.Text = "Checking..."
            checkSendButton.Active = false
            setLastWebhookStatus("Manual check started")

            task.spawn(function()
                local rows = getGrimoireRows()
                local timerText = getRestockTimerText()
                local sentCount = 0
                local inStockCount = 0
                local failedCount = 0
                local foundCount = 0

                if rows then
                    for _, grimoireName in ipairs(selectedNames) do
                        local itemFrame = rows:FindFirstChild(grimoireName)
                        if itemFrame and itemFrame:IsA("Frame") then
                            foundCount = foundCount + 1
                            local inStock, priceText = getGrimoireStockInfo(itemFrame)
                            if inStock == true then
                                inStockCount = inStockCount + 1
                                local success, result = sendGrimoireWebhook(grimoireName, priceText, timerText)
                                if success then
                                    sentCount = sentCount + 1
                                    setLastWebhookStatus(grimoireName .. " sent (" .. tostring(result) .. ")")
                                else
                                    failedCount = failedCount + 1
                                    setLastWebhookStatus(grimoireName .. " failed: " .. tostring(result))
                                    warn("[MoldyHub] Webhook failed for " .. grimoireName .. ": " .. tostring(result))
                                end
                                task.wait(0.25)
                            end
                        end
                    end
                end

                if not rows then
                    checkSendButton.Text = "Rows Not Found"
                    setLastWebhookStatus("Failed: Grimoire Rows not found")
                elseif foundCount == 0 then
                    checkSendButton.Text = "No Rows Found"
                    setLastWebhookStatus("Failed: selected Grimoire rows not found")
                elseif sentCount > 0 then
                    checkSendButton.Text = "Sent " .. tostring(sentCount) .. "/" .. tostring(inStockCount)
                elseif inStockCount == 0 then
                    checkSendButton.Text = "None In Stock"
                    setLastWebhookStatus("No selected Grimoires are in stock")
                else
                    checkSendButton.Text = "Send Failed"
                end
                if failedCount > 0 then
                    warn("[MoldyHub] " .. tostring(failedCount) .. " Grimoire webhook(s) failed.")
                end

                checkSendButton.Active = true
                task.wait(3)
                if checkSendButton.Parent then checkSendButton.Text = "Check & Send" end
            end)
        end

        checkSendButton.MouseButton1Click:Connect(checkAndSendSelectedGrimoires)

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

        -- Philippines time (UTC+8): use UTC epoch arithmetic so executor timezone cannot shift checks.
        -- UTC+8 is an exact multiple of two hours, so 2-hour boundaries remain epoch-aligned.
        local PH_TIME_OFFSET = 8 * 60 * 60
        local TWO_HOURS_SECONDS = 2 * 60 * 60

        local function getNextTwoHourBoundary(timestamp)
            return (math.floor(timestamp / TWO_HOURS_SECONDS) + 1) * TWO_HOURS_SECONDS
        end

        local function formatScheduleRemaining(totalSeconds)
            local totalMinutes = math.max(0, math.ceil(totalSeconds / 60))
            local hours = math.floor(totalMinutes / 60)
            local minutes = totalMinutes % 60
            return string.format("%02d:%02d", hours, minutes)
        end

        local nextWebhookBoundary = getNextTwoHourBoundary(os.time())

        task.spawn(function()
            while card.Parent do
                local currentRows = getGrimoireRows()
                if currentRows ~= grimoireRows then
                    grimoireRows = currentRows
                    watchGrimoireRows(grimoireRows)
                elseif not grimoireRows then
                    refreshGrimoireFilter()
                end

                local currentTimestamp = os.time()
                local secondsUntilCheck = math.max(0, nextWebhookBoundary - currentTimestamp)
                local scheduledTime = os.date("!%H:%M", nextWebhookBoundary + PH_TIME_OFFSET)

                if currentTimestamp >= nextWebhookBoundary then
                    -- A new two-hour clock window has started; allow one fresh notification per item.
                    table.clear(notifiedThisRestock)
                    table.clear(lastWebhookAttemptAt)

                    if triggerStatusLabel and triggerStatusLabel.Parent then
                        triggerStatusLabel.Text = grimoireNotifierEnabled
                            and "Auto trigger: Checking stock for " .. scheduledTime
                            or "Auto trigger: " .. scheduledTime .. " reached; notifier is OFF"
                    end

                    if grimoireNotifierEnabled and grimoireRows then
                        for _, itemFrame in ipairs(grimoireRows:GetChildren()) do
                            if itemFrame:IsA("Frame") and itemFrame.Name ~= "ShopItem" then
                                local id = itemFrame.Name
                                if grimoireFilter[id] == true and not notifiedThisRestock[id] then
                                    local inStock, priceText = getGrimoireStockInfo(itemFrame)
                                    if inStock == true then
                                        lastWebhookAttemptAt[id] = os.clock()
                                        task.spawn(function()
                                            local success, result = sendGrimoireWebhook(
                                                id,
                                                priceText,
                                                "2-hour schedule: " .. scheduledTime
                                            )
                                            if success then
                                                notifiedThisRestock[id] = true
                                                setLastWebhookStatus(id .. " auto-sent (" .. tostring(result) .. ")")
                                            else
                                                setLastWebhookStatus(id .. " auto-send failed: " .. tostring(result))
                                                warn("[MoldyHub] Auto webhook failed for " .. id .. ": " .. tostring(result))
                                            end
                                        end)
                                    end
                                end
                            end
                        end
                    elseif grimoireNotifierEnabled and not grimoireRows then
                        setLastWebhookStatus("Scheduled check reached, but Grimoire Rows are missing")
                    end

                    -- Advance to the next exact even-hour boundary; never add drift or extra minutes.
                    nextWebhookBoundary = getNextTwoHourBoundary(currentTimestamp)
                else
                    if triggerStatusLabel and triggerStatusLabel.Parent then
                        triggerStatusLabel.Text = grimoireNotifierEnabled
                            and "Auto trigger: Next check at " .. scheduledTime
                            or "Auto trigger: Notifier OFF; next check at " .. scheduledTime
                    end
                end

                if timerStatusLabel and timerStatusLabel.Parent then
                    timerStatusLabel.Text = "Next 2-hour check: " .. scheduledTime
                        .. " | In: " .. formatScheduleRemaining(secondsUntilCheck)
                end

                task.wait(1)
            end
            if rowsAddedConnection then rowsAddedConnection:Disconnect() end
            if rowsRemovedConnection then rowsRemovedConnection:Disconnect() end
        end)

    elseif index == 3 then
        -- Labyrinth: mark every chest visited, then engage the boss with Farm toggles.
        local autoOpenChestEnabled = false
        local chestLoopId = 0
        local openedChests = {}
        -- Auto Spire: move to the pod, set difficulty, start, then leave at the configured wave.
        local spireCard = CreateCard(left, "Auto Spire", 148)
        local spireEnabled = false
        local spireLoopId = 0
        local spireDifficulties = {"Easy", "Medium", "Hard", "Extreme"}
        local spireDifficultyIndex = 2
        for difficultyIndex, difficultyName in ipairs(spireDifficulties) do
            if difficultyName == savedConfig.spireDifficulty then spireDifficultyIndex = difficultyIndex break end
        end
        local spireWaveInput
        local spireStatus = Create("TextLabel", {
            Parent = spireCard,
            Position = UDim2.fromOffset(12, 61),
            Size = UDim2.new(1, -24, 0, 16),
            BackgroundTransparency = 1,
            Text = "Status: Idle",
            TextColor3 = Theme.Gray,
            Font = Enum.Font.Gotham,
            TextSize = 8,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd
        })
        local function setSpireStatus(message, color)
            if spireStatus and spireStatus.Parent then
                spireStatus.Text = "Status: " .. tostring(message)
                spireStatus.TextColor3 = color or Theme.Gray
            end
        end

        local setAutoSpire
        local spireToggleRow
        spireToggleRow, setAutoSpire = CreateToggle(spireCard, "Auto Spire", 34, function(enabled)
            spireEnabled = enabled
            savedConfig.autoSpire = enabled
            spireLoopId = spireLoopId + 1
            local thisLoop = spireLoopId
            if not enabled then
                setSpireStatus("Stopped")
                return
            end

            setSpireStatus("Preparing portal...", Theme.Accent)
            task.spawn(function()
                local function isActive()
                    return spireEnabled and spireLoopId == thisLoop and spireCard.Parent ~= nil
                end
                local leaveWave = tonumber(spireWaveInput and spireWaveInput.Text)
                    or tonumber(savedConfig.spireLeaveWave)
                if leaveWave then leaveWave = math.max(1, math.floor(leaveWave)) end

                local function monitorDungeon(replicatedStorage)
                    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
                    local dungeonUI = playerGui:WaitForChild("DungeonUI", 90)
                    local container = dungeonUI and dungeonUI:WaitForChild("Container", 20)
                    local topBar = container and container:WaitForChild("TopBar", 20)
                    local mainFrame = topBar and topBar:WaitForChild("MainFrame", 20)
                    local waveLabel = mainFrame and mainFrame:WaitForChild("Wave", 20)
                    if not waveLabel then
                        setSpireStatus("Waiting for dungeon wave UI timed out", Color3.fromRGB(240, 170, 80))
                        return
                    end

                    setSpireStatus(leaveWave and ("Dungeon active; target wave " .. leaveWave)
                        or "Dungeon active; monitoring waves", Theme.Accent)
                    while isActive() do
                        local waveText = tostring(waveLabel.Text or "")
                        local currentWave = tonumber(string.match(waveText, "%d+"))
                        if currentWave then
                            if leaveWave then
                                setSpireStatus("Wave " .. currentWave .. " / " .. leaveWave, Theme.Accent)
                                if currentWave >= leaveWave then
                                    setSpireStatus("Target reached; leaving dungeon...", Color3.fromRGB(95, 220, 140))
                                    local leaveRemote = replicatedStorage:WaitForChild("WK_Remotes"):WaitForChild("LeaveDungeon")
                                    local leaveOk, leaveError = pcall(function()
                                        leaveRemote:FireServer()
                                    end)
                                    if not leaveOk then
                                        setSpireStatus("Leave failed: " .. tostring(leaveError), Color3.fromRGB(240, 110, 110))
                                        return
                                    end
                                    setAutoSpire(false)
                                    setSpireStatus("Left at wave " .. currentWave, Color3.fromRGB(95, 220, 140))
                                    return
                                end
                            else
                                setSpireStatus("Wave " .. currentWave .. " (set leave wave)", Theme.Accent)
                            end
                        end
                        task.wait(0.25)
                    end
                end

                -- On every execution, first look for an already-running dungeon.
                -- The destination game may need a few seconds to create its wave UI after teleport.
                local playerGui = LocalPlayer:WaitForChild("PlayerGui")
                local activeWaveLabel
                for attempt = 1, 5 do
                    local dungeonUI = playerGui:FindFirstChild("DungeonUI")
                    local container = dungeonUI and dungeonUI:FindFirstChild("Container")
                    local topBar = container and container:FindFirstChild("TopBar")
                    local mainFrame = topBar and topBar:FindFirstChild("MainFrame")
                    local waveLabel = mainFrame and mainFrame:FindFirstChild("Wave")
                    if waveLabel and waveLabel:IsA("TextLabel") then
                        activeWaveLabel = waveLabel
                        break
                    end
                    setSpireStatus("Checking for active dungeon (" .. attempt .. "/5)...", Theme.Accent)
                    if attempt < 5 then task.wait(1) end
                    if not isActive() then return end
                end

                if activeWaveLabel then
                    setSpireStatus("Existing dungeon found; resuming wave monitor...", Theme.Accent)
                    monitorDungeon(game:GetService("ReplicatedStorage"))
                    return
                end

                setSpireStatus("No active dungeon found; preparing Pod1...", Theme.Accent)
                local function getPortalCenter(portal)
                    if not portal then return nil end
                    if portal:IsA("Model") then
                        local ok, pivot = pcall(function()
                            local boxCFrame = portal:GetBoundingBox()
                            return boxCFrame
                        end)
                        if ok and pivot then return pivot.Position end
                    elseif portal:IsA("BasePart") then
                        return portal.Position
                    end

                    local minPoint, maxPoint
                    for _, item in ipairs(portal:GetDescendants()) do
                        if item:IsA("BasePart") then
                            local half = item.Size * 0.5
                            local p = item.Position
                            local low = p - half
                            local high = p + half
                            minPoint = minPoint and Vector3.new(
                                math.min(minPoint.X, low.X), math.min(minPoint.Y, low.Y), math.min(minPoint.Z, low.Z)
                            ) or low
                            maxPoint = maxPoint and Vector3.new(
                                math.max(maxPoint.X, high.X), math.max(maxPoint.Y, high.Y), math.max(maxPoint.Z, high.Z)
                            ) or high
                        end
                    end
                    if minPoint and maxPoint then return (minPoint + maxPoint) * 0.5 end
                    return nil
                end

                local portal = workspace:FindFirstChild("Map")
                portal = portal and portal:FindFirstChild("Islands")
                portal = portal and portal:FindFirstChild("STARTER_ISLAND")
                portal = portal and portal:FindFirstChild("Teleporters")
                portal = portal and portal:FindFirstChild("DungeonPads")
                portal = portal and portal:FindFirstChild("Pod1")
                local portalCenter = getPortalCenter(portal)
                if not portalCenter then
                    setSpireStatus("Pod1 portal not found", Color3.fromRGB(240, 110, 110))
                    return
                end

                local character = LocalPlayer.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                local root = character and character:FindFirstChild("HumanoidRootPart")
                if not character or not humanoid or humanoid.Health <= 0 or not root then
                    setSpireStatus("Character not ready", Color3.fromRGB(240, 110, 110))
                    return
                end

                setSpireStatus("Moving to Pod1 center...", Theme.Accent)
                root.CFrame = CFrame.new(portalCenter + Vector3.new(0, 3, 0))
                local arrived = false
                local arrivalDeadline = os.clock() + 8
                repeat
                    if not isActive() then return end
                    character = LocalPlayer.Character
                    root = character and character:FindFirstChild("HumanoidRootPart")
                    if root and (root.Position - portalCenter).Magnitude <= 8 then
                        arrived = true
                        break
                    end
                    task.wait(0.1)
                until os.clock() >= arrivalDeadline

                if not isActive() then return end
                if not arrived then
                    setSpireStatus("Could not confirm portal position", Color3.fromRGB(240, 170, 80))
                    return
                end

                local difficulty = spireDifficulties[spireDifficultyIndex]
                setSpireStatus("Setting " .. difficulty .. " difficulty...", Theme.Accent)
                local replicatedStorage = game:GetService("ReplicatedStorage")
                local remotes = replicatedStorage:WaitForChild("Remotes")
                local setDifficultyRemote = remotes:WaitForChild("DungeonPodSet")
                local startDungeonRemote = remotes:WaitForChild("StartDungeon")
                local difficultyOk, difficultyError = pcall(function()
                    setDifficultyRemote:FireServer({Difficulty = difficulty})
                end)
                if not difficultyOk then
                    setSpireStatus("Difficulty failed: " .. tostring(difficultyError), Color3.fromRGB(240, 110, 110))
                    return
                end
                task.wait(0.3)
                if not isActive() then return end

                local startOk, startError = pcall(function()
                    startDungeonRemote:FireServer()
                end)
                if not startOk then
                    setSpireStatus("Start failed: " .. tostring(startError), Color3.fromRGB(240, 110, 110))
                    return
                end

                monitorDungeon(replicatedStorage)
            end)
        end)

        Create("TextLabel", {
            Parent = spireCard,
            Position = UDim2.fromOffset(12, 87),
            Size = UDim2.fromOffset(76, 20),
            BackgroundTransparency = 1,
            Text = "Difficulty",
            TextColor3 = Theme.DarkGray,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        local spireDifficultyButton = Create("TextButton", {
            Parent = spireCard,
            Position = UDim2.new(1, -116, 0, 84),
            Size = UDim2.fromOffset(104, 23),
            BackgroundColor3 = Theme.SurfaceInput,
            Text = spireDifficulties[spireDifficultyIndex],
            TextColor3 = Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            BorderSizePixel = 0,
            AutoButtonColor = true
        })
        Corner(spireDifficultyButton, 5)
        Stroke(spireDifficultyButton, Theme.Border, 1)
        spireDifficultyButton.MouseButton1Click:Connect(function()
            spireDifficultyIndex = (spireDifficultyIndex % #spireDifficulties) + 1
            spireDifficultyButton.Text = spireDifficulties[spireDifficultyIndex]
            savedConfig.spireDifficulty = spireDifficulties[spireDifficultyIndex]
        end)

        Create("TextLabel", {
            Parent = spireCard,
            Position = UDim2.fromOffset(12, 116),
            Size = UDim2.fromOffset(110, 20),
            BackgroundTransparency = 1,
            Text = "Leave at wave",
            TextColor3 = Theme.DarkGray,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        spireWaveInput = Create("TextBox", {
            Parent = spireCard,
            Position = UDim2.new(1, -66, 0, 112),
            Size = UDim2.fromOffset(54, 23),
            BackgroundColor3 = Theme.SurfaceInput,
            TextColor3 = Theme.Text,
            PlaceholderColor3 = Theme.Gray,
            PlaceholderText = "e.g. 10",
            Text = type(savedConfig.spireLeaveWave) == "number" and tostring(savedConfig.spireLeaveWave) or "",
            Font = Enum.Font.Gotham,
            TextSize = 9,
            ClearTextOnFocus = false,
            BorderSizePixel = 0
        })
        Corner(spireWaveInput, 5)
        Stroke(spireWaveInput, Theme.Border, 1)
        spireWaveInput.FocusLost:Connect(function()
            local wave = tonumber(spireWaveInput.Text)
            if wave then
                wave = math.max(1, math.floor(wave))
                spireWaveInput.Text = tostring(wave)
                savedConfig.spireLeaveWave = wave
            else
                spireWaveInput.Text = ""
                savedConfig.spireLeaveWave = nil
            end
        end)
        -- Restore Auto Spire only after its wave input and controls exist.
        setAutoSpire(savedConfig.autoSpire == true)

        local chestCard = CreateCard(left, "Auto open chest", 88)
        local chestStatus = Create("TextLabel", {
            Parent = chestCard,
            Position = UDim2.fromOffset(12, 62),
            Size = UDim2.new(1, -24, 0, 18),
            BackgroundTransparency = 1,
            Text = "Chest status: Idle",
            TextColor3 = Theme.Gray,
            Font = Enum.Font.Gotham,
            TextSize = 8,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd
        })
        local function getChestBody(chest)
            local body = chest and chest:FindFirstChild("Body")
            if not body then return nil end
            if body:IsA("BasePart") then return body end
            return body:FindFirstChildWhichIsA("BasePart", true)
        end
        local function getChestPrompt(chest)
            local body = chest and chest:FindFirstChild("Body")
            return body and body:FindFirstChild("ProximityPrompt", true)
        end
        local function setChestStatus(message, color)
            if chestStatus and chestStatus.Parent then
                chestStatus.Text = "Chest status: " .. tostring(message)
                chestStatus.TextColor3 = color or Theme.Gray
            end
        end
        local function markChestOpened(chest, bodyPart)
            openedChests[chest] = true
            if bodyPart and not bodyPart:FindFirstChild("MoldyHubOpenedMarker") then
                local marker = Create("BillboardGui", {
                    Name = "MoldyHubOpenedMarker",
                    Parent = bodyPart,
                    Adornee = bodyPart,
                    Size = UDim2.fromOffset(100, 24),
                    StudsOffset = Vector3.new(0, 3, 0),
                    AlwaysOnTop = true
                })
                local markerText = Create("TextLabel", {
                    Parent = marker,
                    Size = UDim2.fromScale(1, 1),
                    BackgroundColor3 = Color3.fromRGB(24, 110, 65),
                    BackgroundTransparency = 0.12,
                    Text = "✓ OPENED",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    Font = Enum.Font.GothamBold,
                    TextSize = 11,
                    BorderSizePixel = 0
                })
                Corner(markerText, 6)
            end
        end
        local function isLoopActive(thisLoop)
            return autoOpenChestEnabled and chestLoopId == thisLoop and chestCard.Parent ~= nil
        end
        -- Any live enemy model in workspace.Enemies can trigger the encounter; do not
        -- depend on its name containing "Boss".
        local function findAliveEnemy(enemies)
            if not enemies then return nil end
            for _, enemy in ipairs(enemies:GetChildren()) do
                if enemy:IsA("Model") then
                    local humanoid = enemy:FindFirstChildOfClass("Humanoid")
                    local root = enemy:FindFirstChild("HumanoidRootPart")
                    if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
                        return enemy, root
                    end
                end
            end
            return nil
        end
        local floatVelocity
        local function setChestFloat(enabled, root)
            if not enabled then
                if floatVelocity then
                    pcall(function() floatVelocity:Destroy() end)
                    floatVelocity = nil
                end
                return
            end
            if not root or not root.Parent then return end
            if floatVelocity and floatVelocity.Parent == root then return end
            if floatVelocity then pcall(function() floatVelocity:Destroy() end) end
            floatVelocity = Instance.new("BodyVelocity")
            floatVelocity.Name = "MoldyHubChestFloat"
            floatVelocity.MaxForce = Vector3.new(0, 1e9, 0)
            floatVelocity.P = 1e5
            floatVelocity.Velocity = Vector3.zero
            floatVelocity.Parent = root
        end
        local function allChestsMarked(chests)
            if #chests == 0 then return false end
            for _, chest in ipairs(chests) do
                if not openedChests[chest] then return false end
            end
            return true
        end
        local chestCombatOverride = false
        local chestPreviousFarmEnabled = false
        local chestPreviousOrbitEnabled = false
        local function restoreChestCombatToggles()
            if not chestCombatOverride then return end
            chestCombatOverride = false
            if setLabyrinthAutoAttack then setLabyrinthAutoAttack(chestPreviousFarmEnabled) end
            if setLabyrinthAutoOrbit then setLabyrinthAutoOrbit(chestPreviousOrbitEnabled) end
        end
        local _, setAutoOpenChest = CreateToggle(chestCard, "Auto open chest", 34, function(enabled)
            autoOpenChestEnabled = enabled
            savedConfig.autoOpenChest = enabled
            chestLoopId = chestLoopId + 1
            local thisLoop = chestLoopId
            if not enabled then
                restoreChestCombatToggles()
                setChestFloat(false)
                setChestStatus("Stopped")
                return
            end
            chestPreviousFarmEnabled = savedConfig.autoFarm == true
            chestPreviousOrbitEnabled = savedConfig.orbitEnabled == true
            chestCombatOverride = false
            setChestStatus("Floating while opening chests", Theme.Accent)
            task.spawn(function()
                local nextChestIndex = 1
                local chestFolder
                local enemies
                local function getCurrentRoot()
                    local character = LocalPlayer.Character
                    return character and character:FindFirstChild("HumanoidRootPart")
                end
                while isLoopActive(thisLoop) do
                    local root = getCurrentRoot()
                    if root then setChestFloat(true, root) end

                    chestFolder = workspace:FindFirstChild("WK_DungeonChests")
                    local chests = chestFolder and chestFolder:GetChildren() or {}
                    if #chests == 0 then
                        setChestStatus("Floating; waiting for WK_DungeonChests")
                        task.wait(1)
                    elseif not allChestsMarked(chests) then
                        if nextChestIndex > #chests then nextChestIndex = 1 end
                        local chest = chests[nextChestIndex]
                        nextChestIndex = nextChestIndex + 1
                        if chest and not openedChests[chest] then
                            local bodyPart = getChestBody(chest)
                            if bodyPart then
                                root = getCurrentRoot()
                                if root then
                                    setChestFloat(true, root)
                                    setChestStatus("Floating to " .. chest.Name, Theme.Accent)
                                    root.CFrame = CFrame.new(
                                        bodyPart.Position + Vector3.new(0, 2, 4),
                                        bodyPart.Position
                                    )
                                    task.wait(math.random(8, 14) / 10)
                                    if not isLoopActive(thisLoop) then break end
                                    root = getCurrentRoot()
                                    if root then setChestFloat(true, root) end

                                    if root and (root.Position - bodyPart.Position).Magnitude <= 12 then
                                        setChestStatus("Floating; waiting for prompt: " .. chest.Name, Theme.Accent)
                                        local prompt
                                        local promptDeadline = os.clock() + 6
                                        repeat
                                            prompt = getChestPrompt(chest)
                                            if prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled then
                                                break
                                            end
                                            task.wait(0.1)
                                        until os.clock() >= promptDeadline or not isLoopActive(thisLoop)

                                        if not isLoopActive(thisLoop) then break end
                                        if prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled and prompt.Parent then
                                            setChestStatus("Floating; opening " .. chest.Name, Theme.Accent)
                                            local fired = false
                                            if type(environment.fireproximityprompt) == "function" then
                                                local fireOk, fireResult = pcall(environment.fireproximityprompt, prompt)
                                                fired = fireOk and fireResult ~= false
                                            end
                                            if not fired then
                                                local holdOk = pcall(function()
                                                    prompt:InputHoldBegin()
                                                    task.wait(math.max(0.1, prompt.HoldDuration))
                                                    prompt:InputHoldEnd()
                                                end)
                                                fired = holdOk
                                            end
                                            if fired then
                                                markChestOpened(chest, bodyPart)
                                                setChestStatus("✓ Opened " .. chest.Name .. " (floating)",
                                                    Color3.fromRGB(95, 220, 140))
                                            else
                                                setChestStatus("Could not activate " .. chest.Name,
                                                    Color3.fromRGB(240, 110, 110))
                                            end
                                        else
                                            markChestOpened(chest, bodyPart)
                                            setChestStatus("No prompt; marked " .. chest.Name .. " opened",
                                                Color3.fromRGB(240, 170, 80))
                                        end
                                    else
                                        setChestStatus("Character root missing or teleport settling",
                                            Color3.fromRGB(240, 170, 80))
                                    end
                                else
                                    setChestStatus("Character root not found", Color3.fromRGB(240, 110, 110))
                                end
                            else
                                markChestOpened(chest, nil)
                                setChestStatus("No Body; marked " .. chest.Name .. " visited",
                                    Color3.fromRGB(240, 170, 80))
                            end
                            task.wait(math.random(12, 20) / 10)
                        else
                            task.wait(0.15)
                        end
                    else
                        -- Chests are complete. Stay floating until any live enemy appears.
                        enemies = workspace:FindFirstChild("Enemies")
                        local enemy, enemyRoot = findAliveEnemy(enemies)
                        if not enemy then
                            setChestFloat(true, getCurrentRoot())
                            setChestStatus("All chests marked; floating and waiting for enemy spawn", Theme.Accent)
                            task.wait(0.5)
                        else
                            setChestFloat(false)
                            root = getCurrentRoot()
                            if root then
                                setChestStatus("Moving to enemy: " .. enemy.Name, Theme.Accent)
                                root.CFrame = CFrame.new(
                                    enemyRoot.Position + Vector3.new(0, 0, 8),
                                    enemyRoot.Position
                                )
                                task.wait(math.random(10, 16) / 10)
                                if not isLoopActive(thisLoop) then break end

                                -- Temporarily enable combat toggles while clearing the spawned enemy.
                                chestCombatOverride = true
                                if setLabyrinthAutoAttack then setLabyrinthAutoAttack(true) end
                                if setLabyrinthAutoOrbit then setLabyrinthAutoOrbit(true) end
                                setChestStatus("Fighting enemy: " .. enemy.Name, Theme.Accent)
                                while isLoopActive(thisLoop) and enemy.Parent == enemies do
                                    local humanoid = enemy:FindFirstChildOfClass("Humanoid")
                                    if not humanoid or humanoid.Health <= 0 then break end
                                    task.wait(0.4)
                                end
                                restoreChestCombatToggles()
                                if isLoopActive(thisLoop) then
                                    setChestFloat(true, getCurrentRoot())
                                    setChestStatus("Enemy defeated or gone; floating for next spawn",
                                        Color3.fromRGB(95, 220, 140))
                                    task.wait(0.5)
                                end
                            else
                                setChestFloat(true, getCurrentRoot())
                                setChestStatus("Character root not found", Color3.fromRGB(240, 110, 110))
                                task.wait(1)
                            end
                        end
                    end
                end
                setChestFloat(false)
                restoreChestCombatToggles()
            end)
        end)
        setAutoOpenChest(savedConfig.autoOpenChest == true)
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
