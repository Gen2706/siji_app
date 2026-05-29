import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart';

class WarehouseMovementsScreen extends StatefulWidget {
  @override
  _WarehouseMovementsScreenState createState() =>
      _WarehouseMovementsScreenState();
}

class _WarehouseMovementsScreenState
    extends State<WarehouseMovementsScreen> {
  List<dynamic> movements = [];
  bool isLoading = true;
  String? filterType;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getStockMovements();
      setState(() => movements = data);
    } catch (e) {}
    setState(() => isLoading = false);
  }

  List<dynamic> get filtered {
    if (filterType == null) return movements;
    return movements.where((m) => m['type'] == filterType).toList();
  }

  String formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final months = ['Jan','Feb','Mar','Apr','Mei','Jun',
        'Jul','Agu','Sep','Okt','Nov','Des'];
      return '${dt.day} ${months[dt.month-1]} ${dt.year} '
          '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (e) { return dateStr; }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? Color(0xFF2563eb) : Color(0xFFdc2626);

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0f172a) : Color(0xFFf1f5f9),
      appBar: AppBar(
        title: Text('Mutasi Stok',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Filter
          PopupMenuButton<String?>(
            icon: Icon(Icons.filter_list),
            onSelected: (val) => setState(() => filterType = val),
            itemBuilder: (_) => [
              PopupMenuItem(value: null, child: Text('Semua')),
              PopupMenuItem(value: 'in', child: Text('Masuk (+)')),
              PopupMenuItem(value: 'out', child: Text('Keluar (-)')),
            ],
          ),
          IconButton(icon: Icon(Icons.refresh), onPressed: load),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primary))
          : filtered.isEmpty
          ? Center(
          child: Text('Tidak ada mutasi',
              style: TextStyle(color: Colors.grey)))
          : RefreshIndicator(
        onRefresh: () async => load(),
        color: primary,
        child: ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) {
            final m = filtered[i];
            final isIn = m['type'] == 'in';
            final itemName = m['item']?['name'] ?? '-';
            final userName = m['user']?['name'] ?? '-';

            return Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? Color(0xFF1e293b)
                    : Colors.white,
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
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isIn
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isIn
                          ? Icons.add_circle_outline
                          : Icons.remove_circle_outline,
                      color: isIn ? Colors.green : Colors.red,
                      size: 22,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(itemName,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        SizedBox(height: 2),
                        Text(m['notes'] ?? '-',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.person_outline,
                                size: 11, color: Colors.grey),
                            SizedBox(width: 3),
                            Text(userName,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey)),
                            SizedBox(width: 8),
                            Icon(Icons.access_time,
                                size: 11, color: Colors.grey),
                            SizedBox(width: 3),
                            Text(formatDate(m['created_at']),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey)),
                          ],
                        ),
                        if (m['serial_number'] != null) ...[
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.qr_code,
                                  size: 11, color: primary),
                              SizedBox(width: 3),
                              Text('SN: ${m['serial_number']}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: primary)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isIn ? '+' : '-'}${m['quantity']}',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isIn
                                ? Colors.green
                                : Colors.red),
                      ),
                      if (m['stock_after'] != null)
                        Text('sisa: ${m['stock_after']}',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}