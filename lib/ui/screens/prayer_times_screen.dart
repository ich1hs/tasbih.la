import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/prayer_time_service.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  PrayerTime? _prayerTime;
  bool _loading = true;
  bool _gpsEnabled = false;
  bool _gpsLoading = false;

  @override
  void initState() {
    super.initState();
    _gpsEnabled = PrayerTimeService().useGps;
    _loadPrayerTimes();
  }

  Future<void> _loadPrayerTimes() async {
    setState(() => _loading = true);
    final prayer = await PrayerTimeService().getTodayPrayerTimes(forceRefresh: true);
    if (mounted) {
      setState(() {
        _prayerTime = prayer;
        _loading = false;
      });
    }
  }

  Future<void> _toggleGps(bool value) async {
    setState(() => _gpsLoading = true);
    
    if (value) {
      final success = await PrayerTimeService().enableGpsLocation();
      if (success) {
        _gpsEnabled = true;
        await _loadPrayerTimes();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not get location. Check GPS permissions.')),
          );
        }
      }
    } else {
      PrayerTimeService().useDefaultLocation();
      _gpsEnabled = false;
      await _loadPrayerTimes();
    }
    
    if (mounted) setState(() => _gpsLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF8FAE8B) : const Color(0xFF5C8374);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subTextColor = isDark ? Colors.white60 : Colors.black54;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Prayer Times', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadPrayerTimes,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _prayerTime == null
              ? _buildError(primaryColor, textColor)
              : _buildContent(primaryColor, textColor, subTextColor, cardColor),
    );
  }

  Widget _buildError(Color primaryColor, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 64, color: textColor.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'Could not load prayer times',
            style: GoogleFonts.spaceGrotesk(fontSize: 16, color: textColor.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadPrayerTimes,
            icon: const Icon(Icons.refresh_rounded),
            label: Text('Retry', style: GoogleFonts.spaceGrotesk()),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Color primaryColor, Color textColor, Color subTextColor, Color cardColor) {
    final next = _prayerTime!.getNextPrayer();
    final prayers = [
      {'name': 'Fajr', 'time': _prayerTime!.fajr, 'icon': '🌙'},
      {'name': 'Sunrise', 'time': _prayerTime!.sunrise, 'icon': '🌅'},
      {'name': 'Dhuhr', 'time': _prayerTime!.dhuhr, 'icon': '☀️'},
      {'name': 'Asr', 'time': _prayerTime!.asr, 'icon': '🌤️'},
      {'name': 'Maghrib', 'time': _prayerTime!.maghrib, 'icon': '🌇'},
      {'name': 'Isha', 'time': _prayerTime!.isha, 'icon': '🌃'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Location & Date Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_gpsEnabled ? Icons.gps_fixed : Icons.location_on_rounded, size: 16, color: primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      PrayerTimeService().location,
                      style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                    ),
                    if (_gpsLoading)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: SizedBox(
                          width: 12, height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _prayerTime!.date,
                  style: GoogleFonts.spaceGrotesk(fontSize: 12, color: subTextColor),
                ),
                Text(
                  _prayerTime!.hijriDate,
                  style: GoogleFonts.spaceGrotesk(fontSize: 12, color: primaryColor),
                ),
                const SizedBox(height: 12),
                // GPS Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Use my location',
                      style: GoogleFonts.spaceGrotesk(fontSize: 12, color: subTextColor),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _gpsEnabled,
                      onChanged: _gpsLoading ? null : _toggleGps,
                      activeTrackColor: primaryColor.withValues(alpha: 0.5),
                      activeThumbColor: primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Next Prayer Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  'Next Prayer',
                  style: GoogleFonts.spaceGrotesk(fontSize: 12, color: Colors.white70, letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                Text(
                  next['icon'],
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(height: 8),
                Text(
                  next['name'],
                  style: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  next['time'],
                  style: GoogleFonts.spaceGrotesk(fontSize: 48, fontWeight: FontWeight.w300, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    next['remaining'],
                    style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // All Prayer Times
          Text(
            'TODAY\'S SCHEDULE',
            style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w600, color: primaryColor, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),

          ...prayers.map((prayer) {
            final isNext = prayer['name'] == next['name'];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isNext ? primaryColor.withValues(alpha: 0.1) : cardColor,
                borderRadius: BorderRadius.circular(12),
                border: isNext ? Border.all(color: primaryColor, width: 1.5) : null,
              ),
              child: Row(
                children: [
                  Text(prayer['icon']!, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      prayer['name']!,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: isNext ? FontWeight.w600 : FontWeight.w500,
                        color: isNext ? primaryColor : textColor,
                      ),
                    ),
                  ),
                  Text(
                    prayer['time']!,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isNext ? primaryColor : textColor,
                    ),
                  ),
                  if (isNext) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: primaryColor),
                  ],
                ],
              ),
            );
          }),

          const SizedBox(height: 16),

          // Footer
          Text(
            'Times calculated using Kemenag Indonesia method',
            style: GoogleFonts.spaceGrotesk(fontSize: 10, color: subTextColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
