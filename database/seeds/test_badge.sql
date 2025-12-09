-- Simple test badge - just complete 1 project
-- Run this in Supabase SQL Editor

INSERT INTO badges (name, description, type, icon_url)
VALUES
  ('First Quest Complete', 'Congratulations! You completed your first project! 🎉', 'completion', '🎯')
ON CONFLICT (name) DO UPDATE SET
  description = EXCLUDED.description,
  type = EXCLUDED.type,
  icon_url = EXCLUDED.icon_url;

-- Also insert the real badges for progression
INSERT INTO badges (name, description, type, icon_url)
VALUES
  ('Quest Master', 'Complete 5 projects - You are on fire! 🔥', 'completion', '⭐'),
  ('Legendary Quester', 'Complete 10 projects - True legend! 👑', 'completion', '👑'),
  ('Solo Warrior', 'Complete 3 solo projects ⚔️', 'mode', '⚔️'),
  ('Team Player', 'Complete 3 multiplayer projects 🤝', 'mode', '🤝'),
  ('Easy Master', 'Complete 3 easy projects 🌱', 'difficulty', '🌱'),
  ('Medium Master', 'Complete 3 medium projects 🔥', 'difficulty', '🔥'),
  ('Hard Hero', 'Complete 3 hard projects 💎', 'difficulty', '💎')
ON CONFLICT (name) DO UPDATE SET
  description = EXCLUDED.description,
  type = EXCLUDED.type,
  icon_url = EXCLUDED.icon_url;
