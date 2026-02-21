import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:financial_hub/core/app_logger.dart';
import 'package:financial_hub/features/behavior/behavior_report_screen.dart';
import 'package:financial_hub/features/money_plan/money_plan_service.dart';
import 'package:financial_hub/shared/pockets/pocket_icon_catalog.dart';
import 'package:financial_hub/shared/theme/app_radius.dart';
import 'package:financial_hub/shared/theme/app_spacing.dart';
import 'package:financial_hub/shared/theme/app_colors.dart';
import 'package:financial_hub/shared/widgets/app_bottom_nav.dart';
import 'package:financial_hub/shared/widgets/app_card.dart';
import 'package:financial_hub/shared/widgets/app_scaffold.dart';
import 'package:financial_hub/shared/widgets/app_text_field.dart';
import 'package:financial_hub/shared/widgets/primary_button.dart';
import 'package:financial_hub/shared/widgets/secondary_button.dart';
import 'package:financial_hub/shared/widgets/warning_card.dart';

class MoneyPlanScreen extends StatefulWidget {
  const MoneyPlanScreen({super.key, this.onPlanChanged, this.onTabSelected});

  final VoidCallback? onPlanChanged;
  final ValueChanged<int>? onTabSelected;

  @override
  State<MoneyPlanScreen> createState() => _MoneyPlanScreenState();
}

class _MoneyPlanScreenState extends State<MoneyPlanScreen> {
  static const String _autoIconSentinel = '__auto_icon__';

  final _service = MoneyPlanService();
  final _planNameController = TextEditingController();

  MoneyPlanEditorState? _editor;
  List<EditablePocketDraft> _pockets = [];
  String? _selectedPlanId;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _planNameController.dispose();
    super.dispose();
  }

  Future<void> _load({String? selectedPlanId}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final editor = await _service.load(selectedPlanId: selectedPlanId);
      if (!mounted) return;

      if (editor == null) {
        setState(() {
          _editor = null;
          _pockets = [];
          _selectedPlanId = null;
          _loading = false;
          _error =
              'No authenticated profile found. Register with phone to manage plans.';
        });
        return;
      }

      setState(() {
        _editor = editor;
        _selectedPlanId = editor.selectedPlan.id;
        _pockets = editor.pockets.map((p) => p.copy()).toList();
        _planNameController.text = editor.selectedPlan.name;
        _loading = false;
      });
    } catch (e, st) {
      AppLogger.error('Failed to load money plan editor', e, st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceAll(RegExp(r'Exception:?'), '').trim();
      });
    }
  }

  Future<void> _activatePlan(String planId) async {
    if (_editor == null || _selectedPlanId == planId) return;

    final selected = _editor!.plans.firstWhere((p) => p.id == planId);
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _service.setActivePlan(
        profileId: _editor!.profileId,
        planId: planId,
        planName: selected.name,
      );
      await _load(selectedPlanId: planId);
      widget.onPlanChanged?.call();
    } catch (e, st) {
      AppLogger.error('Failed to activate plan', e, st);
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll(RegExp(r'Exception:?'), '').trim();
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _savePlan() async {
    if (_editor == null || _selectedPlanId == null) return;

    final validationError = MoneyPlanService.validatePockets(_pockets);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _service.updatePlan(
        profileId: _editor!.profileId,
        planId: _selectedPlanId!,
        planName: _planNameController.text,
        pockets: _pockets,
      );
      await _load(selectedPlanId: _selectedPlanId);
      widget.onPlanChanged?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Money plan updated.')));
    } catch (e, st) {
      AppLogger.error('Failed to save plan', e, st);
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll(RegExp(r'Exception:?'), '').trim();
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _createPlan() async {
    if (_editor == null) return;

    final newPlanName = await showDialog<String>(
      context: context,
      builder: (_) => const _CreatePlanDialog(initialName: 'New Plan'),
    );

    if (newPlanName == null || newPlanName.isEmpty) return;

    final clonedPockets = _pockets
        .map(
          (p) => EditablePocketDraft(
            name: p.name,
            percentage: p.percentage,
            isSavings: p.isSavings,
            balance: 0,
            iconKey: p.iconKey,
            iconCustom: p.iconCustom,
          ),
        )
        .toList();

    final validationError = MoneyPlanService.validatePockets(clonedPockets);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final planId = await _service.createPlan(
        profileId: _editor!.profileId,
        name: newPlanName,
        pockets: clonedPockets,
      );
      await _load(selectedPlanId: planId);
      widget.onPlanChanged?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New plan created and activated.')),
      );
    } catch (e, st) {
      AppLogger.error('Failed to create plan', e, st);
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll(RegExp(r'Exception:?'), '').trim();
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deletePlan() async {
    if (_editor == null || _selectedPlanId == null) return;

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (_) => const _PlanConfirmDialog(
            title: 'Delete Plan',
            message: 'Delete this plan permanently? This cannot be undone.',
            icon: LucideIcons.alertTriangle,
            iconColor: AppColors.accentRed,
            cancelLabel: 'Cancel',
            confirmLabel: 'Delete',
            confirmIcon: LucideIcons.trash2,
            confirmGradient: false,
          ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final fallback = await _service.deletePlan(
        profileId: _editor!.profileId,
        planId: _selectedPlanId!,
      );
      await _load(selectedPlanId: fallback);
      widget.onPlanChanged?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Plan deleted.')));
    } catch (e, st) {
      AppLogger.error('Failed to delete plan', e, st);
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll(RegExp(r'Exception:?'), '').trim();
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addSpendablePocket() {
    final name = 'Pocket ${_pockets.where((p) => !p.isSavings).length + 1}';
    setState(() {
      _pockets.add(
        EditablePocketDraft(
          name: name,
          percentage: 0,
          isSavings: false,
          iconKey: PocketIconCatalog.inferKey(name: name, isSavings: false),
          iconCustom: false,
        ),
      );
    });
  }

  void _removePocket(int index) {
    setState(() {
      _pockets.removeAt(index);
    });
  }

  Future<void> _editPocketPercentage(int index) async {
    if (_saving) return;
    final pocket = _pockets[index];
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PercentageKeypadSheet(initialValue: pocket.percentage),
    );

    if (!mounted || selected == null) return;
    setState(() {
      pocket.percentage = selected.clamp(0, 100);
    });
  }

  void _onPocketNameChanged(EditablePocketDraft pocket, String value) {
    setState(() {
      pocket.name = value;
      if (!pocket.iconCustom) {
        pocket.iconKey = PocketIconCatalog.inferKey(
          name: value,
          isSavings: pocket.isSavings,
        );
      }
    });
  }

  Future<void> _pickPocketIcon(int index) async {
    final pocket = _pockets[index];
    if (pocket.isSavings || _saving) return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.background,
      builder: (ctx) {
        final options = PocketIconCatalog.optionsForPicker(isSavings: false);
        final inferred = PocketIconCatalog.inferKey(
          name: pocket.name,
          isSavings: false,
        );
        final inferredMeta = PocketIconCatalog.byKey(inferred);
        final gridHeight = math.max(
          220.0,
          math.min(340.0, MediaQuery.sizeOf(ctx).height * 0.44),
        );

        return SafeArea(
          top: false,
          child: ColoredBox(
            color: AppColors.background,
            child: Padding(
              padding: AppSpacing.sheet,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: AppSpacing.card,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.borderMuted),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose pocket icon',
                          style: Theme.of(ctx).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.x1),
                        Text(
                          'Pick custom or keep Auto match by pocket name.',
                          style: Theme.of(ctx).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.x1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            inferredMeta.icon,
                            color: inferredMeta.color,
                          ),
                          title: const Text('Auto match'),
                          subtitle: Text('Suggested: ${inferredMeta.label}'),
                          trailing: !pocket.iconCustom
                              ? const Icon(
                                  LucideIcons.check,
                                  color: AppColors.primary,
                                )
                              : null,
                          onTap: () => Navigator.of(ctx).pop(_autoIconSentinel),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x1),
                  SizedBox(
                    height: gridHeight,
                    child: GridView.builder(
                      itemCount: options.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: AppSpacing.x1,
                            crossAxisSpacing: AppSpacing.x1,
                            childAspectRatio: 1.2,
                          ),
                      itemBuilder: (context, i) {
                        final option = options[i];
                        final selectedNow =
                            pocket.iconCustom && pocket.iconKey == option.key;
                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.of(ctx).pop(option.key),
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selectedNow
                                    ? option.color
                                    : AppColors.borderMuted,
                              ),
                              color: selectedNow
                                  ? option.color.withValues(alpha: 0.12)
                                  : AppColors.surface,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.x1),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(option.icon, color: option.color),
                                  const SizedBox(height: AppSpacing.x0_5),
                                  Text(
                                    option.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(ctx).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) return;

    setState(() {
      if (selected == _autoIconSentinel) {
        pocket.iconCustom = false;
        pocket.iconKey = PocketIconCatalog.inferKey(
          name: pocket.name,
          isSavings: pocket.isSavings,
        );
      } else {
        pocket.iconCustom = true;
        pocket.iconKey = selected;
      }
    });
  }

  void _onNavTap(int index) {
    _handleNavTap(index);
  }

  Future<void> _handleNavTap(int index) async {
    if (index == 1) return;
    final canLeave = await _canLeaveScreen();
    if (!canLeave) return;
    if (!mounted) return;

    if (widget.onTabSelected != null) {
      widget.onTabSelected!(index);
      return;
    }

    switch (index) {
      case 0:
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      case 1:
        return;
      case 2:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BehaviorReportScreen()),
        );
        return;
    }
  }

  int get _totalPercentage =>
      _pockets.fold<int>(0, (sum, p) => sum + p.percentage);

  int get _savingsPercentage {
    final savings = _pockets.where((p) => p.isSavings).toList();
    if (savings.isEmpty) return 0;
    return savings.first.percentage;
  }

  bool get _hasDraftChanges {
    final editor = _editor;
    if (editor == null) return false;
    if (_planNameController.text.trim() != editor.selectedPlan.name.trim()) {
      return true;
    }
    if (_pockets.length != editor.pockets.length) return true;
    for (var i = 0; i < _pockets.length; i++) {
      if (!_sameDraft(_pockets[i], editor.pockets[i])) return true;
    }
    return false;
  }

  bool _sameDraft(EditablePocketDraft a, EditablePocketDraft b) {
    return a.id == b.id &&
        a.name.trim() == b.name.trim() &&
        a.percentage == b.percentage &&
        a.isSavings == b.isSavings &&
        a.iconKey == b.iconKey &&
        a.iconCustom == b.iconCustom;
  }

  Future<bool> _confirmDiscardChanges() async {
    final discard =
        await showDialog<bool>(
          context: context,
          builder: (_) => const _PlanConfirmDialog(
            title: 'Discard unsaved changes?',
            message:
                'You have unsaved plan edits. Leave this screen and discard them?',
            icon: LucideIcons.info,
            iconColor: AppColors.accentAmber,
            cancelLabel: 'Stay',
            confirmLabel: 'Discard',
            confirmIcon: LucideIcons.chevronRight,
            confirmGradient: false,
          ),
        ) ??
        false;
    return discard;
  }

  Future<bool> _canLeaveScreen() async {
    if (!_hasDraftChanges) return true;
    return _confirmDiscardChanges();
  }

  List<_DonutSegment> get _donutSegments {
    const palette = [
      AppColors.accentBlue,
      AppColors.accentAmber,
      AppColors.accentViolet,
      AppColors.accentRed,
      AppColors.accentTeal,
    ];
    var nonSavings = 0;
    final segments = <_DonutSegment>[];
    for (final pocket in _pockets) {
      final color = pocket.isSavings
          ? AppColors.primary
          : palette[(nonSavings++) % palette.length];
      segments.add(
        _DonutSegment(
          label: pocket.name.trim().isEmpty ? 'Pocket' : pocket.name.trim(),
          percentage: pocket.percentage.clamp(0, 100).toInt(),
          color: color,
          savings: pocket.isSavings,
        ),
      );
    }
    return segments;
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _editor == null
        ? Center(
            child: Padding(
              padding: AppSpacing.page,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WarningCard(
                    message: _error ?? 'Could not load money plans.',
                    type: WarningCardType.error,
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  SecondaryButton(
                    label: 'Retry',
                    icon: LucideIcons.refreshCw,
                    onPressed: () => _load(),
                  ),
                ],
              ),
            ),
          )
        : RefreshIndicator(
            onRefresh: () => _load(),
            child: ListView(
              padding: AppSpacing.page,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        key: ValueKey(_selectedPlanId),
                        initialValue: _selectedPlanId,
                        decoration: const InputDecoration(
                          labelText: 'Active plan',
                        ),
                        items: _editor!.plans
                            .map(
                              (p) => DropdownMenuItem<String>(
                                value: p.id,
                                child: Text(p.name),
                              ),
                            )
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (value) async {
                                if (value == null) return;
                                if (value == _selectedPlanId) return;
                                if (_hasDraftChanges) {
                                  final discard =
                                      await _confirmDiscardChanges();
                                  if (!discard) return;
                                }
                                _activatePlan(value);
                              },
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      AppTextField(
                        controller: _planNameController,
                        label: 'Default plan name',
                        hint: 'My Money Plan',
                        prefixIcon: const Icon(LucideIcons.pencil, size: 18),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      Row(
                        children: [
                          Expanded(
                            child: SecondaryButton(
                              label: 'Create New',
                              icon: LucideIcons.plus,
                              onPressed: _saving ? null : _createPlan,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.x1),
                          Expanded(
                            child: SecondaryButton(
                              label: 'Delete Plan',
                              icon: LucideIcons.trash2,
                              onPressed: _saving || _editor!.plans.length <= 1
                                  ? null
                                  : _deletePlan,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x3),
                Text(
                  'Pocket allocations',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.x2),
                const WarningCard(
                  title: 'Savings rule',
                  message:
                      'Savings must be at least 10%. It stays locked with no expiry timer, but you can change the savings percentage anytime here.',
                  type: WarningCardType.info,
                ),
                const SizedBox(height: AppSpacing.x2),
                if (_hasDraftChanges) ...[
                  const WarningCard(
                    title: 'Unsaved changes',
                    message:
                        'You have edits that are not saved yet. Save before leaving to keep them.',
                    type: WarningCardType.warning,
                  ),
                  const SizedBox(height: AppSpacing.x2),
                ],
                ..._pockets.asMap().entries.map((entry) {
                  final index = entry.key;
                  final pocket = entry.value;
                  final iconMeta = PocketIconCatalog.resolve(
                    isSavings: pocket.isSavings,
                    iconKey: pocket.iconKey,
                    name: pocket.name,
                  );

                  return AppCard(
                    margin: const EdgeInsets.only(bottom: AppSpacing.x2),
                    softShadow: true,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                key: ValueKey('name-${pocket.id ?? index}'),
                                initialValue: pocket.name,
                                label: pocket.isSavings
                                    ? 'Savings pocket'
                                    : 'Pocket name',
                                prefixIcon: Icon(
                                  iconMeta.icon,
                                  size: 18,
                                  color: iconMeta.color,
                                ),
                                onChanged: (v) =>
                                    _onPocketNameChanged(pocket, v),
                              ),
                            ),
                            if (!pocket.isSavings) ...[
                              const SizedBox(width: AppSpacing.x0_5),
                              IconButton(
                                onPressed: _saving
                                    ? null
                                    : () => _pickPocketIcon(index),
                                icon: Icon(
                                  iconMeta.icon,
                                  color: iconMeta.color,
                                ),
                                tooltip: pocket.iconCustom
                                    ? 'Edit custom icon'
                                    : 'Set custom icon',
                              ),
                            ],
                            if (!pocket.isSavings) ...[
                              const SizedBox(width: AppSpacing.x1),
                              IconButton(
                                onPressed: _saving
                                    ? null
                                    : () => _removePocket(index),
                                icon: const Icon(
                                  LucideIcons.trash2,
                                  color: AppColors.accentRed,
                                ),
                                tooltip: 'Remove pocket',
                              ),
                            ],
                          ],
                        ),
                        if (!pocket.isSavings)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              pocket.iconCustom
                                  ? 'Icon: ${iconMeta.label} (custom)'
                                  : 'Icon: ${iconMeta.label} (auto by name)',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.x2),
                        AppTextField(
                          // Include current percentage in key so read-only initialValue
                          // refreshes after in-app keypad edits.
                          key: ValueKey(
                            'pct-${pocket.id ?? index}-${pocket.percentage}',
                          ),
                          initialValue: '${pocket.percentage}',
                          label: 'Allocation %',
                          readOnly: true,
                          showCursor: false,
                          onTap: _saving
                              ? null
                              : () => _editPocketPercentage(index),
                          prefixIcon: const Icon(LucideIcons.percent, size: 18),
                          suffixIcon: const Icon(
                            LucideIcons.chevronDown,
                            size: 16,
                          ),
                        ),
                        if (pocket.balance != 0) ...[
                          const SizedBox(height: AppSpacing.x1),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Balance: KES ${pocket.balance}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                SecondaryButton(
                  label: 'Add Pocket',
                  icon: LucideIcons.plus,
                  onPressed: _saving ? null : _addSpendablePocket,
                ),
                const SizedBox(height: AppSpacing.x2),
                AppCard(
                  softShadow: true,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.piggyBank,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.x1),
                          Text('Savings: $_savingsPercentage%'),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.target,
                            size: 16,
                            color: AppColors.accentPurple,
                          ),
                          const SizedBox(width: AppSpacing.x1),
                          Text('Total: $_totalPercentage%'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x2),
                _AllocationDonutCard(
                  segments: _donutSegments,
                  totalPercentage: _totalPercentage,
                  savingsPercentage: _savingsPercentage,
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.x2),
                  WarningCard(message: _error!, type: WarningCardType.error),
                ],
                const SizedBox(height: AppSpacing.x3),
                PrimaryButton(
                  label: 'Save Plan',
                  icon: LucideIcons.save,
                  loading: _saving,
                  onPressed: _hasDraftChanges ? _savePlan : null,
                ),
                const SizedBox(height: AppSpacing.x3),
              ],
            ),
          );

    return PopScope(
      canPop: !_hasDraftChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final canLeave = await _canLeaveScreen();
        if (!canLeave || !navigator.mounted) return;
        navigator.pop();
      },
      child: AppScaffold(
        title: 'Money Plan',
        body: body,
        bottomNavigation: BottomNav(
          selectedIndex: 1,
          onSelected: _onNavTap,
          items: const [
            BottomNavItem(
              label: 'Pockets',
              icon: LucideIcons.wallet2,
              color: AppColors.primary,
            ),
            BottomNavItem(
              label: 'Plan',
              icon: LucideIcons.settings2,
              color: AppColors.accentBlue,
            ),
            BottomNavItem(
              label: 'Insights',
              icon: LucideIcons.barChart3,
              color: AppColors.accentPurple,
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatePlanDialog extends StatefulWidget {
  const _CreatePlanDialog({required this.initialName});

  final String initialName;

  @override
  State<_CreatePlanDialog> createState() => _CreatePlanDialogState();
}

class _CreatePlanDialogState extends State<_CreatePlanDialog> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _close([String? value]) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.bottomCenter,
      backgroundColor: AppColors.transparent,
      insetPadding: const EdgeInsets.fromLTRB(
        AppSpacing.x3,
        AppSpacing.x3,
        AppSpacing.x3,
        AppSpacing.x1,
      ),
      child: AppCard(
        radius: AppRadius.sheet,
        softShadow: true,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.sparkles, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.x1),
                  Text(
                    'Create Plan',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x1),
              Text(
                'Create a new plan by cloning your current pocket structure.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.x2),
              AppTextField(
                controller: _nameController,
                label: 'Plan name',
                hint: 'Starter Plan',
                prefixIcon: const Icon(LucideIcons.pencil, size: 18),
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.x3),
              SecondaryButton(
                label: 'Cancel',
                icon: LucideIcons.x,
                onPressed: () => _close(),
              ),
              const SizedBox(height: AppSpacing.x1),
              PrimaryButton(
                label: 'Create',
                icon: LucideIcons.plus,
                onPressed: () => _close(_nameController.text.trim()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanConfirmDialog extends StatelessWidget {
  const _PlanConfirmDialog({
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.confirmIcon,
    this.confirmGradient = false,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final String cancelLabel;
  final String confirmLabel;
  final IconData confirmIcon;
  final bool confirmGradient;

  void _close(BuildContext context, [bool value = false]) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
      child: AppCard(
        radius: AppRadius.sheet,
        softShadow: true,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor),
                  const SizedBox(width: AppSpacing.x1),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x1),
              Text(message, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.x3),
              SecondaryButton(
                label: cancelLabel,
                icon: LucideIcons.x,
                onPressed: () => _close(context, false),
              ),
              const SizedBox(height: AppSpacing.x1),
              PrimaryButton(
                label: confirmLabel,
                icon: confirmIcon,
                gradient: confirmGradient,
                onPressed: () => _close(context, true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutSegment {
  const _DonutSegment({
    required this.label,
    required this.percentage,
    required this.color,
    required this.savings,
  });

  final String label;
  final int percentage;
  final Color color;
  final bool savings;
}

class _AllocationDonutCard extends StatelessWidget {
  const _AllocationDonutCard({
    required this.segments,
    required this.totalPercentage,
    required this.savingsPercentage,
  });

  final List<_DonutSegment> segments;
  final int totalPercentage;
  final int savingsPercentage;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      softShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live allocation preview',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.x2),
          Center(
            child: SizedBox(
              width: 170,
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size.square(170),
                    painter: _AllocationDonutPainter(
                      segments: segments,
                      totalPercentage: totalPercentage,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$totalPercentage%',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Savings $savingsPercentage%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          Wrap(
            spacing: AppSpacing.x1,
            runSpacing: AppSpacing.x1,
            children: segments.map((segment) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x1,
                  vertical: AppSpacing.x0_5,
                ),
                decoration: BoxDecoration(
                  color: segment.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: segment.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x0_5),
                    Text(
                      '${segment.label} ${segment.percentage}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: segment.savings
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _AllocationDonutPainter extends CustomPainter {
  const _AllocationDonutPainter({
    required this.segments,
    required this.totalPercentage,
  });

  final List<_DonutSegment> segments;
  final int totalPercentage;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;
    final stroke = radius * 0.22;
    final rect = Rect.fromCircle(center: center, radius: radius - stroke / 2);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..color = AppColors.surfaceMuted;
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    if (totalPercentage <= 0) return;

    final total = totalPercentage.toDouble();
    var startAngle = -math.pi / 2;
    for (final segment in segments) {
      if (segment.percentage <= 0) continue;
      final sweep = (segment.percentage / total) * (math.pi * 2);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke
        ..color = segment.color;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _AllocationDonutPainter oldDelegate) {
    if (oldDelegate.totalPercentage != totalPercentage) return true;
    if (oldDelegate.segments.length != segments.length) return true;
    for (var i = 0; i < segments.length; i++) {
      final left = segments[i];
      final right = oldDelegate.segments[i];
      if (left.label != right.label ||
          left.percentage != right.percentage ||
          left.color != right.color) {
        return true;
      }
    }
    return false;
  }
}

class _PercentageKeypadSheet extends StatefulWidget {
  const _PercentageKeypadSheet({required this.initialValue});

  final int initialValue;

  @override
  State<_PercentageKeypadSheet> createState() => _PercentageKeypadSheetState();
}

class _PercentageKeypadSheetState extends State<_PercentageKeypadSheet> {
  late String _text;

  int get _value => int.tryParse(_text) ?? 0;

  @override
  void initState() {
    super.initState();
    final safe = widget.initialValue.clamp(0, 100);
    _text = safe == 0 ? '' : '$safe';
  }

  void _append(String digit) {
    if (_text.length >= 3) return;
    final next = _text == '0' ? digit : '$_text$digit';
    final parsed = int.tryParse(next);
    if (parsed == null || parsed > 100) return;
    setState(() => _text = next);
  }

  void _clear() {
    if (_text.isEmpty) return;
    setState(() => _text = '');
  }

  void _backspace() {
    if (_text.isEmpty) return;
    setState(() => _text = _text.substring(0, _text.length - 1));
  }

  void _apply() {
    Navigator.of(context).pop(_value.clamp(0, 100));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: AppSpacing.sheet.copyWith(
          bottom:
              AppSpacing.sheet.bottom + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Set allocation percentage',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.x0_5),
              Text(
                'Use in-app keypad (0-100).',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.x2),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.x2),
                softShadow: true,
                child: Center(
                  child: Text(
                    '${_value.clamp(0, 100)}%',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.x1),
              for (final row in const [
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
              ]) ...[
                Row(
                  children: [
                    for (final key in row)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.x0_5),
                          child: _PercentKeyButton(
                            label: key,
                            onTap: () => _append(key),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.x0_5),
                      child: _PercentKeyButton(
                        label: 'C',
                        destructive: true,
                        onTap: _clear,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.x0_5),
                      child: _PercentKeyButton(
                        label: '0',
                        onTap: () => _append('0'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.x0_5),
                      child: _PercentKeyButton(
                        icon: LucideIcons.delete,
                        onTap: _backspace,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x2),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Cancel',
                      icon: LucideIcons.x,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x1),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Apply',
                      icon: LucideIcons.check,
                      onPressed: _apply,
                    ),
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

class _PercentKeyButton extends StatelessWidget {
  const _PercentKeyButton({
    this.label,
    this.icon,
    required this.onTap,
    this.destructive = false,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final fg = destructive ? AppColors.accentRed : AppColors.textPrimary;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderMuted),
          ),
          child: Center(
            child: label != null
                ? Text(
                    label!,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: fg),
                  )
                : Icon(icon, color: fg, size: 20),
          ),
        ),
      ),
    );
  }
}
