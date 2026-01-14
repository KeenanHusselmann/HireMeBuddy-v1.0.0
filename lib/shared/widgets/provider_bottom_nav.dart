import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/provider/screens/provider_dashboard_screen.dart';
import '../../features/provider/screens/provider_bookings_screen.dart';
import '../../features/provider/screens/provider_portfolio_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/provider/screens/provider_dashboard_screen.dart' show pendingBookingsCountProvider, unreadMessagesCountProvider;
import '../../features/chat/screens/conversations_screen.dart';

class ProviderBottomNav extends ConsumerStatefulWidget {
  const ProviderBottomNav({super.key});

  @override
  ConsumerState<ProviderBottomNav> createState() => _ProviderBottomNavState();
}

class _ProviderBottomNavState extends ConsumerState<ProviderBottomNav> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ProviderDashboardScreen(),
    ProviderBookingsScreen(),
    ProviderPortfolioScreen(),
    ConversationsScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pendingCountAsync = ref.watch(pendingBookingsCountProvider);
    final unreadCountAsync = ref.watch(unreadMessagesCountProvider);

    final pendingCount = pendingCountAsync.when(
      data: (count) => count,
      loading: () => 0,
      error: (_, __) => 0,
    );

    final unreadCount = unreadCountAsync.when(
      data: (count) => count,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.calendar_today_outlined),
                if (pendingCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        pendingCount > 9 ? '9+' : '$pendingCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            activeIcon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.calendar_today),
                if (pendingCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        pendingCount > 9 ? '9+' : '$pendingCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Bookings',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.photo_library_outlined),
            activeIcon: Icon(Icons.photo_library),
            label: 'Portfolio',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.chat_bubble_outline),
                if (unreadCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            activeIcon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.chat_bubble),
                if (unreadCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Messages',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
