import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class LocationResult {
  final bool success;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String placeName;
  final String address;
  final String? errorCode;
  final String? errorMessage;

  const LocationResult({
    required this.success,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.placeName = '',
    this.address = '',
    this.errorCode,
    this.errorMessage,
  });
}

class PlaceSuggestion {
  final String displayName;
  final String shortName;
  final double latitude;
  final double longitude;

  const PlaceSuggestion({
    required this.displayName,
    required this.shortName,
    required this.latitude,
    required this.longitude,
  });
}

class LocationService {
  static const MethodChannel _channel =
      MethodChannel('com.example.kita_story/location');

  /// Checks whether device GPS is enabled and location permission is granted
  static Future<({bool gpsEnabled, bool permissionGranted})>
      checkStatus() async {
    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'checkStatus',
      );
      if (res != null) {
        return (
          gpsEnabled: (res['gpsEnabled'] as bool?) ?? false,
          permissionGranted: (res['permissionGranted'] as bool?) ?? false,
        );
      }
    } catch (e) {
      debugPrint('LocationService.checkStatus warning: $e');
    }
    return (gpsEnabled: false, permissionGranted: false);
  }

  /// Opens the device's Location / GPS Settings screen
  static Future<bool> openLocationSettings() async {
    try {
      final opened =
          await _channel.invokeMethod<bool>('openLocationSettings') ?? false;
      return opened;
    } catch (e) {
      debugPrint('LocationService.openLocationSettings warning: $e');
      return false;
    }
  }

  /// Opens Google Maps / Geo URI for the given coordinates
  static Future<bool> openMaps({
    required double latitude,
    required double longitude,
    required String label,
  }) async {
    try {
      final opened = await _channel.invokeMethod<bool>('openMaps', {
            'latitude': latitude,
            'longitude': longitude,
            'label': label,
          }) ??
          false;
      return opened;
    } catch (e) {
      debugPrint('LocationService.openMaps warning: $e');
      return false;
    }
  }

  /// Requests permission (if needed) and fetches the current GPS coordinates + address
  static Future<LocationResult> getCurrentLocation() async {
    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getCurrentLocation',
      );
      if (res == null) {
        return const LocationResult(
          success: false,
          errorCode: 'NULL_RESPONSE',
          errorMessage: 'Tidak dapat memperoleh respons dari layanan GPS.',
        );
      }

      final success = (res['success'] as bool?) ?? false;
      if (!success) {
        return LocationResult(
          success: false,
          errorCode: res['errorCode'] as String?,
          errorMessage:
              (res['message'] as String?) ?? 'Gagal mengambil lokasi GPS.',
        );
      }

      final lat = (res['latitude'] as num?)?.toDouble();
      final lng = (res['longitude'] as num?)?.toDouble();
      final acc = (res['accuracy'] as num?)?.toDouble();
      var placeName = (res['placeName'] as String?)?.trim() ?? '';
      var address = (res['address'] as String?)?.trim() ?? '';

      // If Android Geocoder returned empty address, enrich via Nominatim OSM
      if (lat != null && lng != null && address.isEmpty) {
        final osm = await reverseGeocodeNominatim(lat, lng);
        if (osm != null) {
          if (placeName.isEmpty || placeName == 'Lokasi Saat Ini') {
            placeName = osm.shortName;
          }
          address = osm.displayName;
        }
      }

      if (placeName.isEmpty) {
        placeName = 'Lokasi Saat Ini';
      }

      return LocationResult(
        success: true,
        latitude: lat,
        longitude: lng,
        accuracy: acc,
        placeName: placeName,
        address: address,
      );
    } on MissingPluginException {
      return const LocationResult(
        success: false,
        errorCode: 'REBUILD_REQUIRED',
        errorMessage:
            'Layanan GPS baru ditambahkan. Lakukan Restart Penuh (Stop & Run) aplikasi atau gunakan Mode Lokasi Manual.',
      );
    } catch (e) {
      return LocationResult(
        success: false,
        errorCode: 'EXCEPTION',
        errorMessage: 'Gagal mengakses GPS: $e',
      );
    }
  }

  /// Pure Dart reverse geocoding fallback via OpenStreetMap Nominatim
  static Future<PlaceSuggestion?> reverseGeocodeNominatim(
    double latitude,
    double longitude,
  ) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 5);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1&accept-language=id',
      );
      final req = await client.getUrl(uri);
      req.headers.set('User-Agent', 'DayTaleCoupleApp/1.0 (Flutter)');
      final resp = await req.close();
      if (resp.statusCode == 200) {
        final body = await resp.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        final displayName = (data['display_name'] as String?) ?? '';
        final addr = data['address'] as Map<String, dynamic>?;
        String shortName = (data['name'] as String?)?.trim() ?? '';
        if (shortName.isEmpty && addr != null) {
          shortName = (addr['amenity'] ??
                  addr['building'] ??
                  addr['shop'] ??
                  addr['road'] ??
                  addr['neighbourhood'] ??
                  addr['suburb'] ??
                  addr['village'] ??
                  addr['city'] ??
                  'Lokasi GPS')
              .toString();
        }
        return PlaceSuggestion(
          displayName: displayName,
          shortName: shortName.isNotEmpty ? shortName : 'Lokasi GPS',
          latitude: latitude,
          longitude: longitude,
        );
      }
    } catch (e) {
      debugPrint('Nominatim reverse geocode warning: $e');
    } finally {
      client.close();
    }
    return null;
  }

  /// Pure Dart place search via OpenStreetMap Nominatim for Manual / Backdate Location Picker
  static Future<List<PlaceSuggestion>> searchPlaces(String query) async {
    final clean = query.trim();
    if (clean.length < 2) return [];

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 6);
    try {
      final encoded = Uri.encodeQueryComponent(clean);
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=$encoded&limit=5&addressdetails=1&accept-language=id',
      );
      final req = await client.getUrl(uri);
      req.headers.set('User-Agent', 'DayTaleCoupleApp/1.0 (Flutter)');
      final resp = await req.close();
      if (resp.statusCode == 200) {
        final body = await resp.transform(utf8.decoder).join();
        final list = jsonDecode(body) as List<dynamic>;
        return list
            .map((raw) {
              final map = raw as Map<String, dynamic>;
              final displayName = (map['display_name'] as String?) ?? '';
              final name = (map['name'] as String?)?.trim() ?? '';
              final shortName = name.isNotEmpty
                  ? name
                  : displayName.split(',').first.trim();
              final lat = double.tryParse(map['lat']?.toString() ?? '') ?? 0.0;
              final lon = double.tryParse(map['lon']?.toString() ?? '') ?? 0.0;
              return PlaceSuggestion(
                displayName: displayName,
                shortName: shortName,
                latitude: lat,
                longitude: lon,
              );
            })
            .where((p) => p.latitude != 0.0 || p.longitude != 0.0)
            .toList();
      }
    } catch (e) {
      debugPrint('Nominatim search warning: $e');
    } finally {
      client.close();
    }
    return [];
  }
}
