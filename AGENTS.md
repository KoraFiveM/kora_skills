# kora_skills agent guide

`kora_skills` is a Kora XP skill resource: per-character XP per configured skill stored in SQL, a level curve, server/client exports, and a `kora_lib` AppShell progression panel. Layout: `fxmanifest.lua`, `config.lua` (shared config and the `GetSkillsData` export), `shared/curve.lua` (config validation and level maths), `server/schema.lua` and `server/database.lua` (tables and queries), `server/main.lua` (exports, award logic, callback), `client/main.lua` (panel, commands, client exports), `test/smoke/` (offline Lua tests) and `tests/` (kora_qa feature files).

## Documentation

User-facing documentation lives in `docs/` (Markdown, published via the Kora Docusaurus site, kora_docs_next). Read `docs/index.md` first (hub with a documentation map). Layout: `installation.md` (install, requirements, manifest, legacy migration, testing), `how-to-use.md` (curve, awarding XP, skill-check easing, panel), `commands.md` (`/skills`, `/skillList`, key binding), `api/` (`api/exports.md` is the full server/client export reference), and topic pages `configuration.md`, `events.md`, `skill-checks.md`, `database.md`, `ui.md` (progression panel), `troubleshooting.md`. Update the page that owns the topic.

When you add, change, or remove a feature, config option, command, export, event, item, permission, or database table/column, update the matching page in `docs/` in the same change. Keep docs accurate to the code; do not document behaviour that does not exist.

Docs rules: plain Markdown with `title`/`sidebar_position` front matter (no `id`/`slug`), relative links only between docs pages, assets inside `docs/`, fenced code blocks with a language, and no raw `<`, `>`, `{`, `}` outside code (pages are parsed as MDX). The release version comes from `fxmanifest.lua`'s `version` field.

## Shared contribution standards

Read [CONTRIBUTING.md](CONTRIBUTING.md) before editing. Humans and agents follow
the same Kora standards and self-contained local Lua checks. Preserve the domain
constraints above and in module guides; record policy conflicts explicitly.
