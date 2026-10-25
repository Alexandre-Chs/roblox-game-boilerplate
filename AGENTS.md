# Roblox house starter

- Read `docs/architecture.md` before changing services, controllers, networking, player data or purchases. Keep the existing Lifecycle + registries, Packet, Replica and ProfileStore; this project does not use Knit.
- Local files are authoritative. Rojo owns mapped code and assets. Read `docs/assets.md` before scene, lighting, UI, mesh, texture or audio work. Use MCP for observation/playtests and explicitly tracked imports, never to patch mapped scripts.
- Discover project skills in `.agents/skills`; Claude reads the same files through `.claude/skills`. Read `docs/skills.md` before executing imported tools. Load only skills relevant to the task.
- Use strict Luau for house code. Services own authoritative rules; controllers own presentation. Validate client requests and rate-limit them on the server. Keep private data in server modules.
- Follow existing naming and registration patterns. Reuse Trove for cleanup. Put pure rules in modules that can be tested without Studio.
- Use the `pnpm run` commands, never bare `rojo`/`wally`/`stylua` from the shell: the pinned toolchain lives in `~/.rokit/bin` and a Homebrew `rojo` of another version may shadow it. Development happens on macOS; CI runs on Linux.
- Run `pnpm check` for code changes, and an MCP playtest for engine-dependent behavior. Report checks actually run and remaining runtime gaps. A Rojo build is not a syntax/type or gameplay test.
- Never edit generated Packages, ServerPackages, sourcemap or vendored dependencies casually. Update their pinned source intentionally, preserve licences and rerun checks.
- Save progress with Git. Keep secrets, LOCAL.md, generated work and machine paths out of commits. One agent writes to a Studio instance at a time; parallel agents produce files in disjoint areas.
- Use a separate test universe for persistent-data and purchase validation (docs/release.md). Run `pnpm run publish` or paid asset generation only on explicit user authorization for that target.
- Copy the example feature (Coin + Hud, docs/architecture.md) when adding a feature; remove it when the game does not need it.
- PR titles/descriptions are English. User-facing replies are concise and follow the user's language.
