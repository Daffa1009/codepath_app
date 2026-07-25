import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Header dark teal standar dipakai di sebagian besar screen
/// (Jalur Belajar, Latihan, Progress, dsb).
class AppHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onClose;

  const AppHeader({
    super.key,
    required this.title,
    this.onBack,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
      color: AppColors.primaryTeal,
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white24,
                shape: const CircleBorder(),
              ),
            ),
          if (onBack != null) const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
            ),
          ),
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, color: Colors.white),
            ),
        ],
      ),
    );
  }
}
