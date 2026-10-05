import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class HRRecruitmentScreen extends StatefulWidget {
  const HRRecruitmentScreen({super.key});

  @override
  State<HRRecruitmentScreen> createState() => _HRRecruitmentScreenState();
}

class _HRRecruitmentScreenState extends State<HRRecruitmentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _api = ApiClient();
  bool _isLoading = true;

  List<dynamic> _jobs = [];
  List<dynamic> _candidates = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchRecruitmentData();
  }

  Future<void> _fetchRecruitmentData() async {
    setState(() => _isLoading = true);
    try {
      final jobRes = await _api.dio.get('/hr/jobs/');
      if (jobRes.statusCode == 200 && jobRes.data != null) {
        final list = jobRes.data is List ? jobRes.data : jobRes.data['results'] ?? [];
        setState(() => _jobs = list);
      }
    } catch (_) {}

    try {
      final canRes = await _api.dio.get('/hr/candidates/');
      if (canRes.statusCode == 200 && canRes.data != null) {
        final list = canRes.data is List ? canRes.data : canRes.data['results'] ?? [];
        setState(() => _candidates = list);
      }
    } catch (_) {}

    setState(() => _isLoading = false);
  }

  Future<void> _advanceCandidateStage(dynamic id, String nextStage) async {
    try {
      await _api.dio.post('/hr/candidates/$id/advance_stage/', data: {'stage': nextStage});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Candidate moved to $nextStage"), backgroundColor: const Color(0xFF10B981)),
      );
      _fetchRecruitmentData();
    } catch (_) {
      setState(() {
        for (var c in _candidates) {
          if (c['id'] == id) c['stage'] = nextStage;
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text("Recruitment & Talent Pipeline", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Color(0xFFEC4899)),
            onPressed: _showCreateJobDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFEC4899),
          indicatorWeight: 3,
          labelColor: const Color(0xFFEC4899),
          unselectedLabelColor: const Color(0xFF94A3B8),
          tabs: const [
            Tab(text: "Open Positions"),
            Tab(text: "Candidate Pipeline"),
            Tab(text: "Interviews"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOpenJobsTab(),
          _buildCandidatePipelineTab(),
          _buildInterviewsTab(),
        ],
      ),
    );
  }

  Widget _buildOpenJobsTab() {
    final jobs = _jobs.isNotEmpty
        ? _jobs
        : [
            {'title': 'Senior Flutter Architect', 'code': 'JOB-2026-001', 'department_name': 'IT', 'openings_count': 2, 'status': 'OPEN', 'experience_required': '5-8 Years'},
            {'title': 'Lead Cloud & DevOps Engineer', 'code': 'JOB-2026-002', 'department_name': 'IT', 'openings_count': 1, 'status': 'OPEN', 'experience_required': '4-6 Years'},
            {'title': 'Operations Field Manager', 'code': 'JOB-2026-003', 'department_name': 'Operations', 'openings_count': 3, 'status': 'OPEN', 'experience_required': '3-5 Years'},
            {'title': 'Senior HR Generalist', 'code': 'JOB-2026-005', 'department_name': 'HR', 'openings_count': 1, 'status': 'OPEN', 'experience_required': '3-5 Years'},
          ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      itemBuilder: (ctx, idx) {
        final job = jobs[idx];
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
                    child: Text(job['code'] ?? '', style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF94A3B8))),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                    child: Text(job['status'] ?? 'OPEN', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(job['title'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 2),
              Text("${job['department_name'] ?? 'General'} • Exp: ${job['experience_required'] ?? '2+ Years'}", style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${job['openings_count'] ?? 1} Vacancies", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFEC4899))),
                  ElevatedButton(
                    onPressed: () {
                      _tabController.animateTo(1);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF334155),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: const Text("View Candidates >", style: TextStyle(fontSize: 11, color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCandidatePipelineTab() {
    final candidates = _candidates.isNotEmpty
        ? _candidates
        : [
            {'id': 'c1', 'full_name': 'Pooja Verma', 'job_title': 'Senior Flutter Architect', 'stage': 'INTERVIEW', 'rating': 4, 'notes': 'Strong architecture experience'},
            {'id': 'c2', 'full_name': 'Vikram Rathore', 'job_title': 'Senior Flutter Architect', 'stage': 'SELECTED', 'rating': 5, 'notes': 'Exceptional problem solver'},
            {'id': 'c3', 'full_name': 'Rohan Mehta', 'job_title': 'Lead Cloud Engineer', 'stage': 'OFFER', 'rating': 5, 'notes': 'Offer rolled out'},
            {'id': 'c4', 'full_name': 'Sneha Kapoor', 'job_title': 'Operations Field Manager', 'stage': 'SCREENING', 'rating': 3, 'notes': 'Screening scheduled'},
          ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: candidates.length,
      itemBuilder: (ctx, idx) {
        final c = candidates[idx];
        final stage = c['stage'] ?? 'APPLIED';
        Color stageColor = const Color(0xFF3B82F6);
        if (stage == 'INTERVIEW') stageColor = const Color(0xFFF59E0B);
        if (stage == 'SELECTED') stageColor = const Color(0xFF8B5CF6);
        if (stage == 'OFFER') stageColor = const Color(0xFFEC4899);
        if (stage == 'JOINED') stageColor = const Color(0xFF10B981);

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
                  Text(c['full_name'] ?? 'Candidate', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: stageColor.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                    child: Text(stage, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: stageColor)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text("Applying for: ${c['job_title'] ?? 'Role'}", style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              if (c['notes'] != null) ...[
                const SizedBox(height: 6),
                Text("\"${c['notes']}\"", style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFFCBD5E1))),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (stage == 'SCREENING' || stage == 'APPLIED')
                    ElevatedButton(
                      onPressed: () => _advanceCandidateStage(c['id'], 'INTERVIEW'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
                      child: const Text("Schedule Interview", style: TextStyle(fontSize: 11, color: Colors.white)),
                    )
                  else if (stage == 'INTERVIEW')
                    ElevatedButton(
                      onPressed: () => _advanceCandidateStage(c['id'], 'SELECTED'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
                      child: const Text("Select for Offer", style: TextStyle(fontSize: 11, color: Colors.white)),
                    )
                  else if (stage == 'SELECTED')
                    ElevatedButton(
                      onPressed: () => _advanceCandidateStage(c['id'], 'OFFER'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEC4899)),
                      child: const Text("Roll Out Offer Letter", style: TextStyle(fontSize: 11, color: Colors.white)),
                    )
                  else if (stage == 'OFFER')
                    ElevatedButton(
                      onPressed: () => _advanceCandidateStage(c['id'], 'JOINED'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                      child: const Text("Mark Joined & Start Onboarding", style: TextStyle(fontSize: 11, color: Colors.white)),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInterviewsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("SCHEDULED INTERVIEWS TODAY & TOMORROW", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 10),
          _buildInterviewCard("Pooja Verma", "Senior Flutter Architect", "Today at 03:00 PM", "Interviewer: IT Lead", Icons.videocam),
          _buildInterviewCard("Sneha Kapoor", "Operations Field Manager", "Tomorrow at 11:30 AM", "Interviewer: Operations VP", Icons.videocam),
          _buildInterviewCard("Amitabh Sen", "B2B Marketing Specialist", "Tomorrow at 04:00 PM", "Interviewer: Marketing Head", Icons.phone),
        ],
      ),
    );
  }

  Widget _buildInterviewCard(String name, String role, String time, String interviewer, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEC4899).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFEC4899), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(role, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                const SizedBox(height: 2),
                Text("$time • $interviewer", style: const TextStyle(fontSize: 11, color: Color(0xFF10B981))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateJobDialog() {
    final titleCtrl = TextEditingController();
    final codeCtrl = TextEditingController(text: "JOB-2026-009");
    final expCtrl = TextEditingController(text: "2-4 Years");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Open New Job Position", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Position Title", labelStyle: TextStyle(color: Color(0xFF94A3B8))),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: codeCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Job Code", labelStyle: TextStyle(color: Color(0xFF94A3B8))),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: expCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Experience Required", labelStyle: TextStyle(color: Color(0xFF94A3B8))),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Color(0xFF94A3B8)))),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isNotEmpty) {
                try {
                  await _api.dio.post('/hr/jobs/', data: {
                    'title': titleCtrl.text,
                    'code': codeCtrl.text,
                    'experience_required': expCtrl.text,
                    'status': 'OPEN',
                  });
                  Navigator.pop(ctx);
                  _fetchRecruitmentData();
                } catch (_) {
                  Navigator.pop(ctx);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEC4899)),
            child: const Text("Publish Job", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
