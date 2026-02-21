import 'package:financial_hub/core/supabase_client.dart';
import 'package:financial_hub/shared/models/pocket.dart';
import 'package:financial_hub/shared/models/money_plan_allocation.dart';

class PocketsRepository {
  Future<Map<String, dynamic>?> getProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;
    final res = await supabase
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return res;
  }

  Future<List<Pocket>> getPockets(String planId) async {
    final res = await supabase
        .from('pockets')
        .select()
        .eq('plan_id', planId)
        .order('is_savings', ascending: false);
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

  Future<int> getPocketBalance(String pocketId) async {
    final res = await supabase
        .from('pockets')
        .select('cached_balance')
        .eq('id', pocketId)
        .maybeSingle();
    final bal = res?['cached_balance'] ?? res?['balance'];
    return (bal as num?)?.toInt() ?? 0;
  }
}
