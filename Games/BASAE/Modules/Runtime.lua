-- RUNTIME / FINALIZE
return function(Context)
    local function createText(parent, text, position, size, fontSize, color, bold)
        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Position = position
        label.Size = size
        label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
        label.Text = text
        label.TextColor3 = color
        label.TextSize = fontSize
        label.TextWrapped = true
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextYAlignment = Enum.TextYAlignment.Top
        label.Parent = parent
        return label
    end

    for index, name in ipairs(Context.PageOrder) do
        local page = Context.Pages[name]
        local button = Instance.new("TextButton")
        button.Name = "Tab_" .. tostring(index)
        button.Position = UDim2.fromOffset(8, 8 + (index-1)*38)
        button.Size = UDim2.new(1,-16,0,32)
        button.BackgroundColor3 = Context.Theme.Sidebar
        button.BorderSizePixel = 0
        button.Font = Enum.Font.GothamSemibold
        button.Text = name
        button.TextColor3 = Context.Theme.Text
        button.TextSize = 11
        button.Parent = Context.Sidebar
        Instance.new("UICorner", button).CornerRadius = UDim.new(0,6)
        Context.TabButtons[name] = button

        local frame = Instance.new("ScrollingFrame")
        frame.Name = "Page_" .. tostring(index)
        frame.Size = UDim2.fromScale(1,1)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.ScrollBarThickness = 3
        frame.CanvasSize = UDim2.fromOffset(0,0)
        frame.Visible = false
        frame.Parent = Context.Content
        Context.PageFrames[name] = frame

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0,9)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = frame
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0,4)
        padding.PaddingLeft = UDim.new(0,4)
        padding.PaddingRight = UDim.new(0,7)
        padding.Parent = frame

        createText(frame, page.Description, UDim2.fromOffset(4,0), UDim2.new(1,-8,0,25), 10, Context.Theme.Muted, false)
        for cardIndex, card in ipairs(page.Cards) do
            local cardFrame = Instance.new("Frame")
            cardFrame.Name = "Card_" .. tostring(cardIndex)
            cardFrame.Size = UDim2.new(1,-8,0,76)
            cardFrame.BackgroundColor3 = Context.Theme.Card
            cardFrame.BorderSizePixel = 0
            cardFrame.LayoutOrder = cardIndex
            cardFrame.Parent = frame
            Instance.new("UICorner", cardFrame).CornerRadius = UDim.new(0,8)
            createText(cardFrame, card.Title, UDim2.fromOffset(12,10), UDim2.new(1,-24,0,20), 12, Context.Theme.Text, true)
            createText(cardFrame, card.Description, UDim2.fromOffset(12,34), UDim2.new(1,-24,0,34), 10, Context.Theme.Muted, false)
        end
        frame.CanvasSize = UDim2.fromOffset(0, 38 + (#page.Cards * 85))
        button.MouseButton1Click:Connect(function() Context.ShowPage(name) end)
    end

    Context.ShowPage(Context.PageOrder[1])
    Context.Gui.Enabled = true
end
