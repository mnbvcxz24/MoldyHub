# BASAE modules

This directory contains the executable modules loaded by `../main.lua`.

Planned module filenames (loaded in dependency order):

- `Core.lua` — services, shared state, configuration, and common helpers
- `UI.lua` — shared UI construction and reusable widgets
- `Dashboard.lua` — dashboard page
- `Farm.lua` — farming systems
- `Combat.lua` — combat systems
- `Settings.lua` — settings and configuration controls
- `Theme.lua` — theme controls
- `Events.lua` — event page
- `Misc.lua` — miscellaneous features
- `Runtime.lua` — startup, connections, and runtime behavior

Each module will be a separate Lua chunk and will receive the shared context from `main.lua`. These are planned names; modules will be created only after their code and dependencies are separated correctly.

The original `../BASAE.lua` remains the untouched reference. Temporary line-split fragments are kept separately in `../source_parts/` and are not runtime modules.
