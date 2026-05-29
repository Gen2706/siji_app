import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart';

class LeaderboardTab extends StatefulWidget {
  @override
  _LeaderboardTabState createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<LeaderboardTab> {
  List<dynamic> leaderboard = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getList('leaderboard');
      setState(() => leaderboard = data);
    } catch (e) {}
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? Color(0xFF2563eb) : Color(0xFFdc2626);

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0f172a) : Color(0xFFf1f5f9),
      appBar: AppBar(
        title: Text('Leaderboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [IconButton(icon: Icon(Icons.refresh), onPressed: load)],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primary))
          : RefreshIndicator(
        onRefresh: () async => load(),
        color: primary,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Top 3 podium
            if (leaderboard.length >= 3)
              Container(
                margin: EdgeInsets.only(bottom: 20),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Color(0xFF1e3a5f), Color(0xFF1e293b)]
                        : [Color(0xFFfef3c7), Color(0xFFfde68a)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _podium(leaderboard[1], 2, 70, primary),
                    _podium(leaderboard[0], 1, 90, primary),
                    _podium(leaderboard[2], 3, 60, primary),
                  ],
                ),
              ),

            // List semua
            ...leaderboard.asMap().entries.map((e) =>
                _leaderItem(e.key, e.value, primary, isDark)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _podium(Map<String, dynamic> teknisi, int rank, double height, Color primary) {
    final medals = {1: '🥇', 2: '🥈', 3: '🥉'};
    final name = (teknisi['name'] ?? '').split(' ')[0];
    return Column(
      children: [
        Text(medals[rank]!, style: TextStyle(fontSize: 24)),
        SizedBox(height: 4),
        CircleAvatar(
          radius: rank == 1 ? 28 : 22,
          backgroundColor: primary.withOpacity(0.2),
          child: Text(name.isNotEmpty ? name[0] : '?',
              style: TextStyle(color: primary, fontWeight: FontWeight.bold,
                  fontSize: rank == 1 ? 20 : 16)),
        ),
        SizedBox(height: 4),
        Text(name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        Text('${teknisi['total_points'] ?? 0} pts',
            style: TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _leaderItem(int index, Map<String, dynamic> teknisi, Color primary, bool isDark) {
    final medals = ['🥇', '🥈', '🥉'];
    final name = teknisi['name'] ?? '';
    final isTop = index < 3;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1e293b) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: index == 0 ? Border.all(color: Colors.amber.withOpacity(0.5), width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: isTop
                ? Text(medals[index], style: TextStyle(fontSize: 20))
                : Text('${index + 1}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                textAlign: TextAlign.center),
          ),
          SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundColor: primary.withOpacity(0.1),
            child: Text(name.isNotEmpty ? name[0] : '?',
                style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${teknisi['completed_tickets_count'] ?? 0} tiket · ${teknisi['department'] ?? ''}',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Text('${teknisi['total_points'] ?? 0} pts',
                style: TextStyle(fontSize: 12, color: primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
