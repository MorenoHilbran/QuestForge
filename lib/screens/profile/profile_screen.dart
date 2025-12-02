import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/neo_button.dart';
import '../../widgets/common/neo_card.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.border,
            height: 3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Card
            NeoCard(
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary,
                    backgroundImage: user.avatarUrl != null &&
                            user.avatarUrl!.isNotEmpty
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                        ? Text(
                            user.name[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: AppConstants.spacingM),

                  // Name
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingS),

                  // Email
                  Text(
                    user.email,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingM),

                  // Admin badge
                  if (user.isAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingM,
                        vertical: AppConstants.spacingS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        border: Border.all(
                          color: AppColors.border,
                          width: AppConstants.borderWidth,
                        ),
                        borderRadius:
                            BorderRadius.circular(AppConstants.borderRadius),
                      ),
                      child: const Text(
                        'ADMIN',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),

                  // Bio
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: AppConstants.spacingM),
                    Text(
                      user.bio!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),

            // Badges Section
            const Text(
              'Badges Earned',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),

            user.badges.isEmpty
                ? NeoCard(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.spacingL),
                        child: Column(
                          children: const [
                            Icon(
                              Icons.badge_outlined,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(height: AppConstants.spacingM),
                            Text(
                              'No badges yet',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: AppConstants.spacingS),
                            Text(
                              'Complete projects to earn badges!',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: AppConstants.spacingM,
                      mainAxisSpacing: AppConstants.spacingM,
                    ),
                    itemCount: user.badges.length,
                    itemBuilder: (context, index) {
                      final badge = user.badges[index];
                      return _buildBadgeCard(badge.name, badge.tier ?? '');
                    },
                  ),

            const SizedBox(height: AppConstants.spacingL),

            // Edit Profile button
            NeoButton(
              text: 'Edit Profile',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const EditProfileScreen(),
                  ),
                );
              },
              color: AppColors.secondary,
              icon: Icons.edit,
            ),

            const SizedBox(height: AppConstants.spacingM),

            // Logout button
            NeoButton(
              text: 'Logout',
              onPressed: () async {
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (_) => const LoginScreen()),
                  );
                }
              },
              color: AppColors.error,
              icon: Icons.logout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeCard(String name, String tier) {
    Color badgeColor;
    switch (tier) {
      case 'legend':
        badgeColor = const Color(0xFFFFD700); // Gold
        break;
      case 'master':
        badgeColor = const Color(0xFFC0C0C0); // Silver
        break;
      case 'senior':
        badgeColor = const Color(0xFFCD7F32); // Bronze
        break;
      default:
        badgeColor = AppColors.primary;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: AppColors.border,
          width: AppConstants.borderWidth,
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.border,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.badge,
              color: Colors.black,
              size: 24,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
