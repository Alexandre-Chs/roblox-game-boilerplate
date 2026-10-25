---
name: roblox-skills-setup
description: Configure local Roblox skills or diagnose missing code tools, art dependencies and personal asset-provider configuration.
---

# roblox-skills-setup

Read [house integration rules](../../../docs/skills.md) first.

Run pnpm run doctor and inspect rokit.toml. Code setup is pnpm run setup. All skills are already installed in .agents/skills and visible to Claude via .claude/skills; never copy them to the home directory.

For a requested art stage, inspect its imports and LOCAL.template.md. Create a project .venv for required Python libraries, and locate Blender on this machine if needed. Run scripts/check_setup.py from this skill for an optional inventory; its MCP detection is only a hint, so verify tools in the live agent session.

Write only detected paths and environment variable names into the relevant ignored LOCAL.md. Preserve existing configuration. Request missing secrets using the private secret-entry facility, never in chat or committed files. Configure external providers only for the requested stage. Keep Kaggle disabled; verify model licences for commercial use.

Finish with a small local preview or dry run for the configured stage. List configured and unavailable stages separately; do not claim asset upload, mesh generation or MCP works without executing the corresponding check.
