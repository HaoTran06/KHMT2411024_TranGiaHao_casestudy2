
import 'package:flutter/material.dart';
import '../services/task_service.dart';
import 'task_detail_screen.dart';
import 'add_task_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';

class TaskListScreen extends StatefulWidget {
  final String token;

  const TaskListScreen({
    super.key,
    required this.token,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late TaskService taskService;
  late Future<List<dynamic>> tasksFuture;

  @override
  void initState() {
    super.initState();
    taskService = TaskService(token: widget.token);
    tasksFuture = taskService.getTasks();
  }

  String getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Đã hoàn thành';
      case 'in_progress':
        return 'Đang thực hiện';
      default:
        return 'Chưa bắt đầu';
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  Future<void> refreshTasks() async {
    setState(() {
      tasksFuture = taskService.getTasks();
    });

    await tasksFuture;
  }

  Future<void> openTaskDetail(String taskId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(
          taskId: taskId,
          token: widget.token,
        ),
      ),
    );

    if (!mounted) return;
    await refreshTasks();
  }

  Future<void> openAddTaskScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(
          token: widget.token,
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await refreshTasks();
    }
  }

  Future<void> openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationScreen(
          token: widget.token,
        ),
      ),
    );
  }

  Future<void> openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          token: widget.token,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Công việc của tôi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          // Nút hồ sơ cá nhân
          IconButton(
            onPressed: openProfile,
            icon: const Icon(Icons.account_circle),
            tooltip: 'Hồ sơ cá nhân',
          ),

          // Nút thông báo
          IconButton(
            onPressed: openNotifications,
            icon: const Icon(Icons.notifications),
            tooltip: 'Thông báo',
          ),

          // Nút làm mới
          IconButton(
            onPressed: refreshTasks,
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 50,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Lỗi: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: refreshTasks,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final tasks = snapshot.data ?? [];

          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.assignment_outlined,
                    size: 75,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Chưa có công việc nào',
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: openAddTaskScreen,
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo công việc'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: refreshTasks,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                final status = task['status'] ?? 'todo';

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    onTap: () {
                      openTaskDetail(task['_id'].toString());
                    },
                    leading: CircleAvatar(
                      backgroundColor:
                      getStatusColor(status).withOpacity(0.15),
                      child: Icon(
                        Icons.task_alt,
                        color: getStatusColor(status),
                      ),
                    ),
                    title: Text(
                      task['title'] ?? 'Không có tiêu đề',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task['description'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            getStatusText(status),
                            style: TextStyle(
                              color: getStatusColor(status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddTaskScreen,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tạo công việc'),
      ),
    );
  }
}
