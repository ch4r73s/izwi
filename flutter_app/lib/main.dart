import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:outgoing_notifications/bloc/auth/auth_bloc.dart';
import 'package:outgoing_notifications/bloc/auth/auth_event.dart';
import 'package:outgoing_notifications/bloc/auth/auth_state.dart';
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

class CongregationNotificationsApp extends StatelessWidget {
  const CongregationNotificationsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'Izwi',
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

    if (!hasConnection && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection. Some features may not work.'),
          duration: Duration(seconds: 5),
        ),
      );
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
