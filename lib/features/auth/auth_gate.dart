import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_hub/core/supabase_client.dart';
import 'package:financial_hub/features/auth/mvp_auth_service.dart';
import 'package:financial_hub/shared/models/app_state.dart';
import 'package:financial_hub/features/onboarding/onboarding_screen.dart';
import 'package:financial_hub/features/auth/auth_screen.dart';
import 'package:financial_hub/features/pockets/pockets_screen.dart';
import 'package:financial_hub/shared/widgets/app_scaffold.dart';

/// Root gate: onboarding -> auth -> app
/// MVP auth: phone capture + anonymous Supabase session (no OTP/Twilio).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _mvpAuth = MvpAuthService();
  bool _onboardingComplete = false;
  bool _checking = true;
  String? _storedPhone;
  String? _bootstrapError;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete =
        prefs.getBool(AppStateKeys.onboardingComplete) ?? false;
    var storedPhone = prefs.getString(AppStateKeys.phone);
    String? bootstrapError;

    if (onboardingComplete && storedPhone != null && storedPhone.isNotEmpty) {
      try {
        await _mvpAuth.ensureSessionAndProfile(phone: storedPhone);
      } catch (_) {
        bootstrapError =
            'Could not restore your MVP session. Register again to continue.';
        storedPhone = null;
        await prefs.remove(AppStateKeys.phone);
        await supabase.auth.signOut();
      }
    }

    if (!mounted) return;
    setState(() {
      _onboardingComplete = onboardingComplete;
      _storedPhone = storedPhone;
      _bootstrapError = bootstrapError;
      _checking = false;
    });
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppStateKeys.onboardingComplete, true);
    setState(() => _onboardingComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const AppScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_onboardingComplete) {
      return OnboardingScreen(onComplete: _completeOnboarding);
    }
    // Phone registration + anonymous Supabase session: treat stored phone as logged in.
    if (_storedPhone == null || _storedPhone!.isEmpty) {
      return AuthScreen(
        onSuccess: () => _loadState(),
        initialError: _bootstrapError,
      );
    }
    return PocketsScreen(
      onLogout: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(AppStateKeys.phone);
        await supabase.auth.signOut();
        if (mounted) _loadState();
      },
    );

    // --- OTP phone auth path for future Twilio rollout ---
    // final session = supabase.auth.currentSession;
    // if (session == null) {
    //   return AuthScreen(onSuccess: () => setState(() {}));
    // }
    // return const PocketsScreen();
  }
}
