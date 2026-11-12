---
title: "Commands"
sidebar_position: 4
---


# Commands

Kora Skills adds one key binding and two equivalent commands.

## Built-in commands

### `/skills`

Opens the Skills progression panel for the player's current character.

| Field | Details |
| --- | --- |
| Context | In-game · client command |
| Arguments | No arguments. |
| Access | Everyone. |

**Example**

```text
/skills
```

**Result**

Opens the panel, or shows an error notification if skills are not available yet (for example no character loaded).

### `/skillList`

Alias of `/skills`, kept for md_skills compatibility.

| Field | Details |
| --- | --- |
| Context | In-game · client command |
| Arguments | No arguments. |
| Access | Everyone. |

**Example**

```text
/skillList
```

**Result**

Same as `/skills`.

## Key binding

`Config.keyMapping` (default `F4`) is bound to the same open action via `RegisterKeyMapping`; players can rebind it in FiveM's key bindings settings.

## Notes

- The primary command name comes from `Config.command` (default `skills`); `/skillList` is always registered in addition.
- Both commands are registered without restriction, so no ACE permission is required.
- The key mapping label shown in FiveM's key binding settings is "Open your skills".
- The repository README previously said F6; the code default is F4 (`config.lua`).

See [Progression panel](./ui.md) for what the panel shows.
