# Role-Based Task Assignment for Multiplayer Projects

## Fitur
Pada mode **multiplayer**, Project Manager dapat:
1. Assign task ke role tertentu (designer, frontend, backend, dll)
2. Task yang di-assign hanya bisa di-claim/dikerjakan oleh user dengan role tersebut
3. Task tanpa assigned_role bisa dikerjakan oleh semua role

## UI Changes
### Task Creation Dialog
- Dropdown "Assign to Role" muncul untuk multiplayer projects
- Pilihan role diambil dari team members yang sudah join
- "Any role" = task bisa dikerjakan siapa saja

### Task Display
- **Solo Mode**: Tasks ditampilkan dalam list biasa
- **Multiplayer Mode**: Tasks dikelompokkan per section berdasarkan role
  - Section "General Tasks (Any Role)" untuk unassigned tasks
  - Section per role (Designer, Frontend, Backend, dll)
  - Setiap section menampilkan progress: X/Y tasks completed
  - Lock icon (🔒) pada task yang tidak bisa di-claim (beda role)

## Database Changes
### New Column
```sql
ALTER TABLE tasks ADD COLUMN assigned_role TEXT;
```

### RLS Policies
1. **tasks_claim_role_based**: User hanya bisa update task jika:
   - Member aktif di project
   - Task belum di-claim atau sudah di-claim oleh mereka
   - assigned_role = user's role ATAU assigned_role NULL

2. **tasks_assign_role_pm**: PM/Admin bisa update semua tasks termasuk assigned_role

## How to Apply
1. Jalankan migration SQL:
```bash
# Copy isi file database/migrations/add_assigned_role_to_tasks.sql
# Paste di Supabase SQL Editor
# Run query
```

2. Hot reload Flutter app

## Testing
1. **Create Multiplayer Project** sebagai admin
2. **Add team members** dengan berbagai role (designer, frontend, backend)
3. **Create tasks**:
   - Buat task dengan assigned_role = "frontend"
   - Buat task dengan assigned_role = "backend"
   - Buat task tanpa assigned_role (any role)
4. **Login sebagai user dengan role frontend**:
   - Lihat bahwa tasks ter-section berdasarkan role
   - Task frontend bisa di-claim
   - Task backend ada lock icon, tidak bisa di-claim
   - Task "any role" bisa di-claim
5. **Verify RLS**: User dengan role frontend tidak bisa claim task backend

## Notes
- Solo projects tidak terpengaruh (semua task bisa dikerjakan)
- Admin dan PM bisa mengerjakan semua task (bypass role restriction)
- Progress calculation tetap per user (hanya task yang di-claim/assigned ke user)
