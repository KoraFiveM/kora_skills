KoraSkillsSchema = {
    {
        name = 'kora_skills_profiles',
        collate = 'utf8mb4_unicode_ci',
        columns = {
            { name = 'citizenid', type = 'varchar(50)' },
            { name = 'migrated_at', type = 'timestamp', default = { raw = 'CURRENT_TIMESTAMP' } },
        },
        primary = { 'citizenid' },
    },
    {
        name = 'kora_skills_progress',
        collate = 'utf8mb4_unicode_ci',
        columns = {
            { name = 'citizenid', type = 'varchar(50)' },
            { name = 'skill', type = 'varchar(64)' },
            { name = 'xp', type = 'bigint', unsigned = true, default = 0 },
            { name = 'updated_at', type = 'timestamp', default = { raw = 'CURRENT_TIMESTAMP' }, on_update = 'CURRENT_TIMESTAMP' },
        },
        primary = { 'citizenid', 'skill' },
        indexes = { { name = 'kora_skills_progress_skill', columns = { 'skill' } } },
    },
}
