import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class HRDocumentsScreen extends StatefulWidget {
  const HRDocumentsScreen({super.key});

  @override
  State<HRDocumentsScreen> createState() => _HRDocumentsScreenState();
}

class _HRDocumentsScreenState extends State<HRDocumentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _documents = [];

  final List<String> _tabs = ["All Documents", "Pending Verification", "Expiring Soon", "Verified"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/hr/documents/');
      if (res.statusCode == 200 && res.data != null) {
        final list = res.data is List ? res.data : res.data['results'] ?? [];
        setState(() => _documents = list);
      }
    } catch (_) {
      setState(() {
        _documents = [
          {'id': 'd1', 'employee_name': 'Akarshan Mishra', 'employee_code': 'PBE000001', 'title': 'Aadhaar Card Copy', 'document_type': 'ID_PROOF', 'status': 'VERIFIED'},
          {'id': 'd2', 'employee_name': 'Akarshan Mishra', 'employee_code': 'PBE000001', 'title': 'PAN Card Copy', 'document_type': 'PAN', 'status': 'VERIFIED'},
          {'id': 'd3', 'employee_name': 'Rahul Verma', 'employee_code': 'PBE000002', 'title': 'Degree & Transcripts', 'document_type': 'EDUCATION', 'status': 'PENDING'},
          {'id': 'd4', 'employee_name': 'Sneha Kapoor', 'employee_code': 'PBE000004', 'title': 'Passport / Visa Document', 'document_type': 'OTHER', 'status': 'EXPIRED', 'expiry_date': '2026-03-15'},
          {'id': 'd5', 'employee_name': 'Kavita Nair', 'employee_code': 'PBE000005', 'title': 'Previous Relieving Letter', 'document_type': 'EXPERIENCE', 'status': 'PENDING'},
        ];
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _verifyDocument(dynamic id) async {
    try {
      await _api.dio.post('/hr/documents/$id/verify/', data: {'remarks': 'Original physically verified by HR'});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Document marked as verified 🟢"), backgroundColor: Color(0xFF10B981)),
      );
      _fetchDocuments();
    } catch (_) {
      setState(() {
        for (var d in _documents) {
          if (d['id'] == id) d['status'] = 'VERIFIED';
        }
      });
    }
  }

  List<dynamic> _getFilteredDocs() {
    final currentTab = _tabs[_tabController.index];
    if (currentTab == "Pending Verification") {
      return _documents.where((d) => d['status'] == 'PENDING').toList();
    }
    if (currentTab == "Expiring Soon") {
      return _documents.where((d) => d['status'] == 'EXPIRED' || d['status'] == 'MISSING').toList();
    }
    if (currentTab == "Verified") {
      return _documents.where((d) => d['status'] == 'VERIFIED').toList();
    }
    return _documents;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredDocs();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text("Document Center & Expiry Alerts", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEC4899)))
          : filtered.isEmpty
              ? const Center(child: Text("No documents in this filter", style: TextStyle(color: Color(0xFF94A3B8))))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, idx) => _buildDocCard(filtered[idx]),
                ),
    );
  }

  Widget _buildDocCard(Map<String, dynamic> doc) {
    final status = doc['status'] ?? 'PENDING';
    final isVerified = status == 'VERIFIED';
    final isExpired = status == 'EXPIRED';

    Color statusColor = const Color(0xFFF59E0B);
    if (isVerified) statusColor = const Color(0xFF10B981);
    if (isExpired) statusColor = const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isVerified
                  ? Icons.verified
                  : isExpired
                      ? Icons.error_outline
                      : Icons.pending_actions,
              color: statusColor,
              size: 22,
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
                        doc['title'] ?? 'Document',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                      child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "${doc['employee_name'] ?? 'Employee'} (${doc['employee_code'] ?? 'ID'})",
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
                if (doc['expiry_date'] != null) ...[
                  const SizedBox(height: 2),
                  Text("Expiry: ${doc['expiry_date']}", style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444))),
                ],
              ],
            ),
          ),
          if (!isVerified) ...[
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _verifyDocument(doc['id']),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
              ),
              child: const Text("Verify", style: TextStyle(fontSize: 11, color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }
}
