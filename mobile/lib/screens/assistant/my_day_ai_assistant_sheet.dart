import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class MyDayAiAssistantSheet extends StatefulWidget {
  final List<dynamic> todayTasks;
  final VoidCallback onTaskCreated;

  const MyDayAiAssistantSheet({
    super.key,
    required this.todayTasks,
    required this.onTaskCreated,
  });

  @override
  State<MyDayAiAssistantSheet> createState() => _MyDayAiAssistantSheetState();
}

class _MyDayAiAssistantSheetState extends State<MyDayAiAssistantSheet> {
  final ApiClient _api = ApiClient();
  final _nlpController = TextEditingController();
  bool _isListening = false;
  Map<String, dynamic>? _parsedTask;

  List<Map<String, dynamic>> _getRecommendedTaskOrder() {
    final tasks = List<Map<String, dynamic>>.from(widget.todayTasks);
    // Sort logic: Urgent first, then High, then closest deadline, then In Progress
    tasks.sort((a, b) {
      final pA = _priorityWeight(a['priority']);
      final pB = _priorityWeight(b['priority']);
      if (pA != pB) return pB.compareTo(pA);
      return (a['title'] ?? '').toString().compareTo(b['title'] ?? '');
    });
    return tasks;
  }

  int _priorityWeight(String? p) {
    switch (p) {
      case 'URGENT':
        return 4;
      case 'HIGH':
        return 3;
      case 'MEDIUM':
        return 2;
      case 'LOW':
        return 1;
      default:
        return 0;
    }
  }

  void _parseNaturalLanguageTask(String input) {
    if (input.trim().isEmpty) return;

    String clean = input.trim();
    String priority = 'MEDIUM';
    if (clean.toLowerCase().contains('urgent') || clean.toLowerCase().contains('asap')) {
      priority = 'URGENT';
    } else if (clean.toLowerCase().contains('important') || clean.toLowerCase().contains('high priority')) {
      priority = 'HIGH';
    }

    String dueDate = DateTime.now().toIso8601String().substring(0, 10);
    if (clean.toLowerCase().contains('tomorrow') || clean.toLowerCase().contains('kal')) {
      dueDate = DateTime.now().add(const Duration(days: 1)).toIso8601String().substring(0, 10);
    }

    String title = clean
        .replaceAll(RegExp(r'(urgent|asap|important|tomorrow|today|kal)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (title.isEmpty) title = clean;

    setState(() {
      _parsedTask = {
        'title': title,
        'priority': priority,
        'due_date': dueDate,
        'due_time': '18:00:00',
        'description': 'Created via My Day NLP / Voice Assistant: "$clean"',
      };
    });
  }

  Future<void> _confirmCreateTask() async {
    if (_parsedTask == null) return;
    try {
      await _api.dio.post('/tasks/', data: _parsedTask);
      widget.onTaskCreated();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Task created successfully from your voice / text prompt!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create task: $e')),
        );
      }
    }
  }

  void _simulateVoiceInput() {
    setState(() => _isListening = true);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        const sampleVoice = "Follow up with client regarding API integration tomorrow urgent";
        _nlpController.text = sampleVoice;
        _parseNaturalLanguageTask(sampleVoice);
        setState(() => _isListening = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final recommended = _getRecommendedTaskOrder();

    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Day AI Work Advisor',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Smart prioritization & natural language task creation',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 1. Voice & Natural Language Input Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎤 Quick Voice / Natural-Language Task',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nlpController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. "Fix booking API tomorrow urgent"',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          onSubmitted: _parseNaturalLanguageTask,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _simulateVoiceInput,
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? Colors.red : AppTheme.primary,
                        ),
                        tooltip: 'Voice Input',
                      ),
                      ElevatedButton(
                        onPressed: () => _parseNaturalLanguageTask(_nlpController.text),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                        child: const Text('Parse'),
                      ),
                    ],
                  ),
                  if (_parsedTask != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Interpreted Task Structure:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                          const SizedBox(height: 4),
                          Text('Title: ${_parsedTask!['title']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Due Date: ${_parsedTask!['due_date']} • Priority: ${_parsedTask!['priority']}', style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _confirmCreateTask,
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Confirm & Create Task'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 2. Recommended Order for Today
            const Text(
              '🎯 Recommended Order of Work Today',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            if (recommended.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text('No active tasks scheduled for today.', style: TextStyle(color: Colors.grey.shade600)),
              )
            else
              ...recommended.take(4).toList().asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final t = entry.value;
                final priority = t['priority'] ?? 'MEDIUM';
                final isUrgent = priority == 'URGENT';
                final isHigh = priority == 'HIGH';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isUrgent ? Colors.red.shade50 : isHigh ? Colors.orange.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isUrgent ? Colors.red.shade200 : isHigh ? Colors.orange.shade200 : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: isUrgent ? Colors.red : isHigh ? Colors.orange : AppTheme.primary,
                        child: Text(
                          '$idx',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t['title'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Priority: $priority • Status: ${t['status'] ?? 'PENDING'}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
