import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  @override
  _NotificationSettingsScreenState createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  Map<String, bool> settings = {
    'ticket_created': true,
    'ticket_updated': true,
    'ticket_comment': true,
    'ticket_closed': true,
  };
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  void loadSettings() async {
    final s = await ApiService.getNotificationSettings();
    setState(() {
      settings = Map<String, bool>.from(s);
      isLoading = false;
    });
  }

  void toggleSetting(String key, bool value) async {
    setState(() => settings[key] = value);
    await ApiService.saveNotificationSettings(settings);
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final primary =
    isDark ? Color(0xFF2563eb) : Color(0xFFdc2626);

    return Scaffold(
      backgroundColor:
      isDark ? Color(0xFF0f172a) : Color(0xFFf1f5f9),
      appBar: AppBar(
        title: Text('Pengaturan Notifikasi',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? Center(
          child:
          CircularProgressIndicator(color: primary))
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            // Info
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius:
                BorderRadius.circular(12),
                border: Border.all(
                    color: primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: primary, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Atur notifikasi yang ingin kamu terima dari SIJI.',
                      style: TextStyle(
                          fontSize: 12,
                          color: primary),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Notif settings
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Color(0xFF1e293b)
                    : Colors.white,
                borderRadius:
                BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black
                          .withOpacity(0.04),
                      blurRadius: 6,
                      offset: Offset(0, 2))
                ],
              ),
              child: Column(
                children: [
                  _notifItem(
                    Icons.add_circle_outline,
                    'Tiket Baru Dibuat',
                    'Notif saat ada tiket baru',
                    'ticket_created',
                    Colors.blue,
                    primary,
                  ),
                  _divider(),
                  _notifItem(
                    Icons.update_outlined,
                    'Status Tiket Diupdate',
                    'Notif saat status tiket berubah',
                    'ticket_updated',
                    Colors.orange,
                    primary,
                  ),
                  _divider(),
                  _notifItem(
                    Icons.chat_bubble_outline,
                    'Komentar Baru',
                    'Notif saat ada komentar di tiket',
                    'ticket_comment',
                    Colors.green,
                    primary,
                  ),
                  _divider(),
                  _notifItem(
                    Icons.lock_outline,
                    'Tiket Ditutup',
                    'Notif saat tiket ditutup',
                    'ticket_closed',
                    Colors.grey,
                    primary,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _notifItem(
      IconData icon,
      String title,
      String subtitle,
      String key,
      Color color,
      Color primary) {
    return Padding(
      padding:
      EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Switch(
            value: settings[key] ?? true,
            activeColor: primary,
            onChanged: (v) => toggleSetting(key, v),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
      height: 1, color: Colors.grey.withOpacity(0.15));
}