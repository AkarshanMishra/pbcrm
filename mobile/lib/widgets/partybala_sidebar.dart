import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/auth_user.dart';
import '../providers/auth_provider.dart';

enum SidebarRoleView {
  superAdmin,
  hr,
  it,
  marketing,
  operations,
  accounts,
  manager,
  employee,
}

class PartyBalaSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int index, {String? subModule, String? category}) onItemSelected;
  final VoidCallback? onAddEmployee;
  final VoidCallback? onMarkAttendance;
  final VoidCallback? onApproveLeave;
  final VoidCallback? onAssignTask;
  final VoidCallback? onGenerateReport;
  final VoidCallback? onSwitchDepartment;
  final VoidCallback? onImpersonate;
  final VoidCallback? onLogout;

  const PartyBalaSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.onAddEmployee,
    this.onMarkAttendance,
    this.onApproveLeave,
    this.onAssignTask,
    this.onGenerateReport,
    this.onSwitchDepartment,
    this.onImpersonate,
    this.onLogout,
  });

  @override
  State<PartyBalaSidebar> createState() => _PartyBalaSidebarState();
}

class _PartyBalaSidebarState extends State<PartyBalaSidebar> {
  bool _isCollapsed = false;
  String? _expandedFlyoutKey;
  SidebarRoleView _currentRoleView = SidebarRoleView.superAdmin;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Stack(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main Sidebar Column (Dark Navy/Slate Theme #0F172A)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _isCollapsed ? 76 : 268,
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(right: BorderSide(color: Color(0xFF1E293B), width: 1)),
              ),
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _currentRoleView == SidebarRoleView.superAdmin
                        ? _buildSuperAdminMenu()
                        : _buildRoleSpecificMenu(_currentRoleView),
                  ),
                  _buildUserFooter(user),
                ],
              ),
            ),

            // Expanded Flyout Panel (when clicking expandable item)
            if (_expandedFlyoutKey != null && !_isCollapsed)
              _buildFlyoutPanel(),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // 1. BRAND HEADER WITH PARTYBALA FLOWER LOGO
  // ===========================================================================
  Widget _buildHeader() {
    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: _isCollapsed ? 12 : 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        children: [
          _buildPartyBalaFlowerLogo(),
          if (!_isCollapsed) ...[
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PartyBala',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Employee Management',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                _isCollapsed ? Icons.menu_open_rounded : Icons.menu_rounded,
                color: const Color(0xFF94A3B8),
                size: 20,
              ),
              tooltip: _isCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
              onPressed: () => setState(() {
                _isCollapsed = !_isCollapsed;
                _expandedFlyoutKey = null;
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPartyBalaFlowerLogo() {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() {
        _isCollapsed = !_isCollapsed;
        _expandedFlyoutKey = null;
      }),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(6),
        child: CustomPaint(
          painter: _PartyBalaLogoPainter(),
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. SUPER ADMIN MAIN MENU (MATCHING EXACT SPECIFICATION & SIDEBAR DESIGN)
  // ===========================================================================
  Widget _buildSuperAdminMenu() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      children: [
        // 🏠 Dashboard
        _buildNavTile(
          index: 0,
          title: 'Dashboard',
          icon: Icons.home_rounded,
        ),

        // SECTION: GLOBAL
        _buildSectionHeader('GLOBAL'),
        _buildNavTile(
          index: 100,
          title: 'Global Search',
          icon: Icons.search_rounded,
          hasChevron: true,
        ),
        _buildNavTile(
          index: 101,
          title: 'Notifications',
          icon: Icons.notifications_rounded,
          badgeCount: 12,
          hasChevron: true,
        ),
        _buildNavTile(
          index: 4,
          title: 'Approvals',
          icon: Icons.check_circle_rounded,
          badgeCount: 8,
          hasChevron: true,
        ),
        _buildNavTile(
          index: 114,
          title: 'My Calendar',
          icon: Icons.calendar_month_rounded,
          hasChevron: true,
        ),

        // SECTION: PEOPLE & ORGANIZATION
        _buildSectionHeader('PEOPLE & ORGANIZATION'),
        _buildNavTile(
          index: 1,
          title: 'Employees',
          icon: Icons.groups_rounded,
          hasChevron: true,
          flyoutKey: 'employees',
        ),
        _buildNavTile(
          index: 115,
          title: 'Departments',
          icon: Icons.apartment_rounded,
          hasChevron: true,
        ),
        _buildNavTile(
          index: 116,
          title: 'Positions',
          icon: Icons.business_center_rounded,
          hasChevron: true,
        ),
        _buildNavTile(
          index: 6,
          title: 'Roles & Permissions',
          icon: Icons.lock_person_rounded,
          hasChevron: true,
        ),

        // SECTION: DEPARTMENTS
        _buildSectionHeader('DEPARTMENTS'),
        _buildNavTile(
          index: 102,
          title: 'HR',
          icon: Icons.people_alt_rounded,
          hasChevron: true,
          flyoutKey: 'hr',
          accentColor: const Color(0xFFFB7185), // Pink
        ),
        _buildNavTile(
          index: 103,
          title: 'IT',
          icon: Icons.laptop_chromebook_rounded,
          hasChevron: true,
          flyoutKey: 'it',
          accentColor: const Color(0xFF38BDF8), // Sky Blue
        ),
        _buildNavTile(
          index: 104,
          title: 'Marketing',
          icon: Icons.campaign_rounded,
          hasChevron: true,
          flyoutKey: 'marketing',
          accentColor: const Color(0xFF34D399), // Emerald
        ),
        _buildNavTile(
          index: 105,
          title: 'Operations',
          icon: Icons.settings_rounded,
          hasChevron: true,
          flyoutKey: 'operations',
          accentColor: const Color(0xFFFBBF24), // Amber
        ),
        _buildNavTile(
          index: 106,
          title: 'Accounts & Finance',
          icon: Icons.monetization_on_rounded,
          hasChevron: true,
          flyoutKey: 'accounts',
          accentColor: const Color(0xFFA78BFA), // Purple
        ),
        _buildNavTile(
          index: 117,
          title: 'Management',
          icon: Icons.military_tech_rounded,
          hasChevron: true,
          accentColor: const Color(0xFF60A5FA),
        ),

        // SECTION: WORK & OPERATIONS
        _buildSectionHeader('WORK & OPERATIONS'),
        _buildNavTile(
          index: 7,
          title: 'Tasks & Workflows',
          icon: Icons.assignment_turned_in_rounded,
          badgeCount: 24,
          hasChevron: true,
          flyoutKey: 'workflows',
        ),
        _buildNavTile(
          index: 107,
          title: 'Projects',
          icon: Icons.folder_copy_rounded,
          hasChevron: true,
        ),
        _buildNavTile(
          index: 108,
          title: 'Tickets & Support',
          icon: Icons.headphones_rounded,
          badgeCount: 6,
          hasChevron: true,
        ),
        _buildNavTile(
          index: 118,
          title: 'Leads, Partners & Bookings',
          icon: Icons.handshake_rounded,
          hasChevron: true,
        ),

        // SECTION: REPORTS & ANALYTICS
        _buildSectionHeader('REPORTS & ANALYTICS'),
        _buildNavTile(
          index: 8,
          title: 'Reports & Analytics',
          icon: Icons.bar_chart_rounded,
          hasChevron: true,
        ),
        _buildNavTile(
          index: 119,
          title: 'Performance & Insights',
          icon: Icons.insights_rounded,
          hasChevron: true,
        ),

        // SECTION: SYSTEM & SECURITY
        _buildSectionHeader('SYSTEM & SECURITY'),
        _buildNavTile(
          index: 10,
          title: 'Settings & Configuration',
          icon: Icons.tune_rounded,
          hasChevron: true,
        ),
        _buildNavTile(
          index: 120,
          title: 'Security Center',
          icon: Icons.shield_rounded,
          badgeCount: 3,
          hasChevron: true,
        ),
        _buildNavTile(
          index: 9,
          title: 'Audit Logs',
          icon: Icons.history_edu_rounded,
          hasChevron: true,
        ),
        _buildNavTile(
          index: 111,
          title: 'Help & Support',
          icon: Icons.help_outline_rounded,
          hasChevron: true,
        ),
        _buildNavTile(
          index: 113,
          title: 'Offline Sync Center',
          icon: Icons.cloud_sync_rounded,
          accentColor: const Color(0xFF34D399),
          hasChevron: true,
        ),
        _buildNavTile(
          index: 112,
          title: 'Device Fleet Health',
          icon: Icons.phonelink_setup_rounded,
          accentColor: const Color(0xFF38BDF8),
          hasChevron: true,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    if (_isCollapsed) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Divider(color: Color(0xFF1E293B), height: 1),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. ROLE-SPECIFIC VIEWS (HR, IT, Marketing, Ops, Accounts, Mgr, Emp)
  // ===========================================================================
  Widget _buildRoleSpecificMenu(SidebarRoleView roleView) {
    switch (roleView) {
      case SidebarRoleView.hr:
        return _buildRoleList(
          title: 'HR Department',
          badgeColor: const Color(0xFFF43F5E),
          icon: Icons.badge_rounded,
          items: [
            _RoleMenuItem('Dashboard', Icons.dashboard_rounded, 0),
            _RoleMenuItem('Employees', Icons.groups_rounded, 1),
            _RoleMenuItem('Attendance', Icons.access_time_filled_rounded, 3),
            _RoleMenuItem('Leave Management', Icons.event_available_rounded, 4),
            _RoleMenuItem('Recruitment', Icons.person_add_alt_1_rounded, 1),
            _RoleMenuItem('Training & Development', Icons.school_rounded, 1),
            _RoleMenuItem('Performance', Icons.trending_up_rounded, 119),
            _RoleMenuItem('Policies & Documents', Icons.description_rounded, 10),
            _RoleMenuItem('Reports', Icons.analytics_rounded, 8),
          ],
        );
      case SidebarRoleView.it:
        return _buildRoleList(
          title: 'IT Department',
          badgeColor: const Color(0xFF0284C7),
          icon: Icons.computer_rounded,
          items: [
            _RoleMenuItem('Dashboard', Icons.dashboard_rounded, 0),
            _RoleMenuItem('IT Requests', Icons.build_circle_rounded, 108),
            _RoleMenuItem('Tickets & Support', Icons.headset_mic_rounded, 108),
            _RoleMenuItem('Assets & Inventory', Icons.devices_other_rounded, 5),
            _RoleMenuItem('System Access', Icons.vpn_key_rounded, 6),
            _RoleMenuItem('Software Management', Icons.apps_rounded, 5),
            _RoleMenuItem('Device Management', Icons.phone_android_rounded, 112),
            _RoleMenuItem('Security', Icons.security_rounded, 120),
            _RoleMenuItem('Reports', Icons.analytics_rounded, 8),
          ],
        );
      case SidebarRoleView.marketing:
        return _buildRoleList(
          title: 'Marketing Department',
          badgeColor: const Color(0xFF10B981),
          icon: Icons.campaign_rounded,
          items: [
            _RoleMenuItem('Dashboard', Icons.dashboard_rounded, 0),
            _RoleMenuItem('Leads & Partners', Icons.handshake_rounded, 118),
            _RoleMenuItem('Visits', Icons.location_on_rounded, 2),
            _RoleMenuItem('Follow-ups', Icons.phone_callback_rounded, 2),
            _RoleMenuItem('Campaigns', Icons.mark_email_read_rounded, 104),
            _RoleMenuItem('Marketing Tasks', Icons.task_alt_rounded, 2),
            _RoleMenuItem('Reports', Icons.analytics_rounded, 8),
          ],
        );
      case SidebarRoleView.operations:
        return _buildRoleList(
          title: 'Operations Department',
          badgeColor: const Color(0xFFF59E0B),
          icon: Icons.settings_suggest_rounded,
          items: [
            _RoleMenuItem('Dashboard', Icons.dashboard_rounded, 0),
            _RoleMenuItem('Partners & Bookings', Icons.store_rounded, 118),
            _RoleMenuItem('Event Management', Icons.celebration_rounded, 118),
            _RoleMenuItem('Operations Tasks', Icons.task_alt_rounded, 2),
            _RoleMenuItem('Issues & Escalations', Icons.report_problem_rounded, 108),
            _RoleMenuItem('Logistics', Icons.local_shipping_rounded, 105),
            _RoleMenuItem('Service Management', Icons.handyman_rounded, 105),
            _RoleMenuItem('Reports', Icons.analytics_rounded, 8),
          ],
        );
      case SidebarRoleView.accounts:
        return _buildRoleList(
          title: 'Accounts & Finance',
          badgeColor: const Color(0xFF8B5CF6),
          icon: Icons.account_balance_wallet_rounded,
          items: [
            _RoleMenuItem('Dashboard', Icons.dashboard_rounded, 0),
            _RoleMenuItem('Invoices', Icons.receipt_long_rounded, 106),
            _RoleMenuItem('Payments', Icons.payments_rounded, 106),
            _RoleMenuItem('Expenses', Icons.price_change_rounded, 106),
            _RoleMenuItem('12% Partner Settlements', Icons.handshake_rounded, 106),
            _RoleMenuItem('Financial Reports', Icons.summarize_rounded, 8),
          ],
        );
      case SidebarRoleView.manager:
        return _buildRoleList(
          title: 'Team Manager',
          badgeColor: const Color(0xFF2563EB),
          icon: Icons.supervised_user_circle_rounded,
          items: [
            _RoleMenuItem('Dashboard', Icons.dashboard_rounded, 0),
            _RoleMenuItem('My Team', Icons.groups_rounded, 1),
            _RoleMenuItem('Team Tasks', Icons.checklist_rounded, 2),
            _RoleMenuItem('Approvals', Icons.verified_user_rounded, 4),
            _RoleMenuItem('Attendance (Team)', Icons.alarm_on_rounded, 3),
            _RoleMenuItem('Leave Requests', Icons.event_busy_rounded, 4),
            _RoleMenuItem('Performance (Team)', Icons.trending_up_rounded, 119),
            _RoleMenuItem('Reports', Icons.analytics_rounded, 8),
          ],
        );
      case SidebarRoleView.employee:
        return _buildRoleList(
          title: 'Team Member',
          badgeColor: const Color(0xFF059669),
          icon: Icons.person_rounded,
          items: [
            _RoleMenuItem('Dashboard', Icons.dashboard_rounded, 0),
            _RoleMenuItem('My Profile', Icons.badge_rounded, 1),
            _RoleMenuItem('My Tasks', Icons.task_alt_rounded, 2),
            _RoleMenuItem('My Attendance', Icons.fingerprint_rounded, 3),
            _RoleMenuItem('My Leave', Icons.beach_access_rounded, 4),
            _RoleMenuItem('My Approvals', Icons.assignment_turned_in_rounded, 4),
            _RoleMenuItem('My Reports', Icons.insert_chart_outlined_rounded, 8),
            _RoleMenuItem('Help & Support', Icons.help_outline_rounded, 111),
          ],
        );
      default:
        return _buildSuperAdminMenu();
    }
  }

  Widget _buildRoleList({
    required String title,
    required Color badgeColor,
    required IconData icon,
    required List<_RoleMenuItem> items,
  }) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      children: [
        // Role Header Pill
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: badgeColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: badgeColor,
                child: Icon(icon, color: Colors.white, size: 14),
              ),
              if (!_isCollapsed) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _currentRoleView = SidebarRoleView.superAdmin),
                  child: const Icon(Icons.close_rounded, color: Colors.grey, size: 16),
                ),
              ],
            ],
          ),
        ),

        // Role Menu Items
        ...items.map((item) => _buildNavTile(
              index: item.index,
              title: item.title,
              icon: item.icon,
            )),
      ],
    );
  }

  // ===========================================================================
  // 4. NAV TILE RENDERER (DARK SAAS HIGHLIGHT WITH RED BADGE & CHEVRONS)
  // ===========================================================================
  Widget _buildNavTile({
    required int index,
    required String title,
    required IconData icon,
    int? badgeCount,
    Color? badgeColor,
    bool hasChevron = false,
    String? flyoutKey,
    Color? accentColor,
  }) {
    final isSelected = widget.selectedIndex == index;
    final isFlyoutOpen = _expandedFlyoutKey == flyoutKey && flyoutKey != null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1.5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          hoverColor: const Color(0xFF1E293B).withOpacity(0.6),
          onTap: () {
            if (hasChevron && flyoutKey != null && !_isCollapsed) {
              setState(() {
                _expandedFlyoutKey = _expandedFlyoutKey == flyoutKey ? null : flyoutKey;
              });
            } else {
              setState(() => _expandedFlyoutKey = null);
              widget.onItemSelected(index);
            }
          },
          child: Tooltip(
            message: _isCollapsed ? title : '',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.symmetric(
                horizontal: _isCollapsed ? 8 : 12,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : (isFlyoutOpen ? const Color(0xFF1E293B) : Colors.transparent),
              ),
              child: Row(
                mainAxisAlignment: _isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        icon,
                        size: 19,
                        color: isSelected
                            ? Colors.white
                            : (accentColor ?? const Color(0xFFCBD5E1)),
                      ),
                      if (_isCollapsed && badgeCount != null && badgeCount > 0)
                        Positioned(
                          right: -3,
                          top: -3,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: badgeColor ?? const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF0F172A), width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (!_isCollapsed) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badgeCount != null && badgeCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor ?? const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (hasChevron) ...[
                      const SizedBox(width: 4),
                      Icon(
                        isFlyoutOpen ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                        size: 16,
                        color: const Color(0xFF64748B),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 5. USER FOOTER CARD WITH ONLINE STATUS PILL
  // ===========================================================================
  Widget _buildUserFooter(AuthUser? user) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _isCollapsed ? 10 : 14, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF090E17),
        border: Border(top: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xFF2563EB),
            child: Text(
              ((user?.name ?? 'A')[0]).toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          if (!_isCollapsed) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user?.name ?? 'Akarshan Mishra',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Online · Super Admin',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8), size: 18),
              color: const Color(0xFF1E293B),
              onSelected: (val) {
                if (val == 'switch_view') {
                  _showRoleSwitchDialog();
                } else if (val == 'impersonate') {
                  widget.onImpersonate?.call();
                } else if (val == 'dept') {
                  widget.onSwitchDepartment?.call();
                } else if (val == 'logout') {
                  widget.onLogout?.call();
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'switch_view',
                  child: Row(
                    children: [
                      Icon(Icons.dashboard_customize_rounded, color: Colors.blue, size: 16),
                      SizedBox(width: 8),
                      Text('Switch Role Sidebar', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'impersonate',
                  child: Row(
                    children: [
                      Icon(Icons.remove_red_eye_rounded, color: Colors.amber, size: 16),
                      SizedBox(width: 8),
                      Text('View As (Impersonate)', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'dept',
                  child: Row(
                    children: [
                      Icon(Icons.swap_calls_rounded, color: Colors.pink, size: 16),
                      SizedBox(width: 8),
                      Text('Department Views', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.redAccent, size: 16),
                      SizedBox(width: 8),
                      Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showRoleSwitchDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Select Role Sidebar View', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRoleOption(SidebarRoleView.superAdmin, 'Super Admin Full Sidebar', Icons.admin_panel_settings, Colors.blue),
            _buildRoleOption(SidebarRoleView.hr, 'HR Department View', Icons.badge, const Color(0xFFF43F5E)),
            _buildRoleOption(SidebarRoleView.it, 'IT Department View', Icons.computer, const Color(0xFF0284C7)),
            _buildRoleOption(SidebarRoleView.marketing, 'Marketing View', Icons.campaign, const Color(0xFF10B981)),
            _buildRoleOption(SidebarRoleView.operations, 'Operations View', Icons.settings_suggest, const Color(0xFFF59E0B)),
            _buildRoleOption(SidebarRoleView.accounts, 'Accounts & Finance View', Icons.account_balance_wallet, const Color(0xFF8B5CF6)),
            _buildRoleOption(SidebarRoleView.manager, 'Team Manager View', Icons.supervised_user_circle, const Color(0xFF2563EB)),
            _buildRoleOption(SidebarRoleView.employee, 'Employee View', Icons.person, const Color(0xFF059669)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleOption(SidebarRoleView role, String title, IconData icon, Color color) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color, size: 18)),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      onTap: () {
        Navigator.pop(context);
        setState(() {
          _currentRoleView = role;
          _expandedFlyoutKey = null;
        });
      },
    );
  }

  // ===========================================================================
  // 6. EXPANDED FLYOUT PANEL
  // ===========================================================================
  Widget _buildFlyoutPanel() {
    final title = _getFlyoutTitle(_expandedFlyoutKey);

    return Container(
      width: 680,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          right: BorderSide(color: Color(0xFFE2E8F0)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(10, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                const Icon(Icons.groups_rounded, color: Color(0xFF1E293B), size: 24),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => setState(() => _expandedFlyoutKey = null),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildFlyoutColumn(
                      'Management & Actions',
                      [
                        _FlyoutItem('Directory Overview', Icons.groups_rounded, isSelected: true, onTap: () {
                          widget.onItemSelected(1);
                          setState(() => _expandedFlyoutKey = null);
                        }),
                        _FlyoutItem('Add New Entry', Icons.person_add_alt_1_rounded, onTap: () {
                          widget.onAddEmployee?.call();
                          setState(() => _expandedFlyoutKey = null);
                        }),
                        _FlyoutItem('Lifecycle Workflows', Icons.timeline_rounded, onTap: () {
                          widget.onItemSelected(7);
                          setState(() => _expandedFlyoutKey = null);
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildFlyoutColumn(
                      'Attendance & Leave',
                      [
                        _FlyoutItem('Attendance Hub', Icons.access_time_rounded, onTap: () {
                          widget.onItemSelected(3);
                          setState(() => _expandedFlyoutKey = null);
                        }),
                        _FlyoutItem('Leave Requests', Icons.event_note_rounded, onTap: () {
                          widget.onItemSelected(4);
                          setState(() => _expandedFlyoutKey = null);
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildFlyoutColumn(
                      'Reports & Audit',
                      [
                        _FlyoutItem('Performance Insights', Icons.insights_rounded, onTap: () {
                          widget.onItemSelected(119);
                          setState(() => _expandedFlyoutKey = null);
                        }),
                        _FlyoutItem('Analytics Summary', Icons.bar_chart_rounded, onTap: () {
                          widget.onItemSelected(8);
                          setState(() => _expandedFlyoutKey = null);
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                _buildQuickActionBtn('+ Add Employee', Icons.person_add, const Color(0xFF2563EB), () {
                  setState(() => _expandedFlyoutKey = null);
                  widget.onAddEmployee?.call();
                }),
                const SizedBox(width: 10),
                _buildQuickActionBtn('Mark Attendance', Icons.calendar_today, const Color(0xFF10B981), () {
                  setState(() => _expandedFlyoutKey = null);
                  widget.onMarkAttendance?.call();
                }),
                const SizedBox(width: 10),
                _buildQuickActionBtn('Approve Leave', Icons.check_circle_outline, const Color(0xFFF59E0B), () {
                  setState(() => _expandedFlyoutKey = null);
                  widget.onApproveLeave?.call();
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getFlyoutTitle(String? key) {
    switch (key) {
      case 'employees':
        return 'Employees';
      case 'hr':
        return 'HR Department';
      case 'it':
        return 'IT Department';
      case 'marketing':
        return 'Marketing Department';
      case 'operations':
        return 'Operations Department';
      case 'accounts':
        return 'Accounts & Finance';
      case 'workflows':
        return 'Tasks & Workflows';
      default:
        return 'Module Menu';
    }
  }

  Widget _buildFlyoutColumn(String title, List<_FlyoutItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 10),
        ...items.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 4),
              child: Material(
                color: item.isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: item.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          size: 15,
                          color: item.isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 12,
                              color: item.isSelected ? const Color(0xFF2563EB) : const Color(0xFF334155),
                              fontWeight: item.isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildQuickActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleMenuItem {
  final String title;
  final IconData icon;
  final int index;

  _RoleMenuItem(this.title, this.icon, this.index);
}

class _FlyoutItem {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  _FlyoutItem(this.title, this.icon, {this.isSelected = false, required this.onTap});
}

// ===========================================================================
// PARTYBALA 4-PETAL COLORFUL CLOVER LOGO PAINTER
// ===========================================================================
class _PartyBalaLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.28;
    final offset = size.width * 0.18;

    // 1. Top-Left Petal (Orange-Red #F97316)
    final paint1 = Paint()..color = const Color(0xFFF97316);
    canvas.drawCircle(Offset(center.dx - offset, center.dy - offset), radius, paint1);

    // 2. Top-Right Petal (Sky Blue #0EA5E9)
    final paint2 = Paint()..color = const Color(0xFF0EA5E9);
    canvas.drawCircle(Offset(center.dx + offset, center.dy - offset), radius, paint2);

    // 3. Bottom-Left Petal (Purple/Violet #8B5CF6)
    final paint3 = Paint()..color = const Color(0xFF8B5CF6);
    canvas.drawCircle(Offset(center.dx - offset, center.dy + offset), radius, paint3);

    // 4. Bottom-Right Petal (Pink/Rose #EC4899)
    final paint4 = Paint()..color = const Color(0xFFEC4899);
    canvas.drawCircle(Offset(center.dx + offset, center.dy + offset), radius, paint4);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
