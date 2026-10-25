---
name: roblox-build-orchestrator
description: Coordinate an explicitly requested parallel Roblox build or multi-agent asset pipeline within the house starter.
---

# roblox-build-orchestrator

Read [house integration rules](../../../docs/skills.md) first.

Read docs/skills.md and docs/architecture.md. Use the existing T3 orchestration capabilities when running in T3; inspect the live provider catalog and honor requested model/options. Claude role definitions are in .claude/agents; Codex can read those briefs but they are not native Codex agent configuration.

Give each worker a bounded objective, exact output paths, permitted tools, acceptance checks and unresolved dependencies. Allocate disjoint file paths. Asset workers produce files and manifests, not live Studio writes. The parent is the only Studio integrator and preserves the starter architecture.

Validate outputs before integration: licence/provenance, scale, source reproducibility and required local checks. Integrate in small batches, run pnpm run check and Studio playtests. Capture remaining work explicitly; do not convert a missing provider or failed check into fabricated success.

For long runs, scripts/run_log.py can record stages and interventions; inspect --help before use. Upstream references/stage-briefs.md and references/write-boundary.md provide briefing patterns, subject to the local rules. Publication and paid generation are separately authorized actions.
