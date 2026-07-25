/// Satu video tutorial di dalam sebuah Roadmap.
/// Video ini adalah link ke YouTube (bukan file upload sendiri).
class RoadmapItem {
  final String id;
  final String title;
  final String channelName;
  final String youtubeUrl;
  final int durationMinutes;
  final int sortOrder;
  bool isCompleted;

  RoadmapItem({
    required this.id,
    required this.title,
    required this.channelName,
    required this.youtubeUrl,
    required this.durationMinutes,
    this.sortOrder = 0,
    this.isCompleted = false,
  });

  String get durationLabel => '$durationMinutes Menit';
}
