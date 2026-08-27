class DailyContent {
  final String title;
  final String arabic;
  final String persian;
  final String source;

  const DailyContent({
    required this.title,
    this.arabic = '',
    required this.persian,
    required this.source,
  });
}
