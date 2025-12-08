╔═══════════════════════════════════════════════════════════╗
║          🚨 ULTIMATE FIX - READ CAREFULLY 🚨              ║
╚═══════════════════════════════════════════════════════════╝

PROBLEM: User tidak bisa join project - error "mode column"
ROOT CAUSE: Schema cache corrupt + missing triggers

╔═══════════════════════════════════════════════════════════╗
║              SOLUTION - FOLLOW EXACTLY                     ║
╚═══════════════════════════════════════════════════════════╝

STEP 1: CLOSE FLUTTER APP
▶ Press Ctrl+C in terminal
▶ Make sure app is completely stopped

STEP 2: OPEN SUPABASE SQL EDITOR
▶ Go to: https://supabase.com/dashboard
▶ Select your QuestForge project
▶ Click "SQL Editor" (left sidebar)
▶ Click "+ New query" button

STEP 3: COPY THE ULTIMATE FIX
▶ Open file: database\fixes\ULTIMATE_FIX.sql
▶ Press Ctrl+A (select all)
▶ Press Ctrl+C (copy)

STEP 4: PASTE AND RUN
▶ Click in SQL Editor
▶ Press Ctrl+A (clear old content)
▶ Press Ctrl+V (paste new SQL)
▶ Click BIG BLUE "RUN" BUTTON
▶ WAIT until you see GREEN checkmark ✓

STEP 5: VERIFY SUCCESS
You should see output:
✓ "SUCCESS! All tables created"
✓ List of 8 tables
✓ "Triggers created"
✓ "Ready to use! 🚀"

STEP 6: MAKE YOURSELF ADMIN
Run this in NEW SQL query (replace email):

UPDATE profiles 
SET role = 'admin' 
WHERE email = 'YOUR-EMAIL@gmail.com';

STEP 7: RESTART FLUTTER
▶ Open terminal in project folder
▶ Type: flutter run -d edge
▶ Press Enter
▶ Wait for app to load

STEP 8: TEST EVERYTHING
1. Login with your account
2. Should see Admin menu ✓
3. Admin → Create Project ✓
4. Logout
5. Login as different user
6. Projects → Join with Code ✓
7. Enter project code ✓
8. Should work! 🎉

╔═══════════════════════════════════════════════════════════╗
║                  IF STILL ERROR                            ║
╚═══════════════════════════════════════════════════════════╝

Option A: Clear browser cache
▶ Ctrl+Shift+Delete
▶ Clear last hour
▶ Try again

Option B: Use incognito window
▶ Open new incognito tab
▶ Go to localhost:PORT
▶ Test join project

Option C: Wait 30 seconds
▶ Supabase cache might need time to refresh
▶ Close browser completely
▶ Wait 30 seconds
▶ Open browser and try again

╔═══════════════════════════════════════════════════════════╗
║              WHAT THIS FIX DOES                            ║
╚═══════════════════════════════════════════════════════════╝

✓ Drops all old tables and functions
✓ Creates fresh schema with correct columns
✓ Enables super permissive RLS (development mode)
✓ Adds auto-generate project code function
✓ Adds auto-create profile trigger
✓ Clears all schema cache issues
✓ Makes everything work properly

╔═══════════════════════════════════════════════════════════╗
║                    IMPORTANT                               ║
╚═══════════════════════════════════════════════════════════╝

⚠️ This will DELETE all data (users, projects, etc)
⚠️ You need to recreate admin account
⚠️ You need to recreate test projects
✓ But after this, EVERYTHING will work properly!

╔═══════════════════════════════════════════════════════════╗
║                  READY? LET'S GO! 🚀                      ║
╚═══════════════════════════════════════════════════════════╝

Start with STEP 1 above!
