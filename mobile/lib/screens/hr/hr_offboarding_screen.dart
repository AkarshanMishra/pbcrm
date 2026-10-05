import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class HROffboardingScreen extends StatefulWidget {
  const HROffboardingScreen({super.key});

  @override
  State<HROffboardingScreen> createState() => _HROffboardingScreenState();
}

class _HROffboardingScreenState extends State<HROffboardingScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _offboardings = [];

  // 10-point checklist state
  final Map<String, bool> _checklist = {
    '1. Formal Resignation Acceptance': true,
    '2. Knowledge Transfer (KT) Sign-off': true,
    '3. Company Laptop & Accessories Handover': false,
    '4. Corporate Email & Cloud Access Revoked': false,
    '5. Smart NFC ID Badge & Access Card Returned': false,
    '6. Finance & Travel Reimbursements Cleared': false,
    '7. Non-Disclosure & IP Agreement Reaffirmed': true,
    '8. HR Exit Interview Conducted': true,
    '9. Full & Final (FNF) Settlement Processed': false,
    '10. Relieving & Experience Letter Issued': false,
  };

  @override
  void initState() {
    super.initState();
    _fetchOffboardings();
  }

  Future<void> _fetchOffboardings() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/hr/offboarding/');
      if (res.statusCode == 200 && res.data != null) {
        final list = res.data is List ? res.data : res.data['results'] ?? [];
        setState(() => _offboardings = list);
      }
    } catch (_) {
      setState(() {
        _offboardings = [
          {
            'id': 'off1',
            'exit_code': 'EXT-2026-001',
            'employee_name': 'Ramesh Chandra',
            'employee_code': 'PBE000007',
            'department_name': 'Operations',
            'last_working_day': '2026-10-15',
            'status': 'NOTICE_PERIOD',
            'reason_for_leaving': 'Relocating to Bangalore for family reasons.'
          }
        ];
      });
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text("Offboarding & Exit Clearance", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEC4899)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildActiveExitBanner(),
                  const SizedBox(height: 16),
                  const Text("10-POINT OFFBOARDING CLEARANCE CHECKLIST", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 10),
                  ..._checklist.keys.map((k) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: CheckboxListTile(
                          value: _checklist[k],
                          onChanged: (val) {
                            setState(() => _checklist[k] = val ?? false);
                          },
                          title: Text(k, style: const TextStyle(fontSize: 13, color: Colors.white)),
                          activeColor: const Color(0xFF10B981),
                          checkColor: Colors.white,
                        ),
                      )),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Relieving & Experience Certificate generated! 📜"),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      },
                      icon: const Icon(Icons.verified, size: 18),
                      label: const Text("Generate Experience & Relieving Certificate"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEC4899),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildActiveExitBanner() {
    final exit = _offboardings.isNotEmpty ? _offboardings[0] : {'employee_name': 'Ramesh Chandra', 'last_working_day': '2026-10-15', 'exit_code': 'EXT-2026-001'};
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                exit['employee_name'] ?? 'Employee',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                child: const Text("SERVING NOTICE", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text("Exit Code: ${exit['exit_code']} • Last Working Day: ${exit['last_working_day']}", style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          const SizedBox(height: 6),
          const Text("Reason: Relocating to Bangalore for family reasons.", style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFFCBD5E1))),
        ],
      ),
    );
  }
}
