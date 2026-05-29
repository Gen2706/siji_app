import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart';

class WarehouseRequestDetailScreen extends StatefulWidget {
  final int requestId;
  const WarehouseRequestDetailScreen({required this.requestId});

  @override
  _WarehouseRequestDetailScreenState createState() =>
      _WarehouseRequestDetailScreenState();
}

class _WarehouseRequestDetailScreenState
    extends State<WarehouseRequestDetailScreen> {
  Map<String, dynamic>? request;
  bool isLoading = true;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() async {
    setState(() => isLoading = true);
    try {
      final result = await ApiService.getDetail(
          'warehouse/requests', widget.requestId);
      setState(() => request = result['data']);
    } catch (e) {}
    setState(() => isLoading = false);
  }

  void approve() async {
    setState(() => isUpdating = true);
    final result =
    await ApiService.approveItemRequest(widget.requestId);
    setState(() => isUpdating = false);
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('✅ Request disetujui!'),
            backgroundColor: Colors.green),
      );
      load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(result['message'] ?? 'Gagal!'),
            backgroundColor: Colors.red),
      );
    }
  }

  void reject() async {
    setState(() => isUpdating = true);
    final result =
    await ApiService.rejectItemRequest(widget.requestId);
    setState(() => isUpdating = false);
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Request ditolak'),
            backgroundColor: Colors.orange),
      );
      load();
    }
  }

  void cancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Batalkan Request'),
        content: Text('Yakin ingin membatalkan permintaan ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Tidak')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Ya', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => isUpdating = true);
    final result =
    await ApiService.cancelItemRequest(widget.requestId);
    setState(() => isUpdating = false);
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request dibatalkan')),
      );
      Navigator.pop(context, true);
    }
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

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0f172a) : Color(0xFFf1f5f9),
      appBar: AppBar(
        title: Text(
            request?['request_number'] ?? 'Detail Permintaan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: load),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primary))
          : request == null
          ? Center(child: Text('Data tidak ditemukan'))
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            _card(isDark, [
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                          request!['request_number'] ??
                              'Request #${request!['id']}',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text(formatDate(request!['created_at']),
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey)),
                    ],
                  ),
                  _statusBadge(request!['status']),
                ],
              ),
              if (request!['notes'] != null &&
                  request!['notes'].isNotEmpty) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notes,
                          size: 14, color: Colors.grey),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(request!['notes'],
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey)),
                      ),
                    ],
                  ),
                ),
              ],
            ]),
            SizedBox(height: 12),

            // Requester Info
            _card(isDark, [
              Text('Informasi Pemohon',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor:
                    primary.withOpacity(0.1),
                    child: Text(
                      ((request!['requester']?['name'] ??
                          'U')[0])
                          .toString()
                          .toUpperCase(),
                      style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                          request!['requester']?['name'] ??
                              '-',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                      Text(
                          request!['requester']?['role'] ??
                              '-',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ]),
            SizedBox(height: 12),

            // Items List
            _card(isDark, [
              Text(
                  'Daftar Barang (${(request!['details'] as List? ?? []).length} item)',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              ...(request!['details'] as List? ?? [])
                  .map((detail) {
                final item = detail['item'];
                final qty = detail['quantity'] ?? 0;
                final itemStock = item?['stock'] ?? 0;
                final isEnough = itemStock >= qty;

                return Container(
                  margin: EdgeInsets.only(bottom: 10),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Color(0xFF0f172a)
                        : Color(0xFFf8fafc),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isEnough
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.1),
                          borderRadius:
                          BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            item?['code']
                                ?.toString()
                                .substring(
                                0,
                                (item['code']
                                    .toString()
                                    .length >
                                    2)
                                    ? 2
                                    : item['code']
                                    .toString()
                                    .length) ??
                                '??',
                            style: TextStyle(
                                color: primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(item?['name'] ?? '-',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                    FontWeight.w500),
                                maxLines: 1,
                                overflow:
                                TextOverflow.ellipsis),
                            Text(
                                'Stok tersedia: $itemStock ${item?['unit'] ?? ''}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: isEnough
                                        ? Colors.green
                                        : Colors.red)),
                            if (detail['notes'] != null &&
                                detail['notes']
                                    .isNotEmpty)
                              Text(detail['notes'],
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.end,
                        children: [
                          Text('$qty',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primary)),
                          Text(item?['unit'] ?? '',
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
            SizedBox(height: 12),

            // Action Buttons
            if (request!['status'] == 'pending') ...[
              isUpdating
                  ? Center(
                  child: CircularProgressIndicator(
                      color: primary))
                  : Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: approve,
                      icon: Icon(Icons.check_circle,
                          size: 18),
                      label: Text('Setujui Permintaan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                                12)),
                        padding: EdgeInsets.symmetric(
                            vertical: 14),
                        elevation: 0,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: reject,
                          icon: Icon(Icons.close,
                              size: 16,
                              color: Colors.red),
                          label: Text('Tolak',
                              style: TextStyle(
                                  color: Colors.red)),
                          style:
                          OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Colors.red),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(
                                    12)),
                            padding: EdgeInsets.symmetric(
                                vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: cancel,
                          icon: Icon(Icons.cancel_outlined,
                              size: 16,
                              color: Colors.grey),
                          label: Text('Batalkan',
                              style: TextStyle(
                                  color: Colors.grey)),
                          style:
                          OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Colors.grey),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(
                                    12)),
                            padding: EdgeInsets.symmetric(
                                vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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

  Widget _statusBadge(String? status) {
    Color color;
    String label;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'PENDING';
        break;
      case 'approved':
      case 'approved_admin':
      case 'approved_head':
        color = Colors.green;
        label = 'DISETUJUI';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'DITOLAK';
        break;
      case 'cancelled':
        color = Colors.grey;
        label = 'DIBATALKAN';
        break;
      default:
        color = Colors.grey;
        label = (status ?? '').toUpperCase();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold)),
    );
  }
}