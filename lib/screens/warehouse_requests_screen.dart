import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/permission_service.dart';
import '../main.dart';
import 'warehouse_request_detail_screen.dart';

class WarehouseRequestsScreen extends StatefulWidget {
  @override
  _WarehouseRequestsScreenState createState() =>
      _WarehouseRequestsScreenState();
}

class _WarehouseRequestsScreenState extends State<WarehouseRequestsScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> requests = [];
  bool isLoading = true;
  late TabController _tabCtrl;
  final tabs = ['Semua', 'Pending', 'Approved', 'Rejected'];
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: tabs.length, vsync: this);
    _loadUser();
    loadRequests();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _loadUser() async {
    final u = await ApiService.getUser();
    setState(() => _currentUser = u);
  }

  void loadRequests() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getItemRequests();
      setState(() => requests = data);
    } catch (e) {}
    setState(() => isLoading = false);
  }

  List<dynamic> filtered(String tab) {
    if (tab == 'Semua') return requests;
    if (tab == 'Approved') {
      return requests.where((r) {
        final s = r['status']?.toString().toLowerCase() ?? '';
        return s == 'approved' ||
            s == 'approved_admin' ||
            s == 'approved_head';
      }).toList();
    }
    return requests
        .where((r) =>
    r['status']?.toString().toLowerCase() ==
        tab.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? Color(0xFF2563eb) : Color(0xFFdc2626);
    final role = _currentUser?['role'];

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0f172a) : Color(0xFFf1f5f9),
      appBar: AppBar(
        title: Text('Permintaan Barang',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
              icon: Icon(Icons.refresh), onPressed: loadRequests),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),

      // FAB buat permintaan — semua role bisa
      floatingActionButton:
      PermissionService.canCreateRequest(role)
          ? FloatingActionButton.extended(
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    CreateItemRequestScreen()))
            .then((_) => loadRequests()),
        backgroundColor: primary,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('Buat Permintaan',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600)),
      )
          : null,

      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primary))
          : TabBarView(
        controller: _tabCtrl,
        children: tabs.map((tab) {
          final list = filtered(tab);
          if (list.isEmpty)
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined,
                      size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Tidak ada permintaan',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          return RefreshIndicator(
            onRefresh: () async => loadRequests(),
            color: primary,
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: list.length,
              itemBuilder: (ctx, i) => _requestCard(
                  list[i], primary, isDark, role),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _requestCard(Map<String, dynamic> req, Color primary,
      bool isDark, String? role) {
    final status = req['status'] ?? '';
    final details = req['details'] as List? ?? [];
    final requester = req['requester']?['name'] ??
        req['user']?['name'] ??
        '-';
    final date = req['created_at'] != null
        ? req['created_at'].toString().substring(0, 10)
        : '-';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusLabel = 'PENDING';
        break;
      case 'approved':
      case 'approved_admin':
      case 'approved_head':
        statusColor = Colors.green;
        statusLabel = 'DISETUJUI';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusLabel = 'DITOLAK';
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        statusLabel = 'DIBATALKAN';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = status.toUpperCase();
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WarehouseRequestDetailScreen(
              requestId: req['id']),
        ),
      ).then((_) => loadRequests()),
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
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
            Padding(
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          req['request_number'] ??
                              'Request #${req['id']}',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: statusColor.withOpacity(0.3)),
                        ),
                        child: Text(statusLabel,
                            style: TextStyle(
                                fontSize: 10,
                                color: statusColor,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),

                  // Meta info
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 12, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(requester,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      Spacer(),
                      Icon(Icons.calendar_today_outlined,
                          size: 12, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(date,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  SizedBox(height: 10),

                  // Items preview
                  ...details.take(3).map((d) => Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 12, color: primary),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            d['item']?['name'] ?? '-',
                            style: TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.1),
                            borderRadius:
                            BorderRadius.circular(6),
                          ),
                          child: Text('x${d['quantity']}',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: primary)),
                        ),
                      ],
                    ),
                  )),
                  if (details.length > 3)
                    Text('+${details.length - 3} item lainnya',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey)),

                  SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.touch_app_outlined,
                          size: 12, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('Tap untuk detail',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),

            // Quick action buttons — hanya admin & admin_gudang
            if (status == 'pending' &&
                PermissionService.canApproveRequest(role))
              Container(
                decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(
                          color: Colors.grey.withOpacity(0.2))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () async {
                          final result =
                          await ApiService.approveItemRequest(
                              req['id']);
                          if (result['success'] == true) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content: Text('✅ Request disetujui!'),
                              backgroundColor: Colors.green,
                            ));
                            loadRequests();
                          } else {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content: Text(
                                  result['message'] ?? 'Gagal!'),
                              backgroundColor: Colors.red,
                            ));
                          }
                        },
                        icon: Icon(Icons.check,
                            color: Colors.green, size: 16),
                        label: Text('Setujui',
                            style: TextStyle(
                                color: Colors.green,
                                fontSize: 12)),
                      ),
                    ),
                    Container(
                        width: 1,
                        height: 30,
                        color: Colors.grey.withOpacity(0.2)),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () async {
                          final result =
                          await ApiService.rejectItemRequest(
                              req['id']);
                          if (result['success'] == true) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content: Text('Request ditolak'),
                              backgroundColor: Colors.orange,
                            ));
                            loadRequests();
                          }
                        },
                        icon: Icon(Icons.close,
                            color: Colors.red, size: 16),
                        label: Text('Tolak',
                            style: TextStyle(
                                color: Colors.red, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CREATE REQUEST SCREEN
// ============================================================
class CreateItemRequestScreen extends StatefulWidget {
  @override
  _CreateItemRequestScreenState createState() =>
      _CreateItemRequestScreenState();
}

class _CreateItemRequestScreenState
    extends State<CreateItemRequestScreen> {
  List<dynamic> availableItems = [];
  List<Map<String, dynamic>> selectedItems = [];
  bool isLoading = true;
  bool isSubmitting = false;
  final notesCtrl = TextEditingController();
  final searchCtrl = TextEditingController();
  List<dynamic> filteredItems = [];

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  @override
  void dispose() {
    notesCtrl.dispose();
    searchCtrl.dispose();
    super.dispose();
  }

  void loadItems() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getWarehouseItems();
      setState(() {
        availableItems = data;
        filteredItems = data;
      });
    } catch (e) {}
    setState(() => isLoading = false);
  }

  void filterItems(String query) {
    setState(() {
      filteredItems = query.isEmpty
          ? availableItems
          : availableItems
          .where((item) =>
      (item['name'] ?? '')
          .toString()
          .toLowerCase()
          .contains(query.toLowerCase()) ||
          (item['code'] ?? '')
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  void addItem(Map<String, dynamic> item) {
    final existing = selectedItems
        .indexWhere((i) => i['item_id'] == item['id']);
    if (existing >= 0) {
      setState(() => selectedItems[existing]['quantity']++);
    } else {
      setState(() => selectedItems.add({
        'item_id': item['id'],
        'item_name': item['name'],
        'item_unit': item['unit'],
        'item_stock': item['stock'],
        'quantity': 1,
        'notes': '',
      }));
    }
  }

  void removeItem(int index) {
    setState(() => selectedItems.removeAt(index));
  }

  void submit() async {
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih minimal 1 barang!')),
      );
      return;
    }
    setState(() => isSubmitting = true);
    try {
      final items = selectedItems
          .map((i) => {
        'item_id': i['item_id'],
        'quantity': i['quantity'],
        'notes': i['notes'] ?? '',
      })
          .toList();

      final result = await ApiService.createItemRequest(items,
          notes: notesCtrl.text);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('✅ Permintaan berhasil dibuat!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        final errors = result['errors'];
        String msg = result['message'] ?? 'Gagal!';
        if (errors != null) {
          msg = (errors as Map).values.map((e) => e[0]).join('\n');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red),
      );
    }
    setState(() => isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? Color(0xFF2563eb) : Color(0xFFdc2626);

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0f172a) : Color(0xFFf1f5f9),
      appBar: AppBar(
        title: Text('Buat Permintaan',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primary))
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selected items summary
                  if (selectedItems.isNotEmpty) ...[
                    Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Color(0xFF1e293b)
                            : Colors.white,
                        borderRadius:
                        BorderRadius.circular(14),
                        border: Border.all(
                            color: primary.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  'Dipilih (${selectedItems.length})',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight:
                                      FontWeight.bold,
                                      color: primary)),
                              TextButton(
                                onPressed: () => setState(
                                        () => selectedItems.clear()),
                                child: Text('Hapus Semua',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red)),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          ...selectedItems
                              .asMap()
                              .entries
                              .map((entry) {
                            final i = entry.key;
                            final item = entry.value;
                            return Container(
                              margin:
                              EdgeInsets.only(bottom: 6),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color:
                                primary.withOpacity(0.05),
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                      children: [
                                        Text(
                                            item['item_name'] ??
                                                '',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight:
                                                FontWeight
                                                    .w500)),
                                        Text(
                                            'Stok: ${item['item_stock']} ${item['item_unit'] ?? ''}',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color:
                                                Colors.grey)),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (item['quantity'] >
                                                1) {
                                              selectedItems[i][
                                              'quantity']--;
                                            } else {
                                              removeItem(i);
                                            }
                                          });
                                        },
                                        child: Container(
                                          padding:
                                          EdgeInsets.all(4),
                                          decoration:
                                          BoxDecoration(
                                            color: Colors.red
                                                .withOpacity(
                                                0.1),
                                            shape:
                                            BoxShape.circle,
                                          ),
                                          child: Icon(
                                              Icons.remove,
                                              size: 14,
                                              color: Colors.red),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                          '${item['quantity']}',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight:
                                              FontWeight
                                                  .bold)),
                                      SizedBox(width: 10),
                                      GestureDetector(
                                        onTap: () => setState(
                                                () => selectedItems[
                                            i][
                                            'quantity']++),
                                        child: Container(
                                          padding:
                                          EdgeInsets.all(4),
                                          decoration:
                                          BoxDecoration(
                                            color: primary
                                                .withOpacity(
                                                0.1),
                                            shape:
                                            BoxShape.circle,
                                          ),
                                          child: Icon(Icons.add,
                                              size: 14,
                                              color: primary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                  ],

                  // Notes
                  Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Color(0xFF1e293b)
                          : Colors.white,
                      borderRadius:
                      BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      style: TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Catatan (opsional)',
                        border: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(10)),
                        isDense: true,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Search
                  TextField(
                    controller: searchCtrl,
                    onChanged: filterItems,
                    style: TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Cari barang...',
                      prefixIcon: Icon(Icons.search,
                          size: 18, color: Colors.grey),
                      filled: true,
                      fillColor: isDark
                          ? Color(0xFF1e293b)
                          : Colors.white,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  SizedBox(height: 12),

                  Text(
                      'Pilih Barang (${filteredItems.length})',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),

                  // Available items list
                  ...filteredItems.map((item) {
                    final stock = item['stock'] ?? 0;
                    final isSelected = selectedItems.any(
                            (s) => s['item_id'] == item['id']);
                    final selectedQty = isSelected
                        ? selectedItems.firstWhere((s) =>
                    s['item_id'] ==
                        item['id'])['quantity']
                        : 0;

                    return GestureDetector(
                      onTap: stock > 0
                          ? () => addItem(item)
                          : null,
                      child: Container(
                        margin: EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Color(0xFF1e293b)
                              : Colors.white,
                          borderRadius:
                          BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(
                              color: primary,
                              width: 1.5)
                              : Border.all(
                              color: Colors.transparent),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black
                                    .withOpacity(0.04),
                                blurRadius: 4,
                                offset: Offset(0, 2))
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(item['name'] ?? '',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight:
                                          FontWeight.w500)),
                                  SizedBox(height: 2),
                                  Text(
                                    '${item['category'] ?? item['itemCategory']?['name'] ?? '-'} • Stok: $stock ${item['unit'] ?? ''}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: stock > 0
                                            ? Colors.grey
                                            : Colors.red),
                                  ),
                                ],
                              ),
                            ),
                            if (stock == 0)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red
                                      .withOpacity(0.1),
                                  borderRadius:
                                  BorderRadius.circular(6),
                                ),
                                child: Text('Habis',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.red,
                                        fontWeight:
                                        FontWeight.bold)),
                              )
                            else if (isSelected)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4),
                                decoration: BoxDecoration(
                                  color: primary
                                      .withOpacity(0.1),
                                  borderRadius:
                                  BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check,
                                        size: 14,
                                        color: primary),
                                    SizedBox(width: 4),
                                    Text('$selectedQty',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight:
                                            FontWeight.bold,
                                            color: primary)),
                                  ],
                                ),
                              )
                            else
                              Icon(Icons.add_circle_outline,
                                  color: primary, size: 22),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          // Submit button
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF1e293b) : Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -2))
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: isSubmitting
                    ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2))
                    : Text(
                    selectedItems.isEmpty
                        ? 'Pilih barang dulu'
                        : 'Kirim Permintaan (${selectedItems.length} item)',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}