import 'package:flutter/material.dart';
import '../models/service.dart';

class ServicesCarousel extends StatelessWidget {
  final List<Service> services;
  final Service selectedService;
  final PageController pageController;
  final void Function(Service service) onServiceChanged;

  const ServicesCarousel({
    super.key,
    required this.services,
    required this.selectedService,
    required this.pageController,
    required this.onServiceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 210,
          child: PageView.builder(
            controller: pageController,
            itemCount: services.length,
            onPageChanged: (index) => onServiceChanged(services[index]),
            itemBuilder: (context, index) {
              final service = services[index];
              final selected = service == selectedService;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(16),
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.indigo.withOpacity(0.08)
                      : const Color(0xFFF4F5F9),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected ? Colors.indigo : Colors.transparent,
                    width: 1.4,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(service.icon, size: 42, color: Colors.indigo),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      service.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: Text(
                      service.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.25,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(services.length, (index) {
            final isActive = services[index] == selectedService;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? Colors.indigo : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }
}