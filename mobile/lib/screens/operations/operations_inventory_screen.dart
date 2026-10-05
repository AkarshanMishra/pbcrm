import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class OperationsInventoryScreen extends StatefulWidget {
  const OperationsInventoryScreen({super.key});

  @override
  State<OperationsInventoryScreen> createState() => _OperationsInventoryScreenState();
}

class _OperationsInventoryScreenState extends State<OperationsInventoryScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  String _selectedCategory = "ALL";
  List<dynamic> _assets = [];

  final List<String> _categories = [
    "ALL",
    "AUDIO_VISUAL",
    "POS_DEVICE",
    "FURNITURE",
    "DECOR_PROP",
    "UNIFORM",
    "SAFETY_EQUIPMENT",
    "LOGISTICS",
  ];

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/api/v1/operations/assets/');
      if (res.statusCode == 200 && res.data != null) {
        final results = res.data['results'] ?? res.data;
        if (results is List) {
          _assets = results;
        }
      }
    } catch (e) {
      debugPrint("Load assets error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<dynamic> _getFilteredAssets() {
    if (_selectedCategory == "ALL") return _assets;
    return _assets.where((a) => a['category'] == _selectedCategory).toList();
  }

  void _checkoutAsset(dynamic asset) async {
    try {
      await _api.post('/api/v1/operations/assets/${asset['id']}/checkout/', {});
      _loadAssets();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Checked out ${asset['name']}"), backgroundColor: const Color(0xFF10B981)),
      );
    } catch (e) {
      debugPrint("Checkout err: $e");
    }
  }

  void _checkinAsset(dynamic asset) async {
    try {
      await _api.post('/api/v1/operations/assets/${asset['id']}/checkin/', {'condition': 'EXCELLENT'});
      _loadAssets();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Returned ${asset['name']} to Warehouse"), backgroundColor: const Color(0xFF38BDF8)),
      );
    } catch (e) {
      debugPrint("Checkin err: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          "Equipment & Asset Inventory",
          style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : Column(
              children: <Widget>[
                Container(
                  color: const Color(0xFF1E293B),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final bool isSel = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(cat.replaceAll('_', ' ')),
                            selected: isSel,
                            selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                            backgroundColor: const Color(0xFF0F172A),
                            labelStyle: TextStyle(
                              color: isSel ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                              fontSize: 11,
                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            ),
                            side: BorderSide(color: isSel ? const Color(0xFF10B981) : const Color(0xFF334155)),
                            onSelected: (selected) => setState(() => _selectedCategory = cat),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadAssets,
                    color: const Color(0xFF10B981),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _getFilteredAssets().length,
                      itemBuilder: (context, index) {
                        final item = _getFilteredAssets()[index];
                        final String code = item['asset_code'] ?? 'AST-XXX';
                        final String name = item['name'] ?? 'Asset';
                        final String cat = item['category'] ?? 'OTHER';
                        final String status = item['status'] ?? 'AVAILABLE';
                        final String loc = item['location'] ?? 'Main Warehouse';

                        Color stColor = const Color(0xFF10B981);
                        if (status == 'IN_USE') stColor = const Color(0xFF38BDF8);
                        if (status == 'MAINTENANCE' || status == 'DAMAGED') stColor = const Color(0xFFEF4444);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text(
                                    code,
                                    style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.w800),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: stColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: stColor.withOpacity(0.4)),
                                    ),
                                    child: Text(
                                      status.replaceAll('_', ' '),
                                      style: TextStyle(color: stColor, fontSize: 10, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                name,
                                style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Category: ${cat.replaceAll('_', ' ')} • Loc: $loc",
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: <Widget>[
                                  if (status == 'AVAILABLE')
                                    ElevatedButton.icon(
                                      onPressed: () => _checkoutAsset(item),
                                      icon: const Icon(Icons.outbox_rounded, size: 14),
                                      label: const Text("Dispatch / Check Out"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF38BDF8),
                                        foregroundColor: const Color(0xFF0F172A),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    )
                                  else if (status == 'IN_USE')
                                    ElevatedButton.icon(
                                      onPressed: () => _checkinAsset(item),
                                      icon: const Icon(Icons.move_to_inbox_rounded, size: 14),
                                      label: const Text("Return to Warehouse"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF10B981),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
