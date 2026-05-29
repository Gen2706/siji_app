import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart';
import 'warehouse_item_detail_screen.dart';
import 'add_warehouse_item_screen.dart';

class WarehouseItemsScreen extends StatefulWidget {
  final bool lowStockOnly;
  const WarehouseItemsScreen({this.lowStockOnly = false});

  @override
  _WarehouseItemsScreenState createState() =>
      _WarehouseItemsScreenState();
}

class _WarehouseItemsScreenState
    extends State<WarehouseItemsScreen> {
  List<dynamic> items = [];
  bool isLoading = true;
  bool isSearching = false;
  final searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  void loadItems() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getWarehouseItems(
        search: searchCtrl.text,
        lowStock: widget.lowStockOnly ? true : null,
      );
      setState(() => items = data);
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
        title: isSearching
            ? TextField(
          controller: searchCtrl,
          autofocus: true,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Cari barang...',
            hintStyle: TextStyle(color: Colors.white60),
            border: InputBorder.none,
          ),
          onChanged: (_) => loadItems(),
        )
            : Text(
            widget.lowStockOnly ? 'Stok Menipis' : 'Data Barang',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) {
                  searchCtrl.clear();
                  loadItems();
                }
              });
            },
          ),
          IconButton(icon: Icon(Icons.refresh), onPressed: loadItems),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AddWarehouseItemScreen()),
        ).then((result) {
          if (result == true) loadItems();
        }),
        backgroundColor: primary,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('Tambah Barang',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primary))
          : items.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Tidak ada barang',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: () async => loadItems(),
        color: primary,
        child: ListView.builder(
          padding:
          EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: items.length,
          itemBuilder: (context, i) =>
              _itemCard(items[i], primary, isDark),
        ),
      ),
    );
  }

  Widget _itemCard(
      Map<String, dynamic> item, Color primary, bool isDark) {
    final stock    = item['stock'] ?? 0;
    final minStock = item['stock_minimum'] ?? 0;
    final isOut    = stock == 0;
    final isLow    = stock > 0 && stock <= minStock;

    Color stockColor = isOut
        ? Colors.red
        : isLow
        ? Colors.orange
        : Colors.green;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                WarehouseItemDetailScreen(itemId: item['id'])),
      ).then((_) => loadItems()),
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(14),
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
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  item['code']
                      ?.toString()
                      .substring(
                      0,
                      item['code'].toString().length > 2
                          ? 2
                          : item['code'].toString().length) ??
                      '??',
                  style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'] ?? '',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  SizedBox(height: 2),
                  Text(
                    '${item['category'] ?? item['itemCategory']?['name'] ?? '-'} • ${item['unit'] ?? '-'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      if (isOut)
                        _badge('HABIS', Colors.red)
                      else if (isLow)
                        _badge('MENIPIS', Colors.orange)
                      else
                        _badge('TERSEDIA', Colors.green),
                      if (item['use_serial_number'] == true) ...[
                        SizedBox(width: 6),
                        _badge('SN', Colors.purple),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$stock',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: stockColor)),
                Text(item['unit'] ?? '',
                    style:
                    TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
            SizedBox(width: 4),
            PopupMenuButton(
              icon: Icon(Icons.more_vert,
                  color: Colors.grey, size: 18),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('Edit',
                        style: TextStyle(fontSize: 13)),
                  ]),
                ),
                PopupMenuItem(
                  value: 'detail',
                  child: Row(children: [
                    Icon(Icons.info_outline, size: 16),
                    SizedBox(width: 8),
                    Text('Detail',
                        style: TextStyle(fontSize: 13)),
                  ]),
                ),
              ],
              onSelected: (val) {
                if (val == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AddWarehouseItemScreen(
                            existingItem: item)),
                  ).then((result) {
                    if (result == true) loadItems();
                  });
                } else if (val == 'detail') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => WarehouseItemDetailScreen(
                            itemId: item['id'])),
                  ).then((_) => loadItems());
                }
              },
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