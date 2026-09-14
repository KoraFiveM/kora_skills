local APP_ID = 'qbskills:progression'
local skills = {}
local appOpen = false

local function readSkills()
    local data = exports.qbcore:getPlayerData({ 'skills' })
    skills = type(data) == 'table' and data or {}
    return next(skills) ~= nil
end

local function formatNumber(value)
    local formatted = tostring(math.floor(tonumber(value) or 0))
    while true do
        local nextValue, count = formatted:gsub('^(%-?%d+)(%d%d%d)', '%1,%2')
        formatted = nextValue
        if count == 0 then return formatted end
    end
end

local function orderedSkills()
    local result = {}
    for _, name in ipairs(Config.skillOrder) do
        if skills[name] then result[#result + 1] = skills[name] end
    end
    return result
end

local function appDefinition()
    local progress, rows = {}, {}
    local totalXp, totalLevels = 0, 0

    for _, data in ipairs(orderedSkills()) do
        totalXp = totalXp + data.xp
        totalLevels = totalLevels + data.level
        progress[#progress + 1] = {
            label = data.label,
            value = data.percent,
            max = 100,
            description = ('Level %d / %d'):format(data.level, data.maxLevel),
            detail = data.level == data.maxLevel and (formatNumber(data.xp) .. ' XP · Max level')
                or ('%s / %s XP'):format(formatNumber(data.xp), formatNumber(data.nextLevelXp)),
            icon = data.icon,
            tone = data.level == data.maxLevel and 'success' or 'primary',
        }
        rows[#rows + 1] = {
            id = data.name,
            skill = { label = data.label, icon = data.icon },
            level = ('%d / %d'):format(data.level, data.maxLevel),
            xp = formatNumber(data.xp),
            next = data.level == data.maxLevel and 'Max level' or (formatNumber(data.xpToNextLevel) .. ' XP'),
        }
    end

    return {
        id = APP_ID,
        title = 'Skills',
        description = 'Character progression',
        icon = 'Activity',
        width = 980,
        height = 720,
        navigation = {
            {
                id = 'overview', label = 'Overview', icon = 'Activity',
                content = {
                    title = 'Your progression',
                    description = 'Build experience through the activities you choose. Higher levels can make matching skill checks more forgiving.',
                    blocks = {
                        { type = 'stats', items = {
                            { label = 'Total experience', value = formatNumber(totalXp), icon = 'Star', tone = 'primary' },
                            { label = 'Combined levels', value = totalLevels, icon = 'Activity' },
                            { label = 'Tracked skills', value = #progress, icon = 'List' },
                        } },
                        { type = 'progress', id = 'skill-graph', title = 'Experience graph', items = progress },
                    },
                },
            },
            {
                id = 'details', label = 'Details', icon = 'List',
                content = {
                    title = 'Skill details',
                    blocks = {
                        { type = 'table', id = 'skills-table', searchable = true,
                            searchPlaceholder = 'Search skills…', pageSize = 10,
                            columns = {
                                { key = 'skill', label = 'Skill' },
                                { key = 'level', label = 'Level', align = 'center' },
                                { key = 'xp', label = 'Experience', align = 'right', sortable = true },
                                { key = 'next', label = 'To next level', align = 'right' },
                            },
                            rows = rows,
                        },
                    },
                },
            },
        },
        footer = 'Progress is saved with this character.',
    }
end

local function render()
    if appOpen then QB.nui.registerApp(appDefinition()) end
end

local function open()
    if appOpen then return end
    if not readSkills() then
        return QB.notify.send({ title = 'Skills', message = 'Your skills are not available yet.', type = 'error' })
    end
    appOpen = true
    QB.nui.registerApp(appDefinition())
    QB.nui.openApp(APP_ID)
    appOpen = false
end

RegisterNetEvent('qbskills:client:levelledUp', function(data)
    if type(data) ~= 'table' then return end
    QB.notify.send({
        title = 'Skill level up',
        message = ('%s is now level %d.'):format(data.label or 'A skill', tonumber(data.level) or 1),
        type = 'success',
    })
end)

RegisterCommand(Config.command, open, false)
RegisterCommand('skillList', open, false) -- md_skills compatibility command
RegisterKeyMapping(Config.command, 'Open your skills', 'keyboard', Config.keyMapping)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    readSkills()
end)

exports.qbcore:onPlayerDataChange({ 'skills' }, function(_, value)
    skills = type(value) == 'table' and value or {}
    render()
end)

readSkills()

exports('getRep', function(skill)
    if skill == nil then return skills end
    return skills[skill]
end)

exports('getAllRep', function()
    return skills
end)

exports('isLevel', function(skill, level)
    local data = skills[skill]
    return data ~= nil and data.level >= (tonumber(level) or math.huge)
end)

exports('getSkillCheckOptions', function(skill, gameType, options)
    -- The client cache only influences un-authorized presentation checks. The
    -- server export repeats the same calculation over authoritative SQL data
    -- before it issues any proof-producing authorization.
    local definition, data = Config.skills[skill], skills[skill]
    local modifiers = definition and definition.skillCheck and definition.skillCheck[gameType]
    if not data or type(modifiers) ~= 'table' then return options end

    local result = {}
    for key, value in pairs(options or {}) do result[key] = value end
    local ratio = Config.maxLevel == 1 and 1 or (data.level - 1) / (Config.maxLevel - 1)
    for field, delta in pairs(modifiers) do
        if type(result[field]) == 'number' and type(delta) == 'number' then
            result[field] = result[field] + delta * ratio
        end
    end
    return result
end)

exports('open', open)
