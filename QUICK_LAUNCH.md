# QuestForge V2 - 5 Minute Quick Start

## Your Credentials
```
URL:      https://ijimywkjjewkleloksrs.supabase.co
Anon Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlqaW15d2tqamV3a2xlbG9rc3JzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUxOTIyNzgsImV4cCI6MjA4MDc2ODI3OH0.05qAPNIxU6CpL9Xku-PUSLEcSH1qHhT1PpAX8wPRkPg
```

---

## ✅ What's Already Done

1. **Database**: Schema deployed to Supabase ✅
2. **Environment**: `.env` file created with credentials ✅
3. **Code**: All Flutter code complete & V2-compatible ✅
4. **Documentation**: Full guides created ✅

---

## 🚀 Launch in 5 Steps

### 1️⃣ Open Terminal (1 min)
```powershell
cd d:\Nigga\QuestForge
```

### 2️⃣ Install Dependencies (2 min)
```powershell
flutter clean
flutter pub get
```

### 3️⃣ Run App (1 min)
```powershell
flutter run
```
Choose device when prompted.

### 4️⃣ Test Login (1 min)
- Enter any email
- Enter password
- Click "Sign Up"
- Should auto-create profile

### 5️⃣ Done! 🎉

---

## 🧪 Quick Test

**Test Admin:**
```
Email: admin@test.com
Password: Admin123!@
```
Then update in Supabase:
```sql
UPDATE profiles SET role = 'admin' WHERE email = 'admin@test.com';
```

Create a project → Should auto-generate 6-char code!

---

## 📱 Run on Different Devices

**Web (Chrome):**
```powershell
flutter run -d chrome
```

**Windows Desktop:**
```powershell
flutter run -d windows
```

**Android Emulator:**
```powershell
flutter run -d android-emulator
```

---

## 📚 Full Documentation

| Doc | Purpose |
|-----|---------|
| `ENVIRONMENT_SETUP.md` | Complete setup guide with troubleshooting |
| `DEPLOYMENT_CHECKLIST.md` | Pre-launch verification |
| `SETUP_GUIDE_V2.md` | Step-by-step deployment instructions |
| `TESTING_CHECKLIST.md` | 150+ test cases |
| `QUICK_START.md` | Originally created guide |

---

## ✨ V2 Features Ready

- ✅ Project codes (auto-generated)
- ✅ Task claiming system
- ✅ Auto-progress calculation
- ✅ Auto-badge awards
- ✅ PM approval workflow
- ✅ Activity logging
- ✅ Milestone support
- ✅ RLS security

---

## ❌ If Error: "Supabase env vars not found"

**Fix:**
1. Check `.env` file exists at `d:\Nigga\QuestForge\.env`
2. Verify credentials are correct
3. Run: `flutter clean && flutter pub get`
4. Run: `flutter run` again

---

## 🐛 If Database Error

**Verify database schema:**
1. Open Supabase Dashboard
2. Go to SQL Editor
3. Run:
```sql
SELECT COUNT(*) FROM profiles;
```

Should return `0` (or your test data).

If error: Database schema not deployed yet. Contact admin.

---

## ✅ Status: READY TO LAUNCH 🚀

Everything configured. Just run `flutter run`!

Questions? Check `ENVIRONMENT_SETUP.md` for detailed guide.
