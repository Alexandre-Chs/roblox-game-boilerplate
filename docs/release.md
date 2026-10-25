# Environments and release

| Environment | Where | Data |
| --- | --- | --- |
| dev | `build/starter.rbxlx` opened in Studio, unpublished | Mock DataStore, reset on every Play |
| test | A separate Roblox experience you own | Real DataStores, safe to wipe |
| prod | The public experience | Real players. Never test persistence or purchases here |

Create the test and prod experiences by hand on the Creator Dashboard (the API cannot create them). Put their ids in `places.json`. Ids are not secrets.

## Publishing

```sh
export ROBLOX_API_KEY=...   # Open Cloud key: universe-places, Write, on both experiences
pnpm run publish test
pnpm run publish prod --confirm-prod
```

The command builds, then uploads `build/starter.rbxlx` as a new published version through Open Cloud. It refuses to run without ids, a key or, for prod, `--confirm-prod`. Agents run it only when the user explicitly asks for that environment in the current conversation. A build contains only file-backed content; see docs/assets.md before publishing.

Enable Studio access to API services on the test experience to test saving from Studio. Studio sessions use a separate DataStore (`PlayerData_Studio`, see `DataService`), so data saved from Studio never appears on live servers and the reverse; validate live persistence on the published test experience. Products and game passes have different ids per experience; set the ids for the experience you publish to in `src/shared/Config/Monetization.luau` before each publish.

## After release

- Script errors from live servers and clients appear automatically in the Creator Dashboard error report. `ErrorReportService` adds grouped `ScriptError` custom events on top (docs/features.md); do not add a third pipeline.
- Built-in analytics (players, sessions, retention, Robux revenue, devices) need no code: Creator Dashboard > your experience > Analytics.
- Custom analytics come from `TelemetryService` (docs/architecture.md, Analytics): the onboarding funnel, the Shop funnel, the coin economy and custom events, under Analytics > Funnels, Economy and Custom events. They need real players on the published experience; there is a processing delay, so check the next day rather than live.
