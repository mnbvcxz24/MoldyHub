-- ORIGINAL BASAE EVENTS PAGE
return function(Context)
    local index = 3
    local name = "Events"
    local Page = CreatePage(index, name)
    local CandyCard = CreateCard(Page, "Auto collect candies", "UNDER DEVELOPMENT")
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
    
end
