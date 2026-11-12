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
- **Server exports** - read skills, award XP (with optional proximity check) and test levels. See [Public exports](./api/exports.md).
- **Skill-aware minigames** - higher levels can make matching `kora_lib` skill checks easier. See [Skill checks](./skill-checks.md).
- **Progression panel** - overview graph and searchable details table, plus a level-up notification. See [Progression panel](./ui.md) and [Commands](./commands.md).
- **One-time legacy import** - old `metadata.skills` values are imported into SQL once and the metadata key is removed. See [Database](./database.md#legacy-metadata-import).

See [Installation](./installation.md) for requirements, the `ensure` order, manifest and testing.

## Documentation map

- [Installation](./installation.md) - install steps, requirements, manifest, md_skills migration, testing
- [How to use](./how-to-use.md) - XP curve, awarding XP, skill-check easing, the panel
- [Commands](./commands.md) - `/skills`, `/skillList` and the key binding
- [API reference](./api/index.md) - overview of the export modules
- [Public exports](./api/exports.md) - every server and client export with parameters, returns and examples
- [Configuration](./configuration.md) - every `Config` option and the level curve
- [Events](./events.md) - events and the callback used by the resource
- [Skill checks](./skill-checks.md) - how skill levels adjust minigame difficulty
- [Database](./database.md) - tables, columns and the legacy import
- [Progression panel](./ui.md) - the AppShell panel and level-up notification
- [Troubleshooting](./troubleshooting.md) - common problems and caveats
