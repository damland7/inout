import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Text field used by every form in the app (S01–S04, S07, S08, S11).
///
/// Shows a label, optional helper text, inline validation errors and, for
/// passwords, a show/hide button. Colours come from the shared theme.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
    this.helperText,
    this.hintText,
    this.suffixText,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.isPassword = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofillHints,
    this.inputFormatters,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final String? helperText;
  final String? hintText;
  final String? suffixText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool isPassword;
  final bool enabled;
  final bool readOnly;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    final password = widget.isPassword;
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      keyboardType: password ? TextInputType.visiblePassword : widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      obscureText: password && _hidden,
      enableSuggestions: !password,
      autocorrect: !password,
      autofillHints: widget.autofillHints,
      inputFormatters: widget.inputFormatters,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
        helperText: widget.helperText,
        helperMaxLines: 2,
        errorMaxLines: 2,
        suffixText: widget.suffixText,
        suffixIcon: password
            ? IconButton(
                tooltip: _hidden ? 'Show password' : 'Hide password',
                icon: Icon(
                  _hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _hidden = !_hidden),
              )
            : null,
      ),
    );
  }
}

enum AppButtonVariant { primary, outline, danger, text }

/// Full-width button with the app's four styles. While [loading] is true it
/// shows a spinner and ignores taps.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;

  static const _minSize = Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final VoidCallback? tap = loading ? null : onPressed;
    final Widget child = loading
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              semanticsLabel: '$label, loading',
              strokeWidth: 2.4,
              color: variant == AppButtonVariant.primary
                  ? scheme.onPrimary
                  : scheme.primary,
            ),
          )
        : Text(label, textAlign: TextAlign.center);
    return switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: tap,
        style: FilledButton.styleFrom(minimumSize: _minSize),
        child: child,
      ),
      AppButtonVariant.outline => OutlinedButton(
        onPressed: tap,
        style: OutlinedButton.styleFrom(
          minimumSize: _minSize,
          side: BorderSide(color: scheme.primary),
        ),
        child: child,
      ),
      AppButtonVariant.danger => OutlinedButton(
        onPressed: tap,
        style: OutlinedButton.styleFrom(
          minimumSize: _minSize,
          foregroundColor: scheme.error,
          side: BorderSide(color: scheme.error),
        ),
        child: child,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: tap,
        style: TextButton.styleFrom(minimumSize: _minSize),
        child: child,
      ),
    };
  }
}

/// Short uppercase step label such as "STEP 1 OF 2".
class StepLabel extends StatelessWidget {
  const StepLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}
