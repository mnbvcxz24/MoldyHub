-- BASAE V2 UI SHELL
return function(Context)
    local gui = Instance.new("ScreenGui")
    gui.Name = "MoldyHub_BASAE_UI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999999
    gui.Enabled = false
    gui.Parent = Context.Services.CoreGui
    Context.Gui = gui

    local window = Instance.new("Frame")
    window.Name = "Main"
    window.AnchorPoint = Vector2.new(0.5,0.5)
    window.Position = UDim2.fromScale(0.5,0.5)
    window.Size = UDim2.fromOffset(620,410)
    window.BackgroundColor3 = Context.Theme.Background
    window.BorderSizePixel = 0
    window.Parent = gui
    Instance.new("UICorner", window).CornerRadius = UDim.new(0,10)
    Context.Main = window

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(18,10)
    title.Size = UDim2.new(1,-36,0,30)
    title.Font = Enum.Font.GothamBold
    title.Text = "MoldyHub  |  BASAE"
    title.TextColor3 = Context.Theme.Accent
    title.TextSize = 17
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = window

    local sidebar = Instance.new("Frame")
    sidebar.Position = UDim2.fromOffset(12,52)
    sidebar.Size = UDim2.fromOffset(142,346)
    sidebar.BackgroundColor3 = Context.Theme.Sidebar
    sidebar.BorderSizePixel = 0
    sidebar.Parent = window
    Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0,8)
    Context.Sidebar = sidebar

    local content = Instance.new("Frame")
    content.Position = UDim2.fromOffset(164,52)
    content.Size = UDim2.new(1,-176,1,-64)
    content.BackgroundTransparency = 1
    content.Parent = window
    Context.Content = content

    Context.TabButtons = {}
    Context.PageFrames = {}
    Context.ShowPage = function(name)
        for pageName, frame in pairs(Context.PageFrames) do
            frame.Visible = pageName == name
        end
        for pageName, button in pairs(Context.TabButtons) do
            button.BackgroundColor3 = pageName == name and Context.Theme.Accent or Context.Theme.Sidebar
            button.TextColor3 = pageName == name and Color3.fromRGB(35,21,3) or Context.Theme.Text
        end
    end
end
