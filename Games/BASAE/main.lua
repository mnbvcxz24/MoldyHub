-- MoldyHub BASAE modular loader
-- Experimental first-pass split. Shared locals are not yet refactored between modules.

local Players = game:GetService("Players")
local BASE_URL = "https://raw.githubusercontent.com/mnbvcxz24/MoldyHub/main/Games/BASAE/Modules/"
local MODULES = {
    "Core",
    "Dashboard",
    "Farm",
    "Theme",
    "Settings",
    "Events",
    "Misc",
    "Runtime"
}

-- LOADING SCREEN
local LoadingGui
local StatusLabel
local ProgressLabel
local ProgressFill

local function CreateLoadingScreen()
    local ok, result = pcall(function()
        local gui = Instance.new("ScreenGui")
        gui.Name = "MoldyHub_BASAE_Loading"
        gui.IgnoreGuiInset = true
        gui.ResetOnSpawn = false
        gui.DisplayOrder = 1000000
        gui.Parent = game:GetService("CoreGui")

        local overlay = Instance.new("Frame")
        overlay.Name = "Overlay"
        overlay.Size = UDim2.fromScale(1, 1)
        overlay.BackgroundColor3 = Color3.fromRGB(5, 5, 7)
        overlay.BackgroundTransparency = 0.12
        overlay.BorderSizePixel = 0
        overlay.Parent = gui

        local panel = Instance.new("Frame")
        panel.Name = "LoadingPanel"
        panel.AnchorPoint = Vector2.new(0.5, 0.5)
        panel.Position = UDim2.fromScale(0.5, 0.5)
        panel.Size = UDim2.fromOffset(330, 132)
        panel.BackgroundColor3 = Color3.fromRGB(17, 17, 19)
        panel.BorderSizePixel = 0
        panel.Parent = overlay

        local panelCorner = Instance.new("UICorner")
        panelCorner.CornerRadius = UDim.new(0, 10)
        panelCorner.Parent = panel

        local panelStroke = Instance.new("UIStroke")
        panelStroke.Color = Color3.fromRGB(70, 47, 18)
        panelStroke.Thickness = 1
        panelStroke.Parent = panel

        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.BackgroundTransparency = 1
        title.Position = UDim2.fromOffset(18, 14)
        title.Size = UDim2.new(1, -36, 0, 25)
        title.Font = Enum.Font.GothamBold
        title.Text = "MoldyHub"
        title.TextColor3 = Color3.fromRGB(255, 181, 55)
        title.TextSize = 19
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = panel

        local subtitle = Instance.new("TextLabel")
        subtitle.Name = "Subtitle"
        subtitle.BackgroundTransparency = 1
        subtitle.Position = UDim2.fromOffset(19, 40)
        subtitle.Size = UDim2.new(1, -38, 0, 16)
        subtitle.Font = Enum.Font.Gotham
        subtitle.Text = "Preparing BASAE..."
        subtitle.TextColor3 = Color3.fromRGB(153, 146, 132)
        subtitle.TextSize = 10
        subtitle.TextXAlignment = Enum.TextXAlignment.Left
        subtitle.Parent = panel

        local track = Instance.new("Frame")
        track.Name = "ProgressTrack"
        track.Position = UDim2.fromOffset(19, 75)
        track.Size = UDim2.new(1, -38, 0, 7)
        track.BackgroundColor3 = Color3.fromRGB(35, 33, 29)
        track.BorderSizePixel = 0
        track.ClipsDescendants = true
        track.Parent = panel

        local trackCorner = Instance.new("UICorner")
        trackCorner.CornerRadius = UDim.new(1, 0)
        trackCorner.Parent = track

        local fill = Instance.new("Frame")
        fill.Name = "ProgressFill"
        fill.Size = UDim2.fromScale(0, 1)
        fill.BackgroundColor3 = Color3.fromRGB(255, 181, 55)
        fill.BorderSizePixel = 0
        fill.Parent = track

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(1, 0)
        fillCorner.Parent = fill

        local progress = Instance.new("TextLabel")
        progress.Name = "Progress"
        progress.BackgroundTransparency = 1
        progress.Position = UDim2.fromOffset(19, 91)
        progress.Size = UDim2.new(1, -38, 0, 17)
        progress.Font = Enum.Font.Gotham
        progress.Text = "0 / " .. tostring(#MODULES) .. " modules"
        progress.TextColor3 = Color3.fromRGB(208, 201, 187)
        progress.TextSize = 10
        progress.TextXAlignment = Enum.TextXAlignment.Right
        progress.Parent = panel

        return gui, subtitle, progress, fill
    end)

    if ok then
        LoadingGui = result
        -- The remaining return values are assigned separately below.
    end
    return ok, result
end

local screenOk, screenResult = CreateLoadingScreen()
if screenOk then
    LoadingGui = screenResult
    StatusLabel = LoadingGui:FindFirstChild("Subtitle", true)
    ProgressLabel = LoadingGui:FindFirstChild("Progress", true)
    ProgressFill = LoadingGui:FindFirstChild("ProgressFill", true)
end

local function SetLoadingStatus(message, completed, color)
    if not LoadingGui or not LoadingGui.Parent then return end
    if StatusLabel then StatusLabel.Text = message end
    if ProgressLabel then
        ProgressLabel.Text = tostring(completed) .. " / " .. tostring(#MODULES) .. " modules"
    end
    if ProgressFill then
        ProgressFill.Size = UDim2.fromScale(math.clamp(completed / #MODULES, 0, 1), 1)
        if color then ProgressFill.BackgroundColor3 = color end
    end
end

local function CloseLoadingScreen()
    if LoadingGui then
        LoadingGui:Destroy()
        LoadingGui = nil
    end
end

for index, moduleName in ipairs(MODULES) do
    SetLoadingStatus("Loading " .. moduleName .. "...", index - 1)

    local ok, loadError = pcall(function()
        local url = BASE_URL .. moduleName .. ".lua"
        local source = game:HttpGet(url)
        if type(source) ~= "string" or source == "" then
            error("Module source is empty")
        end

        local chunk, compileError = loadstring(source, "@BASAE/Modules/" .. moduleName .. ".lua")
        if not chunk then
            error("Compile error: " .. tostring(compileError))
        end

        local ran, runtimeError = pcall(chunk)
        if not ran then
            error("Runtime error: " .. tostring(runtimeError))
        end
    end)

    if not ok then
        SetLoadingStatus("Failed: " .. moduleName, index - 1, Color3.fromRGB(235, 75, 75))
        if StatusLabel then
            StatusLabel.Text = ("Failed: %s | %s"):format(moduleName, tostring(loadError):sub(1, 90))
        end
        task.wait(2)
        CloseLoadingScreen()
        error("[BASAE] " .. tostring(loadError))
    end

    SetLoadingStatus("Loaded " .. moduleName, index)
    task.wait()
end

SetLoadingStatus("BASAE loaded successfully!", #MODULES)
task.wait(0.45)
CloseLoadingScreen()
