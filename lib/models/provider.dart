class ServiceProvider {
  final String id;
  final String name;
  final String serviceType;
  final String address;
  final double lat;
  final double lng;
  final List<String> slots;
  final int slotDurationMinutes;
  bool isSubscribed;
  final double? rating;
  final String? placeId;
  /// Sloty wymagające potwierdzenia właściciela — pokazywane w kalendarzu jako pomarańczowe.
  final List<String> confirmationSlots;

  // ── Dodatkowe detale (widoczne na stronie usługodawcy) ──
  final String? description;
  final String? phone;
  final String? website;
  /// Godziny otwarcia, np. {'Pon–Pt': '9:00–18:00', 'Sob': '10:00–15:00'}
  final Map<String, String> openingHours;

  /// Pracownicy dostępni na dany slot.
  /// Klucz = godzina slotu (np. '09:00'), wartość = lista imion/nazw
  /// (np. ['Krysia', 'Basia', 'Bogdan']).
  /// Pusta lista lub brak klucza = slot ogólny (bez wyboru pracownika).
  final Map<String, List<String>> slotStaff;

  /// Małe zdjęcie awatara (np. portret, logo) — używane w listach i kartach.
  final String? avatarImageUrl;

  /// Duże zdjęcie hero (np. wnętrze salonu) — używane w nagłówku ekranu detali.
  final String? heroImageUrl;

  ServiceProvider({
    required this.id,
    required this.name,
    required this.serviceType,
    required this.address,
    required this.lat,
    required this.lng,
    required this.slots,
    this.slotDurationMinutes = 60,
    this.isSubscribed = false,
    this.rating,
    this.placeId,
    this.confirmationSlots = const [],
    this.description,
    this.phone,
    this.website,
    this.openingHours = const {},
    this.slotStaff = const {},
    this.avatarImageUrl,
    this.heroImageUrl,
  });
}
