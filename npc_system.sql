-- Prelude NPC System Database
-- Run this file in your database to create the required tables

CREATE TABLE IF NOT EXISTS `npc_guard_zones` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL UNIQUE,
    `center_x` FLOAT NOT NULL,
    `center_y` FLOAT NOT NULL,
    `center_z` FLOAT NOT NULL,
    `radius` FLOAT NOT NULL DEFAULT 50.0,
    `guard_count` INT NOT NULL DEFAULT 5,
    `required_item` VARCHAR(50) DEFAULT NULL,
    `requires_identifier` VARCHAR(100) DEFAULT NULL,
    `ped_models` TEXT NOT NULL, -- JSON array
    `weapons` TEXT NOT NULL, -- JSON array
    `accuracy` INT NOT NULL DEFAULT 50,
    `health` INT NOT NULL DEFAULT 200,
    `armor` INT NOT NULL DEFAULT 100,
    `is_active` TINYINT(1) DEFAULT 0,
    `is_custom` TINYINT(1) DEFAULT 1, -- 0 = pre-configured, 1 = user-created
    `created_by` VARCHAR(50) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `npc_patrol_routes` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL UNIQUE,
    `guard_zone` VARCHAR(100) DEFAULT NULL,
    `vehicle_model` VARCHAR(50) NOT NULL,
    `ped_model` VARCHAR(50) NOT NULL,
    `weapon` VARCHAR(50) NOT NULL DEFAULT 'WEAPON_PISTOL',
    `speed` FLOAT NOT NULL DEFAULT 25.0,
    `waypoints` TEXT NOT NULL, -- JSON array of vector4
    `is_active` TINYINT(1) DEFAULT 0,
    `is_custom` TINYINT(1) DEFAULT 1,
    `created_by` VARCHAR(50) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `npc_guard_spawns` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `zone_id` INT NOT NULL,
    `ped_netid` INT DEFAULT NULL,
    `position_x` FLOAT NOT NULL,
    `position_y` FLOAT NOT NULL,
    `position_z` FLOAT NOT NULL,
    `heading` FLOAT NOT NULL DEFAULT 0.0,
    `spawned_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`zone_id`) REFERENCES `npc_guard_zones`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `npc_patrol_spawns` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `route_id` INT NOT NULL,
    `vehicle_netid` INT DEFAULT NULL,
    `ped_netid` INT DEFAULT NULL,
    `current_waypoint` INT DEFAULT 0,
    `spawned_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`route_id`) REFERENCES `npc_patrol_routes`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `npc_presets` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL UNIQUE,
    `description` TEXT,
    `preset_data` LONGTEXT NOT NULL, -- JSON containing zones and patrols
    `created_by` VARCHAR(50) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `is_public` TINYINT(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `npc_zone_access_log` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `zone_id` INT NOT NULL,
    `player_identifier` VARCHAR(100) NOT NULL,
    `player_name` VARCHAR(100),
    `action` VARCHAR(50) NOT NULL, -- 'entered', 'denied', 'attacked'
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`zone_id`) REFERENCES `npc_guard_zones`(`id`) ON DELETE CASCADE,
    INDEX `idx_zone_player` (`zone_id`, `player_identifier`),
    INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert pre-configured zones (marked as is_custom = 0)
INSERT INTO `npc_guard_zones` 
    (`name`, `center_x`, `center_y`, `center_z`, `radius`, `guard_count`, `required_item`, `requires_identifier`, 
     `ped_models`, `weapons`, `accuracy`, `health`, `armor`, `is_active`, `is_custom`, `created_by`) 
VALUES 
    ('Cayo Perico', 4971.24, -5703.58, 19.88, 150.0, 15, 'creampie', NULL,
     '["s_m_m_marine_01","s_m_m_marine_02","g_m_m_mexboss_01","g_m_m_mexboss_02","g_m_y_mexgang_01","g_m_y_mexgoon_01","g_m_y_mexgoon_02","g_m_y_mexgoon_03"]',
     '["WEAPON_ASSAULTRIFLE","WEAPON_CARBINERIFLE","WEAPON_SPECIALCARBINE","WEAPON_ADVANCEDRIFLE"]',
     60, 400, 200, 0, 0, 'system'),
     
    ('Fort Zancudo', -2047.23, 3132.13, 32.81, 200.0, 20, 'military_id', NULL,
     '["s_m_y_marine_01","s_m_y_marine_02","s_m_y_marine_03"]',
     '["WEAPON_CARBINERIFLE","WEAPON_ASSAULTRIFLE"]',
     80, 500, 250, 0, 0, 'system'),
     
    ('Grove Street Territory', -76.99, -1822.88, 26.94, 80.0, 8, 'gang_bandana', NULL,
     '["g_m_y_famca_01","g_m_y_famdnf_01","g_m_y_famfor_01"]',
     '["WEAPON_PISTOL","WEAPON_MICROSMG","WEAPON_PUMPSHOTGUN"]',
     40, 200, 100, 0, 0, 'system');

-- Insert pre-configured patrol routes
INSERT INTO `npc_patrol_routes`
    (`name`, `guard_zone`, `vehicle_model`, `ped_model`, `weapon`, `speed`, `waypoints`, `is_active`, `is_custom`, `created_by`)
VALUES
    ('Cayo Perico Perimeter', 'Cayo Perico', 'mesa3', 'g_m_m_mexboss_01', 'WEAPON_CARBINERIFLE', 25.0,
     '[{"x":4971.24,"y":-5703.58,"z":19.88,"w":0.0},{"x":5045.32,"y":-5815.67,"z":16.35,"w":90.0},{"x":5183.45,"y":-5735.89,"z":15.23,"w":180.0},{"x":5145.78,"y":-5620.45,"z":15.67,"w":270.0}]',
     0, 0, 'system'),
     
    ('Fort Zancudo Patrol', 'Fort Zancudo', 'barracks', 's_m_y_marine_01', 'WEAPON_ASSAULTRIFLE', 30.0,
     '[{"x":-2047.23,"y":3132.13,"z":32.81,"w":0.0},{"x":-1950.45,"y":3025.67,"z":32.81,"w":90.0},{"x":-2150.89,"y":2980.23,"z":32.81,"w":180.0},{"x":-2250.34,"y":3100.56,"z":32.81,"w":270.0}]',
     0, 0, 'system');
