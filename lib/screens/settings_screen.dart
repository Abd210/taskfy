import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../ui/theme_provider.dart';
import '../services/friend_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FriendService _friendService = FriendService();
  bool _showAllTasks = true;
  String _themeKey = 'purple';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _friendService.getUserSettings().listen((settings) {
      if (mounted) {
        setState(() {
          _showAllTasks = settings.showAllTasks;
          _themeKey = settings.theme;
        });
      }
    });
  }

  void _updateSettings() async {
    try {
      await _friendService.updateUserSettings(_showAllTasks);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _showAllTasks 
                  ? 'All tasks will be shared with friends' 
                  : 'Only selected tasks will be shared with friends',
            ),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  Future<void> _updateTheme(String key) async {
    try {
      await _friendService.updateUserTheme(key);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Theme updated to ${_themeLabel(key)}'),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  String _themeLabel(String key) {
    switch (key) {
      case 'green':
        return 'Green';
      case 'pink':
        return 'Pink';
      case 'black':
        return 'Black';
      case 'ocean':
        return 'Ocean';
      case 'purple':
      default:
        return 'Purple';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context);
    final currentThemeKey = themeProvider?.themeKey ?? 'white';
    final isWhiteTheme = currentThemeKey == 'white';
    final textColor = isWhiteTheme ? Colors.black : Colors.white;
    final subtextColor = isWhiteTheme ? Color(0xFF4b5563) : Colors.white.withOpacity(0.8);
    
    return GradientScaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isWhiteTheme ? Colors.white.withOpacity(0.8) : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isWhiteTheme ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.3),
                  width: isWhiteTheme ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette, color: textColor, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Theme',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose your favorite color scheme',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: subtextColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.1,
                    children: [
                      _ThemeCard(
                        label: 'Clean White',
                        gradientColors: [Color(0xFFf5f7fa), Color(0xFFc3cfe2)],
                        selected: _themeKey == 'white',
                        isCurrentTheme: currentThemeKey == 'white',
                        onTap: () {
                          setState(() => _themeKey = 'white');
                          _updateTheme('white');
                        },
                      ),
                      _ThemeCard(
                        label: 'Purple Dream',
                        gradientColors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        selected: _themeKey == 'purple',
                        isCurrentTheme: currentThemeKey == 'purple',
                        onTap: () {
                          setState(() => _themeKey = 'purple');
                          _updateTheme('purple');
                        },
                      ),
                      _ThemeCard(
                        label: 'Nature',
                        gradientColors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                        selected: _themeKey == 'green',
                        isCurrentTheme: currentThemeKey == 'green',
                        onTap: () {
                          setState(() => _themeKey = 'green');
                          _updateTheme('green');
                        },
                      ),
                      _ThemeCard(
                        label: 'Rose Garden',
                        gradientColors: [Color(0xFFf857a6), Color(0xFFff5858)],
                        selected: _themeKey == 'pink',
                        isCurrentTheme: currentThemeKey == 'pink',
                        onTap: () {
                          setState(() => _themeKey = 'pink');
                          _updateTheme('pink');
                        },
                      ),
                      _ThemeCard(
                        label: 'Midnight',
                        gradientColors: [Color(0xFF0f0c29), Color(0xFF302b63)],
                        selected: _themeKey == 'black',
                        isCurrentTheme: currentThemeKey == 'black',
                        onTap: () {
                          setState(() => _themeKey = 'black');
                          _updateTheme('black');
                        },
                      ),
                      _ThemeCard(
                        label: 'Ocean Breeze',
                        gradientColors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
                        selected: _themeKey == 'ocean',
                        isCurrentTheme: currentThemeKey == 'ocean',
                        onTap: () {
                          setState(() => _themeKey = 'ocean');
                          _updateTheme('ocean');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            // Sharing Settings
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isWhiteTheme ? Colors.white.withOpacity(0.8) : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isWhiteTheme ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.3),
                  width: isWhiteTheme ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.share, color: textColor, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Task Sharing',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Show All Tasks Option
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _showAllTasks 
                        ? (isWhiteTheme ? Color(0xFFe5e7eb) : Colors.white.withOpacity(0.25)) 
                        : (isWhiteTheme ? Colors.white : Colors.white.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _showAllTasks 
                          ? (isWhiteTheme ? Colors.black : Colors.white) 
                          : (isWhiteTheme ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.3)),
                        width: _showAllTasks ? (isWhiteTheme ? 2 : 2) : (isWhiteTheme ? 1.5 : 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Radio<bool>(
                          value: true,
                          groupValue: _showAllTasks,
                          onChanged: (value) {
                            setState(() {
                              _showAllTasks = value!;
                            });
                            _updateSettings();
                          },
                          activeColor: isWhiteTheme ? Colors.black : Colors.white,
                          fillColor: MaterialStateProperty.all(isWhiteTheme ? Colors.black : Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Show All',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                'All your tasks will be visible to friends',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: subtextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Show Some Tasks Option
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: !_showAllTasks 
                        ? (isWhiteTheme ? Color(0xFFe5e7eb) : Colors.white.withOpacity(0.25)) 
                        : (isWhiteTheme ? Colors.white : Colors.white.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !_showAllTasks 
                          ? (isWhiteTheme ? Colors.black : Colors.white) 
                          : (isWhiteTheme ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.3)),
                        width: !_showAllTasks ? (isWhiteTheme ? 2 : 2) : (isWhiteTheme ? 1.5 : 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Radio<bool>(
                          value: false,
                          groupValue: _showAllTasks,
                          onChanged: (value) {
                            setState(() {
                              _showAllTasks = value!;
                            });
                            _updateSettings();
                          },
                          activeColor: isWhiteTheme ? Colors.black : Colors.white,
                          fillColor: MaterialStateProperty.all(isWhiteTheme ? Colors.black : Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Show Some',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                'Choose which tasks to share with friends',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: subtextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Info Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isWhiteTheme ? Color(0xFFdbeafe) : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isWhiteTheme ? Colors.black.withOpacity(0.15) : Colors.white.withOpacity(0.3),
                  width: isWhiteTheme ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: isWhiteTheme ? Color(0xFF1e40af) : Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'When "Show Some" is selected, you can choose which friends to share each task with when creating or editing tasks.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: isWhiteTheme ? Color(0xFF1e3a8a) : Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String label;
  final List<Color> gradientColors;
  final bool selected;
  final bool isCurrentTheme;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.label,
    required this.gradientColors,
    required this.selected,
    required this.isCurrentTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: gradientColors[0], // Use solid color instead of gradient
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.white : Colors.white.withOpacity(0.3),
            width: selected ? 2.5 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (selected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check,
                    size: 14,
                    color: gradientColors.first,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
