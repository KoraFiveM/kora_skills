---
title: "Installation"
sidebar_position: 2
---


# Installation

Kora Skills is a config-driven, server-authoritative XP system: eight skills (mining, smelting, fishing, crafting, cooking, metal detecting, computing, hacking) each levelled 1–99 on a RuneScape-style cumulative curve, shown in a kora_lib AppShell progression panel, and optionally used to make a resource's own skill-check minigame easier at higher levels.

## Install Kora Skills

1. **Add the folder** — Place `kora_skills` in your resources directory (on the Kora recipe it is `resources/[kora]/kora_skills`).

2. **Have the dependencies running** — The manifest declares `dependency 'kora_lib'`, `dependency 'kora_theme'`, `dependency 'kora_core'` and `dependency 'kora_sql'`. The progression panel is drawn by kora_lib's AppShell, player identity and the `PlayerData.skills` field come from kora_core, and all progress is stored through `Kora.sql`.

3. **Start it after its dependencies** — Any resource that calls `exports.kora_skills:addRep` (or the other exports) should start after kora_skills.

   ```bash title="server.cfg"
   ensure kora_lib
   ensure kora_theme
   ensure kora_sql
   ensure kora_core
   ensure kora_skills
   ```

4. **Tables are created automatically** — `server/database.lua` waits for `Kora.sql.ready()` then calls `Kora.sql.ensureTables(KoraSkillsSchema)`, which creates `kora_skills_profiles` and `kora_skills_progress` if they do not exist. There is no SQL file to run by hand.

5. **Review config.lua** — The skill list, labels, icons and skill-check modifiers all live in `Config.skills` / `Config.skillOrder`. See Configuration below.

## Manifest reference

```lua title="fxmanifest.lua"
dependency 'kora_lib'
dependency 'kora_theme'
dependency 'kora_core'
dependency 'kora_sql'

shared_script '@kora_lib/init.lua'
shared_scripts { 'config.lua', 'shared/curve.lua' }

server_scripts { '@kora_sql/init.lua', 'server/schema.lua', 'server/database.lua', 'server/main.lua' }
client_script 'client/main.lua'
```

- `shared/curve.lua` builds the XP table once per Lua realm (client and server each build their own copy) from `Config.maxLevel` and asserts the shape of `Config.skills`/`Config.skillOrder` at load time — a malformed config stops the resource from starting rather than levelling silently wrong.
- This resource's own export names are unprefixed (`getRep`, `addRep`, ...), available as `exports.kora_skills:*`.

## Migrating from md_skills / legacy metadata

If a player already has skill XP stored as kora_core character metadata under the key `Config.legacyMetadataKey` (default `'skills'`), it is imported automatically and only once.

- The first time a character's skills are loaded, `KoraSkillsDatabase.load` checks for a `kora_skills_profiles` row by citizen ID. If there is none, it imports the legacy metadata blob (via `KoraSkills.normalise`) into `kora_skills_progress` inside one transaction, then creates the profile row as a one-way marker.
- After that import, the metadata key is cleared with `exports.kora_core:setMetaData(source, Config.legacyMetadataKey, nil)` — so a later external write to that metadata key is never re-imported or mistaken for authoritative progress.
- A character with no profile row and no legacy metadata simply starts every configured skill at 0 XP (rows are still inserted so later reads are O(1)).

## Requirements

All declared in `fxmanifest.lua` with `dependency`:

| Resource | Used for |
| --- | --- |
| `kora_lib` | `Kora.sql`, `Kora.callback`, `Kora.nui`, `Kora.notify`, `Kora.distance`, `Kora.config` |
| `kora_core` | Player lookup, `PlayerData.skills` field registration, player data change hooks, metadata |
| `kora_sql` | Table creation and queries (its `init.lua` is loaded server-side) |
| `kora_theme` | Declared as a dependency; no direct call to it appears in this resource's Lua |

## Testing

- `bash test/run.sh` runs the offline Lua smoke tests in `test/smoke/` (curve, database, server). It uses `lua` or the interpreter in the `LUA` environment variable and does not start FiveM.
- `tests/checklist-character-and-ui.feature` holds manual QA scenarios for `kora_qa` (registered with `qa_feature` in `fxmanifest.lua`).

## Related pages

See [Configuration](./configuration.md) for every `Config` option and [Database](./database.md) for the tables and the legacy import.
