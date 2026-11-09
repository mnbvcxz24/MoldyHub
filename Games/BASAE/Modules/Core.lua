-- BASAE V2 CORE
-- Shared state is passed explicitly to every module through Context.
return function(Context)
    Context.Services = {
        Players = game:GetService("Players"),
        TweenService = game:GetService("TweenService"),
        UserInputService = game:GetService("UserInputService"),
        RunService = game:GetService("RunService"),
        HttpService = game:GetService("HttpService"),
        CoreGui = game:GetService("CoreGui")
    }
    Context.Player = Context.Services.Players.LocalPlayer
    Context.Theme = {
        Background = Color3.fromRGB(5,5,7),
        Sidebar = Color3.fromRGB(10,10,12),
        Card = Color3.fromRGB(17,17,19),
        Border = Color3.fromRGB(48,39,25),
        Text = Color3.fromRGB(250,247,239),
        Muted = Color3.fromRGB(153,146,132),
        Accent = Color3.fromRGB(255,181,55)
    }
    Context.Pages = {}
    Context.PageOrder = {}
    Context.RegisterPage = function(name, description)
        local page = {Name=name, Description=description or "", Cards={}}
        Context.Pages[name] = page
        table.insert(Context.PageOrder, name)
        return page
    end
    Context.AddCard = function(pageName, title, description)
        local page = Context.Pages[pageName]
        assert(page, "Unknown page: " .. tostring(pageName))
        local card = {Title=title, Description=description or ""}
        table.insert(page.Cards, card)
        return card
    end
end
