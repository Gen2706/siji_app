import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../main.dart';

class CreateTicketScreen extends StatefulWidget {
  @override
  _CreateTicketScreenState createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final customerNameCtrl = TextEditingController();
  final customerPhoneCtrl = TextEditingController();
  final pointsCtrl = TextEditingController(text: '10');

  List<dynamic> categories = [];
  List<dynamic> areas = [];
  List<dynamic> teknisiList = [];

  int? selectedCategory;
  int? selectedArea;
  int? selectedAssignee;
  String selectedPriority = 'medium';
  String selectedClientStatus = 'Home Retail';
  bool isLoading = false;
  bool isLoadingData = true;

  final priorities = ['low', 'medium', 'high', 'critical'];
  final clientStatuses = ['Home Retail', 'Soho', 'Dedicated', 'POP'];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    customerNameCtrl.dispose();
    customerPhoneCtrl.dispose();
    pointsCtrl.dispose();
    super.dispose();
  }

  void loadData() async {
    setState(() => isLoadingData = true);
    try {
      // Ambil areas dari data user yang sudah disimpan
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');
      List<dynamic> userAreas = [];
      if (userStr != null) {
        final user = jsonDecode(userStr);
        userAreas = user['areas'] ?? [];
      }

      // Kalau areas kosong di local, fetch dari API
      if (userAreas.isEmpty) {
        userAreas = await ApiService.getAreas();
      }

      final c = await ApiService.getCategories();
      final t = await ApiService.getTeknisi();

      setState(() {
        categories = c;
        areas = userAreas;
        teknisiList = t;
        if (c.isNotEmpty) {
          selectedCategory = c[0]['id'];
          pointsCtrl.text = '${c[0]['default_points'] ?? 10}';
        }
        if (userAreas.isNotEmpty) selectedArea = userAreas[0]['id'];
      });
    } catch (e) {}
    setState(() => isLoadingData = false);
  }

  void submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih kategori terlebih dahulu!')),
      );
      return;
    }
    if (selectedArea == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih area terlebih dahulu!')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final body = {
        'title': titleCtrl.text.trim(),
        'description': descCtrl.text.trim(),
        'category_id': selectedCategory,
        'client_status': selectedClientStatus,
        'customer_name': customerNameCtrl.text.trim(),
        'customer_phone': customerPhoneCtrl.text.trim(),
        'priority': selectedPriority,
        'points': int.tryParse(pointsCtrl.text) ?? 10,
        'area_id': selectedArea,
        if (selectedAssignee != null) 'assignees': [selectedAssignee],
      };

      final result = await ApiService.createTicket(body);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Tiket berhasil dibuat!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        final errors = result['errors'];
        String msg = result['message'] ?? 'Gagal membuat tiket!';
        if (errors != null) {
          msg = (errors as Map).values.map((e) => e[0]).join('\n');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Koneksi gagal!'), backgroundColor: Colors.red),
      );
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? Color(0xFF2563eb) : Color(0xFFdc2626);

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0f172a) : Color(0xFFf1f5f9),
      appBar: AppBar(
        title: Text('Buat Tiket', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoadingData
          ? Center(child: CircularProgressIndicator(color: primary))
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section('Informasi Tiket', isDark, [
                _field('Judul Tiket', titleCtrl, 'Masukkan judul tiket', required: true),
                SizedBox(height: 12),
                _fieldMultiline('Deskripsi', descCtrl,
                    'Jelaskan masalah secara detail', required: true),
                SizedBox(height: 12),
                _dropdown(
                  'Kategori',
                  categories,
                  selectedCategory,
                  'name',
                      (val) {
                    setState(() {
                      selectedCategory = val;
                      final cat = categories.firstWhere(
                              (c) => c['id'] == val, orElse: () => {});
                      if (cat['default_points'] != null) {
                        pointsCtrl.text = '${cat['default_points']}';
                      }
                    });
                  },
                  primary,
                  isDark,
                ),
                SizedBox(height: 12),
                _dropdownString(
                  'Prioritas',
                  priorities,
                  selectedPriority,
                      (val) => setState(() => selectedPriority = val!),
                  primary,
                  isDark,
                ),
                SizedBox(height: 12),
                _field('Poin', pointsCtrl, '10',
                    keyboardType: TextInputType.number, required: true),
              ]),
              SizedBox(height: 16),

              _section('Informasi Pelanggan', isDark, [
                _field('Nama Pelanggan', customerNameCtrl,
                    'Masukkan nama pelanggan', required: true),
                SizedBox(height: 12),
                _field('No. Telepon', customerPhoneCtrl,
                    'Masukkan nomor telepon',
                    keyboardType: TextInputType.phone),
                SizedBox(height: 12),
                _dropdownString(
                  'Status Klien',
                  clientStatuses,
                  selectedClientStatus,
                      (val) => setState(() => selectedClientStatus = val!),
                  primary,
                  isDark,
                ),
              ]),
              SizedBox(height: 16),

              _section('Penugasan', isDark, [
                // Area dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Area',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey)),
                    SizedBox(height: 4),
                    areas.isEmpty
                        ? Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Tidak ada area tersedia',
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                    )
                        : DropdownButtonFormField<int>(
                      value: selectedArea,
                      isExpanded: true,
                      style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Colors.grey.shade300)),
                      ),
                      items: areas
                          .map((area) => DropdownMenuItem<int>(
                        value: area['id'],
                        child: Text(
                            '${area['name']} (${area['code']})',
                            style: TextStyle(fontSize: 13)),
                      ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => selectedArea = val),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Assignee dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Assignee (Opsional)',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey)),
                    SizedBox(height: 4),
                    DropdownButtonFormField<int?>(
                      value: selectedAssignee,
                      isExpanded: true,
                      style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                            BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                            BorderSide(color: Colors.grey.shade300)),
                      ),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text('-- Tidak ditugaskan --',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey)),
                        ),
                        ...teknisiList
                            .map((t) => DropdownMenuItem<int?>(
                          value: t['id'],
                          child: Text(t['name'] ?? '',
                              style: TextStyle(fontSize: 13)),
                        ))
                            .toList(),
                      ],
                      onChanged: (val) =>
                          setState(() => selectedAssignee = val),
                    ),
                  ],
                ),
              ]),
              SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : Text('Buat Tiket',
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
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint,
      {bool required = false,
        TextInputType keyboardType = TextInputType.text}) {
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

  Widget _fieldMultiline(String label, TextEditingController ctrl, String hint,
      {bool required = false}) {
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
          maxLines: 3,
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

  Widget _dropdown(String label, List<dynamic> items, int? value,
      String nameKey, Function(int?) onChanged, Color primary, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey)),
        SizedBox(height: 4),
        DropdownButtonFormField<int>(
          value: value,
          isExpanded: true,
          style: TextStyle(
              fontSize: 13, color: isDark ? Colors.white : Colors.black),
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
          items: items
              .map((item) => DropdownMenuItem<int>(
            value: item['id'],
            child: Text(item[nameKey] ?? '',
                style: TextStyle(fontSize: 13)),
          ))
              .toList(),
          onChanged: (val) => onChanged(val),
        ),
      ],
    );
  }

  Widget _dropdownString(String label, List<String> items, String value,
      Function(String?) onChanged, Color primary, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey)),
        SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          style: TextStyle(
              fontSize: 13, color: isDark ? Colors.white : Colors.black),
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
          items: items
              .map((item) => DropdownMenuItem<String>(
            value: item,
            child: Text(item, style: TextStyle(fontSize: 13)),
          ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
