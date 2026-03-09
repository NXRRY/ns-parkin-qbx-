-- server/main.lua
local json_path = 'data/redzones.json'

-- โหลดข้อมูลจาก JSON เมื่อเริ่ม Resource
local function LoadRedZones()
    local file = LoadResourceFile(GetCurrentResourceName(), json_path)
    return file and json.decode(file) or {}
end

-- ส่งข้อมูลโซนให้ผู้เล่นที่เพิ่งเข้าเกม
RegisterNetEvent('parking:server:requestZones', function()
    local zones = LoadRedZones()
    TriggerClientEvent('parking:client:syncAllZones', source, zones)
end)

-- บันทึกโซนใหม่
RegisterNetEvent('parking:server:saveNewZone', function(zoneData)
    local zones = LoadRedZones()
    table.insert(zones, zoneData)
    
    SaveResourceFile(GetCurrentResourceName(), json_path, json.encode(zones, {indent = true}), -1)
    
    -- Sync ให้ทุกคนในเซิร์ฟเวอร์สร้างโซนทันที
    TriggerClientEvent('parking:client:addNewZone', -1, zoneData)
    print("^2[RedZone]^7 Saved new zone: " .. zoneData.name)
end)

-- ลบโซนออกจาก JSON
RegisterNetEvent('parking:server:deleteZone', function(zoneName)
    local zones = LoadRedZones()
    local found = false
    
    for i, zone in ipairs(zones) do
        if zone.name == zoneName then
            table.remove(zones, i)
            found = true
            break
        end
    end

    if found then
        SaveResourceFile(GetCurrentResourceName(), json_path, json.encode(zones, {indent = true}), -1)
        TriggerClientEvent('parking:client:removeZone', -1, zoneName) -- สั่งให้ Client ทุกคนลบโซนทิ้ง
        print("^1[RedZone]^7 Deleted zone: " .. zoneName)
    end
end)

-- 1. คำสั่งเพิ่ม RedZone
lib.addCommand('addredzone', {
    help = 'สร้างพื้นที่ห้ามจอดใหม่ (Admin Only)',
    restricted = 'group.admin' -- ล็อกเฉพาะยศ admin (ใช้ระบบ Ace Permissions)
}, function(source, args, raw)
    -- เมื่อยศผ่าน จะส่ง Event ไปให้ Client ของคนนั้นเริ่มกระบวนการมาร์คจุด
    TriggerClientEvent('parking:client:startCreatingZone', source)
end)


lib.addCommand('delredzone', {
    help = 'เปิดเมนูจัดการพื้นที่ห้ามจอด (Admin Only)',
    restricted = 'group.admin'
}, function(source, args, raw)
    local zones = LoadRedZones() -- โหลดข้อมูลจาก JSON
    if #zones == 0 then
        return TriggerClientEvent('ox_lib:notify', source, { description = 'ยังไม่มีโซนถูกสร้างไว้', type = 'error' })
    end
    TriggerClientEvent('parking:client:openDeleteMenu', source, zones)
end)

-- 3. คำสั่ง Debug
lib.addCommand('debugredzone', {
    help = 'เปิด/ปิด เส้นขอบพื้นที่ห้ามจอด (Admin Only)',
    restricted = 'group.admin'
}, function(source, args, raw)
    TriggerClientEvent('parking:client:toggleDebug', source)
end)