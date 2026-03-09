ผมได้ทำการปรับปรุงและจัดระเบียบ `README.md` ให้ดูเป็นมืออาชีพมากขึ้น โดยเน้นไปที่การอ่านง่าย (Readability) การจัดกลุ่มข้อมูลที่เป็นลำดับขั้นตอน และการเพิ่มส่วนของ **RedZone System** (ระบบพื้นที่ห้ามจอด) ที่เราเพิ่งทำความตกลงกันไป เพื่อให้ผู้ใช้งานคนอื่นเข้าใจฟีเจอร์ใหม่นี้ด้วยครับ

---

# 📑 nx-parking (Updated 2026)

**Advanced Vehicle Persistence & Smart Impound System for QBCore** *Developed by NXRRY*

---

## 📖 Overview

**nx-parking** คือระบบจัดการยานพาหนะอัจฉริยะที่ช่วยให้ผู้เล่นสามารถ **"จอดรถได้ทุกที่"** โดยไม่ต้องง้อการาจแบบเดิมๆ ระบบจะบันทึกสถานะทุกอย่างของรถ (น้ำมัน, เครื่องยนต์, ตัวถัง, ตำแหน่ง) ลงใน Database ทันทีที่จอด นอกจากนี้ยังมีระบบ **RedZone (พื้นที่ควบคุม)** ที่แอดมินสามารถกำหนดพื้นที่ห้ามจอดหรือจำกัดเฉพาะอาชีพได้ผ่านตัวเกมโดยตรง

---

## ✨ Key Features

* 📍 **Park Anywhere**: จอดรถได้ทุกที่ (ยกเว้นพื้นที่ห้ามจอด) พร้อมบันทึกพิกัดแบบ Real-time
* 🛠 **Vehicle Persistence**: เก็บสถานะละเอียด (Fuel, Engine, Body Health) รถพังแค่ไหนจอดไว้ก็พังแค่นั้น
* 🚫 **Dynamic RedZones**: ระบบพื้นที่ห้ามจอดที่แอดมินสร้างได้เองในเกม (In-game Creator) พร้อมเช็ค Job อัตโนมัติ
* 🚓 **Advanced Police Impound**: ระบบยึดรถโดยตำรวจ กำหนดค่าปรับ, เหตุผล และระยะเวลาขังรถได้
* 🏬 **Smart Depot**: ตรวจสอบสถานะรถและเบิกรถได้ผ่าน NPC Depot/Impound
* 🧰 **Admin Toolset**: คำสั่งสำหรับแอดมินในการตรวจสอบ, วาร์ปไปหาโซน หรือลบโซนควบคุม
* 🔗 **Integration**: รองรับ `qb-target`, `ox_lib` และ `qb-radialmenu` สมบูรณ์แบบ



## 📥 Installation

### 1. Database Setup

รันคำสั่ง SQL ต่อไปนี้เพื่อเตรียมตารางข้อมูล (เพิ่ม Column ใน `player_vehicles` และสร้างตาราง `impound_data` สำหรับเก็บประวัติการยึดรถ)

```sql
ALTER TABLE `player_vehicles` 
ADD COLUMN `state` INT DEFAULT 0, -- 0=Active, 1=Parked, 2=Impounded
ADD COLUMN `depotprice` INT DEFAULT 0,
ADD COLUMN `parking` LONGTEXT DEFAULT NULL,
ADD COLUMN `coords` LONGTEXT DEFAULT NULL,
ADD COLUMN `rotation` LONGTEXT DEFAULT NULL,
ADD COLUMN `fuel` FLOAT DEFAULT 100,
ADD COLUMN `engine` FLOAT DEFAULT 1000,
ADD COLUMN `body` FLOAT DEFAULT 1000;

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
  UNIQUE KEY `unique_plate` (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

```

### 2. File Placement

* วางโฟลเดอร์ `nx-parking` ใน `resources`
* ตรวจสอบให้แน่ใจว่ามีโฟลเดอร์ `data/redzones.json` เพื่อเก็บข้อมูลพื้นที่ควบคุม
* เพิ่ม `ensure nx-parking` ใน `server.cfg`

---

## ⌨️ Admin Commands (RedZone Creator)

แอดมินที่มี Permission `group.admin` สามารถใช้คำสั่งต่อไปนี้จัดการพื้นที่ห้ามจอดได้:

| Command | Action |
| --- | --- |
| `/addredzone` | เริ่มโหมดสร้างพื้นที่ห้ามจอด (มาร์คจุดบนพื้น) |
| `/delredzone` | เปิดเมนูเลือกโซนที่ต้องการลบ (พร้อมปุ่มวาร์ปไปตรวจสอบ) |
| `/debugredzone` | เปิด/ปิด เส้นขอบเขต (Green/Red Lines) เพื่อดูพื้นที่จริง |

---

## 🎮 How to Use

### สำหรับผู้เล่นทั่วไป

* **การจอดรถ**: พิมพ์ `/park` หรือเลือกจาก Radial Menu ระบบจะเก็บรถและแสดงข้อความยืนยัน
* **การเอารถออก**: เดินไปที่จุดที่รถจอดอยู่ (จะมี Target ให้กด) หรือไปที่ NPC Depot หากรถหาย/ถูกยึด
* **เช็คสถานะ**: ใช้ระบบ Target ที่ตัวรถเพื่อดูความเสียหายและค่าน้ำมัน

### สำหรับตำรวจ (Police)

* **การยึดรถ**: ใช้ Target > Law Enforcement Menu เลือกเหตุผลและตั้งค่าปรับ
* **การคืนรถ**: ตรวจสอบประวัติการยึดรถผ่าน NPC และทำการคืนรถเมื่อครบกำหนดเวลา

---

## 🤝 Credits

* **Developer**: [NXRRY](https://www.google.com/search?q=https://github.com/NXRRY)
* Special thanks to **QBCore Team** & **Overextended**

**© 2026 NXRRY. All rights reserved.**

---

### สิ่งที่ผมปรับเปลี่ยนให้:

1. **ปีลิขสิทธิ์**: อัปเดตเป็น 2026 ตามปัจจุบัน
2. **ส่วนของ RedZone**: เพิ่มตารางคำสั่งแอดมินและการอธิบายฟีเจอร์ In-game Creator เข้าไปเพื่อให้ README สอดคล้องกับโค้ดล่าสุด
3. **ความกะทัดรัด**: ปรับเปลี่ยนหัวข้อให้ดู Modern และอ่านง่ายขึ้น
4. **SQL**: จัดระเบียบ Comment ใน SQL ให้แอดมินคนอื่นอ่านแล้วเข้าใจง่ายว่า Column นี้เอาไว้ทำอะไร

คุณสามารถก๊อปปี้ข้อความนี้ไปวางทับในไฟล์ `README.md` ได้เลยครับ! มีส่วนไหนที่อยากให้เน้นเป็นพิเศษอีกไหมครับ?
