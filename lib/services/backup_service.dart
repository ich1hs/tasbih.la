import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/zikr_model.dart';
import '../models/zikr_chain_model.dart';
import 'storage_service.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  /// Export all data to JSON and share
  Future<bool> exportBackup() async {
    try {
      final data = _createBackupData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      
      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/tasbihla_backup_$timestamp.json');
      await file.writeAsString(jsonString);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'tasbih.la Backup',
        text: 'My tasbih.la backup file',
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Import data from JSON file
  Future<BackupResult> importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return BackupResult(success: false, message: 'No file selected');
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate backup format
      if (!data.containsKey('version') || !data.containsKey('zikr')) {
        return BackupResult(success: false, message: 'Invalid backup file');
      }

      // Import zikr presets
      int zikrCount = 0;
      final zikrList = data['zikr'] as List;
      for (var zikrData in zikrList) {
        final zikr = ZikrModel(
          id: zikrData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: zikrData['name'],
          targetCount: zikrData['targetCount'],
          currentCount: zikrData['currentCount'] ?? 0,
          ayahText: zikrData['ayahText'],
        );
        await StorageService.zikrRepository.add(zikr);
        zikrCount++;
      }

      // Import chains if present
      int chainCount = 0;
      if (data.containsKey('chains')) {
        final chainList = data['chains'] as List;
        for (var chainData in chainList) {
          final steps = (chainData['steps'] as List).map((s) => ChainStep(
            name: s['name'],
            targetCount: s['targetCount'],
            currentCount: s['currentCount'] ?? 0,
            ayahText: s['ayahText'],
          )).toList();

          final chain = ZikrChainModel(
            id: chainData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            name: chainData['name'],
            steps: steps,
            isBuiltIn: false,
          );
          await StorageService.chainRepository.add(chain);
          chainCount++;
        }
      }

      // Import settings if present
      if (data.containsKey('settings')) {
        final settings = data['settings'] as Map<String, dynamic>;
        if (settings.containsKey('globalTotal')) {
          // Note: This would need additional repository methods
        }
      }

      return BackupResult(
        success: true,
        message: 'Imported $zikrCount zikr presets and $chainCount chains',
      );
    } catch (e) {
      return BackupResult(success: false, message: 'Error: $e');
    }
  }

  Map<String, dynamic> _createBackupData() {
    final zikrList = StorageService.zikrRepository.getAll();
    final chainList = StorageService.chainRepository.getAll();

    return {
      'version': '1.0',
      'app': 'tasbih.la',
      'exportedAt': DateTime.now().toIso8601String(),
      'zikr': zikrList.map((z) => {
        'id': z.id,
        'name': z.name,
        'targetCount': z.targetCount,
        'currentCount': z.currentCount,
        'ayahText': z.ayahText,
      }).toList(),
      'chains': chainList.where((c) => !c.isBuiltIn).map((c) => {
        'id': c.id,
        'name': c.name,
        'steps': c.steps.map((s) => {
          'name': s.name,
          'targetCount': s.targetCount,
          'currentCount': s.currentCount,
          'ayahText': s.ayahText,
        }).toList(),
      }).toList(),
      'settings': {
        'globalTotal': StorageService.settingsRepository.globalTotal,
        'completedCount': StorageService.settingsRepository.completedCount,
      },
    };
  }
}

class BackupResult {
  final bool success;
  final String message;

  BackupResult({required this.success, required this.message});
}
