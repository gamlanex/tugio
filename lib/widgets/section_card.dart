import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;

  const SectionCard({
    super.key,
    this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: title != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                child,
              ],
            )
          : child,
    );
  }
}

class ScrollableSection extends StatelessWidget {
  final String title;
  final Widget child;

  const ScrollableSection({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(child: child),
          ),
        ],
      ),
    );
  }
}