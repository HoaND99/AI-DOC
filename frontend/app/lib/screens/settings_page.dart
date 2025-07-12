import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final ThemeMode currentThemeMode;
  final void Function(ThemeMode) onThemeChanged;

  SettingsPage({
    required this.currentThemeMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cài đặt"),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text("Giao diện"),
            trailing: DropdownButton<ThemeMode>(
              value: currentThemeMode,
              onChanged: (mode) => onThemeChanged(mode!),
              items: [
                DropdownMenuItem(value: ThemeMode.light, child: Text("Sáng")),
                DropdownMenuItem(value: ThemeMode.dark, child: Text("Tối")),
                DropdownMenuItem(
                    value: ThemeMode.system, child: Text("Theo hệ thống")),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
