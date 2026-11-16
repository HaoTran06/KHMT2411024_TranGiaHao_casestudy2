
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import 'task_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  final String token;

  const NotificationScreen({
    super.key,
    required this.token,
  });

  @override
  State<NotificationScreen> createState() =>
      _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late NotificationService notificationService;

  List<dynamic> notifications = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    notificationService =
        NotificationService(token: widget.token);
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      final data =
      await notificationService.getNotifications();

      if (!mounted) return;

      setState(() {
        notifications = data;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  String formatDate(dynamic value) {
    if (value == null) return '';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return '';

    final localDate = date.toLocal();

    String twoDigits(int number) =>
        number.toString().padLeft(2, '0');

    return '${twoDigits(localDate.day)}/'
        '${twoDigits(localDate.month)}/'
        '${localDate.year} '
        '${twoDigits(localDate.hour)}:'
        '${twoDigits(localDate.minute)}';
  }

  Future<void> openNotification(
      Map<String, dynamic> notification) async {
    final notificationId =
    notification['_id']?.toString();

    final task = notification['task'];

    final taskId = task is Map
        ? task['_id']?.toString()
        : task?.toString();

    if (taskId == null || taskId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Công việc này không còn tồn tại!'),
        ),
      );
      await loadNotifications();
      return;
    }

    try {
      if (notification['isRead'] != true &&
          notificationId != null) {
        await notificationService.markAsRead(
            notificationId);
      }

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TaskDetailScreen(
            taskId: taskId,
            token: widget.token,
          ),
        ),
      );

      if (mounted) {
        await loadNotifications();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadNotifications,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Text(errorMessage!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: loadNotifications,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      )
          : notifications.isEmpty
          ? const Center(
        child: Text('Chưa có thông báo nào'),
      )
          : RefreshIndicator(
        onRefresh: loadNotifications,
        child: ListView.builder(
          physics:
          const AlwaysScrollableScrollPhysics(),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final item =
            Map<String, dynamic>.from(
                notifications[index]);

            final sender = item['sender'];
            final task = item['task'];

            final senderName = sender is Map
                ? sender['name']?.toString() ??
                sender['email']?.toString() ??
                'Người dùng'
                : 'Người dùng';

            final taskTitle = task is Map
                ? task['title']?.toString() ??
                'Công việc'
                : 'Công việc';

            final isRead =
                item['isRead'] == true;

            final isAssigned =
                item['type'] == 'assigned';

            return Card(
              margin: const EdgeInsets
                  .symmetric(
                horizontal: 12,
                vertical: 5,
              ),
              color: isRead
                  ? null
                  : Colors.teal.withValues(
                alpha: 0.08,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isAssigned
                      ? Colors.blue.shade100
                      : Colors.orange.shade100,
                  child: Icon(
                    isAssigned
                        ? Icons.assignment_ind
                        : Icons.share,
                    color: isAssigned
                        ? Colors.blue
                        : Colors.orange,
                  ),
                ),
                title: Text(
                  item['message']?.toString() ??
                      'Bạn có thông báo mới',
                  style: TextStyle(
                    fontWeight: isRead
                        ? FontWeight.normal
                        : FontWeight.bold,
                  ),
                ),
                subtitle: Padding(
                  padding:
                  const EdgeInsets.only(
                    top: 6,
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text('Người gửi: $senderName'),
                      Text('Công việc: $taskTitle'),
                      Text(formatDate(
                          item['createdAt'])),
                    ],
                  ),
                ),
                trailing: Icon(
                  isRead
                      ? Icons.check_circle_outline
                      : Icons.circle,
                  color: isRead
                      ? Colors.grey
                      : Colors.teal,
                  size: 16,
                ),
                onTap: () =>
                    openNotification(item),
              ),
            );
          },
        ),
      ),
    );
  }
}
