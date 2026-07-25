import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Statistik & aktivitas belajar untuk halaman Progress.
/// Data dihitung dari tabel user_progress di Supabase.
class ProgressProvider extends ChangeNotifier {
  bool _isLoading = false;

  Map<String, double> _weeklyActivity = {};
  int _streakDays = 0;
  int _videosWatched = 0;

  bool get isLoading => _isLoading;
  Map<String, double> get weeklyActivity => _weeklyActivity;
  int get streakDays => _streakDays;
  int get videosWatched => _videosWatched;

  SupabaseClient get _client => Supabase.instance.client;
  String? get _userId => _client.auth.currentUser?.id;

  /// === FETCH DATA DARI SUPABASE ===

  Future<void> loadData() async {
    final userId = _userId;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Total video ditonton
      final completedRows = await _client
          .from('user_progress')
          .select('id')
          .eq('user_id', userId)
          .eq('is_completed', true);
      _videosWatched = completedRows.length;

      // 2. Streak hari — hitung distinct dates dari completed_at
      // TODO: Logic streak yang lebih akurat: iterasi mundur dari hari ini
      //       dan hitung berapa hari berturut-turut ada completed_at.
      //       Versi awal ini hanya menghitung jumlah hari unik yang ada.
      final streakResponse = await _client
          .from('user_progress')
          .select('completed_at')
          .eq('user_id', userId)
          .eq('is_completed', true)
          .not('completed_at', 'is', null);

      final uniqueDays = <String>{};
      for (final row in streakResponse) {
        final dateStr = (row['completed_at'] as String).substring(0, 10); // YYYY-MM-DD
        uniqueDays.add(dateStr);
      }
      _streakDays = uniqueDays.length;

      // 3. Aktivitas mingguan (7 hari terakhir, group by hari)
      final now = DateTime.now().toUtc();
      final sevenDaysAgo = now.subtract(const Duration(days: 6));

      final weeklyResponse = await _client
          .from('user_progress')
          .select('completed_at')
          .eq('user_id', userId)
          .eq('is_completed', true)
          .gte('completed_at', sevenDaysAgo.toIso8601String())
          .not('completed_at', 'is', null);

      // Map nama hari (Bahasa Indonesia) → count
      final hariCount = <String, int>{};
      const hariLabels = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

      // Inisialisasi 0 untuk 7 hari terakhir
      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        hariCount[hariLabels[day.weekday % 7]] = 0;
      }

      for (final row in weeklyResponse) {
        final dt = DateTime.parse(row['completed_at'] as String).toLocal();
        final label = hariLabels[dt.weekday % 7];
        hariCount[label] = (hariCount[label] ?? 0) + 1;
      }

      // Normalize ke 0.0–1.0 (max = hari terbanyak dalam minggu ini)
      final maxCount = hariCount.values.isEmpty
          ? 1
          : hariCount.values.reduce((a, b) => a > b ? a : b);
      _weeklyActivity = hariCount.map(
        (key, value) => MapEntry(
          key,
          maxCount > 0 ? value / maxCount : 0.0,
        ),
      );

      _isLoading = false;
    } catch (_) {
      _isLoading = false;
    }

    notifyListeners();
  }
}
