---
name: create-roblox-game
description: Start a Roblox game or plan and implement a complete gameplay loop using the current local house starter.
---

# create-roblox-game

Read [house integration rules](../../../docs/skills.md) first.

1. Read AGENTS.md, docs/architecture.md and docs/assets.md. Run pnpm run doctor; if dependencies are missing, use pnpm run setup. Work in the current checkout; creating a new repository is a separate user request.
2. Capture the requested concept, core loop, target devices, visual references and acceptance criteria in docs/game-design.md. For vague requests choose a small playable vertical slice and state assumptions. Avoid implementing speculative systems.
3. Use roblox-code for gameplay, roblox-map for layout, roblox-ui for interfaces, roblox-3d-model/roblox-texture-gen for art, roblox-animation, roblox-vfx and roblox-sfx when needed. Load each skill only for its stage. Skills must retain the house architecture.
4. Produce sources locally and document assets/catalog.json. Verify each stage before integrating. Use one Studio writer. Delegation is optional and must be authorized; use roblox-build-orchestrator when parallel work is requested.
5. Run pnpm run check; playtest the exact Studio window via the available MCP. Inspect logs, reset/death, core progression and screenshots. Use multiplayer/device tests when relevant. Stop Play after tests.
6. Report files, playable behavior, actual checks, unresolved issues and asset/save limitations. Publishing and paid generation are outside automatic build scope.

Upstream reference plans under references/ may inspire design, but their scaffold, path and networking assumptions do not apply to this template.
