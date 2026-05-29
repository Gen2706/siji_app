import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart';

class ListScreen extends StatefulWidget {
  final String title;
  final String endpoint;
  ListScreen({required this.title, required this.endpoint});

  @override
  _ListScreenState createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  List<dynamic> items = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    setState(() { isLoading = true; error = null; });
    try {
      final data = await ApiService.getList(widget.endpoint);
      setState(() => items = data);
    } catch (e) {
      setState(() => error = 'Gagal memuat data!');
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? Color(0xFF2563eb) : Color(0xFFdc2626);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: loadData),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: primary,
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primary))
          : error != null
          ? Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text(error!, style: TextStyle(color: Colors.grey)),
          SizedBox(height: 16),
          ElevatedButton(onPressed: loadData, child: Text('Coba Lagi')),
        ],
      ))
          : items.isEmpty
          ? Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text('Data kosong', style: TextStyle(color: Colors.grey)),
        ],
      ))
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            margin: EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: primary.withOpacity(0.1),
                child: Text('${index + 1}',
                    style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
              ),
              title: Text(
                item['title']?.toString() ??
                    item['name']?.toString() ??
                    item['nama']?.toString() ??
                    'Item ${index + 1}',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                item['status']?.toString() ??
                    item['email']?.toString() ??
                    item['description']?.toString() ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Icon(Icons.chevron_right, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}
