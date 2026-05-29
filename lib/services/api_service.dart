import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://siji.mediajaringan.com/api/v1';

  // ============================================================
  // AUTH & USER
  // ============================================================
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final user = prefs.getString('user');
    return user != null ? jsonDecode(user) : null;
  }

  // Ambil user fresh dari API & update cache
  static Future<Map<String, dynamic>?> getUserFresh() async {
    try {
      final headers = await authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final freshUser = data['user'] ?? data['data'];
        if (freshUser != null) {
          await saveUser(freshUser);
          return freshUser;
        }
      }
      return await getUser();
    } catch (e) {
      print('getUserFresh error: $e');
      return await getUser();
    }
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  static Future<Map<String, String>> authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  static Future<void> logout() async {
    try {
      final headers = await authHeaders();
      await http.post(Uri.parse('$baseUrl/logout'),
          headers: headers);
    } catch (e) {}
    await removeToken();
  }

  static Future<void> updateFcmToken(String fcmToken) async {
    try {
      final token = await getToken();
      if (token == null) {
        print('❌ FCM: No auth token, skip');
        return;
      }
      print('📱 Saving FCM token: ${fcmToken.substring(0, 20)}...');
      final response = await http.post(
        Uri.parse('$baseUrl/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'token': fcmToken}),
      );
      print(
          '📱 FCM save response: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('❌ FCM update error: $e');
    }
  }

  // ============================================================
  // GENERIC CRUD
  // ============================================================
  static Future<List<dynamic>> getList(String endpoint) async {
    final headers = await authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
    );
    final data = jsonDecode(response.body);
    if (data['data'] is List) return data['data'];
    if (data['data'] is Map && data['data']['data'] is List)
      return data['data']['data'];
    return [];
  }

  static Future<Map<String, dynamic>> getDetail(
      String endpoint, int id) async {
    final headers = await authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint/$id'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> create(
      String endpoint, Map<String, dynamic> body) async {
    final headers = await authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> update(
      String endpoint, int id, Map<String, dynamic> body) async {
    final headers = await authHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/$endpoint/$id'),
      headers: headers,
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> delete(
      String endpoint, int id) async {
    final headers = await authHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/$endpoint/$id'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  // ============================================================
  // TICKETS
  // ============================================================
  static Future<List<dynamic>> getTickets() async =>
      getList('tickets');

  static Future<List<dynamic>> searchTickets({
    String? search,
    String? status,
    String? priority,
    String? areaId,
    String? assigneeId,
    String? dateFrom,
    String? dateTo,
  }) async {
    final headers = await authHeaders();
    final params = <String, String>{};

    if (search != null && search.isNotEmpty)
      params['search'] = search;
    if (status != null && status.isNotEmpty)
      params['status'] = status;
    if (priority != null && priority.isNotEmpty)
      params['priority'] = priority;
    if (areaId != null && areaId.isNotEmpty)
      params['area_id'] = areaId;
    if (assigneeId != null && assigneeId.isNotEmpty)
      params['assignee_id'] = assigneeId;
    if (dateFrom != null && dateFrom.isNotEmpty)
      params['date_from'] = dateFrom;
    if (dateTo != null && dateTo.isNotEmpty)
      params['date_to'] = dateTo;

    final uri = Uri.parse('$baseUrl/tickets').replace(
        queryParameters: params.isEmpty ? null : params);
    final response = await http.get(uri, headers: headers);
    final data = jsonDecode(response.body);
    if (data['data'] is List) return data['data'];
    return [];
  }

  static Future<Map<String, dynamic>> createTicket(
      Map<String, dynamic> body) async =>
      create('tickets', body);

  static Future<Map<String, dynamic>> updateTicketStatus(
      int id, String status) async {
    final headers = await authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/tickets/$id/status'),
      headers: headers,
      body: jsonEncode({'status': status}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> addComment(
      int ticketId, String content, {File? photo}) async {
    final token = await getToken();
    final uri =
    Uri.parse('$baseUrl/tickets/$ticketId/comment');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    if (content.isNotEmpty)
      request.fields['content'] = content;
    if (photo != null) {
      request.files.add(await http.MultipartFile.fromPath(
          'photo', photo.path));
    }

    final streamedResponse = await request.send();
    final response =
    await http.Response.fromStream(streamedResponse);
    return jsonDecode(response.body);
  }

  // ============================================================
  // CUSTOMER HISTORY
  // ============================================================
  static Future<List<dynamic>> getCustomerHistory({
    String? customerPhone,
    String? customerName,
  }) async {
    final headers = await authHeaders();
    final params = <String, String>{};

    if (customerPhone != null && customerPhone.isNotEmpty)
      params['customer_phone'] = customerPhone;
    if (customerName != null && customerName.isNotEmpty)
      params['customer_name'] = customerName;

    final uri = Uri.parse('$baseUrl/tickets/customer-history')
        .replace(
        queryParameters:
        params.isEmpty ? null : params);
    final response = await http.get(uri, headers: headers);
    final data = jsonDecode(response.body);
    if (data['data'] is List) return data['data'];
    return [];
  }

  // ============================================================
  // LEADERBOARD
  // ============================================================
  static Future<List<dynamic>> getLeaderboard() async =>
      getList('leaderboard');

  // ============================================================
  // MASTER DATA
  // ============================================================
  static Future<List<dynamic>> getCategories() async =>
      getList('master/categories');

  static Future<List<dynamic>> getAreas() async =>
      getList('master/areas');

  static Future<List<dynamic>> getTeknisi() async =>
      getList('master/teknisi');

  // ============================================================
  // WAREHOUSE
  // ============================================================
  static Future<Map<String, dynamic>>
  getWarehouseDashboard() async {
    final headers = await authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/warehouse/dashboard'),
      headers: headers,
    );
    final data = jsonDecode(response.body);
    return data['data'] ?? {};
  }

  static Future<List<dynamic>> getWarehouseItems({
    String? search,
    String? categoryId,
    bool? lowStock,
  }) async {
    final headers = await authHeaders();
    final params = <String, String>{};
    if (search != null && search.isNotEmpty)
      params['search'] = search;
    if (categoryId != null)
      params['category_id'] = categoryId;
    if (lowStock == true) params['low_stock'] = '1';

    final uri = Uri.parse('$baseUrl/warehouse/items').replace(
        queryParameters:
        params.isEmpty ? null : params);
    final response = await http.get(uri, headers: headers);
    final data = jsonDecode(response.body);
    if (data['data'] is List) return data['data'];
    return [];
  }

  static Future<Map<String, dynamic>>
  getWarehouseItemDetail(int id) async {
    final headers = await authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/warehouse/items/$id'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> storeWarehouseItem(
      Map<String, dynamic> body) async =>
      create('warehouse/items', body);

  static Future<Map<String, dynamic>> updateWarehouseItem(
      int id, Map<String, dynamic> body) async =>
      update('warehouse/items', id, body);

  static Future<Map<String, dynamic>> addStock(int itemId,
      int quantity,
      {String? notes, String? serialNumber}) async {
    final headers = await authHeaders();
    final response = await http.post(
      Uri.parse(
          '$baseUrl/warehouse/items/$itemId/add-stock'),
      headers: headers,
      body: jsonEncode({
        'quantity': quantity,
        if (notes != null) 'notes': notes,
        if (serialNumber != null)
          'serial_number': serialNumber,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> reduceStock(
      int itemId, int quantity,
      {String? notes}) async {
    final headers = await authHeaders();
    final response = await http.post(
      Uri.parse(
          '$baseUrl/warehouse/items/$itemId/reduce-stock'),
      headers: headers,
      body: jsonEncode({
        'quantity': quantity,
        if (notes != null) 'notes': notes,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getWarehouseCategories() async =>
      getList('warehouse/categories');

  static Future<List<dynamic>> getWarehouseTypes() async =>
      getList('warehouse/types');

  static Future<Map<String, dynamic>>
  storeWarehouseCategory(
      Map<String, dynamic> body) async =>
      create('warehouse/categories', body);

  static Future<Map<String, dynamic>> storeWarehouseType(
      Map<String, dynamic> body) async =>
      create('warehouse/types', body);

  static Future<List<dynamic>> getItemRequests(
      {String? status}) async {
    final headers = await authHeaders();
    final params = <String, String>{};
    if (status != null && status.isNotEmpty)
      params['status'] = status;
    final uri = Uri.parse('$baseUrl/warehouse/requests')
        .replace(
        queryParameters:
        params.isEmpty ? null : params);
    final response = await http.get(uri, headers: headers);
    final data = jsonDecode(response.body);
    if (data['data'] is List) return data['data'];
    return [];
  }

  static Future<Map<String, dynamic>> createItemRequest(
      List<Map<String, dynamic>> items,
      {String? notes}) async {
    final headers = await authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/warehouse/requests'),
      headers: headers,
      body: jsonEncode({
        'items': items,
        if (notes != null) 'notes': notes,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> approveItemRequest(
      int id) async {
    final headers = await authHeaders();
    final response = await http.post(
      Uri.parse(
          '$baseUrl/warehouse/requests/$id/approve'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> rejectItemRequest(
      int id) async {
    final headers = await authHeaders();
    final response = await http.post(
      Uri.parse(
          '$baseUrl/warehouse/requests/$id/reject'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> cancelItemRequest(
      int id) async {
    final headers = await authHeaders();
    final response = await http.post(
      Uri.parse(
          '$baseUrl/warehouse/requests/$id/cancel'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getStockMovements(
      {int? itemId}) async {
    final headers = await authHeaders();
    final params = <String, String>{};
    if (itemId != null)
      params['item_id'] = itemId.toString();
    final uri = Uri.parse('$baseUrl/warehouse/movements')
        .replace(
        queryParameters:
        params.isEmpty ? null : params);
    final response = await http.get(uri, headers: headers);
    final data = jsonDecode(response.body);
    if (data['data'] is List) return data['data'];
    return [];
  }
  static Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> body) async {
    final headers = await authHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/user/update'),
      headers: headers,
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body);
    // Update cached user kalau berhasil
    if (data['success'] == true && data['user'] != null) {
      await saveUser(data['user']);
    }
    return data;
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final headers = await authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/user/password'),
      headers: headers,
      body: jsonEncode({
        'current_password':      currentPassword,
        'new_password':          newPassword,
        'new_password_confirmation': newPassword,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'ticket_created':  prefs.getBool('notif_ticket_created') ?? true,
      'ticket_updated':  prefs.getBool('notif_ticket_updated') ?? true,
      'ticket_comment':  prefs.getBool('notif_ticket_comment') ?? true,
      'ticket_closed':   prefs.getBool('notif_ticket_closed') ?? true,
    };
  }

  static Future<void> saveNotificationSettings(
      Map<String, bool> settings) async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in settings.entries) {
      await prefs.setBool('notif_${entry.key}', entry.value);
    }
  }
}