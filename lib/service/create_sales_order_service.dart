import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';

class CreateSalesOrderService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String url = '${ApiConstants.baseUrl}create_sales_order';

  Future<Map<String, dynamic>> createSalesOrder({
    required String customer,
    required String deliveryDate,
    required List<Map<String, dynamic>> items,
  }) async {
    final sid = await _secureStorage.read(key: 'sid'); // Get session id

    if (sid == null) {
      throw Exception('Session ID not found. Please log in again.');
    }

    var headers = {'Content-Type': 'application/json', 'Cookie': 'sid=$sid'};

    var body = json.encode({
      "customer": customer,
      "delivery_date": deliveryDate,
      "items": items,
    });

    // 🔹 Debugging logs

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create sales order: ${response.body}');
    }
  }
}
