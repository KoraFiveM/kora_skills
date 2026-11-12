---
title: Skill checks
sidebar_position: 8
---

# Skill checks

Each skill may define `skillCheck` in `config.lua`: per minigame type, per option field, a number that is the change applied at max level. The change scales linearly with the player's level:

```text
ratio = (level - 1) / (maxLevel - 1)
adjusted = base + delta * ratio
```

So level 1 gets no change and the cap gets the full delta. Negative deltas make a value smaller (for example fewer circuit nodes or mash presses).

## Server clamping

The server export `getSkillCheckOptions(source, skill, gameType, options)` only adjusts fields listed in an internal allow-list and clamps the result to safe bounds (matching `kora_lib`'s resolved ranges). Integer fields are floored. Other fields and unknown game types are returned unchanged.

| Game type | Adjustable fields |
| --- | --- |
| `lockpick` | `tolerance`, `speed`, `timeLimit` |
| `skillbar` | `zoneSize`, `speed`, `timeLimit` |
| `circuit` | `nodeCount`, `timeLimit` |
| `mash` | `requiredPresses`, `timeLimit` |
| `pinpad` | `digits`, `timeLimit` |
| `quiz` | `correctRequired`, `timePerQuestion`, `timeLimit` |
| `wordguess` | `guesses`, `timeLimit` |
| `wordscramble` | `timeLimit` |
| `keys` | `amount`, `timeLimit` |
| `hacking` | `solutionsize`, `timeLimit` |

The base option must be a number for a field to be adjusted. The client export applies the same deltas but does not clamp and does not floor integers, so treat it as presentation only.

## Using it with kora_lib

`kora_lib` exposes an optional `Kora.skills` bridge and `Kora.minigames` helpers that call these exports when `kora_skills` is started, and behave like a plain check when it is not. For a valuable action:

```lua
-- server: validate the action yourself first
local authorization = Kora.minigames.authorizeSkillCheck(src, 'mining', 'skillbar', {
    zoneSize = 0.16,
    attempts = 1,
})

-- client
local result = Kora.minigames.playSkillCheck('mining', 'skillbar', nil, authorization)
```

The bonus is computed on the server from authoritative state and captured in the authorization. The calling resource must still re-check its own target, inventory and proximity before applying the result. See the `kora_lib` minigames documentation for the exact API.
