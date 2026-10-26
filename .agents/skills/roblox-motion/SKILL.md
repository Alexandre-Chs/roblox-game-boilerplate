---
name: roblox-motion
description: "Animate generated or imported models in code, with no animation asset: chest lids, doors, wings, tails, swaying props, creatures. Covers splitting a model into moving parts, joining them into a rig and driving the joints. Use for any 'make it move/open/flap' request on a model."
---

Read [house integration rules](../../../docs/skills.md) first. Keyframed character animation (emotes, attacks made in Blender) is `roblox-animation`; this skill is code-driven motion.

# Motion in code

No animation file, no upload, no permissions: the client rotates `Motor6D` joints every frame from attributes. Three pieces ship in the starter:

| Piece | File | Job |
| --- | --- | --- |
| Rig | `src/shared/Utils/Rig.luau`, server `Components/Rig.luau` (tag `Rig`) | Joins every part to the root with a `Motor6D` named after the part. An `Attachment` named `Pivot` in a part is that joint's pivot and axes |
| Motion | `src/shared/Utils/Motion.luau` (pure: `Wave`, `Spring`, `Stride`), client `Components/Motion.luau` (tag `Rig`) | Sets `Motor6D.Transform` each frame from part attributes |
| Openable | server `Components/Openable.luau` (tag `Openable`) | Prompt that sets the model attribute `Open` for everyone; example `assets/world/Chest.model.json` |

Part attributes read by `Components/Motion.luau` (degrees):

- `OpenAngle`: springs there while the model's `Open` is true (lid, door, gate, drawbridge).
- `Wave`, `WaveSpeed` (cycles/s), `WavePhase` (0-1): endless swing (wings 30-45 deg at 1.5-2/s, tail 10-15 deg at 0.5/s, opposite wings `WavePhase` 0 and 0.5 only if they mirror axes, otherwise equal).
- `Axis`: `X` (default), `Y` or `Z` of the pivot.

## Recipe: from prompt to moving model

1. **Generate in parts.** `mcp__Roblox_Studio__generate_mesh` with `segmentation: "explicit"` and `partNames` listing every piece that moves separately (`["base","lid"]`, `["body","head","left wing","right wing","tail"]`, max 8). Set `size` in studs and `maxTriangles` (20000 max per mesh). For an existing single mesh use `segment_mesh` (max 5 parts). The result lands in Workspace tagged `Assistant-<id>`, parts nested in sub-models with JSON-ish names (`["base"_geom`): flatten them into one Model and rename (`Base`, `Lid`).
2. **Pivots.** Add `Attachment` `Pivot` inside each moving part at the joint: back-top edge of a lid, shoulder of a wing, base of a tail. Its X axis is the hinge axis; a positive angle lifts the part's -Z side (the front, if the model faces -Z).
3. **Prompt point.** For `Openable`, add `Attachment` `PromptPoint` in the root just outside the front. A prompt at the root centre is hidden by the moving part (line of sight), which is why the component turns line of sight off when there is no `PromptPoint`.
4. **Ship it as files.** Copy the `Chest.model.json` shape into `assets/world/` with the MeshId/TextureID of each part, tags, attributes (lowercase `"attributes"` key) and attachments. Read the ids in Studio (`part.MeshId`, `part.TextureID`); never keep a Studio-only copy.
5. **Verify in Play.** Teleport the character next to it, trigger with `prompt:InputHoldBegin()`/`InputHoldEnd()` from the Client datamodel (synthetic key presses often miss), read the moving part's position on the Server after ~1 s, and capture a frame. Delete generation leftovers in Workspace.

## Rules

- The server owns state (`Open`, a creature's mode); clients animate it. `Transform` never replicates, so never set it on the server.
- Unique part names per model: joints are named after parts.
- Root stays anchored (set model attribute `Anchored = false` for physics-driven models). Moving parts become massless and unanchored, so they never fall apart.
- Walking creatures: advance a gait phase with `Motion.Stride(phase, distanceMoved, strideLength)` from the root's actual movement, and derive leg angles from the phase, so feet never slide at any speed. Add an attribute-driven branch in `Components/Motion.luau` when a game needs it; do not ship it speculatively.
- Respect taste: no bounce/overshoot by default (the spring is critically damped).
