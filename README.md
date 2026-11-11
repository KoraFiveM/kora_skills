# kora_skills

`kora_skills` is a config-driven, XP-based character skill system, based heavily
on [md_skills](https://github.com/Mustachedom/md_skills): it retains the
RuneScape-style level curve, per-skill XP/level/percentage data, simple
server exports, and a `/skillList` compatibility command.

It integrates with this server differently in two intentional ways:

- Skill XP is authoritative in `kora_skills_progress`. `PlayerData.skills` is a
  replicated-only read model for client UI and is never trusted server-side.
- Its panel is a kora_lib AppShell app. The shared UI owns focus and lifecycle;
  `kora_skills` owns only skill state and the progression graph data.

## Install

Ensure it after kora_lib, kora_theme, and kora_core:

```cfg
ensure kora_skills
```

Configure skill names, order, labels, icons, level cap, and optional minigame
bonuses in [config.lua](config.lua). Existing characters are automatically
backfilled with any new configured skill on their next load/read. Existing
`metadata.skills` values are imported once, marked migrated in
`kora_skills_profiles`, and removed from metadata.

Open the panel with `/skills`, `/skillList`, or the configured F6 key mapping.

## Server API

All progression writes are server-only. Returns are designed to match the
familiar `md_skills` surface:

```lua
-- One skill or the full keyed collection.
exports.kora_skills:getRep(source, 'mining')
exports.kora_skills:getAllRep(source)

-- Award a positive integer amount of XP. The optional location is checked on
-- the server before the award is applied.
local added, err = exports.kora_skills:addRep(source, 'mining', 25, mineCoords, 4.0)

exports.kora_skills:isLevel(source, 'mining', 20) -- boolean
```

Each skill data record contains `name`, `label`, `icon`, `xp`, `level`,
`percent`, `maxLevel`, `levelXp`, `nextLevelXp`, and `xpToNextLevel`.

Client UI can read the already-replicated field without a callback:

```lua
local mining = exports.kora_core:getPlayerData({ 'skills', 'mining' })
if mining and mining.level >= 20 then
    -- presentation only; authorize valuable actions on the server
end
```

## kora_lib skill checks

kora_lib exposes an optional `Kora.skills` bridge only while `kora_skills` is started.
The proof-safe form for a valued action is:

```lua
-- server: perform your own action validation first
local authorization = Kora.minigames.authorizeSkillCheck(src, 'mining', 'skillbar', {
    zoneSize = 0.16,
    attempts = 1,
})

-- client
local result = Kora.minigames.playSkillCheck('mining', 'skillbar', nil, authorization)
```

The skill bonus is calculated from authoritative server SQL state and captured
inside the authorization. The player still needs a valid kora_lib proof and the
calling resource must re-check its own target, inventory, and proximity state
before applying its result.
