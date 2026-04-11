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
  });
}
