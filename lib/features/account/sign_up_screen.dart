import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../shared/contracts.dart';
import '../../shared/widgets/form_widgets.dart';
import 'account_layout.dart';

/// S02 Sign Up (step 1 of 2). UI-only: the account is created in memory and
/// the password is never stored. The daily goal is asked on S04.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitted = false;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _createAccount() {
    if (_loading) return;
    setState(() => _submitted = true);
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    AppScope.of(context).state.registerProfile(
      name: _name.text,
      email: _email.text,
    );
    // The account exists now, so S04 has no way back to the sign-up forms.
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.goalSetup,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final validators = AppScope.of(context).validators;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: AccountLayout(
        children: [
          const StepLabel('Step 1 of 2'),
          const SizedBox(height: 4),
          Text(
            'Start tracking in under a minute.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Form(
            key: _form,
            autovalidateMode: _submitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    key: const ValueKey('signup-name'),
                    label: 'Full name',
                    controller: _name,
                    validator: validators.fullName,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    key: const ValueKey('signup-email'),
                    label: 'Email',
                    hintText: 'name@example.com',
                    controller: _email,
                    validator: validators.email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    key: const ValueKey('signup-password'),
                    label: 'Password',
                    helperText: 'At least 6 characters',
                    controller: _password,
                    validator: validators.signUpPassword,
                    isPassword: true,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    key: const ValueKey('signup-confirm'),
                    label: 'Confirm password',
                    controller: _confirm,
                    validator: (value) =>
                        validators.confirmPassword(value, _password.text),
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _createAccount(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Create Account',
            loading: _loading,
            onPressed: _createAccount,
          ),
          const SizedBox(height: 16),
          AccountLinkRow(
            question: 'Already have an account?',
            action: 'Log In',
            onPressed: () => backToLogin(context),
          ),
        ],
      ),
    );
  }
}
