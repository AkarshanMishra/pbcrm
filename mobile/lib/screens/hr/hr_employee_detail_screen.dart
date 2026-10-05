import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class HREmployeeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> employee;
  const HREmployeeDetailScreen({super.key, required this.employee});

  @override
  State<HREmployeeDetailScreen> createState() => _HREmployeeDetailScreenState();
}

class _HREmployeeDetailScreenState extends State<HREmployeeDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _api = ApiClient();
  bool _showSalary = false;
  bool _isLoading = true;
  List<dynamic> _documents = [];
  List<dynamic> _reviews = [];
  List<dynamic> _trainings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _fetchEmployeeDeepData();
  }

  Future<void> _fetchEmployeeDeepData() async {
    setState(() => _isLoading = true);
    final empId = widget.employee['id'];
    try {
      if (empId != null) {
        final docRes = await _api.dio.get('/hr/documents/?employee=$empId');
        if (docRes.statusCode == 200 && docRes.data != null) {
          final list = docRes.data is List ? docRes.data : docRes.data['results'] ?? [];
          setState(() => _documents = list);
        }

        final revRes = await _api.dio.get('/hr/reviews/?employee=$empId');
        if (revRes.statusCode == 200 && revRes.data != null) {
          final list = revRes.data is List ? revRes.data : revRes.data['results'] ?? [];
          setState(() => _reviews = list);
        }

        final trnRes = await _api.dio.get('/hr/training-enrollments/?employee=$empId');
        if (trnRes.statusCode == 200 && trnRes.data != null) {
          final list = trnRes.data is List ? trnRes.data : trnRes.data['results'] ?? [];
          setState(() => _trainings = list);
        }
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emp = widget.employee;
    final fullName = emp['full_name'] ?? "${emp['first_name'] ?? ''} ${emp['last_name'] ?? ''}".trim();
    final code = emp['employee_code'] ?? emp['user']?['employee_code'] ?? 'EMP-000';
    final dept = emp['department_name'] ?? emp['department']?['name'] ?? 'General';
    final position = emp['position_title'] ?? emp['position']?['title'] ?? 'Staff Member';
    final status = emp['status'] ?? emp['user']?['status'] ?? 'ACTIVE';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Text(fullName.isNotEmpty ? fullName : "Employee Profile", style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildProfileHeader(fullName, code, dept, position, status),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildEmploymentTab(),
                _buildAttendanceTab(),
                _buildLeaveTab(),
                _buildDocumentsTab(),
                _buildPerformanceTab(),
                _buildAssetsTab(),
                _buildActivityTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String name, String code, String dept, String pos, String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1E293B),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFEC4899),
            child: Text(
              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'E',
              style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: status == 'ACTIVE' ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFFF59E0B).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: status == 'ACTIVE' ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: status == 'ACTIVE' ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "$pos • $dept",
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 2),
                Text(
                  "ID: $code",
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF1E293B),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: const Color(0xFFEC4899),
        indicatorWeight: 3,
        labelColor: const Color(0xFFEC4899),
        unselectedLabelColor: const Color(0xFF94A3B8),
        tabs: const [
          Tab(text: "Overview"),
          Tab(text: "Employment"),
          Tab(text: "Attendance"),
          Tab(text: "Leave"),
          Tab(text: "Documents"),
          Tab(text: "Performance"),
          Tab(text: "Assets"),
          Tab(text: "Activity"),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final emp = widget.employee;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection("CONTACT INFORMATION", [
            _buildInfoRow("Official Email", emp['email'] ?? emp['user']?['email'] ?? 'emp@pcrm.local'),
            _buildInfoRow("Phone Number", emp['user']?['phone'] ?? "+91 98765 43210"),
            _buildInfoRow("Gender", emp['gender'] ?? "Male"),
            _buildInfoRow("Date of Birth", emp['date_of_birth'] ?? "12 Aug 1996"),
            _buildInfoRow("Residential Address", emp['address'] ?? "Kanpur, Uttar Pradesh"),
          ]),
          const SizedBox(height: 16),
          _buildInfoSection("EMERGENCY CONTACT", [
            _buildInfoRow("Contact Name", emp['emergency_contact_name'] ?? "Suresh Verma (Father)"),
            _buildInfoRow("Emergency Phone", emp['emergency_contact_phone'] ?? "+91 98765 00000"),
          ]),
          const SizedBox(height: 16),
          _buildInfoSection("REPORTING HIERARCHY", [
            _buildInfoRow("Reporting Manager", emp['reporting_manager_name'] ?? "Engineering Director"),
            _buildInfoRow("Department Head", "VP Operations"),
          ]),
        ],
      ),
    );
  }

  Widget _buildEmploymentTab() {
    final emp = widget.employee;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection("EMPLOYMENT DETAILS", [
            _buildInfoRow("Department", emp['department_name'] ?? emp['department']?['name'] ?? 'IT'),
            _buildInfoRow("Designation / Title", emp['position_title'] ?? emp['position']?['title'] ?? 'Developer'),
            _buildInfoRow("Employment Type", emp['employment_type'] ?? 'FULL_TIME'),
            _buildInfoRow("Date of Joining", emp['joining_date'] ?? '12 Jan 2025'),
            _buildInfoRow("Work Location", "Kanpur Headquarters (Hybrid)"),
            _buildInfoRow("Probation Period", "Completed (Confirmed)"),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
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
                    const Text(
                      "COMPENSATION & CTC (CONFIDENTIAL)",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEC4899)),
                    ),
                    IconButton(
                      icon: Icon(_showSalary ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF94A3B8), size: 18),
                      onPressed: () => setState(() => _showSalary = !_showSalary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildInfoRow("Annual CTC", _showSalary ? "₹ 9,50,000 / annum" : "••••••••••••"),
                _buildInfoRow("Monthly Gross", _showSalary ? "₹ 79,166 / month" : "••••••••••••"),
                _buildInfoRow("PF Deduction", _showSalary ? "₹ 1,800 / month" : "••••••••••••"),
                _buildInfoRow("Bank Account", _showSalary ? "HDFC Bank (•••• 8902)" : "••••••••••••"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildAttendanceStat("21", "Days Present", const Color(0xFF10B981))),
              const SizedBox(width: 8),
              Expanded(child: _buildAttendanceStat("2", "Late Arrivals", const Color(0xFFF59E0B))),
              const SizedBox(width: 8),
              Expanded(child: _buildAttendanceStat("1", "Leaves Taken", const Color(0xFF3B82F6))),
              const SizedBox(width: 8),
              Expanded(child: _buildAttendanceStat("8.8h", "Avg Work Hours", const Color(0xFFA855F7))),
            ],
          ),
          const SizedBox(height: 16),
          const Text("RECENT ATTENDANCE LOGS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          _buildAttendanceLogItem("Today", "09:28 AM", "06:34 PM", "PRESENT", const Color(0xFF10B981)),
          _buildAttendanceLogItem("Yesterday", "09:42 AM", "06:45 PM", "LATE (12m)", const Color(0xFFF59E0B)),
          _buildAttendanceLogItem("02 Oct", "09:15 AM", "06:30 PM", "PRESENT", const Color(0xFF10B981)),
          _buildAttendanceLogItem("01 Oct", "-", "-", "ON_LEAVE", const Color(0xFF3B82F6)),
        ],
      ),
    );
  }

  Widget _buildAttendanceStat(String val, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildAttendanceLogItem(String day, String inTime, String outTime, String tag, Color tagColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(day, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 2),
              Text("In: $inTime  |  Out: $outTime", style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: tagColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: tagColor.withOpacity(0.4)),
            ),
            child: Text(tag, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tagColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("LEAVE BALANCES (2026)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildLeaveCard("Casual Leave", "8 / 12", const Color(0xFF3B82F6))),
              const SizedBox(width: 8),
              Expanded(child: _buildLeaveCard("Sick Leave", "7 / 10", const Color(0xFF10B981))),
              const SizedBox(width: 8),
              Expanded(child: _buildLeaveCard("Earned Leave", "12 / 15", const Color(0xFFF59E0B))),
              const SizedBox(width: 8),
              Expanded(child: _buildLeaveCard("WFH Days", "6 / 8", const Color(0xFFA855F7))),
            ],
          ),
          const SizedBox(height: 20),
          const Text("LEAVE HISTORY", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          _buildLeaveHistoryItem("1 Oct 2026", "Casual Leave (1 Day)", "Family commitment", "APPROVED"),
          _buildLeaveHistoryItem("14 Aug 2026", "Sick Leave (2 Days)", "Fever & recovery", "APPROVED"),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Apply leave on behalf modal"), backgroundColor: Color(0xFFEC4899)),
                );
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text("Apply Leave On Behalf"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC4899),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveCard(String title, String balance, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(balance, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildLeaveHistoryItem(String date, String type, String reason, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("$type • $date", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 2),
              Text(reason, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    final docs = _documents.isNotEmpty
        ? _documents
        : [
            {'title': 'Aadhaar / National ID', 'status': 'VERIFIED', 'document_type': 'ID_PROOF'},
            {'title': 'PAN Card Copy', 'status': 'VERIFIED', 'document_type': 'PAN'},
            {'title': 'Signed Offer Letter', 'status': 'VERIFIED', 'document_type': 'OFFER_LETTER'},
            {'title': 'NDA & Confidentiality', 'status': 'VERIFIED', 'document_type': 'NDA'},
            {'title': 'Degree & Certificates', 'status': 'PENDING', 'document_type': 'EDUCATION'},
          ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("EMPLOYEE DOCUMENTS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
              Text("${docs.length} Total", style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
            ],
          ),
          const SizedBox(height: 10),
          ...docs.map((d) {
            final isVerified = d['status'] == 'VERIFIED';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  Icon(
                    isVerified ? Icons.check_circle : Icons.pending,
                    color: isVerified ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d['title'] ?? 'Document', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text("Type: ${d['document_type'] ?? 'DOC'}", style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                  if (!isVerified)
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Document marked as verified"), backgroundColor: Color(0xFF10B981)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                      child: const Text("Verify", style: TextStyle(fontSize: 11, color: Colors.white)),
                    )
                  else
                    const Text("Verified 🟢", style: TextStyle(fontSize: 11, color: Color(0xFF10B981))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("ANNUAL APPRAISAL 2026", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                    Row(
                      children: [
                        Icon(Icons.star, color: Color(0xFFF59E0B), size: 18),
                        SizedBox(width: 4),
                        Text("4.5 / 5.0", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildProgressBar("KPI Attainment", 0.88, "88%"),
                const SizedBox(height: 8),
                _buildProgressBar("Competencies & Teamwork", 0.85, "85%"),
                const SizedBox(height: 8),
                _buildProgressBar("Attendance & Punctuality", 0.95, "95%"),
                const SizedBox(height: 12),
                const Text("Manager Feedback:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                const SizedBox(height: 4),
                const Text(
                  "\"High quality architecture delivery, exceptional code standards, and proactive team mentorship.\"",
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFFCBD5E1)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text("TRAINING & CERTIFICATIONS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          _buildTrainingItem("InfoSec & GDPR Compliance", "TRN-101", "Completed (95%)", const Color(0xFF10B981)),
          _buildTrainingItem("Workplace Safety & POSH", "TRN-102", "Completed (100%)", const Color(0xFF10B981)),
          _buildTrainingItem("Enterprise Flutter Standards", "TRN-103", "In Progress (60%)", const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double val, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: val,
          backgroundColor: const Color(0xFF334155),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEC4899)),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Widget _buildTrainingItem(String title, String code, String status, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(code, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ],
          ),
          Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildAssetsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ASSIGNED HARDWARE & COMPANY ASSETS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 10),
          _buildAssetCard("MacBook Pro 16\" (M3 Max)", "SN: C02G998902", "Assigned: 12 Jan 2025", Icons.laptop_mac),
          _buildAssetCard("Dell UltraSharp 27\" 4K Monitor", "SN: DL-4K-8921", "Assigned: 12 Jan 2025", Icons.desktop_windows),
          _buildAssetCard("Smart NFC Access ID Card", "Card: NFC-88910", "Active", Icons.credit_card),
        ],
      ),
    );
  }

  Widget _buildAssetCard(String title, String serial, String date, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF3B82F6), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 2),
                Text("$serial  •  $date", style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("LIFECYCLE & AUDIT LOGS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 10),
          _buildActivityLog("12 Jan 2025", "Joined PCRM as Software Developer", "HR Team"),
          _buildActivityLog("15 Jan 2025", "Completed 6-step Induction & Document Sign-off", "System"),
          _buildActivityLog("12 Jul 2025", "Probation successfully confirmed to Full-Time", "Manager"),
          _buildActivityLog("01 Oct 2026", "Annual Performance Appraisal Review logged", "HR Reviewer"),
        ],
      ),
    );
  }

  Widget _buildActivityLog(String date, String title, String actor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 4, right: 10),
            decoration: const BoxDecoration(color: Color(0xFFEC4899), shape: BoxShape.circle),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 2),
                Text("$date • Logged by $actor", style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String heading, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }
}
