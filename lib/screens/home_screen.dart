import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/permission_service.dart';
import '../services/notification_service.dart';
import '../main.dart';
import 'dashboard_tab.dart';
import 'tickets_tab.dart';
import 'leaderboard_tab.dart';
import 'profile_tab.dart';
import 'warehouse_tab.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String? _role;
  bool _roleLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  void _loadRole() async {
    final user = await ApiService.getUser();
    setState(() {
      _role = user?['role'];
      _roleLoaded = true;
    });
  }

  List<_NavItem> get _navItems {
    final items = <_NavItem>[];

    // Dashboard — semua role
    items.add(_NavItem(
      items.length,
      Icons.dashboard_outlined,
      Icons.dashboard,
      'Dashboard',
      DashboardTab(),
    ));

    // Tiket — semua role
    items.add(_NavItem(
      items.length,
      Icons.confirmation_number_outlined,
      Icons.confirmation_number,
      'Tiket',
      TicketsTab(),
    ));

    // Gudang — hanya admin, superadmin, admin_gudang
    if (PermissionService.canSeeWarehouse(_role)) {
      items.add(_NavItem(
        items.length,
        Icons.inventory_2_outlined,
        Icons.inventory_2,
        'Gudang',
        WarehouseTab(),
      ));
    }

    // Leaderboard — semua kecuali teknisi
    if (PermissionService.canSeeLeaderboard(_role)) {
      items.add(_NavItem(
        items.length,
        Icons.leaderboard_outlined,
        Icons.leaderboard,
        'Ranking',
        LeaderboardTab(),
      ));
    }

    // Profil — semua role
    items.add(_NavItem(
      items.length,
      Icons.person_outline,
      Icons.person,
      'Profil',
      ProfileTab(),
    ));

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? Color(0xFF2563eb) : Color(0xFFdc2626);
    final bgColor = isDark ? Color(0xFF1e293b) : Colors.white;
    final unselectedColor =
    isDark ? Color(0xFF64748b) : Color(0xFF94a3b8);

    if (!_roleLoaded) {
      return Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: primary)),
      );
    }

    final items = _navItems;

    if (_currentIndex >= items.length) {
      _currentIndex = 0;
    }

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: items.map((i) => i.screen).toList(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bgColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items
                  .map((item) => _navItemWidget(
                item,
                primary,
                unselectedColor,
              ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItemWidget(
      _NavItem item, Color primary, Color unselected) {
    final isActive = _currentIndex == item.index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = item.index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? item.activeIcon : item.icon,
              color: isActive ? primary : unselected,
              size: 22,
            ),
            SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? primary : unselected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final int index;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget screen;

  _NavItem(this.index, this.icon, this.activeIcon, this.label,
      this.screen);
}