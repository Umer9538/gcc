import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/app_provider.dart';
import '../../constants/app_constants.dart';
import 'dashboard_screen.dart';
import '../meetings/meetings_screen.dart';
import '../announcements/announcements_screen.dart';
import '../directory/directory_screen.dart';
import '../documents/documents_screen.dart';
import '../messaging/messaging_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const MeetingsScreen(),
    const AnnouncementsScreen(),
    const DocumentsScreen(),
    const MessagingScreen(),
    const DirectoryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer2<app_auth.AuthProvider, AppProvider>(
      builder: (context, authProvider, appProvider, child) {
        final isRTL = appProvider.isRTL;

        return Scaffold(
          body: _screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            selectedFontSize: 11,
            unselectedFontSize: 10,
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            selectedItemColor: AppColors.primaryColor,
            unselectedItemColor: AppColors.textSecondaryColor,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.dashboard_outlined),
                activeIcon: const Icon(Icons.dashboard),
                label: isRTL ? 'الرئيسية' : 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.event_outlined),
                activeIcon: const Icon(Icons.event),
                label: isRTL ? 'الاجتماعات' : 'Meetings',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.announcement_outlined),
                activeIcon: const Icon(Icons.announcement),
                label: isRTL ? 'الإعلانات' : 'Announcements',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.description_outlined),
                activeIcon: const Icon(Icons.description),
                label: isRTL ? 'الوثائق' : 'Documents',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.message_outlined),
                activeIcon: const Icon(Icons.message),
                label: isRTL ? 'الرسائل' : 'Messages',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.people_outlined),
                activeIcon: const Icon(Icons.people),
                label: isRTL ? 'الموظفين' : 'Directory',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outlined),
                activeIcon: const Icon(Icons.person),
                label: isRTL ? 'الملف الشخصي' : 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}