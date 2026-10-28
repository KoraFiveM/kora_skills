fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'kora_skills'
-- Keep the legacy resource name resolvable for exports['qbskills'] callers.
provide 'qbskills'
author 'qbcore2'
version '0.1.0'
description 'Config-driven XP skills with qblib AppShell progression graphs'

dependency 'kora_lib'
dependency 'kora_theme'
dependency 'kora_core'
dependency 'kora_sql'

shared_script '@kora_lib/init.lua'
shared_script '@kora_sql/init.lua'

shared_scripts {
    'config.lua',
    'shared/curve.lua',
}

server_scripts {
    'server/database.lua',
    'server/main.lua',
}
client_script 'client/main.lua'
