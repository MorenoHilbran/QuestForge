# 🎮 QuestForge

**QuestForge** adalah aplikasi project management gamifikasi yang memungkinkan mahasiswa untuk bergabung dalam project solo atau tim dengan sistem role-based dan badge achievements. Built dengan Flutter & Supabase untuk pengalaman real-time dan responsive.

![Flutter](https://img.shields.io/badge/Flutter-3.9.2-02569B?logo=flutter)
![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?logo=supabase)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)
![Status](https://img.shields.io/badge/Status-Active-success)

---

## ✨ Fitur Utama

### 👥 Role-Based System
- **Admin**: Membuat dan mengelola project, menentukan mode (solo/team) dan required roles
- **User**: Bergabung dalam project, memilih role (frontend, backend, UI/UX, PM, fullstack)
- **Role Limits**: Sistem validasi untuk membatasi jumlah user per role (e.g., Frontend: 2/2 = FULL)
- **Role Visual Feedback**: Role yang penuh akan grayed out dan tidak bisa dipilih

### 🎯 Project Management
- **Solo Mode**: Project individual dengan tasks yang ditentukan admin
- **Multiplayer Mode**: Project tim dengan required roles dan role limits
- **Task Management**: Status tracking (todo, in progress, done)
- **Progress Tracking**: Otomatis berdasarkan task completion dengan visual progress bar
- **Priority Levels**: Low, medium, high untuk setiap task
- **Role Assignment**: Tasks dapat di-assign ke role tertentu
- **Member Display**: Lihat avatar dan jumlah member yang join (3/6 format)
- **Completion Status**: Badge "COMPLETED" untuk project yang sudah selesai

### 🏆 Gamification
- Badge system berdasarkan project completion
- Role-based badges (Frontend, Backend, UI/UX, PM achievements)
- Solo & Team mode badges
- Meta achievements (Versatile Adventurer, Quest Legend, dll)

### 🔐 Authentication
- **Google OAuth login** untuk user (seamless integration)
- **Email/Password login** untuk admin
- Auto-create profile dengan trigger database
- Profile management (avatar, bio, display name)
- Secure RLS policies untuk data protection

### 🎨 Modern UI
- **Neobrutalism design** (bold borders, vibrant colors, shadows)
- Responsive layouts untuk mobile & web
- Pull-to-refresh functionality
- Real-time progress indicators
- Role validation dengan visual feedback
- Clean progress bars tanpa clutter

### 🔒 Security Features
- Row Level Security (RLS) pada semua tables
- User-specific data access control
- OAuth integration dengan deep linking
- Secure profile creation dan validation

---

## 🆕 Recent Updates (v2.0 - Dec 2025)

### ✅ Implemented Features
- **OAuth Auto-Login**: Google OAuth sekarang langsung redirect ke homepage setelah pilih akun
- **Auto-Profile Creation**: Database trigger otomatis membuat profile untuk OAuth users
- **Role Validation**: Role yang sudah penuh tidak bisa dipilih (grayed out dengan visual feedback)
- **Member Visibility**: Users dapat melihat member lain yang join project yang sama
- **Enhanced RLS Policies**: Cross-user visibility dengan tetap maintain security
- **Null Safety**: Comprehensive null handling untuk semua data models
- **Retry Logic**: Network request retry mechanism untuk handle connection issues
- **Clean Progress Bars**: Removed percentage text untuk UI yang lebih clean
- **Completed Project Badges**: Visual badge untuk project yang sudah selesai
- **Join Validation**: Validasi untuk prevent join project yang full/completed

### 🐛 Bug Fixes
- Fixed OAuth "Connection reset" error dengan retry mechanism
- Fixed "Users not visible" bug dengan RLS policy updates
- Fixed progress bar tidak full width saat 100%
- Fixed badge system tidak award badges setelah completion
- Fixed admin monitoring data tidak akurat
- Fixed null pointer exceptions di UserModel parsing

### 📚 New Documentation
- `COMPLETE_DATABASE_SCHEMA.sql` - All-in-one database setup
- `FIX_OAUTH_CONNECTION_RESET.md` - OAuth troubleshooting guide
- `FIX_USER_VISIBILITY.md` - Multi-user visibility fix
- `ROLE_VALIDATION_FEATURE.md` - Role validation system docs
- `BADGE_SYSTEM_SETUP.md` - Badge system complete guide

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK ^3.9.2
- Dart SDK ^3.0.0
- Supabase account
- Google Cloud Console (untuk OAuth)

### Installation

1. **Clone repository**
```bash
git clone https://github.com/MorenoHilbran/QuestForge.git
cd questforge
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Setup environment variables**
```bash
cp .env.example .env
```

Edit `.env` dengan kredensial Supabase kamu:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

4. **Setup Database**

Buka Supabase Dashboard → SQL Editor, copy paste dan run **LENGKAP**:
```sql
COMPLETE_DATABASE_SCHEMA.sql
```

File ini sudah include **SEMUA** yang dibutuhkan:
- ✅ Semua tables (profiles, projects, user_projects, tasks, badges, dll)
- ✅ RLS policies untuk security (SELECT, INSERT, UPDATE, DELETE)
- ✅ Auto-create profile trigger untuk OAuth users
- ✅ Badge awarding function dengan automatic calculation
- ✅ Update timestamp triggers
- ✅ Indexes untuk performance
- ✅ Seed data untuk 10 badge definitions
- ✅ Permission grants untuk authenticated users

**IMPORTANT**: Run file ini sekali saja untuk setup lengkap database!

5. **Setup Google OAuth** (Optional, untuk user login)

a. Buat project di [Google Cloud Console](https://console.cloud.google.com)

b. Enable Google+ API

c. Buat OAuth 2.0 Client ID:
   - Application type: Web application
   - Authorized JavaScript origins: `http://localhost:3000`
   - Authorized redirect URIs: 
     - `http://localhost:3000/`
     - `https://your-project.supabase.co/auth/v1/callback`

d. Update di Supabase Dashboard:
   - Authentication → Providers → Google
   - Paste Client ID & Client Secret
   - Redirect URLs: `http://localhost:3000/**`

6. **Create Admin User**

After database setup, create an admin account:
```sql
-- Login via Supabase Auth UI or signup in app first
-- Then update user role to admin:
UPDATE profiles 
SET role = 'admin' 
WHERE email = 'your-admin-email@example.com';
```

7. **Run aplikasi**
```bash
# Android (recommended untuk production)
flutter run

# Web (development)
flutter run -d chrome --web-port=3000 --web-hostname=localhost

# Atau gunakan script PowerShell
./run_web.ps1
```

---

## 📂 Struktur Project

```
lib/
├── core/
│   ├── constants/       # App constants (colors, spacing, roles)
│   └── theme/          # Theme configuration
├── data/
│   └── models/         # Data models (User, Project, Badge, dll)
├── providers/          # State management (AuthProvider)
├── screens/
│   ├── admin/          # Admin screens (ManageProjects)
│   ├── auth/           # Login screen
│   ├── home/           # Home screen (browse projects)
│   ├── profile/        # Profile & edit profile
│   └── projects/       # User projects & detail
├── services/           # Supabase service
└── widgets/            # Reusable widgets (NeoButton, NeoCard, dll)
```

---

## 🗄️ Database Schema

### Core Tables
| Table | Description | Key Features |
|-------|-------------|--------------|
| **profiles** | User profiles synced dengan Supabase Auth | Auto-created via trigger, role-based access |
| **projects** | Project definitions dengan mode & roles | Admin-created, role_limits JSONB |
| **user_projects** | Project participation tracking | Junction table, progress tracking |
| **tasks** | Task management per project | Status tracking, priority levels |
| **badges** | Badge definitions & requirements | Category-based, tier system |
| **user_badges** | User badge achievements | Auto-awarded via function |
| **milestones** | Project milestones (optional) | Future feature support |
| **activity_logs** | Activity tracking (optional) | Audit trail |

### Key Features
- ✅ **Row Level Security (RLS)** enabled untuk ALL tables
- ✅ **Auto-create profile trigger** untuk OAuth users
- ✅ **Auto-update timestamps** dengan triggers
- ✅ **Badge awarding function** dengan automatic calculation
- ✅ **Role validation** dengan role_limits JSONB
- ✅ **Progress tracking** based on task completion
- ✅ **Indexes** untuk performance optimization

### Database Setup Files
```
COMPLETE_DATABASE_SCHEMA.sql          # ⭐ Main schema (run this!)
database/
├── triggers/
│   └── auto_create_profile.sql       # Auto-create profile trigger
├── fixes/
│   ├── fix_profiles_rls.sql          # Fix profile RLS policies
│   ├── fix_user_projects_rls.sql     # Fix user_projects RLS policies
│   └── fix_profiles_rls_for_oauth.sql # OAuth-specific fixes
└── debug/
    └── check_user_profile.sql         # Debug user profile issues
```

---

## 🎯 User Flow

### Admin Flow
1. Login dengan email/password
2. Navigate ke "Manage" tab
3. Create project:
   - Set title, description, difficulty
   - Choose mode: Solo atau Multiplayer
   - Select required roles (untuk team projects)
4. Users akan melihat project di Home screen
5. Setelah user join, admin bisa add tasks di project detail

### User Flow
1. Login dengan Google OAuth
2. Browse projects di Home screen
3. Filter by difficulty (easy, medium, hard)
4. Click "Join Project"
5. Pilih role (jika team project)
6. Navigate ke "Projects" tab untuk melihat joined projects
7. Click project → view tasks → mark tasks as complete
8. Earn badges berdasarkan achievement!

---

## 🛠️ Tech Stack

| Category | Technology | Version |
|----------|-----------|---------|
| **Frontend** | Flutter | 3.9.2 |
| **Language** | Dart | 3.0+ |
| **Backend** | Supabase (PostgreSQL) | Latest |
| **Authentication** | Supabase Auth + Google OAuth | - |
| **State Management** | Provider | 6.0+ |
| **Database** | PostgreSQL dengan RLS | 15+ |
| **Storage** | Supabase Storage | - |
| **Deep Linking** | app_links | - |
| **Platform** | Android, Web | - |

### Key Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.10.0
  provider: ^6.0.0
  flutter_dotenv: ^5.0.0
```

---

## 🎨 Design System

### Colors
- Primary: `#FFD93D` (Yellow)
- Secondary: `#A6FF96` (Green)
- Error: `#FF6B9D` (Pink)
- Warning: `#FFA500` (Orange)
- Success: `#6BCF7F` (Green)
- Border: `#000000` (Black, 3px)

### Typography
- Font: System default (bold weights)
- Headings: 900 weight
- Body: 400-700 weight

### Components
- NeoCard: White background, 3px black border, 4px shadow
- NeoButton: Colored background, 3px border, elevation effect
- NeoTextField: Bordered input dengan rounded corners

---

## 📱 Screenshots

> Coming soon - Add screenshots of key screens

---

## 🚨 Troubleshooting

### Common Issues

**1. OAuth "Connection Reset" Error**
- **Solution**: Run `database/fixes/fix_profiles_rls_for_oauth.sql`
- **Details**: See `FIX_OAUTH_CONNECTION_RESET.md`

**2. Users Not Visible in Projects**
- **Solution**: Run `database/fixes/fix_user_projects_rls.sql` dan `fix_profiles_rls.sql`
- **Details**: See `FIX_USER_VISIBILITY.md`

**3. Role Selection Grayed Out**
- **Cause**: Role is full (reached role_limits)
- **Solution**: Working as intended! Choose another role.
- **Details**: See `ROLE_VALIDATION_FEATURE.md`

**4. Badge Not Awarded**
- **Check**: Function `check_and_award_badges()` called after completing project
- **Verify**: `SELECT * FROM badges;` untuk see badge requirements
- **Details**: See `BADGE_SYSTEM_SETUP.md`

### Documentation Files
```
README.md                              # This file
COMPLETE_DATABASE_SCHEMA.sql          # Complete database setup
FIX_OAUTH_CONNECTION_RESET.md         # OAuth login troubleshooting
FIX_USER_VISIBILITY.md                # Multi-user visibility fix
ROLE_VALIDATION_FEATURE.md            # Role validation system
BADGE_SYSTEM_SETUP.md                 # Badge system guide
OAUTH_ANDROID_SETUP.md                # Android OAuth deep linking
```

---

## 👨‍💻 Developer

**Moreno Hilbran**
- GitHub: [@MorenoHilbran](https://github.com/MorenoHilbran)
- Repository: [QuestForge](https://github.com/MorenoHilbran/QuestForge)

---

## 📋 Quick Reference

### Database Setup (One Command)
```sql
-- Run this ONCE in Supabase SQL Editor
COMPLETE_DATABASE_SCHEMA.sql
```

### Create Admin User
```sql
UPDATE profiles SET role = 'admin' WHERE email = 'your-email@example.com';
```

### Debug User Issues
```sql
-- Check if user exists and profile data
SELECT * FROM profiles WHERE email = 'user@example.com';

-- Check project members
SELECT p.name, up.role, prof.name as user_name
FROM user_projects up
JOIN projects p ON up.project_id = p.id
JOIN profiles prof ON up.user_id = prof.id
WHERE p.title = 'Your Project Name';

-- Check badges awarded
SELECT u.name, b.name as badge, ub.awarded_at
FROM user_badges ub
JOIN profiles u ON ub.user_id = u.id
JOIN badges b ON ub.badge_id = b.id
WHERE u.email = 'user@example.com';
```

### Common SQL Fixes
```sql
-- Fix NULL fields in profile
UPDATE profiles 
SET name = COALESCE(name, 'User'),
    role = COALESCE(role, 'user'),
    created_at = COALESCE(created_at, NOW()),
    updated_at = COALESCE(updated_at, NOW())
WHERE email = 'user@example.com';

-- Set default role_limits for multiplayer projects
UPDATE projects
SET role_limits = '{"frontend": 2, "backend": 2, "uiux": 1, "pm": 1, "fullstack": 2}'::jsonb
WHERE mode = 'multiplayer' AND (role_limits IS NULL OR role_limits = '{}'::jsonb);

-- Award badges manually (if function not working)
SELECT check_and_award_badges('user-uuid-here');
```

### Flutter Commands
```bash
# Run on Android
flutter run

# Run on Web
flutter run -d chrome

# Build APK
flutter build apk --release

# Clean build
flutter clean && flutter pub get

# Hot reload (in running app)
r

# Hot restart (in running app)
R
```

---

## 📄 License

This project is part of academic coursework.

---

**Made with ❤️ using Flutter & Supabase**


