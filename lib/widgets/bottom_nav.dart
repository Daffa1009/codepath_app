import 'package:flutter/material.dart';
import '../config/theme.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  static const _items = [
    (icon: Icons.home_rounded, label: 'Beranda'),
    (icon: Icons.collections_bookmark_rounded, label: 'Jalur Belajar'),
    (icon: Icons.check_circle_rounded, label: 'Latihan'),
    (icon: Icons.bar_chart_rounded, label: 'Progress'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.primaryTeal, width: 1.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (index) {
          final item = _items[index];
          final active = index == currentIndex;
          final color = active ? AppColors.primaryTeal : AppColors.textMuted;
          return InkWell(
            onTap: () => onTap(index),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, color: color),
                const SizedBox(height: 4),
                Text(item.label,
                    style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
              ],
            ),
          );
        }),
      ),
    );
  }
}
