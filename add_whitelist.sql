-- Migration to add whitelist fields to existing database
-- Run this if you already have the database set up

USE dreamcity_web;

-- Add whitelist columns to users table if they don't exist
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS is_whitelisted BOOLEAN DEFAULT FALSE AFTER queue_priority,
ADD COLUMN IF NOT EXISTS whitelist_date TIMESTAMP NULL AFTER is_whitelisted,
ADD INDEX IF NOT EXISTS idx_is_whitelisted (is_whitelisted);

-- Optional: Set some test users as whitelisted for testing
-- UPDATE users SET is_whitelisted = TRUE, whitelist_date = NOW() WHERE id = 1;

COMMIT;

SELECT 'Whitelist columns added successfully!' as message;
