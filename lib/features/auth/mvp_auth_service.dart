import 'package:financial_hub/core/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Temporary MVP auth: anonymous Supabase session + phone capture (no OTP).
class MvpAuthService {
  Future<void> ensureSessionAndProfile({String? phone}) async {
    await _ensureSession();
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw StateError('Failed to create an authenticated session.');
    }

    final normalizedPhone = _normalizePhone(phone);
    var profile = await _getProfileByUserId(user.id);
    if (profile == null) {
      profile = await _createProfile(userId: user.id, phone: normalizedPhone);
    } else {
      await _updatePhoneIfNeeded(
        profileId: profile['id'] as String,
        currentPhone: profile['phone'] as String?,
        nextPhone: normalizedPhone,
      );
    }

    await _ensureDefaultPlan(
      profileId: profile['id'] as String,
      defaultPlanId: profile['default_plan_id'] as String?,
    );
  }

  Future<void> _ensureSession() async {
    if (supabase.auth.currentSession != null &&
        supabase.auth.currentUser != null) {
      return;
    }
    await supabase.auth.signInAnonymously();
  }

  Future<Map<String, dynamic>?> _getProfileByUserId(String userId) async {
    return await supabase
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
  }

  Future<Map<String, dynamic>> _createProfile({
    required String userId,
    String? phone,
  }) async {
    try {
      return await supabase
          .from('profiles')
          .insert({'user_id': userId, 'phone': phone})
          .select()
          .single();
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        final existing = await _getProfileByUserId(userId);
        if (existing != null) return existing;
      }
      rethrow;
    }
  }

  Future<void> _updatePhoneIfNeeded({
    required String profileId,
    required String? currentPhone,
    required String? nextPhone,
  }) async {
    if (nextPhone == null || nextPhone == currentPhone) return;
    await supabase
        .from('profiles')
        .update({'phone': nextPhone})
        .eq('id', profileId);
  }

  Future<void> _ensureDefaultPlan({
    required String profileId,
    required String? defaultPlanId,
  }) async {
    final rows = await supabase
        .from('money_plans')
        .select('id')
        .eq('profile_id', profileId)
        .order('created_at', ascending: true);
    final plans = (rows as List).cast<Map<String, dynamic>>();

    String? resolvedPlanId = defaultPlanId;
    if (plans.isEmpty) {
      resolvedPlanId = await _createDefaultPlan(profileId);
    } else {
      final hasDefault =
          resolvedPlanId != null && plans.any((p) => p['id'] == resolvedPlanId);
      if (!hasDefault) {
        resolvedPlanId = plans.first['id'] as String;
      }
    }

    if (resolvedPlanId != defaultPlanId) {
      await supabase
          .from('profiles')
          .update({'default_plan_id': resolvedPlanId})
          .eq('id', profileId);
    }
  }

  Future<String> _createDefaultPlan(String profileId) async {
    final plan = await supabase
        .from('money_plans')
        .insert({
          'profile_id': profileId,
          'name': 'Default Plan',
          'is_active': true,
        })
        .select('id')
        .single();
    final planId = plan['id'] as String;

    final pockets = await supabase
        .from('pockets')
        .insert([
          {
            'profile_id': profileId,
            'plan_id': planId,
            'name': 'Savings',
            'is_savings': true,
          },
          {
            'profile_id': profileId,
            'plan_id': planId,
            'name': 'Transport',
            'is_savings': false,
          },
          {
            'profile_id': profileId,
            'plan_id': planId,
            'name': 'Food',
            'is_savings': false,
          },
          {
            'profile_id': profileId,
            'plan_id': planId,
            'name': 'Other',
            'is_savings': false,
          },
        ])
        .select('id,name');

    final byName = <String, String>{
      for (final row in (pockets as List).cast<Map<String, dynamic>>())
        row['name'] as String: row['id'] as String,
    };

    await supabase.from('money_plan_allocations').insert([
      {'plan_id': planId, 'pocket_id': byName['Savings'], 'percentage': 50},
      {'plan_id': planId, 'pocket_id': byName['Transport'], 'percentage': 20},
      {'plan_id': planId, 'pocket_id': byName['Food'], 'percentage': 20},
      {'plan_id': planId, 'pocket_id': byName['Other'], 'percentage': 10},
    ]);

    return planId;
  }

  String? _normalizePhone(String? phone) {
    final trimmed = phone?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
