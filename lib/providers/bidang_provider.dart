import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bidang.dart';

/// Provider untuk daftar Bidang/Kategori dari Supabase.
class BidangProvider extends ChangeNotifier {
  List<Bidang> _bidangList = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Bidang> get bidangList => _bidangList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Query 1: ambil semua bidang
      final bidangData = await _client
          .from('bidang')
          .select()
          .order('sort_order', ascending: true);

      // Query 2: hitung jumlah roadmap per bidang
      final roadmapData = await _client
          .from('roadmaps')
          .select('bidang_id')
          .not('bidang_id', 'is', null);

      // Hitung manual pakai Map
      final countMap = <String, int>{};
      for (final r in roadmapData) {
        final bid = r['bidang_id'] as String? ?? '';
        if (bid.isNotEmpty) {
          countMap[bid] = (countMap[bid] ?? 0) + 1;
        }
      }

      // Gabungkan bidang + count
      _bidangList = (bidangData as List).map((item) {
        return Bidang.fromMap({
          ...Map<String, dynamic>.from(item),
          'roadmap_count': countMap[item['id'] as String] ?? 0,
        });
      }).toList();
    } catch (e) {
      _errorMessage = 'Gagal memuat bidang.';
      debugPrint('Error loading bidang: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// CRUD admin
  Future<void> addBidang({
    required String nama,
    String? deskripsi,
    String? iconName,
    String? warna,
    int sortOrder = 0,
  }) async {
    await _client.from('bidang').insert({
      'nama': nama,
      if (deskripsi != null) 'deskripsi': deskripsi,
      if (iconName != null) 'icon_name': iconName,
      if (warna != null) 'warna': warna,
      'sort_order': sortOrder,
    });
  }

  Future<void> updateBidang({
    required String id,
    required String nama,
    String? deskripsi,
    String? iconName,
    String? warna,
    int sortOrder = 0,
  }) async {
    await _client.from('bidang').update({
      'nama': nama,
      'deskripsi': deskripsi,
      'icon_name': iconName,
      'warna': warna,
      'sort_order': sortOrder,
    }).eq('id', id);
  }

  Future<void> deleteBidang(String id) async {
    await _client.from('bidang').delete().eq('id', id);
  }

  /// Icon-name yang tersedia untuk dropdown admin
  static const Map<String, IconData> availableIcons = {
    'web': Icons.web_rounded,
    'dns': Icons.dns_rounded,
    'phone_android': Icons.phone_android_rounded,
    'analytics': Icons.analytics_rounded,
    'cloud': Icons.cloud_rounded,
    'auto_awesome': Icons.auto_awesome_rounded,
    'code': Icons.code_rounded,
    'folder': Icons.folder_rounded,
  };
}
