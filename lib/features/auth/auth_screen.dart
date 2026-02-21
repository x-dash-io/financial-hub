import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_hub/core/app_logger.dart';
import 'package:financial_hub/features/auth/mvp_auth_service.dart';
import 'package:financial_hub/shared/models/app_state.dart';
import 'package:financial_hub/shared/theme/app_radius.dart';
import 'package:financial_hub/shared/theme/app_spacing.dart';
import 'package:financial_hub/shared/theme/app_colors.dart';
import 'package:financial_hub/shared/widgets/app_card.dart';
import 'package:financial_hub/shared/widgets/app_number_keypad.dart';
import 'package:financial_hub/shared/widgets/app_scaffold.dart';
import 'package:financial_hub/shared/widgets/app_text_field.dart';
import 'package:financial_hub/shared/widgets/primary_button.dart';
import 'package:financial_hub/shared/widgets/secondary_button.dart';
import 'package:financial_hub/shared/widgets/warning_card.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.onSuccess,
    this.initialError,
    this.onBackToOnboarding,
  });

  final VoidCallback onSuccess;
  final String? initialError;
  final VoidCallback? onBackToOnboarding;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const int _maxPhoneDigits = 15;

  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode(canRequestFocus: false);
  final _mvpAuth = MvpAuthService();
  String _countryCode = '+254';
  int _step = 0;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _error = widget.initialError;
  }

  @override
  void dispose() {
    _phoneFocusNode.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _normalizedLocalPhone() {
    final digits = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    return digits.replaceFirst(RegExp(r'^0+'), '');
  }

  String get _fullPhonePreview {
    final local = _normalizedLocalPhone();
    if (local.isEmpty) return '$_countryCode ...';
    return '$_countryCode$local';
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final fullPhone = '$_countryCode${_normalizedLocalPhone()}';
    try {
      await _mvpAuth.ensureSessionAndProfile(phone: fullPhone);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppStateKeys.phone, fullPhone);

      if (!mounted) return;
      setState(() => _loading = false);
      widget.onSuccess();
    } catch (e, st) {
      AppLogger.error('Registration failed', e, st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'Could not create your MVP session. Enable Anonymous Sign-Ins in Supabase Auth and try again.';
      });
    }
  }

  void _goToPhoneStep() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _step = 1;
      _error = null;
    });
  }

  void _goBack() {
    if (_step > 0) {
      setState(() {
        _step = 0;
        _error = null;
      });
      return;
    }
    widget.onBackToOnboarding?.call();
  }

  static bool _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    final digits = value.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) return false;
    if (digits.length > 15) return false;
    return true;
  }

  void _appendPhoneDigit(String digit) {
    if (_loading) return;
    final current = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (current.length >= _maxPhoneDigits) return;
    setState(() {
      _phoneController.text = '$current$digit';
      _error = null;
    });
  }

  void _backspacePhoneDigit() {
    if (_loading) return;
    final current = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (current.isEmpty) return;
    setState(() {
      _phoneController.text = current.substring(0, current.length - 1);
      _error = null;
    });
  }

  void _clearPhoneDigits() {
    if (_loading || _phoneController.text.isEmpty) return;
    setState(() {
      _phoneController.clear();
      _error = null;
    });
  }

  Widget _buildIntroStep(BuildContext context) {
    return AppCard(
      key: const ValueKey('auth-intro'),
      padding: AppSpacing.page,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.shieldCheck, color: AppColors.primary),
              const SizedBox(width: AppSpacing.x1),
              Expanded(
                child: Text(
                  'Welcome to Financial Hub',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x1),
          Text(
            'Register with your phone number to continue. Your country code is included in the saved number.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.x2),
          const WarningCard(
            title: 'Simple auth flow',
            message:
                'Step 1: confirm setup. Step 2: select country code + phone number and register.',
            type: WarningCardType.info,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.x2),
            WarningCard(message: _error!, type: WarningCardType.error),
          ],
          const SizedBox(height: AppSpacing.x3),
          PrimaryButton(
            label: 'Continue',
            icon: LucideIcons.arrowRight,
            onPressed: _goToPhoneStep,
          ),
          if (widget.onBackToOnboarding != null) ...[
            const SizedBox(height: AppSpacing.x1),
            SecondaryButton(
              label: 'Back to onboarding',
              icon: LucideIcons.chevronLeft,
              onPressed: widget.onBackToOnboarding,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhoneStep(BuildContext context) {
    return Form(
      key: _formKey,
      child: AppCard(
        key: const ValueKey('auth-phone'),
        padding: AppSpacing.page,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.phone, color: AppColors.accentBlue),
                const SizedBox(width: AppSpacing.x1),
                Text(
                  'Register with phone',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x1),
            Text(
              'Choose country code, enter your number, then register.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.x2),
            Text(
              'Country code',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.x1),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppRadius.input),
                color: AppColors.surface,
              ),
              child: CountryCodePicker(
                onChanged: (code) =>
                    setState(() => _countryCode = code.dialCode ?? '+254'),
                initialSelection: 'KE',
                showCountryOnly: false,
                showOnlyCountryWhenClosed: false,
                favorite: const ['+254', '+255', '+256', '+250'],
                alignLeft: true,
                textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                dialogTextStyle: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
                searchStyle: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
                dialogBackgroundColor: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x1),
              ),
            ),
            const SizedBox(height: AppSpacing.x2),
            AppTextField(
              controller: _phoneController,
              label: 'Phone number',
              hint: '712345678',
              keyboardType: TextInputType.none,
              focusNode: _phoneFocusNode,
              readOnly: true,
              showCursor: false,
              enableInteractiveSelection: false,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              prefixIcon: const Icon(
                LucideIcons.phone,
                size: 18,
                color: AppColors.accentBlue,
              ),
              validator: (v) => _validatePhone(v)
                  ? null
                  : 'Enter a valid phone number (7-15 digits)',
            ),
            const SizedBox(height: AppSpacing.x1),
            Text(
              'Use in-app keypad',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.x0_5),
            AppNumberKeypad(
              enabled: !_loading,
              onDigit: _appendPhoneDigit,
              onBackspace: _backspacePhoneDigit,
              onClear: _clearPhoneDigits,
            ),
            const SizedBox(height: AppSpacing.x2),
            WarningCard(
              title: 'Will register as',
              message: _fullPhonePreview,
              type: WarningCardType.info,
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.x2),
              WarningCard(message: _error!, type: WarningCardType.error),
            ],
            const SizedBox(height: AppSpacing.x3),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Back',
                    icon: LucideIcons.chevronLeft,
                    onPressed: _loading ? null : _goBack,
                  ),
                ),
                const SizedBox(width: AppSpacing.x1),
                Expanded(
                  child: PrimaryButton(
                    label: 'Register',
                    icon: LucideIcons.arrowRight,
                    loading: _loading,
                    onPressed: _register,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      safeArea: true,
      body: Center(
        child: Padding(
          padding: AppSpacing.page,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
            child: _step == 0
                ? _buildIntroStep(context)
                : _buildPhoneStep(context),
          ),
        ),
      ),
    );
  }
}
