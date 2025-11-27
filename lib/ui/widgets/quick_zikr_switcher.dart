import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/zikr_chain_model.dart';
import '../../providers/counter_provider.dart';
import '../../services/storage_service.dart';

class QuickZikrSwitcher extends StatefulWidget {
  const QuickZikrSwitcher({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickZikrSwitcher(),
    );
  }

  @override
  State<QuickZikrSwitcher> createState() => _QuickZikrSwitcherState();
}

class _QuickZikrSwitcherState extends State<QuickZikrSwitcher>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final counter = context.read<CounterProvider>();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: counter.mode == ActiveMode.chain ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counterProvider = context.watch<CounterProvider>();
    final zikrList = StorageService.zikrRepository.getAll();
    final chainList = StorageService.chainRepository.getAll();

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 16, bottom: 8),
            decoration: BoxDecoration(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Switch Zikr',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Single Zikr'),
              Tab(text: 'Chains'),
            ],
            labelColor: theme.colorScheme.primary,
            indicatorColor: theme.colorScheme.primary,
          ),

          // Tab Content
          SizedBox(
            height: 350,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Single Zikr Tab
                _buildSingleZikrList(context, theme, counterProvider, zikrList),
                // Chains Tab
                _buildChainList(context, theme, counterProvider, chainList),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSingleZikrList(
    BuildContext context,
    ThemeData theme,
    CounterProvider counterProvider,
    List zikrList,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: zikrList.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final zikr = zikrList[index];
        final isActive = counterProvider.mode == ActiveMode.single &&
            counterProvider.activeZikr?.id == zikr.id;
        final progress = zikr.progress;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: isActive ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isActive
                ? BorderSide(color: theme.colorScheme.primary, width: 2)
                : BorderSide.none,
          ),
          child: ListTile(
            onTap: () async {
              await counterProvider.setActiveZikr(zikr);
              if (context.mounted) Navigator.pop(context);
            },
            leading: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  '${zikr.currentCount}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            title: Text(zikr.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Target: ${zikr.targetCount}'),
            trailing: isActive
                ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildChainList(
    BuildContext context,
    ThemeData theme,
    CounterProvider counterProvider,
    List<ZikrChainModel> chainList,
  ) {
    if (chainList.isEmpty) {
      return Center(
        child: Text(
          'No chains available',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: chainList.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final chain = chainList[index];
        final isActive = counterProvider.mode == ActiveMode.chain &&
            counterProvider.activeChain?.id == chain.id;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: isActive ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isActive
                ? BorderSide(color: theme.colorScheme.primary, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              await counterProvider.setActiveChain(chain);
              if (context.mounted) Navigator.pop(context);
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        chain.isBuiltIn ? Icons.auto_awesome : Icons.link,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          chain.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isActive)
                        Icon(Icons.check_circle, color: theme.colorScheme.primary),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Steps preview
                  Wrap(
                    spacing: 8,
                    children: chain.steps.asMap().entries.map((e) {
                      final stepIndex = e.key;
                      final step = e.value;
                      final isCurrent = chain.currentStepIndex == stepIndex;
                      final isDone = step.isCompleted;
                      
                      return Chip(
                        label: Text(
                          '${step.name} (${step.targetCount})',
                          style: TextStyle(
                            fontSize: 11,
                            color: isCurrent 
                                ? Colors.white 
                                : theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        backgroundColor: isCurrent
                            ? theme.colorScheme.primary
                            : isDone
                                ? theme.colorScheme.primary.withValues(alpha: 0.2)
                                : null,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  // Overall progress
                  LinearProgressIndicator(
                    value: chain.overallProgress,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
