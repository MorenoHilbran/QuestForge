# QuestForge Changelog

## Version 2.0 (December 3, 2025)

### 🎉 Major Updates

#### Database & Infrastructure
- ✅ **Complete Database Schema**: All-in-one SQL file (`COMPLETE_DATABASE_SCHEMA.sql`) untuk setup lengkap
- ✅ **Auto-Create Profile Trigger**: Database trigger otomatis membuat profile untuk OAuth users
- ✅ **Enhanced RLS Policies**: Updated policies untuk allow cross-user visibility dengan tetap secure
- ✅ **Performance Indexes**: Added indexes pada semua foreign keys dan frequently queried columns

#### Authentication & OAuth
- ✅ **OAuth Auto-Redirect**: Google OAuth sekarang langsung navigate ke homepage setelah select account
- ✅ **Auto-Profile Creation**: New OAuth users automatically get profile created dengan metadata dari Google
- ✅ **Retry Mechanism**: Added 3-retry logic dengan exponential backoff untuk network issues
- ✅ **Deep Linking**: Proper OAuth callback handling via `questforge://login-callback`

#### Project Management
- ✅ **Role Validation System**: Role limits enforcement dengan visual feedback
- ✅ **Role Visual Indicators**: Grayed out roles yang sudah penuh (e.g., Frontend 2/2 - FULL)
- ✅ **Member Visibility**: Users dapat see other members yang join same project
- ✅ **Member Display**: Avatar display (up to 3) + count badge (e.g., +5)
- ✅ **Completion Badge**: Visual "COMPLETED" badge untuk finished projects
- ✅ **Join Validation**: Prevent joining full/completed projects

#### UI/UX Improvements
- ✅ **Clean Progress Bars**: Removed percentage text untuk cleaner UI
- ✅ **Progress Bar Width Fix**: 100% progress sekarang full width (bukan hanya indicator)
- ✅ **Role Selection Cards**: Enhanced dengan availability status dan count
- ✅ **Join Button States**: 4 states (joined, completed, full, available) dengan proper colors

#### Data Models
- ✅ **Comprehensive Null Safety**: All models handle null values gracefully
- ✅ **BadgeModel Improvements**: Null-safe parsing dengan default values
- ✅ **UserModel Enhancements**: `.toString()` conversions untuk prevent type errors
- ✅ **ProjectModel Updates**: Added `isCompleted` field untuk completion tracking

### 🐛 Bug Fixes

#### Critical Fixes
- 🐛 Fixed OAuth "Connection reset by peer" error (network retry + profile creation)
- 🐛 Fixed "Users not visible to admin/other users" bug (RLS policies)
- 🐛 Fixed "type 'Null' is not a subtype of type 'String'" parsing errors
- 🐛 Fixed progress bar not showing full width at 100% completion

#### Feature Fixes
- 🐛 Fixed badge system not awarding badges after project completion
- 🐛 Fixed admin monitoring showing 0 users and incorrect progress
- 🐛 Fixed user can join project multiple times (added UNIQUE constraint)
- 🐛 Fixed role selection allowing full roles to be selected

### 📚 New Documentation

#### Setup & Configuration
- 📄 `COMPLETE_DATABASE_SCHEMA.sql` - All-in-one database setup (800+ lines)
- 📄 `README.md` - Updated with v2.0 features, troubleshooting, quick reference

#### Troubleshooting Guides
- 📄 `FIX_OAUTH_CONNECTION_RESET.md` - OAuth login issues dan solutions
- 📄 `FIX_USER_VISIBILITY.md` - Multi-user visibility RLS policy fix
- 📄 `ROLE_VALIDATION_FEATURE.md` - Complete role validation system docs

#### Feature Documentation
- 📄 `BADGE_SYSTEM_SETUP.md` - Badge system implementation guide
- 📄 `OAUTH_ANDROID_SETUP.md` - Android OAuth deep linking setup

#### Database Tools
- 📄 `database/triggers/auto_create_profile.sql` - Profile auto-creation trigger
- 📄 `database/fixes/fix_profiles_rls_for_oauth.sql` - OAuth-specific RLS fixes
- 📄 `database/fixes/fix_user_projects_rls.sql` - User projects visibility fix
- 📄 `database/debug/check_user_profile.sql` - Debug queries untuk user issues

### 🔧 Technical Improvements

#### Code Quality
- ✅ Added debug logging untuk OAuth flow dan profile loading
- ✅ Enhanced error messages dengan stack traces
- ✅ Try-catch blocks di all critical parsing functions
- ✅ Null safety throughout data models

#### Database
- ✅ Added verification queries di schema file
- ✅ Permission grants untuk authenticated users
- ✅ Service role policies untuk system operations
- ✅ ON CONFLICT clauses untuk prevent duplicates

#### Performance
- ✅ Database indexes pada user_id, project_id, status columns
- ✅ Optimized queries dengan proper JOINs
- ✅ Reduced database roundtrips dengan combined queries

### 🚀 Migration Guide

#### From v1.x to v2.0

**1. Backup Current Database**
```sql
-- Export data
pg_dump your_database > backup_v1.sql
```

**2. Run Complete Schema**
```sql
-- This will recreate all tables with new structure
-- WARNING: Drops existing tables!
COMPLETE_DATABASE_SCHEMA.sql
```

**3. Update Flutter Dependencies**
```bash
flutter pub get
```

**4. Test OAuth Flow**
- Delete test users from auth.users
- Clear app data
- Test Google OAuth login
- Verify profile auto-created

**5. Update Role Limits**
```sql
-- Set role_limits for existing multiplayer projects
UPDATE projects
SET role_limits = '{"frontend": 2, "backend": 2, "uiux": 1, "pm": 1}'::jsonb
WHERE mode = 'multiplayer' AND role_limits = '{}'::jsonb;
```

### ⚠️ Breaking Changes

1. **Database Schema Changes**
   - Added `role_limits` JSONB column to `projects` table
   - Changed `is_admin` boolean to `role` TEXT in `profiles` table
   - Added `assigned_role` TEXT column to `tasks` table

2. **RLS Policy Changes**
   - `profiles` now allows all authenticated users to SELECT (was: own profile only)
   - `user_projects` now allows all authenticated users to SELECT (was: own records only)
   - Added service_role policies untuk system operations

3. **Model Changes**
   - `UserModel.isAdmin` now computed from `role == 'admin'` (was: separate field)
   - `ProjectModel` added `isCompleted` boolean field
   - All models now use `.toString()` conversions untuk null safety

### 📊 Statistics

- **Total Files Changed**: 15+
- **New Files Created**: 10
- **Lines of Code Added**: 1500+
- **SQL Scripts Created**: 5
- **Documentation Pages**: 6
- **Bug Fixes**: 8 critical, 4 minor
- **Features Added**: 12

### 🎯 Future Roadmap

#### Planned Features (v2.1)
- [ ] Real-time notifications untuk project updates
- [ ] Chat/comments system untuk project collaboration
- [ ] File attachment untuk tasks
- [ ] Project templates untuk common use cases
- [ ] Advanced analytics dashboard untuk admin

#### Planned Improvements
- [ ] Offline mode dengan local storage
- [ ] Push notifications via Firebase
- [ ] Export project data ke PDF/Excel
- [ ] Dark mode support
- [ ] Multi-language support (i18n)

---

## Version 1.0 (Initial Release)

### Features
- Basic project management (solo/multiplayer)
- Role-based access control
- Task management system
- Badge system foundation
- Google OAuth login
- Admin dashboard
- Profile management

---

**For detailed upgrade instructions, see README.md**
