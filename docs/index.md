---
title: kora_skills
sidebar_position: 1
---

# kora_skills

`kora_skills` is a config-driven XP skill system for Kora servers. Each character has an XP value per configured skill (mining, fishing and so on) stored in SQL, a RuneScape-style level curve turns XP into a level and percentage, and other resources award XP or check levels through exports. Players view their progress in a `kora_lib` AppShell panel opened with `/skills`. It is based on `md_skills` and keeps a similar export surface plus a `/skillList` command.

Current version: see `version` in `fxmanifest.lua`.

## Features

- **Configurable skills** - skill ids, order, labels, icons and the level cap come from `config.lua`. See [Configuration](./configuration.md).
- **Authoritative SQL storage** - XP lives in `kora_skills_progress`. `PlayerData.skills` is a replicated read model for UI only. See [Database](./database.md).
- **Level curve** - cumulative XP per level follows the curve described in [Configuration](./configuration.md#level-curve).
- **Server exports** - read skills, award XP (with optional proximity check) and test levels. See [Exports](./exports.md).
- **Skill-aware minigames** - higher levels can make matching `kora_lib` skill checks easier. See [Skill checks](./skill-checks.md).
- **Progression panel** - overview graph and searchable details table, plus a level-up notification. See [UI and commands](./ui.md).
- **One-time legacy import** - old `metadata.skills` values are imported into SQL once and the metadata key is removed. See [Database](./database.md#legacy-metadata-import).

## Requirements

All declared in `fxmanifest.lua` with `dependency`:

| Resource | Used for |
| --- | --- |
| `kora_lib` | `Kora.sql`, `Kora.callback`, `Kora.nui`, `Kora.notify`, `Kora.distance`, `Kora.config` |
| `kora_core` | Player lookup, `PlayerData.skills` field registration, player data change hooks, metadata |
| `kora_sql` | Table creation and queries (its `init.lua` is loaded server-side) |
| `kora_theme` | Declared as a dependency; no direct call to it appears in this resource's Lua |

## Installation

1. Place the resource in your resources folder.
2. Ensure it after its dependencies:

   ```cfg
   ensure kora_lib
   ensure kora_theme
   ensure kora_sql
   ensure kora_core
   ensure kora_skills
   ```

3. No SQL import is needed. The tables are created automatically once `kora_sql` is ready. See [Database](./database.md).
4. Adjust [Configuration](./configuration.md) if you want different skills.

Other resources that call the exports (for example fishing or mining resources) should be ensured after `kora_skills`.

## Testing

- `bash test/run.sh` runs the offline Lua smoke tests in `test/smoke/` (curve, database, server). It uses `lua` or the interpreter in the `LUA` environment variable and does not start FiveM.
- `tests/checklist-character-and-ui.feature` holds manual QA scenarios for `kora_qa` (registered with `qa_feature` in `fxmanifest.lua`).

## Pages

- [Configuration](./configuration.md) - every `Config` option and the level curve
- [Exports](./exports.md) - server and client exports
- [Events](./events.md) - events and the callback used by the resource
- [Skill checks](./skill-checks.md) - how skill levels adjust minigame difficulty
- [UI and commands](./ui.md) - commands, key mapping and the progression panel
- [Database](./database.md) - tables, columns and the legacy import
- [Troubleshooting](./troubleshooting.md) - common problems and caveats
