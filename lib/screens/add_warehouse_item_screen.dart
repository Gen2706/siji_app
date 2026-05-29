import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart';

class AddWarehouseItemScreen extends StatefulWidget {
  final Map<String, dynamic>? existingItem;
  const AddWarehouseItemScreen({this.existingItem});

  @override
  _AddWarehouseItemScreenState createState() =>
      _AddWarehouseItemScreenState();
}

class _AddWarehouseItemScreenState
    extends State<AddWarehouseItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final codeCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final unitCtrl = TextEditingController();
  final stockCtrl = TextEditingController(text: '0');
  final minStockCtrl = TextEditingController(text: '5');
  final descCtrl = TextEditingController();

  List<dynamic> categories = [];
  List<dynamic> types = [];
  List<dynamic> areas = [];

  int? selectedCategory;
  int? selectedType;
  int? selectedArea;
  bool useSerial = false;
  bool isLoading = true;
  bool isSaving = false;
  bool isEdit = false;

  @override
  void initState() {
    super.initState();
    isEdit = widget.existingItem != null;
    if (isEdit) {
      final item = widget.existingItem!;
      codeCtrl.text = item['code'] ?? '';
      nameCtrl.text = item['name'] ?? '';
      unitCtrl.text = item['unit'] ?? '';
      stockCtrl.text = '${item['stock'] ?? 0}';
      minStockCtrl.text = '${item['stock_minimum'] ?? 5}';
      descCtrl.text = item['description'] ?? '';
      selectedCategory = item['item_category_id'];
      selectedType = item['item_type_id'];
      selectedArea = item['area_id'];
      useSerial = item['use_serial_number'] ?? false;
    }
    loadMasterData();
  }

  @override
  void dispose() {
    codeCtrl.dispose();
    nameCtrl.dispose();
    unitCtrl.dispose();
    stockCtrl.dispose();
    minStockCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  void loadMasterData() async {
    setState(() => isLoading = true);
    try {
      final c = await ApiService.getWarehouseCategories();
      final t = await ApiService.getWarehouseTypes();
      final a = await ApiService.getAreas();
      setState(() {
        categories = c;
        types = t;
        areas = a;
      });
    } catch (e) {}
    setState(() => isLoading = false);
  }

  void save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSaving = true);

    try {
      final body = {
        'code': codeCtrl.text.trim(),
        'name': nameCtrl.text.trim(),
        'unit': unitCtrl.text.trim(),
        'stock': int.tryParse(stockCtrl.text) ?? 0,
        'stock_minimum': int.tryParse(minStockCtrl.text) ?? 5,
        'description': descCtrl.text.trim(),
        'use_serial_number': useSerial,
        if (selectedCategory != null) 'item_category_id': selectedCategory,
        if (selectedType != null) 'item_type_id': selectedType,
        if (selectedArea != null) 'area_id': selectedArea,
      };

      Map<String, dynamic> result;
      if (isEdit) {
        result = await ApiService.updateWarehouseItem(
            widget.existingItem!['id'], body);
      } else {
        result = await ApiService.storeWarehouseItem(body);
      }

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isEdit
                  ? '✅ Barang berhasil diupdate!'
                  : '✅ Barang berhasil ditambahkan!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        final errors = result['errors'];
        String msg = result['message'] ?? 'Gagal!';
        if (errors != null) {
          msg = (errors as Map).values.map((e) => e[0]).join('\n');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
    setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? Color(0xFF2563eb) : Color(0xFFdc2626);

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0f172a) : Color(0xFFf1f5f9),
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Barang' : 'Tambah Barang',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primary))
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _section('Informasi Barang', isDark, [
                _field('Kode Barang', codeCtrl, 'contoh: ONT-001',
                    required: true),
                SizedBox(height: 12),
                _field('Nama Barang', nameCtrl,
                    'contoh: ONT ZTE F660', required: true),
                SizedBox(height: 12),
                _field('Satuan', unitCtrl, 'contoh: pcs, meter, unit',
                    required: true),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _field('Stok Awal', stockCtrl, '0',
                          keyboardType: TextInputType.number,
                          required: !isEdit),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _field('Stok Minimum', minStockCtrl, '5',
                          keyboardType: TextInputType.number),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                _field('Deskripsi', descCtrl, 'Opsional',
                    maxLines: 2),
              ]),
              SizedBox(height: 16),

              _section('Klasifikasi', isDark, [
                _dropdownWidget('Kategori', categories,
                    selectedCategory, 'name',
                        (val) => setState(() => selectedCategory = val),
                    primary, isDark),
                SizedBox(height: 12),
                _dropdownWidget('Tipe', types, selectedType, 'name',
                        (val) => setState(() => selectedType = val),
                    primary, isDark),
                SizedBox(height: 12),
                _dropdownWidget('Area', areas, selectedArea, 'name',
                        (val) => setState(() => selectedArea = val),
                    primary, isDark),
              ]),
              SizedBox(height: 16),

              _section('Pengaturan', isDark, [
                SwitchListTile(
                  title: Text('Gunakan Serial Number',
                      style: TextStyle(fontSize: 13)),
                  subtitle: Text(
                      'Aktifkan jika setiap unit punya nomor seri',
                      style:
                      TextStyle(fontSize: 11, color: Colors.grey)),
                  value: useSerial,
                  activeColor: primary,
                  onChanged: (v) => setState(() => useSerial = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ]),
              SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isSaving ? null : save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: isSaving
                      ? SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : Text(
                      isEdit ? 'Update Barang' : 'Simpan Barang',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, bool isDark, List<Widget> children) {
    return Container(
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
        children: [
          Text(title,
              style:
              TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint,
      {bool required = false,
        TextInputType keyboardType = TextInputType.text,
        int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey)),
        SizedBox(height: 4),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(fontSize: 13),
          validator: required
              ? (v) => v!.isEmpty ? '$label wajib diisi' : null
              : null,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding:
            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
        ),
      ],
    );
  }

  Widget _dropdownWidget(String label, List<dynamic> items, int? value,
      String nameKey, Function(int?) onChanged, Color primary,
      bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey)),
        SizedBox(height: 4),
        DropdownButtonFormField<int?>(
          value: value,
          isExpanded: true,
          style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
          items: [
            DropdownMenuItem<int?>(
                value: null,
                child: Text('-- Pilih $label --',
                    style: TextStyle(color: Colors.grey, fontSize: 13))),
            ...items.map((item) => DropdownMenuItem<int?>(
              value: item['id'],
              child: Text(item[nameKey] ?? '',
                  style: TextStyle(fontSize: 13)),
            )),
          ],
          onChanged: (val) => onChanged(val),
        ),
      ],
    );
  }
}