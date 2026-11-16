
import 'package:flutter/material.dart';
import '../services/task_service.dart';

class AddTaskScreen extends StatefulWidget {
  final String token;

  const AddTaskScreen({
    super.key,
    required this.token,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  late TaskService taskService;

  DateTime? startDate;
  DateTime? dueDate;

  String priority = 'medium';
  String status = 'todo';

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    taskService = TaskService(token: widget.token);
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> selectDate(bool isStartDate) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (startDate ?? DateTime.now())
          : (dueDate ?? startDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: isStartDate
          ? 'Chọn ngày bắt đầu'
          : 'Chọn hạn hoàn thành',
    );

    if (selected != null) {
      setState(() {
        if (isStartDate) {
          startDate = selected;
        } else {
          dueDate = selected;
        }
      });
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'Chưa chọn';

    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    if (startDate != null &&
        dueDate != null &&
        startDate!.isAfter(dueDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ngày bắt đầu không được sau hạn hoàn thành'),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await taskService.createTask(
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        startDate: startDate,
        dueDate: dueDate,
        priority: priority,
        status: status,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo công việc thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
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
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Tạo công việc',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông tin công việc',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Tên công việc *',
                  hintText: 'Nhập tên công việc',
                  prefixIcon: Icon(Icons.task_alt),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên công việc';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  hintText: 'Nhập mô tả công việc',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Thời gian',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.calendar_today,
                    color: Colors.deepPurple,
                  ),
                  title: const Text('Ngày bắt đầu'),
                  subtitle: Text(formatDate(startDate)),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: () => selectDate(true),
                ),
              ),

              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.event,
                    color: Colors.deepPurple,
                  ),
                  title: const Text('Hạn hoàn thành'),
                  subtitle: Text(formatDate(dueDate)),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: () => selectDate(false),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Mức độ ưu tiên',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: priority,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'low',
                    child: Text('Thấp'),
                  ),
                  DropdownMenuItem(
                    value: 'medium',
                    child: Text('Trung bình'),
                  ),
                  DropdownMenuItem(
                    value: 'high',
                    child: Text('Cao'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => priority = value);
                  }
                },
              ),

              const SizedBox(height: 20),

              const Text(
                'Trạng thái ban đầu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sync),
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
                    setState(() => status = value);
                  }
                },
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : saveTask,
                  icon: isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.save),
                  label: Text(
                    isSaving ? 'Đang lưu...' : 'Lưu công việc',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
