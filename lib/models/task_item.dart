enum TaskUrgency { mendatang, mendesak }

enum TaskType { praktik, kuis }

/// Tugas praktik atau kuis yang terhubung ke sebuah roadmap/video.
class TaskItem {
  final String id;
  final String courseTitle;
  final String title;
  final String description;
  final DateTime deadline;
  final TaskUrgency urgency;
  final TaskType type;
  bool isDone;
  final String? roadmapId; // Dipakai admin screen untuk dropdown roadmap

  TaskItem({
    required this.id,
    required this.courseTitle,
    required this.title,
    required this.description,
    required this.deadline,
    required this.urgency,
    required this.type,
    this.isDone = false,
    this.roadmapId,
  });
}
