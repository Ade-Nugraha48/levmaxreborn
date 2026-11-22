import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/navigation_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'home_page.dart';
import 'cardio_page.dart';
import 'stats_page.dart';
import 'profile_page.dart';

/// Main Shell Page containing IndexedStack for the 4 core tabs
/// and custom Neo-Gothic Cyberpunk Bottom Navigation Bar.
/// Conforms to `stitch_exports/05_home.html` and `docs/user_flow.md`.
class MainShellPage extends StatelessWidget {
  const MainShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = NavigationController.to;

    const List<Widget> pages = [
      HomePage(),
      CardioPage(),
      StatsPage(),
      ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(
        () => IndexedStack(
          index: nav.currentIndex.value,
          children: pages,
        ),
      ),
      bottomNavigationBar: Obx(() {
        final currentIndex = nav.currentIndex.value;

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0D1018),
            border: Border(
              top: BorderSide(
                color: Color(0xFF1E2538),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 12,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 60,
              child: Row(
                children: [
                  _buildNavItem(
                    index: 0,
                    currentIndex: currentIndex,
                    label: 'HOME',
                    icon: Icons.grid_view_outlined,
                    onTap: () => nav.changeTab(0),
                  ),
                  _buildNavItem(
                    index: 1,
                    currentIndex: currentIndex,
                    label: 'MAP',
                    icon: Icons.directions_run_outlined,
                    onTap: () => nav.changeTab(1),
                  ),
                  _buildNavItem(
                    index: 2,
                    currentIndex: currentIndex,
                    label: 'STATS',
                    icon: Icons.query_stats_outlined,
                    onTap: () => nav.changeTab(2),
                  ),
                  _buildNavItem(
                    index: 3,
                    currentIndex: currentIndex,
                    label: 'PROFILE',
                    icon: Icons.terminal_outlined,
                    onTap: () => nav.changeTab(3),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNavItem({
    required int index,
    required int currentIndex,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final bool isActive = index == currentIndex;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Active Top Diamond Indicator
            if (isActive)
              Positioned(
                top: 2,
                child: Text(
                  '◆',
                  style: TextStyle(
                    fontSize: 7,
                    color: AppColors.primary,
                    shadows: [
                      Shadow(
                        color: AppColors.primary.withValues(alpha: 0.8),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),

            // Icon and Label
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isActive) const SizedBox(height: 4),
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                  shadows: isActive
                      ? [
                          Shadow(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: AppTextStyles.labelMonoSmall(
                    color:
                        isActive ? AppColors.primary : AppColors.textSecondary,
                  ).copyWith(
                    fontSize: 9,
                    letterSpacing: 1.2,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
