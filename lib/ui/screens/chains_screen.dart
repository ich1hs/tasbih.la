import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/zikr_chain_model.dart';
import '../../providers/counter_provider.dart';
import '../../services/storage_service.dart';

class ChainsScreen extends StatefulWidget {
  const ChainsScreen({super.key});

  @override
  State<ChainsScreen> createState() => _ChainsScreenState();
}

class _ChainsScreenState extends State<ChainsScreen> {
  List<ZikrChainModel> _chains = [];

  @override
  void initState() {
    super.initState();
    _loadChains();
  }

  void _loadChains() {
    setState(() {
      _chains = StorageService.chainRepository.getAll();
    });
  }

  Future<void> _createChain() async {
    final result = await showModalBottomSheet<ZikrChainModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _ChainEditorSheet(),
    );

    if (result != null) {
      await StorageService.chainRepository.add(result);
      _loadChains();
    }
  }

  Future<void> _editChain(ZikrChainModel chain) async {
    if (chain.isBuiltIn) {
      // For built-in chains, only allow editing counts
      final result = await showModalBottomSheet<ZikrChainModel>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _ChainEditorSheet(existingChain: chain),
      );

      if (result != null) {
        await StorageService.chainRepository.update(result);
        _loadChains();
      }
    } else {
      final result = await showModalBottomSheet<ZikrChainModel>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _ChainEditorSheet(existingChain: chain),
      );

      if (result != null) {
        await StorageService.chainRepository.update(result);
        _loadChains();
      }
    }
  }

  Future<void> _deleteChain(ZikrChainModel chain) async {
    if (chain.isBuiltIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete built-in chains')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Chain?'),
        content: Text('Are you sure you want to delete "${chain.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.chainRepository.delete(chain);
      _loadChains();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final counter = context.watch<CounterProvider>();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Zikr Chains', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: _chains.isEmpty
          ? _buildEmptyState(theme)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _chains.length,
              itemBuilder: (context, index) {
                final chain = _chains[index];
                final isActive = counter.mode == ActiveMode.chain &&
                    counter.activeChain?.id == chain.id;

                return _ChainCard(
                  chain: chain,
                  isActive: isActive,
                  onTap: () async {
                    await counter.setActiveChain(chain);
                    if (mounted) Navigator.pop(context);
                  },
                  onEdit: () => _editChain(chain),
                  onDelete: () => _deleteChain(chain),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createChain,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Chain'),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.link_off_rounded,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No chains yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a chain to combine multiple zikr',
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChainCard extends StatelessWidget {
  final ZikrChainModel chain;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ChainCard({
    required this.chain,
    required this.isActive,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isActive
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      chain.isBuiltIn ? Icons.auto_awesome : Icons.link_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              chain.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (chain.isBuiltIn) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Built-in',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          '${chain.steps.length} steps',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    Icon(Icons.check_circle, color: theme.colorScheme.primary),
                ],
              ),
              const SizedBox(height: 16),
              // Steps
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: chain.steps.map((step) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${step.name} × ${step.targetCount}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              // Progress
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: chain.overallProgress,
                  minHeight: 4,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                ),
              ),
              const SizedBox(height: 12),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Edit'),
                  ),
                  if (!chain.isBuiltIn)
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_rounded, size: 18),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Chain Editor Bottom Sheet
class _ChainEditorSheet extends StatefulWidget {
  final ZikrChainModel? existingChain;

  const _ChainEditorSheet({this.existingChain});

  @override
  State<_ChainEditorSheet> createState() => _ChainEditorSheetState();
}

class _ChainEditorSheetState extends State<_ChainEditorSheet> {
  late TextEditingController _nameController;
  List<_StepData> _steps = [];
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingChain?.name ?? '',
    );

    if (widget.existingChain != null) {
      _steps = widget.existingChain!.steps.map((s) => _StepData(
        nameController: TextEditingController(text: s.name),
        countController: TextEditingController(text: s.targetCount.toString()),
        ayahController: TextEditingController(text: s.ayahText ?? ''),
      )).toList();
    } else {
      _addStep();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var step in _steps) {
      step.dispose();
    }
    super.dispose();
  }

  void _addStep() {
    setState(() {
      _steps.add(_StepData(
        nameController: TextEditingController(),
        countController: TextEditingController(text: '33'),
        ayahController: TextEditingController(),
      ));
    });
  }

  void _removeStep(int index) {
    if (_steps.length > 1) {
      setState(() {
        _steps[index].dispose();
        _steps.removeAt(index);
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_steps.isEmpty) return;

    final steps = _steps.map((s) => ChainStep(
      name: s.nameController.text.trim(),
      targetCount: int.tryParse(s.countController.text) ?? 33,
      ayahText: s.ayahController.text.trim().isEmpty 
          ? null 
          : s.ayahController.text.trim(),
    )).toList();

    final chain = widget.existingChain?.copyWith(
      name: _nameController.text.trim(),
      steps: steps,
    ) ?? ZikrChainModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      steps: steps,
    );

    Navigator.pop(context, chain);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isBuiltIn = widget.existingChain?.isBuiltIn ?? false;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    widget.existingChain != null ? 'Edit Chain' : 'New Chain',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Chain name
                  TextFormField(
                    controller: _nameController,
                    enabled: !isBuiltIn,
                    decoration: InputDecoration(
                      labelText: 'Chain Name',
                      hintText: 'e.g., Morning Adhkar',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => v?.trim().isEmpty == true 
                        ? 'Please enter a name' 
                        : null,
                  ),
                  const SizedBox(height: 24),
                  // Steps header
                  Row(
                    children: [
                      Text(
                        'Steps',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      if (!isBuiltIn)
                        TextButton.icon(
                          onPressed: _addStep,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Step'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Steps list
                  ...List.generate(_steps.length, (index) {
                    return _StepEditor(
                      index: index,
                      data: _steps[index],
                      canDelete: _steps.length > 1 && !isBuiltIn,
                      onDelete: () => _removeStep(index),
                      nameEditable: !isBuiltIn,
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepData {
  final TextEditingController nameController;
  final TextEditingController countController;
  final TextEditingController ayahController;

  _StepData({
    required this.nameController,
    required this.countController,
    required this.ayahController,
  });

  void dispose() {
    nameController.dispose();
    countController.dispose();
    ayahController.dispose();
  }
}

class _StepEditor extends StatelessWidget {
  final int index;
  final _StepData data;
  final bool canDelete;
  final VoidCallback onDelete;
  final bool nameEditable;

  const _StepEditor({
    required this.index,
    required this.data,
    required this.canDelete,
    required this.onDelete,
    required this.nameEditable,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.05) 
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: data.nameController,
                  enabled: nameEditable,
                  decoration: const InputDecoration(
                    labelText: 'Zikr Name',
                    hintText: 'e.g., SubhanAllah',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  validator: (v) => v?.trim().isEmpty == true 
                      ? 'Required' 
                      : null,
                ),
              ),
              if (canDelete)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.red,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: data.countController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Count',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                  ),
                  validator: (v) {
                    if (v?.isEmpty == true) return 'Required';
                    if (int.tryParse(v!) == null) return 'Invalid';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: data.ayahController,
                  decoration: InputDecoration(
                    labelText: 'Arabic Text (optional)',
                    hintText: 'سُبْحَانَ اللَّهِ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
