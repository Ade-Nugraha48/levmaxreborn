import 'package:geolocator/geolocator.dart';

/// Location Service (Module 7: LBS)
/// Wraps Geolocator for GPS permission checking, position streaming (distanceFilter: 5m),
/// distance calculations, and anti-cheat speed validation (max 24 km/h).
class LocationService {
  LocationService._();

  /// Maximum legitimate running speed threshold in km/h (PRD: <= 24 km/h)
  static const double maxSpeedKmPerHour = 24.0;

  /// Max speed in meters per second (~6.67 m/s)
  static const double maxSpeedMps = maxSpeedKmPerHour / 3.6;

  /// Validates whether device location services are enabled
  static Future<bool> isServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Checks and requests location permission
  /// Returns LocationPermission result
  static Future<LocationPermission> checkAndRequestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  /// Returns whether the permission is granted
  static bool isPermissionGranted(LocationPermission permission) {
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Fetches current position with high accuracy
  static Future<Position?> getCurrentPosition() async {
    final serviceEnabled = await isServiceEnabled();
    if (!serviceEnabled) return null;

    final permission = await checkAndRequestPermission();
    if (!isPermissionGranted(permission)) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Subscribes to position stream with distanceFilter: 5 meters
  static Stream<Position> getPositionStream({int distanceFilter = 5}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Calculates geodesic distance between two coordinates in meters
  static double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Anti-cheat speed check
  /// Rejects waypoint if instantaneous or step speed exceeds 24.0 km/h (e.g. driving/biking)
  static bool isValidSpeed(double speedMps) {
    // If speed is not reported or negative by sensor, allow with step check
    if (speedMps <= 0) return true;
    return speedMps <= maxSpeedMps;
  }

  /// Anti-cheat step interval validation
  static bool isValidStep({
    required double distanceMeters,
    required int elapsedSeconds,
  }) {
    if (elapsedSeconds <= 0) return true;
    final stepSpeedMps = distanceMeters / elapsedSeconds;
    return stepSpeedMps <= maxSpeedMps;
  }
}
