import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:outgoing_notifications/config/app_constants.dart';
import 'package:outgoing_notifications/bloc/auth/auth_bloc.dart';
import 'package:outgoing_notifications/bloc/auth/auth_event.dart';
import 'package:outgoing_notifications/bloc/auth/auth_state.dart';
import 'package:outgoing_notifications/config/navigation_key.dart';
import 'package:outgoing_notifications/config/routes.dart';
import 'package:outgoing_notifications/enums/user_role.dart';
import 'package:outgoing_notifications/features/auth/auth_repository.dart';
import 'package:outgoing_notifications/screens/authentication.dart';
import 'package:outgoing_notifications/services/storage/secure_storage_service.dart';
import 'package:outgoing_notifications/services/theme_notifier.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: RepositoryProvider(
        create: (_) => AuthRepository(SecureStorageService()),
        child: BlocProvider(
          create:
              (context) =>
                  AuthBloc(context.read<AuthRepository>())
                    ..add(const AuthStarted()),
          child: const CongregationNotificationsApp(),
        ),
      ),
    ),
  );
}

class CongregationNotificationsApp extends StatefulWidget {
  const CongregationNotificationsApp({super.key});

  @override
  State<CongregationNotificationsApp> createState() =>
      _CongregationNotificationsAppState();
}

class _CongregationNotificationsAppState extends State<CongregationNotificationsApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkConnectivity();
    }
  }

  Future<void> _checkConnectivity() async {
    final connectivity = await Connectivity().checkConnectivity();
    final hasConnection = connectivity.any(
      (result) => result != ConnectivityResult.none,
    );
    if (!hasConnection) {
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No internet connection. Some features may not work.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'Velvet',
          navigatorKey: navigatorKey,
          theme: themeNotifier.currentTheme,
          routes: getRoutes(context),
          home: const LoaderScreen(),
        );
      },
    );
  }
}

class LoaderScreen extends StatefulWidget {
  const LoaderScreen({super.key});

  @override
  State<LoaderScreen> createState() => _LoaderScreenState();
}

class _LoaderScreenState extends State<LoaderScreen> {
  bool _hasCheckedInternet = false;

  @override
  void initState() {
    super.initState();
    _checkInternetAndNotify();
  }

  Future<void> _checkInternetAndNotify() async {
    if (_hasCheckedInternet) {
      return;
    }

    _hasCheckedInternet = true;
    final connectivity = await Connectivity().checkConnectivity();
    final hasConnection = connectivity.any(
      (result) => result != ConnectivityResult.none,
    );

    if (!hasConnection) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No internet connection. Some features may not work.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    // Check if the API server is reachable.
    try {
      final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}${AppConstants.healthPath}',
      );
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('API server unreachable: ${AppConstants.apiBaseUrl}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('API server unreachable: ${AppConstants.apiBaseUrl}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.initial ||
            state.status == AuthStatus.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == AuthStatus.authenticated && state.role != null) {
          final route = switch (state.role!) {
            UserRole.admin => Routes.adminHome,
            UserRole.user => Routes.userHome,
            UserRole.guest => Routes.guestHome,
          };

          final routes = getRoutes(context);
          final builder = routes[route] ?? routes[Routes.authentication]!;
          return builder(context);
        }

        if (state.status == AuthStatus.failure && state.message != null) {
          return AuthenticationScreen(errorMessage: state.message);
        }

        return const AuthenticationScreen();
      },
    );
  }
}
