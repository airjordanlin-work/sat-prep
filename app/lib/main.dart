import 'package:flutter/material.dart';
import 'data/question_repository.dart';
import 'screens/home_screen.dart';
import 'screens/gate_screen.dart';
import 'services/gate_channel.dart';
import 'theme/app_theme.dart';

const demoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: true);

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repo = QuestionRepository();
  await repo.load();

  GateChannel.onGateRequested((package) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => GateScreen(repo: repo, blockedPackage: package),
        fullscreenDialog: true,
      ),
    );
  });

  runApp(GatekeeperApp(repo: repo));
}

class GatekeeperApp extends StatelessWidget {
  final QuestionRepository repo;
  const GatekeeperApp({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
              navigatorKey: navigatorKey,
              title: 'Strolle',
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: ThemeMode.system,
              home: HomeScreen(repo: repo),
            );

  }
}
