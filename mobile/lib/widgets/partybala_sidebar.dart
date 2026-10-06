import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/auth_user.dart';
import '../providers/auth_provider.dart';

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
  final TextEditingController _menuSearchController = TextEditingController();
  String _menuFilter = '';

  @override
  void dispose() {
    _menuSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isCollapsed ? 76 : 280,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Dark Slate Navy Theme
        border: Border(right: BorderSide(color: Color(0xFF1E293B), width: 1.5)),
      ),
      child: Column(
        children: [
          // 1. Brand Header
          _buildHeader(),

          // 2. Menu Quick Search Filter (when expanded)
          if (!_isCollapsed) _buildMenuSearchBar(),

          // 3. Unified All-in-One Master Menu List
          Expanded(
            child: _buildUnifiedMasterMenu(),
          ),

          // 4. User Footer Card with Status Pill & Logout
          _buildUserFooter(user),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. BRAND HEADER WITH PARTYBALA FLOWER LOGO
  // ===========================================================================
  Widget _buildHeader() {
    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: _isCollapsed ? 12 : 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 1)),
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
                    'PartyBala CRM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Enterprise Control Center',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                _isCollapsed ? Icons.menu_open_rounded : Icons.menu_rounded,
                color: const Color(0xFFCBD5E1),
                size: 22,
              ),
              tooltip: _isCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
              onPressed: () => setState(() => _isCollapsed = !_isCollapsed),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPartyBalaFlowerLogo() {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _isCollapsed = !_isCollapsed),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF334155), width: 1),
        ),
        padding: const EdgeInsets.all(6),
        child: CustomPaint(
          painter: _PartyBalaLogoPainter(),
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. QUICK MENU SEARCH FILTER
  // ===========================================================================
  Widget _buildMenuSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: SizedBox(
        height: 36,
        child: TextField(
          controller: _menuSearchController,
          onChanged: (val) => setState(() => _menuFilter = val.trim().toLowerCase()),
          style: const TextStyle(color: Colors.white, fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Filter menu items...',
            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
            prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
            suffixIcon: _menuFilter.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 14, color: Color(0xFF94A3B8)),
                    onPressed: () {
                      _menuSearchController.clear();
                      setState(() => _menuFilter = '');
                    },
                  )
                : null,
            contentPadding: EdgeInsets.zero,
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. UNIFIED ALL-IN-ONE MASTER MENU LIST (ALL 4 PERSPECTIVES IN ONE SIDEBAR)
  // ===========================================================================
  Widget _buildUnifiedMasterMenu() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      children: [
        // 🏠 1. MAIN CONTROL HUB
        _buildNavTile(
          index: 0,
          title: 'Dashboard',
          icon: Icons.home_rounded,
        ),

        // 🌐 2. GLOBAL ENTERPRISE
        _buildSectionHeader('GLOBAL WORKSPACE'),
        _buildNavTile(
          index: 100,
          title: 'Global Omnisearch',
          icon: Icons.search_rounded,
          accentColor: const Color(0xFF38BDF8),
        ),
        _buildNavTile(
          index: 101,
          title: 'Notification Studio',
          icon: Icons.notifications_active_rounded,
          badgeCount: 12,
          accentColor: const Color(0xFFFBBF24),
        ),
        _buildNavTile(
          index: 4,
          title: 'Approvals Hub',
          icon: Icons.check_circle_rounded,
          badgeCount: 8,
          accentColor: const Color(0xFF34D399),
        ),
        _buildNavTile(
          index: 114,
          title: 'Master Calendar',
          icon: Icons.calendar_month_rounded,
          accentColor: const Color(0xFFA78BFA),
        ),

        // 👥 3. PEOPLE & ORGANIZATION
        _buildSectionHeader('PEOPLE & ORGANIZATION'),
        _buildNavTile(
          index: 1,
          title: 'Employees Directory',
          icon: Icons.groups_rounded,
          accentColor: const Color(0xFF60A5FA),
        ),
        _buildNavTile(
          index: 115,
          title: 'Departments Hierarchy',
          icon: Icons.apartment_rounded,
          accentColor: const Color(0xFFFB7185),
        ),
        _buildNavTile(
          index: 116,
          title: 'Positions & Job Roles',
          icon: Icons.business_center_rounded,
          accentColor: const Color(0xFFFBBF24),
        ),
        _buildNavTile(
          index: 6,
          title: 'Roles & RBAC Matrix',
          icon: Icons.lock_person_rounded,
          accentColor: const Color(0xFFC084FC),
        ),

        // 🏢 4. DEPARTMENTS (CROSS-FUNCTIONAL CONTROL TOWERS)
        _buildSectionHeader('DEPARTMENT TOWERS'),
        _buildNavTile(
          index: 102,
          title: 'HR Department',
          icon: Icons.people_alt_rounded,
          accentColor: const Color(0xFFFB7185), // Pink
        ),
        _buildNavTile(
          index: 103,
          title: 'IT & Infrastructure',
          icon: Icons.laptop_chromebook_rounded,
          accentColor: const Color(0xFF38BDF8), // Sky Blue
        ),
        _buildNavTile(
          index: 104,
          title: 'Marketing & Growth',
          icon: Icons.campaign_rounded,
          accentColor: const Color(0xFF34D399), // Emerald
        ),
        _buildNavTile(
          index: 105,
          title: 'Operations & Events',
          icon: Icons.settings_suggest_rounded,
          accentColor: const Color(0xFFFBBF24), // Amber
        ),
        _buildNavTile(
          index: 106,
          title: 'Accounts & Finance',
          icon: Icons.monetization_on_rounded,
          accentColor: const Color(0xFFA78BFA), // Purple
        ),
        _buildNavTile(
          index: 117,
          title: 'Executive Management',
          icon: Icons.military_tech_rounded,
          accentColor: const Color(0xFF60A5FA), // Blue
        ),

        // 📋 5. WORK & OPERATIONS
        _buildSectionHeader('WORK & OPERATIONS'),
        _buildNavTile(
          index: 7,
          title: 'Tasks & Workflows',
          icon: Icons.assignment_turned_in_rounded,
          badgeCount: 24,
          accentColor: const Color(0xFF38BDF8),
        ),
        _buildNavTile(
          index: 107,
          title: 'Projects Portfolio',
          icon: Icons.folder_copy_rounded,
          accentColor: const Color(0xFFFBBF24),
        ),
        _buildNavTile(
          index: 108,
          title: 'Tickets & SLA Support',
          icon: Icons.headphones_rounded,
          badgeCount: 6,
          accentColor: const Color(0xFFFB7185),
        ),
        _buildNavTile(
          index: 118,
          title: 'Leads, Partners & Bookings',
          icon: Icons.handshake_rounded,
          accentColor: const Color(0xFF34D399),
        ),

        // 📊 6. REPORTS & ANALYTICS
        _buildSectionHeader('REPORTS & ANALYTICS'),
        _buildNavTile(
          index: 8,
          title: 'Reports & Analytics',
          icon: Icons.bar_chart_rounded,
          accentColor: const Color(0xFF818CF8),
        ),
        _buildNavTile(
          index: 119,
          title: 'Performance & Insights',
          icon: Icons.insights_rounded,
          accentColor: const Color(0xFF34D399),
        ),

        // 🛡️ 7. SYSTEM, SECURITY & SYNC
        _buildSectionHeader('SYSTEM & SECURITY'),
        _buildNavTile(
          index: 10,
          title: 'Settings & Config',
          icon: Icons.tune_rounded,
          accentColor: const Color(0xFF94A3B8),
        ),
        _buildNavTile(
          index: 120,
          title: 'Security Center & MFA',
          icon: Icons.shield_rounded,
          badgeCount: 3,
          accentColor: const Color(0xFFEF4444),
        ),
        _buildNavTile(
          index: 9,
          title: 'Immutable Audit Logs',
          icon: Icons.history_edu_rounded,
          accentColor: const Color(0xFFFBBF24),
        ),
        _buildNavTile(
          index: 113,
          title: 'Offline Sync Center',
          icon: Icons.cloud_sync_rounded,
          accentColor: const Color(0xFF34D399),
        ),
        _buildNavTile(
          index: 112,
          title: 'Device Fleet Health',
          icon: Icons.phonelink_setup_rounded,
          accentColor: const Color(0xFF38BDF8),
        ),
        _buildNavTile(
          index: 111,
          title: 'Help & Knowledge Base',
          icon: Icons.help_outline_rounded,
          accentColor: const Color(0xFFA78BFA),
        ),
      ],
    );
  }

  // ===========================================================================
  // SECTION HEADER WITH ULTRA-LEGIBLE TEXT
  // ===========================================================================
  Widget _buildSectionHeader(String title) {
    if (_menuFilter.isNotEmpty) return const SizedBox.shrink();

    if (_isCollapsed) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Divider(color: Color(0xFF1E293B), height: 1),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF94A3B8), // High-contrast Light Slate
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  // ===========================================================================
  // HIGH-CONTRAST ULTRA-LEGIBLE NAVIGATION TILE
  // ===========================================================================
  Widget _buildNavTile({
    required int index,
    required String title,
    required IconData icon,
    int? badgeCount,
    Color? badgeColor,
    Color? accentColor,
  }) {
    // Filter matching
    if (_menuFilter.isNotEmpty && !title.toLowerCase().contains(_menuFilter)) {
      return const SizedBox.shrink();
    }

    final isSelected = widget.selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          hoverColor: const Color(0xFF1E293B),
          onTap: () {
            widget.onItemSelected(index);
          },
          child: Tooltip(
            message: _isCollapsed ? title : '',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.symmetric(
                horizontal: _isCollapsed ? 10 : 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isSelected ? const Color(0xFF2563EB) : Colors.transparent, // Royal Blue when selected
              ),
              child: Row(
                mainAxisAlignment: _isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: isSelected
                            ? Colors.white
                            : (accentColor ?? const Color(0xFFE2E8F0)), // Bright high-contrast icon
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
                          color: isSelected ? Colors.white : const Color(0xFFF1F5F9), // Pure visible text
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 13.5,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badgeCount != null && badgeCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white24 : (badgeColor ?? const Color(0xFFEF4444)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
  // 4. USER FOOTER WITH VISIBLE TEXT & ROLE INFO
  // ===========================================================================
  Widget _buildUserFooter(AuthUser? user) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _isCollapsed ? 10 : 14, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF090E17),
        border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF2563EB),
            child: Text(
              ((user?.name ?? 'A')[0]).toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981), // Emerald Green
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Online · Super Admin',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8), size: 20),
              color: const Color(0xFF1E293B),
              onSelected: (val) {
                if (val == 'impersonate') {
                  widget.onImpersonate?.call();
                } else if (val == 'dept') {
                  widget.onSwitchDepartment?.call();
                } else if (val == 'logout') {
                  widget.onLogout?.call();
                }
              },
              itemBuilder: (ctx) => [
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
                      Text('Department Switcher', style: TextStyle(color: Colors.white, fontSize: 12)),
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
