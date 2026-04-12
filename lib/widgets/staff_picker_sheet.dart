import 'package:flutter/material.dart';

/// Bottom sheet do wyboru pracownika dla danego slotu.
/// Zwraca wybrany String (imię) lub null jeśli użytkownik zamknie.
class StaffPickerSheet extends StatelessWidget {
  final List<String> staffList;
  final String time;
  final String providerName;

  const StaffPickerSheet({
    super.key,
    required this.staffList,
    required this.time,
    required this.providerName,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).padding.bottom;
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // Maksymalnie 75% ekranu — reszta scrolluje
      constraints: BoxConstraints(maxHeight: screenH * 0.75),
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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

          // Tytuł
          Text(
            'Wybierz osobę — $time',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          Text(
            providerName,
            style:
                TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.55)),
          ),
          const SizedBox(height: 16),

          // Lista pracowników — scrollowana jeśli za długa
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: staffList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              padding: EdgeInsets.only(bottom: 12 + bottom),
              itemBuilder: (_, i) {
                final name = staffList[i];
                return InkWell(
                  onTap: () => Navigator.pop(context, name),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 8,
                          color: Colors.black.withOpacity(0.04),
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.teal.withOpacity(0.12),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.teal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          name,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right_rounded,
                            color: cs.onSurface.withOpacity(0.35)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
