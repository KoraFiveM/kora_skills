local APP_ID = 'kora_skills:progression'
local skills = {}
local appOpen = false

local function skillLabel(name)
    if type(name) ~= 'string' then return Kora.lang('fallback_skill') end
    local definition = Config.skills[name]
    return definition and definition.label or Kora.lang('fallback_skill')
end

local function readSkills()
    local data = exports.kora_core:getPlayerData({ 'skills' })
    skills = type(data) == 'table' and data or {}
    return next(skills) ~= nil
end

local function formatNumber(value)
    local formatted = tostring(math.floor(tonumber(value) or 0))
    while true do
        Wait(0)
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
            label = skillLabel(data.name),
            value = data.percent,
            max = 100,
            description = Kora.lang('level_progress', data.level, data.maxLevel),
            detail = data.level == data.maxLevel and Kora.lang('max_level_detail', formatNumber(data.xp))
                or Kora.lang('xp_progress', formatNumber(data.xp), formatNumber(data.nextLevelXp)),
            icon = data.icon,
            tone = data.level == data.maxLevel and 'success' or 'primary',
        }
        rows[#rows + 1] = {
            id = data.name,
            skill = { label = skillLabel(data.name), icon = data.icon },
            level = Kora.lang('level_progress_compact', data.level, data.maxLevel),
            xp = formatNumber(data.xp),
            next = data.level == data.maxLevel and Kora.lang('max_level') or Kora.lang('xp_to_next_level', formatNumber(data.xpToNextLevel)),
        }
    end

    return {
        id = APP_ID,
        title = Kora.lang('title'),
        description = Kora.lang('description'),
        icon = 'Activity',
        width = 980,
        height = 720,
        navigation = {
            {
                id = 'overview', label = Kora.lang('overview'), icon = 'Activity',
                content = {
                    title = Kora.lang('your_progression'),
                    description = Kora.lang('progression_description'),
                    blocks = {
                        { type = 'stats', items = {
                            { label = Kora.lang('total_experience'), value = formatNumber(totalXp), icon = 'Star', tone = 'primary' },
                            { label = Kora.lang('combined_levels'), value = totalLevels, icon = 'Activity' },
                            { label = Kora.lang('tracked_skills'), value = #progress, icon = 'List' },
                        } },
                        { type = 'progress', id = 'skill-graph', title = Kora.lang('experience_graph'), items = progress },
                    },
                },
            },
            {
                id = 'details', label = Kora.lang('details'), icon = 'List',
                content = {
                    title = Kora.lang('skill_details'),
                    blocks = {
                        { type = 'table', id = 'skills-table', searchable = true,
                            searchPlaceholder = Kora.lang('search_skills'), pageSize = 10,
                            columns = {
                                { key = 'skill', label = Kora.lang('skill') },
                                { key = 'level', label = Kora.lang('level'), align = 'center' },
                                { key = 'xp', label = Kora.lang('experience'), align = 'right', sortable = true },
                                { key = 'next', label = Kora.lang('to_next_level'), align = 'right' },
                            },
                            rows = rows,
                        },
                    },
                },
            },
        },
        footer = Kora.lang('progress_saved'),
    }
end

local function render()
    if appOpen then Kora.nui.registerApp(appDefinition()) end
end

local function open()
    if appOpen then return end
    local current = Kora.callback.trigger('kora_skills:server:getAll')
    if type(current) ~= 'table' or next(current) == nil then
        return Kora.notify.send({ title = Kora.lang('title'), message = Kora.lang('unavailable'), type = 'error' })
    end
    skills = current
    appOpen = true
    Kora.nui.registerApp(appDefinition())
    Kora.nui.openApp(APP_ID)
    appOpen = false
end

RegisterNetEvent('kora_skills:client:levelledUp', function(data)
    if type(data) ~= 'table' then return end
    Kora.notify.send({
        title = Kora.lang('level_up_title'),
        message = Kora.lang('level_up_message', skillLabel(data.name), tonumber(data.level) or 1),
        type = 'success',
    })
end)

RegisterCommand(Config.command, open, false)
RegisterKeyMapping(Config.command, Kora.lang('open_skills'), 'keyboard', Config.keyMapping)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    readSkills()
end)

exports.kora_core:onPlayerDataChange({ 'skills' }, function(_, value)
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
    level = tonumber(level)
    if not level or level % 1 ~= 0 or level < 1 then
        return false
    end
    local data = skills[skill]
    return data ~= nil and data.level >= level
end)

exports('getSkillCheckOptions', function(skill, gameType, options)
    local definition, data = Config.skills[skill], skills[skill]
    local modifiers = definition and definition.skillCheck and definition.skillCheck[gameType]
    if not data or type(modifiers) ~= 'table' then
        return options
    end

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
