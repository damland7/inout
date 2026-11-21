import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../shared/contracts.dart';
import '../../shared/widgets/form_widgets.dart';
import 'account_layout.dart';

/// S03 Forgot Password. UI-only in Step 2.2: no email is actually sent until
/// Firebase Authentication is added in Step 3. The dialog never says whether
/// the email belongs to an account.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _initialized = false;
  bool _submitted = false;
  bool _sending = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    // Pre-fill the email the user already typed on Login.
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ForgotPasswordArguments) _email.text = args.email;
    _initialized = true;
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    setState(() => _submitted = true);
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    final email = _email.text.trim();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.mark_email_read_outlined),
        title: const Text('Check your email'),
        content: Text(
          'If an account exists for $email, we sent a link to reset your '
          'password.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Back to Log In'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    backToLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    final validators = AppScope.of(context).validators;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: AccountLayout(
        children: [
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.lock_reset_rounded,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Forgot your password?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the email you used to sign up. We will send you a link to '
            'choose a new password.',
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
            child: AppTextField(
              key: const ValueKey('forgot-email'),
              label: 'Email',
              hintText: 'name@example.com',
              controller: _email,
              validator: validators.email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              onFieldSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Send Reset Link',
            loading: _sending,
            onPressed: _send,
          ),
          const SizedBox(height: 8),
          AppButton(
            label: 'Back to Log In',
            variant: AppButtonVariant.text,
            onPressed: () => backToLogin(context),
          ),
        ],
      ),
    );
  }
}
