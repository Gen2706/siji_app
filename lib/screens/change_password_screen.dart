import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  @override
  _ChangePasswordScreenState createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {
  final currentCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  bool isSaving = false;
  bool obscureCurrent = true;
  bool obscureNew = true;
  bool obscureConfirm = true;

  @override
  void dispose() {
    currentCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  void save() async {
    if (currentCtrl.text.isEmpty ||
        newCtrl.text.isEmpty ||
        confirmCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Semua field wajib diisi!')),
      );
      return;
    }

    if (newCtrl.text != confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
            Text('Password baru tidak cocok!'),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (newCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Password minimal 6 karakter!'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => isSaving = true);
    try {
      final result = await ApiService.changePassword(
        currentPassword: currentCtrl.text,
        newPassword: newCtrl.text,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
              Text('✅ Password berhasil diubah!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  result['message'] ?? 'Gagal!'),
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
        title: Text('Ganti Password',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Info card
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: primary, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Password minimal 6 karakter. Gunakan kombinasi huruf dan angka.',
                      style: TextStyle(
                          fontSize: 12, color: primary),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Color(0xFF1e293b)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text('Ubah Password',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),

                  _passwordField(
                    'Password Lama',
                    currentCtrl,
                    obscureCurrent,
                        () => setState(() =>
                    obscureCurrent = !obscureCurrent),
                    primary,
                  ),
                  SizedBox(height: 14),
                  _passwordField(
                    'Password Baru',
                    newCtrl,
                    obscureNew,
                        () => setState(
                            () => obscureNew = !obscureNew),
                    primary,
                  ),
                  SizedBox(height: 14),
                  _passwordField(
                    'Konfirmasi Password Baru',
                    confirmCtrl,
                    obscureConfirm,
                        () => setState(() =>
                    obscureConfirm = !obscureConfirm),
                    primary,
                  ),
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
                    : Text('Ubah Password',
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

  Widget _passwordField(
      String label,
      TextEditingController ctrl,
      bool obscure,
      VoidCallback toggleObscure,
      Color primary) {
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
          obscureText: obscure,
          style: TextStyle(fontSize: 13),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock_outline,
                color: primary, size: 18),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.grey,
                size: 18,
              ),
              onPressed: toggleObscure,
            ),
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