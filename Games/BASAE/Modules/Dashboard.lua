-- DASHBOARD PAGE
return function(Context)
    Context.RegisterPage("Main", "Overview and status")
    Context.AddCard("Main", "BASAE Modular Build", "The new modular foundation is running. Feature migration will be added page by page.")
    Context.AddCard("Main", "Loading", "Modules are initialized through a shared Context. The original BASAE.lua reference remains untouched.")
end
