-- MoldyHub BASAE modular loader
-- Experimental first-pass split. Module boundaries follow the original source sections;
-- shared local variables are not yet refactored into a common context.
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

for _, moduleName in ipairs(MODULES) do
    local url = BASE_URL .. moduleName .. ".lua"
    local ok, source = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok or type(source) ~= "string" or source == "" then
        error("[BASAE] Failed to fetch module " .. moduleName .. ": " .. tostring(source))
    end

    local chunk, compileError = loadstring(source, "@BASAE/Modules/" .. moduleName .. ".lua")
    if not chunk then
        error("[BASAE] Compile error in " .. moduleName .. ": " .. tostring(compileError))
    end

    local ran, runtimeError = pcall(chunk)
    if not ran then
        error("[BASAE] Runtime error in " .. moduleName .. ": " .. tostring(runtimeError))
    end
end
