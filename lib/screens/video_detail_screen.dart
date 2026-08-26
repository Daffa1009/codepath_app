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

  // State AI Assistant — history disimpan di lokal state sehingga otomatis
  // terhapus saat user keluar dari halaman.
  final List<Map<String, String>> _chatHistory = [];
  bool _isAiLoading = false;
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  // Floating Chat Widget State
  bool _isChatOpen = false;
  late AnimationController _fabScaleController;
  late AnimationController _pulseController;

  /// Batas maksimum pertanyaan user per sesi.
  static const int _maxUserMessages = 20;

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
    _questionController.dispose();
    _chatScrollController.dispose();
    _fabScaleController.dispose();
    _pulseController.dispose();
    _removePointerBlockerOverlay();
    super.dispose();
  }

  /// Bikin HTML overlay element di atas iframe YouTube untuk memblokir
  /// pointer event saat panel AI terbuka. IgnorePointer Flutter TIDAK
  /// bekerja untuk platform view HTML — iframe adalah elemen DOM
  /// independen yang menangkap event-nya sendiri, jadi harus manipulasi
  /// langsung di level DOM/browser.
  void _applyPointerBlockerOverlay() {
    if (!kIsWeb) return;
    try {
      final iframe =
          web.document.querySelector('iframe.youtube-embed') as web.HTMLIFrameElement?;
      if (iframe == null) return;

      // Matikan pointer-events iframe langsung di CSS
      iframe.style.pointerEvents = 'none';
      // Hentikan video YouTube untuk benar-benar mencegah play/pause
      final src = iframe.src;
      if (!src.contains('enablejsapi=1')) {
        iframe.src = src + (src.contains('?') ? '&' : '?') + 'enablejsapi=1';
      }
      // Buat overlay element transparan di atas seluruh area halaman
      // (bukan hanya di atas iframe) yang menangkap SEMUA pointer event
      // di level browser. Ini adalah "second line of defense" karena
      // panel AI juga bisa tumpang tindih dengan chapter tiles.
      // Overlay div ini sendirinya (tanpa event listener) sudah cukup
      // memblokir klik mencapai iframe/chapter karena zIndex 999
      // menutupi seluruh viewport. Penutupan panel di-handle oleh
      // Flutter GestureDetector barrier di Stack.
      _removePointerBlockerOverlay(); // bersihkan dulu jika sudah ada
      final overlay = web.document.createElement('div') as web.HTMLDivElement;
      overlay.id = '__ai-chat-pointer-blocker__';
      overlay.style.position = 'fixed';
      overlay.style.top = '0';
      overlay.style.left = '0';
      overlay.style.width = '100vw';
      overlay.style.height = '100vh';
      overlay.style.zIndex = '999'; // di atas konten tapi di bawah panel AI (1000)
      overlay.style.backgroundColor = 'transparent';
      overlay.style.cursor = 'default';
      web.document.body!.appendChild(overlay);
    } catch (_) {
      // Best effort — jangan crash UI jika gagal
    }
  }

  /// Hapus overlay pemblokiran pointer (dipanggil saat panel ditutup).
  void _removePointerBlockerOverlay() {
    if (!kIsWeb) return;
    try {
      final existing =
          web.document.getElementById('__ai-chat-pointer-blocker__');
      if (existing != null) {
        existing.remove();
      }
      final iframe =
          web.document.querySelector('iframe.youtube-embed') as web.HTMLIFrameElement?;
      if (iframe != null) {
        iframe.style.pointerEvents = '';
      }
    } catch (_) {}
  }

  /// Toggle panel AI + pasang/hapus DOM overlay pemblokiran pointer ke iframe
  void _toggleChat() {
    final willOpen = !_isChatOpen;
    setState(() => _isChatOpen = willOpen);
    if (willOpen) {
      _applyPointerBlockerOverlay();
    } else {
      _removePointerBlockerOverlay();
    }
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

  /// Kirim pertanyaan user ke AI Assistant via Supabase Edge Function.
  Future<void> _sendQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty || _isAiLoading) return;

    final userMessageCount =
        _chatHistory.where((msg) => msg['role'] == 'user').length;

    if (userMessageCount >= _maxUserMessages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Batas maksimum 20 pertanyaan per sesi telah tercapai.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _chatHistory.add({'role': 'user', 'content': question});
      _isAiLoading = true;
    });
    _questionController.clear();
    _scrollToBottom();

    try {
      debugPrint('[AI] sending question: "$question"');
      final response = await Supabase.instance.client.functions
          .invoke(
            'ai-assistant',
            body: {
              'question': question,
              'videoTitle': widget.item.title,
              'channelName': widget.item.channelName,
              'chapters': _chapters
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

      debugPrint('[AI] response status: ${response.status}');
      final answer = response.data['answer'] as String;

      if (!mounted) return;
      setState(() {
        _chatHistory.add({'role': 'assistant', 'content': answer});
        _isAiLoading = false;
      });
      _scrollToBottom();
    } catch (e, st) {
      debugPrint('[AI] ERROR: $e');
      debugPrint('[AI] stack: $st');
      if (!mounted) return;

      String message = 'Maaf, terjadi kesalahan. Silakan coba lagi.';
      if (e is FunctionException) {
        debugPrint(
            '[AI] FunctionException: status=${e.status}, details=${e.details}');
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
    }
  }

  /// Auto-scroll chat ke bawah saat ada pesan baru.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Tiga titik teal dengan opacity naik — indikator AI sedang mengetik.
  Widget _buildTypingIndicator() {
    return Row(
      children: List.generate(
        3,
        (i) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 600 + (i * 100)),
          builder: (context, value, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color:
                    AppColors.primaryTeal.withValues(alpha: 0.5 + value * 0.5),
                shape: BoxShape.circle,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final panelWidth = (screenWidth * 0.85).clamp(280.0, 380.0);
    final panelHeight = screenHeight * 0.68;
    final fabSize = 56.0;

    return Scaffold(
      backgroundColor: Colors.white,
      // Matikan interaksi YouTube iframe secara native saat chat terbuka,
      // sehingga klik "Tutup" / "Saran" tidak diinterpretasikan browser
      // sebagai play/pause pada player.
      body: Stack(
        children: [
          SafeArea(
            // IgnorePointer: saat panel terbuka, konten di belakangnya (YouTube
            // iframe, chapter tiles, tombol YT, dst) tidak menerima tap.
            // Ini mencegah event bocor ke player YT dan chapter "loncat menit".
            child: IgnorePointer(
              ignoring: _isChatOpen,
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
          ),

          // === OVERLAY BARRIER (modal-style) ===
          // GestureDetector ini menangkap tap di luar panel sebagai
          // "tutup panel" (DOM overlay utama juga dipasang di
          // _applyPointerBlockerOverlay untuk memblokir event ke iframe).
          if (_isChatOpen)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleChat,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ),
            ),

          // === CHAT PANEL (slide dari kanan) ===
          // Ditaruh SETELAH barrier agar menerima event, dan posisinya
          // hanya men-cover sebagian layar (panel kecil), jadi area di
          // luar panel akan tetap tertutup barrier & tidak bocor.
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            right: _isChatOpen ? 16 : -panelWidth - 16,
            bottom: 80,
            width: panelWidth,
            height: panelHeight,
            child: IgnorePointer(
              ignoring: !_isChatOpen,
              child: _buildChatPanel(),
            ),
          ),

          // === FLOATING ACTION BUTTON ===
          // IgnorePointer saat tertutup agar tidak mengganggu konten
          // di belakangnya (sangat kecil kemungkinannya, tapi aman).
          Positioned(
            right: 16,
            bottom: 16,
            child: IgnorePointer(
              ignoring: _isChatOpen,
              child: GestureDetector(
                onTap: _toggleChat,
                child: _buildFloatingButton(fabSize),
              ),
            ),
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
        onTap: () => setState(() => _isChatOpen = !_isChatOpen),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _isChatOpen
                ? AppColors.primaryTeal.withValues(alpha: 0.7)
                : AppColors.primaryTeal,
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
              if (!_isChatOpen)
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

              // Icon berubah saat terbuka/tertutup
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _isChatOpen ? Icons.close : Icons.auto_awesome,
                  key: ValueKey(_isChatOpen),
                  color: Colors.white,
                  size: 24,
                ),
              ),

              // Badge "AI" di pojok kanan atas
              if (!_isChatOpen)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// CHAT PANEL WIDGET
  Widget _buildChatPanel() {
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(16),
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header (teal)
            Container(
              color: AppColors.primaryTeal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
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
                        const Text(
                          'AI Assistant',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          widget.item.title,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => setState(() => _isChatOpen = false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Body (chat area)
            Expanded(
              child: Container(
                color: Colors.grey.shade50,
                child: _buildChatBody(),
              ),
            ),

            // Footer (input)
            Container(
              color: Colors.white,
              child: _buildChatInput(),
            ),
          ],
        ),
      ),
    );
  }

  /// CHAT BODY - riwayat + suggested questions + typing indicator
  Widget _buildChatBody() {
    return ListView(
      controller: _chatScrollController,
      padding: const EdgeInsets.all(12),
      children: [
        if (_chatHistory.isNotEmpty) ...[
          ..._chatHistory.map((msg) => _buildChatBubble(msg)),
          if (_isAiLoading) _buildTypingBubble(),
        ],
        if (_chatHistory.isEmpty) _buildSuggestedQuestions(),
      ],
    );
  }

  /// Single chat bubble
  Widget _buildChatBubble(Map<String, String> msg) {
    final isUser = msg['role'] == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryTeal,
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primaryTeal : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: isUser
                    ? null
                    : Border.all(color: Colors.grey.shade200),
              ),
              child: SelectableText(
                msg['content']!,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  /// Typing indicator bubble
  Widget _buildTypingBubble() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primaryTeal,
          child: const Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 14,
          ),
        ),
        const SizedBox(width: 8),
        _buildTypingIndicator(),
      ],
    );
  }

  /// Suggested questions chips (saat chat kosong)
  Widget _buildSuggestedQuestions() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          'Jelaskan konsep utama video ini',
          'Berikan contoh penggunaan',
          'Apa yang harus dipelajari selanjutnya?',
        ].map((q) => GestureDetector(
              onTap: () {
                _questionController.text = q;
                _sendQuestion();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryTeal.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  q,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),
            )).toList(),
      ),
    );
  }

  /// CHAT INPUT FOOTER
  Widget _buildChatInput() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _questionController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendQuestion(),
              decoration: InputDecoration(
                hintText: 'Tanyakan sesuatu tentang materi ini...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isAiLoading ? null : _sendQuestion,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isAiLoading
                    ? Colors.grey.shade300
                    : AppColors.primaryTeal,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
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
