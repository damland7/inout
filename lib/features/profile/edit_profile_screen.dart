import 'package:flutter/material.dart';

import '../../shared/contracts.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _goal = TextEditingController();
  bool _initialized = false;
  bool _submitted = false;
  bool _saving = false;
  bool _closing = false;
  bool _dialogOpen = false;
  String _originalName = '';
  String _originalGoal = '';
  String _email = '';
  bool get _dirty => _name.text != _originalName || _goal.text != _originalGoal;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final profile = AppScope.of(context).state.profile;
    _originalName = _name.text = profile.name;
    _originalGoal = _goal.text = profile.dailyGoalKcal.toString();
    _email = profile.email;
    _name.addListener(_changed);
    _goal.addListener(_changed);
    _initialized = true;
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _name.dispose();
    _goal.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (_closing || !mounted) return;
    _closing = true;
    Navigator.pop(context);
  }

  Future<void> _back() async {
    if (_saving) return;
    if (!_dirty) {
      await _close();
      return;
    }
    if (_dialogOpen) return;
    _dialogOpen = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your edits to the profile will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    _dialogOpen = false;
    if (discard == true && mounted) await _close();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _submitted = true);
    if (!_form.currentState!.validate()) return;
    final goal = int.tryParse(_goal.text.trim());
    if (goal == null) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    AppScope.of(context).state
        .updateProfile(name: _name.text.trim(), dailyGoalKcal: goal);
    await _close();
    messenger.showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  @override
  Widget build(BuildContext context) {
    final validators = AppScope.of(context).validators;
    return PopScope(
      canPop: !_dirty || _closing,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          leading: BackButton(onPressed: _back),
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _form,
              autovalidateMode: _submitted
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const ValueKey('profile-name'),
                    controller: _name,
                    validator: validators.fullName,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Full name'),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const ValueKey('profile-email'),
                    initialValue: _email,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      helperText: 'Email cannot be changed',
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const ValueKey('profile-goal'),
                    controller: _goal,
                    validator: validators.dailyGoal,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Daily calorie goal',
                      suffixText: 'kcal',
                      helperText: 'Between 1,200 and 5,000 kcal',
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: const Text('Save Changes'),
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
