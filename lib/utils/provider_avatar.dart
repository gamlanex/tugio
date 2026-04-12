import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Zwraca ikonę dopasowaną do typu usługi.
IconData serviceTypeIcon(String serviceType) {
  switch (serviceType.toLowerCase()) {
    case 'fryzjer':
    case 'salon urody':
      return Icons.content_cut_rounded;
    case 'psycholog':
    case 'psychiatra':
    case 'terapeuta':
      return Icons.self_improvement_rounded;
    case 'trener personalny':
    case 'trener':
    case 'fitness':
      return Icons.fitness_center_rounded;
    case 'dentysta':
    case 'stomatolog':
      return Icons.medical_services_rounded;
    case 'lekarz':
    case 'internista':
      return Icons.local_hospital_rounded;
    case 'masażysta':
    case 'masaż':
      return Icons.spa_rounded;
    case 'dietetyk':
    case 'dieta':
      return Icons.restaurant_rounded;
    case 'kosmetyczka':
    case 'kosmetolog':
      return Icons.face_retouching_natural_rounded;
    default:
      return Icons.store_rounded;
  }
}

/// Zwraca kolor tematyczny dla danego typu usługi.
/// Kolory są zdefiniowane centralnie w AppColors.serviceTypeColors.
Color serviceTypeColor(String serviceType) {
  // Normalizuj: szukaj po kluczu case-insensitive
  final key = AppColors.serviceTypeColors.keys.firstWhere(
    (k) => k.toLowerCase() == serviceType.toLowerCase(),
    orElse: () => '',
  );
  return AppColors.serviceTypeColors[key] ?? AppColors.seed;
}

/// Gotowy widget awatara usługodawcy z ikoną tematyczną.
class ProviderAvatar extends StatelessWidget {
  final String serviceType;
  final double radius;

  const ProviderAvatar({
    super.key,
    required this.serviceType,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final color = serviceTypeColor(serviceType);
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withOpacity(0.13),
      child: Icon(
        serviceTypeIcon(serviceType),
        color: color,
        size: radius * 0.9,
      ),
    );
  }
}
