import 'package:hive_flutter/hive_flutter.dart';
import '../models/zikr_chain_model.dart';

class ChainRepository {
  final Box<ZikrChainModel> _box;

  ChainRepository(this._box);

  List<ZikrChainModel> getAll() {
    return _box.values.toList();
  }

  Future<void> add(ZikrChainModel chain) async {
    await _box.put(chain.id, chain);
  }

  Future<void> update(ZikrChainModel chain) async {
    await _box.put(chain.id, chain);
  }

  Future<void> delete(ZikrChainModel chain) async {
    await chain.delete();
  }

  ZikrChainModel? getById(String id) {
    return _box.get(id);
  }

  /// Ensure Tasbih Fatimah exists
  Future<void> ensureBuiltInChains() async {
    if (_box.get('tasbih_fatimah') == null) {
      final tasbihFatimah = ZikrChainModel.tasbihFatimah();
      await _box.put(tasbihFatimah.id, tasbihFatimah);
    }
  }
}
