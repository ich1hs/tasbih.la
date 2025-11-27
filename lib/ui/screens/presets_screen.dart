import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/zikr_model.dart';
import '../../providers/counter_provider.dart';
import '../../services/storage_service.dart';

class PresetsScreen extends StatefulWidget {
  const PresetsScreen({super.key});

  @override
  State<PresetsScreen> createState() => _PresetsScreenState();
}

class _PresetsScreenState extends State<PresetsScreen> {
  List<ZikrModel> _zikrList = [];
  bool _isSelectionMode = false;
  Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadZikr();
  }

  void _loadZikr() {
    setState(() {
      _zikrList = StorageService.zikrRepository.getAll();
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete ${_selectedIds.length} items?', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
        content: Text('This action cannot be undone.', style: GoogleFonts.spaceGrotesk()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.spaceGrotesk()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final id in _selectedIds) {
        final zikr = _zikrList.firstWhere((z) => z.id == id);
        await StorageService.zikrRepository.delete(zikr);
      }
      _selectedIds.clear();
      _isSelectionMode = false;
      _loadZikr();
    }
  }

  Future<void> _addNewZikr() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ZikrBottomSheet(),
    );

    if (result != null) {
      final newZikr = ZikrModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: result['name'],
        targetCount: result['target'],
        ayahText: result['ayahText'],
      );

      await StorageService.zikrRepository.add(newZikr);
      _loadZikr();
    }
  }

  Future<void> _editZikr(ZikrModel zikr) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ZikrBottomSheet(existingZikr: zikr),
    );

    if (result != null) {
      // Update the original object directly (required for HiveObject.save() to work)
      zikr.name = result['name'];
      zikr.targetCount = result['target'];
      zikr.ayahText = result['ayahText'];
      zikr.lastUpdated = DateTime.now();

      await StorageService.zikrRepository.update(zikr);
      _loadZikr();

      if (mounted) {
        context.read<CounterProvider>().refreshZikr();
      }
    }
  }

  Future<void> _deleteZikr(ZikrModel zikr) async {
    await StorageService.zikrRepository.delete(zikr);
    _loadZikr();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final counterProvider = context.watch<CounterProvider>();
    final primaryColor = theme.colorScheme.primary;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subTextColor = isDark ? Colors.white60 : Colors.black54;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _isSelectionMode ? '${_selectedIds.length} selected' : 'Zikr Presets',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all_rounded),
              onPressed: () {
                setState(() {
                  if (_selectedIds.length == _zikrList.length) {
                    _selectedIds.clear();
                  } else {
                    _selectedIds = _zikrList.map((z) => z.id).toSet();
                  }
                });
              },
              tooltip: 'Select all',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: _selectedIds.isNotEmpty ? _deleteSelected : null,
              tooltip: 'Delete selected',
            ),
          ],
          IconButton(
            icon: Icon(_isSelectionMode ? Icons.close : Icons.checklist_rounded),
            onPressed: _toggleSelectionMode,
            tooltip: _isSelectionMode ? 'Cancel' : 'Select',
          ),
        ],
      ),
      body: _zikrList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: subTextColor),
                  const SizedBox(height: 16),
                  Text('No zikr presets', style: GoogleFonts.spaceGrotesk(fontSize: 16, color: subTextColor)),
                  const SizedBox(height: 8),
                  Text('Tap + to add one', style: GoogleFonts.spaceGrotesk(fontSize: 13, color: subTextColor)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: _zikrList.length,
              itemBuilder: (context, index) {
                final zikr = _zikrList[index];
                final isActive = counterProvider.activeZikr?.id == zikr.id;
                final isSelected = _selectedIds.contains(zikr.id);
                final progress = zikr.targetCount > 0 ? zikr.currentCount / zikr.targetCount : 0.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: isActive ? Border.all(color: primaryColor, width: 1.5) : null,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      if (_isSelectionMode) {
                        _toggleSelection(zikr.id);
                      } else {
                        counterProvider.setActiveZikr(zikr);
                        Navigator.pop(context);
                      }
                    },
                    onLongPress: () {
                      if (!_isSelectionMode) {
                        HapticFeedback.mediumImpact();
                        _toggleSelectionMode();
                        _toggleSelection(zikr.id);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Checkbox or Progress
                          if (_isSelectionMode)
                            Checkbox(
                              value: isSelected,
                              onChanged: (_) => _toggleSelection(zikr.id),
                              activeColor: primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            )
                          else
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 3,
                                    backgroundColor: primaryColor.withValues(alpha: 0.15),
                                    color: primaryColor,
                                  ),
                                ),
                                Text(
                                  '${zikr.currentCount}',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(width: 12),
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        zikr.name,
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                    if (isActive)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: primaryColor,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'ACTIVE',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Target: ${zikr.targetCount}',
                                  style: GoogleFonts.spaceGrotesk(fontSize: 11, color: subTextColor),
                                ),
                                if (zikr.ayahText != null && zikr.ayahText!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    zikr.ayahText!,
                                    style: GoogleFonts.amiri(fontSize: 13, color: textColor.withValues(alpha: 0.7)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textDirection: TextDirection.rtl,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Edit button
                          if (!_isSelectionMode)
                            IconButton(
                              icon: Icon(Icons.edit_outlined, size: 18, color: subTextColor),
                              onPressed: () => _editZikr(zikr),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewZikr,
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _ZikrBottomSheet extends StatefulWidget {
  final ZikrModel? existingZikr;
  const _ZikrBottomSheet({this.existingZikr});

  @override
  State<_ZikrBottomSheet> createState() => _ZikrBottomSheetState();
}

class _ZikrBottomSheetState extends State<_ZikrBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _targetController;
  late final TextEditingController _ayahController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingZikr?.name ?? '');
    _targetController = TextEditingController(text: widget.existingZikr?.targetCount.toString() ?? '33');
    _ayahController = TextEditingController(text: widget.existingZikr?.ayahText ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _ayahController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final isEdit = widget.existingZikr != null;

    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isEdit ? 'Edit Zikr' : 'Add New Zikr',
                style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
              ),
              const SizedBox(height: 20),
              // Name field
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.spaceGrotesk(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: GoogleFonts.spaceGrotesk(color: textColor.withValues(alpha: 0.6)),
                  hintText: 'e.g., SubhanAllah',
                  hintStyle: GoogleFonts.spaceGrotesk(color: textColor.withValues(alpha: 0.3)),
                  filled: true,
                  fillColor: primaryColor.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              // Target field
              TextFormField(
                controller: _targetController,
                style: GoogleFonts.spaceGrotesk(color: textColor),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Target Count',
                  labelStyle: GoogleFonts.spaceGrotesk(color: textColor.withValues(alpha: 0.6)),
                  hintText: '33',
                  hintStyle: GoogleFonts.spaceGrotesk(color: textColor.withValues(alpha: 0.3)),
                  filled: true,
                  fillColor: primaryColor.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (int.tryParse(value) == null || int.parse(value) <= 0) return 'Enter valid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // Arabic text field
              TextFormField(
                controller: _ayahController,
                style: GoogleFonts.amiri(color: textColor, fontSize: 18),
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  labelText: 'Arabic Text (Optional)',
                  labelStyle: GoogleFonts.spaceGrotesk(color: textColor.withValues(alpha: 0.6)),
                  hintText: 'سُبْحَانَ اللَّهِ',
                  hintStyle: GoogleFonts.amiri(color: textColor.withValues(alpha: 0.3)),
                  filled: true,
                  fillColor: primaryColor.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 24),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Cancel', style: GoogleFonts.spaceGrotesk(color: textColor)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.pop(context, {
                            'name': _nameController.text,
                            'target': int.parse(_targetController.text),
                            'ayahText': _ayahController.text.isEmpty ? null : _ayahController.text,
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        isEdit ? 'Update' : 'Add',
                        style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
