CREATE TABLE IF NOT EXISTS `qbskills_profiles` (
    `citizenid` VARCHAR(50) NOT NULL,
    `migrated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `qbskills_progress` (
    `citizenid` VARCHAR(50) NOT NULL,
    `skill` VARCHAR(64) NOT NULL,
    `xp` BIGINT UNSIGNED NOT NULL DEFAULT 0,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`citizenid`, `skill`),
    KEY `qbskills_progress_skill` (`skill`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
