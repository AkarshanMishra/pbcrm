import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import 'mfa_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiClient _api = ApiClient();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showServerConfigDialog() {
    final urlController = TextEditingController(text: _api.dio.options.baseUrl);
    bool testing = false;
    String? testMsg;
    bool? testSuccess;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.dns_outlined, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Server IP Settings', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter the backend server IP address and port (e.g. your PC IP on Wi-Fi):',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Backend URL',
                  hintText: 'http://10.198.30.44:8000/api/v1',
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 12),
              if (testMsg != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: testSuccess == true ? const Color(0xFFECFDF5) : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    testMsg!,
                    style: TextStyle(
                      fontSize: 12,
                      color: testSuccess == true ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: testing ? null : () async {
                  setDialogState(() {
                    testing = true;
                    testMsg = null;
                  });
                  try {
                    await _api.setBaseUrl(urlController.text.trim());
                    final pingRes = await _api.dio.get('/organization/departments/');
                    setDialogState(() {
                      testing = false;
                      testSuccess = true;
                      testMsg = '✓ Connected successfully to server!';
                    });
                  } catch (e) {
                    setDialogState(() {
                      testing = false;
                      testSuccess = false;
                      testMsg = '✕ Connection failed. Verify IP & Wi-Fi.';
                    });
                  }
                },
                icon: const Icon(Icons.wifi_tethering),
                label: Text(testing ? 'Testing...' : 'Test Connection'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await _api.setBaseUrl(urlController.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Server URL set to: ${_api.dio.options.baseUrl}'), backgroundColor: AppTheme.success),
                );
              },
              child: const Text('Save URL'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _identifierController.text,
      _passwordController.text,
      deviceInfo: {
        'device_id': 'flutter-client-device-01',
        'device_name': 'Mobile Device',
        'device_type': 'ANDROID',
        'app_version': '1.0.0',
      },
    );

    if (success && mounted) {
      if (authProvider.status == AuthStatus.mfaRequired) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MFAScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.primary),
            tooltip: 'Server Connection Settings',
            onPressed: _showServerConfigDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / Header
                  const Icon(Icons.shield_outlined, size: 64, color: AppTheme.primary),
                  const SizedBox(height: 16),
                  const Text(
                    'PCRM Enterprise',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Secure Employee Identity & Access Portal',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  ),
                  const SizedBox(height: 36),

                  if (auth.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              auth.errorMessage!,
                              style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Identifier Input
                  TextFormField(
                    controller: _identifierController,
                    decoration: const InputDecoration(
                      labelText: 'Employee ID or Email',
                      hintText: 'e.g. PBE000001 or name@company.com',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter Employee ID or Email' : null,
                  ),
                  const SizedBox(height: 16),

                  // Password Input
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (val) => (val == null || val.isEmpty) ? 'Please enter your password' : null,
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleLogin,
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Sign In Securely'),
                  ),
                  const SizedBox(height: 24),

                  const Center(
                    child: Text(
                      'Protected by Enterprise Rate Limiting & Audit Logging',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
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
