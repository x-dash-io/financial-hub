import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:financial_hub/features/behavior/behavior_report_screen.dart';
import 'package:financial_hub/features/money_plan/money_plan_service.dart';
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
  const MoneyPlanScreen({super.key, this.onPlanChanged});

  final VoidCallback? onPlanChanged;

  @override
  State<MoneyPlanScreen> createState() => _MoneyPlanScreenState();
}

class _MoneyPlanScreenState extends State<MoneyPlanScreen> {
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
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
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

    final nameController = TextEditingController(text: 'New Plan');
    final newPlanName = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Create Plan'),
          content: AppTextField(
            controller: nameController,
            label: 'Plan name',
            hint: 'Starter Plan',
            prefixIcon: const Icon(LucideIcons.pencil, size: 18),
            autofocus: true,
          ),
          actions: [
            SecondaryButton(
              label: 'Cancel',
              icon: LucideIcons.x,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            PrimaryButton(
              label: 'Create',
              icon: LucideIcons.plus,
              onPressed: () =>
                  Navigator.of(ctx).pop(nameController.text.trim()),
            ),
          ],
        );
      },
    );
    nameController.dispose();

    if (newPlanName == null || newPlanName.isEmpty) return;

    final clonedPockets = _pockets
        .map(
          (p) => EditablePocketDraft(
            name: p.name,
            percentage: p.percentage,
            isSavings: p.isSavings,
            balance: 0,
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
    } catch (e) {
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
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Plan'),
            content: const Text('Delete this plan? This cannot be undone.'),
            actions: [
              SecondaryButton(
                label: 'Cancel',
                icon: LucideIcons.x,
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
              PrimaryButton(
                label: 'Delete',
                icon: LucideIcons.trash2,
                gradient: false,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ],
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll(RegExp(r'Exception:?'), '').trim();
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addSpendablePocket() {
    setState(() {
      _pockets.add(
        EditablePocketDraft(
          name: 'Pocket ${_pockets.where((p) => !p.isSavings).length + 1}',
          percentage: 0,
          isSavings: false,
        ),
      );
    });
  }

  void _removePocket(int index) {
    setState(() {
      _pockets.removeAt(index);
    });
  }

  void _onNavTap(int index) {
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
                            : (value) {
                                if (value == null) return;
                                _activatePlan(value);
                              },
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      AppTextField(
                        controller: _planNameController,
                        label: 'Default plan name',
                        hint: 'My Money Plan',
                        prefixIcon: const Icon(LucideIcons.pencil, size: 18),
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
                ..._pockets.asMap().entries.map((entry) {
                  final index = entry.key;
                  final pocket = entry.value;

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
                                  pocket.isSavings
                                      ? LucideIcons.piggyBank
                                      : LucideIcons.wallet2,
                                  size: 18,
                                  color: pocket.isSavings
                                      ? AppColors.primary
                                      : AppColors.accentBlue,
                                ),
                                onChanged: (v) => pocket.name = v,
                              ),
                            ),
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
                        const SizedBox(height: AppSpacing.x2),
                        AppTextField(
                          key: ValueKey('pct-${pocket.id ?? index}'),
                          initialValue: '${pocket.percentage}',
                          keyboardType: TextInputType.number,
                          label: 'Allocation %',
                          prefixIcon: const Icon(LucideIcons.percent, size: 18),
                          onChanged: (v) {
                            final parsed = int.tryParse(v.trim()) ?? 0;
                            setState(() => pocket.percentage = parsed);
                          },
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
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.x2),
                  WarningCard(message: _error!, type: WarningCardType.error),
                ],
                const SizedBox(height: AppSpacing.x3),
                PrimaryButton(
                  label: 'Save Plan',
                  icon: LucideIcons.save,
                  loading: _saving,
                  onPressed: _savePlan,
                ),
                const SizedBox(height: AppSpacing.x3),
              ],
            ),
          );

    return AppScaffold(
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
    );
  }
}
