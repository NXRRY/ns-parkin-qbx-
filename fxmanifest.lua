fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_fxv2_oal 'yes'
author 'NXRRY'
description 'A parking system for FiveM servers.'
version '1.0.1'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'config.lua'
}

server_script {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua',
}

client_scripts {
    '@PolyZone/client.lua',
    '@PolyZone/PolyZone.lua',
    '@PolyZone/BoxZone.lua',
    'client/*.lua'
}

files {
    'data/redzones.json'
}