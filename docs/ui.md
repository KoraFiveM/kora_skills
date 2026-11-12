---
title: UI and commands
sidebar_position: 6
---

# UI and commands

## Commands

| Command | Description |
| --- | --- |
| `/skills` | Opens the skills panel. The name comes from `Config.command`. |
| `/skillList` | Always registered; same behaviour (md_skills compatibility). |

The commands are registered without restriction, so no ACE permission is required.

## Key mapping

`RegisterKeyMapping` binds `Config.command` to `Config.keyMapping` (default `F4`) with the label "Open your skills". Players can rebind it in the FiveM key binding settings. The code default is F4 (the repository README still says F6, which is wrong).

## Panel

The panel is a `kora_lib` AppShell app with id `kora_skills:progression`, titled "Skills" (980 by 720). On open the client fetches fresh data with the `kora_skills:server:getAll` callback. If no skills are returned it shows an error notification ("Your skills are not available yet." or the server's error).

- **Overview** - stats for total experience, combined levels and tracked skills, plus a progress bar per skill (percentage to next level, "Level X / max", and XP against the next level threshold; max-level skills show as success).
- **Details** - a searchable table (10 rows per page) with Skill, Level, Experience (sortable) and To next level.

The footer reads "Progress is saved with this character." While the panel is open it re-renders when the replicated `skills` field changes.

A level-up notification is shown when XP awards raise a level. See [Events](./events.md).
