import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import '../../providers/counter_provider.dart';
import '../../services/storage_service.dart';
import '../../services/prayer_time_service.dart';
import '../widgets/quick_zikr_switcher.dart';
import '../widgets/tasbih_beads.dart';
import 'presets_screen.dart';
import 'settings_screen.dart';
import 'chains_screen.dart';
import 'prayer_times_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  PrayerTime? _prayerTime;

  @override
  void initState() {
    super.initState();
    _loadPrayerTime();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  Future<void> _loadPrayerTime() async {
    final prayer = await PrayerTimeService().getTodayPrayerTimes();
    if (mounted) {
      setState(() => _prayerTime = prayer);
      // Update prayer widget
      if (prayer != null) {
        _updatePrayerWidget(prayer);
      }
    }
    // Also update tasbih widget
    _updateTasbihWidget();
  }

  Future<void> _updateTasbihWidget() async {
    try {
      final total = StorageService.settingsRepository.globalTotal;
      await HomeWidget.saveWidgetData('globalTotal', total.toString());
      await HomeWidget.updateWidget(androidName: 'TasbihWidgetProvider');
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _updatePrayerWidget(PrayerTime prayer) async {
    try {
      final next = prayer.getNextPrayer();
      // Next prayer info
      await HomeWidget.saveWidgetData('nextPrayerName', next['name']);
      await HomeWidget.saveWidgetData('nextPrayerTime', next['time']);
      await HomeWidget.saveWidgetData('nextPrayerRemaining', next['remaining']);
      await HomeWidget.saveWidgetData('nextPrayerIcon', next['icon']);
      // All prayer times
      await HomeWidget.saveWidgetData('fajr', prayer.fajr);
      await HomeWidget.saveWidgetData('sunrise', prayer.sunrise);
      await HomeWidget.saveWidgetData('dhuhr', prayer.dhuhr);
      await HomeWidget.saveWidgetData('asr', prayer.asr);
      await HomeWidget.saveWidgetData('maghrib', prayer.maghrib);
      await HomeWidget.saveWidgetData('isha', prayer.isha);
      await HomeWidget.updateWidget(androidName: 'PrayerWidgetProvider');
    } catch (e) {
      // Ignore
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap() {
    final counter = context.read<CounterProvider>();
    counter.increment();
    _pulseController.forward().then((_) => _pulseController.reverse());
    setState(() {}); // Refresh stats
    _updateTasbihWidget(); // Update widget count
  }

  @override
  Widget build(BuildContext context) {
    final counter = context.watch<CounterProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Elegant sage green color scheme
    final primaryColor = isDark ? const Color(0xFF8FAE8B) : const Color(0xFF5C8374);
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subTextColor = isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context, isDark, textColor, primaryColor),
              
              Expanded(
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    
                    // Next prayer time
                    if (_prayerTime != null)
                      _buildNextPrayer(primaryColor, textColor, subTextColor),
                    
                    // Arabic text
                    if (counter.ayahText != null)
                      _buildArabicText(counter.ayahText!, textColor),
                    
                    // Chain badge
                    if (counter.mode == ActiveMode.chain)
                      _buildChainBadge(counter, primaryColor, textColor),
                    
                    // Zikr selector
                    _buildZikrSelector(counter, primaryColor, textColor),
                    
                    const SizedBox(height: 32),
                    
                    // Main counter - tap only in circle area
                    GestureDetector(
                      onTap: _handleTap,
                      child: ScaleTransition(
                        scale: _pulseAnimation,
                        child: _buildMainCounter(counter, primaryColor, textColor, subTextColor, isDark),
                      ),
                    ),
                    
                    const Spacer(flex: 2),
                    
                    // Stats
                    _buildStatsBar(textColor, subTextColor, primaryColor),
                    
                    const SizedBox(height: 16),
                    
                    // Reset buttons side by side
                    _buildResetButtons(counter, primaryColor, textColor),
                    
                    const SizedBox(height: 8),
                    
                    // Hint text
                    Text(
                      'tap circle to count',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        color: subTextColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDark, Color textColor, Color primaryColor) {
    final logoPath = isDark 
        ? 'assets/icgos/tasbihla-darkmode.png'
        : 'assets/icgos/tasbihla-lightmode.png';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.menu_rounded, color: textColor.withValues(alpha: 0.7)),
            onPressed: () => _showMenuSheet(context, isDark, textColor),
          ),
          const Spacer(),
          // Logo
          Image.asset(
            logoPath,
            height: 28,
            errorBuilder: (_, __, ___) => Text(
              'Tasbih.la',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: textColor.withValues(alpha: 0.7)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChainBadge(CounterProvider counter, Color primaryColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            counter.chainName ?? '',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          ...List.generate(counter.totalSteps, (i) {
            final isActive = i == counter.currentStepIndex;
            final isDone = i < counter.currentStepIndex;
            return Container(
              width: isActive ? 14 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isDone || isActive ? primaryColor : primaryColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNextPrayer(Color primaryColor, Color textColor, Color subTextColor) {
    final next = _prayerTime!.getNextPrayer();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(next['icon'], style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            '${next['name']}',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${next['time']}',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              color: subTextColor,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(${next['remaining']})',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              color: subTextColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZikrSelector(CounterProvider counter, Color primaryColor, Color textColor) {
    return GestureDetector(
      onTap: () => QuickZikrSwitcher.show(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              counter.zikrName,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: textColor.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildArabicText(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: GoogleFonts.amiri(
          fontSize: 28,
          color: textColor.withValues(alpha: 0.75),
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMainCounter(CounterProvider counter, Color primaryColor, Color textColor, Color subTextColor, bool isDark) {
    // Subtle, muted bead color
    final beadColor = isDark 
        ? primaryColor.withValues(alpha: 0.7)
        : primaryColor.withValues(alpha: 0.85);
    
    return SizedBox(
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Tasbih beads - simple single color
          TasbihBeads(
            totalBeads: counter.target > 0 ? counter.target : 33,
            currentCount: counter.count,
            size: 260,
            colors: [beadColor],
          ),
          
          // Center content - count only
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${counter.count}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 64,
                  fontWeight: FontWeight.w300,
                  color: textColor,
                  height: 1,
                ),
              ),
              if (counter.target > 0)
                Text(
                  'of ${counter.target}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: subTextColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(Color textColor, Color subTextColor, Color primaryColor) {
    final globalTotal = StorageService.settingsRepository.globalTotal;
    final completedCount = StorageService.settingsRepository.completedCount;
    final allZikr = StorageService.zikrRepository.getAll();

    return GestureDetector(
      onLongPress: () => _showResetStatsDialog(primaryColor, textColor),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem('$globalTotal', 'Total', textColor, subTextColor),
            Container(width: 1, height: 28, color: textColor.withValues(alpha: 0.08)),
            _buildStatItem('$completedCount', 'Done', textColor, subTextColor),
            Container(width: 1, height: 28, color: textColor.withValues(alpha: 0.08)),
            _buildStatItem('${allZikr.length}', 'Zikr', textColor, subTextColor),
          ],
        ),
      ),
    );
  }

  void _showResetStatsDialog(Color primaryColor, Color textColor) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reset All Stats?', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
        content: Text('This will reset your Total count and Done count to 0.', style: GoogleFonts.spaceGrotesk()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.spaceGrotesk(color: textColor.withValues(alpha: 0.6))),
          ),
          TextButton(
            onPressed: () async {
              await StorageService.settingsRepository.resetStats();
              Navigator.pop(ctx);
              setState(() {});
            },
            child: Text('Reset All', style: GoogleFonts.spaceGrotesk(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color textColor, Color subTextColor) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            color: subTextColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildResetButtons(CounterProvider counter, Color primaryColor, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset Tasbih button
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text('Reset Counter?', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
                content: Text('Reset current zikr count to 0.', style: GoogleFonts.spaceGrotesk()),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Cancel', style: GoogleFonts.spaceGrotesk(color: textColor.withValues(alpha: 0.6))),
                  ),
                  TextButton(
                    onPressed: () {
                      counter.reset();
                      Navigator.pop(ctx);
                      setState(() {});
                    },
                    child: Text('Reset', style: GoogleFonts.spaceGrotesk(color: primaryColor, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded, size: 14, color: primaryColor),
                const SizedBox(width: 4),
                Text(
                  'Tasbih',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Reset Total button
        GestureDetector(
          onTap: () => _showResetStatsDialog(primaryColor, textColor),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.restart_alt_rounded, size: 14, color: Colors.red.withValues(alpha: 0.8)),
                const SizedBox(width: 4),
                Text(
                  'Total',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.red.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showMenuSheet(BuildContext context, bool isDark, Color textColor) {
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.list_rounded, color: textColor.withValues(alpha: 0.7)),
              title: Text('Zikr Presets', style: GoogleFonts.spaceGrotesk(color: textColor, fontWeight: FontWeight.w500)),
              subtitle: Text('Manage your zikr list', style: GoogleFonts.spaceGrotesk(color: textColor.withValues(alpha: 0.5), fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PresetsScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.link_rounded, color: textColor.withValues(alpha: 0.7)),
              title: Text('Zikr Chains', style: GoogleFonts.spaceGrotesk(color: textColor, fontWeight: FontWeight.w500)),
              subtitle: Text('Create & manage chains', style: GoogleFonts.spaceGrotesk(color: textColor.withValues(alpha: 0.5), fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChainsScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.access_time_rounded, color: textColor.withValues(alpha: 0.7)),
              title: Text('Prayer Times', style: GoogleFonts.spaceGrotesk(color: textColor, fontWeight: FontWeight.w500)),
              subtitle: Text('Today\'s prayer schedule', style: GoogleFonts.spaceGrotesk(color: textColor.withValues(alpha: 0.5), fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PrayerTimesScreen()));
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
