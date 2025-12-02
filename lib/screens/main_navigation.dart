import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import 'home/home_screen.dart';
import 'projects/projects_screen.dart';
import 'profile/profile_screen.dart';
import 'admin/admin_manage_projects_screen.dart';
import 'admin/admin_monitoring_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    final List<Widget> screens = [
      isAdmin ? const AdminMonitoringScreen() : const HomeScreen(),
      isAdmin ? const AdminManageProjectsScreen() : const ProjectsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.border,
              width: 3.0,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: _buildIcon(
                isAdmin ? Icons.monitor_outlined : Icons.home_outlined, 
                0
              ),
              activeIcon: _buildIcon(
                isAdmin ? Icons.monitor : Icons.home, 
                0, 
                isActive: true
              ),
              label: isAdmin ? 'Monitor' : 'Home',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon(Icons.folder_outlined, 1),
              activeIcon: _buildIcon(Icons.folder, 1, isActive: true),
              label: isAdmin ? 'Manage' : 'Projects',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon(Icons.person_outline, 2),
              activeIcon: _buildIcon(Icons.person, 2, isActive: true),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(IconData icon, int index, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: isActive
          ? BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary,
                width: 2,
              ),
            )
          : null,
      child: Icon(icon),
    );
  }
}
