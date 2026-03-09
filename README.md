# nx-parking  
**Advanced Parking System for FiveM (QBCore / Qbox)**  
*Developed by NXRRY*

---

## 📌 Description  
nx-parking is an intelligent parking system that allows players to **park their vehicle anywhere** (not limited to garages). The system saves the vehicle’s condition (fuel, engine, body health) and last known location in the database. Parked vehicles are hidden and can be retrieved at any time via a menu, or through depot NPCs.  

The system fully supports:
- **Job‑restricted parking zones** (RedZones) – only authorised jobs can park in certain areas.
- **Police impound** with reasons, fines, and duration – vehicles are marked as impounded and stored in a separate table.
- **Public depot** for vehicles sent by police or players with unpaid fees.
- **Admin tools** to create, delete, and debug RedZones in‑game using **ox_lib** menus and zones.
- **Radial menu** (built with **ox_lib**) for quick access to park and vehicle list.
- **Target interaction** using **ox_target** to check status, retrieve, or impound vehicles.
- **ox_lib notifications, progress circles, input dialogs, and context menus** throughout.
- **Automatic version check** to keep your server up‑to‑date.

---

## ✨ Key Features  
- ✅ Park anywhere (outside restricted zones)  
- ✅ Saves vehicle condition (fuel, engine, body, location)  
- ✅ RedZones with job restrictions (configurable via in‑game commands)  
- ✅ Vehicle status check (ownership, engine health, fuel, depot fee)  
- ✅ Police impound system with custom reasons, fines, and release time  
- ✅ Send vehicle to public depot  
- ✅ Retrieve vehicles from depot/impound via NPC  
- ✅ Set GPS to parked vehicle location  
- ✅ Radial menu (ox_lib)  
- ✅ Target interaction (ox_target)  
- ✅ Admin commands to manage RedZones  
- ✅ Automatic version check  
- ✅ Fully localised strings (Thai included, easily customisable)

---

## 🔧 Dependencies  
- **[Qbox / qbx_core](https://github.com/Qbox-project/qbx_core)** (or QBCore with ox_lib compatibility)  
- **[ox_lib](https://github.com/overextended/ox_lib)** – used for notifications, radial menu, context menus, progress circles, input dialogs, and zone management  
- **[ox_target](https://github.com/overextended/ox_target)** – for interacting with vehicles and NPCs  
- **[LegacyFuel](https://github.com/InZidiuZ/LegacyFuel)** (or any compatible fuel system)  

> **Note:** The script does **not** require `qb-radialmenu`, `qb-target`, or `PolyZone` separately – all functionality is provided by **ox_lib** and **ox_target**.

---

## 📥 Installation  

### 1. Download and Place Files  
- Download the script from GitHub  
- Place the `nx-parking` folder in your server's `resources` directory  

### 2. Database Setup  
Run the following SQL queries in your server database.  
(Ensure the `player_vehicles` table exists; if not, create it as per Qbox/QBCore standards.)

```sql
-- Add required columns to player_vehicles (if not present)
ALTER TABLE `player_vehicles` 
ADD COLUMN `state` INT DEFAULT 0, -- 0 = active, 1 = parked, 2 = impounded
ADD COLUMN `depotprice` INT DEFAULT 0,
ADD COLUMN `parking` LONGTEXT DEFAULT NULL,
ADD COLUMN `coords` LONGTEXT DEFAULT NULL,
ADD COLUMN `rotation` LONGTEXT DEFAULT NULL,
ADD COLUMN `fuel` FLOAT DEFAULT 100,
ADD COLUMN `engine` FLOAT DEFAULT 1000,
ADD COLUMN `body` FLOAT DEFAULT 1000;

-- Create impound_data table for impound history
CREATE TABLE IF NOT EXISTS `impound_data` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `plate` VARCHAR(10) NOT NULL,
  `vehicle_model` VARCHAR(50),
  `charge_name` VARCHAR(100),
  `fee` INT DEFAULT 0,
  `impound_time` INT DEFAULT 0,
  `officer_name` VARCHAR(100),
  `release_time` TIMESTAMP NULL,
  `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_plate` (`plate`),
  UNIQUE KEY `unique_plate` (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 3. Add to server.cfg  
```
ensure nx-parking
```

---

## ⚙️ Configuration (config.lua)  

The main configuration options in `config.lua`:

| Variable | Description |
|----------|-------------|
| `Config.Debug` | Enable/disable debug logging |
| `Config.EnableParkCommand` | Enable `/park` command |
| `Config.notifyType` | Notification style: `'ox'` (recommended), `'qb'`, or `'chat'` |
| `Config.DefaultSpawnCoords` | Default spawn coordinates if no vehicle data |
| `Config.Depot` | List of depot locations (NPC, spawn points, blip, marker) |
| `Config.Impound` | Citizen and Officer impound NPCs, spawn coordinates |
| `Config.ImpoundReasons` | Impound reasons with fines and duration (used by police) |
| `Config.Strings` | All UI strings (customisable, Thai included) |

### Example: Adding a Depot
```lua
Config.Depot = {
    {
        name = "Legion Depot",
        coords = vector4(408.63, -1623.13, 29.29, 228.48),
        spawnPoint = { vector4(...), ... },
        marker = { ... },
        blip = { ... }
    }
}
```


### Example: Impound Reasons
```lua
Config.ImpoundReasons = {
    { label = 'จอดในที่ห้ามจอด ($500 / 30 mins)', value = 'illegal_parking', price = 500, time = 30 },
    ...
}
```

### Customizing Strings  
All text displayed to players is located in `Config.Strings`. You can modify them to match your server's language or preference.

---

## 🎮 Usage  

### For Regular Players  
- **Park Vehicle**: Drive to desired spot, then use Radial Menu (ox_lib) > "Park Vehicle" or type `/park` (must be stationary and driver).  
- **View Vehicle List**: Radial Menu > "Vehicle List" or type `/parklish` (if enabled).  
- **Retrieve Parked Vehicle**: Approach a parked vehicle (target appears) → "Retrieve Vehicle".  
- **Check Vehicle Status**: Approach vehicle → Target > "Check Vehicle Status".  
- **Retrieve from Depot**: Go to Depot NPC → "View Pending Vehicles".  
- **Retrieve Impounded Vehicle**: Go to Impound NPC → "Contact Impound Officer" (if release time has passed).  

### For Police / Officers  
- **Impound Vehicle**: Approach target vehicle → Target > "🛡️ Law Enforcement Menu" → choose action (Impound/Depot) and reason.  
- **Check Citizen Impound Records**: Go to "Impound Officer" NPC → "Search Impound Records" → select nearby citizen.  
- **Release Vehicle**: When impound time expires, officer can release the vehicle directly to the owner via the same menu.  

### For Admins (Managing RedZones)  
- **Create a RedZone**: `/addredzone` – then follow on‑screen instructions (place points with E, save with G, cancel with X). Uses ox_lib text UI and input dialogs.  
- **Delete a RedZone**: `/delredzone` – opens an ox_lib context menu to teleport to or delete existing zones.  
- **Toggle Debug Polygons**: `/debugredzone` – shows/hides the outlines of all RedZones (ox_lib zone debug).  

---

## ⌨️ Commands  
- `/park` – Park the current vehicle (if enabled)  
- `/parklish` – Open vehicle list (alternative to radial menu)  
- `/addredzone` – (Admin) Start creating a new RedZone  
- `/delredzone` – (Admin) Open RedZone deletion/management menu  
- `/debugredzone` – (Admin) Toggle debug drawing of RedZones  

---

## 🗂️ Database Structure (Additional Columns)  

### Table `player_vehicles` (extended)
| Column | Type | Description |
|--------|------|-------------|
| `state` | INT | 0=active, 1=parked, 2=impounded |
| `depotprice` | INT | Fee required before retrieval |
| `parking` | JSON | Parking info (timestamp, location) |
| `coords` | JSON | Last known coordinates |
| `rotation` | JSON | Vehicle rotation |
| `fuel` | FLOAT | Fuel level |
| `engine` | FLOAT | Engine health |
| `body` | FLOAT | Body health |

### Table `impound_data`
| Column | Type | Description |
|--------|------|-------------|
| `plate` | VARCHAR | License plate |
| `vehicle_model` | VARCHAR | Vehicle model name |
| `charge_name` | VARCHAR | Impound reason |
| `fee` | INT | Fine amount |
| `impound_time` | INT | Impound duration (minutes) |
| `officer_name` | VARCHAR | Name of the officer |
| `release_time` | TIMESTAMP | Time when vehicle can be released |
| `timestamp` | TIMESTAMP | Record creation time |

---

## 📸 Screenshots  
![Screenshot](images/showcase.jpg)  

---

## 🤝 Credits  
- Developer: **NXRRY**  
- Powered by [ox_lib](https://github.com/overextended/ox_lib) and [ox_target](https://github.com/overextended/ox_target)  
- Thanks to Qbox / QBCore communities for their frameworks.  

---

## 🔗 Links  
- GitHub: [https://github.com/NXRRY/nx-parking](https://github.com/NXRRY/nx-parking)  
- Discord: *Coming soon*  

---

## ⚠️ Notes  
- This script is designed to work with **Qbox (qbx_core)** or **QBCore** that uses **ox_lib**.  
- If you encounter issues or have suggestions, please open an issue on GitHub.  

---

**© 2025 NXRRY. All rights reserved.**
