#!/bin/bash
# Run script for Flutter Web with Supabase environment variables

flutter run -d chrome \
  --dart-define=SUPABASE_URL="https://vgcksmihyzwajthwxprp.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZnY2tzbWloeXp3YWp0aHd4cHJwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ2MDY2NjIsImV4cCI6MjA4MDE4MjY2Mn0.Gn7_I9HlyzcNNJyQkH5OF6-OPnkQMr7DqcIrfmo8YzI"
