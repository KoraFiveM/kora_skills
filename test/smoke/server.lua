local scriptDir = debug.getinfo(1, 'S').source:match('@?(.*/)') or './'
local testDir = scriptDir .. '../'
local resourceRoot = testDir .. '../'
package.path = testDir .. '?.lua;' .. package.path

local harness = require('harness')
local callbacks, registeredExports, clientEvents = {}, {}, {}
local metadata = {}

_G.QB = {
    callback = {
        register = function(name, handler) callbacks[name] = handler end,
    },
}
_G.exports = setmetatable({
    qbcore = {
        getPlayer = function(_, source)
            return source == 1 and { citizenid = 'TEST' } or nil
        end,
        getMetaData = function(_, _, key)
            return metadata[key]
        end,
        setMetaData = function(_, _, key, value)
            metadata[key] = value
            return true
        end,
    },
}, {
    __call = function(_, name, fn) registeredExports[name] = fn end,
})
_G.TriggerClientEvent = function(name, source, payload)
    clientEvents[#clientEvents + 1] = { name = name, source = source, payload = payload }
end
_G.AddEventHandler = function() end

dofile(resourceRoot .. 'config.lua')
dofile(resourceRoot .. 'shared/curve.lua')
dofile(resourceRoot .. 'server/main.lua')

harness.test('skill reads backfill the metadata namespace through qbcore', function()
    local skills = registeredExports.getAllRep(1)
    harness.truthy(skills.mining ~= nil, 'configured skills should be returned')
    harness.truthy(metadata.skills ~= nil, 'the missing metadata namespace should be persisted')
    harness.equal(skills.mining.level, 1, 'new skills should begin at level one')
end)

harness.test('awards persist and synchronise the authoritative skill snapshot', function()
    local added, err = registeredExports.addRep(1, 'mining', 100)
    harness.truthy(added, err)
    harness.equal(metadata.skills.mining.xp, 100, 'the award should be persisted through qbcore metadata')
    local updated = false
    for _, event in ipairs(clientEvents) do
        if event.name == 'qbskills:client:skillsUpdated' then updated = true end
    end
    harness.truthy(updated, 'the client should receive the fresh snapshot')
    local rejected = registeredExports.addRep(1, 'mining', 0)
    harness.equal(rejected, false, 'zero XP must be rejected')
end)

harness.test('skill check options only adjust configured bounded fields', function()
    metadata.skills.mining = { xp = QBSkills.xpForLevel(Config.maxLevel) }
    local options = registeredExports.getSkillCheckOptions(1, 'mining', 'skillbar', {
        zoneSize = 0.1,
        attempts = 1,
    })
    harness.truthy(math.abs(options.zoneSize - 0.24) < 0.000001,
        'a level cap mining bonus should widen the skillbar by its configured amount')
    harness.equal(options.attempts, 1, 'skill configuration must not alter attempts')
end)

harness.test('the client read callback stays registered and scoped', function()
    harness.truthy(callbacks['qbskills:server:skillsRead'] ~= nil, 'the UI callback should be registered')
    local skills = callbacks['qbskills:server:skillsRead'](1)
    harness.truthy(skills.cooking ~= nil, 'the callback should only return the caller character skills')
end)

if harness.failures > 0 then os.exit(1) end
