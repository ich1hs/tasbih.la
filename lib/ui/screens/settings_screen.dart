import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/prayer_time_service.dart';
import '../../services/backup_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PrayerTime? _prayerTime;
  bool _loadingPrayer = true;

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
  }

  Future<void> _loadPrayerTimes() async {
    final prayer = await PrayerTimeService().getTodayPrayerTimes();
    if (mounted) {
      setState(() {
        _prayerTime = prayer;
        _loadingPrayer = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subTextColor = isDark ? Colors.white60 : Colors.black54;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Prayer Times Section
          _buildSectionTitle('Prayer Times', primaryColor),
          const SizedBox(height: 8),
          _buildPrayerTimesCard(cardColor, textColor, subTextColor, primaryColor),

          const SizedBox(height: 24),

          // Theme Section
          _buildSectionTitle('Appearance', primaryColor),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: _buildIcon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, primaryColor),
              title: Text('Theme', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500, color: textColor)),
              subtitle: Text(
                settings.themeMode == ThemeMode.system ? 'System' : settings.themeMode == ThemeMode.light ? 'Light' : 'Dark',
                style: GoogleFonts.spaceGrotesk(color: subTextColor, fontSize: 12),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButton<ThemeMode>(
                  value: settings.themeMode,
                  onChanged: (v) => v != null ? settings.setThemeMode(v) : null,
                  underline: const SizedBox(),
                  isDense: true,
                  style: GoogleFonts.spaceGrotesk(color: primaryColor, fontSize: 13, fontWeight: FontWeight.w500),
                  dropdownColor: cardColor,
                  items: [
                    DropdownMenuItem(value: ThemeMode.system, child: Text('System', style: GoogleFonts.spaceGrotesk())),
                    DropdownMenuItem(value: ThemeMode.light, child: Text('Light', style: GoogleFonts.spaceGrotesk())),
                    DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark', style: GoogleFonts.spaceGrotesk())),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Feedback Section
          _buildSectionTitle('Feedback', primaryColor),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildSwitchTile(
                  icon: settings.soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  title: 'Sound',
                  subtitle: 'Play sound on tap',
                  value: settings.soundEnabled,
                  onChanged: settings.setSoundEnabled,
                  primaryColor: primaryColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
                Divider(height: 1, indent: 70, color: textColor.withValues(alpha: 0.06)),
                _buildSwitchTile(
                  icon: settings.vibrationEnabled ? Icons.vibration_rounded : Icons.smartphone_rounded,
                  title: 'Vibration',
                  subtitle: 'Haptic feedback on tap',
                  value: settings.vibrationEnabled,
                  onChanged: settings.setVibrationEnabled,
                  primaryColor: primaryColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Backup Section
          _buildSectionTitle('Data', primaryColor),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: _buildIcon(Icons.upload_rounded, primaryColor),
                  title: Text('Export Backup', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500, color: textColor)),
                  subtitle: Text('Save data to file', style: GoogleFonts.spaceGrotesk(color: subTextColor, fontSize: 12)),
                  trailing: Icon(Icons.chevron_right_rounded, color: subTextColor),
                  onTap: () async {
                    final success = await BackupService().exportBackup();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Backup exported!' : 'Export failed'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                Divider(height: 1, indent: 70, color: textColor.withValues(alpha: 0.06)),
                ListTile(
                  leading: _buildIcon(Icons.download_rounded, primaryColor),
                  title: Text('Import Backup', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500, color: textColor)),
                  subtitle: Text('Restore from file', style: GoogleFonts.spaceGrotesk(color: subTextColor, fontSize: 12)),
                  trailing: Icon(Icons.chevron_right_rounded, color: subTextColor),
                  onTap: () async {
                    final result = await BackupService().importBackup();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result.message),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: result.success ? primaryColor : Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // About Section
          _buildSectionTitle('About', primaryColor),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: _buildIcon(Icons.info_outline_rounded, primaryColor),
                  title: Text('Version', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500, color: textColor)),
                  trailing: Text('3.7.7', style: GoogleFonts.spaceGrotesk(color: subTextColor, fontSize: 13)),
                ),
                Divider(height: 1, indent: 70, color: textColor.withValues(alpha: 0.06)),
                ListTile(
                  leading: _buildIcon(Icons.favorite_outline_rounded, primaryColor),
                  title: Text('Made with', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500, color: textColor)),
                  trailing: Text('Flutter ❤️', style: GoogleFonts.spaceGrotesk(color: subTextColor, fontSize: 13)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Center(
            child: Text('tasbih.la', style: GoogleFonts.spaceGrotesk(color: subTextColor, fontSize: 12, letterSpacing: 1)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPrayerTimesCard(Color cardColor, Color textColor, Color subTextColor, Color primaryColor) {
    if (_loadingPrayer) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
        ),
      );
    }

    if (_prayerTime == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_off_rounded, size: 32, color: subTextColor),
            const SizedBox(height: 8),
            Text('Could not load prayer times', style: GoogleFonts.spaceGrotesk(color: subTextColor, fontSize: 13)),
            TextButton(
              onPressed: () {
                setState(() => _loadingPrayer = true);
                _loadPrayerTimes();
              },
              child: Text('Retry', style: GoogleFonts.spaceGrotesk(color: primaryColor)),
            ),
          ],
        ),
      );
    }

    final nextPrayer = _prayerTime!.getNextPrayer();

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Next prayer highlight
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Text(nextPrayer['icon'], style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Next: ${nextPrayer['name']}', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, color: textColor, fontSize: 15)),
                      Text('${nextPrayer['time']} (${nextPrayer['remaining']})', style: GoogleFonts.spaceGrotesk(color: primaryColor, fontSize: 13)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(PrayerTimeService().location, style: GoogleFonts.spaceGrotesk(color: subTextColor, fontSize: 11)),
                    Text(_prayerTime!.hijriDate, style: GoogleFonts.spaceGrotesk(color: subTextColor, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          // All prayer times
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPrayerItem('Fajr', _prayerTime!.fajr, textColor, subTextColor),
                _buildPrayerItem('Dhuhr', _prayerTime!.dhuhr, textColor, subTextColor),
                _buildPrayerItem('Asr', _prayerTime!.asr, textColor, subTextColor),
                _buildPrayerItem('Maghrib', _prayerTime!.maghrib, textColor, subTextColor),
                _buildPrayerItem('Isha', _prayerTime!.isha, textColor, subTextColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerItem(String name, String time, Color textColor, Color subTextColor) {
    return Column(
      children: [
        Text(name, style: GoogleFonts.spaceGrotesk(fontSize: 10, color: subTextColor)),
        const SizedBox(height: 2),
        Text(time, style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
      ],
    );
  }

  Widget _buildIcon(IconData icon, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: primaryColor, size: 20),
    );
  }

  Widget _buildSectionTitle(String title, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w600, color: primaryColor, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required Color primaryColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return ListTile(
      leading: _buildIcon(icon, primaryColor),
      title: Text(title, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500, color: textColor)),
      subtitle: Text(subtitle, style: GoogleFonts.spaceGrotesk(color: subTextColor, fontSize: 12)),
      trailing: Switch.adaptive(value: value, onChanged: onChanged, activeTrackColor: primaryColor.withValues(alpha: 0.5), activeThumbColor: primaryColor),
    );
  }
}
