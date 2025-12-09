# QuestForge V2 Testing Checklist

**Date:** December 8, 2025  
**Version:** 2.0  
**Tester:** _______________  
**Environment:** _______________

---

## 🗄️ Database Setup Tests

### Schema Deployment
- [ ] Executed COMPLETE_DATABASE_SCHEMA_V2.sql successfully
- [ ] No errors in Supabase SQL execution
- [ ] Success message received

### Tables Created (8 total)
- [ ] `profiles` table exists
- [ ] `projects` table exists with code, requires_approval, deleted_at fields
- [ ] `tasks` table exists with assigned_user_id, claimed_at, milestone_id
- [ ] `user_projects` table exists with approval_status, approved_by, approved_at
- [ ] `milestones` table exists with title, is_completed, order_index
- [ ] `badges` table exists
- [ ] `user_badges` table exists
- [ ] `activity_logs` table exists with action, target_type, metadata

### Functions Created (8 total)
- [ ] `generate_project_code()` exists
- [ ] `check_and_award_badges()` exists
- [ ] `calculate_user_progress()` exists
- [ ] `update_project_progress()` exists
- [ ] `log_activity()` exists
- [ ] `handle_new_user()` exists
- [ ] `update_updated_at_column()` exists
- [ ] `check_role_limits()` exists

### Triggers Created (13 total)
- [ ] `auto_generate_project_code_trigger` exists
- [ ] `update_project_progress_trigger` exists
- [ ] `log_project_created_trigger` exists
- [ ] `log_task_created_trigger` exists
- [ ] `log_task_claimed_trigger` exists
- [ ] `log_task_completed_trigger` exists
- [ ] `award_badges_on_task_complete_trigger` exists
- [ ] All other triggers exist (check in Supabase dashboard)

### RLS Policies
- [ ] RLS enabled on all tables
- [ ] Can query own profile
- [ ] Can view public projects
- [ ] Can only edit own data
- [ ] Admin can edit all data

---

## 🎨 UI/UX Tests

### Registration & Login
- [ ] Can register new account
- [ ] Email validation works
- [ ] Password requirements enforced
- [ ] Can login with credentials
- [ ] Profile auto-created in `profiles` table
- [ ] Default role set to 'user'

### Home Screen
- [ ] Projects load and display
- [ ] Can filter by difficulty (easy/medium/hard)
- [ ] Project cards show correct info
- [ ] Project full indicator works (calculatedMaxMembers)
- [ ] Only approved members counted
- [ ] Join button appears for non-joined projects

### Project Creation
- [ ] Can create solo project
- [ ] Can create multiplayer project
- [ ] Project code auto-generated (6 chars, uppercase)
- [ ] Code is unique
- [ ] Can set difficulty
- [ ] Can set requires_approval
- [ ] Can set role limits for multiplayer

---

## 🎯 Core Feature Tests

### 1. Project Codes
- [ ] Every new project has a code
- [ ] Code is exactly 6 characters
- [ ] Code is uppercase
- [ ] Code is alphanumeric
- [ ] Code is unique (create 5 projects, check all different)
- [ ] Code displays in project detail screen
- [ ] Copy button works for project code
- [ ] Can join project via code (JoinWithCodeScreen)
- [ ] Invalid code shows error
- [ ] Deleted project code shows error

### 2. Auto Progress Calculation
- [ ] Create project with 0 tasks → progress = 0%
- [ ] Add 4 tasks → progress still 0%
- [ ] Complete 1 task → progress = 25%
- [ ] Complete 2 tasks → progress = 50%
- [ ] Complete 3 tasks → progress = 75%
- [ ] Complete 4 tasks → progress = 100%
- [ ] Progress updates WITHOUT manual app code
- [ ] Check `user_projects.progress` in database
- [ ] Progress shows correctly in UI

### 3. Auto Badge Awards
- [ ] Complete 1 task → "First Steps" badge awarded
- [ ] Complete 5 tasks → "Task Master" badge awarded
- [ ] Complete 10 tasks → "Veteran" badge awarded
- [ ] Complete project → "Project Complete" badge awarded
- [ ] Check `user_badges` table for entries
- [ ] Badges appear in profile screen
- [ ] No RPC calls from app (check code)

### 4. Task Claiming
- [ ] Unclaimed task shows "Claim Task" button
- [ ] Click claim → confirmation dialog appears
- [ ] Confirm → task assigned to user
- [ ] `assigned_user_id` set in database
- [ ] `claimed_at` timestamp set
- [ ] Task auto-moves to "in_progress" status
- [ ] Claimed task shows "Claimed by you" badge
- [ ] Other users see "Claimed" badge (not claim button)
- [ ] Can complete claimed task

### 5. PM Approval Workflow

#### Project with requires_approval = true
- [ ] Create multiplayer project with requires_approval = true
- [ ] User requests to join
- [ ] `approval_status` set to 'pending'
- [ ] Join message says "Waiting for PM approval"
- [ ] PM opens PMApprovalScreen
- [ ] Pending request appears in list
- [ ] PM can see user info, role, join date

#### PM Approves
- [ ] Click approve button
- [ ] `approval_status` changes to 'approved'
- [ ] `approved_by` set to PM user_id
- [ ] `approved_at` timestamp set
- [ ] User can now access project
- [ ] User appears in team list

#### PM Rejects
- [ ] PM clicks reject button
- [ ] `approval_status` changes to 'rejected'
- [ ] `approved_by` set to PM user_id
- [ ] `approved_at` timestamp set
- [ ] User removed from project access

#### Project with requires_approval = false
- [ ] User joins project
- [ ] `approval_status` auto-set to 'approved'
- [ ] No PM approval needed
- [ ] User immediately has access

### 6. Activity Logging
- [ ] Create project → activity log created
- [ ] Join project → activity log created
- [ ] Create task → activity log created
- [ ] Claim task → activity log created
- [ ] Complete task → activity log created
- [ ] Complete milestone → activity log created
- [ ] Earn badge → activity log created
- [ ] Check `activity_logs` table
- [ ] Logs have correct action type
- [ ] Logs have correct target_type and target_id
- [ ] Logs have metadata (JSON)
- [ ] Activity feed displays in profile (if implemented)

---

## 🔍 Advanced Tests

### Role Limits
- [ ] Set developer limit = 2 in project
- [ ] 2 developers join successfully
- [ ] 3rd developer blocked from joining
- [ ] Error message shows "Role full"
- [ ] calculatedMaxMembers works correctly

### Soft Delete
- [ ] Admin deletes project (sets deleted_at)
- [ ] Project doesn't appear in browse list
- [ ] Can't join via code
- [ ] Error message: "Project not found or deleted"
- [ ] Database record still exists (not hard deleted)

### Member Filtering
- [ ] Project has 5 users: 2 approved, 2 pending, 1 rejected
- [ ] Only 2 approved members show in team list
- [ ] Project member count = 2
- [ ] Project not marked as full (if limit > 2)

### Milestone Completion
- [ ] Create milestone with 3 tasks
- [ ] Complete 3 tasks
- [ ] Milestone auto-marked as completed (if implemented)
- [ ] `milestones.is_completed` = true
- [ ] `milestones.completed_at` timestamp set

### Multiple Users
- [ ] User A creates project
- [ ] User B joins project
- [ ] User C joins project
- [ ] Each has separate progress tracking
- [ ] User A completes task → only User A progress updates
- [ ] User B completes different task → only User B progress updates
- [ ] Each user sees own progress in user_projects

---

## 🐛 Error Handling Tests

### Invalid Inputs
- [ ] Join with invalid code (too short) → error
- [ ] Join with invalid code (too long) → error
- [ ] Join with non-existent code → error
- [ ] Join already-joined project → error
- [ ] Claim already-claimed task → appropriate message
- [ ] Create project with empty title → validation error

### Network Issues
- [ ] Disconnect internet → graceful error message
- [ ] Reconnect → app recovers
- [ ] Offline actions queued (if implemented)

### Permission Tests
- [ ] Non-member can't see private project details
- [ ] Non-PM can't access PMApprovalScreen
- [ ] Non-admin can't delete projects
- [ ] User can't edit other users' data

---

## 📊 Performance Tests

### Load Times
- [ ] Home screen loads < 2 seconds
- [ ] Project detail loads < 1 second
- [ ] Task list loads < 1 second
- [ ] Smooth scrolling with 50+ projects

### Database Performance
- [ ] Progress calculation < 100ms (check Supabase logs)
- [ ] Badge checking < 100ms
- [ ] Activity logging < 50ms
- [ ] Indexes used (check query plans)

---

## 🔐 Security Tests

### RLS Policies
- [ ] Logged-out user can't access data
- [ ] User can't modify other users' profiles
- [ ] User can't fake PM status
- [ ] User can't bypass approval workflow
- [ ] Admin can access all data

### SQL Injection
- [ ] Project title with SQL → safely escaped
- [ ] Task description with SQL → safely escaped
- [ ] Code search with special chars → safe

---

## 📱 Cross-Platform Tests

### Android
- [ ] App runs on Android
- [ ] All features work
- [ ] No platform-specific crashes

### iOS
- [ ] App runs on iOS
- [ ] All features work
- [ ] No platform-specific crashes

### Web
- [ ] App runs in Chrome
- [ ] App runs in Firefox
- [ ] App runs in Edge
- [ ] All features work

### Desktop (Windows)
- [ ] App runs on Windows
- [ ] All features work
- [ ] No desktop-specific issues

---

## ✅ Final Verification

### Code Quality
- [ ] No manual progress calculation in code
- [ ] No manual badge checking in code
- [ ] All V2 fields used correctly
- [ ] No deprecated V1 code remains
- [ ] Comments added for V2 changes

### Documentation
- [ ] SETUP_GUIDE_V2.md is accurate
- [ ] V2_IMPLEMENTATION_COMPLETE.md is comprehensive
- [ ] TESTING_CHECKLIST.md (this file) is complete
- [ ] README updated with V2 info (if needed)

### Database
- [ ] All triggers firing correctly
- [ ] All functions executing correctly
- [ ] All RLS policies enforced
- [ ] Indexes improving query speed

---

## 🎯 Test Results Summary

**Date Tested:** _______________  
**Tested By:** _______________

**Total Tests:** 150+  
**Passed:** _____  
**Failed:** _____  
**Skipped:** _____

**Critical Issues Found:**
1. _______________
2. _______________
3. _______________

**Minor Issues Found:**
1. _______________
2. _______________
3. _______________

**Recommendations:**
_______________________________________________
_______________________________________________
_______________________________________________

**Overall Status:** [ ] PASS  [ ] FAIL  [ ] NEEDS WORK

---

## 📝 Notes

_______________________________________________
_______________________________________________
_______________________________________________
_______________________________________________
_______________________________________________

---

**Sign-off:**

Tester: _______________  Date: _______________  
Reviewer: _______________  Date: _______________  
Approved: _______________  Date: _______________
