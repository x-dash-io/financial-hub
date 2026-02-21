import 'package:financial_hub/features/money_plan/money_plan_repository.dart';
import 'package:financial_hub/shared/models/money_plan.dart';
import 'package:financial_hub/shared/models/money_plan_allocation.dart';
import 'package:financial_hub/shared/models/pocket.dart';

class EditablePocketDraft {
  String? id;
  String name;
  int percentage;
  bool isSavings;
  int balance;

  EditablePocketDraft({
    this.id,
    required this.name,
    required this.percentage,
    required this.isSavings,
    this.balance = 0,
  });

  EditablePocketDraft copy() {
    return EditablePocketDraft(
      id: id,
      name: name,
      percentage: percentage,
      isSavings: isSavings,
      balance: balance,
    );
  }
}

class MoneyPlanEditorState {
  final String profileId;
  final String? defaultPlanId;
  final List<MoneyPlan> plans;
  final MoneyPlan selectedPlan;
  final List<EditablePocketDraft> pockets;

  const MoneyPlanEditorState({
    required this.profileId,
    required this.defaultPlanId,
    required this.plans,
    required this.selectedPlan,
    required this.pockets,
  });
}

class MoneyPlanService {
  final MoneyPlanRepository _repo;

  MoneyPlanService({MoneyPlanRepository? repository})
    : _repo = repository ?? MoneyPlanRepository();

  Future<MoneyPlanEditorState?> load({String? selectedPlanId}) async {
    final profile = await _repo.getProfile();
    if (profile == null) return null;

    final profileId = profile['id'] as String;
    final defaultPlanId = profile['default_plan_id'] as String?;

    var plans = await _repo.getPlans(profileId);
    if (plans.isEmpty) {
      final fallbackPlanId = await createPlan(
        profileId: profileId,
        name: 'Default Plan',
        pockets: [
          EditablePocketDraft(name: 'Savings', percentage: 10, isSavings: true),
          EditablePocketDraft(
            name: 'Transport',
            percentage: 30,
            isSavings: false,
          ),
          EditablePocketDraft(name: 'Food', percentage: 30, isSavings: false),
          EditablePocketDraft(name: 'Other', percentage: 30, isSavings: false),
        ],
      );
      plans = await _repo.getPlans(profileId);
      return load(selectedPlanId: fallbackPlanId);
    }

    final chosenPlanId =
        selectedPlanId ??
        defaultPlanId ??
        plans.firstWhere((p) => p.isActive, orElse: () => plans.first).id;

    final selectedPlan = plans.firstWhere(
      (p) => p.id == chosenPlanId,
      orElse: () => plans.first,
    );

    final pockets = await _repo.getPockets(selectedPlan.id);
    final allocations = await _repo.getAllocations(selectedPlan.id);

    return MoneyPlanEditorState(
      profileId: profileId,
      defaultPlanId: defaultPlanId,
      plans: plans,
      selectedPlan: selectedPlan,
      pockets: _mergePocketsWithAllocations(pockets, allocations),
    );
  }

  Future<void> setActivePlan({
    required String profileId,
    required String planId,
    required String planName,
  }) async {
    await _repo.setPlanActive(profileId: profileId, planId: planId);
    await _repo.logPlanModification(
      profileId: profileId,
      payload: {'action': 'activate', 'plan_id': planId, 'plan_name': planName},
    );
  }

  Future<void> updatePlan({
    required String profileId,
    required String planId,
    required String planName,
    required List<EditablePocketDraft> pockets,
  }) async {
    final error = validatePockets(pockets);
    if (error != null) {
      throw StateError(error);
    }

    final normalizedPlanName = _normalizePlanName(planName);
    await _repo.updatePlanName(planId: planId, name: normalizedPlanName);

    final existingPockets = await _repo.getPockets(planId);
    final incomingById = {
      for (final p in pockets)
        if (p.id != null) p.id!: p,
    };

    for (final existing in existingPockets) {
      if (!incomingById.containsKey(existing.id)) {
        final hasTransactions = await _repo.hasTransactions(existing.id);
        if (hasTransactions || existing.balance != 0) {
          throw StateError(
            'Cannot delete pocket "${existing.name}" with existing balance/history.',
          );
        }
        await _repo.deletePocket(existing.id);
      }
    }

    final pocketIdsByDraft = <EditablePocketDraft, String>{};
    for (final draft in pockets) {
      if (draft.id != null) {
        await _repo.updatePocket(
          pocketId: draft.id!,
          name: draft.name.trim(),
          isSavings: draft.isSavings,
        );
        pocketIdsByDraft[draft] = draft.id!;
      } else {
        final createdId = await _repo.createPocket(
          profileId: profileId,
          planId: planId,
          name: draft.name.trim(),
          isSavings: draft.isSavings,
        );
        draft.id = createdId;
        pocketIdsByDraft[draft] = createdId;
      }
    }

    await _repo.replaceAllocations(
      planId: planId,
      allocations: pockets
          .map(
            (p) => {
              'plan_id': planId,
              'pocket_id': pocketIdsByDraft[p],
              'percentage': p.percentage,
            },
          )
          .toList(),
    );

    await _repo.logPlanModification(
      profileId: profileId,
      payload: {
        'action': 'update',
        'plan_id': planId,
        'plan_name': normalizedPlanName,
        'allocations': pockets
            .map(
              (p) => {
                'name': p.name.trim(),
                'percentage': p.percentage,
                'is_savings': p.isSavings,
              },
            )
            .toList(),
      },
    );
  }

  Future<String> createPlan({
    required String profileId,
    required String name,
    required List<EditablePocketDraft> pockets,
  }) async {
    final error = validatePockets(pockets);
    if (error != null) {
      throw StateError(error);
    }

    final planName = name.trim().isEmpty ? 'New Plan' : name.trim();
    final planId = await _repo.createPlan(profileId: profileId, name: planName);

    final allocations = <Map<String, dynamic>>[];
    for (final p in pockets) {
      final pocketId = await _repo.createPocket(
        profileId: profileId,
        planId: planId,
        name: p.name.trim(),
        isSavings: p.isSavings,
      );
      allocations.add({
        'plan_id': planId,
        'pocket_id': pocketId,
        'percentage': p.percentage,
      });
    }

    await _repo.replaceAllocations(planId: planId, allocations: allocations);
    await _repo.setPlanActive(profileId: profileId, planId: planId);

    await _repo.logPlanModification(
      profileId: profileId,
      payload: {
        'action': 'create',
        'plan_id': planId,
        'plan_name': planName,
        'allocations': pockets
            .map(
              (p) => {
                'name': p.name.trim(),
                'percentage': p.percentage,
                'is_savings': p.isSavings,
              },
            )
            .toList(),
      },
    );

    return planId;
  }

  String _normalizePlanName(String input) {
    final name = input.trim();
    if (name.isEmpty) return 'Default Plan';
    return name;
  }

  Future<String> deletePlan({
    required String profileId,
    required String planId,
  }) async {
    final plans = await _repo.getPlans(profileId);
    if (plans.length <= 1) {
      throw StateError('At least one plan must exist.');
    }

    final deleted = plans.firstWhere(
      (p) => p.id == planId,
      orElse: () => throw StateError('Plan not found.'),
    );

    final fallback = plans.firstWhere((p) => p.id != planId);

    await _repo.deletePlan(planId);
    await _repo.setPlanActive(profileId: profileId, planId: fallback.id);

    await _repo.logPlanModification(
      profileId: profileId,
      payload: {
        'action': 'delete',
        'plan_id': deleted.id,
        'plan_name': deleted.name,
        'fallback_plan_id': fallback.id,
      },
    );

    return fallback.id;
  }

  static String? validatePockets(List<EditablePocketDraft> pockets) {
    if (pockets.isEmpty) {
      return 'Add at least one pocket.';
    }

    var total = 0;
    var savingsPercent = 0;
    var savingsCount = 0;
    var spendableCount = 0;
    final seenNames = <String>{};

    for (final p in pockets) {
      final name = p.name.trim();
      if (name.isEmpty) return 'Pocket names cannot be empty.';
      final key = name.toLowerCase();
      if (!seenNames.add(key)) {
        return 'Pocket names must be unique.';
      }
      if (p.percentage < 0 || p.percentage > 100) {
        return 'Percentages must be between 0 and 100.';
      }
      total += p.percentage;
      if (p.isSavings) {
        savingsCount++;
        savingsPercent += p.percentage;
      } else {
        spendableCount++;
      }
    }

    if (savingsCount != 1) {
      return 'Exactly one Savings pocket is required.';
    }
    if (savingsPercent < 10) {
      return 'Savings must be at least 10%.';
    }
    if (spendableCount < 1) {
      return 'Add at least one spendable pocket.';
    }
    if (total != 100) {
      return 'Total percentage must equal 100% (currently $total%).';
    }

    return null;
  }

  List<EditablePocketDraft> _mergePocketsWithAllocations(
    List<Pocket> pockets,
    List<MoneyPlanAllocation> allocations,
  ) {
    final allocationByPocket = {
      for (final a in allocations) a.pocketId: a.percentage,
    };

    final drafts = pockets
        .map(
          (p) => EditablePocketDraft(
            id: p.id,
            name: p.name,
            isSavings: p.isSavings,
            percentage: allocationByPocket[p.id] ?? 0,
            balance: p.balance,
          ),
        )
        .toList();

    drafts.sort((a, b) {
      if (a.isSavings == b.isSavings) return 0;
      return a.isSavings ? -1 : 1;
    });
    return drafts;
  }
}
