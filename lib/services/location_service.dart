import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Get address from coordinates
  Future<Map<String, String>?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        final address = '${place.locality}, ${place.administrativeArea}, ${place.country}';
        return {
          'address': address,
          'state': (place.administrativeArea ?? '').toString(),
          'district': (place.subAdministrativeArea ?? '').toString(),
          'city': (place.locality ?? '').toString(),
        };
      }
      return null;
    } catch (e) {
      print('Error getting address: $e');
      return null;
    }
  }

  // Get location info as a formatted string
  Future<Map<String, dynamic>?> getLocationInfo() async {
    Position? position = await getCurrentLocation();
    if (position == null) return null;

    final geo = await getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );

    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'address': geo?['address'] ?? 'Unknown location',
      'state': geo?['state'] ?? '',
      'district': geo?['district'] ?? '',
      'city': geo?['city'] ?? '',
    };
  }
}
