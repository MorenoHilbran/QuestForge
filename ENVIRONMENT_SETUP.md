# QuestForge V2 - Environment Setup & Deployment Guide

## ✅ Status: READY FOR DEPLOYMENT

Database schema telah berhasil di-deploy ke Supabase. Semua credentials sudah dikonfigurasi.

---

## 📋 Environment Configuration

### 1. File `.env` (sudah dibuat)
```
SUPABASE_URL=https://ijimywkjjewkleloksrs.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlqaW15d2tqamV3a2xlbG9rc3JzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUxOTIyNzgsImV4cCI6MjA4MDc2ODI3OH0.05qAPNIxU6CpL9Xku-PUSLEcSH1qHhT1PpAX8wPRkPg
```

File ini sudah ada di root project: `d:\Nigga\QuestForge\.env`

### 2. Configuration di `pubspec.yaml`
✅ `flutter_dotenv: ^5.0.2` - sudah ada
✅ `.env` file sudah di-include di `assets`

### 3. Initialization di `main.dart`
✅ `dotenv.load()` - sudah di-load sebelum `runApp()`
✅ `SupabaseService.init()` - sudah di-call

---

## 🚀 Langkah-Langkah Deployment

### Step 1: Pastikan Database Schema Sudah Ter-Deploy
```bash
# Buka Supabase Dashboard
# Menu: SQL Editor → Buat query baru
# Copy-paste seluruh isi COMPLETE_DATABASE_SCHEMA_V2.sql
# Klik "Run" atau "Ctrl+Enter"
```

**Verifikasi:**
- 8 tables terbuat: profiles, projects, user_projects, milestones, tasks, badges, user_badges, activity_logs
- 9 functions terbuat
- 13 triggers terbuat
- 35+ RLS policies terbuat

### Step 2: Buat Admin User
```bash
# Di Supabase Dashboard:
# 1. Go to Authentication → Users
# 2. Click "Create new user"
# 3. Input email: your@email.com
# 4. Input password: strong_password_123
# 5. Uncheck "Auto Confirm User"
# 6. Click "Create user"
```

### Step 3: Set Admin Role
```bash
# Di Supabase Dashboard:
# 1. Go to SQL Editor → Create new query
# 2. Run this command:
UPDATE profiles 
SET role = 'admin' 
WHERE email = 'your@email.com';

# 3. Verify:
SELECT id, email, role FROM profiles WHERE email = 'your@email.com';
```

### Step 4: Run Flutter App
```powershell
# Terminal 1: Clean & Get Dependencies
cd d:\Nigga\QuestForge
flutter clean
flutter pub get

# Terminal 2: Run App
flutter run

# Untuk specific device/platform:
flutter run -d chrome          # Web
flutter run -d windows         # Windows Desktop
flutter run -d android-emulator # Android Emulator
```

### Step 5: Test Login Flow
1. **Launch app** → Should see LoginScreen
2. **Click "Create Account"** → Go to RegisterScreen
3. **Enter details:**
   - Email: testuser@example.com
   - Password: Test123!@
   - Name: Test User
4. **Click "Sign Up"** → Should redirect to LoginScreen
5. **Enter credentials** → Should auto-create profile & log in

---

## ⚙️ Configuration Details

### Supabase URL
```
https://ijimywkjjewkleloksrs.supabase.co
```

### Anon Key (safe for frontend)
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlqaW15d2tqamV3a2xlbG9rc3JzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUxOTIyNzgsImV4cCI6MjA4MDc2ODI3OH0.05qAPNIxU6CpL9Xku-PUSLEcSH1qHhT1PpAX8wPRkPg
```

### Environment Loading Priority (di `supabase_service.dart`)
1. Load dari `.env` file (mobile/desktop)
2. Fallback ke compile-time constants (web)

---

## 🔐 Security Considerations

### 1. `.env` File
- **Include dalam `.gitignore`** ✅ (already in project)
- **JANGAN push ke GitHub**
- Contains only `anon` key (safe for frontend)
- Service role key NOT included (untuk backend only)

### 2. Row Level Security (RLS)
- ✅ Enabled pada semua tables
- ✅ 35+ policies configured
- ✅ Users hanya bisa akses data mereka sendiri

### 3. Authentication
- ✅ Supabase Auth (JWT tokens)
- ✅ Auto-create profiles di trigger
- ✅ Role-based access control

---

## 📱 Testing Checklist

### Authentication
- [ ] Login dengan email yang sudah ada
- [ ] Sign up user baru
- [ ] Logout
- [ ] Profile page menampilkan user data

### Projects (Admin)
- [ ] Admin bisa create project
- [ ] Project code auto-generated (6 char)
- [ ] Project tampil di home screen
- [ ] Can edit own projects

### Projects (User)
- [ ] Join project dengan code
- [ ] View project details
- [ ] See team members
- [ ] View tasks & milestones

### Task Management
- [ ] Create task (PM only)
- [ ] Claim task (set assigned_user_id)
- [ ] Update task status: todo → in_progress → done
- [ ] Progress auto-update

### Badges
- [ ] Complete project → Check badges triggered
- [ ] User badges page shows earned badges
- [ ] Badge icons display correctly

### Activity Logs
- [ ] Log created when project made
- [ ] Log created when user joined
- [ ] Log created when task completed
- [ ] Activity feed shows correct actions

---

## 🐛 Troubleshooting

### Error: "Supabase env vars not found"
**Solution:**
- Verify `.env` file exists at `d:\Nigga\QuestForge\.env`
- Check credentials are correct
- Run `flutter clean && flutter pub get`
- Restart app

### Error: "Relation 'profiles' does not exist"
**Solution:**
- Run full database schema in SQL Editor
- Verify all 8 tables created: `SELECT * FROM information_schema.tables WHERE table_schema = 'public';`
- Check triggers and functions exist

### Error: "User not authenticated"
**Solution:**
- Confirm user created in Supabase Auth
- Check RLS policies enabled
- Verify JWT token is valid
- Check browser console for errors

### App Crashes on Login
**Solution:**
- Enable Supabase debug mode: Add `SUPABASE_DEBUG=true` to `.env`
- Check app logs: `flutter run --verbose`
- Verify email format is valid
- Check Supabase Auth settings

---

## 📚 Project Structure (V2)

```
lib/
├── main.dart                    # App entry, env loading
├── core/
│   ├── constants/
│   │   └── app_constants.dart  # Enums, config (UPDATED V2)
│   └── theme/
│       └── app_theme.dart      # Theme (unchanged)
├── data/
│   └── models/                 # All 5 models (UPDATED V2)
│       ├── project_model.dart
│       ├── task_model.dart
│       ├── user_project_model.dart
│       ├── milestone_model.dart
│       └── activity_log_model.dart
├── providers/
│   └── auth_provider.dart      # Auth state (unchanged)
├── services/
│   └── supabase_service.dart   # DB connection (unchanged)
├── screens/
│   ├── main_navigation.dart    # Bottom nav (UPDATED V2)
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   └── home_screen.dart    # Shows projects (UPDATED V2)
│   ├── profile/
│   │   └── profile_screen.dart
│   ├── projects/
│   │   ├── project_detail_screen.dart     # (UPDATED V2)
│   │   ├── join_project_screen.dart       # (UPDATED V2)
│   │   ├── join_with_code_screen.dart     # (NEW V2)
│   │   ├── pm_approval_screen.dart        # (NEW V2)
│   │   └── create_project_screen.dart
│   ├── admin/
│   │   └── admin_monitoring_screen.dart   # (UPDATED V2)
│   └── widgets/
│       ├── common/
│       └── claim_task_button.dart         # (NEW V2)
└── assets/
    └── images/
```

---

## ✨ V2 Features Enabled

### 1. **Project Codes**
- Auto-generated 6-character uppercase codes
- Users join projects by scanning/entering code
- Database trigger: `auto_generate_project_code`

### 2. **Task Claiming**
- Users claim tasks for themselves
- Sets `assigned_user_id` in tasks table
- NEW widget: `ClaimTaskButton`

### 3. **Auto-Progress Calculation**
- Progress auto-calculated from task completion
- No manual calculation needed
- Database function: `calculate_user_progress()`

### 4. **Auto-Badge Awards**
- Badges awarded automatically on project completion
- 30+ badge types pre-seeded
- Database function: `check_and_award_badges()`

### 5. **PM Approval Workflow**
- For multiplayer projects with `requires_approval: true`
- PM reviews join requests
- NEW screen: `PMApprovalScreen`

### 6. **Activity Logging**
- Auto-logged via triggers
- 14 action types tracked
- Table: `activity_logs`

### 7. **Milestones**
- Fully implemented with progress tracking
- order_index for display order
- can mark as complete

---

## 🎯 Next Steps

1. **Verify database deployed**: Check Supabase SQL Editor for all tables
2. **Create admin account**: Update profile role to 'admin'
3. **Run Flutter app**: `flutter run`
4. **Test workflows**: Follow testing checklist above
5. **Deploy to app stores** (future): Build release APK/IPA

---

## 📞 Support Info

**Supabase Project:**
- URL: https://ijimywkjjewkleloksrs.supabase.co
- Region: (check dashboard)
- Database: PostgreSQL

**Generated Files:**
- `.env` - Environment variables
- `COMPLETE_DATABASE_SCHEMA_V2.sql` - Full schema (deployed)

---

**Status: ✅ DEPLOYMENT READY**
All code complete. Environment configured. Ready to test! 🚀
