import 'package:hive_flutter/hive_flutter.dart';
import '../models/zikr_model.dart';
import '../models/zikr_chain_model.dart';
import '../repositories/zikr_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/chain_repository.dart';

class StorageService {
  static const String _zikrBoxName = 'zikr_box';
  static const String _settingsBoxName = 'settings_box';
  static const String _chainBoxName = 'chain_box';

  static late Box<ZikrModel> _zikrBox;
  static late Box _settingsBox;
  static late Box<ZikrChainModel> _chainBox;

  static late ZikrRepository zikrRepository;
  static late SettingsRepository settingsRepository;
  static late ChainRepository chainRepository;

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(ZikrModelAdapter());
    Hive.registerAdapter(ZikrChainModelAdapter());
    Hive.registerAdapter(ChainStepAdapter());

    // Open boxes
    _zikrBox = await Hive.openBox<ZikrModel>(_zikrBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _chainBox = await Hive.openBox<ZikrChainModel>(_chainBoxName);

    // Initialize repositories
    zikrRepository = ZikrRepository(_zikrBox);
    settingsRepository = SettingsRepository(_settingsBox);
    chainRepository = ChainRepository(_chainBox);

    // Add defaults
    if (_zikrBox.isEmpty) {
      await _addDefaultZikr();
    }
    
    // Ensure built-in chains exist
    await chainRepository.ensureBuiltInChains();
  }

  static Future<void> _addDefaultZikr() async {
    final defaultZikr = [
      ZikrModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'SubhanAllah',
        targetCount: 33,
        ayahText: 'سُبْحَانَ اللَّهِ',
      ),
      ZikrModel(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        name: 'Alhamdulillah',
        targetCount: 33,
        ayahText: 'الْحَمْدُ لِلَّهِ',
      ),
      ZikrModel(
        id: (DateTime.now().millisecondsSinceEpoch + 2).toString(),
        name: 'Allahu Akbar',
        targetCount: 34,
        ayahText: 'اللَّهُ أَكْبَرُ',
      ),
    ];

    for (var zikr in defaultZikr) {
      await _zikrBox.add(zikr);
    }
  }
}
