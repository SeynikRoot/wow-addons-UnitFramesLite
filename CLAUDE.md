# UnitFramesLite — Claude Code Context

## Project
World of Warcraft **Retail** addon (Patch 12.0.0+). Lightweight unit frames showing player/target health, power, and buffs.

- Addon files: `UnitFramesLite.lua`, `UnitFramesLite_Options.lua`, `UnitFramesLite.xml`, `UnitFramesLite.toc`
- Deploy: `deploy-addon.ps1` copies files to the WoW addons directory
- Slash commands: `/ufl options`, `/ufl reset`, `/ufl`

## Shared WoW Addon Resources
All WoW API knowledge, coding standards, and agent instructions live in the shared repo:

- **Agent**: `c:/Repos/wow-addon-agents-shared/.github/agents/wow-addon.agent.md`
- **Skills**: `c:/Repos/wow-addon-agents-shared/.github/skills/`

**Always read the agent file before working on WoW API tasks.** It defines coding standards, anti-patterns to avoid, and how to use the skill system.

## Finding WoW API Information
1. Read `wow-api-index` skill (`c:/Repos/wow-addon-agents-shared/.github/skills/wow-api-index/SKILL.md`) to locate the right domain skill
2. Read the domain skill for function signatures and usage examples
3. Fall back to `https://warcraft.wiki.gg/wiki/API_<FunctionName>` if no skill covers it

## Key Conventions (from wow-addon agent)
- Use `local addonName, ns = ...` for namespacing — no global pollution
- Event-driven architecture only — avoid `OnUpdate` polling
- Check `InCombatLockdown()` before modifying protected frames
- Cache frequently used globals locally (`local UnitHealth = UnitHealth`)
- Validate API existence before calling: `if C_Namespace and C_Namespace.Fn then`
- Use `RegisterUnitEvent` instead of `RegisterEvent` when filtering by unit
