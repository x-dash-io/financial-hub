import 'package:financial_hub/core/supabase_client.dart';
import 'package:financial_hub/shared/models/money_plan.dart';
import 'package:financial_hub/shared/models/money_plan_allocation.dart';
import 'package:financial_hub/shared/models/pocket.dart';

class MoneyPlanRepository {
  Future<Map<String, dynamic>?> getProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;
    final profile = await supabase
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return profile;
  }

  Future<List<MoneyPlan>> getPlans(String profileId) async {
    final res = await supabase
        .from('money_plans')
        .select()
        .eq('profile_id', profileId)
        .order('created_at', ascending: true);
    return (res as List)
        .map((e) => MoneyPlan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>?> getPlanRaw(String planId) async {
    return await supabase
        .from('money_plans')
        .select()
        .eq('id', planId)
        .maybeSingle();
  }

  Future<List<Pocket>> getPockets(String planId) async {
    final res = await supabase
        .from('pockets')
        .select()
        .eq('plan_id', planId)
        .order('is_savings', ascending: false)
        .order('created_at', ascending: true);
    return (res as List)
        .map((e) => Pocket.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MoneyPlanAllocation>> getAllocations(String planId) async {
    final res = await supabase
        .from('money_plan_allocations')
        .select()
        .eq('plan_id', planId);
    return (res as List)
        .map((e) => MoneyPlanAllocation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> createPlan({
    required String profileId,
    required String name,
  }) async {
    final res = await supabase
        .from('money_plans')
        .insert({'profile_id': profileId, 'name': name, 'is_active': true})
        .select('id')
        .single();
    return res['id'] as String;
  }

  Future<void> updatePlanName({
    required String planId,
    required String name,
  }) async {
    await supabase.from('money_plans').update({'name': name}).eq('id', planId);
  }

  Future<void> setPlanActive({
    required String profileId,
    required String planId,
  }) async {
    await supabase
        .from('money_plans')
        .update({'is_active': false})
        .eq('profile_id', profileId);
    await supabase
        .from('money_plans')
        .update({'is_active': true})
        .eq('id', planId);
    await supabase
        .from('profiles')
        .update({'default_plan_id': planId})
        .eq('id', profileId);
  }

  Future<String> createPocket({
    required String profileId,
    required String planId,
    required String name,
    required bool isSavings,
    String? iconKey,
    bool iconCustom = false,
  }) async {
    final res = await supabase
        .from('pockets')
        .insert({
          'profile_id': profileId,
          'plan_id': planId,
          'name': name,
          'is_savings': isSavings,
          'icon_key': iconKey,
          'icon_custom': iconCustom,
        })
        .select('id')
        .single();
    return res['id'] as String;
  }

  Future<void> updatePocket({
    required String pocketId,
    required String name,
    required bool isSavings,
    String? iconKey,
    bool iconCustom = false,
  }) async {
    await supabase
        .from('pockets')
        .update({
          'name': name,
          'is_savings': isSavings,
          'icon_key': iconKey,
          'icon_custom': iconCustom,
        })
        .eq('id', pocketId);
  }

  Future<void> deletePocket(String pocketId) async {
    await supabase
        .from('money_plan_allocations')
        .delete()
        .eq('pocket_id', pocketId);
    await supabase.from('pockets').delete().eq('id', pocketId);
  }

  Future<bool> hasTransactions(String pocketId) async {
    final rows = await supabase
        .from('transactions')
        .select('id')
        .eq('pocket_id', pocketId)
        .limit(1);
    return (rows as List).isNotEmpty;
  }

  Future<void> replaceAllocations({
    required String planId,
    required List<Map<String, dynamic>> allocations,
  }) async {
    await supabase
        .from('money_plan_allocations')
        .delete()
        .eq('plan_id', planId);
    await supabase.from('money_plan_allocations').insert(allocations);
  }

  Future<void> deletePlan(String planId) async {
    await supabase.from('money_plans').delete().eq('id', planId);
  }

  Future<void> logPlanModification({
    required String profileId,
    required Map<String, dynamic> payload,
  }) async {
    await supabase.from('behavioral_events').insert({
      'profile_id': profileId,
      'event_type': 'plan_modification',
      'payload': payload,
    });
  }
}
