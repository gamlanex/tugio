import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CachedSvgIcon extends StatelessWidget {
  final String? iconUrl;
  final double size;
  final Color color;
  final String fallbackLetter;

  const CachedSvgIcon({
    super.key,
    required this.iconUrl,
    required this.size,
    required this.color,
    required this.fallbackLetter,
  });

  Future<Uint8List?> _loadBytes() async {
    if (iconUrl == null || iconUrl!.isEmpty) return null;
    try {
      debugPrint('[CachedSvgIcon] pobieranie: $iconUrl');
      final file = await DefaultCacheManager()
          .getSingleFile(iconUrl!)
          .timeout(const Duration(seconds: 10));
      final bytes = await file.readAsBytes();
      debugPrint('[CachedSvgIcon] OK: $iconUrl (${bytes.length} bajtów)');
      return bytes;
    } catch (e) {
      debugPrint('[CachedSvgIcon] BŁĄD: $iconUrl → $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (iconUrl == null || iconUrl!.isEmpty) {
      return _FallbackLetter(letter: fallbackLetter, size: size, color: color);
    }

    return FutureBuilder<Uint8List?>(
      future: _loadBytes(),
      builder: (context, snapshot) {
        // ── Dane załadowane ────────────────────────────────────
        if (snapshot.connectionState == ConnectionState.done) {
          final bytes = snapshot.data;
          if (bytes != null && bytes.isNotEmpty) {
            return SvgPicture.memory(
              bytes,
              width: size,
              height: size,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            );
          }
          // Brak danych lub błąd → litera
          return _FallbackLetter(
              letter: fallbackLetter, size: size, color: color);
        }

        // ── Ładowanie (tylko przy pierwszym pobraniu) ──────────
        return SizedBox(
          width: size,
          height: size,
          child: Center(
            child: SizedBox(
              width: size * 0.45,
              height: size * 0.45,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: color.withOpacity(0.4),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FallbackLetter extends StatelessWidget {
  final String letter;
  final double size;
  final Color color;

  const _FallbackLetter(
      {required this.letter, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: size * 0.65,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1,
          ),
        ),
      ),
    );
  }
}
