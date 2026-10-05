import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class HRPerformanceScreen extends StatefulWidget {
  const HRPerformanceScreen({super.key});

  @override
  State<HRPerformanceScreen> createState() => _HRPerformanceScreenState();
}

class _HRPerformanceScreenState extends State<HRPerformanceScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _reviews = [];

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/hr/reviews/');
      if (res.statusCode == 200 && res.data != null) {
        final list = res.data is List ? res.data : res.data['results'] ?? [];
        setState(() => _reviews = list);
      }
    } catch (_) {
      setState(() {
        _reviews = [
          {'id': 'rv1', 'review_code': 'REV-2026-001', 'employee_name': 'Akarshan Mishra', 'employee_code': 'PBE000001', 'rating': '4.5', 'kpi_score': 88, 'status': 'MANAGER_REVIEW', 'cycle_name': 'Annual Appraisal 2026'},
          {'id': 'rv2', 'review_code': 'REV-2026-002', 'employee_name': 'Rahul Verma', 'employee_code': 'PBE000002', 'rating': '4.0', 'kpi_score': 82, 'status': 'FINAL_REVIEW', 'cycle_name': 'Annual Appraisal 2026'},
          {'id': 'rv3', 'review_code': 'REV-2026-003', 'employee_name': 'Sneha Kapoor', 'employee_code': 'PBE000004', 'rating': '4.2', 'kpi_score': 85, 'status': 'GOAL_SETTING', 'cycle_name': 'Annual Appraisal 2026'},
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
        title: const Text("Performance & Appraisal Cycles", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEC4899)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCycleOverviewCard(),
                  const SizedBox(height: 16),
                  const Text("APPRAISAL REVIEWS QUEUE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 10),
                  ..._reviews.map((r) => _buildReviewCard(r)),
                ],
              ),
            ),
    );
  }

  Widget _buildCycleOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("ACTIVE CYCLE: ANNUAL APPRAISAL 2026", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEC4899))),
              Text("Phase 3 of 5", style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(label: "Avg Org Rating", value: "4.2 / 5.0", color: Color(0xFFF59E0B)),
              _StatItem(label: "Reviews Logged", value: "98 / 124", color: Color(0xFF10B981)),
              _StatItem(label: "Pending HR Final", value: "26", color: Color(0xFF3B82F6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> r) {
    final status = r['status'] ?? 'MANAGER_REVIEW';
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
              Text(r['employee_name'] ?? 'Employee', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFF59E0B), size: 16),
                  const SizedBox(width: 4),
                  Text("${r['rating'] ?? '4.0'} / 5.0", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text("${r['employee_code'] ?? ''} • KPI Attainment: ${r['kpi_score'] ?? 85}%", style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFEC4899).withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                child: Text(status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFEC4899))),
              ),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Appraisal scorecard opened"), backgroundColor: Color(0xFF10B981)),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF334155), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                child: const Text("View Scorecard >", style: TextStyle(fontSize: 11, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
      ],
    );
  }
}
