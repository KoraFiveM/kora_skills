local scriptDir = debug.getinfo(1, 'S').source:match('@?(.*/)') or './'
local testDir = scriptDir .. '../'
local resourceRoot = testDir .. '../'
package.path = testDir .. '?.lua;' .. package.path

local harness = require('harness')
local registeredExports, eventHandlers = {}, {}
local player = { citizenid = 'TEST', metadata = { skills = { mining = { xp = 40 } } } }
local replicated
local storedSkills
local registeredProvider
local metadataCleared = false

_G.QB = {}
_G.QBSkillsDatabase = {
    load = function(citizenid, legacy)
        harness.equal(citizenid, 'TEST')
        local skills = QBSkills.normalise(storedSkills or legacy)
        storedSkills = skills
        return skills
    end,
    addXp = function(citizenid, skill, amount, maximumXp)
        harness.equal(citizenid, 'TEST')
        return math.min(storedSkills[skill].xp + amount, maximumXp)
    end,
}
_G.exports = setmetatable({
    qbcore = {
        getPlayer = function(_, source) return source == 1 and player or nil end,
        setMetaData = function(_, _, key, value)
            player.metadata[key] = value
            metadataCleared = value == nil
            return true
        end,
        registerPlayerDataField = function(_, key, provider)
            harness.equal(key, 'skills')
            registeredProvider = provider
            return true
        end,
        setPlayerDataField = function(_, source, key, value)
            harness.equal(source, 1)
            harness.equal(key, 'skills')
            replicated = value
            return true
        end,
    },
}, {
    __call = function(_, name, fn) registeredExports[name] = fn end,
})
_G.TriggerClientEvent = function() end
_G.AddEventHandler = function(name, handler)
    eventHandlers[name] = eventHandlers[name] or {}
    eventHandlers[name][#eventHandlers[name] + 1] = handler
end

local function fire(name, ...)
    for _, handler in ipairs(eventHandlers[name] or {}) do handler(...) end
end

dofile(resourceRoot .. 'config.lua')
dofile(resourceRoot .. 'shared/curve.lua')
dofile(resourceRoot .. 'server/main.lua')

harness.test('database readiness registers the pre-snapshot PlayerData provider', function()
    fire('qbskills:server:databaseReady')
    harness.truthy(registeredProvider, 'PlayerData.skills provider should be registered')
    local skills = registeredProvider(1, 'TEST')
    harness.equal(skills.mining.xp, 40, 'legacy XP should reach the SQL-backed profile loader')
    harness.truthy(metadataCleared, 'legacy metadata should be removed after successful import')
end)

harness.test('reads use the private SQL-backed session cache', function()
    local skills = registeredExports.getAllRep(1)
    harness.equal(skills.mining.xp, 40)
    harness.equal(skills.mining.level, QBSkills.levelForXp(40))
end)

harness.test('awards write through the database then update replicated PlayerData', function()
    local added, err = registeredExports.addRep(1, 'mining', 100)
    harness.truthy(added, err)
    harness.equal(storedSkills.mining.xp, 140, 'the private authoritative cache should follow the SQL result')
    harness.equal(replicated.mining.xp, 140, 'PlayerData.skills should receive the presentation snapshot')
    harness.equal(registeredExports.addRep(1, 'mining', 0), false, 'zero XP must be rejected')
end)

harness.test('metadata changes cannot affect server skill checks after hydration', function()
    player.metadata.skills = { mining = { xp = QBSkills.xpForLevel(Config.maxLevel) } }
    harness.equal(registeredExports.isLevel(1, 'mining', Config.maxLevel), false,
        'server checks must use the private SQL-backed cache, not metadata')
end)

harness.test('skill check options use authoritative cached progression', function()
    storedSkills.mining = QBSkills.makeSkill('mining', QBSkills.xpForLevel(Config.maxLevel))
    fire('QBCore:Server:OnPlayerUnload', 1)
    player.metadata.skills = nil
    local options = registeredExports.getSkillCheckOptions(1, 'mining', 'skillbar', {
        zoneSize = 0.1,
        attempts = 1,
    })
    harness.truthy(math.abs(options.zoneSize - 0.24) < 0.000001,
        'a level cap mining bonus should widen the skillbar by its configured amount')
    harness.equal(options.attempts, 1, 'skill configuration must not alter attempts')
end)

if harness.failures > 0 then os.exit(1) end
