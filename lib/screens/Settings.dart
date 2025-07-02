import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = false;
  String _uiLanguage = 'en';
  String _speechLanguage = 'en';
  String _textSize = 'medium';

  final List<String> _languages = ['en', 'el'];
  final List<String> _textSizes = ['small', 'medium', 'large'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _uiLanguage = prefs.getString('uiLanguage') ?? 'en';
      _speechLanguage = prefs.getString('speechLanguage') ?? 'en';
      _textSize = prefs.getString('textSize') ?? 'medium';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _isDarkMode);
    await prefs.setString('uiLanguage', _uiLanguage);
    await prefs.setString('speechLanguage', _speechLanguage);
    await prefs.setString('textSize', _textSize);
  }

  Future<void> _resetPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      _isDarkMode = false;
      _uiLanguage = 'en';
      _speechLanguage = 'en';
      _textSize = 'medium';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textStyle = Theme.of(context).textTheme.bodyLarge;

    return Column(
      children: [
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Dark Mode', style: textStyle),
                  Switch(
                    value: _isDarkMode,
                    onChanged: (value) {
                      setState(() => _isDarkMode = value);
                      _saveSettings();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Text('UI Language', style: textStyle),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: _uiLanguage,
                isExpanded: true,
                items:
                    _languages.map((lang) {
                      return DropdownMenuItem(
                        value: lang,
                        child: Text(lang == 'en' ? 'English' : 'Ελληνικά'),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _uiLanguage = value);
                    _saveSettings();
                  }
                },
              ),
              const SizedBox(height: 24),

              Text('Speech Recognition Language', style: textStyle),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: _speechLanguage,
                isExpanded: true,
                items:
                    _languages.map((lang) {
                      return DropdownMenuItem(
                        value: lang,
                        child: Text(lang == 'en' ? 'English' : 'Ελληνικά'),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _speechLanguage = value);
                    _saveSettings();
                  }
                },
              ),
              const SizedBox(height: 24),

              Text('Text Size', style: textStyle),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: _textSize,
                isExpanded: true,
                items:
                    _textSizes.map((size) {
                      return DropdownMenuItem(
                        value: size,
                        child: Text(size[0].toUpperCase() + size.substring(1)),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _textSize = value);
                    _saveSettings();
                  }
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _resetPreferences,
              icon: const Icon(Icons.restore),
              label: const Text('Reset Preferences'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[850],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
