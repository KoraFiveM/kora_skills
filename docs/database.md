---
title: Database
sidebar_position: 9
---

# Database

Tables are created and checked automatically with `Kora.sql.ensureTables` once `kora_sql` is ready (the server console prints a waiting message until then, and schema warnings or failures are logged). No SQL files need importing. Both tables use `utf8mb4_unicode_ci`.

## `kora_skills_progress`

One row per character per skill. This is the source of truth for XP.

| Column | Type | Notes |
| --- | --- | --- |
| `citizenid` | `varchar(50)` | Part of primary key |
| `skill` | `varchar(64)` | Part of primary key; configured skill id |
| `xp` | `bigint unsigned` | Default 0 |
| `updated_at` | `timestamp` | Default and on update `CURRENT_TIMESTAMP` |

Primary key is `(citizenid, skill)`, with an index `kora_skills_progress_skill` on `skill`.

Behaviour:

- When a character is loaded, missing rows for configured skills are inserted with 0 XP (`INSERT IGNORE`, in a transaction).
- Awards use `INSERT ... ON DUPLICATE KEY UPDATE xp = LEAST(xp + award, max)` where max is the XP for `Config.maxLevel`, then read the value back.
- Rows for skills no longer configured are ignored.

## `kora_skills_profiles`

| Column | Type | Notes |
| --- | --- | --- |
| `citizenid` | `varchar(50)` | Primary key |
| `migrated_at` | `timestamp` | Default `CURRENT_TIMESTAMP` |

A row marks that the character's legacy metadata import has been handled.

## Legacy metadata import

When a character has no `kora_skills_profiles` row, the XP found in the character metadata key `Config.legacyMetadataKey` (default `skills`) is normalised and inserted (`INSERT IGNORE`, only skills with XP above 0) in the same transaction as the profile row. After a successful load, if that metadata key is set, it is cleared with `kora_core:setMetaData`. The profile row guarantees the import never runs again.

## Replicated read model

`PlayerData.skills` is registered with `kora_core` as a player data field and updated after loads and awards. It is for client UI only; the server reads and writes through its own cache backed by SQL.
