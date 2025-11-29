# 🚀 Quick Start Guide - QuestForge

## Running the App

1. **Open Terminal in project directory**
2. **Get dependencies**:
   ```bash
   flutter pub get
   ```
3. **Run the app**:
   ```bash
   flutter run
   ```

## Testing the App

### Scenario 1: Admin Creating a Project

1. **Login as Admin**
   - Name: `Alice Admin`
   - Email: `alice@example.com`
   - ✅ Check "Login as Admin"
   - Click "Get Started"

2. **Create a Project**
   - Click "Manage Projects"
   - Click "Create New Project"
   - Project Name: `Mobile App Development`
   - Description: `Building our awesome mobile app`
   - Select a deadline (e.g., 30 days from now)
   - Click "Create Project"
   - **Note the project code** (e.g., "ABC123")

3. **Add Tasks**
   - Open the project
   - Click "View Tasks"
   - Click "Add Task"
   - Title: `Design Login Screen`
   - Select Role: `UI/UX`
   - Priority: `High`
   - Click "Add"
   - Repeat for more tasks:
     - `Implement Login API` → Backend → Medium
     - `Create Login Form` → Frontend → High

4. **Add Milestones**
   - Go back to project detail
   - Click "View Milestones"
   - Click "Add Milestone"
   - Name: `Phase 1 - Authentication`
   - Select target date
   - Click "Add"

### Scenario 2: User Joining a Project

1. **Logout** (top right icon in Home)

2. **Login as User**
   - Name: `Bob Developer`
   - Email: `bob@example.com`
   - ❌ Don't check "Login as Admin"
   - Click "Get Started"

3. **Join the Project**
   - Click "My Projects"
   - Click "Join Project"
   - Enter the project code from step 1 (e.g., "ABC123")
   - Select your role: `Frontend`
   - Click "Join Project"

4. **View Your Tasks**
   - Open the project
   - Click "View Tasks"
   - You'll only see tasks assigned to "Frontend"
   - Click on a task
   - Update status: `In Progress`

5. **Check Progress**
   - Go back to project detail
   - See the progress bar update automatically

### Scenario 3: Solo Project

1. **Join Project in Solo Mode**
   - Click "Join Project"
   - Enter project code
   - ✅ Check "Solo Project"
   - Click "Join Project"
   - You'll now see ALL tasks from all roles

## Key Features to Test

### ✅ Authentication
- [x] Login as Admin
- [x] Login as User
- [x] Persistent login
- [x] Logout

### ✅ Admin Features
- [x] Create project with auto-generated code
- [x] View all admin projects
- [x] View project statistics
- [x] Add tasks to any role
- [x] Add milestones

### ✅ User Features
- [x] Join project with code
- [x] Solo mode (all roles)
- [x] Multiplayer mode (single role)
- [x] View role-specific tasks
- [x] Update task status
- [x] View project progress

### ✅ Design Features
- [x] Neobrutalism theme
- [x] Bold colors
- [x] Thick borders
- [x] Hard shadows
- [x] Chunky UI elements

## Common Use Cases

### Use Case 1: Team Capstone Project
1. One student logs in as Admin
2. Creates the capstone project
3. Shares project code with team
4. Each team member:
   - Logs in as User
   - Joins with their role (Frontend/Backend/UI/UX)
5. PM adds tasks for each role
6. Team members update task progress
7. Everyone tracks milestone progress

### Use Case 2: Freelancer Solo Project
1. Login as User
2. Join a project (or have someone create one)
3. Choose "Solo Project"
4. See and manage all tasks
5. Track own progress

### Use Case 3: Small Team Collaboration
1. Admin creates multiple projects
2. Team members join different projects
3. PM assigns tasks
4. Regular check-ins on progress
5. Milestone tracking for deadlines

## Troubleshooting

### App won't run?
```bash
flutter clean
flutter pub get
flutter run
```

### No data showing?
- Data is stored in-memory
- Restarting the app clears all data
- Create new projects and users after restart

### Can't see tasks?
- Check if you're viewing the correct project
- Users only see tasks for their role
- PM/Admin see all tasks

## Tips & Tricks

1. **Project Codes**: Write them down! They're needed for joining
2. **Role Selection**: Choose your role carefully in multiplayer mode
3. **Solo Mode**: Perfect for personal projects or testing
4. **Task Status**: Update regularly to keep progress accurate
5. **Milestones**: Progress updates automatically based on task completion

## Next Steps

After testing, consider:
- Adding more roles/statuses
- Customizing colors
- Adding backend integration
- Implementing real-time sync
- Adding notifications

---

**Happy Project Managing! 🎯**
