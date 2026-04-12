/// Opcja usługi prezentowana podczas tworzenia rezerwacji.
class ServiceOption {
  final String name;
  final String description;
  final int price;
  final int durationMinutes;

  /// true = usługa wymaga potwierdzenia ze strony właściciela
  final bool requiresConfirmation;

  const ServiceOption(
    this.name,
    this.description,
    this.price,
    this.durationMinutes, {
    this.requiresConfirmation = false,
  });
}
