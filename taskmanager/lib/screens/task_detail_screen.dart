
import 'package:flutter/material.dart';
import '../services/task_service.dart';
import 'assign_task_screen.dart';
import 'share_task_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  final String token;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
    required this.token,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TaskService taskService;
  late Future<Map<String, dynamic>> taskFuture;

  @override
  void initState() {
    super.initState();
    taskService = TaskService(token: widget.token);
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

  Future<void> refreshTask() async {
    if (!mounted) return;

    setState(() {
      taskFuture = taskService.getTaskDetail(widget.taskId);
    });
  }

  // Mở màn hình giao việc
  Future<void> openAssignScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignTaskScreen(
          taskId: widget.taskId,
          token: widget.token,
        ),
      ),
    );

    if (result == true && mounted) {
      await refreshTask();
    }
  }

  // Mở màn hình chia sẻ công việc
  Future<void> openShareScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShareTaskScreen(
          taskId: widget.taskId,
          token: widget.token,
        ),
      ),
    );

    if (mounted) {
      await refreshTask();
    }
  }

  // Chỉnh sửa công việc
  Future<void> editTask(Map<String, dynamic> task) async {
    final titleController = TextEditingController(
      text: task['title'] ?? '',
    );

    final descriptionController = TextEditingController(
      text: task['description'] ?? '',
    );

    String selectedStatus = task['status'] ?? 'todo';

    final shouldUpdate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Sửa công việc'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tên công việc',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Trạng thái',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'todo',
                          child: Text('Chưa bắt đầu'),
                        ),
                        DropdownMenuItem(
                          value: 'in_progress',
                          child: Text('Đang thực hiện'),
                        ),
                        DropdownMenuItem(
                          value: 'completed',
                          child: Text('Đã hoàn thành'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedStatus = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Tên công việc không được để trống',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldUpdate == true) {
      try {
        await taskService.updateTask(
          id: widget.taskId,
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          status: selectedStatus,
        );

        if (!mounted) return;

        await refreshTask();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật công việc thành công'),
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: $e')),
        );
      }
    }

    titleController.dispose();
    descriptionController.dispose();
  }

  // Xóa công việc
  Future<void> deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa công việc'),
          content: const Text(
            'Mày có chắc chắn muốn xóa công việc này không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await taskService.deleteTask(widget.taskId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa công việc'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xóa công việc: $e')),
      );
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
        actions: [
          IconButton(
            onPressed: () async {
              try {
                final task = await taskFuture;

                if (!mounted) return;

                await editTask(task);
              } catch (e) {
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Không thể mở chỉnh sửa: $e'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.edit),
            tooltip: 'Sửa công việc',
          ),
          IconButton(
            onPressed: deleteTask,
            icon: const Icon(Icons.delete),
            tooltip: 'Xóa công việc',
          ),
        ],
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
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Lỗi tải dữ liệu: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('Không tìm thấy công việc'),
            );
          }

          final task = snapshot.data!;
          final status = task['status'] ?? 'todo';
          final creator = task['createdBy'];

          final creatorName = creator is Map
              ? creator['name'] ?? 'Không xác định'
              : 'Không xác định';

          final creatorEmail = creator is Map
              ? creator['email'] ?? ''
              : '';

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

                        Text(creatorName.toString()),
                        Text(creatorEmail.toString()),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Nút giao việc
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: openAssignScreen,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Giao việc'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(14),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Nút chia sẻ công việc
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: openShareScreen,
                    icon: const Icon(Icons.share),
                    label: const Text('Chia sẻ công việc'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(14),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Nút chỉnh sửa và xóa
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => editTask(task),
                        icon: const Icon(Icons.edit),
                        label: const Text('Chỉnh sửa'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: deleteTask,
                        icon: const Icon(Icons.delete),
                        label: const Text('Xóa'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
