import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../config/theme.dart';
import '../models/roadmap.dart';
import '../models/roadmap_item.dart';
import '../providers/roadmap_provider.dart';
import '../widgets/course_card.dart';
import 'roadmap_detail_screen.dart';
import 'video_detail_screen.dart';

enum _Filter { semua, selesai, berjalan }

class RoadmapListScreen extends StatefulWidget {
  const RoadmapListScreen({super.key});

  @override
  State<RoadmapListScreen> createState() => _RoadmapListScreenState();
}

class _RoadmapListScreenState extends State<RoadmapListScreen> {
  _Filter _filter = _Filter.semua;

  // Search
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Optional: auto-focus on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    // Debounce 300ms
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim().toLowerCase();
        });
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoadmapProvider>();
    final roadmaps = provider.roadmaps;
    final isLoading = provider.isLoading;
    final errorMessage = provider.errorMessage;

    if (isLoading) {
      return const SafeArea(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.maroon),
              const SizedBox(height: 16),
              Text(errorMessage, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => provider.loadData(),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    // Filter logic
    List<Roadmap> filteredRoadmaps;
    switch (_filter) {
      case _Filter.selesai:
        filteredRoadmaps = provider.selesai;
        break;
      case _Filter.berjalan:
        filteredRoadmaps = provider.berjalan;
        break;
      case _Filter.semua:
        filteredRoadmaps = roadmaps;
        break;
    }

    final bool isSearching = _searchQuery.isNotEmpty;

    // Search results
    final roadmapResults = isSearching
        ? filteredRoadmaps
            .where((r) => r.title.toLowerCase().contains(_searchQuery))
            .toList()
        : <Roadmap>[];

    // Video level search results
    final Map<Roadmap, List<RoadmapItem>> videoResults = {};
    if (isSearching) {
      for (final roadmap in filteredRoadmaps) {
        final matchingItems = roadmap.items.where((item) {
          final title = item.title.toLowerCase();
          final channel = item.channelName.toLowerCase();
          return title.contains(_searchQuery) || channel.contains(_searchQuery);
        }).toList();
        if (matchingItems.isNotEmpty) {
          videoResults[roadmap] = matchingItems;
        }
      }
    }

    final hasRoadmapResults = roadmapResults.isNotEmpty;
    final hasVideoResults = videoResults.isNotEmpty;
    final hasAnyResults = hasRoadmapResults || hasVideoResults;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ─── SliverAppBar — scroll mengecil smooth seperti bidang_detail ───
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.primaryTeal,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: const Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jalur Belajar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Temukan roadmap yang sesuai',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryTeal,
                      Color(0xFF1A5C54),
                    ],
                  ),
                ),
                child: const Align(
                  alignment: Alignment.centerRight,
                  child: Opacity(
                    opacity: 0.08,
                    child: Icon(
                      Icons.route_rounded,
                      size: 140,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ─── Search bar + filter chips inline ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  // Filter chips
                  _filterChip('Semua', _Filter.semua),
                  const SizedBox(width: 8),
                  _filterChip('Berjalan', _Filter.berjalan),
                  const SizedBox(width: 8),
                  _filterChip('Selesai', _Filter.selesai),
                  const SizedBox(width: 10),
                  // Search icon button → expand ke TextField
                  Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.text,
                      child: SizedBox(
                        height: 38,
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _searchFocus.unfocus(),
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Cari...',
                            hintStyle: const TextStyle(
                                color: AppColors.textMuted, fontSize: 13),
                            prefixIcon: const Icon(Icons.search,
                                color: AppColors.textMuted, size: 18),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear,
                                        color: AppColors.textMuted, size: 16),
                                    onPressed: _clearSearch,
                                    padding: EdgeInsets.zero,
                                  )
                                : null,
                            filled: true,
                            fillColor: AppColors.inputBackground,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 0),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              borderSide: const BorderSide(
                                  color: AppColors.primaryTeal, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Content ───
          isSearching
              ? _buildSearchResultsSliver(
                  roadmapResults: roadmapResults,
                  videoResults: videoResults,
                  hasAnyResults: hasAnyResults,
                  query: _searchQuery,
                )
              : _buildDefaultListSliver(roadmaps: filteredRoadmaps),
        ],
      ),
    );
  }

  Widget _buildDefaultListSliver({required List<Roadmap> roadmaps}) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final roadmap = roadmaps[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: CourseCard(
                roadmap: roadmap,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RoadmapDetailScreen(roadmapId: roadmap.id),
                  ),
                ),
              ),
            );
          },
          childCount: roadmaps.length,
        ),
      ),
    );
  }

  Widget _buildSearchResultsSliver({
    required List<Roadmap> roadmapResults,
    required Map<Roadmap, List<RoadmapItem>> videoResults,
    required bool hasAnyResults,
    required String query,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      sliver: SliverToBoxAdapter(
        child: _buildSearchResults(
          key: const ValueKey('search_results'),
          roadmapResults: roadmapResults,
          videoResults: videoResults,
          hasAnyResults: hasAnyResults,
          query: query,
        ),
      ),
    );
  }

  Widget _buildSearchResults({
    required Key key,
    required List<Roadmap> roadmapResults,
    required Map<Roadmap, List<RoadmapItem>> videoResults,
    required bool hasAnyResults,
    required String query,
  }) {
    return ListView(
      key: key,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        if (!hasAnyResults)
          _buildEmptyState(query)
        else ...[
          if (roadmapResults.isNotEmpty) ...[
            _buildSectionHeader('Jalur Belajar'),
            const SizedBox(height: 8),
            ...roadmapResults.map((roadmap) => _SearchResultFadeIn(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: CourseCard(
                      roadmap: roadmap,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RoadmapDetailScreen(roadmapId: roadmap.id),
                        ),
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 20),
          ],
          if (videoResults.isNotEmpty) ...[
            _buildSectionHeader('Video & Materi'),
            const SizedBox(height: 8),
            ...videoResults.entries.map((entry) {
              final roadmap = entry.key;
              final items = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SearchResultFadeIn(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        roadmap.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.primaryTeal,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                  ...items.map((item) => _SearchResultFadeIn(
                        child: _VideoSearchResultTile(
                          item: item,
                          roadmapId: roadmap.id,
                          query: query,
                        ),
                      )),
                  const SizedBox(height: 12),
                ],
              );
            }),
          ],
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
    );
  }

  Widget _buildEmptyState(String query) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Tidak ada hasil untuk "$query"',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textDark,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba kata kunci lain',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, _Filter value) {
    final active = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: active,
      showCheckmark: false,
      onSelected: (_) => setState(() => _filter = value),
      // AKTIF: background gold, teks putih
      selectedColor: AppColors.gold,
      // TIDAK AKTIF: background putih, teks teal, border teal tipis
      backgroundColor: Colors.white,
      side: BorderSide(
        color: active
            ? Colors.transparent
            : AppColors.primaryTeal.withValues(alpha: 0.3),
      ),
      labelStyle: TextStyle(
        color: active ? Colors.white : AppColors.primaryTeal,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      shape: const StadiumBorder(),
    );
  }
}

/// Staggered fade-in animation for search results
class _SearchResultFadeIn extends StatefulWidget {
  final Widget child;

  const _SearchResultFadeIn({required this.child});

  @override
  State<_SearchResultFadeIn> createState() => _SearchResultFadeInState();
}

class _SearchResultFadeInState extends State<_SearchResultFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

/// Video search result tile with highlight text
class _VideoSearchResultTile extends StatelessWidget {
  final RoadmapItem item;
  final String roadmapId;
  final String query;

  const _VideoSearchResultTile({
    required this.item,
    required this.roadmapId,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium!;
    final subtitleStyle = theme.textTheme.bodySmall!.copyWith(color: AppColors.textMuted);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoDetailScreen(
                item: item,
                roadmapId: roadmapId,
                topicTitle: '', // optional
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Row(
              children: [
                // Leading: play icon in colored box
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.play_arrow, color: AppColors.primaryTeal, size: 20),
                ),
                const SizedBox(width: 14),
                // Title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HighlightText(text: item.title, query: query, style: textStyle),
                      const SizedBox(height: 2),
                      HighlightText(
                        text: '${item.channelName} · ${item.durationLabel}',
                        query: query,
                        style: subtitleStyle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper widget to highlight matching text
class HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;

  const HighlightText({
    super.key,
    required this.text,
    required this.query,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text, style: style);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return Text(text, style: style);
    }

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text.substring(0, index),
            style: style,
          ),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: style.copyWith(
              backgroundColor: AppColors.gold.withValues(alpha: 0.3),
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: text.substring(index + query.length),
            style: style,
          ),
        ],
      ),
    );
  }
}
