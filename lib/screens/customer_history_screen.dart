import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart';
import 'ticket_detail_screen.dart';

class CustomerHistoryScreen extends StatefulWidget {
  @override
  _CustomerHistoryScreenState createState() =>
      _CustomerHistoryScreenState();
}

class _CustomerHistoryScreenState
    extends State<CustomerHistoryScreen> {
  final searchCtrl = TextEditingController();
  List<dynamic> tickets = [];
  bool isLoading = false;
  bool hasSearched = false;
  String searchType = 'phone'; // phone or name

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  void search() async {
    if (searchCtrl.text.trim().isEmpty) return;
    setState(() { isLoading = true; hasSearched = true; });
    try {
      final data = await ApiService.getCustomerHistory(
        customerPhone: searchType == 'phone' ? searchCtrl.text.trim() : null,
        customerName: searchType == 'name' ? searchCtrl.text.trim() : null,
      );
      setState(() => tickets = data);
    } catch (e) {}
    setState(() => isLoading = false);
  }

  // Group tiket by customer
  Map<String, List<dynamic>> get groupedTickets {
    final Map<String, List<dynamic>> grouped = {};
    for (final ticket in tickets) {
      final key = '${ticket['customer_name']} | ${ticket['customer_phone'] ?? 'No HP'}';
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(ticket);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? Color(0xFF2563eb) : Color(0xFFdc2626);

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0f172a) : Color(0xFFf1f5f9),
      appBar: AppBar(
        title: Text('History Pelanggan',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: primary,
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Toggle search type
                Row(
                  children: [
                    _toggleBtn('Nomor HP', 'phone', primary),
                    SizedBox(width: 8),
                    _toggleBtn('Nama', 'name', primary),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchCtrl,
                        style: TextStyle(fontSize: 13),
                        onSubmitted: (_) => search(),
                        decoration: InputDecoration(
                          hintText: searchType == 'phone'
                              ? 'Cari nomor HP pelanggan...'
                              : 'Cari nama pelanggan...',
                          hintStyle:
                          TextStyle(color: Colors.grey, fontSize: 13),
                          filled: true,
                          fillColor: Colors.white,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(
                            searchType == 'phone'
                                ? Icons.phone_outlined
                                : Icons.person_outline,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: search,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        elevation: 0,
                      ),
                      child: Icon(Icons.search, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: isLoading
                ? Center(
                child: CircularProgressIndicator(color: primary))
                : !hasSearched
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_search,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Cari history tiket pelanggan',
                      style: TextStyle(
                          color: Colors.grey, fontSize: 14)),
                  SizedBox(height: 4),
                  Text(
                      'Gunakan nomor HP atau nama pelanggan',
                      style: TextStyle(
                          color: Colors.grey, fontSize: 12)),
                ],
              ),
            )
                : tickets.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Tidak ada tiket ditemukan',
                      style: TextStyle(
                          color: Colors.grey)),
                ],
              ),
            )
                : ListView(
              padding: EdgeInsets.all(16),
              children: [
                // Summary
                Container(
                  padding: EdgeInsets.all(14),
                  margin: EdgeInsets.only(bottom: 16),
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
                      SizedBox(width: 8),
                      Text(
                        'Ditemukan ${tickets.length} tiket dari ${groupedTickets.length} pelanggan',
                        style: TextStyle(
                            color: primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),

                // Grouped by customer
                ...groupedTickets.entries.map((entry) {
                  final parts = entry.key.split(' | ');
                  final custName = parts[0];
                  final custPhone =
                  parts.length > 1 ? parts[1] : '-';
                  final custTickets = entry.value;

                  return Container(
                    margin:
                    EdgeInsets.only(bottom: 16),
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
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        // Customer header
                        Container(
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color:
                            primary.withOpacity(0.05),
                            borderRadius:
                            BorderRadius.vertical(
                                top: Radius.circular(
                                    14)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: primary
                                    .withOpacity(0.15),
                                child: Text(
                                  custName.isNotEmpty
                                      ? custName[0]
                                      .toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                      color: primary,
                                      fontWeight:
                                      FontWeight.bold),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                                  children: [
                                    Text(custName,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight:
                                            FontWeight
                                                .bold)),
                                    Row(
                                      children: [
                                        Icon(
                                            Icons
                                                .phone_outlined,
                                            size: 12,
                                            color:
                                            Colors.grey),
                                        SizedBox(width: 4),
                                        Text(custPhone,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors
                                                    .grey)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4),
                                decoration: BoxDecoration(
                                  color: primary
                                      .withOpacity(0.1),
                                  borderRadius:
                                  BorderRadius.circular(
                                      10),
                                ),
                                child: Text(
                                  '${custTickets.length} tiket',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: primary,
                                      fontWeight:
                                      FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Ticket list
                        ...custTickets.map((ticket) =>
                            _ticketItem(
                                ticket, primary, isDark)),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, String type, Color primary) {
    final isSelected = searchType == type;
    return GestureDetector(
      onTap: () => setState(() => searchType = type),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? primary : Colors.white,
            fontWeight: isSelected
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _ticketItem(
      Map<String, dynamic> ticket, Color primary, bool isDark) {
    final status = ticket['status'] ?? '';
    Color statusColor = status == 'open'
        ? Colors.orange
        : status == 'in_progress' || status == 'assigned'
        ? Colors.blue
        : status == 'resolved'
        ? Colors.green
        : Colors.grey;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                TicketDetailScreen(ticketId: ticket['id'])),
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
                color: Colors.grey.withOpacity(0.1), width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 45,
              decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(3)),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text(ticket['ticket_number'] ?? '',
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey)),
                      Text(
                        ticket['created_at'] != null
                            ? ticket['created_at']
                            .toString()
                            .substring(0, 10)
                            : '',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(ticket['title'] ?? '',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
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
                      Spacer(),
                      Icon(Icons.chevron_right,
                          size: 16, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
}