---
title: Exports
sidebar_position: 3
---

# Exports

## Server

All progression writes are server-only. Return values are `value` on success or `nil, error` (reads) / `false, error` (writes) on failure.

| Export | Description |
| --- | --- |
| `getRep(source, skill?)` | One skill record, or all skills keyed by id when `skill` is `nil`. Unknown skill returns `nil, 'unknown skill'`. |
| `getAllRep(source)` | All skill records keyed by skill id. |
| `addRep(source, skill, amount, location?, distance?)` | Adds XP. Returns `true` or `false, error`. |
| `isLevel(source, skill, level)` | `true` if the skill level is at least `level` (a whole number of 1 or more); otherwise `false`. |
| `getSkillCheckOptions(source, skill, gameType, options?)` | Returns adjusted minigame options and the skill record. See [Skill checks](./skill-checks.md). |
| `GetSkillsData()` | Map of skill id to label. Registered by `config.lua`, so it exists on both server and client. |

```lua
local skills = exports.kora_skills:getAllRep(source)
local mining = exports.kora_skills:getRep(source, 'mining')
local ok, err = exports.kora_skills:addRep(source, 'mining', 25, mineCoords, 4.0)
local can = exports.kora_skills:isLevel(source, 'mining', 20)
```

### addRep rules

- `skill` must be a configured skill.
- `amount` must be a whole number greater than 0 and not above `Config.maxAward`.
- If `location` is given it must be a vector3, vector4 or a table with numeric `x`, `y`, `z`; the player must be within `distance` (default 5.0, must be above 0 and at most 1000) according to `Kora.distance.player`. Without `location` no proximity check is made.
- The player must have an active character.
- XP is added in SQL with an atomic capped increment, so it never exceeds the XP for `maxLevel`. Awards for one player are serialised.
- On success `PlayerData.skills` is updated, and if the level increased the client receives `kora_skills:client:levelledUp` (see [Events](./events.md)).

Skills are loaded (and any legacy data imported) the first time they are read for a character, or when the `PlayerData.skills` field is loaded.

## Client

The client exports read the replicated `PlayerData.skills` cache. Use them for presentation only; authorise valuable actions on the server.

| Export | Description |
| --- | --- |
| `getRep(skill?)` | One skill record, or the full table when `skill` is `nil`. |
| `getAllRep()` | The full table of skill records. |
| `isLevel(skill, level)` | Same rule as the server export, against the cache. |
| `getSkillCheckOptions(skill, gameType, options?)` | Adds the configured level-scaled deltas to `options`. Unlike the server version it does not clamp the result. |
| `open()` | Opens the skills panel (same as the command). |
| `GetSkillsData()` | Skill id to label map (from `config.lua`). |

```lua
local mining = exports.kora_skills:getRep('mining')
if mining and mining.level >= 20 then
    -- presentation only
end
```
