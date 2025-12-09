# Project Completion Feature

## Overview
Fitur ini memungkinkan Project Manager untuk menandai project sebagai selesai dan memberikan badge kepada semua anggota tim secara otomatis.

## Changes Made

### 1. Database Migration (`database/migrations/add_project_completion.sql`)
**Kolom baru di tabel `projects`:**
- `status` - Status project: 'planning', 'in_progress', 'completed'
- `completed_at` - Timestamp kapan project diselesaikan

**Fungsi baru:**
- `complete_project(p_project_id, p_user_id)` - Menyelesaikan project dan award badges
  - Validasi: Hanya PM yang bisa complete
  - Validasi: Semua task harus status 'done'
  - Update project status menjadi 'completed'
  - Update semua user_projects menjadi 'completed' dengan progress 100%
  - Memanggil `check_and_award_badges()` untuk setiap team member

### 2. UI Changes (`lib/screens/projects/project_detail_screen.dart`)

**Tombol Complete Project:**
- Hanya muncul untuk PM
- Hanya muncul jika semua tasks sudah done
- Confirmation dialog dengan detail:
  - Jumlah team members
  - Daftar aksi yang akan dilakukan
  - Warning bahwa ini permanent action

**Fungsi baru:**
- `_canCompleteProject()` - Check apakah project bisa diselesaikan
- `_completeProject()` - Handle completion dengan confirmation

## How to Use

### Setup (Run Once)
1. Buka Supabase Dashboard → SQL Editor
2. Copy paste isi file `database/migrations/add_project_completion.sql`
3. Run migration

### Usage
1. Login sebagai PM dari suatu project
2. Pastikan semua tasks sudah status 'done' (checkbox tercentang)
3. Tombol **"Complete Project & Award Badges"** akan muncul di tab Tasks
4. Klik tombol → Konfirmasi
5. System akan:
   - Mark project sebagai completed
   - Set semua team member progress ke 100%
   - Award badges sesuai kriteria ke semua team members
6. Setelah 2 detik, auto redirect ke project list

## Benefits
✅ General tasks (assigned_role = null) tetap terhitung ke progress PM
✅ Badges otomatis diberikan saat project selesai
✅ Validasi di level database (RLS + function)
✅ UI yang jelas dengan confirmation
✅ Team members mendapat achievement secara otomatis

## Notes
- Progress PM sudah include general tasks sejak awal (via `calculate_user_progress`)
- Function `check_and_award_badges` sudah ada sebelumnya di `database/functions/check_and_award_badges.sql`
- Completed project tidak bisa di-uncomplete (permanent)
