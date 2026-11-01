import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../data/mock/mock_cars.dart';

/// Raisons pour lesquelles la position n'a pas pu être obtenue.
enum LocationFailure { serviceDisabled, denied, deniedForever, timeout, unknown }

class LocationException implements Exception {
  const LocationException(this.reason);
  final LocationFailure reason;

  String get message => switch (reason) {
    LocationFailure.serviceDisabled =>
      'La localisation (GPS) est désactivée sur votre appareil.',
    LocationFailure.denied =>
      "Vous avez refusé l'accès à votre position.",
    LocationFailure.deniedForever =>
      "L'accès à la position est bloqué. Autorisez-le dans les paramètres "
          "de l'application.",
    LocationFailure.timeout =>
      "Position introuvable pour l'instant. Réessayez à l'extérieur ou "
          'choisissez votre ville.',
    LocationFailure.unknown => 'Impossible de récupérer votre position.',
  };

  @override
  String toString() => message;
}

/// Résultat de la détection : coordonnées, adresse lisible et agence la
/// plus proche parmi [MockCars.villes].
class DetectedLocation {
  const DetectedLocation({
    required this.latitude,
    required this.longitude,
    required this.nearestCity,
    required this.distanceKm,
    this.address,
  });

  final double latitude;
  final double longitude;
  final String nearestCity;
  final double distanceKm;

  /// `null` si Nominatim n'a pas répondu (hors ligne, quota…).
  final String? address;
}

/// GPS (geolocator) + adresse via Nominatim OpenStreetMap.
class LocationService {
  const LocationService();

  /// Coordonnées (centre-ville) des agences de [MockCars.villes].
  static const Map<String, (double, double)> agencyCoordinates = {
    'Tunis': (36.8065, 10.1815),
    'Ariana': (36.8665, 10.1647),
    'La Marsa': (36.8782, 10.3247),
    'Sousse': (35.8256, 10.6360),
    'Monastir': (35.7643, 10.8113),
    'Sfax': (34.7406, 10.7603),
    'Hammamet': (36.4000, 10.6167),
    'Nabeul': (36.4561, 10.7376),
    'Djerba': (33.8750, 10.8575),
    'Bizerte': (37.2744, 9.8739),
    'Tozeur': (33.9197, 8.1335),
    'Tabarka': (36.9544, 8.7580),
  };

  Future<DetectedLocation> detect() async {
    final position = await _currentPosition();
    final (city, km) = nearestCity(position.latitude, position.longitude);
    final address = await reverseGeocode(
      position.latitude,
      position.longitude,
    );
    return DetectedLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      nearestCity: city,
      distanceKm: km,
      address: address,
    );
  }

  /// Ville d'agence la plus proche et distance en km.
  (String, double) nearestCity(double lat, double lng) {
    var bestCity = MockCars.villes.first;
    var bestMeters = double.infinity;
    for (final city in MockCars.villes) {
      final coords = agencyCoordinates[city];
      if (coords == null) continue;
      final meters = Geolocator.distanceBetween(lat, lng, coords.$1, coords.$2);
      if (meters < bestMeters) {
        bestMeters = meters;
        bestCity = city;
      }
    }
    return (bestCity, bestMeters / 1000);
  }

  /// Adresse courte (rue, quartier, ville) ou `null` en cas d'échec.
  Future<String?> reverseGeocode(double lat, double lng) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': '$lat',
      'lon': '$lng',
      'zoom': '18',
      'accept-language': 'fr',
    });
    try {
      final response = await http
          .get(
            uri,
            // Nominatim exige un User-Agent identifiant l'app
            // (le navigateur interdit de le modifier sur web).
            headers: kIsWeb ? null : {'User-Agent': 'RentCarTn/1.0 (Flutter)'},
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is! Map<String, dynamic>) return null;
      final a = json['address'];
      if (a is Map<String, dynamic>) {
        final street = [a['house_number'], a['road']]
            .whereType<String>()
            .join(' ');
        final parts = <String?>[
          street.isEmpty ? null : street,
          a['suburb'] as String? ?? a['neighbourhood'] as String?,
          a['city'] as String? ?? a['town'] as String? ?? a['village'] as String?,
        ].whereType<String>().where((s) => s.isNotEmpty).toList();
        if (parts.isNotEmpty) return parts.join(', ');
      }
      return json['display_name'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<Position> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(LocationFailure.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(LocationFailure.denied);
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(LocationFailure.deniedForever);
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on TimeoutException {
      final last = kIsWeb ? null : await Geolocator.getLastKnownPosition();
      if (last != null) return last;
      throw const LocationException(LocationFailure.timeout);
    } on LocationServiceDisabledException {
      throw const LocationException(LocationFailure.serviceDisabled);
    } on PermissionDeniedException {
      throw const LocationException(LocationFailure.denied);
    } catch (_) {
      throw const LocationException(LocationFailure.unknown);
    }
  }

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}
