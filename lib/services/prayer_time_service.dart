import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class PrayerTime {
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String date;
  final String hijriDate;
  final String? locationName;

  PrayerTime({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.date,
    required this.hijriDate,
    this.locationName,
  });

  factory PrayerTime.fromJson(Map<String, dynamic> json) {
    final timings = json['timings'];
    final date = json['date'];
    final hijri = date['hijri'];
    
    return PrayerTime(
      fajr: _formatTime(timings['Fajr']),
      sunrise: _formatTime(timings['Sunrise']),
      dhuhr: _formatTime(timings['Dhuhr']),
      asr: _formatTime(timings['Asr']),
      maghrib: _formatTime(timings['Maghrib']),
      isha: _formatTime(timings['Isha']),
      date: date['readable'],
      hijriDate: '${hijri['day']} ${hijri['month']['en']} ${hijri['year']}',
    );
  }

  static String _formatTime(String time) {
    // Remove timezone info like "(WIB)"
    return time.replaceAll(RegExp(r'\s*\([^)]*\)'), '');
  }

  /// Get the next prayer and time until it
  Map<String, dynamic> getNextPrayer() {
    final now = DateTime.now();
    final prayers = [
      {'name': 'Fajr', 'time': fajr, 'icon': '🌙'},
      {'name': 'Sunrise', 'time': sunrise, 'icon': '🌅'},
      {'name': 'Dhuhr', 'time': dhuhr, 'icon': '☀️'},
      {'name': 'Asr', 'time': asr, 'icon': '🌤️'},
      {'name': 'Maghrib', 'time': maghrib, 'icon': '🌇'},
      {'name': 'Isha', 'time': isha, 'icon': '🌃'},
    ];

    for (var prayer in prayers) {
      final timeParts = prayer['time']!.split(':');
      final prayerTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      if (prayerTime.isAfter(now)) {
        final diff = prayerTime.difference(now);
        return {
          'name': prayer['name'],
          'time': prayer['time'],
          'icon': prayer['icon'],
          'remaining': _formatDuration(diff),
          'prayerTime': prayerTime,
        };
      }
    }

    // If all prayers passed, next is Fajr tomorrow
    return {
      'name': 'Fajr',
      'time': fajr,
      'icon': '🌙',
      'remaining': 'Tomorrow',
      'prayerTime': null,
    };
  }

  static String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

class PrayerTimeService {
  static final PrayerTimeService _instance = PrayerTimeService._internal();
  factory PrayerTimeService() => _instance;
  PrayerTimeService._internal();

  // Default: Batu, Indonesia
  double _latitude = -7.8672;
  double _longitude = 112.5239;
  String _locationName = 'Batu, Indonesia';
  bool _useGps = false;

  PrayerTime? _cachedPrayerTime;
  DateTime? _cacheDate;

  String get location => _locationName;
  bool get useGps => _useGps;

  /// Request location permission and get current position
  Future<bool> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  /// Enable GPS-based location
  Future<bool> enableGpsLocation() async {
    final hasPermission = await requestLocationPermission();
    if (!hasPermission) return false;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      _latitude = position.latitude;
      _longitude = position.longitude;

      // Get city name from coordinates
      try {
        final placemarks = await placemarkFromCoordinates(_latitude, _longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          _locationName = '${place.locality ?? place.subAdministrativeArea ?? 'Unknown'}, ${place.country ?? ''}';
        }
      } catch (e) {
        _locationName = 'Lat: ${_latitude.toStringAsFixed(2)}, Lng: ${_longitude.toStringAsFixed(2)}';
      }

      _useGps = true;
      _cachedPrayerTime = null; // Clear cache to fetch new times
      _cacheDate = null;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Disable GPS and use default location
  void useDefaultLocation() {
    _latitude = -7.8672;
    _longitude = 112.5239;
    _locationName = 'Batu, Indonesia';
    _useGps = false;
    _cachedPrayerTime = null;
    _cacheDate = null;
  }

  Future<PrayerTime?> getTodayPrayerTimes({bool forceRefresh = false}) async {
    final today = DateTime.now();
    
    // Return cached if same day and not forcing refresh
    if (!forceRefresh && 
        _cachedPrayerTime != null && 
        _cacheDate != null &&
        _cacheDate!.day == today.day &&
        _cacheDate!.month == today.month &&
        _cacheDate!.year == today.year) {
      return _cachedPrayerTime;
    }

    try {
      final dateStr = DateFormat('dd-MM-yyyy').format(today);
      final url = Uri.parse(
        'https://api.aladhan.com/v1/timings/$dateStr'
        '?latitude=$_latitude'
        '&longitude=$_longitude'
        '&method=20' // Method 20 = Kemenag Indonesia
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['code'] == 200) {
          final data = json['data'];
          final timings = data['timings'];
          final date = data['date'];
          final hijri = date['hijri'];
          
          _cachedPrayerTime = PrayerTime(
            fajr: PrayerTime._formatTime(timings['Fajr']),
            sunrise: PrayerTime._formatTime(timings['Sunrise']),
            dhuhr: PrayerTime._formatTime(timings['Dhuhr']),
            asr: PrayerTime._formatTime(timings['Asr']),
            maghrib: PrayerTime._formatTime(timings['Maghrib']),
            isha: PrayerTime._formatTime(timings['Isha']),
            date: date['readable'],
            hijriDate: '${hijri['day']} ${hijri['month']['en']} ${hijri['year']}',
            locationName: _locationName,
          );
          _cacheDate = today;
          return _cachedPrayerTime;
        }
      }
    } catch (e) {
      // Return cached on error if available
      if (_cachedPrayerTime != null) {
        return _cachedPrayerTime;
      }
    }
    return null;
  }
}
