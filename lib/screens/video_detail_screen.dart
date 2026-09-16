import 'dart:async';

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

class _VideoDetailScreenState extends State<VideoDetailScreen>
    with TickerProviderStateMixin {
  static const _defaultSrc = 'autoplay=0&rel=0';

  late final String _viewId;
  late final String? _videoId;
  late web.HTMLIFrameElement _iframeElement;

  // Chapters
  List<ChapterItem> _chapters = [];
  bool _chaptersLoading = true;
  int? _activeChapterSeconds; // null = no active chapter

  // State AI Assistant dipindahkan ke _AIChatBottomSheet
  // Floating Chat Widget State
  late AnimationController _fabScaleController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _videoId = extractYoutubeId(widget.item.youtubeUrl);
    _viewId = 'yt-${widget.item.id}';

    // Initialize animation controllers
    _fabScaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

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

    // Trigger FAB entrance animation after delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _fabScaleController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fabScaleController.dispose();
    _pulseController.dispose();
    super.dispose();
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
            content: Text('URL tidak valid atau tidak bisa dibuka.'),
          ),
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
          content: Text('Tidak bisa membuka YouTube.'),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    const fabSize = 56.0;

    return Scaffold(
      backgroundColor: Colors.white,
      // Matikan interaksi YouTube iframe secara native saat chat terbuka,
      // sehingga klik "Tutup" / "Saran" tidak diinterpretasikan browser
      // sebagai play/pause pada player.
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 8, 12, 20),
                      color: AppColors.primaryTeal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              (widget.topicTitle ?? '').toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                      color: Colors.white, letterSpacing: 1),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.white),
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

                          const SizedBox(height: 100), // Space for FAB
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // === FLOATING ACTION BUTTON ===
          Positioned(
            right: 16,
            bottom: 16,
            child: _buildFloatingButton(fabSize),
          ),
        ],
      ),
    );
  }

  /// FLOATING BUTTON dengan pulse ring animation
  Widget _buildFloatingButton(double size) {
    return ScaleTransition(
      scale: Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _fabScaleController,
          curve: Curves.elasticOut,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => _AIChatBottomSheet(
              item: widget.item,
              chapters: _chapters,
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primaryTeal,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryTeal.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulse ring animation
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final value = 0.8 + (_pulseController.value * 0.6);
                  return Container(
                    width: size * value,
                    height: size * value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryTeal.withValues(
                            alpha: (1.5 - value).clamp(0.0, 1.0)),
                        width: 2,
                      ),
                    ),
                  );
                },
              ),

              // Icon
              const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
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

class _AIChatBottomSheet extends StatefulWidget {
  final RoadmapItem item;
  final List<ChapterItem> chapters;

  const _AIChatBottomSheet({
    required this.item,
    required this.chapters,
  });

  @override
  State<_AIChatBottomSheet> createState() => _AIChatBottomSheetState();
}

class _AIChatBottomSheetState extends State<_AIChatBottomSheet> {
  final List<Map<String, String>> _chatHistory = [];
  bool _isAiLoading = false;
  final TextEditingController _questionController = TextEditingController();
  ScrollController? _sheetScrollController;

  static const int _maxUserMessages = 20;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sheetScrollController?.hasClients ?? false) {
        _sheetScrollController!.animateTo(
          _sheetScrollController!.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty || _isAiLoading) return;

    final userMessageCount =
        _chatHistory.where((msg) => msg['role'] == 'user').length;

    if (userMessageCount >= _maxUserMessages) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Batas maksimum 20 pertanyaan per sesi telah tercapai.',
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _chatHistory.add({'role': 'user', 'content': question});
      _isAiLoading = true;
    });
    _questionController.clear();
    _scrollToBottom();

    try {
      final response = await Supabase.instance.client.functions
          .invoke(
            'ai-assistant',
            body: {
              'question': question,
              'videoTitle': widget.item.title,
              'channelName': widget.item.channelName,
              'chapters': widget.chapters
                  .map((c) => {
                        'title': c.title,
                        'startTime': c.startTime,
                      })
                  .toList(),
            },
          )
          .timeout(
            const Duration(seconds: 90),
            onTimeout: () => throw TimeoutException(
              'AI tidak merespons dalam 90 detik. Coba lagi.',
            ),
          );

      final answer = response.data['answer'] as String;

      if (!mounted) return;
      setState(() {
        _chatHistory.add({'role': 'assistant', 'content': answer});
        _isAiLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      String message = 'Maaf, terjadi kesalahan. Silakan coba lagi.';
      if (e is FunctionException) {
        message = 'AI gagal (${e.status}): ${e.details ?? ''}';
      } else if (e is TimeoutException) {
        message = e.message ?? message;
      } else {
        message = 'AI gagal: $e';
      }
      setState(() {
        _chatHistory.add({'role': 'assistant', 'content': message});
        _isAiLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.3, 0.55, 0.85],
      builder: (context, scrollController) {
        _sheetScrollController = scrollController;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              )
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.auto_awesome, 
                        color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('AI Assistant',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.black87,
                            )),
                          Text(
                            widget.item.title,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: Colors.grey.shade200),

              // Chat area (scrollable)
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // AI greeting (kalau chat kosong)
                    if (_chatHistory.isEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primaryTeal,
                            child: Icon(Icons.auto_awesome,
                              color: Colors.white, size: 14),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade200),
                              ),
                              child: Text(
                                'Halo! 👋 Apa yang ingin kamu pelajari dari materi ${widget.item.title} ini? 🚀\n\nSilakan tanyakan topik apa saja yang ingin kamu pahami lebih dalam.',
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Suggested questions chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'Rangkum materi ini',
                          'Berikan contoh penggunaan',
                          'Apa prasyarat belajar ini?',
                          'Topik lanjutan setelah ini?',
                        ].map((q) => GestureDetector(
                          onTap: () {
                            _questionController.text = q;
                            _sendQuestion();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.grey.shade300),
                            ),
                            child: Text(q, style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            )),
                          ),
                        )).toList(),
                      ),
                    ],

                    // Chat history
                    ..._chatHistory.map((msg) {
                      final isUser = msg['role'] == 'user';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: isUser
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                          children: [
                            if (!isUser) ...[
                              const CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.primaryTeal,
                                child: Icon(Icons.auto_awesome,
                                  color: Colors.white, size: 12),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isUser
                                    ? AppColors.primaryTeal
                                    : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                  border: isUser ? null : Border.all(
                                    color: Colors.grey.shade200),
                                ),
                                child: SelectableText(
                                  msg['content']!,
                                  style: TextStyle(
                                    color: isUser
                                      ? Colors.white
                                      : Colors.black87,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Loading indicator
                    if (_isAiLoading)
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.primaryTeal,
                            child: Icon(Icons.auto_awesome,
                              color: Colors.white, size: 12),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(3, (i) =>
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: Duration(milliseconds: 600 + (i * 100)),
                                  builder: (context, value, child) {
                                    return Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 2),
                                      width: 6, height: 6,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryTeal.withValues(alpha: 0.5 + value * 0.5),
                                        shape: BoxShape.circle,
                                      ),
                                    );
                                  },
                                )
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Input field di bawah
              Container(
                padding: EdgeInsets.fromLTRB(
                  16, 8, 16,
                  MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _questionController,
                        maxLines: null,
                        onSubmitted: (_) => _sendQuestion(),
                        decoration: InputDecoration(
                          hintText: 'Ajukan pertanyaan...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: AppColors.primaryTeal, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _isAiLoading ? null : _sendQuestion,
                      child: Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: _isAiLoading
                            ? Colors.grey.shade300
                            : AppColors.primaryTeal,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
