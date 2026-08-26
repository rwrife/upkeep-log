import 'package:flutter/material.dart';
import 'package:upkeep_log/domain/app_capabilities.dart';

/// Root widget for the local-first Upkeep Log application.
class UpkeepLogApp extends StatelessWidget {
  const UpkeepLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Upkeep Log',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E6F5E)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFF74C7AD),
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const EmptyHomeScreen(),
    );
  }
}

/// Honest startup state shown before home and task creation is implemented.
class EmptyHomeScreen extends StatelessWidget {
  const EmptyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Upkeep Log')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const ExcludeSemantics(
                    child: Icon(Icons.home_repair_service_outlined, size: 64),
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    header: true,
                    child: Text(
                      'No upkeep tasks yet',
                      style: textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Home and task creation will arrive in the next milestone. '
                    'Your maintenance history will stay on this device unless '
                    'you choose to export it.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppCapabilities.requiresNetwork
                        ? 'A network connection is required.'
                        : 'No account or network connection is required.',
                    style: textTheme.bodySmall,
                    textAlign: TextAlign.center,
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
