import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/employee/employee_dashboard_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/marketing/marketing_shell_screen.dart';
import 'screens/it/it_shell_screen.dart';
import 'screens/operations/operations_shell_screen.dart';
import 'screens/hr/hr_shell_screen.dart';
import 'widgets/connectivity_status_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PCRMApp());
}

class PCRMApp extends StatelessWidget {
  const PCRMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initializeAuth()),
      ],
      child: MaterialApp(
        title: 'PCRM Enterprise',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.authenticated:
        final effectiveUser = auth.activeUser;
        final isImpersonating = auth.isImpersonating;

        Widget contentScreen;

        if (!isImpersonating && (auth.currentUser?.isAdmin == true)) {
          contentScreen = const AdminDashboardScreen();
        } else {
          final role = (effectiveUser?.role ?? '').toUpperCase();
          final dept = (effectiveUser?.department ?? '').toUpperCase();
          final email = (effectiveUser?.email ?? '').toLowerCase();

          // Operations Department Routing
          if (role.contains('OPS_MANAGER') || role.contains('OPERATIONS_MANAGER') || email.contains('ops.manager') || email.contains('mgr.ops')) {
            contentScreen = const OperationsShellScreen(isManager: true);
          } else if (role.contains('OPERATIONS') || role.contains('OPS') || dept.contains('OPERATIONS') || dept.contains('OPS') || email.contains('ops') || email.contains('operations')) {
            contentScreen = const OperationsShellScreen(isManager: false);
          }
          // IT Department Routing
          else if (role.contains('IT_MANAGER') || role.contains('TECH_LEAD') || email.contains('it.manager')) {
            contentScreen = const ITShellScreen(isManager: true);
          } else if (role.contains('IT') || role.contains('ENGINEER') || role.contains('DEV') || dept.contains('IT') || dept.contains('TECH') || email.contains('akarshan') || email.contains('dev')) {
            contentScreen = const ITShellScreen(isManager: false);
          }
          // HR Department Routing
          else if (role.contains('HR_MANAGER') || role.contains('PEOPLE_LEAD') || email.contains('hr.lead') || email.contains('hr.manager') || email.contains('mgr.hr')) {
            contentScreen = const HRShellScreen(isManager: true);
          } else if (role.contains('HR') || dept.contains('HR') || dept.contains('HUMAN RESOURCES') || dept.contains('PEOPLE') || email.contains('hr')) {
            contentScreen = const HRShellScreen(isManager: false);
          }
          // Marketing Routing
          else if (role.contains('MARKETING') || dept.contains('MARKETING') || email.contains('rahul') || email.contains('marketing')) {
            contentScreen = const MarketingShellScreen();
          } else {
            contentScreen = const EmployeeDashboardScreen();
          }
        }

        if (isImpersonating) {
          return Scaffold(
            body: Column(
              children: [
                Container(
                  color: const Color(0xFFF59E0B),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        const Icon(Icons.remove_red_eye_rounded, color: Colors.black87, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'VIEWING AS: ${effectiveUser?.name} (${effectiveUser?.role ?? 'Staff'} · ${effectiveUser?.department ?? 'General'})',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => auth.stopImpersonating(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                          icon: const Icon(Icons.exit_to_app, size: 14),
                          label: const Text('Exit View', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(child: contentScreen),
              ],
            ),
          );
        }

        return Scaffold(
          body: Column(
            children: [
              const ConnectivityStatusBanner(),
              Expanded(child: contentScreen),
            ],
          ),
        );

      case AuthStatus.initializing:
        return const Scaffold(
          backgroundColor: Color(0xFF0F172A),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF3B82F6)),
                SizedBox(height: 16),
                Text(
                  'Loading PCRM Enterprise...',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );

      case AuthStatus.unauthenticated:
      case AuthStatus.mfaRequired:
      case AuthStatus.authenticating:
      case AuthStatus.locked:
      default:
        return const LoginScreen();
    }
  }
}
