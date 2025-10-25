import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/task_service.dart';
import '../services/user_service.dart';
import '../models/task_model.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with TickerProviderStateMixin {
  final TaskService _taskService = TaskService();
  final UserService _userService = UserService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Tasks'),
            Tab(text: 'Users'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AllTasksTab(taskService: _taskService, userService: _userService),
          _UsersTab(userService: _userService),
        ],
      ),
    );
  }
}

class _AllTasksTab extends StatelessWidget {
  const _AllTasksTab({required this.taskService, required this.userService});

  final TaskService taskService;
  final UserService userService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Task>>(
      stream: taskService.getAllTasks(),
      builder: (context, taskSnap) {
        if (taskSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (taskSnap.hasError) {
          return Center(child: Text('Error loading tasks: ${taskSnap.error}'));
        }
        final tasks = taskSnap.data ?? [];

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final users = {for (var d in userSnap.data?.docs ?? []) d.id: (d.data() as Map<String,dynamic>)['username']?.toString() ?? ''};

            if (tasks.isEmpty) {
              return const Center(child: Text('No tasks'));
            }

            return ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (_, i) {
                final t = tasks[i];
                final owner = users[t.userId] ?? t.userId;
                return ListTile(
                  title: Text(t.title),
                  subtitle: Text('Owner: $owner • Priority: ${t.priority.name}'),
                  trailing: Text('${t.completions.length} done'),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _UsersTab extends StatefulWidget {
  const _UsersTab({required this.userService});
  final UserService userService;

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('No users'));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d = docs[i];
            final data = d.data() as Map<String, dynamic>;
            final username = data['username']?.toString() ?? '';
            final email = data['email']?.toString() ?? '';
            final c = _controllers.putIfAbsent(d.id, () => TextEditingController(text: username));
            return ListTile(
              title: TextField(
                controller: c,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              subtitle: Text(email),
              trailing: ElevatedButton(
                onPressed: () async {
                  final newName = c.text.trim();
                  if (newName.isEmpty) return;
                  await widget.userService.updateUsername(d.id, newName);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Username updated')),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            );
          },
        );
      },
    );
  }
}
