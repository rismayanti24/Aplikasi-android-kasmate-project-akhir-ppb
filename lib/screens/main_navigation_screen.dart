import 'package:flutter/material.dart';
import '../data/kas_store.dart';
import 'home_screen.dart';
import 'statistik_screen.dart';
import 'buat_tagihan_screen.dart';
import 'notifikasi_screen.dart';
import 'profil_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeScreen(),
      StatistikScreen(onBack: () => setState(() => _currentIndex = 0)),
      const SizedBox.shrink(), // Index 2 dialihkan untuk membuka BuatTagihanScreen
      const NotifikasiScreen(),
      const ProfilScreen(),
    ];
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      // Tombol tengah (+) langsung membuka modal / halaman Buat Tagihan
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BuatTagihanScreen()),
      );
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: _pages[_currentIndex],
      bottomNavigationBar: ValueListenableBuilder<KasRootState>(
        valueListenable: kasStore,
        builder: (context, _, __) {
          final unreadCount = kasStore.jumlahNotifikasiBelumDibaca;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: const Color(0xFF074E3B),
              unselectedItemColor: const Color(0xFF6B7280),
              showSelectedLabels: false,
              showUnselectedLabels: false,
              elevation: 0,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_outlined),
                  activeIcon: Icon(Icons.bar_chart_rounded),
                  label: 'Statistik',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF074E3B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  activeIcon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF074E3B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  label: 'Buat Tagihan',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text('$unreadCount'),
                    backgroundColor: const Color(0xFFEF4444),
                    child: const Icon(Icons.notifications_none_rounded),
                  ),
                  activeIcon: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text('$unreadCount'),
                    backgroundColor: const Color(0xFFEF4444),
                    child: const Icon(Icons.notifications_rounded),
                  ),
                  label: 'Notifikasi',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Profil',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
