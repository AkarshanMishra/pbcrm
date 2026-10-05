import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

import 'marketing_home_screen.dart';
import 'marketing_work_screen.dart';
import 'visit_management_screen.dart';
import 'leads_pipeline_screen.dart';
import 'marketing_manager_dashboard.dart';
import 'marketing_report_screen.dart';
import 'marketing_profile_screen.dart';
import 'partner_onboarding_screen.dart';
import '../tasks/create_task_screen.dart';

class MarketingShellScreen extends StatefulWidget {
  const MarketingShellScreen({super.key});

  @override
  State<MarketingShellScreen> createState() => _MarketingShellScreenState();
}

class _MarketingShellScreenState extends State<MarketingShellScreen> {
  int _currentIndex = 0;
  final ApiClient _api = ApiClient();
  Map<String, dynamic>? _telemetry;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchTelemetry();
  }

  Future<void> _fetchTelemetry() async {
    try {
      final res = await _api.get('/api/v1/marketing/telemetry/');
      if (mounted) {
        setState(() {
          _telemetry = res.data;
        });
      }
    } catch (_) {}
  }

  void _showQuickAddModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Marketing Quick Action',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Text('Field action, client meeting, or pipeline update', style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5)),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _buildQuickActionItem(ctx, 'Schedule Visit', Icons.place_rounded, const Color(0xFF2563EB), () {
                    Navigator.pop(ctx);
                    _showScheduleVisitDialog(context);
                  }),
                  _buildQuickActionItem(ctx, 'Add Follow-up', Icons.phone_in_talk_rounded, const Color(0xFF10B981), () {
                    Navigator.pop(ctx);
                    _showAddFollowupDialog(context);
                  }),
                  _buildQuickActionItem(ctx, 'Add New Lead', Icons.person_add_alt_1_rounded, const Color(0xFFF59E0B), () {
                    Navigator.pop(ctx);
                    _showAddLeadDialog(context);
                  }),
                  _buildQuickActionItem(ctx, 'Onboard Partner', Icons.handshake_rounded, const Color(0xFF8B5CF6), () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PartnerOnboardingScreen()));
                  }),
                  _buildQuickActionItem(ctx, 'Create Task', Icons.add_task_rounded, const Color(0xFFEC4899), () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTaskScreen()));
                  }),
                  _buildQuickActionItem(ctx, 'Submit Report', Icons.summarize_rounded, const Color(0xFF0EA5E9), () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketingReportScreen()));
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(BuildContext ctx, String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color,
              radius: 18,
              child: Icon(icon, color: Colors.white, size: 19),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddLeadDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final cityCtrl = TextEditingController(text: 'Kanpur');
    final areaCtrl = TextEditingController();
    String type = 'venue';
    String priority = 'high';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.person_add_rounded, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text('Create New Lead', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Business / Venue Name *', prefixIcon: Icon(Icons.storefront_rounded))),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Lead Type'),
                  items: const [
                    DropdownMenuItem(value: 'venue', child: Text('Venue / Banquet')),
                    DropdownMenuItem(value: 'vendor', child: Text('Vendor / Supplier')),
                    DropdownMenuItem(value: 'partner', child: Text('Corporate Partner')),
                    DropdownMenuItem(value: 'client', child: Text('Direct Client')),
                  ],
                  onChanged: (v) => setDialogState(() => type = v!),
                ),
                const SizedBox(height: 10),
                TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'Contact Person Name *', prefixIcon: Icon(Icons.person_outline_rounded))),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number *', prefixIcon: Icon(Icons.phone_outlined))),
                const SizedBox(height: 10),
                TextField(controller: areaCtrl, decoration: const InputDecoration(labelText: 'Area / Locality', prefixIcon: Icon(Icons.place_outlined))),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'Priority Level'),
                  items: const [
                    DropdownMenuItem(value: 'urgent', child: Text('🔴 Urgent')),
                    DropdownMenuItem(value: 'high', child: Text('🟠 High')),
                    DropdownMenuItem(value: 'medium', child: Text('🟡 Medium')),
                    DropdownMenuItem(value: 'low', child: Text('🟢 Low')),
                  ],
                  onChanged: (v) => setDialogState(() => priority = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || contactCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields.')));
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await _api.post('/api/v1/marketing/leads/', {
                    'business_name': nameCtrl.text.trim(),
                    'lead_type': type,
                    'contact_person': contactCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'city': cityCtrl.text.trim(),
                    'area': areaCtrl.text.trim(),
                    'priority': priority,
                    'status': 'new',
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lead created successfully!'), backgroundColor: Colors.green));
                  _fetchTelemetry();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create lead: $e')));
                }
              },
              child: const Text('Save Lead'),
            ),
          ],
        ),
      ),
    );
  }

  void _showScheduleVisitDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String purpose = 'venue_onboarding';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.place_rounded, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text('Schedule Field Visit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Partner / Venue Name *', prefixIcon: Icon(Icons.business_rounded))),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: purpose,
                  decoration: const InputDecoration(labelText: 'Visit Purpose'),
                  items: const [
                    DropdownMenuItem(value: 'venue_onboarding', child: Text('Venue Onboarding & Photos')),
                    DropdownMenuItem(value: 'vendor_meeting', child: Text('Vendor Agreement Meeting')),
                    DropdownMenuItem(value: 'lead_followup', child: Text('Lead Follow-up')),
                    DropdownMenuItem(value: 'site_audit', child: Text('Site Audit & Verification')),
                  ],
                  onChanged: (v) => setDialogState(() => purpose = v!),
                ),
                const SizedBox(height: 10),
                TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location / Address *', prefixIcon: Icon(Icons.pin_drop_rounded))),
                const SizedBox(height: 10),
                TextField(controller: notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Discussion Notes / Objectives', prefixIcon: Icon(Icons.notes_rounded))),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || locationCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter partner name and location.')));
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await _api.post('/api/v1/marketing/visits/', {
                    'partner_name': nameCtrl.text.trim(),
                    'purpose': purpose,
                    'location_name': locationCtrl.text.trim(),
                    'scheduled_start': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
                    'discussion_notes': notesCtrl.text.trim(),
                    'checklist': {'owner_details': true, 'pan': true, 'gst': false},
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visit scheduled successfully!'), backgroundColor: Colors.green));
                  _fetchTelemetry();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to schedule visit: $e')));
                }
              },
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFollowupDialog(BuildContext context) {
    final leadCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String type = 'call';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.phone_in_talk_rounded, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text('Schedule Follow-up', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: leadCtrl, decoration: const InputDecoration(labelText: 'Lead / Client Name *', prefixIcon: Icon(Icons.person_rounded))),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Follow-up Type'),
                  items: const [
                    DropdownMenuItem(value: 'call', child: Text('📞 Phone Call')),
                    DropdownMenuItem(value: 'whatsapp', child: Text('💬 WhatsApp Message')),
                    DropdownMenuItem(value: 'meeting', child: Text('🤝 In-Person Meeting')),
                    DropdownMenuItem(value: 'email', child: Text('✉️ Email Quotation')),
                  ],
                  onChanged: (v) => setDialogState(() => type = v!),
                ),
                const SizedBox(height: 10),
                TextField(controller: notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Follow-up Objective *', prefixIcon: Icon(Icons.note_alt_rounded))),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
              onPressed: () async {
                if (leadCtrl.text.trim().isEmpty || notesCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields.')));
                  return;
                }
                Navigator.pop(ctx);
                try {
                  // Find or create lead on the fly
                  final leadRes = await _api.post('/api/v1/marketing/leads/', {
                    'business_name': leadCtrl.text.trim(),
                    'contact_person': leadCtrl.text.trim(),
                    'phone': '9800000000',
                    'lead_type': 'venue',
                    'status': 'interested',
                  });
                  final newLeadId = leadRes.data['id'];
                  await _api.post('/api/v1/marketing/followups/', {
                    'lead': newLeadId,
                    'type': type,
                    'scheduled_at': DateTime.now().add(const Duration(hours: 3)).toIso8601String(),
                    'notes': notesCtrl.text.trim(),
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Follow-up scheduled!'), backgroundColor: Colors.green));
                  _fetchTelemetry();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to schedule follow-up: $e')));
                }
              },
              child: const Text('Save Follow-up'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final isManager = _telemetry?['is_manager'] == true || (user?.email?.contains('manager') ?? false);

    final List<Widget> screens = [
      MarketingHomeScreen(telemetry: _telemetry, onRefresh: _fetchTelemetry),
      const MarketingWorkScreen(),
      const VisitManagementScreen(),
      isManager ? const MarketingManagerDashboard() : const LeadsPipelineScreen(),
      const MarketingProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickAddModal(context),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        tooltip: 'Quick Marketing Action',
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF2563EB),
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment_rounded),
              label: 'Work',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.place_outlined),
              activeIcon: Icon(Icons.place_rounded),
              label: 'Visits',
            ),
            BottomNavigationBarItem(
              icon: Icon(isManager ? Icons.groups_outlined : Icons.person_search_outlined),
              activeIcon: Icon(isManager ? Icons.groups_rounded : Icons.person_search_rounded),
              label: isManager ? 'Team' : 'Leads',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined),
              activeIcon: Icon(Icons.account_circle_rounded),
              label: 'Me',
            ),
          ],
        ),
      ),
    );
  }
}
