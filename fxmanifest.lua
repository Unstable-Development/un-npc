fx_version 'cerulean'
game 'gta5'

author 'Unstable Development'
description 'Comprehensive NPC system: hunters, guards, patrols, bodyguards, scenarios, AI behaviors'
version '3.1.0'

shared_script 'config.lua'

client_scripts {
    'client.lua',
    'client_builders.lua', -- Zone and route builder tools
    'client_features.lua'  -- Warning system, AI behaviors, templates
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config.lua',
    'server.lua',
    'server_sql.lua' -- SQL database handler
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}
