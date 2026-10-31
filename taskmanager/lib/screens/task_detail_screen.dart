
import 'package:flutter/material.dart';
import '../services/task_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TaskService taskService = TaskService();

  late Future<Map<String, dynamic>> taskFuture;

  @override
  void initState() {
    super.initState();
    taskFuture = taskService.getTaskDetail(widget.taskId);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Chi tiết công việc'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: taskFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Lỗi tải dữ liệu: ${snapshot.error}'),
            );
          }

          final task = snapshot.data!;
          final status = task['status'] ?? 'todo';

          final creator = task['createdBy'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.assignment_rounded,
                  size: 55,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 20),
                Text(
                  task['title'] ?? 'Không có tiêu đề',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 25),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mô tả công việc',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          task['description'] ?? 'Không có mô tả',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Divider(height: 30),
                        const Text(
                          'Trạng thái',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Chip(
                          label: Text(
                            getStatusText(status),
                            style: TextStyle(
                              color: getStatusColor(status),
                            ),
                          ),
                          backgroundColor:
                          getStatusColor(status).withOpacity(0.12),
                        ),
                        const Divider(height: 30),
                        const Text(
                          'Người tạo công việc',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(creator?['name'] ?? 'Không xác định'),
                        Text(creator?['email'] ?? ''),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
