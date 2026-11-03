local scriptDir = debug.getinfo(1, 'S').source:match('@?(.*/)') or './'
local testDir = scriptDir .. '../'
local resourceRoot = testDir .. '../'
package.path = testDir .. '?.lua;' .. package.path

local harness = require('harness')
local profileExists = false
local progress = {}

_G.Kora = { sql = {
    ready = function() return true end,
    migrateFiles = function() return true end,
    single = function(sql, params)
        if sql:find('qbskills_profiles', 1, true) then return profileExists and { citizenid = params[1] } or nil end
        return progress[params[2]] and { xp = progress[params[2]] } or nil
    end,
    query = function()
        local rows = {}
        for skill, xp in pairs(progress) do rows[#rows + 1] = { skill = skill, xp = xp } end
        return rows
    end,
    transaction = function(statements)
        profileExists = true
        for _, statement in ipairs(statements) do
            if statement.params and #statement.params == 3 then progress[statement.params[2]] = statement.params[3] end
        end
        return true
    end,
    update = function(_, params)
        progress[params[2]] = math.min((progress[params[2]] or 0) + params[3], params[4])
        return 1
    end,
} }
_G.CreateThread = function() end
_G.exports = _G.exports or function() end
_G.GetCurrentResourceName = function() return 'kora_skills' end
_G.TriggerEvent = function() end

dofile(resourceRoot .. 'config.lua')
dofile(resourceRoot .. 'shared/curve.lua')
dofile(resourceRoot .. 'server/database.lua')

harness.test('first load imports legacy metadata exactly once', function()
    local skills, err = QBSkillsDatabase.load('TEST', { mining = { xp = 75 } })
    harness.truthy(skills, err)
    harness.equal(skills.mining.xp, 75)
    harness.truthy(profileExists)

    skills = QBSkillsDatabase.load('TEST', { mining = { xp = 9999 } })
    harness.equal(skills.mining.xp, 75, 'a profile marker must prevent later metadata re-imports')
end)

harness.test('awards atomically accumulate in SQL and return the stored value', function()
    local xp, err = QBSkillsDatabase.addXp('TEST', 'mining', 25, 1000)
    harness.equal(xp, 100, err)
end)

if harness.failures > 0 then os.exit(1) end
