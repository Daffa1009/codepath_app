import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Model untuk bidang/kategori ilmu — level di atas roadmap.
class Bidang {
  final String id;
  final String nama;
  final String? deskripsi;
  final String? iconName;
  final String? warna;
  final int sortOrder;
  final int roadmapCount;

  const Bidang({
    required this.id,
    required this.nama,
    this.deskripsi,
    this.iconName,
    this.warna,
    this.sortOrder = 0,
    this.roadmapCount = 0,
  });

  factory Bidang.fromMap(Map<String, dynamic> map) => Bidang(
        id: map['id'] as String,
        nama: map['nama'] as String,
        deskripsi: map['deskripsi'] as String?,
        iconName: map['icon_name'] as String?,
        warna: map['warna'] as String?,
        sortOrder: map['sort_order'] as int? ?? 0,
        roadmapCount: map['roadmap_count'] as int? ?? 0,
      );

  Color get warnaColor {
    if (warna == null) return AppColors.primaryTeal;
    try {
      return Color(int.parse(warna!.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primaryTeal;
    }
  }

  IconData get iconData {
    switch (iconName) {
      case 'web':
        return Icons.web_rounded;
      case 'dns':
        return Icons.dns_rounded;
      case 'phone_android':
        return Icons.phone_android_rounded;
      case 'analytics':
        return Icons.analytics_rounded;
      case 'cloud':
        return Icons.cloud_rounded;
      case 'auto_awesome':
        return Icons.auto_awesome_rounded;
      case 'code':
        return Icons.code_rounded;
      default:
        return Icons.folder_rounded;
    }
  }
}
