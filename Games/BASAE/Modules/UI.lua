-- The original BASAE core creates the full UI shell and reusable controls.
-- This module remains as an explicit dependency slot for future UI-only extraction.
return function(Context)
    Context.UIShellReady = ScreenGui ~= nil and Main ~= nil
end
