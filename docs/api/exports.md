---
title: "Public exports"
sidebar_position: 2
---


# Public exports

## Server

Server-authoritative reads, the one write path (`addRep`), and the skill-check option adjuster. Every export validates `source` and the player's active character before touching anything.

Namespace: `exports.kora_skills` · Source: `server/main.lua, server/database.lua`

### How it works

Skill data is cached per `source` (keyed also by `citizenid`, so a character swap invalidates it) and lazily loaded/imported on first read. `addRep` is the only path that changes XP, going through an atomic SQL upsert capped at the level-99 threshold, with per-player award serialisation.

### Functions

Six exports.

#### `exports.kora_skills:getRep(source, skill?)`

Reads one skill record, or the whole set, for an online player. Loads and/or legacy-imports the player's skills on first access.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `source` | number | Required. Server ID of an online player with an active character. |
| `skill?` | string | Skill id from `Config.skillOrder`. Omit to get every skill. |

**Returns**

- **`table | nil, string | nil`** — a skill record (`{ name, label, icon, xp, level, percent, maxLevel, levelXp, nextLevelXp, xpToNextLevel }`) or the full `{ [skill] = record }` table; `nil, error` for an invalid source, no active character, an unknown skill id, or a database error.

**Example**

```lua
local mining = exports.kora_skills:getRep(source, 'mining')
if mining and mining.level >= 10 then print('can mine the good rocks') end
```

**Representative console output**

```text
Results are cached per source/citizenid for the session; the cache is cleared on `QBCore:Server:OnPlayerUnload` and `kora_core:server:playerDropped`.
```

#### `exports.kora_skills:getAllRep(source)`

Shorthand for `getRep(source)` with no skill argument.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `source` | number | Required. Server ID of an online player. |

**Returns**

- **`table | nil, string | nil`** — `{ [skill] = record }` for every configured skill, or `nil, error`.

**Example**

```lua
local all = exports.kora_skills:getAllRep(source)
```

**Representative console output**

```text
Same caching and error behavior as `getRep`.
```

#### `exports.kora_skills:addRep(source, skill, amount, location?, distance?)`

Server-authoritative XP award. The only way any resource increases a player's skill XP.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `source` | number | Required. Server ID of an online player. |
| `skill` | string | Required skill id from `Config.skillOrder`. |
| `amount` | number | Required positive integer, at most `Config.maxAward` (default 100000). |
| `location?` | table | Optional `{ x, y, z }`. When given, the player must be server-confirmed within `distance` of it. |
| `distance?` | number | Metres, 0 &lt; distance &lt;= 1000. Default 5.0. Only used when `location` is given. |

**Returns**

- **`boolean, string | nil`** — `true` on success; `false, reason` for an unknown skill, an invalid/out-of-range amount, a missing character, a location check failure, or a database error.

**Example**

```lua
local ok, err = exports.kora_skills:addRep(source, 'fishing', 25)
if not ok then print('xp award failed:', err) end
```

**Representative console output**

```text
XP is written through an atomic SQL upsert capped at the level-99 threshold, then re-read back before `PlayerData.skills` is updated and a level-up event is fired if applicable. Awards to the same player are serialised so concurrent calls cannot race each other.
```

#### `exports.kora_skills:isLevel(source, skill, level)`

Convenience gate: does this player meet a minimum level in a skill?

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `source` | number | Required. |
| `skill` | string | Required skill id. |
| `level` | number | Required positive integer minimum level. |

**Returns**

- **`boolean`** — `true` if the player has an active character and that skill's level is at least `level`; `false` for any invalid input, missing character or lower level.

**Example**

```lua
if not exports.kora_skills:isLevel(source, 'crafting', 20) then return false, 'level 20 crafting required' end
```

**Representative console output**

```text
Calls `getRep` internally, so it shares the same cache and loading behavior.
```

#### `exports.kora_skills:getSkillCheckOptions(source, skill, gameType, options)`

Applies a skill's configured minigame-easing modifiers to a kora_lib skill-check options table, scaled by the player's level.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `source` | number | Required. |
| `skill` | string | Required skill id. |
| `gameType` | string | One of `lockpick`, `skillbar`, `circuit`, `mash`, `pinpad`, `quiz`, `wordguess`, `wordscramble`, `keys`, `hacking`. |
| `options` | table | The base options you would otherwise pass to the kora_lib minigame. |

**Returns**

- **`table, table | nil`** — the adjusted options (unchanged fields copied through) and the skill record used for the adjustment (`nil` if the skill or player data was unavailable, in which case `options` is returned unchanged).

**Example**

```lua
local options = exports.kora_skills:getSkillCheckOptions(source, 'mining', 'skillbar', { zoneSize = 0.10 })
```

**Representative console output**

```text
Adjusted fields are clamped to kora_lib's documented safe bounds for that game type, so a skill can never make a check unfairly easy or push a value out of range.
```

#### `exports.kora_skills:GetSkillsData()`

Returns the configured skills as a `{ [skill] = label }` map, handy for building a skills list or picker in another resource.

**Parameters**



**Returns**

- **`table`** — `{ [skillKey] = label }` for every entry of `Config.skills`.

**Example**

```lua
local skills = exports.kora_skills:GetSkillsData()
for key, label in pairs(skills) do print(key, label) end
```

**Representative console output**

```text
Prints one line per configured skill, for example `hacking	Hacking`. Registered from `config.lua`, so it exists on both the client and the server.
```

### Limits and related APIs

Server only. `addRep` amounts above `Config.maxAward` or non-positive-integer amounts are rejected outright. Skill ids not present in `Config.skillOrder` are always rejected.

## Client

Read-only mirrors of the server exports plus `open()`, all backed by the client's own cached copy of `PlayerData.skills`.

Namespace: `exports.kora_skills` · Source: `client/main.lua`

### How it works

The cache is refreshed whenever kora_core fires a player-data change for the `skills` field, and once on resource start / character load.

### Functions

Six exports.

#### `exports.kora_skills:getRep(skill?)`

Reads the client's cached copy of the player's own skills.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `skill?` | string | Skill id. Omit for the full table. |

**Returns**

- **`table | nil`** — a skill record or the `{ [skill] = record }` table, from whatever `PlayerData.skills` last held on this client.

**Example**

```lua
local mining = exports.kora_skills:getRep('mining')
```

**Representative console output**

```text
Read-only and client-local: use it only for UI/UX decisions, never to decide whether something is actually allowed — the server does not trust it.
```

#### `exports.kora_skills:getAllRep()`

Shorthand for `getRep()` with no argument.

**Parameters**



**Returns**

- **`table`** — the cached `{ [skill] = record }` table (may be empty before the first load).

**Example**

```lua
local all = exports.kora_skills:getAllRep()
```

**Representative console output**

```text
Same caveats as the server `getRep`: client-local and advisory only.
```

#### `exports.kora_skills:isLevel(skill, level)`

Client-side convenience check against the cached skill data.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `skill` | string | Required. |
| `level` | number | Required minimum level. |

**Returns**

- **`boolean`** — `true` if the cached record meets the level.

**Example**

```lua
if exports.kora_skills:isLevel('mining', 10) then ... end
```

**Representative console output**

```text
Advisory only; the server re-checks anything that matters through its own `isLevel`/`getRep` exports.
```

#### `exports.kora_skills:getSkillCheckOptions(skill, gameType, options)`

Client-side mirror of the server function, computed from the cached skill data.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `skill` | string | Required. |
| `gameType` | string | Required. |
| `options` | table | Required base options. |

**Returns**

- **`table`** — the adjusted options, unclamped by `CHECK_BOUNDS` (that clamping only happens server-side).

**Example**

```lua
local options = exports.kora_skills:getSkillCheckOptions('mining', 'skillbar', { zoneSize = 0.10 })
```

**Representative console output**

```text
Use for presentation only; the authorizing copy of the minigame should request its real options from the server export.
```

#### `exports.kora_skills:open()`

Opens the Skills progression panel programmatically — the same action as `/skills` or the key binding.

**Parameters**



**Returns**

- **No return value.**

**Example**

```lua
exports.kora_skills:open()
```

**Representative console output**

```text
A no-op if the panel is already open.
```

#### `exports.kora_skills:GetSkillsData()`

Returns the configured skills as a `{ [skill] = label }` map, handy for building a skills list or picker in another resource.

**Parameters**



**Returns**

- **`table`** — `{ [skillKey] = label }` for every entry of `Config.skills`.

**Example**

```lua
local skills = exports.kora_skills:GetSkillsData()
for key, label in pairs(skills) do print(key, label) end
```

**Representative console output**

```text
Prints one line per configured skill, for example `hacking	Hacking`. Registered from `config.lua`, so it exists on both the client and the server.
```

### Limits and related APIs

Advisory only — nothing here can change XP, and none of it is trusted for authorization decisions.

## Additional notes on the exports

### Return conventions

Server reads return `value` on success or `nil, error` on failure; writes return `true` or `false, error`. An unknown skill passed to `getRep` returns `nil, 'unknown skill'`; the same string is returned by `addRep` as `false, 'unknown skill'`.

### addRep rules

- `skill` must be a configured skill.
- `amount` must be a whole number greater than 0 and not above `Config.maxAward`.
- If `location` is given it must be a vector3, vector4 or a table with numeric `x`, `y`, `z`; otherwise the call fails with `invalid award location`. The player must be within `distance` (default 5.0, must be above 0 and at most 1000; otherwise `invalid award distance`) according to `Kora.distance.player`. Without `location` no proximity check is made.
- The player must have an active character.
- XP is added in SQL with an atomic capped increment, so it never exceeds the XP for `maxLevel`. Awards for one player are serialised.
- On success `PlayerData.skills` is updated, and if the level increased the client receives `kora_skills:client:levelledUp` (see [Events](../events.md)).

```lua
local ok, err = exports.kora_skills:addRep(source, 'mining', 25, mineCoords, 4.0)
```

Skills are loaded (and any legacy data imported) the first time they are read for a character, or when the `PlayerData.skills` field is loaded.

### Client exports

The client exports read the replicated `PlayerData.skills` cache. Use them for presentation only; authorise valuable actions on the server. The client `getSkillCheckOptions` adds the configured level-scaled deltas without clamping; see [Skill checks](../skill-checks.md).
