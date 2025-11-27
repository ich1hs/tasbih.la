import 'package:hive_flutter/hive_flutter.dart';
import '../models/zikr_model.dart';

class ZikrRepository {
  final Box<ZikrModel> _box;

  ZikrRepository(this._box);

  List<ZikrModel> getAll() {
    return _box.values.toList();
  }

  Future<void> add(ZikrModel zikr) async {
    await _box.add(zikr);
  }

  Future<void> update(ZikrModel zikr) async {
    await zikr.save();
  }

  Future<void> delete(ZikrModel zikr) async {
    await zikr.delete();
  }

  ZikrModel? getById(String id) {
    try {
      return _box.values.firstWhere((zikr) => zikr.id == id);
    } catch (e) {
      return null;
    }
  }
}
