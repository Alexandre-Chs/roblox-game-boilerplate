---
name: roblox-code
description: Implement or review Luau gameplay, services, controllers, networking and data in this house starter.
---

# roblox-code

Read [house integration rules](../../../docs/skills.md) first.

Read docs/architecture.md and the callers of the modules being changed. Keep Lifecycle, explicit registries, Packet, Replica and ProfileStore. Implement in src, registering services/controllers explicitly. Screens use local models in assets/ui and UIController behavior. Prefer pure modules for rules and add assertions in tests/run.luau for meaningful edge cases.

Run pnpm run check, then use MCP for engine-dependent verification. Never substitute rojo build for type checking or gameplay tests. The original Knit scaffolder is disabled; pnpm run setup prepares this template.

For validation and known upstream failure patterns, consult references/traps.md selectively, translating any Knit examples into the house architecture.
