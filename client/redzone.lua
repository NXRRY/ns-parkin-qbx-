local PlayerData = exports.qbx_core:GetPlayerData()
local CreatedZones = {}
local storedZoneData = {}
local isDebugEnabled = false
insidenoParkingZone = false

-- ============================
-- 1. HELPERS & UI HANDLING
-- ============================

local function isJobAllowed(allowJobs)
    if not allowJobs or next(allowJobs) == nil then return false end
    if not PlayerData or not PlayerData.job then return false end
    return allowJobs[PlayerData.job.name] ~= nil
end

local function formatAllowedJobList(allowJobs)
    if not allowJobs or next(allowJobs) == nil then return "ทุกคนห้ามจอด" end
    local jobs = {}
    for jobName, _ in pairs(allowJobs) do
        jobs[#jobs + 1] = jobName:gsub("^%l", string.upper)
    end
    return table.concat(jobs, ", ")
end

local function handleZoneUI(zoneData, isInside)
    if isInside then
        local isAllowed = isJobAllowed(zoneData.allowJobs)
        insidenoParkingZone = not isAllowed

        local statusColor = isAllowed and "#2ecc71" or "#ff4d4d"
        local statusIcon = isAllowed and "square-check" or "circle-exclamation"
        local allowedList = formatAllowedJobList(zoneData.allowJobs)

        local msg = string.format("# %s  \n---\n%s", 
            zoneData.title or "พื้นที่ควบคุม", 
            isAllowed and "✅ คุณได้รับอนุญาตให้จอดรถ" or "❌ พื้นที่ห้ามจอด (ยกเว้น: "..allowedList..")"
        )

        lib.showTextUI(msg, {
            position = "bottom-center",
            icon = statusIcon,
            style = {
                borderRadius = '12px',
                backgroundColor = 'rgba(10, 10, 10, 0.9)',
                color = '#ffffff',
                borderBottom = '4px solid ' .. statusColor,
                padding = '15px 25px',
            }
        })
    else
        insidenoParkingZone = false
        lib.hideTextUI()
    end
end

-- ============================
-- 2. ZONE LOGIC (CREATE / REMOVE)
-- ============================

local function createRedZone(data)
    if CreatedZones[data.name] then 
        CreatedZones[data.name]:remove() 
    end
    
    storedZoneData[data.name] = data

    local formattedPoints = {}
    for i = 1, #data.points do
        local p = data.points[i]
        formattedPoints[i] = vec3(p.x, p.y, data.minZ or 0.0)
    end

    local zone = lib.zones.poly({
        points = formattedPoints,
        thickness = (data.maxZ - data.minZ),
        debug = isDebugEnabled,
        onEnter = function() handleZoneUI(data, true) end,
        onExit = function() handleZoneUI(data, false) end
    })

    CreatedZones[data.name] = zone
end

RegisterNetEvent('parking:client:removeZone', function(zoneName)
    if CreatedZones[zoneName] then
        CreatedZones[zoneName]:remove()
        CreatedZones[zoneName] = nil
        storedZoneData[zoneName] = nil
        lib.notify({description = 'ลบโซน '..zoneName..' สำเร็จ', type = 'inform'})
    end
end)

-- ============================
-- 3. CORE SYNC & UPDATES
-- ============================

RegisterNetEvent('parking:client:syncAllZones', function(zones)
    for _, zoneData in ipairs(zones) do
        createRedZone(zoneData)
    end
end)

RegisterNetEvent('parking:client:addNewZone', function(zoneData)
    createRedZone(zoneData)
    lib.notify({description = 'เพิ่ม RedZone ใหม่สำเร็จ', type = 'success'})
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = exports.qbx_core:GetPlayerData()
    TriggerServerEvent('parking:server:requestZones')
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)

AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() ~= resource then return end
    TriggerServerEvent('parking:server:requestZones')
end)

-- ============================
-- 4. ADMIN FEATURES (CREATOR)
-- ============================

RegisterNetEvent('parking:client:startCreatingZone', function()
    local points = {}
    local isCreating = true

    lib.showTextUI("**🟥 สร้าง RedZone** \n[E] มาร์คจุด [G] บันทึก [X] ยกเลิก", {
        position = "left-center",
        icon = 'draw-polygon',
        style = {
            borderRadius = '8px',
            backgroundColor = 'rgba(26, 26, 26, 0.8)',
            color = '#ffffff',
            borderLeft = '4px solid #ff4d4d',
            padding = '10px'
        }
    })

    CreateThread(function()
        while isCreating do
            Wait(0)
            local coords = GetEntityCoords(PlayerPedId())
            
            DrawMarker(28, coords.x, coords.y, coords.z - 0.9, 0,0,0,0,0,0, 0.2,0.2,0.2, 255, 0, 0, 200, false, false, 2, nil, nil, false)

            if #points > 0 then
                for i = 1, #points do
                    DrawMarker(28, points[i].x, points[i].y, coords.z - 0.9, 0,0,0,0,0,0, 0.15,0.15,0.15, 255, 255, 255, 150, false, false, 2, nil, nil, false)
                    if points[i+1] then
                        DrawLine(points[i].x, points[i].y, coords.z - 0.9, points[i+1].x, points[i+1].y, coords.z - 0.9, 255, 255, 255, 255)
                    end
                end
            end

            -- [E] มาร์คจุด
            if IsControlJustReleased(0, 38) then 
                table.insert(points, vector2(coords.x, coords.y))
                PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
                lib.notify({description = 'วางจุดที่ ' .. #points, type = 'inform'})
            end

            -- [G] บันทึก
            if IsControlJustReleased(0, 47) then 
                if #points < 3 then
                    lib.notify({description = 'ต้องมีอย่างน้อย 3 จุด!', type = 'error'})
                else
                    isCreating = false
                end
            end

            -- [X] ยกเลิก
            if IsControlJustReleased(0, 73) then 
                isCreating = false
                points = {}
                lib.hideTextUI()
                lib.notify({description = 'ยกเลิกการสร้าง', type = 'error'})
                return
            end
        end

        lib.hideTextUI()

        if #points >= 3 then
            local input = lib.inputDialog('ตั้งค่า RedZone ใหม่', {
                {type = 'input', label = 'ID โซน (ภาษาอังกฤษ)', placeholder = 'police_area', required = true},
                {type = 'input', label = 'ชื่อที่แสดง (TextUI)', default = 'พื้นที่ห้ามจอด'},
                {type = 'number', label = 'ความสูงพื้น (Min Z)', default = GetEntityCoords(PlayerPedId()).z - 1.0},
                {type = 'number', label = 'ความสูงเพดาน (Max Z)', default = GetEntityCoords(PlayerPedId()).z + 10.0},
                {type = 'input', label = 'อาชีพที่ยกเว้น (คั่นด้วยคอมม่า)', placeholder = 'police, ambulance'},
            })

            if input then
                local allowed = {}
                if input[5] ~= "" then
                    for job in string.gmatch(input[5], '([^, ]+)') do
                        allowed[job] = true
                    end
                end

                TriggerServerEvent('parking:server:saveNewZone', {
                    name = input[1],
                    title = input[2],
                    points = points,
                    minZ = input[3],
                    maxZ = input[4],
                    allowJobs = allowed
                })
            end
        end
    end)
end)

-- ============================
-- 5. ADMIN FEATURES (DEBUG & MENU)
-- ============================

RegisterNetEvent('parking:client:toggleDebug', function()
    isDebugEnabled = not isDebugEnabled
    for name, data in pairs(storedZoneData) do createRedZone(data) end
    lib.notify({
        description = 'โหมด Debug: '..(isDebugEnabled and 'เปิด' or 'ปิด'), 
        type = isDebugEnabled and 'inform' or 'error'
    })
end)

RegisterNetEvent('parking:client:openDeleteMenu', function(zones)
    local options = {}

    for i, zone in ipairs(zones) do
        -- คำนวณจุดศูนย์กลาง
        local centerX, centerY = 0, 0
        for _, p in ipairs(zone.points) do
            centerX = centerX + p.x
            centerY = centerY + p.y
        end
        local targetPos = vec3(centerX / #zone.points, centerY / #zone.points, zone.minZ + 1.0)
        local allowedStr = formatAllowedJobList(zone.allowJobs)

        table.insert(options, {
            title = '📍 ' .. (zone.title or zone.name),
            description = string.format('ID: %s\nยกเว้น: %s', zone.name, allowedStr),
            icon = 'location-dot',
            arrow = true,
            onSelect = function()
                lib.registerContext({
                    id = 'redzone_manage_' .. zone.name,
                    title = zone.name,
                    menu = 'redzone_delete_menu',
                    options = {
                        {
                            title = 'วาร์ปไปตรวจสอบ (Teleport)',
                            icon = 'street-view',
                            onSelect = function()
                                DoScreenFadeOut(500)
                                Wait(500)
                                SetEntityCoords(PlayerPedId(), targetPos.x, targetPos.y, targetPos.z)
                                Wait(500)
                                DoScreenFadeIn(500)
                            end
                        },
                        {
                            title = 'ลบโซนนี้',
                            icon = 'trash-can',
                            iconColor = '#ff4d4d',
                            onSelect = function()
                                local alert = lib.alertDialog({
                                    header = 'ยืนยันการลบ',
                                    content = 'คุณต้องการลบโซน **' .. zone.name .. '** หรือไม่?',
                                    centered = true,
                                    cancel = true
                                })
                                if alert == 'confirm' then
                                    TriggerServerEvent('parking:server:deleteZone', zone.name)
                                end
                            end
                        }
                    }
                })
                lib.showContext('redzone_manage_' .. zone.name)
            end
        })
    end

    lib.registerContext({
        id = 'redzone_delete_menu',
        title = '🗑️ จัดการ RedZones',
        options = options
    })
    lib.showContext('redzone_delete_menu')
end)