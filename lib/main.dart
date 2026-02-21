import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:financial_hub/core/supabase_client.dart';
import 'package:financial_hub/features/auth/auth_gate.dart';
import 'package:financial_hub/shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await initSupabase();
  runApp(const FinancialHubApp());
}

class FinancialHubApp extends StatelessWidget {
  const FinancialHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Financial Hub',
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}
