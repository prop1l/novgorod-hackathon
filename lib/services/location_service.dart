import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

enum LocationAccess { unknown, serviceOff, denied, deniedForever, whileInUse, always }

extension LocationAccessX on LocationAccess {
  bool get granted => this == LocationAccess.whileInUse || this == LocationAccess.always;
}

/// Обёртка над geolocator: разрешения и поток координат, который живёт в фоне.
class LocationService {
  StreamSubscription<Position>? _sub;

  Future<LocationAccess> checkAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationAccess.serviceOff;
    return _map(await Geolocator.checkPermission());
  }

  Future<LocationAccess> requestAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationAccess.serviceOff;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    // На iOS «Всегда» запрашивается вторым шагом после «При использовании».
    if (permission == LocationPermission.whileInUse &&
        defaultTargetPlatform == TargetPlatform.iOS) {
      permission = await Geolocator.requestPermission();
    }
    return _map(permission);
  }

  Future<void> openSettings() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  Future<Position?> lastKnown() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  void start(void Function(double lat, double lon) onPosition, {void Function(Object)? onError}) {
    stop();
    _sub = Geolocator.getPositionStream(locationSettings: _settings()).listen(
      (p) => onPosition(p.latitude, p.longitude),
      onError: (Object e) => onError?.call(e),
    );
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  bool get running => _sub != null;

  LocationSettings _settings() {
    const distanceFilter = 25;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilter,
          intervalDuration: const Duration(seconds: 10),
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'Гид активен',
            notificationText: 'Сообщим, когда рядом будет историческое место',
            enableWakeLock: true,
            setOngoing: true,
          ),
        );
      case TargetPlatform.iOS:
        return AppleSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: distanceFilter,
          activityType: ActivityType.fitness,
          pauseLocationUpdatesAutomatically: false,
          allowBackgroundLocationUpdates: true,
          showBackgroundLocationIndicator: true,
        );
      default:
        return const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilter,
        );
    }
  }

  static LocationAccess _map(LocationPermission p) => switch (p) {
        LocationPermission.always => LocationAccess.always,
        LocationPermission.whileInUse => LocationAccess.whileInUse,
        LocationPermission.deniedForever => LocationAccess.deniedForever,
        LocationPermission.denied => LocationAccess.denied,
        LocationPermission.unableToDetermine => LocationAccess.unknown,
      };
}
