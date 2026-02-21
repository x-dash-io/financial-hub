import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.initialValue,
    required this.label,
    this.hint,
    this.keyboardType,
    this.onChanged,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.textAlign = TextAlign.start,
    this.style,
    this.autofocus = false,
    this.enabled = true,
  }) : assert(
         controller == null || initialValue == null,
         'Use either controller or initialValue, not both.',
       );

  final TextEditingController? controller;
  final String? initialValue;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextAlign textAlign;
  final TextStyle? style;
  final bool autofocus;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      autofocus: autofocus,
      enabled: enabled,
      textAlign: textAlign,
      style: style,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
