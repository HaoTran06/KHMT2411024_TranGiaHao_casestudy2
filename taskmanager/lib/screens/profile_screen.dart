
import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String token;

  const ProfileScreen({
    super.key,
    required this.token,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ProfileService profileService;

  Map<String, dynamic>? profileData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    profileService = ProfileService(token: widget.token);
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final result = await profileService.getProfile();

      if (!mounted) return;

      setState(() {
        profileData = result;
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
    if (value == null) return 'Không xác định';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return 'Không xác định';

    final localDate = date.toLocal();

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}';
  }

  Widget buildStatCard(
      String title,
      dynamic value,
      IconData icon,
      Color color,
      ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: loadProfile,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(errorMessage!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: loadProfile,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      )
          : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    final user = profileData?['user'] ?? {};
    final stats = profileData?['statistics'] ?? {};

    return RefreshIndicator(
      onRefresh: loadProfile,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 42,
                    backgroundColor: Colors.deepPurple,
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 45,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    user['name']?.toString() ?? 'Người dùng',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user['email']?.toString() ?? '',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ngày tham gia: ${formatDate(user['createdAt'])}',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Thống kê công việc',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.35,
            children: [
              buildStatCard(
                'Tổng công việc',
                stats['total'] ?? 0,
                Icons.assignment,
                Colors.deepPurple,
              ),
              buildStatCard(
                'Chưa bắt đầu',
                stats['todo'] ?? 0,
                Icons.pending_actions,
                Colors.blue,
              ),
              buildStatCard(
                'Đang thực hiện',
                stats['inProgress'] ?? 0,
                Icons.autorenew,
                Colors.orange,
              ),
              buildStatCard(
                'Đã hoàn thành',
                stats['completed'] ?? 0,
                Icons.task_alt,
                Colors.green,
              ),
              buildStatCard(
                'Đã tạo',
                stats['owned'] ?? 0,
                Icons.create,
                Colors.indigo,
              ),
              buildStatCard(
                'Được giao',
                stats['assigned'] ?? 0,
                Icons.assignment_ind,
                Colors.teal,
              ),
              buildStatCard(
                'Được chia sẻ',
                stats['shared'] ?? 0,
                Icons.share,
                Colors.pink,
              ),
            ],
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: logout,
            icon: const Icon(Icons.logout),
            label: const Text('Đăng xuất'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(15),
            ),
          ),
        ],
      ),
    );
  }
}
