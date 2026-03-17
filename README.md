# wow-addons-UnitFramesLite
Lightweight addon to show unit frames

## Deployment
1. Run deploy script from addon folder:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\deploy-addon.ps1 -WoWPath "D:\Games\World of Warcraft" -GameType retail
   ```
2. Start WoW and enable `UnitFramesLite` under AddOns.

## In-game configuration
- Open the Blizzard Interface Options: AddOns → UnitFramesLite → Player/Target.
- Or use slash commands:
  - `/ufl options` → opens options panel
  - `/ufl reset` → resets settings to defaults
  - `/ufl` → command help

## Files
- `UnitFramesLite.toc`
- `UnitFramesLite.lua`
- `UnitFramesLite.xml`
- `UnitFramesLite_Options.lua`

