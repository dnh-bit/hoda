import 'package:flutter/material.dart';

import '../models/daily_content.dart';
import '../services/content_repository.dart';
import '../services/favorites_store.dart';
import '../theme/content_style.dart';
import '../theme/hoda_theme.dart';
import '../utils/fa_num.dart';
import '../widgets/content_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/hoda_app_bar.dart';
import '../widgets/hoda_pattern.dart';
import '../widgets/motion.dart';
import '../widgets/search_field.dart';
import 'content_detail_screen.dart';

/// «نشان‌شده‌ها» — the bookmarks screen.
///
/// In 0.1.x this was a placeholder promising the feature "in a future version";
/// it is now real: [FavoritesStore] persists the uid of every bookmarked item
/// and the loaded snapshot resolves it back to content, so the list survives
/// restarts and stays in sync with every bookmark button in the app.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, required this.content});

  final HodaContent content;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  /// 0 = همه, otherwise index+1 into the browsable families.
  int _kindIndex = 0;

  List<ContentStyle> get _kinds => ContentStyle.all
      .where((ContentStyle s) => s.kind != ContentKind.zekr)
      .toList(growable: false);

  /// Newest bookmark first.
  List<DailyContent> _items(Set<String> uids) {
    final List<DailyContent> out = <DailyContent>[];
    for (final String uid in uids.toList().reversed) {
      final DailyContent? item = widget.content.findByUid(uid);
      if (item == null) continue;
      if (_kindIndex != 0 &&
          ContentStyle.forUid(uid).kind != _kinds[_kindIndex - 1].kind) {
        continue;
      }
      out.add(item);
    }
    return out;
  }

  Future<void> _confirmClear() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('پاک کردن همه نشان‌شده‌ها'),
        content: const Text(
          'همه موارد نشان‌شده حذف می‌شوند. محتوا حذف نمی‌شود و می‌توانید دوباره '
          'نشان‌گذاری کنید.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: HodaColors.danger),
            child: const Text('پاک کن'),
          ),
        ],
      ),
    );
    if (ok == true) await FavoritesStore.clear();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);

    return ValueListenableBuilder<Set<String>>(
      valueListenable: FavoritesStore.uids,
      builder: (BuildContext context, Set<String> uids, _) {
        final List<DailyContent> items = _items(uids);
        return Scaffold(
          appBar: HodaAppBar(
            titleText: 'نشان‌شده‌ها',
            actions: <Widget>[
              if (uids.isNotEmpty)
                IconButton(
                  tooltip: 'پاک کردن همه',
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: _confirmClear,
                ),
            ],
          ),
          body: HodaBackground(
            child: uids.isEmpty
                ? EmptyState(
                    icon: Icons.bookmark_border,
                    title: 'هنوز چیزی نشان نکرده‌اید',
                    message:
                        'روی آیکن نشان‌گذاری هر آیه، حدیث، حکمت یا وصیت بزنید تا '
                        'اینجا ذخیره شود و همیشه در دسترس بماند.',
                    color: palette.accent,
                    action: FilledButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.explore_outlined),
                      label: const Text('برگشت به گنجینه'),
                    ),
                  )
                : Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Icon(
                                  Icons.bookmarks_outlined,
                                  size: 17,
                                  color: palette.accent,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${FaNum.number(uids.length)} مورد ذخیره شده',
                                    style: theme.textTheme.labelMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            FilterChipsBar(
                              color: palette.accent,
                              selectedIndex: _kindIndex,
                              onSelected: (int index) =>
                                  setState(() => _kindIndex = index),
                              labels: <String>[
                                'همه',
                                for (final ContentStyle s in _kinds) s.label,
                              ],
                              icons: <IconData>[
                                Icons.apps,
                                for (final ContentStyle s in _kinds) s.icon,
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: items.isEmpty
                            ? EmptyState(
                                icon: Icons.filter_alt_outlined,
                                title: 'در این دسته چیزی نیست',
                                message: 'فیلتر را بردارید تا همه را ببینید.',
                                color: palette.accent,
                              )
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 6, 16, 28),
                                itemCount: items.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 14),
                                itemBuilder:
                                    (BuildContext context, int index) {
                                  final DailyContent item = items[index];
                                  final Widget card = ContentCard(
                                    content: item,
                                    compact: true,
                                    maxPersianLines: 3,
                                    maxArabicLines: 2,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => ContentDetailScreen(
                                          content: item,
                                        ),
                                      ),
                                    ),
                                  );
                                  if (index > 5) return card;
                                  return Reveal(
                                    delay: Reveal.stagger(index),
                                    child: card,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
