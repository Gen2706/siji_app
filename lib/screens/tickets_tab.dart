import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/permission_service.dart';
import '../main.dart';
import 'create_ticket_screen.dart';
import 'ticket_detail_screen.dart';
import 'customer_history_screen.dart';

class TicketsTab extends StatefulWidget {
  @override
  _TicketsTabState createState() => _TicketsTabState();
}

class _TicketsTabState extends State<TicketsTab>
    with SingleTickerProviderStateMixin {
  List<dynamic> tickets = [];
  bool isLoading = true;
  late TabController _tabController;
  final tabs = ['Semua', 'Open', 'In Progress', 'Selesai'];
  final searchCtrl = TextEditingController();
  Map<String, dynamic>? user;

  String? filterStatus;
  String? filterPriority;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _loadUser();
    loadTickets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchCtrl.dispose();
    super.dispose();
  }

  void _loadUser() async {
    final u = await ApiService.getUser();
    setState(() => user = u);
  }

  void loadTickets() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.searchTickets(
        search: searchCtrl.text,
        status: filterStatus,
        priority: filterPriority,
      );
      setState(() => tickets = data);
    } catch (e) {}
    setState(() => isLoading = false);
  }

  List<dynamic> filtered(String tab) {
    if (tab == 'Semua') return tickets;
    if (tab == 'Open')
      return tickets.where((t) => t['status'] == 'open').toList();
    if (tab == 'In Progress')
      return tickets
          .where((t) =>
      t['status'] == 'in_progress' ||
          t['status'] == 'assigned')
          .toList();
    if (tab == 'Selesai')
      return tickets
          .where((t) =>
      t['status'] == 'resolved' || t['status'] == 'closed')
          .toList();
    return tickets;
  }

  void showFilterDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? Color(0xFF2563eb) : Color(0xFFdc2626);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filter Tiket',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      setModal(() {
                        filterStatus = null;
                        filterPriority = null;
                      });
                      setState(() {});
                    },
                    child: Text('Reset',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text('Status',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  'open',
                  'assigned',
                  'in_progress',
                  'resolved',
                  'closed'
                ]
                    .map((s) => ChoiceChip(
                  label: Text(
                      s.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(fontSize: 11)),
                  selected: filterStatus == s,
                  selectedColor: primary.withOpacity(0.2),
                  onSelected: (v) {
                    setModal(() =>
                    filterStatus = v ? s : null);
                    setState(() {});
                  },
                ))
                    .toList(),
              ),
              SizedBox(height: 12),
              Text('Prioritas',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: ['low', 'medium', 'high', 'critical']
                    .map((p) => ChoiceChip(
                  label: Text(p.toUpperCase(),
                      style: TextStyle(fontSize: 11)),
                  selected: filterPriority == p,
                  selectedColor: primary.withOpacity(0.2),
                  onSelected: (v) {
                    setModal(() =>
                    filterPriority = v ? p : null);
                    setState(() {});
                  },
                ))
                    .toList(),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    loadTickets();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Terapkan Filter',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? Color(0xFF2563eb) : Color(0xFFdc2626);
    final role = user?['role'];
    final hasFilter =
        filterStatus != null || filterPriority != null;

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0f172a) : Color(0xFFf1f5f9),
      appBar: AppBar(
        title: Text('Tiket',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _TicketSearchDelegate(
                    role: role, primary: primary, isDark: isDark),
              );
            },
          ),
          Stack(
            children: [
              IconButton(
                  icon: Icon(Icons.filter_list),
                  onPressed: showFilterDialog),
              if (hasFilter)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: Colors.yellow,
                        shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
          // History pelanggan hanya untuk admin & user
          if (PermissionService.canSeeCustomerHistory(role))
            IconButton(
              icon: Icon(Icons.person_search_outlined),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => CustomerHistoryScreen())),
              tooltip: 'History Pelanggan',
            ),
          IconButton(
              icon: Icon(Icons.refresh), onPressed: loadTickets),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600),
          tabs: tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),

      // FAB hanya untuk admin & user
      floatingActionButton:
      PermissionService.canCreateTicket(role)
          ? FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CreateTicketScreen()));
          if (result == true) loadTickets();
        },
        backgroundColor: primary,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('Buat Tiket',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600)),
      )
          : null,

      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primary))
          : TabBarView(
        controller: _tabController,
        children: tabs.map((tab) {
          final list = filtered(tab);
          if (list.isEmpty)
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    PermissionService.isTeknisi(role)
                        ? 'Belum ada tiket yang di-assign ke kamu'
                        : 'Tidak ada tiket',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          return RefreshIndicator(
            onRefresh: () async => loadTickets(),
            color: primary,
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: list.length,
              itemBuilder: (context, i) =>
                  _ticketCard(list[i], primary, isDark, role),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _ticketCard(Map<String, dynamic> ticket, Color primary,
      bool isDark, String? role) {
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

    String formatDate(String? dateStr) {
      if (dateStr == null) return '-';
      try {
        final dt = DateTime.parse(dateStr).toLocal();
        return '${dt.day}/${dt.month}/${dt.year}';
      } catch (e) {
        return dateStr;
      }
    }

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    TicketDetailScreen(ticketId: ticket['id'])));
        if (result == true) loadTickets();
      },
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
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                  width: 4,
                  height: 70,
                  decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(4))),
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
                        Text(ticket['category']?['name'] ?? '',
                            style: TextStyle(
                                fontSize: 10,
                                color: primary,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(ticket['title'] ?? '',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 12, color: Colors.grey),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            ticket['customer_name'] ?? '',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        _badge(
                            status
                                .replaceAll('_', ' ')
                                .toUpperCase(),
                            statusColor),
                        SizedBox(width: 6),
                        _badge(
                            priority.toUpperCase(), priorityColor),
                        Spacer(),
                        if (ticket['due_date'] != null) ...[
                          Icon(Icons.schedule,
                              size: 12, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(formatDate(ticket['due_date']),
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.chevron_right,
                  color: Colors.grey, size: 18),
            ],
          ),
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

// Search Delegate
class _TicketSearchDelegate extends SearchDelegate<String> {
  final String? role;
  final Color primary;
  final bool isDark;

  _TicketSearchDelegate(
      {this.role, required this.primary, required this.isDark});

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(
        icon: Icon(Icons.clear),
        onPressed: () => query = '')
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: Icon(Icons.arrow_back),
    onPressed: () => close(context, ''),
  );

  @override
  Widget buildResults(BuildContext context) => _buildList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildList();

  Widget _buildList() {
    return FutureBuilder<List<dynamic>>(
      future: ApiService.searchTickets(search: query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: primary));
        }
        final tickets = snapshot.data ?? [];
        if (tickets.isEmpty) {
          return Center(
              child: Text('Tidak ada hasil untuk "$query"',
                  style: TextStyle(color: Colors.grey)));
        }
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: tickets.length,
          itemBuilder: (ctx, i) {
            final t = tickets[i];
            return ListTile(
              title: Text(t['title'] ?? ''),
              subtitle: Text(
                  '${t['ticket_number']} • ${t['customer_name'] ?? ''}'),
              trailing: Text(t['status'] ?? '',
                  style: TextStyle(fontSize: 11)),
              onTap: () {
                close(context, '');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          TicketDetailScreen(ticketId: t['id'])),
                );
              },
            );
          },
        );
      },
    );
  }
}