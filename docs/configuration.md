---
title: Configuration
sidebar_position: 6
---

# Configuration

All options are in `config.lua`, which is loaded on both client and server as a shared script. The table is registered with `Kora.config.adopt` when `kora_lib` provides it.

At load, `shared/curve.lua` validates the config and raises an error if it is invalid: `maxLevel` must be a positive integer, `skillOrder` entries must be unique ids of at most 64 characters made of letters, digits, `_` or `-`, each ordered skill needs a non-empty `label`, `icon` must be a string if set, and every key of `Config.skills` must appear in `Config.skillOrder`.

## Options

| Option | Default | Description |
| --- | --- | --- |
| `legacyMetadataKey` | `'skills'` | Character metadata key read once for the legacy import. See [Database](./database.md#legacy-metadata-import). |
| `maxLevel` | `99` | Level cap. XP is clamped to the XP needed for this level. |
| `maxAward` | `100000` | Largest XP amount a single `addRep` call may award. |
| `command` | `'skills'` | Command that opens the panel. |
| `keyMapping` | `'F4'` | Default keyboard key for the same command (`RegisterKeyMapping`, description "Open your skills"). Players can rebind it in FiveM settings. |
| `skillOrder` | eight skills | Ordered list of skill ids. Controls panel and data order. |
| `skills` | eight skills | Map of skill id to its definition. |

Default skills: `mining`, `smelting`, `fishing`, `crafting`, `cooking`, `metaldetecting`, `computing`, `hacking`.

## Skill definition

```lua
mining = {
    label = 'Mining',        -- required, shown in the UI
    icon = 'Hammer',         -- optional icon name for the panel
    skillCheck = {           -- optional minigame adjustments
        skillbar = { zoneSize = 0.14 },
        lockpick = { tolerance = 0.05 },
    },
},
```

`skillCheck` is explained in [Skill checks](./skill-checks.md). Default icons: Hammer, Flame, Activity, ShoppingBag, Star, Search, Cpu and Terminal.

## Adding or removing a skill

- **Add**: put a definition in `Config.skills` and the id in `Config.skillOrder`. Existing characters get a zero-XP row the next time their skills are loaded.
- **Remove**: delete it from both places. Its rows stay in `kora_skills_progress` but are ignored (rows for unconfigured skills are skipped when reading).

## Level curve

The XP table is built once at startup. For level `L` from 2 up to `maxLevel`, with `p = L - 1`, a running total adds `floor(p + 300 * 2^(p / 7))` and the XP required for level `L` is `floor(total / 4)`. Level 1 requires 0 XP. The level for a given XP is the highest level whose requirement is met. Changing `maxLevel` changes the table.

Each skill record exposes `name`, `label`, `icon`, `xp`, `level`, `percent`, `maxLevel`, `levelXp`, `nextLevelXp` and `xpToNextLevel`. At max level `percent` is 100 and `xpToNextLevel` is 0.
