import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/permission_service.dart';
import '../main.dart';

class WarehouseItemDetailScreen extends StatefulWidget {
  final int itemId;
  const WarehouseItemDetailScreen({required this.itemId});

  @override
  _WarehouseItemDetailScreenState createState() =>
      _WarehouseItemDetailScreenState();
}

class _WarehouseItemDetailScreenState
    extends State<WarehouseItemDetailScreen> {
  Map<String, dynamic>? item;
  Map<String, dynamic>? currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    loadItem();
  }

  void _loadUser() async {
    final u = await ApiService.getUser();
    setState(() => currentUser = u);
  }

  void loadItem() async {
    setState(() => isLoading = true);
    try {
      final result =
      await ApiService.getWarehouseItemDetail(widget.itemId);
      setState(() => item = result['data']);
    } catch (e) {}
    setState(() => isLoading = false);
  }

  void showAddStockDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? Color(0xFF2563eb) : Color(0xFFdc2626);
    final qtyCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final snCtrl = TextEditingController();
    bool isAdding = false;
    final useSerial = item?['use_serial_number'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20,
              MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tambah Stok',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Jumlah',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
              ),
              SizedBox(height: 12),
              if (useSerial) ...[
                TextField(
                  controller: snCtrl,
                  decoration: InputDecoration(
                    labelText: 'Serial Number',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                ),
                SizedBox(height: 12),
              ],
              TextField(
                controller: notesCtrl,
                decoration: InputDecoration(
                  labelText: 'Keterangan (opsional)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isAdding
                      ? null
                      : () async {
                    final qty =
                        int.tryParse(qtyCtrl.text) ?? 0;
                    if (qty <= 0) return;
                    setModal(() => isAdding = true);
                    final result = await ApiService.addStock(
                      widget.itemId, qty,
                      notes: notesCtrl.text,
                      serialNumber:
                      useSerial ? snCtrl.text : null,
                    );
                    Navigator.pop(ctx);
                    if (result['success'] == true) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(
                        content:
                        Text('✅ Stok berhasil ditambahkan!'),
                        backgroundColor: Colors.green,
                      ));
                      loadItem();
                    } else {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(
                        content: Text(
                            result['message'] ?? 'Gagal!'),
                        backgroundColor: Colors.red,
                      ));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isAdding
                      ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : Text('Tambah Stok',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showReduceStockDialog() {
    final qtyCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool isReducing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20,
              MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kurangi Stok',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Stok saat ini: ${item?['stock'] ?? 0}',
                  style:
                  TextStyle(color: Colors.grey, fontSize: 13)),
              SizedBox(height: 16),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Jumlah',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: InputDecoration(
                  labelText: 'Keterangan',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isReducing
                      ? null
                      : () async {
                    final qty =
                        int.tryParse(qtyCtrl.text) ?? 0;
                    if (qty <= 0) return;
                    setModal(() => isReducing = true);
                    final result =
                    await ApiService.reduceStock(
                      widget.itemId, qty,
                      notes: notesCtrl.text,
                    );
                    Navigator.pop(ctx);
                    if (result['success'] == true) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(
                        content:
                        Text('✅ Stok berhasil dikurangi!'),
                        backgroundColor: Colors.green,
                      ));
                      loadItem();
                    } else {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(
                        content: Text(
                            result['message'] ?? 'Gagal!'),
                        backgroundColor: Colors.red,
                      ));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isReducing
                      ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : Text('Kurangi Stok',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? Color(0xFF2563eb) : Color(0xFFdc2626);
    final role = currentUser?['role'];

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
            backgroundColor: primary,
            foregroundColor: Colors.white),
        body: Center(
            child: CircularProgressIndicator(color: primary)),
      );
    }

    if (item == null) {
      return Scaffold(
        appBar: AppBar(
            backgroundColor: primary,
            foregroundColor: Colors.white),
        body: Center(child: Text('Item tidak ditemukan')),
      );
    }

    final stock = item!['stock'] ?? 0;
    final minStock = item!['stock_minimum'] ?? 0;
    final isOut = stock == 0;
    final isLow = stock > 0 && stock <= minStock;
    final stockColor =
    isOut ? Colors.red : isLow ? Colors.orange : Colors.green;
    final movements = item!['stock_movements'] as List? ?? [];
    final serialNumbers = item!['serial_numbers'] as List? ?? [];

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0f172a) : Color(0xFFf1f5f9),
      appBar: AppBar(
        title: Text(item!['name'] ?? '',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: loadItem),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stock Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [Color(0xFF1e3a5f), Color(0xFF1e293b)]
                      : [
                    stockColor.withOpacity(0.8),
                    stockColor
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text('$stock',
                      style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  Text(item!['unit'] ?? '',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 16)),
                  SizedBox(height: 8),
                  Text(
                    isOut
                        ? '⚠️ STOK HABIS'
                        : isLow
                        ? '⚠️ STOK MENIPIS'
                        : '✅ STOK TERSEDIA',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                  if (minStock > 0)
                    Text(
                        'Minimum: $minStock ${item!['unit'] ?? ''}',
                        style: TextStyle(
                            color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Action Buttons — hanya admin & admin_gudang
            if (PermissionService.canAddStock(role) ||
                PermissionService.canReduceStock(role))
              Row(
                children: [
                  if (PermissionService.canAddStock(role))
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: showAddStockDialog,
                        icon: Icon(Icons.add, size: 18),
                        label: Text('Tambah Stok'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(10)),
                          padding:
                          EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                      ),
                    ),
                  if (PermissionService.canAddStock(role) &&
                      PermissionService.canReduceStock(role))
                    SizedBox(width: 12),
                  if (PermissionService.canReduceStock(role))
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                        stock > 0 ? showReduceStockDialog : null,
                        icon: Icon(Icons.remove, size: 18),
                        label: Text('Kurangi Stok'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(10)),
                          padding:
                          EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                      ),
                    ),
                ],
              ),
            SizedBox(height: 16),

            // Info
            _card(isDark, [
              Text('Informasi Barang',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              _infoRow('Kode', item!['code'] ?? '-'),
              _infoRow('Nama', item!['name'] ?? '-'),
              _infoRow('Kategori', item!['category'] ?? '-'),
              _infoRow('Satuan', item!['unit'] ?? '-'),
              _infoRow('Min. Stok', '$minStock'),
              _infoRow('Deskripsi', item!['description'] ?? '-'),
              _infoRow('Serial Number',
                  item!['use_serial_number'] == true ? 'Ya' : 'Tidak'),
            ]),
            SizedBox(height: 12),

            // Serial Numbers
            if (serialNumbers.isNotEmpty) ...[
              _card(isDark, [
                Text(
                    'Serial Numbers (${serialNumbers.length})',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                ...serialNumbers
                    .map((sn) => Container(
                  margin: EdgeInsets.only(bottom: 4),
                  padding: EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.qr_code,
                          size: 14, color: primary),
                      SizedBox(width: 8),
                      Text(sn.toString(),
                          style: TextStyle(
                              fontSize: 12, color: primary)),
                    ],
                  ),
                ))
                    .toList(),
              ]),
              SizedBox(height: 12),
            ],

            // Stock Movements
            if (movements.isNotEmpty) ...[
              _card(isDark, [
                Text('Riwayat Mutasi',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                ...movements.take(10).map((m) {
                  final isIn = m['type'] == 'in';
                  return Container(
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Color(0xFF0f172a)
                          : Color(0xFFf8fafc),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isIn
                              ? Icons.add_circle
                              : Icons.remove_circle,
                          color:
                          isIn ? Colors.green : Colors.red,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(m['notes'] ?? '-',
                                  style: TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              Text(
                                  formatDate(m['created_at']),
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey)),
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
                                  fontSize: 14,
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
                }).toList(),
              ]),
            ],
            SizedBox(height: 24),
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style:
                TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          Text(': ', style: TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}