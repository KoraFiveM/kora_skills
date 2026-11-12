---
title: "How to use"
sidebar_position: 3
---


# How to use

Other resources award XP on the server (there is no client path to add XP), read a player's level to gate content, and optionally make their own skill-check minigame a little easier as the matching skill levels up. Players open a read-only progression panel to see their own levels.

## The XP curve

Both realms build the same cumulative table once from `Config.maxLevel` (default 99), adapted from md_skills:

```lua title="shared/curve.lua"
-- shared/curve.lua builds a RuneScape-style cumulative curve once, from Config.maxLevel:
for level = 2, Config.maxLevel do
    local previous = level - 1
    accumulated = accumulated + math.floor(previous + 300 * math.pow(2, previous / 7))
    xpForLevel[level] = math.floor(accumulated / 4)
end
```

- `KoraSkills.xpForLevel(level)` — total XP needed to reach that level (clamped to 1..maxLevel).
- `KoraSkills.levelForXp(xp)` — binary search for the highest level whose threshold is at or below `xp`.
- `KoraSkills.makeSkill(skill, xp)` — builds the full display record for one skill: `{ name, label, icon, xp, level, percent, maxLevel, levelXp, nextLevelXp, xpToNextLevel }`. XP is clamped to the level-99 threshold, so a skill can never show more than 100%.
- `KoraSkills.normalise(values)` — fills in every skill from `Config.skillOrder` that is missing from a stored/legacy table (each defaulting to 0 XP) and reports whether anything changed, so the caller knows whether to persist the result.

## XP is server-authoritative

Only the server can increase a player's XP. The client-side export set (below) is read-only.

- The real work happens in `addRepLocked` (server/main.lua): it re-reads the player's skills, calls `KoraSkillsDatabase.addXp` (an atomic `INSERT ... ON DUPLICATE KEY UPDATE xp = LEAST(xp + VALUES(xp), maximumXp)` capped at the level-99 threshold), rebuilds the skill record from the authoritative new XP, writes it back into kora_core's `PlayerData.skills` field, and fires a level-up notification if the level increased.
- `exports.kora_skills:addRep` is server-only — there is no equivalent client export, so a client resource cannot request its own XP gain; it has to ask a server-side resource to call `addRep` on its behalf.
- Concurrent awards to the same player are serialised with a simple spin-wait lock (`awardLocks[source]`) so two awards in flight cannot read-modify-write past each other.
- An optional `location`/`distance` pair can be passed to `addRep` to additionally require the player be server-confirmed within range of a point (`Kora.distance.player`) before the award is applied — useful for "must still be at the rock/stove" checks.

## Letting a skill ease your own skill-check minigame

Each skill in `Config.skills` can declare `skillCheck = { <gameType> = { <field> = <delta> } }`. The server export `getSkillCheckOptions` applies that delta, scaled by the player's progress from level 1 to `Config.maxLevel`, to options you already built for kora_lib's skill-check minigames.

```text title="server (any resource)"
-- Config.skills.mining.skillCheck = { skillbar = { zoneSize = 0.14 }, lockpick = { tolerance = 0.05 } }
local options, repData = exports.kora_skills:getSkillCheckOptions(source, 'mining', 'skillbar', { zoneSize = 0.10 })
-- options.zoneSize is now up to 0.10 + 0.14 = 0.24 at level 99, linearly interpolated below that
```

- The adjusted field is clamped to kora_lib's own safe bounds per game type (`CHECK_BOUNDS` in server/main.lua), so a generous config value can never push a minigame past what kora_lib considers fair — for example `skillbar.zoneSize` is always clamped to 0.05–0.6.
- Supported game types: `lockpick`, `skillbar`, `circuit`, `mash`, `pinpad`, `quiz`, `wordguess`, `wordscramble`, `keys`, `hacking` — only the fields each one's bounds table lists are adjustable.
- The client also exposes `getSkillCheckOptions`, computing the same formula against its own cached copy of the player's skills. Use it only to decide what to *show* (for example a preview); treat the server's version as the one that actually matters, since the client's cached level could be briefly stale.

## Opening your own skills panel

Players press `Config.keyMapping` (default `F4`) or run `/skills` (or the legacy `/skillList`) to open the Skills AppShell app.

- Opening calls the server callback `kora_skills:server:getAll`, which loads (or lazily imports) the player's skills and returns the full set; the panel shows an Overview (total XP, combined levels, a per-skill experience-graph bar) and a searchable Details table (level, XP, XP to next level).
- The panel is read-only: there is no way to spend XP or change a skill from the UI. A level-up toast (`kora_skills:client:levelledUp`) shows automatically whenever the server reports a level increase from any resource's `addRep` call, whether or not the panel is open.
