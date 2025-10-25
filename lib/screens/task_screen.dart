import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../services/auth_service.dart';
import '../widgets/task_item.dart';
import '../widgets/task_input.dart';
import '../widgets/task_details_modal.dart';
import '../ui/theme_provider.dart';
import 'friends_screen.dart';
import 'settings_screen.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import 'admin_screen.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final TaskService _taskService = TaskService();
  final AuthService _authService = AuthService();
  final ScrollController _scrollController = ScrollController();
  final UserService _userService = UserService();
  int _tapCount = 0;
  DateTime? _lastTap;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Ensure user profile exists even if the session was persisted
    Future.microtask(() => _userService.ensureCurrentUserProfile());
  }

  void _showTaskDetails(Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskDetailsModal(
        task: task,
        onUpdate: (updatedTask) {
          _taskService.updateTask(updatedTask);
        },
        onDelete: () {
          _taskService.deleteTask(task.id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final fallbackUsername = user?.email?.split('@').first ?? 'User';
    final themeProvider = ThemeProvider.of(context);
    final themeKey = themeProvider?.themeKey ?? 'white';
    final config = themeProvider?.config;
    
    // Use dark text for white theme, white text for others
    final isWhiteTheme = themeKey == 'white';
    final textColor = isWhiteTheme ? Colors.black : Colors.white;
    final subtextColor = isWhiteTheme ? Color(0xFF4b5563) : Colors.white.withOpacity(0.9);

    return GradientScaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          color: config?.gradient[0] ?? Color(0xFFfafafa), // Match theme background color
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleSecretTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<UserProfile?>(
                stream: _userService.streamCurrentUserProfile(),
                builder: (context, snapshot) {
                  final name = snapshot.data?.username.trim();
                  final display = (name != null && name.isNotEmpty) ? name : fallbackUsername;
                  return Text(
                    'Hi $display! 👋',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      shadows: isWhiteTheme ? [] : [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  );
                },
              ),
              Text(
                'Let\'s get things done',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: subtextColor,
                  shadows: isWhiteTheme ? [] : [
                    Shadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isWhiteTheme ? Colors.white : Colors.white.withOpacity(0.9),
                border: isWhiteTheme ? Border.all(color: Colors.black.withOpacity(0.2), width: 1.5) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundColor: Colors.transparent,
                child: Text(
                  'U',
                  style: GoogleFonts.poppins(
                    color: config?.primary ?? (isWhiteTheme ? Color(0xFF2563eb) : Colors.deepPurple),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            onSelected: (value) {
              if (value == 'friends') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const FriendsScreen()),
                );
              } else if (value == 'settings') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              } else if (value == 'logout') {
                _authService.signOut();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'friends',
                child: Row(
                  children: [
                    const Icon(Icons.people, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Friends',
                      style: GoogleFonts.poppins(color: Colors.blue),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Settings',
                      style: GoogleFonts.poppins(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      'Sign Out',
                      style: GoogleFonts.poppins(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
        ),
      ),
      body: Column(
        children: [
          // Task List
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: _taskService.getTasks(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: isWhiteTheme ? config?.primary : Colors.white,
                      strokeWidth: 3,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: isWhiteTheme ? Colors.grey[400] : Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Something went wrong',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: isWhiteTheme ? Colors.grey[700] : Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final tasks = snapshot.data ?? [];

                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt_outlined,
                          size: 80,
                          color: isWhiteTheme ? Colors.grey[400] : Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No tasks yet',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isWhiteTheme ? Colors.grey[800] : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first task below!',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: isWhiteTheme ? Colors.grey[600] : Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return TaskItem(
                      task: task,
                      themeKey: themeKey,
                      onToggle: (isCompleted) {
                        _taskService.toggleTaskCompletion(task.id, isCompleted);
                      },
                      onTap: () => _showTaskDetails(task),
                    );
                  },
                );
              },
            ),
          ),
          
          // Task Input pinned to bottom with safe area
          SafeArea(
            top: false,
            child: TaskInput(
              themeKey: themeKey,
              onTaskAdded: () {},
            ),
          ),
        ],
      ),
    );
  }

  void _handleSecretTap() async {
    final now = DateTime.now();
    if (_lastTap == null || now.difference(_lastTap!) > const Duration(seconds: 1)) {
      _tapCount = 0;
    }
    _lastTap = now;
    _tapCount++;
    if (_tapCount >= 3) {
      _tapCount = 0;
      final ok = await _promptAdminPassword();
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AdminScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wrong password')),
        );
      }
    }
  }

  Future<bool> _promptAdminPassword() async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Enter password'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Password'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop(controller.text.trim() == 'layladube');
              },
              child: const Text('Enter'),
            ),
          ],
        );
      },
    );
    return result == true;
  }
}

