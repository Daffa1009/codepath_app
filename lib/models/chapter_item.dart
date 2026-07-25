/// Satu poin materi (chapter) dalam sebuah video roadmap.
/// Admin bisa menambahkan timestamp untuk loncat ke momen tertentu.
class ChapterItem {
  final String id;
  final String itemId;
  final String title;
  final int startTime; // dalam detik
  final int sortOrder;

  const ChapterItem({
    required this.id,
    required this.itemId,
    required this.title,
    required this.startTime,
    required this.sortOrder,
  });

  /// Konversi detik → label "MM:SS" atau "HH:MM:SS".
  String get timeLabel {
    final hours = startTime ~/ 3600;
    final minutes = (startTime % 3600) ~/ 60;
    final seconds = startTime % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  factory ChapterItem.fromMap(Map<String, dynamic> map) => ChapterItem(
        id: map['id'] as String,
        itemId: map['item_id'] as String,
        title: map['title'] as String,
        startTime: map['start_time'] as int,
        sortOrder: map['sort_order'] as int? ?? 0,
      );
}
