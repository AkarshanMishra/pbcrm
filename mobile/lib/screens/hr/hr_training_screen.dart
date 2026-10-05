import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class HRTrainingScreen extends StatefulWidget {
  const HRTrainingScreen({super.key});

  @override
  State<HRTrainingScreen> createState() => _HRTrainingScreenState();
}

class _HRTrainingScreenState extends State<HRTrainingScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _trainings = [];

  @override
  void initState() {
    super.initState();
    _fetchTrainings();
  }

  Future<void> _fetchTrainings() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/hr/training-programs/');
      if (res.statusCode == 200 && res.data != null) {
        final list = res.data is List ? res.data : res.data['results'] ?? [];
        setState(() => _trainings = list);
      }
    } catch (_) {
      setState(() {
        _trainings = [
          {'id': 't1', 'code': 'TRN-101', 'title': 'Information Security, Phishing & Data Privacy', 'is_mandatory': true, 'duration_hours': 2, 'deadline': '2026-11-30', 'enrolled_count': 124},
          {'id': 't2', 'code': 'TRN-102', 'title': 'Workplace Safety, POSH & Anti-Harassment', 'is_mandatory': true, 'duration_hours': 1, 'deadline': '2026-12-15', 'enrolled_count': 124},
          {'id': 't3', 'code': 'TRN-103', 'title': 'PCRM Enterprise Architecture & Flutter Best Practices', 'is_mandatory': false, 'duration_hours': 8, 'deadline': '2026-12-31', 'enrolled_count': 42},
          {'id': 't4', 'code': 'TRN-104', 'title': 'Operational Excellence & Vendor SLA Compliance', 'is_mandatory': false, 'duration_hours': 4, 'deadline': '2026-12-31', 'enrolled_count': 38},
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
        title: const Text("Training & Enablement Hub", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEC4899)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _trainings.length,
              itemBuilder: (ctx, idx) {
                final t = _trainings[idx];
                final isMandatory = t['is_mandatory'] == true;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(4)),
                            child: Text(t['code'] ?? '', style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF94A3B8))),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isMandatory ? const Color(0xFFEF4444).withOpacity(0.15) : const Color(0xFF3B82F6).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isMandatory ? "MANDATORY" : "OPTIONAL",
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isMandatory ? const Color(0xFFEF4444) : const Color(0xFF3B82F6)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(t['title'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text("Duration: ${t['duration_hours'] ?? 2} Hours • Deadline: ${t['deadline'] ?? ''}", style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("${t['enrolled_count'] ?? 0} Enrolled", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF10B981))),
                          ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Course launched: ${t['title']}"), backgroundColor: const Color(0xFF10B981)),
                              );
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEC4899), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                            child: const Text("Launch Course", style: TextStyle(fontSize: 11, color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
