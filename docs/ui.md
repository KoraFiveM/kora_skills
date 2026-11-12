---
title: Progression panel
sidebar_position: 10
---

# Progression panel

Commands and the key binding are documented on [Commands](./commands.md).

## Panel

The panel is a `kora_lib` AppShell app with id `kora_skills:progression`, titled "Skills" (980 by 720). On open the client fetches fresh data with the `kora_skills:server:getAll` callback. If no skills are returned it shows an error notification ("Your skills are not available yet." or the server's error).

- **Overview** - stats for total experience, combined levels and tracked skills, plus a progress bar per skill (percentage to next level, "Level X / max", and XP against the next level threshold; max-level skills show as success).
- **Details** - a searchable table (10 rows per page) with Skill, Level, Experience (sortable) and To next level.

The footer reads "Progress is saved with this character." While the panel is open it re-renders when the replicated `skills` field changes.

A level-up notification is shown when XP awards raise a level. See [Events](./events.md).
