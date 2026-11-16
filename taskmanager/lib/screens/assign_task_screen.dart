
import 'package:flutter/material.dart';
import '../services/task_service.dart';

class AssignTaskScreen extends StatefulWidget {
  final String taskId;
  final String token;

  const AssignTaskScreen({
    super.key,
    required this.taskId,
    required this.token,
  });

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  late TaskService taskService;

  final TextEditingController searchController =
  TextEditingController();

  List<dynamic> searchResults = [];
  final Map<String, Map<String, dynamic>> selectedUsers = {};

  String? primaryAssignee;
  bool isSearching = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    taskService = TaskService(token: widget.token);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> searchUsers(String keyword) async {
    if (keyword.trim().isEmpty) {
      setState(() {
        searchResults = [];
        isSearching = false;
      });
      return;
    }

    setState(() {
      isSearching = true;
    });

    try {
      final results = await taskService.searchUsers(keyword.trim());

      if (!mounted) return;

      setState(() {
        searchResults = results;
        isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSearching = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tìm người dùng: $e')),
      );
    }
  }

  void toggleUser(Map<String, dynamic> user) {
    final userId = user['_id']?.toString();

    if (userId == null) return;

    setState(() {
      if (selectedUsers.containsKey(userId)) {
        selectedUsers.remove(userId);

        if (primaryAssignee == userId) {
          primaryAssignee = null;
        }
      } else {
        selectedUsers[userId] = user;

        if (primaryAssignee == null) {
          primaryAssignee = userId;
        }
      }
    });
  }

  Future<void> saveAssignment() async {
    if (selectedUsers.isNotEmpty && primaryAssignee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hãy chọn người phụ trách chính'),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await taskService.assignTask(
        taskId: widget.taskId,
        assignees: selectedUsers.keys.toList(),
        primaryAssignee: primaryAssignee,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giao công việc thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Giao công việc thất bại: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giao công việc'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tìm người dùng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: searchController,
              onChanged: searchUsers,
              decoration: InputDecoration(
                hintText: 'Nhập tên hoặc email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    searchUsers('');
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Kết quả tìm kiếm',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: isSearching
                  ? const Center(
                child: CircularProgressIndicator(),
              )
                  : searchResults.isEmpty
                  ? const Center(
                child: Text('Không tìm thấy người dùng'),
              )
                  : ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final user =
                  Map<String, dynamic>.from(
                    searchResults[index],
                  );

                  final userId = user['_id']?.toString();
                  final isSelected =
                  selectedUsers.containsKey(userId);

                  return Card(
                    child: CheckboxListTile(
                      value: isSelected,
                      onChanged: (_) => toggleUser(user),
                      secondary: CircleAvatar(
                        child: Text(
                          (user['name'] ?? 'U')
                              .toString()
                              .substring(0, 1)
                              .toUpperCase(),
                        ),
                      ),
                      title: Text(
                        user['name'] ?? 'Không có tên',
                      ),
                      subtitle: Text(
                        user['email'] ?? '',
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(),

            const Text(
              'Người được giao',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            if (selectedUsers.isEmpty)
              const Text(
                'Chưa chọn người dùng nào',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...selectedUsers.entries.map((entry) {
                final userId = entry.key;
                final user = entry.value;

                return RadioListTile<String>(
                  value: userId,
                  groupValue: primaryAssignee,
                  onChanged: (value) {
                    setState(() {
                      primaryAssignee = value;
                    });
                  },
                  title: Text(user['name'] ?? 'Người dùng'),
                  subtitle: Text(
                    userId == primaryAssignee
                        ? 'Người phụ trách chính'
                        : 'Người được giao',
                  ),
                  secondary: IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                    ),
                    onPressed: () => toggleUser(user),
                  ),
                );
              }),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : saveAssignment,
                icon: isSaving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.assignment_turned_in),
                label: Text(
                  isSaving ? 'Đang lưu...' : 'Lưu giao việc',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
