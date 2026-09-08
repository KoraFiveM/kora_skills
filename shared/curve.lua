-- RuneScape-style cumulative XP curve, adapted from md_skills. The table is
-- generated once per Lua realm so reads and level checks are constant-time in
-- ordinary gameplay and never yield.

QBSkills = QBSkills or {}

assert(type(Config) == 'table' and type(Config.maxLevel) == 'number' and Config.maxLevel >= 1
    and Config.maxLevel % 1 == 0, 'qbskills Config.maxLevel must be a positive integer.')
assert(type(Config.skills) == 'table' and type(Config.skillOrder) == 'table',
    'qbskills Config.skills and Config.skillOrder must be tables.')

local xpForLevel = { [1] = 0 }
local accumulated = 0

for level = 2, Config.maxLevel do
    local previous = level - 1
    accumulated = accumulated + math.floor(previous + 300 * math.pow(2, previous / 7))
    xpForLevel[level] = math.floor(accumulated / 4)
end

local seenSkills = {}
for index, name in ipairs(Config.skillOrder) do
    local definition = Config.skills[name]
    assert(type(name) == 'string' and name:match('^[%w_%-]+$'),
        ('qbskills Config.skillOrder item %d must be a safe skill id.'):format(index))
    assert(not seenSkills[name], ('qbskills Config.skillOrder repeats %q.'):format(name))
    assert(type(definition) == 'table' and type(definition.label) == 'string' and definition.label ~= '',
        ('qbskills Config.skills.%s requires a label.'):format(name))
    assert(definition.icon == nil or type(definition.icon) == 'string',
        ('qbskills Config.skills.%s icon must be a string.'):format(name))
    seenSkills[name] = true
end

for name in pairs(Config.skills) do
    assert(seenSkills[name], ('qbskills Config.skills.%s is missing from Config.skillOrder.'):format(name))
end

---@param level integer
---@return integer
function QBSkills.xpForLevel(level)
    level = math.max(1, math.min(Config.maxLevel, math.floor(tonumber(level) or 1)))
    return xpForLevel[level]
end

---@param xp number
---@return integer
function QBSkills.levelForXp(xp)
    xp = math.max(0, math.floor(tonumber(xp) or 0))
    local low, high = 1, Config.maxLevel
    while low < high do
        local middle = math.floor((low + high + 1) / 2)
        if xp >= xpForLevel[middle] then low = middle else high = middle - 1 end
    end
    return low
end

---@param skill string
---@param xp number
---@return table|nil
function QBSkills.makeSkill(skill, xp)
    local definition = Config.skills[skill]
    if not definition then return nil end

    local maximumXp = xpForLevel[Config.maxLevel]
    xp = math.max(0, math.min(maximumXp, math.floor(tonumber(xp) or 0)))
    local level = QBSkills.levelForXp(xp)
    local currentLevelXp = xpForLevel[level]
    local nextLevelXp = level < Config.maxLevel and xpForLevel[level + 1] or maximumXp
    local percent = level == Config.maxLevel and 100
        or math.floor((xp - currentLevelXp) / (nextLevelXp - currentLevelXp) * 100)

    return {
        name = skill,
        label = definition.label,
        icon = definition.icon,
        xp = xp,
        level = level,
        percent = percent,
        maxLevel = Config.maxLevel,
        levelXp = currentLevelXp,
        nextLevelXp = nextLevelXp,
        xpToNextLevel = math.max(0, nextLevelXp - xp),
    }
end

---@param values? table
---@return table skills, boolean changed
function QBSkills.normalise(values)
    local result, changed = {}, type(values) ~= 'table'
    values = type(values) == 'table' and values or {}

    for _, skill in ipairs(Config.skillOrder) do
        local stored = values[skill]
        local xp = type(stored) == 'table' and stored.xp or 0
        local data = QBSkills.makeSkill(skill, xp)
        result[skill] = data
        if type(stored) ~= 'table' or stored.xp ~= data.xp or stored.level ~= data.level
            or stored.percent ~= data.percent or stored.label ~= data.label or stored.name ~= data.name
            or stored.icon ~= data.icon or stored.maxLevel ~= data.maxLevel or stored.levelXp ~= data.levelXp
            or stored.nextLevelXp ~= data.nextLevelXp or stored.xpToNextLevel ~= data.xpToNextLevel then
            changed = true
        end
    end
    return result, changed
end
