import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer; // بديل احترافي لـ print

class LocationService {
  final Dio _dio = Dio();

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('خدمة الموقع معطلة');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('تم رفض الإذن');
      }
    }
    return await Geolocator.getCurrentPosition();
  }

  Future<void> sendLocationToServer(Position position) async {
    try {
      await _dio.post(
        'https://your-api-link.com/update-location',
        data: {
          'lat': position.latitude,
          'lng': position.longitude,
          'driver_id': 'driver_001',
        },
      );
    } catch (e, stackTrace) {
      // استخدام developer.log بدلاً من print
      developer.log(
        'Error sending location',
        error: e,
        stackTrace: stackTrace,
        name: 'LocationService',
      );
    }
  }
}

final locationServiceProvider = Provider((ref) => LocationService());

final driverLocationStreamProvider = StreamProvider<Position>((ref) {
  final service = ref.watch(locationServiceProvider);

  return Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    ),
  ).map((position) {
    service.sendLocationToServer(position);
    return position;
  });
});
