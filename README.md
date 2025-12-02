# 🎮 QuestForge

**QuestForge** adalah aplikasi project management gamifikasi yang memungkinkan mahasiswa untuk bergabung dalam project solo atau tim dengan sistem role-based dan badge achievements.

![Flutter](https://img.shields.io/badge/Flutter-3.9.2-02569B?logo=flutter)
![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?logo=supabase)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)

---

## ✨ Fitur Utama

### 👥 Role-Based System
- **Admin**: Membuat dan mengelola project, menentukan mode (solo/team) dan required roles
- **User**: Bergabung dalam project, memilih role (frontend, backend, UI/UX, PM, fullstack)

### 🎯 Project Management
- **Solo Mode**: Project individual dengan tasks yang ditentukan admin
- **Multiplayer Mode**: Project tim dengan required roles yang ditentukan admin
- Task management dengan status tracking (todo, in progress, done)
- Progress tracking otomatis berdasarkan task completion
- Priority levels (low, medium, high) untuk setiap task

### 🏆 Gamification
- Badge system berdasarkan project completion
- Role-based badges (Frontend, Backend, UI/UX, PM achievements)
- Solo & Team mode badges
- Meta achievements (Versatile Adventurer, Quest Legend, dll)

### 🔐 Authentication
- Google OAuth login untuk user
- Email/Password login untuk admin
- Profile management (avatar, bio, display name)

### 🎨 Modern UI
- Neobrutalism design (bold borders, vibrant colors, shadows)
- Responsive layouts
- Pull-to-refresh functionality
- Real-time progress indicators

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

Buka Supabase Dashboard → SQL Editor, copy paste dan run:
```sql
DATABASE_SCHEMA.sql
```

File ini sudah include:
- Semua tabel (profiles, projects, user_projects, tasks, milestones, badges, dll)
- RLS policies untuk security
- Functions untuk badge awarding & progress calculation
- Seed data untuk badge definitions

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

6. **Run aplikasi**
```bash
# Web (recommended for development)
flutter run -d chrome --web-port=3000 --web-hostname=localhost

# Atau gunakan script
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
- **profiles** - User profiles (synced dengan Supabase Auth)
- **projects** - Project definitions dengan mode & required_roles
- **user_projects** - Project participation dengan role & progress
- **tasks** - Tasks untuk setiap project
- **milestones** - Project milestones (optional)
- **badge_definitions** - Badge types & requirements
- **activity_logs** - Activity tracking

### Key Features
- Row Level Security (RLS) enabled untuk semua tables
- Auto-update timestamps dengan triggers
- Badge awarding function dengan automatic calculation
- Progress calculation based on task completion

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

- **Frontend**: Flutter (Dart)
- **Backend**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth + Google OAuth
- **State Management**: Provider
- **Database**: PostgreSQL dengan Supabase
- **Hosting**: Web (deployable ke Vercel, Netlify, Firebase Hosting)

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


## 👨‍💻 Developer

**Moreno Hilbran**
- GitHub: [@MorenoHilbran](https://github.com/MorenoHilbran)
- Repository: [QuestForge](https://github.com/MorenoHilbran/QuestForge)

---
