-- MoldyHub BASAE V2 - clean modular bootstrap
-- All module chunks are compiled first. Initializers then run in a shared Context.
-- The original BASAE.lua is intentionally preserved as a reference backup.

local CORE_GUI = game:GetService("CoreGui")
local BASE_URL = "https://raw.githubusercontent.com/mnbvcxz24/MoldyHub/main/Games/BASAE/Modules/"
local MODULES = {
    "Core", "UI", "Dashboard", "Farm", "Events", "Misc", "Theme", "Settings", "Runtime"
}

pcall(function()
    local old = CORE_GUI:FindFirstChild("MoldyHub_BASAE_UI")
    if old then old:Destroy() end
    local oldLoad = CORE_GUI:FindFirstChild("MoldyHub_BASAE_Loading")
    if oldLoad then oldLoad:Destroy() end
end)

local loading = Instance.new("ScreenGui")
loading.Name = "MoldyHub_BASAE_Loading"
loading.IgnoreGuiInset = true
loading.ResetOnSpawn = false
loading.DisplayOrder = 1000000
loading.Parent = CORE_GUI

local overlay = Instance.new("Frame")
overlay.Size = UDim2.fromScale(1,1)
overlay.BackgroundColor3 = Color3.fromRGB(5,5,7)
overlay.BackgroundTransparency = 0.08
overlay.BorderSizePixel = 0
overlay.Parent = loading

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5,0.5)
panel.Position = UDim2.fromScale(0.5,0.5)
panel.Size = UDim2.fromOffset(340,142)
panel.BackgroundColor3 = Color3.fromRGB(17,17,19)
panel.BorderSizePixel = 0
panel.Parent = overlay
Instance.new("UICorner",panel).CornerRadius = UDim.new(0,10)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(18,14)
title.Size = UDim2.new(1,-36,0,24)
title.Font = Enum.Font.GothamBold
title.Text = "MoldyHub"
title.TextColor3 = Color3.fromRGB(255,181,55)
title.TextSize = 19
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Position = UDim2.fromOffset(19,43)
status.Size = UDim2.new(1,-38,0,18)
status.Font = Enum.Font.Gotham
status.Text = "Preparing modules..."
status.TextColor3 = Color3.fromRGB(208,201,187)
status.TextSize = 10
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = panel

local track = Instance.new("Frame")
track.Position = UDim2.fromOffset(19,78)
track.Size = UDim2.new(1,-38,0,7)
track.BackgroundColor3 = Color3.fromRGB(38,35,30)
track.BorderSizePixel = 0
track.ClipsDescendants = true
track.Parent = panel
Instance.new("UICorner",track).CornerRadius = UDim.new(1,0)

local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(0,1)
fill.BackgroundColor3 = Color3.fromRGB(255,181,55)
fill.BorderSizePixel = 0
fill.Parent = track
Instance.new("UICorner",fill).CornerRadius = UDim.new(1,0)

local count = Instance.new("TextLabel")
count.BackgroundTransparency = 1
count.Position = UDim2.fromOffset(19,92)
count.Size = UDim2.new(1,-38,0,17)
count.Font = Enum.Font.Gotham
count.Text = "0 / " .. #MODULES .. " modules"
count.TextColor3 = Color3.fromRGB(153,146,132)
count.TextSize = 10
count.TextXAlignment = Enum.TextXAlignment.Right
count.Parent = panel

local function progress(message, done, failed)
    status.Text = message
    count.Text = tostring(done) .. " / " .. #MODULES .. " modules"
    fill.Size = UDim2.fromScale(math.clamp(done/#MODULES,0,1),1)
    if failed then fill.BackgroundColor3 = Color3.fromRGB(235,75,75) end
end

local function fail(message, done)
    progress("ERROR: " .. tostring(message):sub(1,110),done,true)
    task.wait(4)
    if loading then loading:Destroy() end
    error("[BASAE] " .. tostring(message),0)
end

-- Download and compile all modules before executing any of them.
local initializers = {}
for index, name in ipairs(MODULES) do
    progress("Downloading " .. name .. "...",index-1)
    local ok, result = pcall(function()
        local source = game:HttpGet(BASE_URL .. name .. ".lua")
        assert(type(source)=="string" and #source>0,"Empty module source")
        local chunk, compileError = loadstring(source,"@BASAE/Modules/" .. name .. ".lua")
        assert(chunk,compileError or "Compilation failed")
        return chunk
    end)
    if not ok then fail(name .. ": " .. tostring(result),index-1) end
    initializers[index] = result
    progress("Compiled " .. name,index)
    task.wait()
end

local Context = {Version="2.0-reset"}
for index, name in ipairs(MODULES) do
    progress("Initializing " .. name .. "...",index-1)
    local ok, initializer = pcall(initializers[index])
    if not ok then fail(name .. ": " .. tostring(initializer),index-1) end
    if type(initializer) ~= "function" then
        fail(name .. " must return an initializer function",index-1)
    end
    local initialized, initError = pcall(initializer,Context)
    if not initialized then fail(name .. ": " .. tostring(initError),index-1) end
    progress("Initialized " .. name,index)
    task.wait()
end

progress("BASAE ready!",#MODULES)
task.wait(0.35)
loading:Destroy()
