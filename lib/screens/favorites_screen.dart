import 'package:flutter/material.dart';

import '../widgets/empty_state.dart';

/// Placeholder for bookmarks. Kept as its own screen so the feature can grow
/// without touching the shell.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نشان‌شده‌ها')),
      body: const EmptyState(
        icon: Icons.bookmark_border,
        title: 'هنوز موردی را نشان نکرده‌اید',
        message:
            'در نسخه‌های بعدی می‌توانید آیه‌ها، احادیث و حکمت‌های مورد علاقه‌تان را اینجا ذخیره کنید.',
      ),
    );
  }
}
