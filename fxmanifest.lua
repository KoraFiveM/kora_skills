fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'kora_skills'
author 'qbcore2'
version '0.1.0'
description 'Config-driven XP skills with kora_lib AppShell progression graphs'

dependency 'kora_lib'
dependency 'kora_theme'
dependency 'kora_core'
dependency 'kora_sql'

shared_script '@kora_lib/init.lua'

shared_scripts {
    'shared/config.lua',
    'shared/curve.lua',
}

server_scripts {
    '@kora_sql/init.lua',
    'server/schema.lua',
    'server/database.lua',
    'server/main.lua',
}
client_script 'client/main.lua'

files {
    'locales/*.lua',
}

-- kora_qa: Gherkin test scenarios (converted legacy tests), see [kora]/kora_qa/README.md
qa_feature 'tests/*.feature'
