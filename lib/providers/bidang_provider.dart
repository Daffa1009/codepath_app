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
      // Fetch bidang + count roadmap per bidang via subquery
      final data = await _client
          .from('bidang')
          .select('*, roadmaps(count)')
          .order('sort_order');

      _bidangList = data.map<Bidang>((item) {
        final roadmapsList = item['roadmaps'] as List?;
        final roadmapCount = roadmapsList != null && roadmapsList.isNotEmpty
            ? (roadmapsList.first as Map<String, dynamic>)['count'] as int? ?? 0
            : 0;
        return Bidang.fromMap({
          ...item,
          'roadmap_count': roadmapCount,
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
