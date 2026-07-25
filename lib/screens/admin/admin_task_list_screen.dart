import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';

/// Admin screen: daftar semua tugas/kuis + CRUD.
class AdminTaskListScreen extends StatefulWidget {
  const AdminTaskListScreen({super.key});

  @override
  State<AdminTaskListScreen> createState() => _AdminTaskListScreenState();
}

class _AdminTaskListScreenState extends State<AdminTaskListScreen> {
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _roadmaps = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      // Fetch tasks dan roadmaps secara paralel
      final results = await Future.wait([
        Supabase.instance.client
            .from('tasks')
            .select(
                'id, roadmap_id, course_title, title, description, deadline, urgency, type')
            .order('created_at'),
        Supabase.instance.client
            .from('roadmaps')
            .select('id, title')
            .order('created_at'),
      ]);
      setState(() {
        _tasks = List<Map<String, dynamic>>.from(results[0] as List);
        _roadmaps = List<Map<String, dynamic>>.from(results[1] as List);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showSnack('Gagal memuat data: $e', isError: true);
    }
  }

  void _showAddDialog() => _showTaskDialog(null);
  void _showEditDialog(Map<String, dynamic> task) => _showTaskDialog(task);

  void _showTaskDialog(Map<String, dynamic>? existing) {
    final titleCtrl = TextEditingController(
        text: existing?['title'] as String? ?? '');
    final descCtrl = TextEditingController(
        text: existing?['description'] as String? ?? '');

    // Cari roadmap yang cocok
    String? selectedRoadmapId = existing?['roadmap_id'] as String?;
    if (selectedRoadmapId != null &&
        !_roadmaps.any((r) => r['id'] == selectedRoadmapId)) {
      selectedRoadmapId = null;
    }
    if (selectedRoadmapId == null && _roadmaps.isNotEmpty) {
      selectedRoadmapId = _roadmaps.first['id'] as String;
    }

    String selectedUrgency =
        existing?['urgency'] as String? ?? 'mendatang';
    String selectedType = existing?['type'] as String? ?? 'praktik';

    // Deadline dari existing atau default 7 hari ke depan
    DateTime selectedDeadline = DateTime.now().add(const Duration(days: 7));
    if (existing?['deadline'] != null) {
      try {
        selectedDeadline =
            DateTime.parse(existing!['deadline'] as String).toLocal();
      } catch (_) {}
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          scrollable: true,
          title: Text(existing == null ? 'Tambah Tugas' : 'Edit Tugas',
              style: const TextStyle(
                  color: AppColors.primaryTeal,
                  fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pilih Roadmap
              const Text('Roadmap *',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedRoadmapId,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                items: _roadmaps
                    .map((r) => DropdownMenuItem<String>(
                          value: r['id'] as String,
                          child: Text(r['title'] as String),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => selectedRoadmapId = v),
              ),
              const SizedBox(height: 14),
              // Judul
              const Text('Judul *',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: titleCtrl,
                decoration:
                    const InputDecoration(hintText: 'Judul tugas/kuis'),
              ),
              const SizedBox(height: 14),
              // Deskripsi
              const Text('Deskripsi',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration:
                    const InputDecoration(hintText: 'Deskripsi tugas'),
              ),
              const SizedBox(height: 14),
              // Deadline
              const Text('Deadline *',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDeadline,
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365)),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: AppColors.primaryTeal,
                          onPrimary: Colors.white,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDeadline = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius:
                        BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 18, color: AppColors.primaryTeal),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('d MMM yyyy').format(selectedDeadline),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Urgensi
              const Text('Urgensi *',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedUrgency,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'mendatang', child: Text('Mendatang')),
                  DropdownMenuItem(
                      value: 'mendesak', child: Text('Mendesak')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedUrgency = v);
                },
              ),
              const SizedBox(height: 14),
              // Tipe
              const Text('Tipe *',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'praktik', child: Text('Praktik')),
                  DropdownMenuItem(value: 'kuis', child: Text('Kuis')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedType = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder()),
              onPressed: () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty || selectedRoadmapId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Judul dan Roadmap tidak boleh kosong.')),
                  );
                  return;
                }
                Navigator.pop(ctx);

                // Ambil course_title dari roadmap yang dipilih
                final selectedRoadmap = _roadmaps.firstWhere(
                    (r) => r['id'] == selectedRoadmapId,
                    orElse: () => {});
                final courseTitle =
                    selectedRoadmap['title'] as String? ?? '';

                final payload = {
                  'roadmap_id': selectedRoadmapId,
                  'course_title': courseTitle,
                  'title': title,
                  'description': descCtrl.text.trim(),
                  'deadline': selectedDeadline.toUtc().toIso8601String(),
                  'urgency': selectedUrgency,
                  'type': selectedType,
                };

                try {
                  if (existing == null) {
                    await Supabase.instance.client
                        .from('tasks')
                        .insert(payload);
                    _showSnack('Tugas berhasil ditambahkan.');
                  } else {
                    await Supabase.instance.client
                        .from('tasks')
                        .update(payload)
                        .eq('id', existing['id'] as String);
                    _showSnack('Tugas berhasil diperbarui.');
                  }
                  await _loadAll();
                } catch (e) {
                  _showSnack('Gagal menyimpan: $e', isError: true);
                }
              },
              child: Text(existing == null ? 'Tambah' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Tugas?',
            style: TextStyle(
                color: AppColors.maroon, fontWeight: FontWeight.w700)),
        content: Text(
          'Yakin ingin menghapus "${task['title']}"?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.maroon,
                foregroundColor: Colors.white,
                shape: const StadiumBorder()),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Supabase.instance.client
            .from('tasks')
            .delete()
            .eq('id', task['id'] as String);
        _showSnack('Tugas berhasil dihapus.');
        await _loadAll();
      } catch (e) {
        _showSnack('Gagal menghapus: $e', isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.maroon : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 16, 20, 20),
              color: AppColors.primaryTeal,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon:
                        const Icon(Icons.arrow_back, color: Colors.white),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.white24,
                        shape: const CircleBorder()),
                  ),
                  const SizedBox(width: 8),
                  Text('Kelola Tugas',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: Colors.white)),
                ],
              ),
            ),
            // List
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryTeal))
                  : _tasks.isEmpty
                      ? const Center(
                          child:
                              Text('Belum ada tugas. Tambahkan dulu!'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: _tasks.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final task = _tasks[i];
                            return _TaskAdminCard(
                              task: task,
                              onEdit: () => _showEditDialog(task),
                              onDelete: () => _confirmDelete(task),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Tugas'),
      ),
    );
  }
}

class _TaskAdminCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskAdminCard({
    required this.task,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final urgency = task['urgency'] as String? ?? 'mendatang';
    final type = task['type'] as String? ?? 'praktik';
    final isUrgent = urgency == 'mendesak';
    final badgeColor = isUrgent ? AppColors.maroon : AppColors.primaryTeal;

    String deadlineLabel = '-';
    if (task['deadline'] != null) {
      try {
        final dt =
            DateTime.parse(task['deadline'] as String).toLocal();
        deadlineLabel = DateFormat('d MMM yyyy').format(dt);
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(task['course_title'] as String? ?? '',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius:
                      BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  isUrgent ? 'Mendesak' : 'Mendatang',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius:
                      BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  type == 'kuis' ? 'Kuis' : 'Praktik',
                  style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(task['title'] as String? ?? '',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text('Deadline: $deadlineLabel',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.gold),
                  foregroundColor: AppColors.gold,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                ),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit',
                    style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onDelete,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.maroon),
                  foregroundColor: AppColors.maroon,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                ),
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('Hapus',
                    style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
