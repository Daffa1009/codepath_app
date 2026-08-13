import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui;

import '../config/theme.dart';
import '../models/roadmap_item.dart';
import '../models/chapter_item.dart';
import '../providers/roadmap_provider.dart';
import '../utils/youtube_helper.dart';

/// Halaman "Materi Pembelajaran". Di web: embed YouTube iframe langsung
/// + daftar poin materi (chapters) dengan timestamp. Tap chapter → loncat
/// ke momen video tersebut. Di mobile: thumbnail + tombol buka external.
class VideoDetailScreen extends StatefulWidget {
  final RoadmapItem item;
  final String? roadmapId;
  final String? topicTitle;

  const VideoDetailScreen({
    super.key,
    required this.item,
    this.roadmapId,
    this.topicTitle,
  });

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  static const _defaultSrc = 'autoplay=0&rel=0';

  late final String _viewId;
  late final String? _videoId;
  late web.HTMLIFrameElement _iframeElement;

  // Chapters
  List<ChapterItem> _chapters = [];
  bool _chaptersLoading = true;
  int? _activeChapterSeconds; // null = no active chapter

  @override
  void initState() {
    super.initState();
    _videoId = extractYoutubeId(widget.item.youtubeUrl);
    _viewId = 'yt-${widget.item.id}';

    // Register platform view SEKALI — simpan referensi iframe untuk seek
    if (kIsWeb && _videoId != null) {
      ui.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
        _iframeElement =
            web.document.createElement('iframe') as web.HTMLIFrameElement;
        _iframeElement.src =
            'https://www.youtube.com/embed/$_videoId?$_defaultSrc';
        _iframeElement.style.border = 'none';
        _iframeElement.style.width = '100%';
        _iframeElement.style.height = '100%';
        _iframeElement.allow =
            'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture';
        _iframeElement.allowFullscreen = true;
        _iframeElement.className = 'youtube-embed';
        return _iframeElement;
      });
    }

    // Fetch chapters dari Supabase
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    setState(() => _chaptersLoading = true);
    try {
      final rows = await Supabase.instance.client
          .from('roadmap_item_chapters')
          .select('id, item_id, title, start_time, sort_order')
          .eq('item_id', widget.item.id)
          .order('sort_order');
      setState(() {
        _chapters = rows.map((r) => ChapterItem.fromMap(r)).toList();
        _chaptersLoading = false;
      });
    } catch (_) {
      setState(() => _chaptersLoading = false);
    }
  }

  /// Loncat ke timestamp di iframe dengan update src + autoplay=1.
  void _seekToTime(int seconds) {
    if (_videoId == null) return;
    setState(() => _activeChapterSeconds = seconds);

    final newSrc =
        'https://www.youtube.com/embed/$_videoId?start=$seconds&autoplay=1&rel=0';
    _iframeElement.src = newSrc;
  }

  Future<void> _openExternalYoutube(BuildContext context) async {
    final uri = Uri.parse(widget.item.youtubeUrl);

    if (!await canLaunchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('URL tidak valid atau tidak bisa dibuka.')),
        );
      }
      return;
    }

    final launchedExternal =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (launchedExternal) return;

    final launchedPlatform =
        await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!launchedPlatform && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tidak bisa membuka YouTube.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 20),
              color: AppColors.primaryTeal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    (widget.topicTitle ?? '').toUpperCase(),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                            color: Colors.white, letterSpacing: 1),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon:
                        const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === AREA VIDEO: embed iframe di web, fallback di mobile ===
                  if (kIsWeb && _videoId != null)
                    // YouTube embed di web
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppRadius.card),
                      child: SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: HtmlElementView(
                            viewType: _viewId),
                      ),
                    )
                  else if (kIsWeb && _videoId == null)
                    // Web tapi videoId invalid
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius:
                            BorderRadius.circular(AppRadius.card),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.videocam_off,
                              size: 40,
                              color: AppColors.textMuted),
                          SizedBox(height: 8),
                          Text(
                            'Video tidak tersedia',
                            style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  else
                    // Mobile/desktop: thumbnail + tap untuk buka external
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Material(
                        color: Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(AppRadius.card),
                        child: InkWell(
                          onTap: () =>
                              _openExternalYoutube(context),
                          borderRadius:
                              BorderRadius.circular(AppRadius.card),
                          child: Container(
                            height: 220,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primaryTeal,
                                  Color(0xFF1B5A50)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(
                                  AppRadius.card),
                            ),
                            child: Center(
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_arrow,
                                    color: AppColors.primaryTeal,
                                    size: 32),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // === POIN MATERI (CHAPTERS) ===
                  if (!_chaptersLoading && _chapters.isNotEmpty) ...[
                    Text(
                      'Poin Materi',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    ..._chapters.map((ch) => _buildChapterTile(ch)),
                    const SizedBox(height: 8),
                  ],

                  Text(widget.item.title,
                      style:
                          Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    'by ${widget.item.channelName} · ${widget.item.durationLabel}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),

                  // Tombol "Tonton di YouTube" — selalu ada (animated)
                  _AnimatedYoutubeButton(
                    onPressed: () =>
                        _openExternalYoutube(context),
                  ),
                  const SizedBox(height: 12),

                  if (widget.roadmapId != null)
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: widget.item.isCompleted
                              ? null
                              : () {
                                  context
                                      .read<RoadmapProvider>()
                                      .markItemComplete(
                                          widget.roadmapId!,
                                          widget.item.id);
                                  Navigator.pop(context);
                                },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: AppColors.primaryTeal),
                            foregroundColor:
                                AppColors.primaryTeal,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                          ),
                          icon: Icon(widget.item.isCompleted
                              ? Icons.check_circle
                              : Icons.check),
                          label: Text(widget.item.isCompleted
                              ? 'Sudah Selesai'
                              : 'Tandai Selesai'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Satu tile poin materi: [timestamp badge] [judul] [chevron].
  Widget _buildChapterTile(ChapterItem ch) {
    final isActive = _activeChapterSeconds == ch.startTime;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Material(
          color: isActive
              ? AppColors.primaryTeal.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: InkWell(
            onTap: () => _seekToTime(ch.startTime),
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isActive
                      ? AppColors.primaryTeal.withValues(alpha: 0.2)
                      : const Color(0xFFE8E8E8),
                ),
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Row(
                children: [
                  // Timestamp badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primaryTeal
                          : AppColors.primaryTeal.withValues(
                              alpha: 0.8),
                      borderRadius:
                          BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      ch.timeLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Judul chapter
                  Expanded(
                    child: Text(
                      ch.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive
                            ? AppColors.primaryTeal
                            : Colors.black87,
                      ),
                    ),
                  ),

                  // Chevron
                  Icon(
                    Icons.play_arrow,
                    size: 18,
                    color: isActive
                        ? AppColors.primaryTeal
                        : AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tombol "Tonton di YouTube" dengan animasi PRESS ONLY:
/// - Scale mengecil ke 96% saat ditekan
/// - Cursor pointer (telunjuk) saat di-hover (web)
/// - Gradient lebih terang saat ditekan
class _AnimatedYoutubeButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _AnimatedYoutubeButton({required this.onPressed});

  @override
  State<_AnimatedYoutubeButton> createState() =>
      _AnimatedYoutubeButtonState();
}

class _AnimatedYoutubeButtonState extends State<_AnimatedYoutubeButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            height: 56,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _pressed
                    ? const [
                        Color(0xFFD32F2F),
                        Color(0xFFE53935),
                        Color(0xFFEF5350),
                      ]
                    : const [
                        Color(0xFFB31217),
                        AppColors.maroon,
                        Color(0xFFD32F2F),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: [
                BoxShadow(
                  color: AppColors.maroon
                      .withValues(alpha: _pressed ? 0.55 : 0.35),
                  blurRadius: _pressed ? 20 : 14,
                  offset: Offset(0, _pressed ? 3 : 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.maroon,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Tonton di YouTube',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.open_in_new,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
