import 'package:flutter/material.dart';
import 'hr_home_screen.dart';
import 'hr_people_screen.dart';
import 'hr_attendance_screen.dart';
import 'hr_requests_screen.dart';
import 'hr_profile_screen.dart';
import 'hr_manager_dashboard_screen.dart';
import 'onboarding_wizard_screen.dart';
import 'hr_recruitment_screen.dart';
import 'hr_documents_screen.dart';
import 'hr_policies_screen.dart';
import 'hr_performance_screen.dart';
import 'hr_training_screen.dart';
import 'hr_offboarding_screen.dart';
import 'hr_daily_report_screen.dart';

class HRShellScreen extends StatefulWidget {
  final bool isManager;
  const HRShellScreen({super.key, this.isManager = false});

  @override
  State<HRShellScreen> createState() => _HRShellScreenState();
}

class _HRShellScreenState extends State<HRShellScreen> {
  int _currentIndex = 0;
  late bool _managerView;

  @override
  void initState() {
    super.initState();
    _managerView = widget.isManager;
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _showQuickActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF475569),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  "HR Operations Quick Action",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 10,
                  children: [
                    _buildModalItem(
                      icon: Icons.person_add_alt_1,
                      label: "+ Employee",
                      color: const Color(0xFFEC4899),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const OnboardingWizardScreen()));
                      },
                    ),
                    _buildModalItem(
                      icon: Icons.event_available,
                      label: "Leave Apprv",
                      color: const Color(0xFF3B82F6),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const HRAttendanceScreen(initialTabIndex: 2)));
                      },
                    ),
                    _buildModalItem(
                      icon: Icons.work_outline,
                      label: "+ Job",
                      color: const Color(0xFFF59E0B),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const HRRecruitmentScreen()));
                      },
                    ),
                    _buildModalItem(
                      icon: Icons.verified_user,
                      label: "Verify Docs",
                      color: const Color(0xFF10B981),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const HRDocumentsScreen()));
                      },
                    ),
                    _buildModalItem(
                      icon: Icons.menu_book,
                      label: "Policies",
                      color: const Color(0xFF06B6D4),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const HRPoliciesScreen()));
                      },
                    ),
                    _buildModalItem(
                      icon: Icons.school,
                      label: "Training",
                      color: const Color(0xFF8B5CF6),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const HRTrainingScreen()));
                      },
                    ),
                    _buildModalItem(
                      icon: Icons.exit_to_app,
                      label: "Offboarding",
                      color: const Color(0xFFEF4444),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const HROffboardingScreen()));
                      },
                    ),
                    _buildModalItem(
                      icon: Icons.rate_review,
                      label: "Daily Report",
                      color: const Color(0xFFE11D48),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const HRDailyReportScreen()));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFFCBD5E1)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = _managerView
        ? [
            HRHomeScreen(
              onNavigateToPeople: () => _onTabSelected(1),
              onNavigateToRequests: () => _onTabSelected(2),
            ),
            const HRPeopleScreen(),
            const HRRequestsScreen(),
            const HRManagerDashboardScreen(),
            HRProfileScreen(
              isManager: _managerView,
              onToggleManagerView: (val) => setState(() => _managerView = val),
            ),
          ]
        : [
            HRHomeScreen(
              onNavigateToPeople: () => _onTabSelected(1),
              onNavigateToRequests: () => _onTabSelected(3),
            ),
            const HRPeopleScreen(),
            const HRAttendanceScreen(),
            const HRRequestsScreen(),
            HRProfileScreen(
              isManager: _managerView,
              onToggleManagerView: (val) => setState(() => _managerView = val),
            ),
          ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickActionSheet,
        backgroundColor: const Color(0xFFEC4899),
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF334155), width: 0.5)),
        ),
        child: BottomAppBar(
          color: const Color(0xFF1E293B),
          notchMargin: 6,
          shape: const CircularNotchedRectangle(),
          elevation: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavButton(Icons.home_outlined, Icons.home, "Home", 0),
              _buildNavButton(Icons.people_outline, Icons.people, "People", 1),
              const SizedBox(width: 48), // Space for notched FAB
              if (_managerView) ...[
                _buildNavButton(Icons.assignment_outlined, Icons.assignment, "Requests", 2),
                _buildNavButton(Icons.insights_outlined, Icons.insights, "Reports", 3),
              ] else ...[
                _buildNavButton(Icons.schedule_outlined, Icons.schedule, "Attendance", 2),
                _buildNavButton(Icons.assignment_outlined, Icons.assignment, "Requests", 3),
              ],
              _buildNavButton(Icons.person_outline, Icons.person, "Me", 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(IconData inactiveIcon, IconData activeIcon, String label, int index) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? const Color(0xFFEC4899) : const Color(0xFF94A3B8);

    return InkWell(
      onTap: () => _onTabSelected(index),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : inactiveIcon, color: color, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
