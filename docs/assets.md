# Assets and visual ownership

## Local source of truth

- `assets/ui`: ScreenGui models (`.model.json`, `.rbxmx`, `.rbxm`), synced to StarterGui. Runtime behavior stays in UIController screens.
- `assets/world`: locally authored models synced beneath Workspace.StarterMap. Keep unrelated Studio-authored content outside this owned folder.
- `default.project.json`: Lighting properties and scene mappings. Add Atmosphere/post-processing instances here or as local models when needed.
- `assets/source`: original images, model/Blender files and authored specifications. Rojo does not upload PNG/FBX/GLB files automatically.
- `assets/catalog.json`: entries with name, kind, source path/URL, licence, creator, Roblox asset ID (null until uploaded) and intended use. Never put API keys here.
- `work/`: ignored previews, generated intermediate files and run logs. Move approved reusable sources into assets before completion.

Import/generate assets using connected tools or the selected art skill. Inspect third-party model scripts before integrating. Record tool/model provenance and commercial usage rights. Test scale, pivot, orientation, collisions and mobile performance in Studio. UI needs desktop and narrow mobile screenshots, readable text and usable touch targets.

## Studio boundary

MCP can inspect, capture, playtest, import or temporarily adjust an object. Commit the final properties/models back into mapped files so the next Rojo build reproduces them. Stop play mode before editing the authoring scene. Never edit another open Studio project accidentally: identify the target window/place first.

Rojo cannot live-sync every property (notably some mesh/terrain/CSG data). For such content, export compatible models or explicitly save a separate authored place outside `build/` and document how to assemble it. `pnpm run build` recreates only file-backed content; it does not capture unsaved Studio changes. Export before rebuilding, not afterward.

This template deliberately ignores unknown service children to preserve authored content. It does not magically version them. A release is incomplete until every required asset is accounted for in files or the documented authored place.
