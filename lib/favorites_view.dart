import 'package:flutter/material.dart';
import 'theme.dart';
import 'models.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('نشان‌شده‌ها و علاقه‌مندی‌ها',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: HodaColors.gold.withOpacity(0.4)),
          ),
          child: Column(
            children: [
              const Icon(Icons.bookmark_border, size: 48, color: HodaColors.gold),
              const SizedBox(height: 16),
              const Text('هنوز موردی را نشان نکرده‌اید',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text('با لمس آیکون نشان در هر آیه یا حدیث، می‌توانید آن را اینجا ذخیره کنید.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
