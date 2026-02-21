import 'package:flutter/material.dart';
import 'package:financial_hub/shared/theme/app_colors.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    this.actions,
    required this.body,
    this.bottomNavigation,
    this.floatingActionButton,
    this.backgroundGradient,
    this.safeArea = true,
  });

  final String? title;
  final List<Widget>? actions;
  final Widget body;
  final Widget? bottomNavigation;
  final Widget? floatingActionButton;
  final Gradient? backgroundGradient;
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        gradient:
            backgroundGradient ??
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.backgroundTop, AppColors.background],
            ),
      ),
      child: safeArea ? SafeArea(child: body) : body,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: title == null
          ? null
          : AppBar(title: Text(title!), actions: actions),
      body: content,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigation,
    );
  }
}
