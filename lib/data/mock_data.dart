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
    slots: ['09:00', '10:00', '13:00', '17:00'],
    confirmationSlots: ['11:30', '15:00'],
    slotStaff: {
      '09:00': ['Krysia', 'Basia', 'Bogdan'],
      '10:00': ['Basia', 'Bogdan'],
      '11:30': ['Krysia'],
      '13:00': ['Marek', 'Krysia'],
      '15:00': ['Basia'],
      '17:00': ['Krysia', 'Marek', 'Basia', 'Bogdan'],
    },
    isSubscribed: true,
    rating: 4.8,
    description:
        'Doświadczony fryzjer z ponad 15-letnim stażem. Specjalizuje się w nowoczesnych cięciach, koloryzacji i stylizacji. Pracuje z najlepszymi produktami Wella i L\'Oréal Professional. Zapraszam do swojego klimatycznego zakładu w centrum Warszawy.',
    phone: '+48 601 234 567',
    website: 'fryzjer-kowalski.pl',
    openingHours: {
      'Pon–Pt': '9:00–19:00',
      'Sobota': '9:00–15:00',
      'Niedziela': 'Nieczynne',
    },
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
    description:
        'Elegancki salon urody w sercu Nowego Światu. Oferujemy pełen zakres usług fryzjerskich i kosmetycznych. Nasz zespół to certyfikowani specjaliści regularnie podnoszący kwalifikacje na międzynarodowych szkoleniach.',
    phone: '+48 22 555 0001',
    website: 'salon-anna.pl',
    openingHours: {
      'Pon–Pt': '8:00–20:00',
      'Sobota': '9:00–17:00',
      'Niedziela': 'Nieczynne',
    },
  ),
  ServiceProvider(
    id: 'provider_3',
    name: 'Gabinet Psychologiczny dr. Nowak',
    serviceType: 'Psycholog',
    address: 'ul. Puławska 50, Warszawa',
    lat: 52.2056,
    lng: 21.0084,
    slots: ['12:30', '15:00'],
    confirmationSlots: ['09:00', '10:30', '18:00'],
    isSubscribed: true,
    rating: 4.9,
    description:
        'Dr Anna Nowak — psycholog kliniczny z 12-letnim doświadczeniem. Specjalizacja: terapia poznawczo-behawioralna, terapia par, wsparcie w kryzysie. Przyjmuję dorosłych i młodzież. Gabinet przystosowany dla osób z niepełnosprawnością ruchową.',
    phone: '+48 789 456 123',
    openingHours: {
      'Pon, Śr, Pt': '9:00–18:00',
      'Wt, Czw': '12:00–20:00',
      'Sobota': 'Na życzenie',
    },
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
    slotStaff: {
      '07:00': ['Kort 2'],
      '08:00': ['Kort 1', 'Kort 3'],
      '17:00': ['Kort 1', 'Kort 2', 'Kort 3'],
      '18:00': ['Kort 1'],
      '19:00': ['Kort 2', 'Kort 3'],
    },
    isSubscribed: true,
    rating: 4.7,
    description:
        'Certyfikowany trener personalny i dietetyk sportowy. Pracuję z klientami na wszystkich poziomach zaawansowania — od osób zaczynających przygodę z fitnessem po sportowców wyczynowych. Treningi prowadzone w nowoczesnym centrum FitZone lub dojazd do klienta.',
    phone: '+48 512 789 000',
    website: 'fitzone.pl',
    openingHours: {
      'Pon–Pt': '6:00–21:00',
      'Sob–Ndz': '8:00–16:00',
    },
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