import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../shared/contracts.dart';
import '../../shared/widgets/form_widgets.dart';
import 'account_layout.dart';

/// S01 Login. UI-only in Step 2.2: any valid email and password open the
/// demo account. Firebase Authentication is added in Step 3.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _submitted = false;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _logIn() {
    if (_loading) return;
    setState(() => _submitted = true);
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    AppScope.of(context).state.logIn();
    // Home becomes the only route, so Back never returns to Login.
    AppRoutes.openHome(context);
  }

  void _forgotPassword() => Navigator.pushNamed(
    context,
    AppRoutes.forgotPassword,
    arguments: ForgotPasswordArguments(_email.text.trim()),
  );

  @override
  Widget build(BuildContext context) {
    final validators = AppScope.of(context).validators;
    final theme = Theme.of(context);
    return Scaffold(
      body: AccountLayout(
        children: [
          const SizedBox(height: 32),
          const Center(child: AppLogo()),
          const SizedBox(height: 16),
          Text(
            'InOut',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Track what you eat and what you burn',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
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
                    key: const ValueKey('login-email'),
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
                    key: const ValueKey('login-password'),
                    label: 'Password',
                    controller: _password,
                    validator: validators.loginPassword,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _logIn(),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _forgotPassword,
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: 8),
          AppButton(label: 'Log In', loading: _loading, onPressed: _logIn),
          const SizedBox(height: 24),
          AccountLinkRow(
            question: "Don't have an account?",
            action: 'Sign Up',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.signUp),
          ),
        ],
      ),
    );
  }
}
