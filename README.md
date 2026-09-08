# qbskills

`qbskills` is a config-driven, XP-based character skill system, based heavily
on [md_skills](https://github.com/Mustachedom/md_skills): it retains the
RuneScape-style level curve, per-skill XP/level/percentage data, simple
server exports, and a `/skillList` compatibility command.

It integrates with this server differently in two intentional ways:

- Skill data is persisted under `players.metadata.skills` through qbcore, so
  it is replicated and saved with the character without an extra SQL table.
- Its panel is a qblib AppShell app. The shared UI owns focus and lifecycle;
  `qbskills` owns only skill state and the progression graph data.

## Install

Ensure it after qblib, qbtheme, and qbcore:

```cfg
ensure qbskills
```

Configure skill names, order, labels, icons, level cap, and optional minigame
bonuses in [config.lua](config.lua). Existing characters are automatically
backfilled with any new configured skill on their next load/read.

Open the panel with `/skills`, `/skillList`, or the configured F6 key mapping.

## Server API

All progression writes are server-only. Returns are designed to match the
familiar `md_skills` surface:

```lua
-- One skill or the full keyed collection.
exports.qbskills:getRep(source, 'mining')
exports.qbskills:getAllRep(source)

-- Award a positive integer amount of XP. The optional location is checked on
-- the server before the award is applied.
local added, err = exports.qbskills:addRep(source, 'mining', 25, mineCoords, 4.0)

exports.qbskills:isLevel(source, 'mining', 20) -- boolean
```

Each skill data record contains `name`, `label`, `icon`, `xp`, `level`,
`percent`, `maxLevel`, `levelXp`, `nextLevelXp`, and `xpToNextLevel`.

## qblib skill checks

qblib exposes an optional `QB.skills` bridge only while `qbskills` is started.
The proof-safe form for a valued action is:

```lua
-- server: perform your own action validation first
local authorization = QB.minigames.authorizeSkillCheck(src, 'mining', 'skillbar', {
    zoneSize = 0.16,
    attempts = 1,
})

-- client
local result = Citizen.Await(QB.minigames.playSkillCheck('mining', 'skillbar', nil, authorization))
```

The skill bonus is calculated from authoritative server metadata and captured
inside the authorization. The player still needs a valid qblib proof and the
calling resource must re-check its own target, inventory, and proximity state
before applying its result.
