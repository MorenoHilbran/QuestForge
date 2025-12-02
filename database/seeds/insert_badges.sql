-- Insert initial badges into the badges table
-- Run this in Supabase SQL Editor after creating the badges table

-- Achievement Badges (by project count)
INSERT INTO badges (name, description, tier, icon)
VALUES
  ('First Quest', 'Complete your first project', 'bronze', '🎯'),
  ('Quest Master', 'Complete 5 projects', 'silver', '⭐'),
  ('Legendary Quester', 'Complete 10 projects', 'gold', '👑')
ON CONFLICT (name) DO NOTHING;

-- Difficulty Badges
INSERT INTO badges (name, description, tier, icon)
VALUES
  ('Easy Conqueror', 'Complete 3 easy projects', 'bronze', '🌱'),
  ('Medium Master', 'Complete 3 medium projects', 'silver', '🔥'),
  ('Hard Hero', 'Complete 3 hard projects', 'gold', '💎')
ON CONFLICT (name) DO NOTHING;

-- Mode Badges
INSERT INTO badges (name, description, tier, icon)
VALUES
  ('Lone Wolf', 'Complete 3 solo projects', 'silver', '⚔️'),
  ('Team Player', 'Complete 3 multiplayer projects', 'silver', '🤝')
ON CONFLICT (name) DO NOTHING;

-- Special Badges
INSERT INTO badges (name, description, tier, icon)
VALUES
  ('Speed Demon', 'Complete a project in under 3 days', 'gold', '⚡'),
  ('Perfectionist', 'Complete all tasks in a project without skipping', 'gold', '✨')
ON CONFLICT (name) DO NOTHING;
