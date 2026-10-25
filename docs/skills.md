# Local skill integration

The canonical pack is `.agents/skills`; `.claude/skills` is a relative symlink to it. The seven Claude worker definitions live in `.claude/agents`. Codex reads the skills, but does not automatically execute Claude agent definitions. T3 delegation uses its live provider catalog and explicitly assigned tasks.

## Precedence and architecture

User request → AGENTS.md → docs/architecture.md → this document → imported skill recipes.

This fork uses the starter's Lifecycle and registries, Packet for actions, Replica for state, and ProfileStore for data. Translate upstream Knit, Net, Core and controller examples to these existing modules. Our `roblox-code`, `create-roblox-game`, setup and orchestration entrypoints replace the incompatible upstream defaults. Historical recipes under `references/upstream.md` are reference material, not commands to execute blindly.

- Work from the repository root. `.agents/skills/<name>` always means this checkout, not the user's home directory.
- Start/check code using `pnpm run setup`, `pnpm run dev`, `pnpm run check`. The imported Knit project generators are deliberately disabled. Start another game with a new copy of this template.
- Only one process writes to a Studio instance. Asset workers produce files and manifests; the parent does integration. Discover the actual MCP tool names in the session instead of assuming a specific plugin prefix.
- Use the user's selected model. Imported role descriptions do not authorize model changes, spending or publication.
- `LOCAL.md` is optional machine-specific configuration, ignored by Git. Record paths and environment variable names only; never secret values. Preserve existing personal configuration.

## Art prerequisites

Code setup does not install Blender, Python art libraries or external generation services. Run `pnpm run doctor`, then the setup skill for the chosen art stage. Use `pnpm run setup:art` for the tested local preview dependencies in `.venv`. Determine required packages from the chosen script before installing; Blender scripts use Blender's Python.

Blender 4.x is used by upstream mesh/animation workflows. Hugging Face, Cloudflare and Roblox Open Cloud are optional providers, not mandatory accounts. Prefer connected image/mesh tools when they meet the request. Check current availability, quotas and commercial licences before calling external services. Kaggle generation remains disabled as upstream requires.

The import includes author-specific scripts written on Windows. `place_state.py` and `preflight.py` work on macOS; `recover_mcp.py` and `capture_frames.ps1` target the Windows third-party MCP server and exit or do not apply here. Use the connected official Studio MCP rather than launching duplicate servers or killing Studio. A missing provider is a reported limitation, not grounds to invent an asset ID or claim success.

## Completion

Each produced asset needs a reproducible local source or explicit Studio export, provenance and licence, output location, and measured runtime verification. See docs/assets.md. Never report a local PNG preview or geometric reachability calculation as proof of the final rendered game.
