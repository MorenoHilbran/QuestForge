# Setup Database QuestForge - Instruksi Singkat

## Problem
Terjadi error saat user signup: `Database error saving new user`

## Solusi (Untuk yang punya akses Supabase)

### Langkah 1: Buka Supabase
1. Login ke https://supabase.com
2. Pilih project: `ijimywkjjewkleloksrs`
3. Klik menu **SQL Editor** di sidebar kiri

### Langkah 2: Jalankan Schema
**Pilih SALAH SATU:**

**Opsi A (Recommended - Paling Sederhana):**
1. Buka file: `PRODUCTION_READY_SCHEMA.sql`
2. Copy semua isinya
3. Paste di SQL Editor Supabase
4. Klik **Run** atau tekan `Ctrl+Enter`
5. Tunggu sampai selesai (✅ Success)

**Opsi B (Lebih Lengkap):**
1. Buka file: `COMPLETE_DATABASE_SCHEMA_V2.sql`
2. Copy semua isinya
3. Paste di SQL Editor Supabase
4. Klik **Run**
5. Tunggu sampai selesai

### Langkah 3: Verifikasi
Jalankan query ini untuk cek apakah berhasil:
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```

Harus muncul minimal:
- profiles
- projects
- user_projects
- milestones
- tasks
- badges
- user_badges
- activity_logs

### Langkah 4: Test
Minta teman coba signup lagi di aplikasi.

---

## Kalau Masih Error
Jalankan file-file ini secara berurutan:
1. `database/fixes/ULTIMATE_FIX.sql`
2. `database/fixes/allow_user_registration.sql`

---

**Status:** Database schema belum di-setup dengan benar. Setelah SQL dijalankan, aplikasi akan berfungsi normal.
