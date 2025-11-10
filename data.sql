-- Dream City RP Database Schema
-- Steam Authentication & User Management System

-- Create database
CREATE DATABASE IF NOT EXISTS dreamcity_web;
USE dreamcity_web;

-- Users table - stores Steam authenticated users
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    steam_id VARCHAR(20) UNIQUE NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    avatar_url VARCHAR(255),
    profile_url VARCHAR(255),
    subscription_tier ENUM('none', 'silver', 'gold', 'emerald') DEFAULT 'none',
    queue_priority INT DEFAULT 0,
    is_whitelisted BOOLEAN DEFAULT FALSE,
    whitelist_date TIMESTAMP NULL,
    is_banned BOOLEAN DEFAULT FALSE,
    ban_reason TEXT,
    is_admin BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_steam_id (steam_id),
    INDEX idx_subscription_tier (subscription_tier),
    INDEX idx_last_login (last_login),
    INDEX idx_is_whitelisted (is_whitelisted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- User statistics table
CREATE TABLE IF NOT EXISTS user_stats (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    playtime_hours DECIMAL(10, 2) DEFAULT 0,
    total_earnings DECIMAL(15, 2) DEFAULT 0,
    total_spent DECIMAL(15, 2) DEFAULT 0,
    vehicles_owned INT DEFAULT 0,
    properties_owned INT DEFAULT 0,
    arrests INT DEFAULT 0,
    deaths INT DEFAULT 0,
    jobs_completed INT DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_stats (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Subscriptions table - tracks subscription history
CREATE TABLE IF NOT EXISTS subscriptions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    tier ENUM('silver', 'gold', 'emerald') NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    payment_method VARCHAR(50),
    transaction_id VARCHAR(100) UNIQUE,
    status ENUM('active', 'expired', 'cancelled', 'refunded') DEFAULT 'active',
    start_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_date TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_subscriptions (user_id),
    INDEX idx_status (status),
    INDEX idx_end_date (end_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Characters table - in-game characters
CREATE TABLE IF NOT EXISTS characters (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    character_name VARCHAR(100) NOT NULL,
    character_age INT NOT NULL,
    gender ENUM('male', 'female', 'other') NOT NULL,
    backstory TEXT,
    money_cash DECIMAL(15, 2) DEFAULT 0,
    money_bank DECIMAL(15, 2) DEFAULT 0,
    job VARCHAR(50),
    gang_affiliation VARCHAR(100),
    is_dead BOOLEAN DEFAULT FALSE,
    death_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_played TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_characters (user_id),
    INDEX idx_character_name (character_name),
    INDEX idx_last_played (last_played)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Vehicles table
CREATE TABLE IF NOT EXISTS vehicles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    character_id INT NOT NULL,
    vehicle_model VARCHAR(100) NOT NULL,
    vehicle_plate VARCHAR(20) UNIQUE NOT NULL,
    vehicle_color VARCHAR(50),
    vehicle_type ENUM('car', 'motorcycle', 'truck', 'boat', 'aircraft') NOT NULL,
    tier INT DEFAULT 1,
    purchase_price DECIMAL(15, 2),
    is_impounded BOOLEAN DEFAULT FALSE,
    garage_location VARCHAR(100),
    purchased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE,
    INDEX idx_character_vehicles (character_id),
    INDEX idx_vehicle_plate (vehicle_plate)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Properties table
CREATE TABLE IF NOT EXISTS properties (
    id INT AUTO_INCREMENT PRIMARY KEY,
    character_id INT NOT NULL,
    property_type ENUM('house', 'apartment', 'business', 'warehouse') NOT NULL,
    property_name VARCHAR(100),
    property_address VARCHAR(255) NOT NULL,
    purchase_price DECIMAL(15, 2),
    property_tier INT DEFAULT 1,
    is_locked BOOLEAN DEFAULT TRUE,
    purchased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE,
    INDEX idx_character_properties (character_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Login history table - track user logins
CREATE TABLE IF NOT EXISTS login_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    login_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_logins (user_id),
    INDEX idx_login_time (login_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Admin actions log
CREATE TABLE IF NOT EXISTS admin_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    admin_user_id INT NOT NULL,
    action_type ENUM('ban', 'unban', 'kick', 'warn', 'subscription_grant', 'other') NOT NULL,
    target_user_id INT,
    action_details TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (admin_user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (target_user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_admin_actions (admin_user_id),
    INDEX idx_target_user (target_user_id),
    INDEX idx_action_type (action_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Server settings table
CREATE TABLE IF NOT EXISTS server_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert default server settings
INSERT INTO server_settings (setting_key, setting_value, description) VALUES
('server_name', 'Dream City RP', 'Server display name'),
('max_players', '64', 'Maximum number of players'),
('queue_enabled', 'true', 'Enable queue system'),
('maintenance_mode', 'false', 'Server maintenance mode'),
('discord_webhook', '', 'Discord webhook URL for notifications')
ON DUPLICATE KEY UPDATE setting_value=VALUES(setting_value);

-- Create view for active subscriptions
CREATE OR REPLACE VIEW active_subscriptions AS
SELECT 
    u.id as user_id,
    u.steam_id,
    u.display_name,
    s.tier,
    s.amount,
    s.start_date,
    s.end_date,
    DATEDIFF(s.end_date, NOW()) as days_remaining
FROM users u
INNER JOIN subscriptions s ON u.id = s.user_id
WHERE s.status = 'active' 
AND (s.end_date IS NULL OR s.end_date > NOW());

-- Create view for user overview
CREATE OR REPLACE VIEW user_overview AS
SELECT 
    u.id,
    u.steam_id,
    u.display_name,
    u.avatar_url,
    u.subscription_tier,
    u.queue_priority,
    u.created_at,
    u.last_login,
    COALESCE(us.playtime_hours, 0) as playtime_hours,
    COALESCE(us.total_earnings, 0) as total_earnings,
    COUNT(DISTINCT c.id) as character_count,
    COUNT(DISTINCT v.id) as vehicle_count,
    COUNT(DISTINCT p.id) as property_count
FROM users u
LEFT JOIN user_stats us ON u.id = us.user_id
LEFT JOIN characters c ON u.id = c.user_id AND c.is_dead = FALSE
LEFT JOIN vehicles v ON c.id = v.character_id
LEFT JOIN properties p ON c.id = p.character_id
GROUP BY u.id;

-- Sample data for testing (optional - remove in production)
-- INSERT INTO users (steam_id, display_name, avatar_url, subscription_tier, queue_priority) VALUES
-- ('76561198000000001', 'TestPlayer1', 'https://via.placeholder.com/150', 'gold', 14),
-- ('76561198000000002', 'TestPlayer2', 'https://via.placeholder.com/150', 'silver', 10);

COMMIT;
