import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_google_bottom_nav.dart';

class StudentShellPage extends StatelessWidget {
  const StudentShellPage({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: AppGoogleBottomNav(
        selectedIndex: navigationShell.currentIndex,
        onSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: [
          AppGoogleNavItem(
            icon: Icons.quiz_rounded,
            label: 'Sınavlar',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
