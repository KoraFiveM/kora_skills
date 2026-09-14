Config = {
    -- Read once for the automatic metadata -> SQL migration. A per-character
    -- profile marker ensures later metadata writes can never be re-imported.
    legacyMetadataKey = 'skills',
    maxLevel = 99,
    maxAward = 100000,
    command = 'skills',
    keyMapping = 'F4',

    -- The ordering is explicit so the panel and exported data stay stable.
    skillOrder = { 'mining', 'fishing', 'woodcutting', 'crafting', 'cooking' },
    skills = {
        mining = {
            label = 'Mining', icon = 'Hammer',
            -- At level 99, this grants up to 0.14 more of the visible
            -- skillbar target. The server clamps it to qblib's safe bounds.
            skillCheck = { skillbar = { zoneSize = 0.14 }, lockpick = { tolerance = 0.05 } },
        },
        fishing = {
            label = 'Fishing', icon = 'Activity',
            skillCheck = { skillbar = { zoneSize = 0.10 } },
        },
        woodcutting = {
            label = 'Woodcutting', icon = 'Wrench',
            skillCheck = { skillbar = { zoneSize = 0.12 }, mash = { requiredPresses = -8 } },
        },
        crafting = {
            label = 'Crafting', icon = 'ShoppingBag',
            skillCheck = { circuit = { nodeCount = -2 } },
        },
        cooking = {
            label = 'Cooking', icon = 'Star',
            skillCheck = { skillbar = { zoneSize = 0.08 }, mash = { requiredPresses = -5 } },
        },
    },
}
