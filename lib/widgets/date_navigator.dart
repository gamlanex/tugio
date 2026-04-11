import 'package:flutter/material.dart';

class DateNavigator extends StatelessWidget {
  final String title;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  /// Jeśli nie-null, wyświetlany jest przycisk "Dziś".
  final VoidCallback? onToday;
  /// Czy bieżący widok pokazuje dziś — wtedy przycisk "Dziś" jest nieaktywny.
  final bool isToday;

  const DateNavigator({
    super.key,
    required this.title,
    required this.onPrevious,
    required this.onNext,
    this.onToday,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
          visualDensity: VisualDensity.compact,
        ),

        // ── Przycisk "Dziś" ───────────────────────────────
        if (onToday != null) ...[
          AnimatedOpacity(
            opacity: isToday ? 0.35 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: TextButton(
              onPressed: isToday ? null : onToday,
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: Colors.indigo,
                textStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: Colors.indigo.withOpacity(isToday ? 0.2 : 0.5),
                    width: 1,
                  ),
                ),
              ),
              child: const Text('Dziś'),
            ),
          ),
          const SizedBox(width: 4),
        ],

        // ── Tytuł (data / zakres) ─────────────────────────
        Expanded(
          child: Center(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),

        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
