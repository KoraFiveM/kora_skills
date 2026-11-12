---
title: Events
sidebar_position: 7
---

# Events

## Events and callbacks provided

| Name | Type | Direction | Description |
| --- | --- | --- | --- |
| `kora_skills:client:levelledUp` | Net event | Server to client | Sent by `addRep` when the awarded XP raises the level. Payload is the updated skill record. The client shows a "Skill level up" notification ("`Label` is now level `N`."). |
| `kora_skills:server:getAll` | `Kora.callback` | Client to server | Returns all skill records for the caller (loading them from SQL), or `nil, error` when the player has no active character. Used by the panel when it opens. |
| `kora_skills:server:databaseReady` | Local server event | Internal | Triggered once the tables exist. The resource then registers the `skills` player data field with `kora_core`. Not intended for other resources. |

## Events listened to

| Name | Side | Effect |
| --- | --- | --- |
| `QBCore:Server:OnPlayerUnload` | Server | Clears the player's cached skills. |
| `kora_core:server:playerDropped` | Server | Clears the player's cached skills. |
| `QBCore:Client:OnPlayerLoaded` | Client | Re-reads `PlayerData.skills` into the client cache. |

The client also subscribes to changes of the `skills` player data field through `kora_core`'s `onPlayerDataChange`, updating its cache and re-rendering the panel if it is open.
