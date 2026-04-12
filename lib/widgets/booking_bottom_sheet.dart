import 'package:flutter/material.dart';
import '../models/provider.dart';
import '../models/service_option.dart';
import '../utils/date_helpers.dart';
import '../utils/provider_avatar.dart';

/// Bottom sheet rezerwacji — duży, prawie pełnoekranowy.
/// Zwraca wybraną [ServiceOption] lub null jeśli użytkownik anuluje.
class BookingBottomSheet extends StatefulWidget {
  final ServiceProvider provider;
  final String time;
  final DateTime day;
  final String? staffName;

  const BookingBottomSheet({
    super.key,
    required this.provider,
    required this.time,
    required this.day,
    this.staffName,
  });

  @override
  State<BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<BookingBottomSheet> {
  int _selectedServiceIndex = 0;

  // Mock usługi dla danego usługodawcy z opisami i cenami.
  // TODO: zamienić na wywołanie API GET /providers/{id}/services
  List<ServiceOption> get _services {
    switch (widget.provider.serviceType) {
      case 'Fryzjer':
        return [
          const ServiceOption('Strzyżenie damskie',
              'Mycie, strzyżenie i stylizacja włosów.', 120, 60),
          const ServiceOption('Strzyżenie męskie',
              'Klasyczne lub nowoczesne strzyżenie.', 70, 30),
          const ServiceOption(
              'Koloryzacja',
              'Pełna koloryzacja lub odrosty z pielęgnacją.',
              250,
              120,
              requiresConfirmation: true),
          const ServiceOption('Modelowanie',
              'Blow-dry, fale lub prostowanie.', 90, 45,
              requiresConfirmation: true),
        ];
      case 'Psycholog':
        return [
          const ServiceOption(
              'Konsultacja indywidualna',
              'Pierwsza wizyta, diagnoza i omówienie celów terapii.',
              200,
              60,
              requiresConfirmation: true),
          const ServiceOption('Sesja terapeutyczna',
              'Regularna sesja terapii indywidualnej.', 180, 50),
          const ServiceOption('Terapia par',
              'Sesja dla par — komunikacja i relacje.', 300, 90,
              requiresConfirmation: true),
        ];
      case 'Trener personalny':
        return [
          const ServiceOption(
              'Trening personalny',
              'Indywidualny plan ćwiczeń dostosowany do Twoich celów.',
              150,
              60),
          const ServiceOption('Analiza postawy',
              'Ocena biomechaniki i korygowanie wad postawy.', 120, 45,
              requiresConfirmation: true),
          const ServiceOption('Konsultacja dietetyczna',
              'Plan żywieniowy wspierający Twój trening.', 100, 40),
        ];
      default:
        return [
          ServiceOption('Wizyta standardowa',
              'Standardowa wizyta u ${widget.provider.name}.', 150, 60),
          const ServiceOption('Wizyta pilna',
              'Szybka konsultacja w trybie pilnym.', 200, 30,
              requiresConfirmation: true),
        ];
    }
  }

  String _addMinutes(String time, int minutes) {
    final parts = time.split(':');
    final dt = DateTime(0, 0, 0, int.parse(parts[0]), int.parse(parts[1]));
    final end = dt.add(Duration(minutes: minutes));
    return '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final services = _services;
    final selected = services[_selectedServiceIndex];
    final endTime = _addMinutes(widget.time, selected.durationMinutes);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── uchwyt ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // ── treść scrollowana ────────────────────────────
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    // Nagłówek — usługodawca
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 12,
                            color: Colors.black.withOpacity(0.05),
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ProviderAvatar(
                            serviceType: widget.provider.serviceType,
                            radius: 26,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.provider.name,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 3),
                                Text(widget.provider.serviceType,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600)),
                                if (widget.provider.rating != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.star_rounded,
                                          color: Colors.amber.shade600,
                                          size: 15),
                                      const SizedBox(width: 3),
                                      Text(
                                        widget.provider.rating!
                                            .toStringAsFixed(1),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Termin
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.indigo.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              color: Colors.indigo, size: 18),
                          const SizedBox(width: 10),
                          Text(formatDate(widget.day),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 20),
                          const Icon(Icons.access_time_rounded,
                              color: Colors.indigo, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.time} – $endTime',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Wybrany pracownik (jeśli dotyczy)
                    if (widget.staffName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.teal.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_rounded,
                                color: Colors.teal, size: 18),
                            const SizedBox(width: 10),
                            Text(widget.staffName!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.teal)),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Nagłówek sekcji usług
                    const Text('Wybierz usługę',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),

                    // Lista usług
                    ...services.asMap().entries.map((entry) {
                      final i = entry.key;
                      final svc = entry.value;
                      final isSelected = i == _selectedServiceIndex;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedServiceIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.indigo.withOpacity(0.07)
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  isSelected ? Colors.indigo : Colors.black12,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Radio indicator
                              Container(
                                width: 20,
                                height: 20,
                                margin: const EdgeInsets.only(top: 1),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.indigo
                                        : Colors.black26,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? Center(
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.indigo,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(svc.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                color: isSelected
                                                    ? Colors.indigo.shade800
                                                    : Colors.black87,
                                              )),
                                        ),
                                        Text(
                                          '${svc.price} zł',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            color: isSelected
                                                ? Colors.indigo
                                                : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(svc.description,
                                        style: TextStyle(
                                            fontSize: 12.5,
                                            color: Colors.grey.shade600,
                                            height: 1.4)),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.timer_outlined,
                                            size: 13,
                                            color: Colors.grey.shade500),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${svc.durationMinutes} min',
                                          style: TextStyle(
                                              fontSize: 11.5,
                                              color: Colors.grey.shade500),
                                        ),
                                        const SizedBox(width: 10),
                                        // Badge: natychmiastowa / wymaga potwierdzenia
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: svc.requiresConfirmation
                                                ? Colors.orange
                                                    .withOpacity(0.12)
                                                : Colors.green
                                                    .withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                svc.requiresConfirmation
                                                    ? Icons
                                                        .hourglass_top_rounded
                                                    : Icons.bolt_rounded,
                                                size: 11,
                                                color: svc.requiresConfirmation
                                                    ? Colors.orange.shade700
                                                    : Colors.green.shade700,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                svc.requiresConfirmation
                                                    ? 'Wymaga potwierdzenia'
                                                    : 'Natychmiastowa',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: svc
                                                          .requiresConfirmation
                                                      ? Colors.orange.shade700
                                                      : Colors.green.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),

                    // Adres
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 15, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(widget.provider.address,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 80), // miejsce na przycisk
                  ],
                ),
              ),

              // ── przyciski (przyklejone na dole) ─────────────
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  16 +
                      MediaQuery.of(context).viewInsets.bottom +
                      MediaQuery.of(context).padding.bottom,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 16,
                      color: Colors.black.withOpacity(0.07),
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Podsumowanie ceny
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(selected.name,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black54),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              Text('${selected.price} zł',
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.indigo)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.timer_outlined,
                                size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text('${selected.durationMinutes} min',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Przyciski
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Colors.black26),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => Navigator.pop(ctx, null),
                            child: const Text('Anuluj',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: selected.requiresConfirmation
                                  ? Colors.orange.shade700
                                  : Colors.indigo,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => Navigator.pop(ctx, selected),
                            icon: Icon(
                              selected.requiresConfirmation
                                  ? Icons.send_rounded
                                  : Icons.check_rounded,
                              size: 18,
                            ),
                            label: Text(
                              selected.requiresConfirmation
                                  ? 'Wyślij prośbę'
                                  : 'Zarezerwuj',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
