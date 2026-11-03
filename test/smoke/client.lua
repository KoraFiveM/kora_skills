local scriptDir = debug.getinfo(1, 'S').source:match('@?(.*/)') or './'
local testDir = scriptDir .. '../'
local resourceRoot = testDir .. '../'
package.path = testDir .. '?.lua;' .. package.path

local harness = require('harness')
local commands, keybinds, rawMappings, opened = {}, {}, {}, 0

_G.exports = setmetatable({
    kora_core = {
        getPlayerData = function() return { skills = {} } end,
        onPlayerDataChange = function() end,
    },
}, { __call = function() end })
_G.Kora = {
    keybind = { add = function(options) keybinds[#keybinds + 1] = options; return {} end },
    callback = { trigger = function() opened = opened + 1; return nil, 'not ready' end },
    notify = { send = function() end },
    nui = { registerApp = function() end, openApp = function() end },
}
_G.RegisterCommand = function(name, fn) commands[name] = fn end
_G.RegisterKeyMapping = function(name) rawMappings[#rawMappings + 1] = name end
_G.RegisterNetEvent = function() end
_G.AddEventHandler = function() end

dofile(resourceRoot .. 'config.lua')
dofile(resourceRoot .. 'shared/curve.lua')
dofile(resourceRoot .. 'client/main.lua')

harness.test('the skills key goes through Kora.keybind and both commands stay', function()
    harness.equal(#rawMappings, 0, 'no raw RegisterKeyMapping')
    harness.equal(#keybinds, 1)
    harness.equal(keybinds[1].defaultKey, Config.keyMapping, 'default key comes from Config.keyMapping')
    harness.truthy(commands[Config.command], '/' .. Config.command .. ' still works')
    harness.truthy(commands.skillList, '/skillList alias still works')
    keybinds[1].onPressed({})
    commands.skillList()
    harness.equal(opened, 2, 'the key and the alias both open the panel')
end)

if harness.failures > 0 then os.exit(1) end
