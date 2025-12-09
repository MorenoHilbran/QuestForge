-- ============================================================
-- UPDATE USER TO ADMIN
-- ============================================================
-- Run this in Supabase SQL Editor to make a user an admin

-- Replace 'admin@admin.com' with the actual email of the user you want to make admin
UPDATE profiles
SET role = 'admin'
WHERE email = 'admin@admin.com';

-- Verify the update
SELECT id, email, name, role, created_at
FROM profiles
WHERE email = 'admin@admin.com';
