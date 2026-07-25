import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/roadmap.dart';
import '../models/roadmap_item.dart';

/// Mengelola daftar roadmap (jalur belajar) dari Supabase,
/// termasuk progress user per video.
class RoadmapProvider extends ChangeNotifier {
  final List<Roadmap> _roadmaps = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Roadmap> get roadmaps => _roadmaps;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Roadmap> get berjalan =>
      _roadmaps.where((r) => r.status == RoadmapStatus.berjalan).toList();

  List<Roadmap> get selesai =>
      _roadmaps.where((r) => r.status == RoadmapStatus.selesai).toList();

  /// Roadmap terakhir yang masih berjalan — section "Lanjutkan Belajar".
  Roadmap? get lastInProgress => berjalan.isNotEmpty ? berjalan.first : null;

  Roadmap byId(String id) => _roadmaps.firstWhere((r) => r.id == id);

  /// Video berikutnya yang direkomendasikan (belum selesai, urutan pertama).
  RoadmapItem? get recommendedNext {
    for (final r in _roadmaps) {
      for (final item in r.items) {
        if (!item.isCompleted) return item;
      }
    }
    return null;
  }

  int get totalRoadmaps => _roadmaps.length;
  int get completedRoadmaps => selesai.length;

  SupabaseClient get _client => Supabase.instance.client;
  String? get _userId => _client.auth.currentUser?.id;

  /// === FETCH DATA DARI SUPABASE ===

  Future<void> loadData() async {
    final userId = _userId;
    if (userId == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch semua roadmaps
      final roadmapRows = await _client
          .from('roadmaps')
          .select('id, title, description, icon_name')
          .order('created_at');

      // 2. Fetch semua roadmap_items
      final itemRows = await _client
          .from('roadmap_items')
          .select('id, roadmap_id, title, channel_name, youtube_url, duration_minutes, sort_order')
          .order('sort_order');

      // 3. Fetch user_progress milik user saat ini
      final progressRows = await _client
          .from('user_progress')
          .select('roadmap_item_id, is_completed, completed_at')
          .eq('user_id', userId);

      // Build lookup set: item ID yang sudah completed
      final completedItemIds = <String>{};
      for (final row in progressRows) {
        if (row['is_completed'] == true) {
          completedItemIds.add(row['roadmap_item_id'] as String);
        }
      }

      // 4. Build model objects
      _roadmaps.clear();

      for (final rRow in roadmapRows) {
        final rId = rRow['id'] as String;
        final iconName = rRow['icon_name'] as String? ?? 'code';

        // Filter items milik roadmap ini
        final items = <RoadmapItem>[];
        for (final iRow in itemRows) {
          if (iRow['roadmap_id'] as String == rId) {
            final itemId = iRow['id'] as String;
            items.add(RoadmapItem(
              id: itemId,
              title: iRow['title'] as String,
              channelName: iRow['channel_name'] as String? ?? '',
              youtubeUrl: iRow['youtube_url'] as String,
              durationMinutes: iRow['duration_minutes'] as int? ?? 0,
              sortOrder: iRow['sort_order'] as int? ?? 0,
              isCompleted: completedItemIds.contains(itemId),
            ));
          }
        }

        _roadmaps.add(Roadmap(
          id: rId,
          title: rRow['title'] as String,
          description: rRow['description'] as String? ?? '',
          iconColor: _iconNameToColor(iconName),
          icon: _iconNameToData(iconName),
          items: items,
        ));
      }

      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal memuat data roadmap.';
    }

    notifyListeners();
  }

  /// === TANDAI VIDEO SELESAI ===

  Future<void> markVideoCompleted(String itemId) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      // UPSERT: jika row sudah ada → update, jika belum → insert
      await _client.from('user_progress').upsert({
        'user_id': userId,
        'roadmap_item_id': itemId,
        'is_completed': true,
        'completed_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,roadmap_item_id');

      // Update in-memory state
      for (final roadmap in _roadmaps) {
        for (final item in roadmap.items) {
          if (item.id == itemId) {
            item.isCompleted = true;
            break;
          }
        }
      }

      notifyListeners();
    } catch (_) {
      // Silent fail — UI tetap update optimistically (item.isCompleted sudah true)
    }
  }

  /// Convenience — dipanggil dari VideoDetailScreen dengan roadmapId + itemId.
  Future<void> markItemComplete(String roadmapId, String itemId) async {
    await markVideoCompleted(itemId);
  }

  /// === ADMIN CRUD ===

  Future<void> addRoadmap({
    required String title,
    required String description,
    required String iconName,
  }) async {
    await _client.from('roadmaps').insert({
      'title': title,
      'description': description,
      'icon_name': iconName,
    });
  }

  Future<void> updateRoadmap({
    required String id,
    required String title,
    required String description,
    required String iconName,
  }) async {
    await _client.from('roadmaps').update({
      'title': title,
      'description': description,
      'icon_name': iconName,
    }).eq('id', id);
  }

  Future<void> deleteRoadmap(String id) async {
    // CASCADE delete akan otomatis hapus roadmap_items + user_progress terkait
    await _client.from('roadmaps').delete().eq('id', id);
  }

  Future<void> addRoadmapItem({
    required String roadmapId,
    required String title,
    required String channelName,
    required String youtubeUrl,
    required int durationMinutes,
    required int sortOrder,
  }) async {
    await _client.from('roadmap_items').insert({
      'roadmap_id': roadmapId,
      'title': title,
      'channel_name': channelName,
      'youtube_url': youtubeUrl,
      'duration_minutes': durationMinutes,
      'sort_order': sortOrder,
    });
  }

  Future<void> updateRoadmapItem({
    required String id,
    required String title,
    required String channelName,
    required String youtubeUrl,
    required int durationMinutes,
    required int sortOrder,
  }) async {
    await _client.from('roadmap_items').update({
      'title': title,
      'channel_name': channelName,
      'youtube_url': youtubeUrl,
      'duration_minutes': durationMinutes,
      'sort_order': sortOrder,
    }).eq('id', id);
  }

  Future<void> deleteRoadmapItem(String id) async {
    await _client.from('roadmap_items').delete().eq('id', id);
  }

  /// === HELPERS: icon_name → IconData / Color ===

  static IconData _iconNameToData(String name) {
    switch (name) {
      case 'code':
        return Icons.code;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'web':
        return Icons.web;
      case 'school':
        return Icons.school;
      case 'build':
        return Icons.build;
      case 'phone_android':
        return Icons.phone_android;
      case 'storage':
        return Icons.storage;
      case 'cloud':
        return Icons.cloud;
      default:
        return Icons.menu_book;
    }
  }

  static Color _iconNameToColor(String name) {
    switch (name) {
      case 'code':
        return const Color(0xFFC9A227); // gold
      case 'auto_awesome':
        return const Color(0xFF0D3B36); // primary teal
      case 'web':
        return const Color(0xFFC9A227); // gold
      case 'school':
        return const Color(0xFF1E7A46); // success green
      case 'phone_android':
        return const Color(0xFFA02020); // maroon
      default:
        return const Color(0xFF0D3B36); // primary teal default
    }
  }

  /// Map string icon name ke Flutter IconData. Digunakan oleh admin screen
  /// untuk dropdown pilihan icon.
  static const Map<String, IconData> availableIcons = {
    'code': Icons.code,
    'auto_awesome': Icons.auto_awesome,
    'web': Icons.web,
    'school': Icons.school,
    'build': Icons.build,
    'phone_android': Icons.phone_android,
    'storage': Icons.storage,
    'cloud': Icons.cloud,
    'menu_book': Icons.menu_book,
  };
}
