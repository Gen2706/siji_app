import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../main.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passController = TextEditingController();
  bool isLoading = false;
  bool obscurePassword = true;
  bool rememberMe = false;

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }

  void doLogin() async {
    if (emailController.text.isEmpty || passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email dan password wajib diisi!')),
      );
      return;
    }
    setState(() => isLoading = true);
    try {
      final result = await ApiService.login(
        emailController.text.trim(),
        passController.text,
      );
      if (result['success'] == true && result['token'] != null) {
        await ApiService.saveToken(result['token']);
        await ApiService.saveUser(result['user']);

        // Init notifikasi setelah login
        try {
          await NotificationService.initialize();
          print('✅ Notification initialized OK');
        } catch (e) {
          print('❌ Notification init error: $e');
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Login gagal!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? Color(0xFF2563eb) : Color(0xFFdc2626);
    final bgTop = isDark ? Color(0xFF1e3a5f) : Color(0xFFb91c1c);
    final bgBottom = isDark ? Color(0xFF0f172a) : Color(0xFF7f1d1d);
    final cardBg = isDark ? Color(0xFF1e293b) : Colors.white;
    final cardTitle = isDark ? Colors.white : Color(0xFF0f172a);
    final cardSub = isDark ? Color(0xFF94a3b8) : Color(0xFF64748b);
    final labelColor = isDark ? Color(0xFFcbd5e1) : Color(0xFF374151);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgTop, bgBottom],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: ClampingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(height: 20),

                  // Toggle Theme
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => MyApp.of(context)?.toggleTheme(),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isDark
                                  ? Icons.wb_sunny_outlined
                                  : Icons.nightlight_round,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 6),
                            Text(
                              isDark ? 'Light Mode' : 'Dark Mode',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 32),

                  // Logo
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text('S',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ),
                  SizedBox(height: 10),

                  Text('SIJI',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 4)),
                  SizedBox(height: 4),
                  Text('Satu Platform, Semua Kendali',
                      style: TextStyle(
                          color: Colors.white60, fontSize: 12)),
                  SizedBox(height: 10),

                  Wrap(
                    spacing: 6,
                    children: ['Terintegrasi', 'Terukur', 'Terkendali']
                        .map((tag) => Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(tag,
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10)),
                    ))
                        .toList(),
                  ),
                  SizedBox(height: 32),

                  // Card Login
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Selamat Datang 👋',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: cardTitle)),
                        SizedBox(height: 2),
                        Text('Masuk ke platform SIJI Anda',
                            style: TextStyle(
                                color: cardSub, fontSize: 12)),
                        SizedBox(height: 20),

                        // Email
                        Text('Email',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: labelColor)),
                        SizedBox(height: 5),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'email@example.com',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            prefixIcon: Icon(Icons.email_outlined,
                                size: 16, color: primary),
                          ),
                        ),
                        SizedBox(height: 14),

                        // Password
                        Text('Password',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: labelColor)),
                        SizedBox(height: 5),
                        TextField(
                          controller: passController,
                          obscureText: obscurePassword,
                          style: TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            prefixIcon: Icon(Icons.lock_outline,
                                size: 16, color: primary),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 16,
                                color: primary,
                              ),
                              onPressed: () => setState(() =>
                              obscurePassword = !obscurePassword),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),

                        // Remember & Forgot
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: rememberMe,
                                    activeColor: primary,
                                    onChanged: (v) => setState(
                                            () => rememberMe = v!),
                                    materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text('Ingat saya',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: cardSub)),
                              ],
                            ),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text('Lupa password?',
                                  style: TextStyle(
                                      fontSize: 11, color: primary)),
                            ),
                          ],
                        ),
                        SizedBox(height: 18),

                        // Tombol Login
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : doLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2))
                                : Text('Masuk ke SIJI',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Footer
                        Center(
                          child: Text(
                              '© 2026 SIJI — Terintegrasi · Terukur · Terkendali',
                              style: TextStyle(
                                  fontSize: 9, color: cardSub),
                              textAlign: TextAlign.center),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}