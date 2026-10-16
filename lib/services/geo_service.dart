import 'dart:convert';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteResult {
  final List<LatLng> points;
  final int etaMinutes;
  final double distanceKm;
  final bool isFromRoadApi;

  RouteResult({
    required this.points,
    required this.etaMinutes,
    required this.distanceKm,
    required this.isFromRoadApi,
  });
}

class GeoService {
  /// Calculate straight-line distance in kilometers between two GPS coordinates using Haversine formula
  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }

  /// Calculates estimated emergency transit time in minutes given distance in KM
  static int calculateEtaMinutes(double distanceKm, {double avgSpeedKmH = 32.0}) {
    if (distanceKm <= 0.05) return 1;
    final hours = distanceKm / avgSpeedKmH;
    final minutes = (hours * 60).round();
    return max(2, minutes);
  }

  /// Fetches real road routing polyline from open-source OSRM routing API.
  /// Falls back gracefully to high-resolution interpolated waypoints if offline.
  static Future<RouteResult> getRoadRoute(LatLng start, LatLng destination) async {
    final straightDist = calculateDistanceKm(
      start.latitude,
      start.longitude,
      destination.latitude,
      destination.longitude,
    );

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final firstRoute = routes[0] as Map<String, dynamic>;
          final geometry = firstRoute['geometry'] as Map<String, dynamic>;
          final coords = geometry['coordinates'] as List<dynamic>;

          final points = coords.map<LatLng>((c) {
            final list = c as List<dynamic>;
            return LatLng((list[1] as num).toDouble(), (list[0] as num).toDouble());
          }).toList();

          final durationSec = (firstRoute['duration'] as num?)?.toDouble() ?? (straightDist / 30 * 3600);
          final distanceMeters = (firstRoute['distance'] as num?)?.toDouble() ?? (straightDist * 1000);

          return RouteResult(
            points: points,
            etaMinutes: max(2, (durationSec / 60).round()),
            distanceKm: distanceMeters / 1000.0,
            isFromRoadApi: true,
          );
        }
      }
    } catch (_) {
      // Network timeout / offline fallback
    }

    // High-resolution realistic curved urban route fallback
    final fallbackPoints = _generateCurvedWaypoints(start, destination);
    return RouteResult(
      points: fallbackPoints,
      etaMinutes: calculateEtaMinutes(straightDist),
      distanceKm: straightDist,
      isFromRoadApi: false,
    );
  }

  /// Generates 14 realistic waypoints with natural urban road curvature between two points
  static List<LatLng> _generateCurvedWaypoints(LatLng start, LatLng end) {
    final points = <LatLng>[start];
    const steps = 14;

    final dx = end.longitude - start.longitude;
    final dy = end.latitude - start.latitude;

    // Perpendicular vector for realistic road detours
    final perpX = -dy;
    final perpY = dx;

    for (int i = 1; i < steps; i++) {
      final t = i / steps.toDouble();
      // Smooth sinusoidal curve for natural road routing
      final curveFactor = sin(t * pi) * 0.18;

      final lat = start.latitude + (dy * t) + (perpY * curveFactor);
      final lng = start.longitude + (dx * t) + (perpX * curveFactor);
      points.add(LatLng(lat, lng));
    }

    points.add(end);
    return points;
  }

  /// Request GPS permission and fetch current user position
  static Future<LatLng> getCurrentLocationOrDefault() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Fallback default: New Delhi / NCR coordinates for demonstration
        return const LatLng(28.6139, 77.2090);
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LatLng(28.6139, 77.2090);
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LatLng(28.6139, 77.2090);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      // Graceful fallback to default campus/city location
      return const LatLng(28.6139, 77.2090);
    }
  }
}
