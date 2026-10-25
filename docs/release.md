# Environments and release

| Environment | Where | Data |
| --- | --- | --- |
| dev | `build/game.rbxlx` opened in Studio, unpublished | Mock DataStore, reset on every Play |
| test | A separate Roblox experience you own | Real DataStores, safe to wipe |
| prod | The public experience | Real players. Never test persistence or purchases here |

Create the test and prod experiences by hand on the Creator Dashboard (the API cannot create them). Put their ids in `places.json`. Ids are not secrets.

## Publishing

```sh
export ROBLOX_API_KEY=...   # Open Cloud key: universe-places, Write, on both experiences
pnpm run publish test
pnpm run publish prod --confirm-prod
```

The command builds, then uploads `build/game.rbxlx` as a new published version through Open Cloud. It refuses to run without ids, a key or, for prod, `--confirm-prod`. Agents run it only when the user explicitly asks for that environment in the current conversation. A build contains only file-backed content; see docs/assets.md before publishing.

Enable Studio access to API services on the test experience to test saving from Studio. Products and game passes have different ids per experience; map them in `Products.luau` deliberately.

## After release

- Script errors from live servers and clients appear automatically in the Creator Dashboard error report. Do not add a custom error pipeline.
- Use `AnalyticsService` (funnels, economy, custom events) from services when a game needs retention or economy data. Add it per game, server side.
