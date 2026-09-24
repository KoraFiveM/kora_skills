local scriptDir = debug.getinfo(1, 'S').source:match('@?(.*/)') or './'
local testDir = scriptDir .. '../'
local resourceRoot = testDir .. '../'
package.path = testDir .. '?.lua;' .. package.path

local harness = require('harness')

dofile(resourceRoot .. 'config.lua')
dofile(resourceRoot .. 'shared/curve.lua')

harness.test('the curve starts at level one with zero XP', function()
    local mining = QBSkills.makeSkill('mining', 0)
    harness.equal(mining.level, 1, 'zero XP should be level one')
    harness.equal(mining.percent, 0, 'zero XP should have no progress')
    harness.equal(QBSkills.xpForLevel(1), 0, 'level one should require no XP')
end)

harness.test('the curve reaches and caps at the configured maximum level', function()
    local maximum = QBSkills.xpForLevel(Config.maxLevel)
    local mining = QBSkills.makeSkill('mining', maximum + 1000)
    harness.equal(mining.level, Config.maxLevel, 'excess XP should cap at max level')
    harness.equal(mining.percent, 100, 'the max level should show complete progress')
    harness.equal(mining.xp, maximum, 'stored XP should cap at the max-level threshold')
end)

harness.test('normalisation backfills every configured skill', function()
    local skills, changed = QBSkills.normalise({ mining = { xp = 100 } })
    harness.truthy(changed, 'a partial legacy record should be marked for persistence')
    harness.equal(#Config.skillOrder, 6, 'the default config should expose six skills')
    harness.truthy(skills.fishing ~= nil, 'missing configured skills should be backfilled')
    harness.equal(skills.mining.xp, 100, 'existing XP should survive normalisation')
end)

if harness.failures > 0 then os.exit(1) end
