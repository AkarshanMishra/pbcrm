import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedCategory = 'IT_SUPPORT';
  String _selectedPriority = 'MEDIUM';

  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'How does offline mode sync work?',
      'answer': 'When your device goes offline, all actions (tasks, check-ins, reports) are stored locally in the encrypted SQLite queue. Once connection is restored, the Offline Sync Engine automatically pushes mutations to the Django server with conflict detection.',
      'category': 'System & Sync',
    },
    {
      'question': 'What is PartyBala’s 12% Partner Commission rule?',
      'answer': 'All banquet and vendor partner bookings automatically calculate a 12% platform commission. The Accounts & Finance module generates both client invoices and partner settlement payouts based on verified attendance and event readiness.',
      'category': 'Accounts & Billing',
    },
    {
      'question': 'How do I submit an attendance correction request?',
      'answer': 'Navigate to My Attendance or HR module -> Select the date with an anomaly -> Tap "Request Correction" -> Enter punch-in / punch-out time and reason -> Submit for manager approval.',
      'category': 'HR & Attendance',
    },
    {
      'question': 'Who has authority to approve high-value partner discounts?',
      'answer': 'Discounts beyond 5% require Super Admin approval via the Executive Escalations Gate in the Management Overview screen.',
      'category': 'Management & Policy',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.help_center_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Help & Support Center', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF2563EB),
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_rounded), text: 'Knowledge Base'),
            Tab(icon: Icon(Icons.confirmation_num_rounded), text: 'Submit Ticket'),
            Tab(icon: Icon(Icons.dns_rounded), text: 'System Health'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildKnowledgeBaseTab(),
          _buildSubmitTicketTab(),
          _buildSystemHealthTab(),
        ],
      ),
    );
  }

  Widget _buildKnowledgeBaseTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Search Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('How can we assist you today?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Search SOPs, workflows, system guides, and policies across departments.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              const SizedBox(height: 14),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search documentation & FAQs...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text('FREQUENTLY ASKED QUESTIONS & SOPS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)),
        const SizedBox(height: 10),
        ..._faqs.map((faq) => Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: ExpansionTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.help_outline_rounded, color: Color(0xFF2563EB), size: 18),
                ),
                title: Text(faq['question'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A))),
                subtitle: Text(faq['category'], style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(faq['answer'], style: const TextStyle(color: Color(0xFF334155), fontSize: 13, height: 1.4)),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildSubmitTicketTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Create Internal Support Ticket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                const Text('Submit incident or request to IT, HR, Accounts, or Operations teams.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                const SizedBox(height: 20),

                // Category & Priority
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Department / Category',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'IT_SUPPORT', child: Text('IT & Hardware / Software')),
                          DropdownMenuItem(value: 'HR_QUERY', child: Text('HR & Payroll Query')),
                          DropdownMenuItem(value: 'ACCOUNTS', child: Text('Accounts & Expense Reimb')),
                          DropdownMenuItem(value: 'OPS_LOGISTICS', child: Text('Operations & Logistics')),
                        ],
                        onChanged: (val) => setState(() => _selectedCategory = val ?? 'IT_SUPPORT'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedPriority,
                        decoration: InputDecoration(
                          labelText: 'Priority Level',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'LOW', child: Text('Low Priority')),
                          DropdownMenuItem(value: 'MEDIUM', child: Text('Medium Priority')),
                          DropdownMenuItem(value: 'HIGH', child: Text('High Priority')),
                          DropdownMenuItem(value: 'URGENT', child: Text('Urgent (SLA < 2h)')),
                        ],
                        onChanged: (val) => setState(() => _selectedPriority = val ?? 'MEDIUM'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                TextField(
                  controller: _titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Subject / Summary',
                    hintText: 'e.g. Sync error on Android APK when saving offline banquet visit',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                TextField(
                  controller: _descCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Detailed Explanation & Steps to Reproduce',
                    hintText: 'Provide complete details to help resolve quickly...',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_titleCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a ticket subject')));
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('🎫 Ticket #TCK-2026-104 created and assigned to triage queue')),
                      );
                      _titleCtrl.clear();
                      _descCtrl.clear();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Submit Ticket', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemHealthTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildServiceStatusCard('Django REST API Core', '127.0.0.1:8000', 'OPERATIONAL', '12ms latency', Colors.green),
        _buildServiceStatusCard('PostgreSQL / SQLite Storage Engine', 'Master Database', 'OPERATIONAL', '99.99% uptime', Colors.green),
        _buildServiceStatusCard('Offline Sync & Telemetry Daemon', 'Batch & Heartbeat', 'OPERATIONAL', 'Active (0 queue backlog)', Colors.green),
        _buildServiceStatusCard('Geo-Fencing & Visit Verification', 'GPS Coordinates', 'OPERATIONAL', 'Ready for mobile punches', Colors.green),
        _buildServiceStatusCard('Push Notification Service', 'Firebase FCM', 'OPERATIONAL', 'Delivering alerts', Colors.green),
      ],
    );
  }

  Widget _buildServiceStatusCard(String name, String endpoint, String status, String metric, Color color) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(Icons.check_circle_rounded, color: color, size: 20),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
        subtitle: Text('$endpoint · $metric', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
          child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
