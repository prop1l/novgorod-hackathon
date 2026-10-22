import 'package:shared_preferences/shared_preferences.dart';

import 'proximity_checker.dart';

/// Посещённые места, время уведомлений и настройки в shared_preferences.
class Storage implements NotificationLog {
  Storage(this._prefs);

  static Future<Storage> open() async => Storage(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  static const _visitedKey = 'visited';
  static const _notifiedPrefix = 'notified_';
  static const _lastAnyKey = 'notified_any';

  bool get onboardingDone => _prefs.getBool('onboarding_done') ?? false;
  set onboardingDone(bool v) => _prefs.setBool('onboarding_done', v);

  bool get guideEnabled => _prefs.getBool('guide_enabled') ?? true;
  set guideEnabled(bool v) => _prefs.setBool('guide_enabled', v);

  double get radiusScale => _prefs.getDouble('radius_scale') ?? 1.0;
  set radiusScale(double v) => _prefs.setDouble('radius_scale', v);

  Set<String> get visited => (_prefs.getStringList(_visitedKey) ?? const []).toSet();

  void markVisited(String placeId) {
    final ids = visited..add(placeId);
    _prefs.setStringList(_visitedKey, ids.toList());
  }

  void resetProgress() {
    _prefs.remove(_visitedKey);
    _prefs.remove(_lastAnyKey);
    for (final key in _prefs.getKeys().where((k) => k.startsWith(_notifiedPrefix)).toList()) {
      _prefs.remove(key);
    }
  }

  @override
  DateTime? lastNotified(String placeId) => _readTime('$_notifiedPrefix$placeId');

  @override
  DateTime? get lastAnyNotified => _readTime(_lastAnyKey);

  @override
  void markNotified(String placeId, DateTime at) {
    _prefs.setInt('$_notifiedPrefix$placeId', at.millisecondsSinceEpoch);
    _prefs.setInt(_lastAnyKey, at.millisecondsSinceEpoch);
    markVisited(placeId);
  }

  DateTime? _readTime(String key) {
    final ms = _prefs.getInt(key);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }
}
