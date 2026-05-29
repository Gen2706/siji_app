import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/permission_service.dart';
import '../main.dart';

class TicketDetailScreen extends StatefulWidget {
  final int ticketId;
  const TicketDetailScreen({required this.ticketId});

  @override
  _TicketDetailScreenState createState() =>
      _TicketDetailScreenState();
}

class _TicketDetailScreenState
    extends State<TicketDetailScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? ticket;
  Map<String, dynamic>? currentUser;
  bool isLoading = true;
  bool isSending = false;
  late TabController _tabCtrl;
  final commentCtrl = TextEditingController();
  File? selectedPhoto;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadUser();
    loadTicket();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    commentCtrl.dispose();
    super.dispose();
  }

  void _loadUser() async {
    final u = await ApiService.getUser();
    setState(() => currentUser = u);
  }

  void loadTicket() async {
    setState(() => isLoading = true);
    try {
      final result = await ApiService.getDetail(
          'tickets', widget.ticketId);
      setState(() => ticket = result['data']);
    } catch (e) {}
    setState(() => isLoading = false);
  }

  void sendComment() async {
    if (commentCtrl.text.trim().isEmpty &&
        selectedPhoto == null) return;
    setState(() => isSending = true);
    try {
      final result = await ApiService.addComment(
        widget.ticketId,
        commentCtrl.text.trim(),
        photo: selectedPhoto,
      );
      if (result['success'] == true) {
        commentCtrl.clear();
        setState(() => selectedPhoto = null);
        loadTicket();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
              Text(result['message'] ?? 'Gagal kirim!'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red),
      );
    }
    setState(() => isSending = false);
  }

  void updateStatus(String status) async {
    final result = await ApiService.updateTicketStatus(
        widget.ticketId, status);
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('✅ Status diupdate!'),
            backgroundColor: Colors.green),
      );
      loadTicket();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(result['message'] ?? 'Gagal!'),
            backgroundColor: Colors.red),
      );
    }
  }

  void deleteTicket() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Hapus Tiket'),
        content: Text('Yakin ingin menghapus tiket ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal',
                style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              child: Text('Hapus',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    final result = await ApiService.delete(
        'tickets', widget.ticketId);
    if (result['success'] == true) {
      Navigator.pop(context, true);
    }
  }

  // Pilih foto dari kamera atau galeri
  void pickPhoto() async {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final primary =
    isDark ? Color(0xFF2563eb) : Color(0xFFdc2626);

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pilih Sumber Foto',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color:
                          primary.withOpacity(0.1),
                          borderRadius:
                          BorderRadius.circular(14),
                          border: Border.all(
                              color: primary
                                  .withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.camera_alt,
                                color: primary, size: 36),
                            SizedBox(height: 8),
                            Text('Kamera',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                    FontWeight.w600,
                                    color: primary)),
                            Text('Ambil foto baru',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, ImageSource.gallery),
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green
                              .withOpacity(0.1),
                          borderRadius:
                          BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.green
                                  .withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.photo_library,
                                color: Colors.green,
                                size: 36),
                            SizedBox(height: 8),
                            Text('Galeri',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                    FontWeight.w600,
                                    color: Colors.green)),
                            Text('Pilih dari galeri',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Batal',
                    style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1280,
      );
      if (picked != null) {
        setState(() => selectedPhoto = File(picked.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Gagal ambil foto: $e'),
            backgroundColor: Colors.red),
      );
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

  List<String> _getStatusActions(
      String currentStatus, String? role) {
    if (PermissionService.isTeknisi(role)) {
      switch (currentStatus) {
        case 'assigned':
        case 'open':
          return ['in_progress', 'pending'];
        case 'in_progress':
          return ['pending', 'resolved'];
        case 'pending':
          return ['in_progress', 'resolved'];
        default:
          return [];
      }
    }
    switch (currentStatus) {
      case 'open':
        return ['assigned', 'in_progress', 'closed'];
      case 'assigned':
        return ['in_progress', 'resolved', 'closed'];
      case 'in_progress':
        return ['resolved', 'pending', 'closed'];
      case 'pending':
        return ['in_progress', 'resolved', 'closed'];
      case 'resolved':
        return ['closed', 'in_progress'];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final primary =
    isDark ? Color(0xFF2563eb) : Color(0xFFdc2626);
    final role = currentUser?['role'];

    return Scaffold(
      backgroundColor:
      isDark ? Color(0xFF0f172a) : Color(0xFFf1f5f9),
      appBar: AppBar(
        title: Text(
            ticket?['ticket_number'] ?? 'Detail Tiket',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (PermissionService.canDeleteTicket(role))
            IconButton(
              icon: Icon(Icons.delete_outline),
              onPressed: deleteTicket,
            ),
          IconButton(
              icon: Icon(Icons.refresh),
              onPressed: loadTicket),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'Detail'),
            Tab(text: 'Komentar'),
          ],
        ),
      ),
      body: isLoading
          ? Center(
          child:
          CircularProgressIndicator(color: primary))
          : ticket == null
          ? Center(child: Text('Tiket tidak ditemukan'))
          : TabBarView(
        controller: _tabCtrl,
        children: [
          _detailTab(isDark, primary, role),
          _commentsTab(isDark, primary, role),
        ],
      ),
    );
  }

  Widget _detailTab(
      bool isDark, Color primary, String? role) {
    final status = ticket!['status'] ?? '';
    final priority = ticket!['priority'] ?? '';
    final points = ticket!['points'] ?? 0;

    Color statusColor = status == 'open'
        ? Colors.orange
        : status == 'in_progress' || status == 'assigned'
        ? Colors.blue
        : status == 'pending'
        ? Colors.purple
        : status == 'resolved'
        ? Colors.green
        : Colors.grey;

    Color priorityColor =
    priority == 'high' || priority == 'critical'
        ? Colors.red
        : priority == 'medium'
        ? Colors.orange
        : Colors.green;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _card(isDark, [
            Row(
              children: [
                _badge(
                    status
                        .replaceAll('_', ' ')
                        .toUpperCase(),
                    statusColor),
                SizedBox(width: 8),
                _badge(
                    priority.toUpperCase(), priorityColor),
                Spacer(),
                if (PermissionService.canSeeTicketPoints(
                    role))
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius:
                      BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star,
                            color: Colors.amber, size: 14),
                        SizedBox(width: 4),
                        Text('$points pts',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.amber,
                                fontWeight:
                                FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12),
            Text(ticket!['title'] ?? '',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(ticket!['description'] ?? '',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.5)),
          ]),
          SizedBox(height: 12),

          _card(isDark, [
            Text('Info Pelanggan',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            _infoRow(Icons.person_outline, 'Nama',
                ticket!['customer_name'] ?? '-', primary),
            _infoRow(Icons.phone_outlined, 'No. HP',
                ticket!['customer_phone'] ?? '-', primary),
            _infoRow(Icons.category_outlined, 'Kategori',
                ticket!['category']?['name'] ?? '-',
                primary),
            _infoRow(Icons.location_on_outlined, 'Area',
                ticket!['area']?['name'] ?? '-', primary),
          ]),
          SizedBox(height: 12),

          _card(isDark, [
            Text('Penugasan',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            _infoRow(Icons.person_pin_outlined,
                'Dibuat oleh',
                ticket!['requester']?['name'] ?? '-',
                primary),
            _infoRow(Icons.engineering_outlined, 'Assignee',
                ticket!['assignee']?['name'] ?? '-',
                primary),
            if (ticket!['due_date'] != null)
              _infoRow(Icons.event_outlined, 'Deadline',
                  formatDate(ticket!['due_date']), primary),
          ]),
          SizedBox(height: 12),

          if (PermissionService.canUpdateTicketStatus(
              role) &&
              status != 'closed') ...[
            _card(isDark, [
              Text('Update Status',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              if (PermissionService.isTeknisi(role))
                Padding(
                  padding:
                  EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(
                    'Kamu bisa ubah ke: In Progress, Menunggu, atau Selesai',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey),
                  ),
                ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                _getStatusActions(status, role)
                    .map((s) =>
                    _statusButton(s, isDark))
                    .toList(),
              ),
            ]),
            SizedBox(height: 12),
          ],

          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _statusButton(String status, bool isDark) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'resolved':
        color = Colors.green;
        label = 'Selesai';
        icon = Icons.check_circle_outline;
        break;
      case 'closed':
        color = Colors.grey;
        label = 'Tutup';
        icon = Icons.lock_outline;
        break;
      case 'in_progress':
        color = Colors.blue;
        label = 'In Progress';
        icon = Icons.play_circle_outline;
        break;
      case 'pending':
        color = Colors.purple;
        label = 'Menunggu';
        icon = Icons.pause_circle_outline;
        break;
      case 'assigned':
        color = Colors.orange;
        label = 'Assigned';
        icon = Icons.person_outline;
        break;
      default:
        color = Colors.grey;
        label = status.replaceAll('_', ' ');
        icon = Icons.circle_outlined;
    }

    return ElevatedButton.icon(
      onPressed: () => updateStatus(status),
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        elevation: 0,
      ),
    );
  }

  Widget _commentsTab(
      bool isDark, Color primary, String? role) {
    final comments =
        ticket!['comments'] as List? ?? [];

    return Column(
      children: [
        Expanded(
          child: comments.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('Belum ada komentar',
                    style: TextStyle(
                        color: Colors.grey)),
              ],
            ),
          )
              : ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: comments.length,
            itemBuilder: (ctx, i) => _commentCard(
                comments[i], isDark, primary),
          ),
        ),

        if (PermissionService.canAddComment(role))
          Container(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Color(0xFF1e293b)
                  : Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -2))
              ],
            ),
            child: Column(
              children: [
                // Preview foto terpilih
                if (selectedPhoto != null)
                  Stack(
                    children: [
                      Container(
                        height: 80,
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          borderRadius:
                          BorderRadius.circular(8),
                          image: DecorationImage(
                            image:
                            FileImage(selectedPhoto!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(
                                  () => selectedPhoto = null),
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle),
                            child: Icon(Icons.close,
                                color: Colors.white,
                                size: 14),
                          ),
                        ),
                      ),
                    ],
                  ),

                Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.end,
                  children: [
                    // Tombol foto (kamera + galeri)
                    GestureDetector(
                      onTap: pickPhoto,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: selectedPhoto != null
                              ? primary.withOpacity(0.15)
                              : Colors.grey
                              .withOpacity(0.1),
                          borderRadius:
                          BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.add_a_photo_outlined,
                          color: selectedPhoto != null
                              ? primary
                              : Colors.grey,
                          size: 22,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),

                    // Text field komentar
                    Expanded(
                      child: TextField(
                        controller: commentCtrl,
                        style: TextStyle(fontSize: 13),
                        maxLines: 4,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: 'Tulis komentar...',
                          hintStyle:
                          TextStyle(fontSize: 13),
                          border: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color:
                                Colors.grey.shade300),
                          ),
                          enabledBorder:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color:
                                Colors.grey.shade300),
                          ),
                          focusedBorder:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: primary, width: 1.5),
                          ),
                          isDense: true,
                          contentPadding:
                          EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),

                    // Tombol kirim
                    GestureDetector(
                      onTap: isSending ? null : sendComment,
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSending
                              ? Colors.grey
                              : primary,
                          shape: BoxShape.circle,
                        ),
                        child: isSending
                            ? SizedBox(
                            width: 16,
                            height: 16,
                            child:
                            CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2))
                            : Icon(Icons.send,
                            color: Colors.white,
                            size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _commentCard(Map<String, dynamic> comment,
      bool isDark, Color primary) {
    final isMe =
        comment['user_id'] == currentUser?['id'];
    final name = comment['user']?['name'] ?? '-';
    final content = comment['content'] ?? '';
    final photo = comment['photo'];
    final date = formatDate(comment['created_at']);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: primary.withOpacity(0.1),
              child: Text(
                name.isNotEmpty
                    ? name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                    color: primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: Text(name,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: primary)),
                  ),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? primary.withOpacity(0.1)
                        : isDark
                        ? Color(0xFF1e293b)
                        : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft:
                      Radius.circular(isMe ? 12 : 0),
                      topRight:
                      Radius.circular(isMe ? 0 : 12),
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black
                              .withOpacity(0.04),
                          blurRadius: 4,
                          offset: Offset(0, 1))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      if (content.isNotEmpty)
                        Text(content,
                            style: TextStyle(fontSize: 13)),
                      if (photo != null) ...[
                        SizedBox(height: 6),
                        ClipRRect(
                          borderRadius:
                          BorderRadius.circular(8),
                          child: Image.network(
                            photo,
                            width: 200,
                            fit: BoxFit.cover,
                            loadingBuilder:
                                (ctx, child, progress) {
                              if (progress == null)
                                return child;
                              return Container(
                                width: 200,
                                height: 120,
                                color: Colors.grey[200],
                                child: Center(
                                    child:
                                    CircularProgressIndicator(
                                        strokeWidth: 2)),
                              );
                            },
                            errorBuilder: (_, __, ___) =>
                                Container(
                                  width: 200,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius:
                                    BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image,
                                          color: Colors.grey),
                                      Text('Gagal load foto',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey)),
                                    ],
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 2),
                Text(date,
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          if (isMe) SizedBox(width: 8),
        ],
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

  Widget _infoRow(IconData icon, String label,
      String value, Color primary) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: primary),
          SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey)),
          ),
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

  Widget _badge(String text, Color color) {
    return Container(
      padding:
      EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border:
          Border.all(color: color.withOpacity(0.3))),
      child: Text(text,
          style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold)),
    );
  }
}
