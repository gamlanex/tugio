import 'package:flutter/material.dart';

class Service {
  final String name;
  final IconData icon;
  final List<String> slots;
  final String description;

  Service({
    required this.name,
    required this.icon,
    required this.slots,
    required this.description,
  });
}