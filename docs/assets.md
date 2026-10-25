# Assets and visual ownership

## Local source of truth

- `assets/ui`: ScreenGui models (`.model.json`, `.rbxmx`, `.rbxm`), synced to StarterGui. Runtime behavior stays in UIController screens.
- `assets/world`: locally authored models synced beneath Workspace.StarterMap. Keep unrelated Studio-authored content outside this owned folder.
- `default.project.json`: Lighting properties and scene mappings. Add Atmosphere/post-processing instances here or as local models when needed.
- `assets/source`: original images, model/Blender files and authored specifications. Rojo does not upload PNG/FBX/GLB files automatically.
- `assets/catalog.json`: entries with name, kind, source path/URL, licence, creator, Roblox asset ID (null until uploaded) and intended use. Never put API keys here.
- `work/`: ignored previews, generated intermediate files and run logs. Move approved reusable sources into assets before completion.

Import/generate assets using connected tools or the selected art skill. Inspect third-party model scripts before integrating. Record tool/model provenance and commercial usage rights. Test scale, pivot, orientation, collisions and mobile performance in Studio. UI needs desktop and narrow mobile screenshots, readable text and usable touch targets.

## Illustrated UI kits

Every screen (Shop, Hud and its dock, Settings, DailyReward, Notifications, the loading screen) uses the image kit in `assets/source/ui/shop/`; `assets/source/ui/promo/` adds discount tags, POPULAR / BEST VALUE / LIMITED banners, VIP and premium badges and premium icons. `assets/source/ui/social/` holds the inventory, rewards, tutorial and leaderboard art (group, invite, heart, trophy, medals, input field, hint banner, board). Open each kit's `contact_sheet.png` to pick art. To make or extend a kit:

1. Generate the images with an image model (the shop kit was produced by a delegated Codex agent): PNG with real alpha, no text baked in (prices, timers and labels stay TextLabels), exact sizes, stretchable pieces designed for 9-slice. Keep `manifest.json` (size, purpose, `sliceCenter`, generator) and a `contact_sheet.png` next to them.
2. Upload with the Studio MCP: serve the folder over `http://localhost` (for example `python3 -m http.server`) and call `upload_image` with the URLs. Save the returned ids in `roblox-ids.json`. New ids can report `AssetFetchStatus.Failure` in Edit for a few minutes while moderation runs; check them in Play.
3. Edit layout in `build_ui.py` and run `.venv/bin/python assets/source/ui/shop/build_ui.py`. It reads every kit's ids and writes `assets/ui/*.model.json`, `src/shared/Config/UiImages.luau` and `src/first/LoadingImages.luau`; never hand-edit those outputs.
4. Add each image to `assets/catalog.json` with its source, licence and Roblox id. `pnpm run check` fails if a UI model or config uses an image id that no kit records.

Layout rules learned in Studio: in `.model.json` files Rojo only reads lowercase `"attributes"` (a capitalised key is dropped silently; a test guards it); give panels fixed pixel sizes plus a `DeviceScale` UIScale instead of scale sizes with `UISizeConstraint`; banner art with ornate ends keeps its ratio (`ScaleType = Fit`), it is never 9-sliced; 9-slice pieces need `ScaleType = Slice` with the manifest's `SliceCenter` and a `SliceScale` around 0.5 for 256-px art; a square icon inside a wide button uses `SizeConstraint = RelativeYY` with X and Y scale set; card templates are image elements, so screens look them up as `GuiObject`, not `Frame`.

## Studio boundary

MCP can inspect, capture, playtest, import or temporarily adjust an object. Commit the final properties/models back into mapped files so the next Rojo build reproduces them. Stop play mode before editing the authoring scene. Never edit another open Studio project accidentally: identify the target window/place first.

Rojo cannot live-sync every property (notably some mesh/terrain/CSG data). For such content, export compatible models or explicitly save a separate authored place outside `build/` and document how to assemble it. `pnpm run build` recreates only file-backed content; it does not capture unsaved Studio changes. Export before rebuilding, not afterward.

This template deliberately ignores unknown service children to preserve authored content. It does not magically version them. A release is incomplete until every required asset is accounted for in files or the documented authored place.
