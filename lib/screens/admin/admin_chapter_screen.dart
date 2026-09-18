import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../models/chapter_item.dart';

/// Admin screen: kelola chapter (poin materi + timestamp) untuk satu video.
class AdminChapterScreen extends StatefulWidget {
  final String itemId;
  final String videoTitle;

  const AdminChapterScreen({
    super.key,
    required this.itemId,
    required this.videoTitle,
  });

  @override
  State<AdminChapterScreen> createState() => _AdminChapterScreenState();
}

class _AdminChapterScreenState extends State<AdminChapterScreen> {
  List<ChapterItem> _chapters = [];
  bool _loading = true;

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchChapters();
  }

  Future<void> _fetchChapters() async {
    setState(() => _loading = true);
    try {
      final rows = await _db
          .from('roadmap_item_chapters')
          .select()
          .eq('item_id', widget.itemId)
          .order('sort_order');
      setState(() {
        _chapters = rows.map((r) => ChapterItem.fromMap(r)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat chapter: $e')),
        );
      }
    }
  }

  // ---------------------------------------------------------------
  // TAMBAH / EDIT dialog
  // ---------------------------------------------------------------
  void _showChapterDialog({ChapterItem? existing}) {
    final titleCtrl = TextEditingController(
        text: existing?.title ?? '');
    final menitCtrl = TextEditingController(
        text: existing != null
            ? '${existing.startTime ~/ 60}'
            : '');
    final detikCtrl = TextEditingController(
        text: existing != null
            ? '${existing.startTime % 60}'
            : '0');
    final orderCtrl = TextEditingController(
        text: existing != null
            ? '${existing.sortOrder}'
            : '${_chapters.length + 1}');

    bool saving = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> handleSave() async {
            final title = titleCtrl.text.trim();
            final menit = int.tryParse(menitCtrl.text) ?? -1;
            final detik = int.tryParse(detikCtrl.text) ?? -1;
            final sortOrder = int.tryParse(orderCtrl.text) ?? 0;

            if (title.isEmpty) {
              setDialogState(() =>
                  errorMsg = 'Judul materi tidak boleh kosong.');
              return;
            }
            if (menit < 0) {
              setDialogState(
                  () => errorMsg = 'Masukkan menit yang valid (≥ 0).');
              return;
            }
            if (detik < 0 || detik > 59) {
              setDialogState(
                  () => errorMsg = 'Detik harus antara 0–59.');
              return;
            }

            final startTimeSecs = menit * 60 + detik;
            setDialogState(() {
              saving = true;
              errorMsg = null;
            });

            try {
              if (existing == null) {
                // INSERT
                await _db.from('roadmap_item_chapters').insert({
                  'item_id': widget.itemId,
                  'title': title,
                  'start_time': startTimeSecs,
                  'sort_order': sortOrder,
                });
              } else {
                // UPDATE
                await _db
                    .from('roadmap_item_chapters')
                    .update({
                      'title': title,
                      'start_time': startTimeSecs,
                      'sort_order': sortOrder,
                    })
                    .eq('id', existing.id);
              }

              if (ctx.mounted) Navigator.pop(ctx);
              await _fetchChapters();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(existing == null
                        ? 'Chapter berhasil ditambahkan'
                        : 'Chapter berhasil diperbarui'),
                    backgroundColor: AppColors.primaryTeal,
                  ),
                );
              }
            } catch (e) {
              setDialogState(() {
                saving = false;
                errorMsg = 'Gagal menyimpan: $e';
              });
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text(
              existing == null ? 'Tambah Chapter' : 'Edit Chapter',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryTeal),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (errorMsg != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.maroon.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(errorMsg!,
                          style: const TextStyle(
                              color: AppColors.maroon, fontSize: 13)),
                    ),
                  const Text('Judul Materi',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                        hintText: 'mis. Pengenalan variabel'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Menit',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: menitCtrl,
                              keyboardType: TextInputType.number,
                              decoration:
                                  const InputDecoration(hintText: '0'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Detik',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: detikCtrl,
                              keyboardType: TextInputType.number,
                              decoration:
                                  const InputDecoration(hintText: '0'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Urutan (Sort Order)',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: orderCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(hintText: '1'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('Batal',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                onPressed: saving ? null : handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
                child: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------
  // HAPUS
  // ---------------------------------------------------------------
  Future<void> _confirmDelete(ChapterItem ch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Chapter?',
            style: TextStyle(
                color: AppColors.maroon, fontWeight: FontWeight.w700)),
        content: Text(
            'Chapter "${ch.title}" akan dihapus permanen.',
            style: const TextStyle(fontSize: 14)),
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

    if (confirmed != true) return;

    try {
      await _db
          .from('roadmap_item_chapters')
          .delete()
          .eq('id', ch.id);
      await _fetchChapters();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chapter dihapus'),
            backgroundColor: AppColors.maroon,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e')),
        );
      }
    }
  }

  // ---------------------------------------------------------------
  // TAMBAH BULK dialog
  // ---------------------------------------------------------------
  void _showBulkImportDialog() {
    final textCtrl = TextEditingController();
    List<ChapterItem> parsedChapters = [];
    bool saving = false;
    String? errorMsg;

    // Format MM:SS atau HH:MM:SS di awal baris
    final regex = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?\s*[-|]?\s*(.+)$');

    void parseInput(String input) {
      final lines = input.split('\n');
      final newChapters = <ChapterItem>[];
      int sortOrder = 1;

      for (final line in lines) {
        final match = regex.firstMatch(line.trim());
        if (match != null) {
          final group1 = match.group(1)!;
          final group2 = match.group(2)!;
          final group3 = match.group(3);
          final title = match.group(4)!.trim();

          int startTime = 0;
          if (group3 == null) {
            // MM:SS
            startTime = (int.parse(group1) * 60) + int.parse(group2);
          } else {
            // HH:MM:SS
            startTime = (int.parse(group1) * 3600) +
                (int.parse(group2) * 60) +
                int.parse(group3);
          }

          newChapters.add(ChapterItem(
            id: '', // temporary
            itemId: widget.itemId,
            title: title,
            startTime: startTime,
            sortOrder: sortOrder++,
          ));
        }
      }

      parsedChapters = newChapters;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> handleImport() async {
            if (parsedChapters.isEmpty) {
              setDialogState(() => errorMsg = 'Tidak ada timestamp valid ditemukan.');
              return;
            }
            
            setDialogState(() {
              saving = true;
              errorMsg = null;
            });

            try {
              await _db.from('roadmap_item_chapters').insert(
                    parsedChapters
                        .map((c) => {
                              'item_id': c.itemId,
                              'title': c.title,
                              'start_time': c.startTime,
                              'sort_order': c.sortOrder,
                            })
                        .toList(),
                  );

              if (ctx.mounted) Navigator.pop(ctx);
              await _fetchChapters();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Berhasil import ${parsedChapters.length} chapter!'),
                    backgroundColor: AppColors.primaryTeal,
                  ),
                );
              }
            } catch (e) {
              setDialogState(() {
                saving = false;
                errorMsg = 'Gagal menyimpan: $e';
              });
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Import Poin Materi (Bulk)',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryTeal)),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Paste timestamp dari deskripsi YouTube atau ketik manual.\n'
                      'Format yang didukung:\n'
                      '- 00:00 Judul materi\n'
                      '- 0:00:00 Judul materi\n'
                      '- 00:00 - Judul materi\n'
                      '- 00:00 | Judul materi',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Contoh:\n'
                      '00:00 Pengenalan\n'
                      '05:30 Instalasi Tools\n'
                      '15:00 Membuat Project\n'
                      '45:20 Routing Dasar',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: textCtrl,
                      maxLines: null,
                      minLines: 8,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.background,
                        hintText: 'Paste di sini...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          parseInput(value);
                          errorMsg = null;
                        });
                      },
                    ),
                    if (errorMsg != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(errorMsg!,
                            style: const TextStyle(color: AppColors.maroon, fontSize: 13)),
                      ),
                    if (textCtrl.text.trim().isNotEmpty && parsedChapters.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('Preview:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      ...parsedChapters.take(3).map(
                            (c) => Text(
                              '✓ ${c.timeLabel} - ${c.title}',
                              style: const TextStyle(color: AppColors.primaryTeal, fontSize: 12),
                            ),
                          ),
                      if (parsedChapters.length > 3)
                        Text(
                          '... dan ${parsedChapters.length - 3} lainnya',
                          style: const TextStyle(color: AppColors.primaryTeal, fontSize: 12),
                        ),
                    ],
                    if (textCtrl.text.trim().isNotEmpty && parsedChapters.isEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        '✗ baris tidak valid / tidak ada timestamp valid',
                        style: TextStyle(color: AppColors.maroon, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                onPressed: (saving || textCtrl.text.trim().isEmpty) ? null : handleImport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
                child: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Import ${parsedChapters.length} Chapter'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Chapter: ${widget.videoTitle}',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        actions: [
          TextButton.icon(
            onPressed: _showBulkImportDialog,
            icon: const Icon(Icons.playlist_add, color: Colors.white),
            label: const Text('Import Bulk', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primaryTeal),
            )
          : _chapters.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.format_list_numbered,
                            size: 52, color: AppColors.textMuted),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada chapter.\nTap + untuk menambahkan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _chapters.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _buildChapterCard(_chapters[i]),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showChapterDialog(),
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Chapter'),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Card setiap chapter
  // ---------------------------------------------------------------
  Widget _buildChapterCard(ChapterItem ch) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      child: Row(
        children: [
          // Timestamp badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              ch.timeLabel,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ch.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text('Urutan: ${ch.sortOrder}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),

          // Aksi
          IconButton(
            onPressed: () => _showChapterDialog(existing: ch),
            icon: const Icon(Icons.edit,
                color: AppColors.primaryTeal, size: 20),
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: () => _confirmDelete(ch),
            icon: const Icon(Icons.delete,
                color: AppColors.maroon, size: 20),
            tooltip: 'Hapus',
          ),
        ],
      ),
    );
  }
}
