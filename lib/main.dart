import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/prayer_times_screen.dart';
import 'providers/counter_provider.dart';
import 'providers/settings_provider.dart';
import 'services/storage_service.dart';
import 'services/audio_service.dart';
import 'services/prayer_time_service.dart';

/// Global navigator key for widget navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize critical storage with timeout
    await StorageService.init().timeout(
      const Duration(seconds: 2), 
      onTimeout: () {
        debugPrint("Storage init timed out");
        return;
      }
    );
    
    // Initialize home widget
    HomeWidget.setAppGroupId('com.ich1hs.tasbih_la');
    
    // Initialize non-critical services in background (don't await)
    _initWidgetData();
    AudioService().init();

    // Allow GoogleFonts to fetch over HTTP (needed for some networks)
    GoogleFonts.config.allowRuntimeFetching = true;

    // Edge-to-edge display
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  } catch (e, stack) {
    debugPrint("Error during initialization: $e\n$stack");
  }

  runApp(const TasbihApp());
}

/// Initialize widget data on app startup
Future<void> _initWidgetData() async {
  try {
    // Tasbih widget data
    final total = StorageService.settingsRepository.globalTotal;
    await HomeWidget.saveWidgetData('globalTotal', total.toString());
    await HomeWidget.updateWidget(androidName: 'TasbihWidgetProvider');
    
    // Prayer widget data - try to fetch if not already cached
    final prayerService = PrayerTimeService();
    final prayer = await prayerService.getTodayPrayerTimes();
    if (prayer != null) {
      final next = prayer.getNextPrayer();
      await HomeWidget.saveWidgetData('nextPrayerName', next['name']);
      await HomeWidget.saveWidgetData('nextPrayerTime', next['time']);
      await HomeWidget.saveWidgetData('nextPrayerRemaining', next['remaining']);
      await HomeWidget.saveWidgetData('nextPrayerIcon', next['icon']);
      await HomeWidget.saveWidgetData('fajr', prayer.fajr);
      await HomeWidget.saveWidgetData('sunrise', prayer.sunrise);
      await HomeWidget.saveWidgetData('dhuhr', prayer.dhuhr);
      await HomeWidget.saveWidgetData('asr', prayer.asr);
      await HomeWidget.saveWidgetData('maghrib', prayer.maghrib);
      await HomeWidget.saveWidgetData('isha', prayer.isha);
      await HomeWidget.updateWidget(androidName: 'PrayerWidgetProvider');
    }
  } catch (e) {
    // Widget init failed, ignore - will be updated when HomeScreen loads
  }
}

class TasbihApp extends StatefulWidget {
  const TasbihApp({super.key});

  @override
  State<TasbihApp> createState() => _TasbihAppState();
}

class _TasbihAppState extends State<TasbihApp> {
  @override
  void initState() {
    super.initState();
    _handleWidgetLaunch();
  }

  /// Check if app was launched from widget and navigate accordingly
  Future<void> _handleWidgetLaunch() async {
    // Check initial launch data
    final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (initialUri != null) {
      _handleWidgetUri(initialUri);
    }
    
    // Listen for widget clicks while app is running
    HomeWidget.widgetClicked.listen((uri) {
      if (uri != null) {
        _handleWidgetUri(uri);
      }
    });
  }

  void _handleWidgetUri(Uri uri) {
    // Prayer widget clicked - navigate to prayer times
    if (uri.host == 'prayerwidget' || uri.toString().contains('prayer')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const PrayerTimesScreen()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProxyProvider<SettingsProvider, CounterProvider>(
          create: (context) => CounterProvider(context.read<SettingsProvider>()),
          update: (context, settings, counter) => counter!..updateSettings(settings),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'tasbih.la',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      primaryColor: const Color(0xFF5C8374),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF5C8374),
        secondary: Color(0xFF7C9A92),
        surface: Color(0xFFFAFAFA),
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme(
        ThemeData.light().textTheme,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF2D2D2D)),
      ),
      useMaterial3: true,
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      primaryColor: const Color(0xFF8FAE8B),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF8FAE8B),
        secondary: Color(0xFF5C8374),
        surface: Color(0xFF121212),
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme(
        ThemeData.dark().textTheme,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      useMaterial3: true,
    );
  }
}
