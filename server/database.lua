KoraSkillsDatabase = KoraSkillsDatabase or {}

local PROFILE_SQL = 'SELECT `citizenid` FROM `kora_skills_profiles` WHERE `citizenid` = ?'
local PROGRESS_SQL = 'SELECT `skill`,`xp` FROM `kora_skills_progress` WHERE `citizenid` = ?'
local AWARD_SQL = [[INSERT INTO `kora_skills_progress` (`citizenid`,`skill`,`xp`) VALUES (?,?,?)
    ON DUPLICATE KEY UPDATE `xp` = LEAST(`xp` + VALUES(`xp`), ?)]]
local SKILL_SQL = 'SELECT `xp` FROM `kora_skills_progress` WHERE `citizenid` = ? AND `skill` = ?'

local function readProgress(citizenid)
    local rows, err = Kora.sql.query(PROGRESS_SQL, { citizenid })
    if not rows then return nil, err end
    local stored = {}
    for _, row in ipairs(rows) do
        if Config.skills[row.skill] then stored[row.skill] = { xp = tonumber(row.xp) or 0 } end
    end
    local missing = {}
    for _, skill in ipairs(Config.skillOrder) do
        if not stored[skill] then
            missing[#missing + 1] = {
                sql = 'INSERT IGNORE INTO `kora_skills_progress` (`citizenid`,`skill`,`xp`) VALUES (?,?,?)',
                params = { citizenid, skill, 0 },
            }
        end
    end
    if #missing > 0 then
        local inserted, insertErr = Kora.sql.transaction(missing)
        if not inserted then return nil, insertErr or 'could not initialise configured skills' end
    end
    local skills = KoraSkills.normalise(stored)
    return skills
end

local function importLegacy(citizenid, legacy)
    local skills = KoraSkills.normalise(legacy)
    local statements = {
        { sql = 'INSERT IGNORE INTO `kora_skills_profiles` (`citizenid`) VALUES (?)', params = { citizenid } },
    }
    for _, skill in ipairs(Config.skillOrder) do
        local xp = skills[skill].xp
        if xp > 0 then
            statements[#statements + 1] = {
                sql = 'INSERT IGNORE INTO `kora_skills_progress` (`citizenid`,`skill`,`xp`) VALUES (?,?,?)',
                params = { citizenid, skill, xp },
            }
        end
    end
    return Kora.sql.transaction(statements)
end

---@param citizenid string
---@param legacy? table
---@return table|nil, string|nil
function KoraSkillsDatabase.load(citizenid, legacy)
    local profile, profileErr = Kora.sql.single(PROFILE_SQL, { citizenid })
    if profileErr then return nil, profileErr end
    if not profile then
        local imported, importErr = importLegacy(citizenid, legacy)
        if not imported then return nil, importErr or 'could not initialise skill profile' end
    end
    return readProgress(citizenid)
end

---@param citizenid string
---@param skill string
---@param amount integer
---@param maximumXp integer
---@return integer|nil, string|nil
function KoraSkillsDatabase.addXp(citizenid, skill, amount, maximumXp)
    local affected, err = Kora.sql.update(AWARD_SQL, { citizenid, skill, amount, maximumXp })
    if not affected then return nil, err end
    local row, readErr = Kora.sql.single(SKILL_SQL, { citizenid, skill })
    if not row then return nil, readErr or 'skill award was written but could not be read back' end
    return math.max(0, math.min(maximumXp, math.floor(tonumber(row.xp) or 0)))
end

CreateThread(function()
    while not Kora.sql.ready(60000) do
        print('^3[kora_skills]^7 still waiting for kora_sql; schema setup will resume automatically.')
    end
    local reports, err = Kora.sql.ensureTables(KoraSkillsSchema)
    if err then
        print(('^1[kora_skills]^7 schema setup failed: %s'):format(tostring(err)))
        return
    end
    for _, report in ipairs(reports or {}) do
        for _, warning in ipairs(report.warnings or {}) do
            print(('^3[kora_skills]^7 schema warning: %s'):format(tostring(warning)))
        end
    end
    TriggerEvent('kora_skills:server:databaseReady')
end)
