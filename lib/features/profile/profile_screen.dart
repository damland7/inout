import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../shared/contracts.dart';
import '../../shared/formatters.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  Future<void> _logout(BuildContext context) async {
    final state = AppScope.of(context).state;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need to log in again to see your entries.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    state.logOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    }
  }

  Future<void> _reset(BuildContext context, String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change password'),
        content: Text(
          'We will send a link to $email so you can choose a new password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset link requested (UI demo).')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final profile = services.state.profile;
    final theme = Theme.of(context);
    final mode = switch (profile.themeMode) {
      ThemeMode.system => 'System',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        top: false,
        child: ListView(
          key: const PageStorageKey('profile-scroll'),
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            Center(
              child: CircleAvatar(
                radius: 36,
                child: Text(
                  initials(profile.name),
                  style: theme.textTheme.headlineSmall,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              profile.name,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(profile.email, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _Detail(
                      label: 'Daily goal',
                      value: '${profile.dailyGoalKcal} kcal',
                    ),
                    const SizedBox(height: 12),
                    _Detail(
                      label: 'Theme',
                      value:
                          '$mode · ${services.accentName(profile.accentColor)}',
                    ),
                    const SizedBox(height: 12),
                    _Detail(
                      label: 'Member since',
                      value:
                          '${months[profile.createdAt.month - 1]} ${profile.createdAt.year}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.editProfile),
              child: const Text('Edit Profile'),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Appearance'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, AppRoutes.appearance),
            ),
            ListTile(
              leading: const Icon(Icons.lock_reset),
              title: const Text('Change password'),
              onTap: () => _reset(context, profile.email),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About InOut'),
              onTap: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('InOut · 0.1.0'),
                  content: const Text(
                    'CS310 · Group 8\n\nHüseyin Vakkasoğlu\nDamla Kandemir\n'
                    'Berre Özçanak\nBedirhan Ceylan',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.error),
              title: Text(
                'Log out',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () => _logout(context),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: Text(label)),
      const SizedBox(width: 12),
      Flexible(child: Text(value, textAlign: TextAlign.end)),
    ],
  );
}
