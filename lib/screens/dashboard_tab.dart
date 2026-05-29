import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/permission_service.dart';
import '../services/notification_service.dart';
import '../main.dart';
import 'login_screen.dart';
import 'ticket_detail_screen.dart';

class DashboardTab extends StatefulWidget {
  @override
  _DashboardTabState createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  Map<String, dynamic>? user;
  Map<String, dynamic>? stats;
  List<dynamic> recentTickets = [];
  List<dynamic> topLeaderboard = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  void loadAll() async {
    setState(() => isLoading = true);
    try {
      // Ambil user fresh dari API agar points selalu update
      final userResult = await ApiService.getUserFresh();
      final u = userResult ?? await ApiService.getUser();
      final role = u?['role'];

      // Ambil tiket sesuai role
      final t = await ApiService.searchTickets();

      // Leaderboard hanya untuk non-teknisi
      List<dynamic> l = [];
      if (PermissionService.canSeeLeaderboard(role)) {
        l = await ApiService.getList('leaderboard');
      }

      setState(() {
        user = u;
        recentTickets = t;
        topLeaderboard = l;
        stats = {
          'total': t.length,
          'open': t
              .where((x) => x['status'] == 'open')
              .length,
          'in_progress': t
              .where((x) =>
          x['status'] == 'in_progress' ||
              x['status'] == 'assigned')
              .length,
          'resolved': t
              .where((x) =>
          x['status'] == 'resolved' ||
              x['status'] == 'closed')
              .length,
        };
      });
    } catch (e) {
      print('Dashboard error: $e');
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? Color(0xFF2563eb) : Color(0xFFdc2626);
    final name = user?['name'] ?? 'User';
    final role = user?['role'] ?? '';
    final avatar = user?['avatar'] ?? '';
    final points = user?['total_points'] ?? 0;
    final firstName = name.split(' ')[0];

    return Scaffold(
      backgroundColor:
      isDark ? Color(0xFF0f172a) : Color(0xFFf1f5f9),
      body: isLoading
          ? Center(
          child: CircularProgressIndicator(color: primary))
          : RefreshIndicator(
        onRefresh: () async => loadAll(),
        color: primary,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              backgroundColor: primary,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: Icon(
                    isDark
                        ? Icons.wb_sunny_outlined
                        : Icons.nightlight_round,
                    color: Colors.white,
                  ),
                  onPressed: () =>
                      MyApp.of(context)?.toggleTheme(),
                ),
                IconButton(
                  icon: Icon(Icons.logout,
                      color: Colors.white),
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
                                Navigator.pop(context, false),
                            child: Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, true),
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
                            builder: (_) => LoginScreen()),
                      );
                    }
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                        Color(0xFF1e3a5f),
                        Color(0xFF0f172a)
                      ]
                          : [
                        Color(0xFFb91c1c),
                        Color(0xFF7f1d1d)
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          20, 8, 20, 16),
                      child: Column(
                        mainAxisAlignment:
                        MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                Colors.white24,
                                backgroundImage:
                                avatar.isNotEmpty
                                    ? NetworkImage(avatar)
                                    : null,
                                child: avatar.isEmpty
                                    ? Text(
                                    name.isNotEmpty
                                        ? name[0]
                                        : 'U',
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight:
                                        FontWeight.bold))
                                    : null,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Halo, $firstName! 👋',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                          FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(
                                          top: 2),
                                      padding:
                                      EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2),
                                      decoration: BoxDecoration(
                                          color: Colors.white24,
                                          borderRadius:
                                          BorderRadius
                                              .circular(10)),
                                      child: Text(
                                        PermissionService
                                            .getRoleLabel(role),
                                        style: TextStyle(
                                            fontSize: 10,
                                            color:
                                            Colors.white70),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Poin untuk teknisi di header
                              if (PermissionService
                                  .isTeknisi(role))
                                Container(
                                  padding:
                                  EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius:
                                    BorderRadius.circular(
                                        12),
                                  ),
                                  child: Row(
                                    mainAxisSize:
                                    MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star,
                                          color: Colors.amber,
                                          size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        '$points pts',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight:
                                            FontWeight.bold,
                                            fontSize: 13),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Stack(
                                  children: [
                                    Icon(
                                        Icons
                                            .notifications_outlined,
                                        color: Colors.white,
                                        size: 26),
                                    if ((stats?['open'] ?? 0) >
                                        0)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          width: 14,
                                          height: 14,
                                          decoration:
                                          BoxDecoration(
                                              color: Colors
                                                  .yellow,
                                              shape: BoxShape
                                                  .circle),
                                          child: Center(
                                            child: Text(
                                              '${stats!['open']}',
                                              style: TextStyle(
                                                  fontSize: 8,
                                                  fontWeight:
                                                  FontWeight
                                                      .bold,
                                                  color: Colors
                                                      .black),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    // Poin card besar untuk teknisi
                    if (PermissionService.isTeknisi(
                        role)) ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF2563eb),
                              Color(0xFF1e40af),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                          BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF2563eb)
                                  .withOpacity(0.3),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.star,
                                  color: Colors.amber,
                                  size: 32),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Poin Kamu',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12),
                                  ),
                                  Text(
                                    '$points',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight:
                                        FontWeight.bold,
                                        height: 1.1),
                                  ),
                                  Text(
                                    'poin diperoleh',
                                    style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.end,
                              children: [
                                _pointBadge(
                                  '${recentTickets.where((t) => t['status'] == 'resolved' || t['status'] == 'closed').length}',
                                  'selesai',
                                  Colors.green,
                                ),
                                SizedBox(height: 6),
                                _pointBadge(
                                  '${recentTickets.where((t) => t['status'] == 'in_progress' || t['status'] == 'assigned').length}',
                                  'aktif',
                                  Colors.orange,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                    ],

                    // Stat Cards
                    Text(
                      PermissionService.isTeknisi(role)
                          ? 'Tiket Saya'
                          : 'Ringkasan Tiket',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics:
                      NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.6,
                      children: [
                        _statCard(
                            'Total',
                            stats?['total'] ?? 0,
                            Icons.confirmation_number_outlined,
                            primary,
                            isDark),
                        _statCard(
                            'Open',
                            stats?['open'] ?? 0,
                            Icons.radio_button_unchecked,
                            Colors.orange,
                            isDark),
                        _statCard(
                            'In Progress',
                            stats?['in_progress'] ?? 0,
                            Icons.autorenew,
                            Colors.blue,
                            isDark),
                        _statCard(
                            'Selesai',
                            stats?['resolved'] ?? 0,
                            Icons.check_circle_outline,
                            Colors.green,
                            isDark),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Tiket Terbaru
                    Text(
                      PermissionService.isTeknisi(role)
                          ? 'Tiket Saya Terbaru'
                          : 'Tiket Terbaru',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    recentTickets.isEmpty
                        ? Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Color(0xFF1e293b)
                            : Colors.white,
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 40,
                                color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              PermissionService
                                  .isTeknisi(role)
                                  ? 'Belum ada tiket yang di-assign ke kamu'
                                  : 'Belum ada tiket',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13),
                              textAlign:
                              TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                        : Column(
                      children: recentTickets
                          .take(5)
                          .map((t) => _ticketCard(
                          t, primary, isDark))
                          .toList(),
                    ),
                    SizedBox(height: 20),

                    // Top Leaderboard — hanya non-teknisi
                    if (PermissionService.canSeeLeaderboard(
                        role) &&
                        topLeaderboard.isNotEmpty) ...[
                      Text('Top Teknisi',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      ...topLeaderboard
                          .take(3)
                          .toList()
                          .asMap()
                          .entries
                          .map((e) => _leaderCard(e.key,
                          e.value, primary, isDark))
                          .toList(),
                    ],

                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pointBadge(String value, String label, Color color) {
    return Container(
      padding:
      EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$value $label',
        style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _statCard(String label, int value, IconData icon,
      Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1e293b) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$value',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(label,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ticketCard(Map<String, dynamic> ticket,
      Color primary, bool isDark) {
    final status = ticket['status'] ?? '';
    final priority = ticket['priority'] ?? '';
    Color statusColor = status == 'open'
        ? Colors.orange
        : status == 'in_progress' || status == 'assigned'
        ? Colors.blue
        : status == 'resolved'
        ? Colors.green
        : Colors.grey;
    Color priorityColor =
    priority == 'high' || priority == 'critical'
        ? Colors.red
        : priority == 'medium'
        ? Colors.orange
        : Colors.green;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                TicketDetailScreen(ticketId: ticket['id'])),
      ).then((_) => loadAll()),
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1e293b) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
                width: 4,
                height: 50,
                decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(4))),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ticket['ticket_number'] ?? '',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey)),
                  SizedBox(height: 2),
                  Text(ticket['title'] ?? '',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      _badge(
                          status
                              .replaceAll('_', ' ')
                              .toUpperCase(),
                          statusColor),
                      SizedBox(width: 6),
                      _badge(priority.toUpperCase(),
                          priorityColor),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding:
      EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(text,
          style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _leaderCard(int index,
      Map<String, dynamic> teknisi, Color primary, bool isDark) {
    final medals = ['🥇', '🥈', '🥉'];
    final name = teknisi['name'] ?? '';
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1e293b) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: index == 0
            ? Border.all(
            color: Colors.amber.withOpacity(0.5),
            width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Text(medals[index],
              style: TextStyle(fontSize: 22)),
          SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: primary.withOpacity(0.1),
            child: Text(
              name.isNotEmpty ? name[0] : '?',
              style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(
                    '${teknisi['completed_tickets_count'] ?? 0} tiket selesai',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Text(
              '${teknisi['total_points'] ?? 0} pts',
              style: TextStyle(
                  fontSize: 12,
                  color: primary,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}