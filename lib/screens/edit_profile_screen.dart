import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const EditProfileScreen({required this.user});

  @override
  _EditProfileScreenState createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {
  late TextEditingController nameCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController deptCtrl;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    nameCtrl =
        TextEditingController(text: widget.user['name'] ?? '');
    phoneCtrl =
        TextEditingController(text: widget.user['phone'] ?? '');
    deptCtrl = TextEditingController(
        text: widget.user['department'] ?? '');
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    deptCtrl.dispose();
    super.dispose();
  }

  void save() async {
    if (nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nama tidak boleh kosong!')),
      );
      return;
    }

    setState(() => isSaving = true);
    try {
      final result = await ApiService.updateProfile({
        'name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'department': deptCtrl.text.trim(),
      });

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('✅ Profil berhasil diupdate!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        final errors = result['errors'];
        String msg = result['message'] ?? 'Gagal!';
        if (errors != null) {
          msg = (errors as Map)
              .values
              .map((e) => e[0])
              .join('\n');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(msg),
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
    setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final primary =
    isDark ? Color(0xFF2563eb) : Color(0xFFdc2626);

    return Scaffold(
      backgroundColor:
      isDark ? Color(0xFF0f172a) : Color(0xFFf1f5f9),
      appBar: AppBar(
        title: Text('Edit Profil',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar info
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? Color(0xFF1e293b)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor:
                    primary.withOpacity(0.1),
                    backgroundImage:
                    widget.user['avatar'] != null &&
                        widget.user['avatar']
                            .isNotEmpty
                        ? NetworkImage(
                        widget.user['avatar'])
                        : null,
                    child: widget.user['avatar'] == null ||
                        widget.user['avatar'].isEmpty
                        ? Text(
                        (widget.user['name'] ?? 'U')[0]
                            .toUpperCase(),
                        style: TextStyle(
                            fontSize: 32,
                            color: primary,
                            fontWeight: FontWeight.bold))
                        : null,
                  ),
                  SizedBox(height: 8),
                  Text(widget.user['email'] ?? '',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Form fields
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Color(0xFF1e293b)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Informasi Pribadi',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),

                  _field('Nama Lengkap', nameCtrl,
                      Icons.person_outline, primary,
                      required: true),
                  SizedBox(height: 14),
                  _field('No. HP', phoneCtrl,
                      Icons.phone_outlined, primary,
                      keyboardType: TextInputType.phone),
                  SizedBox(height: 14),
                  _field('Departemen', deptCtrl,
                      Icons.business_outlined, primary),
                ],
              ),
            ),
            SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isSaving ? null : save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: isSaving
                    ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2))
                    : Text('Simpan Perubahan',
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
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      IconData icon, Color primary,
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
        SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: TextStyle(fontSize: 13),
          decoration: InputDecoration(
            prefixIcon:
            Icon(icon, color: primary, size: 18),
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
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                BorderSide(color: primary, width: 1.5)),
          ),
        ),
      ],
    );
  }
}