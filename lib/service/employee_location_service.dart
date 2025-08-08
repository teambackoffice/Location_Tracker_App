import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';

class EmployeeLocationService {
  static const _storage = FlutterSecureStorage();

  Future<void> sendLocation({
    required double latitude,
    required double longitude,
    required String date,
    required String time,
    required String entryType, // NEW: Added entry type
  }) async {
    print("🌐 EmployeeLocationService.sendLocation called");
    print("📍 Lat: $latitude, Lng: $longitude");
    print("📅 Date: $date, Time: $time");
    print("🏷️ Entry Type: $entryType");

    try {
      // Get stored values
      String? sid = await _storage.read(key: 'sid');
      String? salesPersonId = await _storage.read(key: 'sales_person_id');

      print("🔐 SID: ${sid != null ? 'Found' : 'Missing'}");
      print("👤 Sales Person ID: ${salesPersonId ?? 'Missing'}");

      if (sid == null || salesPersonId == null) {
        throw Exception('Missing credentials in secure storage');
      }

      var headers = {'Content-Type': 'application/json', 'Cookie': 'sid=$sid'};

      // Create the request body with entry_type
      var body = json.encode({
        "sales_person_id": salesPersonId,
        "date": date,
        "entries": [
          {
            "entry_type": entryType,
            "time": time,
            "latitude": latitude,
            "longitude": longitude,
          },
        ],
      });

      print("📡 Sending to API...");
      print("🔗 URL: ${ApiConstants.baseUrl}save_salesperson_location_log");
      print("📦 Body: $body");

      var request = http.Request(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}save_salesperson_location_log'),
      );

      request.body = body;
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      print("📡 Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        print("✅ SUCCESS: Location sent to API with entry type: $entryType");
        print("📝 Response: $responseBody");
      } else {
        final responseBody = await response.stream.bytesToString();
        print("❌ FAILED: ${response.statusCode} - ${response.reasonPhrase}");
        print("📝 Response: $responseBody");
        throw Exception('Failed to send location: ${response.statusCode}');
      }
    } catch (e) {
      print("💥 ERROR in sendLocation: $e");
      rethrow;
    }
  }

  // Batch send multiple location entries
  Future<void> sendLocationBatch({
    required List<LocationEntry> entries,
    required String date,
  }) async {
    try {
      // Get stored values
      String? sid = await _storage.read(key: 'sid');
      String? salesPersonId = await _storage.read(key: 'sales_person_id');

      if (sid == null || salesPersonId == null) {
        throw Exception('Missing credentials in secure storage');
      }

      var headers = {'Content-Type': 'application/json', 'Cookie': 'sid=$sid'};

      // Convert LocationEntry objects to maps
      List<Map<String, dynamic>> entriesList = entries
          .map(
            (entry) => {
              "entry_type": entry.entryType,
              "time": entry.time,
              "latitude": entry.latitude,
              "longitude": entry.longitude,
            },
          )
          .toList();

      var body = json.encode({
        "sales_person_id": salesPersonId,
        "date": date,
        "entries": entriesList,
      });

      print("Sending batch location data: $body");

      var request = http.Request(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}save_salesperson_location_log'),
      );

      request.body = body;
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        print("Batch location sent successfully: $responseBody");
      } else {
        final responseBody = await response.stream.bytesToString();
        print(
          "Failed to send batch location: ${response.statusCode} - ${response.reasonPhrase}",
        );
        print("Response body: $responseBody");
        throw Exception(
          'Failed to send batch location: ${response.statusCode}',
        );
      }
    } catch (e) {
      print("Error in sendLocationBatch: $e");
      rethrow;
    }
  }
}

// Helper class for location entries
class LocationEntry {
  final String entryType; // NEW: Added entry type
  final String time;
  final double latitude;
  final double longitude;

  LocationEntry({
    required this.entryType,
    required this.time,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'entry_type': entryType,
      'time': time,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory LocationEntry.fromJson(Map<String, dynamic> json) {
    return LocationEntry(
      entryType: json['entry_type'],
      time: json['time'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
    );
  }
}
