# 📘 QuestForge - Project Management Mobile App

QuestForge is a mobile Project Management application with a **Neobrutalism** design style that delivers a visual, bold, and playful project management experience. The app facilitates team collaboration through solo/multiplayer project setup, role assignment, task management, and milestone tracking.

## ✨ Features

### 🔐 Authentication
- Simple login/registration with name and email
- Admin and regular user roles
- Persistent login state

### 👔 Admin Features
- **Create Projects**: Add new projects with name, description, deadline, and auto-generated project codes
- **View All Projects**: See all projects with member count, progress, and statistics
- **Project Management**: Manage all aspects of created projects

### 👤 User Features
- **Join Projects**: Join existing projects using project codes
- **Solo/Multiplayer Mode**: 
  - Solo: Handle all roles yourself
  - Multiplayer: Choose a specific role (Frontend, Backend, PM, UI/UX)
- **View My Projects**: See all projects you're part of
- **Role-based Task View**: See only tasks relevant to your role

### 📊 Project Features
- **Project Dashboard**: Visual overview with progress, members, milestones
- **Task Management**: 
  - Create tasks (PM only)
  - Assign to specific roles
  - Set priority (High, Medium, Low)
  - Update status (To-do, In Progress, Review, Done)
- **Milestone Tracking**:
  - Create and manage milestones
  - Automatic progress calculation based on task completion
  - Visual progress bars

### 🎨 Neobrutalism Design
- Bold, contrasting colors (Yellow #FFDA26, Cyan #00E0E0, Pink #FF69AD)
- Thick black borders (3-5px)
- Hard shadows (4px offset)
- Chunky, blocky UI elements
- High contrast and visual hierarchy

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio / VS Code
- An Android/iOS device or emulator

### Installation

1. **Clone the repository**
   ```bash
   cd questforge
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## 📱 How to Use

### First Time Setup
1. **Launch the app**
2. **Create an account**:
   - Enter your name and email
   - Check "Login as Admin" if you want to create projects
   - Or leave unchecked to join existing projects
3. **Click "Get Started"**

### For Admins
1. **Create a Project**:
   - From Home, click "Manage Projects"
   - Click "Create New Project"
   - Fill in project details (name, description, deadline)
   - Note the generated project code
2. **Share the code** with team members
3. **Manage Tasks**:
   - Open a project
   - Click "View Tasks"
   - Add tasks and assign to roles
4. **Track Milestones**:
   - Click "View Milestones"
   - Add milestones with target dates

### For Users
1. **Join a Project**:
   - From Home, click "My Projects"
   - Click "Join Project"
   - Enter the project code
   - Choose Solo mode or select your role
2. **View and Update Tasks**:
   - Open your project
   - Click "View Tasks"
   - See tasks assigned to your role
   - Click on a task to update its status
3. **Track Progress**:
   - View project dashboard for overall progress
   - Check milestone progress

## 🏗️ Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart
│   └── theme/
│       ├── app_colors.dart
│       └── app_theme.dart
├── data/
│   └── models/
│       ├── activity_log_model.dart
│       ├── milestone_model.dart
│       ├── project_model.dart
│       ├── project_user_model.dart
│       ├── task_model.dart
│       └── user_model.dart
├── providers/
│   ├── auth_provider.dart
│   └── project_provider.dart
├── screens/
│   ├── admin/
│   │   ├── add_project_screen.dart
│   │   └── admin_projects_screen.dart
│   ├── auth/
│   │   └── login_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── project/
│   │   ├── milestones_screen.dart
│   │   ├── project_detail_screen.dart
│   │   └── tasks_screen.dart
│   └── user/
│       ├── join_project_screen.dart
│       └── user_projects_screen.dart
├── widgets/
│   └── common/
│       ├── neo_button.dart
│       ├── neo_card.dart
│       ├── neo_progress_bar.dart
│       └── neo_text_field.dart
└── main.dart
```

## 🎯 Key Technologies

- **Flutter**: Cross-platform mobile framework
- **Provider**: State management
- **SharedPreferences**: Local data persistence
- **UUID**: Unique ID generation
- **Intl**: Date formatting

## 🎨 Design System

### Colors
- **Primary (Yellow)**: `#FFDA26` - Main actions, highlights
- **Secondary (Cyan)**: `#00E0E0` - Secondary actions, info
- **Accent (Pink)**: `#FF69AD` - Call-to-action, important elements
- **Background**: `#F5F5F5` - App background

### Role Colors
- **Frontend**: Purple `#6B5CE7`
- **Backend**: Green `#00D4AA`
- **Project Manager**: Red `#FF6B6B`
- **UI/UX**: Orange `#FF8C42`

### Status Colors
- **To-do**: Light Gray `#E5E5E5`
- **In Progress**: Yellow `#FFDA26`
- **Review**: Cyan `#00E0E0`
- **Done**: Green `#51CF66`

## 🔄 State Management

The app uses Provider for state management with two main providers:

1. **AuthProvider**: Manages user authentication and session
2. **ProjectProvider**: Manages all project-related data (projects, tasks, milestones, activity logs)

## 💾 Data Persistence

- User session data is stored using SharedPreferences
- App data is stored in-memory (resets on app restart)
- For production, consider integrating Firebase or a backend API

## 🚧 Future Enhancements

- [ ] Backend integration (Firebase/Node.js)
- [ ] Real-time updates
- [ ] Push notifications
- [ ] File attachments for tasks
- [ ] Comments and discussions
- [ ] Team chat
- [ ] Export project reports
- [ ] Dark mode option
- [ ] Custom project themes

## 📝 License

This project is created for educational purposes.

## 👥 Target Users

- Students working on group projects / capstone projects
- Freelancers
- Small teams needing simple PM tools
- Beginner Project Managers

## 🤝 Contributing

This is an educational project. Feel free to fork and enhance it for your own learning!

---

**Built with ❤️ using Flutter and Neobrutalism design principles**
# QuestForge
