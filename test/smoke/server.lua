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

local callbacks = {}
_G.Kora = { callback = { register = function(name, fn) callbacks[name] = fn end } }
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
    kora_core = {
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
dofile(arg[1] or resourceRoot .. 'server/main.lua')

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

harness.test('pending profile reads cannot outlive unload or drop cleanup', function()
    local originalLoad = QBSkillsDatabase.load
    local originalGetter = exports.kora_core.getPlayer
    local originalMetadata = exports.kora_core.setMetaData
    local originalSync = exports.kora_core.setPlayerDataField
    local writes = 0
    exports.kora_core.getPlayer = function(_, source)
        if source ~= 1 or not player then return nil end
        -- Actual Core exports a fresh snapshot; table identity must not identify a session.
        return { citizenid = player.citizenid, metadata = player.metadata }
    end
    exports.kora_core.setMetaData = function(_, _, key, value)
        writes = writes + 1
        if not player then return false, 'no such player' end
        player.metadata[key] = value
        return true
    end
    exports.kora_core.setPlayerDataField = function(_, _, _, value)
        writes = writes + 1
        if not player then return false, 'no such player' end
        replicated = value
        return true
    end
    for _, case in ipairs({ 'different-character', 'unload-empty', 'drop-empty', 'unload-notification', 'same-cid-unload', 'same-cid-drop' }) do
        fire('QBCore:Server:OnPlayerUnload', 1)
        player = { citizenid = 'TEST', metadata = { skills = { fishing = { xp = 5 } } } }
        local level, held = 15, true
        QBSkillsDatabase.load = function()
            local snapshot = QBSkills.normalise({ fishing = { xp = QBSkills.xpForLevel(level) } })
            if held then held = false; coroutine.yield('profile-read') end
            return snapshot
        end
        local thread = coroutine.create(function() return registeredExports.getRep(1, 'fishing') end)
        local ok, marker = coroutine.resume(thread)
        harness.truthy(ok, marker); harness.equal(marker, 'profile-read')
        fire(case:find('drop', 1, true) and 'qbcore:server:playerDropped' or 'QBCore:Server:OnPlayerUnload', 1)
        if case == 'unload-empty' or case == 'drop-empty' then
            player = nil
        elseif case == 'different-character' then
            player = { citizenid = 'NEXT', metadata = {} }; level = 1
            replicated = registeredProvider(1, 'NEXT')
            player.metadata.skills = { marker = 'CURRENT' }
        elseif case == 'unload-notification' then
            player.metadata.skills = { marker = 'CURRENT' }
        else
            player = { citizenid = 'TEST', metadata = {} }; level = 30
            replicated = registeredProvider(1, 'TEST')
            player.metadata.skills = { marker = 'CURRENT' }
        end
        local before, beforeReplicated = writes, replicated
        local value, err
        ok, value, err = coroutine.resume(thread)
        harness.truthy(ok, value)
        harness.equal(coroutine.status(thread), 'dead')
        harness.equal(value, nil, case .. ' must reject the old read')
        harness.equal(err, 'player has no active character', case .. ' preserves nil,error contract')
        harness.equal(writes, before, case .. ' must not clear metadata or synchronize')
        harness.equal(replicated, beforeReplicated, case .. ' preserves the current read model')
        if player then
            harness.equal(player.metadata.skills.marker, 'CURRENT', case .. ' preserves current metadata')
            if case ~= 'unload-notification' then
                harness.equal(registeredExports.getRep(1, 'fishing').level, level, case .. ' keeps current session cache')
            end
        end
    end
    -- An incomplete cache marker must not suppress retry or concurrent active reads.
    fire('QBCore:Server:OnPlayerUnload', 1)
    player = { citizenid = 'TEST', metadata = {} }
    QBSkillsDatabase.load = function() return nil, 'controlled read failure' end
    local value, err = registeredExports.getRep(1, 'fishing')
    harness.equal(value, nil); harness.equal(err, 'controlled read failure')
    local held = true
    QBSkillsDatabase.load = function()
        if held then held = false; coroutine.yield('profile-read') end
        return QBSkills.normalise({ fishing = { xp = QBSkills.xpForLevel(15) } })
    end
    local thread = coroutine.create(function() return registeredExports.getRep(1, 'fishing') end)
    local ok, marker = coroutine.resume(thread)
    harness.truthy(ok, marker); harness.equal(marker, 'profile-read')
    harness.equal(registeredExports.getRep(1, 'fishing').level, 15, 'parallel active read still loads')
    ok, value, err = coroutine.resume(thread)
    harness.truthy(ok, value); harness.equal(value.level, 15); harness.equal(err, nil)
    QBSkillsDatabase.load = originalLoad
    exports.kora_core.getPlayer = originalGetter
    exports.kora_core.setMetaData = originalMetadata
    exports.kora_core.setPlayerDataField = originalSync
end)

harness.test('the getAll callback is registered and returns the session skills', function()
    fire('QBCore:Server:OnPlayerUnload', 1)
    player = { citizenid = 'TEST', metadata = {} }
    storedSkills = QBSkills.normalise({ mining = { xp = 70 } })
    local getAll = callbacks['kora_skills:server:getAll']
    harness.truthy(getAll, 'getAll callback should be registered')
    local loads, originalLoad = 0, QBSkillsDatabase.load
    QBSkillsDatabase.load = function(...) loads = loads + 1; return originalLoad(...) end
    local skills = getAll(1)
    harness.equal(skills.mining.xp, 70)
    getAll(1); getAll(1)
    harness.equal(loads, 1, 'repeat UI opens are served from the session cache')
    registeredExports.addRep(1, 'mining', 5)
    harness.equal(getAll(1).mining.xp, 75, 'getAll reflects awards without reloading')
    harness.equal(loads, 1)
    QBSkillsDatabase.load = originalLoad
    harness.equal(getAll(2), nil, 'a source without a character gets nil')
end)

harness.test('a contended award waits without a per-frame spin', function()
    local waits = {}
    local ran = false
    _G.Wait = function(ms) waits[#waits + 1] = ms; coroutine.yield() end
    local first = coroutine.create(function()
        local load = QBSkillsDatabase.addXp
        QBSkillsDatabase.addXp = function(...) coroutine.yield('held'); return load(...) end
        local ok = registeredExports.addRep(1, 'mining', 1)
        QBSkillsDatabase.addXp = load
        return ok
    end)
    harness.equal(select(2, coroutine.resume(first)), 'held')
    local second = coroutine.create(function() ran = registeredExports.addRep(1, 'mining', 1) end)
    coroutine.resume(second)
    harness.equal(waits[1], 10, 'the lock is polled every 10 ms, not every frame')
    coroutine.resume(first)
    coroutine.resume(second)
    harness.truthy(ran, 'the queued award completes after the lock is released')
end)

if harness.failures > 0 then os.exit(1) end
