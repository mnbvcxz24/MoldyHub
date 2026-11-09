    elseif index == 5 then
        local ThemeCard = CreateCard(Page, "Theme Settings", "Choose a color palette for the interface.")
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
