import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/permission_service.dart';
import '../services/notification_service.dart';
import '../main.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'notification_settings_screen.dart';

class ProfileTab extends StatefulWidget {
  @override
  _ProfileTabState createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic>? user;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  void loadUser() async {
    setState(() => isLoading = true);
    final u = await ApiService.getUserFresh();
    setState(() {
      user = u;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? Color(0xFF2563eb) : Color(0xFFdc2626);
    final name = user?['name'] ?? 'User';
    final email = user?['email'] ?? '';
    final role = user?['role'] ?? '';
    final phone = user?['phone'] ?? '-';
    final department = user?['department'] ?? '-';
    final points = user?['total_points'] ?? 0;
    final avatar = user?['avatar'] ?? '';

    return Scaffold(
      backgroundColor:
      isDark ? Color(0xFF0f172a) : Color(0xFFf1f5f9),
      appBar: AppBar(
        title: Text('Profil',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
                isDark
                    ? Icons.wb_sunny_outlined
                    : Icons.nightlight_round),
            onPressed: () => MyApp.of(context)?.toggleTheme(),
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: loadUser,
          ),
        ],
      ),
      body: isLoading
          ? Center(
          child: CircularProgressIndicator(color: primary))
          : SingleChildScrollView(
        child: Column(
          children: [
            // Header gradient
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [Color(0xFF1e3a5f), Color(0xFF0f172a)]
                      : [Color(0xFFb91c1c), Color(0xFF7f1d1d)],
                ),
              ),
              child: Column(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white24,
                        backgroundImage: avatar.isNotEmpty
                            ? NetworkImage(avatar)
                            : null,
                        child: avatar.isEmpty
                            ? Text(
                            name.isNotEmpty
                                ? name[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                                fontSize: 36,
                                color: Colors.white,
                                fontWeight:
                                FontWeight.bold))
                            : null,
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(name,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                    child: Text(
                      PermissionService.getRoleLabel(role),
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Poin untuk teknisi
                  if (PermissionService.isTeknisi(role))
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star,
                              color: Colors.amber,
                              size: 20),
                          SizedBox(width: 8),
                          Text('$points Poin',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight:
                                  FontWeight.bold,
                                  fontSize: 16)),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Info Card
                  _card(isDark, [
                    _sectionTitle('Informasi Akun'),
                    SizedBox(height: 12),
                    _infoRow(Icons.email_outlined,
                        'Email', email, primary),
                    _divider(),
                    _infoRow(Icons.phone_outlined,
                        'No. HP', phone, primary),
                    _divider(),
                    _infoRow(
                        Icons.business_outlined,
                        'Departemen',
                        department,
                        primary),
                  ]),
                  SizedBox(height: 12),

                  // Menu Card
                  _card(isDark, [
                    _sectionTitle('Pengaturan Akun'),
                    SizedBox(height: 8),
                    _menuItem(
                      Icons.edit_outlined,
                      'Edit Profil',
                      'Ubah nama, no. HP, departemen',
                      primary,
                          () async {
                        final result =
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  EditProfileScreen(
                                      user: user!)),
                        );
                        if (result == true) loadUser();
                      },
                    ),
                    _divider(),
                    _menuItem(
                      Icons.lock_outline,
                      'Ganti Password',
                      'Ubah password akun kamu',
                      primary,
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                ChangePasswordScreen()),
                      ),
                    ),
                    _divider(),
                    _menuItem(
                      Icons.notifications_outlined,
                      'Notifikasi',
                      'Atur preferensi notifikasi',
                      primary,
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                NotificationSettingsScreen()),
                      ),
                    ),
                  ]),
                  SizedBox(height: 12),

                  // App Info
                  _card(isDark, [
                    _sectionTitle('Tentang Aplikasi'),
                    SizedBox(height: 8),
                    _infoRow(Icons.info_outline,
                        'Versi', 'SIJI v1.0.0', primary),
                    _divider(),
                    _infoRow(
                        Icons.business,
                        'Dibuat oleh',
                        'Kentang Dev',
                        primary),
                  ]),
                  SizedBox(height: 12),

                  // Logout
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirm =
                        await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text('Keluar'),
                            content: Text(
                                'Yakin ingin keluar dari SIJI?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(
                                        context, false),
                                child: Text('Batal'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(
                                        context, true),
                                child: Text('Keluar',
                                    style: TextStyle(
                                        color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          NotificationService.reset();
                          await ApiService.logout();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    LoginScreen()),
                          );
                        }
                      },
                      icon: Icon(Icons.logout,
                          color: Colors.red),
                      label: Text('Keluar',
                          style: TextStyle(
                              color: Colors.red,
                              fontWeight:
                              FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                                12)),
                        padding: EdgeInsets.symmetric(
                            vertical: 14),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '© 2026 SIJI — Terintegrasi · Terukur · Terkendali',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(bool isDark, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1e293b) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: Offset(0, 2))
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey));
  }

  Widget _divider() =>
      Divider(height: 1, color: Colors.grey.withOpacity(0.2));

  Widget _infoRow(
      IconData icon, String label, String value, Color primary) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: primary, size: 18),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey)),
              Text(value,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title,
      String subtitle, Color primary, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: primary, size: 20),
      ),
      title: Text(title,
          style:
          TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: TextStyle(fontSize: 11, color: Colors.grey)),
      trailing:
      Icon(Icons.chevron_right, color: Colors.grey, size: 18),
      onTap: onTap,
    );
  }
}