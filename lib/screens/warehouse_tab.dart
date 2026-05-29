import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart';
import 'warehouse_items_screen.dart';
import 'warehouse_requests_screen.dart';
import 'warehouse_movements_screen.dart';
import 'warehouse_master_screen.dart';

class WarehouseTab extends StatefulWidget {
  @override
  _WarehouseTabState createState() => _WarehouseTabState();
}

class _WarehouseTabState extends State<WarehouseTab> {
  Map<String, dynamic> dashboard = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  void loadDashboard() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getWarehouseDashboard();
      setState(() => dashboard = data);
    } catch (e) {}
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? Color(0xFF2563eb) : Color(0xFFdc2626);

    final totalItems      = dashboard['total_items'] ?? 0;
    final lowStock        = dashboard['low_stock'] ?? 0;
    final outOfStock      = dashboard['out_of_stock'] ?? 0;
    final pendingReqs     = dashboard['pending_requests'] ?? 0;
    final recentMovements = dashboard['recent_movements'] as List? ?? [];
    final lowStockItems   = dashboard['low_stock_items'] as List? ?? [];

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0f172a) : Color(0xFFf1f5f9),
      appBar: AppBar(
        title: Text('Gudang',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
              icon: Icon(Icons.refresh), onPressed: loadDashboard),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primary))
          : RefreshIndicator(
        onRefresh: () async => loadDashboard(),
        color: primary,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stat Cards
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _statCard('Total Item', totalItems,
                      Icons.inventory_2_outlined, primary, isDark),
                  _statCard('Stok Menipis', lowStock,
                      Icons.warning_amber_outlined,
                      Colors.orange, isDark),
                  _statCard('Habis', outOfStock,
                      Icons.remove_circle_outline,
                      Colors.red, isDark),
                  _statCard('Permintaan', pendingReqs,
                      Icons.pending_actions_outlined,
                      Colors.blue, isDark),
                ],
              ),
              SizedBox(height: 20),

              // Menu Navigasi
              Text('Menu Gudang',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _menuCard(
                      context,
                      'Data Barang',
                      Icons.inventory_outlined,
                      primary,
                          () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  WarehouseItemsScreen()))
                          .then((_) => loadDashboard()),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _menuCard(
                      context,
                      'Permintaan',
                      Icons.assignment_outlined,
                      Colors.blue,
                          () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  WarehouseRequestsScreen()))
                          .then((_) => loadDashboard()),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _menuCard(
                      context,
                      'Mutasi Stok',
                      Icons.swap_horiz_outlined,
                      Colors.green,
                          () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  WarehouseMovementsScreen())),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _menuCard(
                      context,
                      'Stok Menipis',
                      Icons.warning_outlined,
                      Colors.orange,
                          () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => WarehouseItemsScreen(
                                  lowStockOnly: true)))
                          .then((_) => loadDashboard()),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _menuCard(
                      context,
                      'Master Barang',
                      Icons.settings_outlined,
                      Colors.purple,
                          () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  WarehouseMasterScreen())),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(child: SizedBox()),
                ],
              ),
              SizedBox(height: 20),

              // Stok Menipis
              if (lowStockItems.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('⚠️ Stok Menipis',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => WarehouseItemsScreen(
                                  lowStockOnly: true))),
                      child: Text('Lihat Semua',
                          style: TextStyle(
                              fontSize: 12, color: primary)),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ...lowStockItems
                    .map((item) => _lowStockCard(item, isDark))
                    .toList(),
                SizedBox(height: 20),
              ],

              // Mutasi Terbaru
              if (recentMovements.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Mutasi Terbaru',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  WarehouseMovementsScreen())),
                      child: Text('Lihat Semua',
                          style: TextStyle(
                              fontSize: 12, color: primary)),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ...recentMovements
                    .take(5)
                    .map((m) => _movementCard(m, isDark))
                    .toList(),
              ],

              SizedBox(height: 24),
            ],
          ),
        ),
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
              borderRadius: BorderRadius.circular(10),
            ),
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
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menuCard(BuildContext context, String label, IconData icon,
      Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _lowStockCard(Map<String, dynamic> item, bool isDark) {
    final stock    = item['stock'] ?? 0;
    final minStock = item['stock_minimum'] ?? 0;
    final isOut    = stock == 0;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1e293b) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOut
              ? Colors.red.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isOut
                  ? Colors.red.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isOut ? Icons.remove_circle : Icons.warning_amber,
              color: isOut ? Colors.red : Colors.orange,
              size: 18,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'] ?? '',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text(
                    '${item['category'] ?? ''} • ${item['unit'] ?? ''}',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$stock',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isOut ? Colors.red : Colors.orange)),
              Text('min: $minStock',
                  style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _movementCard(Map<String, dynamic> movement, bool isDark) {
    final isIn     = movement['type'] == 'in';
    final qty      = movement['quantity'] ?? 0;
    final itemName = movement['item']?['name'] ?? '-';
    final date     = movement['created_at'] != null
        ? movement['created_at'].toString().substring(0, 10)
        : '-';

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
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
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isIn
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isIn
                  ? Icons.add_circle_outline
                  : Icons.remove_circle_outline,
              color: isIn ? Colors.green : Colors.red,
              size: 18,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(itemName,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(movement['notes'] ?? '',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIn ? '+' : '-'}$qty',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isIn ? Colors.green : Colors.red),
              ),
              Text(date,
                  style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}