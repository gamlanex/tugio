import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/booking.dart';
import '../models/provider.dart';
import '../utils/date_helpers.dart';
import '../utils/provider_avatar.dart';

/// Bottom sheet ze szczegółami rezerwacji.
/// [provider] = null oznacza event zaimportowany z Google Calendar.
/// [onCancel] = null oznacza że nie można odwołać (np. import).
class BookingDetailSheet extends StatelessWidget {
  final Booking booking;
  final ServiceProvider? provider;
  final VoidCallback? onCancel;

  const BookingDetailSheet({
    super.key,
    required this.booking,
    this.provider,
    this.onCancel,
  });

  Future<void> _openMaps(ServiceProvider p) async {
    final uri = Uri.parse('https://maps.google.com/?q=${p.lat},${p.lng}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _callPhone(ServiceProvider p) async {
    if (p.phone == null) return;
    final uri = Uri.parse('tel:${p.phone}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).padding.bottom;
    final isImported = provider == null;

    // Kolor statusu
    final statusColor = booking.status == BookingStatus.booked
        ? Colors.green
        : booking.status == BookingStatus.pending ||
                booking.status == BookingStatus.inquiry
            ? Colors.orange
            : Colors.grey;
    final statusLabel = booking.status == BookingStatus.booked
        ? 'Potwierdzona'
        : booking.status == BookingStatus.pending
            ? 'Oczekuje na potwierdzenie'
            : booking.status == BookingStatus.inquiry
                ? 'Zapytanie'
                : 'Nieznany';

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Uchwyt
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Nagłówek: dostawca lub kalendarz ─────────────────
          Row(
            children: [
              if (provider != null)
                ProviderAvatar(serviceType: provider!.serviceType, radius: 24)
              else
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.indigo.withOpacity(0.1),
                  child: Icon(Icons.event_rounded,
                      color: Colors.indigo.shade400, size: 26),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider?.name ?? 'Google Calendar',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    if (provider != null)
                      Text(
                        provider!.serviceType,
                        style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurface.withOpacity(0.55)),
                      ),
                  ],
                ),
              ),
              // Badge statusu
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: statusColor.withOpacity(0.4), width: 1),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Usługa i pracownik ────────────────────────────────
          Text(
            booking.service,
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          if (booking.staffName != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.person_rounded,
                    size: 15, color: Colors.teal.shade600),
                const SizedBox(width: 6),
                Text(
                  booking.staffName!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade700,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),

          // ── Data i godzina ────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(0.35),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  formatDate(booking.start),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time_rounded,
                    size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  booking.timeText,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // ── Adres ─────────────────────────────────────────────
          if (provider != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 15, color: cs.onSurface.withOpacity(0.5)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    provider!.address,
                    style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withOpacity(0.6)),
                  ),
                ),
              ],
            ),
          ],

          // ── Import info ───────────────────────────────────────
          if (isImported) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.amber.withOpacity(0.4), width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: Colors.amber.shade800),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Event z Google Calendar — edytuj go bezpośrednio w kalendarzu.',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── Przyciski akcji ───────────────────────────────────
          if (provider != null) ...[
            Row(
              children: [
                if (provider!.phone != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _callPhone(provider!),
                      icon: const Icon(Icons.phone_rounded, size: 18),
                      label: const Text('Zadzwoń'),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                if (provider!.phone != null) const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openMaps(provider!),
                    icon: const Icon(Icons.map_rounded, size: 18),
                    label: const Text('Mapa'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // ── Odwołaj / Zamknij ─────────────────────────────────
          if (onCancel != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.cancel_outlined,
                    size: 18, color: Colors.red),
                label: const Text('Odwołaj rezerwację',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: BorderSide(
                      color: Colors.red.withOpacity(0.5), width: 1.2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Zamknij'),
              ),
            ),
        ],
      ),
    );
  }
}
