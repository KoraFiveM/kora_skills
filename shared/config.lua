Config = {
    legacyMetadataKey = 'skills',
    maxLevel = 99,
    maxAward = 100000,
    command = 'skills',
    keyMapping = 'F4',

    skillOrder = { 'mining', 'smelting', 'fishing', 'crafting', 'cooking', 'metaldetecting', 'computing', 'hacking' },
    skills = {
        mining = {
            label = 'Mining', icon = 'Hammer',
            skillCheck = { skillbar = { zoneSize = 0.14 }, lockpick = { tolerance = 0.05 } },
        },
        smelting = { label = 'Smelting', icon = 'Flame' },
        fishing = {
            label = 'Fishing', icon = 'Activity',
            skillCheck = { skillbar = { zoneSize = 0.10 } },
        },
        crafting = {
            label = 'Crafting', icon = 'ShoppingBag',
            skillCheck = { circuit = { nodeCount = -2 } },
        },
        cooking = {
            label = 'Cooking', icon = 'Star',
            skillCheck = { skillbar = { zoneSize = 0.08 }, mash = { requiredPresses = -5 } },
        },
        metaldetecting = {
            label = 'Metal Detecting', icon = 'Search',
            skillCheck = { skillbar = { zoneSize = 0.10 } },
        },
        computing = {
            label = 'Computing', icon = 'Cpu',
            skillCheck = { circuit = { nodeCount = -3 }, hacking = { solutionsize = -1 } },
        },
        hacking = {
            label = 'Hacking', icon = 'Terminal',
            skillCheck = { hacking = { solutionsize = -1 }, circuit = { nodeCount = -1 } },
        },
    },
}
exports('GetSkillsData', function()
    local tbl = {}
    for k, v in pairs(Config.skills) do
        tbl[k] = v.label
    end
    return tbl
end)

if Kora and Kora.config and Kora.config.adopt then Config = Kora.config.adopt(Config) end
