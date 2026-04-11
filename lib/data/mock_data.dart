import 'package:flutter/material.dart';
import '../models/service.dart';
import '../models/booking.dart';
import '../models/provider.dart';

final List<Service> initialServices = [
  Service(
    name: 'Fryzjer 1',
    icon: Icons.content_cut,
    description: 'Strzyżenie, modelowanie i szybkie wizyty kontrolne.',
//    slots: ['09:00', '10:00', '11:30', '13:00', '15:00', '17:00'],
    slots: [
      '07:00', '08:00', '09:00', '10:00', '10:30',
      '11:00', '11:30', '12:00', '13:00', '13:30',
      '14:00', '15:00', '16:00', '17:00', '18:00',
    ],
  ),
  Service(
    name: 'Fryzjer 2',
    icon: Icons.face_retouching_natural,
    description: 'Koloryzacja, pielęgnacja i stylizacja włosów.',
    slots: ['08:30', '10:30', '12:00', '14:30', '16:30'],
  ),
  Service(
    name: 'Psycholog',
    icon: Icons.psychology,
    description: 'Konsultacje indywidualne i spotkania terapeutyczne.',
    slots: ['09:00', '10:30', '12:30', '15:00', '18:00'],
  ),
  Service(
    name: 'Trening',
    icon: Icons.fitness_center,
    description: 'Trening personalny, plan ćwiczeń i analiza postępów.',
    slots: ['07:00', '08:00', '17:00', '18:00', '19:00'],
  ),
];

// ─── mock service providers (subscribed) ────────────────────────────────────
final List<ServiceProvider> mockProviders = [
  ServiceProvider(
    id: 'provider_1',
    name: 'Fryzjer Jan Kowalski',
    serviceType: 'Fryzjer',
    address: 'ul. Marszałkowska 10, Warszawa',
    lat: 52.2297,
    lng: 21.0122,
    // natychmiastowe (niebieskie)
    slots: ['09:00', '10:00', '13:00', '17:00'],
    // wymagające potwierdzenia (pomarańczowe) — koloryzacja, modelowanie
    confirmationSlots: ['11:30', '15:00'],
    isSubscribed: true,
    rating: 4.8,
  ),
  ServiceProvider(
    id: 'provider_2',
    name: 'Salon Urody Anna',
    serviceType: 'Fryzjer',
    address: 'ul. Nowy Świat 25, Warszawa',
    lat: 52.2318,
    lng: 21.0213,
    slots: ['08:30', '12:00', '16:30'],
    confirmationSlots: ['10:30', '14:30'],
    isSubscribed: true,
    rating: 4.5,
  ),
  ServiceProvider(
    id: 'provider_3',
    name: 'Gabinet Psychologiczny dr. Nowak',
    serviceType: 'Psycholog',
    address: 'ul. Puławska 50, Warszawa',
    lat: 52.2056,
    lng: 21.0084,
    // sesje terapeutyczne — natychmiastowe
    slots: ['12:30', '15:00'],
    // konsultacje i terapia par — wymagają potwierdzenia
    confirmationSlots: ['09:00', '10:30', '18:00'],
    isSubscribed: true,
    rating: 4.9,
  ),
  ServiceProvider(
    id: 'provider_4',
    name: 'FitZone Personal Training',
    serviceType: 'Trener personalny',
    address: 'ul. Długa 3, Warszawa',
    lat: 52.2460,
    lng: 21.0132,
    slots: ['07:00', '17:00', '19:00'],
    confirmationSlots: ['08:00', '18:00'],
    isSubscribed: true,
    rating: 4.7,
  ),
];

List<Booking> initialBookings(DateTime today) {
  return [
    Booking(
      id: 'local_b1',
      service: 'Dentysta',
      start: DateTime(today.year, today.month, today.day, 12, 0),
      durationMinutes: 60,
      status: BookingStatus.booked,
    ),
    Booking(
      id: 'local_b2',
      service: 'Spotkanie',
      start: DateTime(today.year, today.month, today.day, 15, 30),
      durationMinutes: 30,
      status: BookingStatus.inquiry,
    ),
    Booking(
      id: 'local_b3',
      service: 'Psycholog',
      start: DateTime(today.year, today.month, today.day + 1, 10, 30),
      durationMinutes: 60,
      status: BookingStatus.booked,
    ),
  ];
}