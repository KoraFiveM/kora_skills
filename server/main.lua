local function isSource(source)
    return type(source) == 'number' and source >= 1 and source % 1 == 0
end

local skillsBySource = {}
local awardLocks = {}

local function loadPlayerSkills(source, citizenid)
    local player = exports.qbcore:getPlayer(source)
    if type(player) ~= 'table' or player.citizenid ~= citizenid then return nil, 'player has no active character' end
    local metadata = type(player.metadata) == 'table' and player.metadata or {}
    local legacy = metadata[Config.legacyMetadataKey]
    local skills, err = QBSkillsDatabase.load(citizenid, legacy)
    if not skills then return nil, err end
    skillsBySource[source] = { citizenid = citizenid, skills = skills }

    -- The profile marker in SQL makes this a one-way migration. Removing the
    -- old blob also prevents stale/external metadata writes from looking like
    -- authoritative progression to other server resources.
    if legacy ~= nil then exports.qbcore:setMetaData(source, Config.legacyMetadataKey, nil) end
    return skills
end

local function playerSkills(source)
    if not isSource(source) then return nil, 'invalid player source' end
    local player = exports.qbcore:getPlayer(source)
    if type(player) ~= 'table' then return nil, 'player has no active character' end
    local cached = skillsBySource[source]
    if cached and cached.citizenid == player.citizenid then return cached.skills end

    local skills, err = loadPlayerSkills(source, player.citizenid)
    if not skills then return nil, err end
    exports.qbcore:setPlayerDataField(source, 'skills', skills)
    return skills
end

local function syncSkills(source, skills)
    return exports.qbcore:setPlayerDataField(source, 'skills', skills)
end

local function cloneOptions(options)
    local clone = {}
    for key, value in pairs(options or {}) do clone[key] = value end
    return clone
end

-- These are qblib's post-resolution safe ranges. Restricting the configuration
-- to this allow-list means a skill config cannot alter puzzle content, attempts,
-- or server-side anti-cheat floors.
local CHECK_BOUNDS = {
    lockpick = { tolerance = { min = 0.03, max = 0.35 }, speed = { min = 0.3, max = 4.0 }, timeLimit = { min = 2000, max = 60000 } },
    skillbar = { zoneSize = { min = 0.05, max = 0.6 }, speed = { min = 0.3, max = 4.0 }, timeLimit = { min = 1500, max = 30000 } },
    circuit = { nodeCount = { min = 2, max = 8, integer = true }, timeLimit = { min = 3000, max = 60000 } },
    mash = { requiredPresses = { min = 3, max = 100, integer = true }, timeLimit = { min = 1000, max = 30000 } },
    pinpad = { digits = { min = 3, max = 8, integer = true }, timeLimit = { min = 3000, max = 60000 } },
    quiz = { correctRequired = { min = 1, max = 20, integer = true }, timePerQuestion = { min = 2000, max = 120000 }, timeLimit = { min = 2000, max = 600000 } },
    wordguess = { guesses = { min = 1, max = 26, integer = true }, timeLimit = { min = 5000, max = 300000 } },
    wordscramble = { timeLimit = { min = 3000, max = 300000 } },
    keys = { amount = { min = 1, max = 30, integer = true }, timeLimit = { min = 1000, max = 300000 } },
    hacking = { solutionsize = { min = 2, max = 10, integer = true }, timeLimit = { min = 5000, max = 120000 } },
}

local function skillCheckOptions(data, skill, gameType, options)
    local result = cloneOptions(options)
    local definition = Config.skills[skill]
    local modifiers = definition and definition.skillCheck and definition.skillCheck[gameType]
    local bounds = CHECK_BOUNDS[gameType]
    if not data or type(modifiers) ~= 'table' or not bounds then return result end

    local ratio = Config.maxLevel == 1 and 1 or (data.level - 1) / (Config.maxLevel - 1)
    for field, delta in pairs(modifiers) do
        local limit, current = bounds[field], result[field]
        if limit and type(delta) == 'number' and type(current) == 'number' then
            local adjusted = math.max(limit.min, math.min(limit.max, current + delta * ratio))
            result[field] = limit.integer and math.floor(adjusted) or adjusted
        end
    end
    return result
end

---@param source integer
---@param skill? string
---@return table|nil, string|nil
local function getRep(source, skill)
    local skills, err = playerSkills(source)
    if not skills then return nil, err end
    if skill == nil then return skills end
    if type(skill) ~= 'string' or not Config.skills[skill] then return nil, 'unknown skill' end
    return skills[skill]
end

---@param source integer
---@return table|nil, string|nil
local function getAllRep(source)
    return playerSkills(source)
end

---@param source integer
---@param skill string
---@param level integer
---@return boolean
local function isLevel(source, skill, level)
    level = tonumber(level)
    if not level or level % 1 ~= 0 or level < 1 then return false end
    local data = getRep(source, skill)
    return data ~= nil and data.level >= level
end

local function isWithinDistance(source, location, distance)
    if type(location) ~= 'table' or type(location.x) ~= 'number' or type(location.y) ~= 'number'
        or type(location.z) ~= 'number' then
        return false, 'invalid award location'
    end
    distance = tonumber(distance) or 5.0
    if distance <= 0 or distance > 1000 then return false, 'invalid award distance' end

    local target = vector3(location.x, location.y, location.z)
    if not QB.distance.player(source, target, distance) then
        return false, 'player is too far from the award location'
    end
    return true
end

---@param source integer
---@param skill string
---@param amount number
---@param location? vector3|table
---@param distance? number
---@return boolean, string|nil
local function addRepLocked(source, skill, amount)
    local skills, err = playerSkills(source)
    if not skills then return false, err end
    local previous = skills[skill]
    local player = exports.qbcore:getPlayer(source)
    if type(player) ~= 'table' then return false, 'player has no active character' end
    local xp, writeErr = QBSkillsDatabase.addXp(
        player.citizenid,
        skill,
        amount,
        QBSkills.xpForLevel(Config.maxLevel)
    )
    if not xp then return false, writeErr end
    local updated = QBSkills.makeSkill(skill, xp)
    skills[skill] = updated
    local synced, syncErr = syncSkills(source, skills)
    if not synced then return false, syncErr end

    if updated.level > previous.level then
        TriggerClientEvent('qbskills:client:levelledUp', source, updated)
    end
    return true
end

local function addRep(source, skill, amount, location, distance)
    if type(skill) ~= 'string' or not Config.skills[skill] then return false, 'unknown skill' end
    amount = tonumber(amount)
    if not amount or amount % 1 ~= 0 or amount <= 0 or amount > Config.maxAward then
        return false, 'skill award must be a positive integer within the configured maximum'
    end
    if location then
        local near, err = isWithinDistance(source, location, distance)
        if not near then return false, err end
    end

    -- The SQL increment itself is atomic. Serialising per session also keeps
    -- read-back completion order from allowing an older result to replace a
    -- newer value in the private cache or replicated read model.
    while awardLocks[source] do Wait(0) end
    awardLocks[source] = true
    local results = table.pack(pcall(addRepLocked, source, skill, amount))
    awardLocks[source] = nil
    if not results[1] then error(results[2], 0) end
    return table.unpack(results, 2, results.n)
end

AddEventHandler('qbskills:server:databaseReady', function()
    local registered, err = exports.qbcore:registerPlayerDataField('skills', loadPlayerSkills)
    if not registered then
        print(('^1[qbskills]^7 could not register PlayerData.skills: %s'):format(tostring(err)))
    end
end)

AddEventHandler('QBCore:Server:OnPlayerUnload', function(source)
    skillsBySource[source] = nil
end)

AddEventHandler('qbcore:server:playerDropped', function(source)
    skillsBySource[source] = nil
end)

exports('getRep', getRep)
exports('getAllRep', getAllRep)
exports('addRep', addRep)
exports('isLevel', isLevel)
exports('getSkillCheckOptions', function(source, skill, gameType, options)
    local data = getRep(source, skill)
    return skillCheckOptions(data, skill, gameType, options), data
end)
