import 'package:flutter/material.dart';

import '../shared/contracts.dart';
import '../features/history/history_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import 'app_routes.dart';
import 'pending_screen.dart';

class InOutApp extends StatelessWidget {
  const InOutApp({
    super.key,
    required this.services,
    this.initialRoute = AppRoutes.home,
    this.featureRoutes = const {},
    this.homeBuilder,
    this.themeBuilder,
  });
  final AppServices services;
  final String initialRoute;
  final Map<String, WidgetBuilder> featureRoutes;
  final WidgetBuilder? homeBuilder;
  final SharedThemeBuilder? themeBuilder;
  @override
  Widget build(BuildContext context) => AppScope(
    services: services,
    child: ListenableBuilder(
      listenable: services.state,
      builder: (context, _) {
        final profile = services.state.profile;
        ThemeData theme(Brightness brightness) =>
            themeBuilder?.call(brightness, profile.accentColor) ??
            ThemeData(
              useMaterial3: true,
              brightness: brightness,
              colorSchemeSeed: profile.accentColor,
            );
        final routes = <String, WidgetBuilder>{
          for (final screen in AppRoutes.titles.entries)
            screen.key: (_) => PendingScreen(title: screen.value),
          AppRoutes.home:
              homeBuilder ?? (_) => const PendingScreen(title: 'S05 Home'),
          AppRoutes.history: (_) => const HistoryScreen(),
          AppRoutes.profile: (_) => const ProfileScreen(),
          AppRoutes.editProfile: (_) => const EditProfileScreen(),
          ...featureRoutes,
        };
        return MaterialApp(
          title: 'InOut',
          debugShowCheckedModeBanner: false,
          theme: theme(Brightness.light),
          darkTheme: theme(Brightness.dark),
          themeMode: profile.themeMode,
          initialRoute: initialRoute,
          onGenerateInitialRoutes: (name) => [
            MaterialPageRoute<void>(
              settings: RouteSettings(name: name),
              builder: routes[name]!,
            ),
          ],
          routes: routes,
        );
      },
    ),
  );
}
