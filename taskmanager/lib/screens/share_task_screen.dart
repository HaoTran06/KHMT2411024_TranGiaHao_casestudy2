
import 'package:flutter/material.dart';
import '../services/task_service.dart';

class ShareTaskScreen extends StatefulWidget {
  final String taskId;
  final String token;

  const ShareTaskScreen({
    super.key,
    required this.taskId,
    required this.token,
  });

  @override
  State<ShareTaskScreen> createState() => _ShareTaskScreenState();
}

class _ShareTaskScreenState extends State<ShareTaskScreen> {
  late TaskService taskService;

  final searchController = TextEditingController();

  List<dynamic> users = [];
  List<dynamic> sharedUsers = [];

  bool isSearching = false;
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    taskService = TaskService(token: widget.token);
    loadSharedUsers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadSharedUsers() async {
    try {
      final task = await taskService.getTaskDetail(widget.taskId);

      if (!mounted) return;

      setState(() {
        sharedUsers = task['sharedWith'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage('Không thể tải danh sách chia sẻ: $e');
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> searchUsers(String keyword) async {
    if (keyword.trim().isEmpty) {
      setState(() {
        users = [];
      });
      return;
    }

    setState(() {
      isSearching = true;
    });

    try {
      final result = await taskService.searchUsers(keyword.trim());

      if (!mounted) return;

      setState(() {
        users = result;
        isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSearching = false;
      });

      showMessage('Lỗi tìm người dùng: $e');
    }
  }

  String getUserId(dynamic user) {
    if (user is Map) {
      return (user['_id'] ?? user['id'] ?? '').toString();
    }
    return '';
  }

  String getUserName(dynamic user) {
    if (user is Map) {
      return (user['name'] ?? 'Người dùng').toString();
    }
    return 'Người dùng';
  }

  String getUserEmail(dynamic user) {
    if (user is Map) {
      return (user['email'] ?? '').toString();
    }
    return '';
  }

  String getRole(dynamic item) {
    if (item is Map) {
      return (item['role'] ?? 'viewer').toString();
    }
    return 'viewer';
  }

  dynamic getSharedUser(dynamic item) {
    if (item is Map) {
      return item['user'] ?? item;
    }
    return item;
  }

  bool isAlreadyShared(String userId) {
    return sharedUsers.any((item) {
      final user = getSharedUser(item);
      return getUserId(user) == userId;
    });
  }

  Future<void> shareUser(dynamic user) async {
    final userId = getUserId(user);

    if (userId.isEmpty || isAlreadyShared(userId)) return;

    String selectedRole = 'viewer';

    final role = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Chia sẻ công việc'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chia sẻ với ${getUserName(user)}'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Phân quyền',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'viewer',
                        child: Text('Viewer - Chỉ xem'),
                      ),
                      DropdownMenuItem(
                        value: 'editor',
                        child: Text('Editor - Được chỉnh sửa'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedRole = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, selectedRole);
                  },
                  child: const Text('Chia sẻ'),
                ),
              ],
            );
          },
        );
      },
    );

    if (role == null) return;

    try {
      setState(() {
        isSaving = true;
      });

      await taskService.shareTask(
        taskId: widget.taskId,
        userId: userId,
        role: role,
      );

      await loadSharedUsers();

      if (!mounted) return;

      setState(() {
        isSaving = false;
        users = [];
        searchController.clear();
      });

      showMessage('Chia sẻ công việc thành công');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showMessage('Lỗi chia sẻ: $e');
    }
  }

  Future<void> changeRole(dynamic item) async {
    final user = getSharedUser(item);
    final userId = getUserId(user);

    if (userId.isEmpty) return;

    String selectedRole = getRole(item);

    final role = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Thay đổi quyền'),
              content: DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Phân quyền',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'viewer',
                    child: Text('Viewer - Chỉ xem'),
                  ),
                  DropdownMenuItem(
                    value: 'editor',
                    child: Text('Editor - Được chỉnh sửa'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      selectedRole = value;
                    });
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, selectedRole);
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );

    if (role == null || role == getRole(item)) return;

    try {
      await taskService.shareTask(
        taskId: widget.taskId,
        userId: userId,
        role: role,
      );

      await loadSharedUsers();

      if (!mounted) return;
      showMessage('Đã cập nhật quyền');
    } catch (e) {
      if (!mounted) return;
      showMessage('Lỗi cập nhật quyền: $e');
    }
  }

  Future<void> removeUser(dynamic item) async {
    final user = getSharedUser(item);
    final userId = getUserId(user);

    if (userId.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Thu hồi quyền'),
          content: Text(
            'Mày có chắc muốn thu hồi quyền của ${getUserName(user)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Thu hồi'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await taskService.removeSharedUser(
        taskId: widget.taskId,
        userId: userId,
      );

      await loadSharedUsers();

      if (!mounted) return;
      showMessage('Đã thu hồi quyền chia sẻ');
    } catch (e) {
      if (!mounted) return;
      showMessage('Lỗi thu hồi quyền: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Chia sẻ công việc'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tìm người dùng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Nhập tên hoặc email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    setState(() {
                      users = [];
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              onChanged: searchUsers,
            ),
            const SizedBox(height: 12),

            if (isSearching)
              const Center(child: CircularProgressIndicator()),

            if (!isSearching)
              ...users.map((user) {
                final userId = getUserId(user);
                final alreadyShared = isAlreadyShared(userId);

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(getUserName(user)),
                    subtitle: Text(getUserEmail(user)),
                    trailing: alreadyShared
                        ? const Chip(label: Text('Đã chia sẻ'))
                        : IconButton(
                      icon: const Icon(
                        Icons.share,
                        color: Colors.deepPurple,
                      ),
                      onPressed: isSaving
                          ? null
                          : () => shareUser(user),
                    ),
                  ),
                );
              }),

            const Divider(height: 35),

            const Text(
              'Người đang được chia sẻ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            if (sharedUsers.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Center(
                    child: Text('Chưa chia sẻ công việc với ai'),
                  ),
                ),
              ),

            ...sharedUsers.map((item) {
              final user = getSharedUser(item);
              final role = getRole(item);

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(getUserName(user)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(getUserEmail(user)),
                      Text(
                        role == 'editor'
                            ? 'Editor - Được chỉnh sửa'
                            : 'Viewer - Chỉ xem',
                        style: TextStyle(
                          color: role == 'editor'
                              ? Colors.orange
                              : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'change') {
                        changeRole(item);
                      } else if (value == 'remove') {
                        removeUser(item);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'change',
                        child: Text('Đổi quyền'),
                      ),
                      PopupMenuItem(
                        value: 'remove',
                        child: Text('Thu hồi quyền'),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
