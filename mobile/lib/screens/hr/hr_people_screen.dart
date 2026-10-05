import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import 'hr_employee_detail_screen.dart';
import 'onboarding_wizard_screen.dart';

class HRPeopleScreen extends StatefulWidget {
  const HRPeopleScreen({super.key});

  @override
  State<HRPeopleScreen> createState() => _HRPeopleScreenState();
}

class _HRPeopleScreenState extends State<HRPeopleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _api = ApiClient();
  final TextEditingController _searchCtrl = TextEditingController();
  
  bool _isLoading = true;
  List<dynamic> _employees = [];
  String _searchQuery = "";
  String? _selectedDeptFilter;

  final List<String> _tabs = ["All", "Active", "Onboarding", "Probation", "On Leave", "Exited"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/employees/');
      if (res.statusCode == 200 && res.data != null) {
        final list = res.data is List ? res.data : res.data['results'] ?? [];
        setState(() {
          _employees = list;
        });
      }
    } catch (_) {
      // Demo fallback if offline
      setState(() {
        _employees = [
          {
            'id': '1',
            'first_name': 'Akarshan',
            'last_name': 'Mishra',
            'employee_code': 'PBE000001',
            'department_name': 'Information Technology',
            'position_title': 'Software Developer',
            'status': 'ACTIVE',
            'employment_type': 'FULL_TIME',
            'joining_date': '12 Jan 2025'
          },
          {
            'id': '2',
            'first_name': 'Rahul',
            'last_name': 'Verma',
            'employee_code': 'PBE000002',
            'department_name': 'Marketing',
            'position_title': 'Marketing Executive',
            'status': 'ACTIVE',
            'employment_type': 'FULL_TIME',
            'joining_date': '01 Feb 2025'
          },
          {
            'id': '3',
            'first_name': 'Ananya',
            'last_name': 'Sharma',
            'employee_code': 'PBH000001',
            'department_name': 'Human Resources',
            'position_title': 'HR Manager',
            'status': 'ACTIVE',
            'employment_type': 'FULL_TIME',
            'joining_date': '01 Jun 2023'
          },
          {
            'id': '4',
            'first_name': 'Vikram',
            'last_name': 'Rathore',
            'employee_code': 'PBE000004',
            'department_name': 'Information Technology',
            'position_title': 'Lead Cloud Engineer',
            'status': 'ONBOARDING',
            'employment_type': 'FULL_TIME',
            'joining_date': '01 Oct 2026'
          },
          {
            'id': '5',
            'first_name': 'Kavita',
            'last_name': 'Nair',
            'employee_code': 'PBE000005',
            'department_name': 'Operations',
            'position_title': 'Operations Coordinator',
            'status': 'PROBATION',
            'employment_type': 'FULL_TIME',
            'joining_date': '15 Aug 2026'
          },
        ];
      });
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<dynamic> _getFilteredEmployees() {
    final currentTab = _tabs[_tabController.index];
    return _employees.filter((emp) {
      final status = emp['status'] ?? emp['user']?['status'] ?? 'ACTIVE';
      final name = "${emp['first_name'] ?? ''} ${emp['last_name'] ?? ''}".toLowerCase();
      final code = (emp['employee_code'] ?? emp['user']?['employee_code'] ?? '').toString().toLowerCase();
      final dept = (emp['department_name'] ?? emp['department']?['name'] ?? '').toString().toLowerCase();
      final pos = (emp['position_title'] ?? emp['position']?['title'] ?? '').toString().toLowerCase();

      // Tab filter
      if (currentTab == "Active" && status != 'ACTIVE') return false;
      if (currentTab == "Onboarding" && status != 'ONBOARDING' && status != 'INVITED') return false;
      if (currentTab == "Probation" && status != 'PROBATION' && status != 'PENDING_VERIFICATION') return false;
      if (currentTab == "On Leave" && status != 'ON_LEAVE') return false;
      if (currentTab == "Exited" && status != 'EXITED' && status != 'DEACTIVATED') return false;

      // Dept filter
      if (_selectedDeptFilter != null && _selectedDeptFilter!.isNotEmpty) {
        if (!dept.contains(_selectedDeptFilter!.toLowerCase())) return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || code.contains(query) || dept.contains(query) || pos.contains(query);
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredEmployees();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          "Employee Directory",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Color(0xFFEC4899)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingWizardScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFFEC4899),
          indicatorWeight: 3,
          labelColor: const Color(0xFFEC4899),
          unselectedLabelColor: const Color(0xFF94A3B8),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFEC4899)))
                : filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, idx) => _buildEmployeeCard(filtered[idx]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF1E293B),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: "Search name, ID, department, position...",
              hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Color(0xFF64748B), size: 16),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = "");
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF0F172A),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> emp) {
    final fullName = emp['full_name'] ?? "${emp['first_name'] ?? ''} ${emp['last_name'] ?? ''}".trim();
    final code = emp['employee_code'] ?? emp['user']?['employee_code'] ?? 'EMP-000';
    final dept = emp['department_name'] ?? emp['department']?['name'] ?? 'General';
    final pos = emp['position_title'] ?? emp['position']?['title'] ?? 'Staff Member';
    final status = emp['status'] ?? emp['user']?['status'] ?? 'ACTIVE';

    Color statusColor = const Color(0xFF10B981);
    if (status == 'ONBOARDING' || status == 'INVITED') statusColor = const Color(0xFFF97316);
    if (status == 'PROBATION' || status == 'PENDING_VERIFICATION') statusColor = const Color(0xFFEAB308);
    if (status == 'ON_LEAVE') statusColor = const Color(0xFF3B82F6);
    if (status == 'EXITED' || status == 'DEACTIVATED') statusColor = const Color(0xFFEF4444);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HREmployeeDetailScreen(employee: emp)),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFEC4899),
              child: Text(
                fullName.isNotEmpty ? fullName.substring(0, 1).toUpperCase() : 'E',
                style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          fullName,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$pos • $dept",
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        code,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'monospace'),
                      ),
                      const Spacer(),
                      const Text(
                        "View Profile >",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFEC4899)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, color: Color(0xFF475569), size: 48),
          const SizedBox(height: 12),
          const Text("No employees found", style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingWizardScreen()),
              );
            },
            icon: const Icon(Icons.person_add, size: 16),
            label: const Text("Start Onboarding Wizard"),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEC4899), foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}

extension ListFilter<T> on List<T> {
  List<T> filter(bool Function(T) test) {
    return where(test).toList();
  }
}
