fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'qbskills'
author 'qbcore2'
version '0.1.0'
description 'Config-driven XP skills with qblib AppShell progression graphs'

dependency 'qblib'
dependency 'qbtheme'
dependency 'qbcore'

shared_script '@qblib/init.lua'

shared_scripts {
    'config.lua',
    'shared/curve.lua',
}

server_script 'server/main.lua'
client_script 'client/main.lua'
