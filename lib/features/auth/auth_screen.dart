import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_hub/features/auth/mvp_auth_service.dart';
import 'package:financial_hub/shared/models/app_state.dart';
import 'package:financial_hub/shared/theme/app_spacing.dart';
import 'package:financial_hub/shared/theme/app_colors.dart';
import 'package:financial_hub/shared/widgets/app_card.dart';
import 'package:financial_hub/shared/widgets/app_scaffold.dart';
import 'package:financial_hub/shared/widgets/app_text_field.dart';
import 'package:financial_hub/shared/widgets/primary_button.dart';
import 'package:financial_hub/shared/widgets/warning_card.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.onSuccess, this.initialError});

  final VoidCallback onSuccess;
  final String? initialError;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _mvpAuth = MvpAuthService();
  String _countryCode = '+254';
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _error = widget.initialError;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final fullPhone =
        '$_countryCode${_phoneController.text.trim().replaceFirst(RegExp(r'^0'), '')}';
    try {
      await _mvpAuth.ensureSessionAndProfile(phone: fullPhone);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppStateKeys.phone, fullPhone);

      if (!mounted) return;
      setState(() => _loading = false);
      widget.onSuccess();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'Could not create your MVP session. Enable Anonymous Sign-Ins in Supabase Auth and try again.';
      });
    }
  }

  static bool _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    final digits = value.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) return false;
    if (digits.length > 15) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      safeArea: true,
      body: Center(
        child: Padding(
          padding: AppSpacing.page,
          child: Form(
            key: _formKey,
            child: AppCard(
              padding: AppSpacing.page,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.sparkles,
                        color: AppColors.accentPurple,
                      ),
                      const SizedBox(width: AppSpacing.x1),
                      Text(
                        'Register with phone',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x1),
                  Text(
                    'Enter your phone number to continue. OTP is temporarily disabled in this build.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CountryCodePicker(
                        onChanged: (code) => setState(
                          () => _countryCode = code.dialCode ?? '+254',
                        ),
                        initialSelection: 'KE',
                        showCountryOnly: false,
                        showOnlyCountryWhenClosed: false,
                        favorite: const ['+254', '+255', '+256', '+250'],
                        alignLeft: false,
                      ),
                      const SizedBox(width: AppSpacing.x1),
                      Expanded(
                        child: AppTextField(
                          controller: _phoneController,
                          label: 'Phone number',
                          hint: '712345678',
                          keyboardType: TextInputType.phone,
                          prefixIcon: const Icon(
                            LucideIcons.phone,
                            size: 18,
                            color: AppColors.accentBlue,
                          ),
                          validator: (v) => _validatePhone(v)
                              ? null
                              : 'Enter a valid phone number (7-15 digits)',
                        ),
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.x2),
                    WarningCard(message: _error!, type: WarningCardType.error),
                  ],
                  const SizedBox(height: AppSpacing.x3),
                  PrimaryButton(
                    label: 'Register',
                    icon: LucideIcons.arrowRight,
                    loading: _loading,
                    onPressed: _register,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
