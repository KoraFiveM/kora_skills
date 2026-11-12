---
title: Troubleshooting
sidebar_position: 11
---

# Troubleshooting

## Panel says "Your skills are not available yet."

The player has no active character, or the SQL load failed. Check the server console for `[kora_skills]` messages, confirm `kora_sql` and `kora_core` are started, and see [Database](./database.md).

## Console prints "still waiting for kora_sql"

Tables are only created after `kora_sql` reports ready. Start `kora_sql` (and its database) before `kora_skills`. Setup resumes automatically.

## "could not register PlayerData.skills"

`kora_core` rejected the field registration. Ensure `kora_core` is started before `kora_skills`. Until it is registered, exports still work for loaded players but the replicated field is not populated at character load.

## addRep returns false

The second return value gives the reason:

- `unknown skill` - the id is not in `Config.skills`.
- `skill award must be a positive integer within the configured maximum` - non-integer, zero, negative, or above `Config.maxAward`.
- `invalid award location` / `invalid award distance` - the optional location or distance is malformed.
- `player is too far from the award location` - the proximity check failed.
- `player has no active character` - the source has no loaded character.

## Added a skill but players do not see it

Make sure the id is in both `Config.skills` and `Config.skillOrder`, then restart the resource. The server console errors at startup if the two disagree.

## Key does not open the panel

The default key is F4, not F6. It can be rebound in FiveM settings, and players who already have a binding keep it when `Config.keyMapping` changes.

## Client values look stale

Client exports read a replicated cache updated when the `skills` player data field changes. For anything that matters, call the server exports.
