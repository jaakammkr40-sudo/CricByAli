import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'home_screen.dart';
import 'score/score_home_screen.dart';
import 'profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [
          HomeScreen(),
          ScoreHomeScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          backgroundColor: AppColors.bgDeep,
          indicatorColor: AppColors.primary.withOpacity(0.25),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.emoji_events_outlined),
              selectedIcon: Icon(Icons.emoji_events, color: AppColors.secondary),
              label: 'Tournament',
            ),
            NavigationDestination(
              icon: Icon(Icons.sports_cricket_outlined),
              selectedIcon:
                  Icon(Icons.sports_cricket, color: AppColors.secondary),
              label: 'Score',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppColors.secondary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
