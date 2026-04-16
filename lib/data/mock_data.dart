import 'package:flutter/material.dart';
import '../models/service.dart';
import '../models/booking.dart';
import '../models/provider.dart';
import '../services/language_service.dart';

String _t({required String pl, required String en}) =>
    LanguageService.instance.text(pl: pl, en: en);

List<Service> get initialServices => [
  Service(
    name: _t(pl: 'Fryzjer 1', en: 'Hairdresser 1'),
    icon: Icons.content_cut,
    description: _t(
      pl: 'Strzyżenie, modelowanie i szybkie wizyty kontrolne.',
      en: 'Haircuts, styling, and quick follow-up visits.',
    ),
    slots: [
      '07:00', '08:00', '09:00', '10:00', '10:30',
      '11:00', '11:30', '12:00', '13:00', '13:30',
      '14:00', '15:00', '16:00', '17:00', '18:00',
    ],
  ),
  Service(
    name: _t(pl: 'Fryzjer 2', en: 'Hairdresser 2'),
    icon: Icons.face_retouching_natural,
    description: _t(
      pl: 'Koloryzacja, pielęgnacja i stylizacja włosów.',
      en: 'Hair coloring, care, and styling.',
    ),
    slots: ['08:30', '10:30', '12:00', '14:30', '16:30'],
  ),
  Service(
    name: _t(pl: 'Psycholog', en: 'Psychologist'),
    icon: Icons.psychology,
    description: _t(
      pl: 'Konsultacje indywidualne i spotkania terapeutyczne.',
      en: 'Individual consultations and therapy sessions.',
    ),
    slots: ['09:00', '10:30', '12:30', '15:00', '18:00'],
  ),
  Service(
    name: _t(pl: 'Trening', en: 'Training'),
    icon: Icons.fitness_center,
    description: _t(
      pl: 'Trening personalny, plan ćwiczeń i analiza postępów.',
      en: 'Personal training, workout plans, and progress analysis.',
    ),
    slots: ['07:00', '08:00', '17:00', '18:00', '19:00'],
  ),
];

List<ServiceProvider> get mockProviders => [
  ServiceProvider(
    id: 'provider_1',
    name: _t(pl: 'Fryzjer Jan Kowalski', en: 'Jan Kowalski Hair Studio'),
    serviceType: 'Fryzjer',
    address: _t(
      pl: 'ul. Marszałkowska 10, Warszawa',
      en: 'Marszalkowska St 10, Warsaw',
    ),
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
    description: _t(
      pl: "Doświadczony fryzjer z ponad 15-letnim stażem. Specjalizuje się w nowoczesnych cięciach, koloryzacji i stylizacji. Pracuje z najlepszymi produktami Wella i L'Oréal Professional. Zapraszam do swojego klimatycznego zakładu w centrum Warszawy.",
      en: "Experienced hairdresser with over 15 years in the industry. Specializes in modern cuts, coloring, and styling. Works with premium Wella and L'Oréal Professional products in a cozy studio in central Warsaw.",
    ),
    phone: '+48 601 234 567',
    website: 'fryzjer-kowalski.pl',
    openingHours: {
      _t(pl: 'Pon-Pt', en: 'Mon-Fri'): '9:00-19:00',
      _t(pl: 'Sobota', en: 'Saturday'): '9:00-15:00',
      _t(pl: 'Niedziela', en: 'Sunday'): _t(pl: 'Nieczynne', en: 'Closed'),
    },
    avatarImageUrl: 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=200&h=200&fit=crop',
    heroImageUrl: 'https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?w=800&h=400&fit=crop',
  ),
  ServiceProvider(
    id: 'provider_2',
    name: _t(pl: 'Salon Urody Anna', en: 'Anna Beauty Salon'),
    serviceType: 'Fryzjer',
    address: _t(
      pl: 'ul. Nowy Świat 25, Warszawa',
      en: 'Nowy Swiat St 25, Warsaw',
    ),
    lat: 52.2318,
    lng: 21.0213,
    slots: ['08:30', '12:00', '16:30'],
    confirmationSlots: ['10:30', '14:30'],
    isSubscribed: true,
    rating: 4.5,
    description: _t(
      pl: 'Elegancki salon urody w sercu Nowego Światu. Oferujemy pełen zakres usług fryzjerskich i kosmetycznych. Nasz zespół to certyfikowani specjaliści regularnie podnoszący kwalifikacje na międzynarodowych szkoleniach.',
      en: 'Elegant beauty salon in the heart of Nowy Swiat. We offer a full range of hair and beauty services. Our certified specialists regularly improve their skills through international training.',
    ),
    phone: '+48 22 555 0001',
    website: 'salon-anna.pl',
    openingHours: {
      _t(pl: 'Pon-Pt', en: 'Mon-Fri'): '8:00-20:00',
      _t(pl: 'Sobota', en: 'Saturday'): '9:00-17:00',
      _t(pl: 'Niedziela', en: 'Sunday'): _t(pl: 'Nieczynne', en: 'Closed'),
    },
    avatarImageUrl: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=200&h=200&fit=crop',
    heroImageUrl: 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=800&h=400&fit=crop',
  ),
  ServiceProvider(
    id: 'provider_3',
    name: _t(pl: 'Gabinet Psychologiczny dr. Nowak', en: 'Dr Nowak Psychology Office'),
    serviceType: 'Psycholog',
    address: _t(
      pl: 'ul. Puławska 50, Warszawa',
      en: 'Pulawska St 50, Warsaw',
    ),
    lat: 52.2056,
    lng: 21.0084,
    slots: ['12:30', '15:00'],
    confirmationSlots: ['09:00', '10:30', '18:00'],
    isSubscribed: true,
    rating: 4.9,
    description: _t(
      pl: 'Dr Anna Nowak - psycholog kliniczny z 12-letnim doświadczeniem. Specjalizacja: terapia poznawczo-behawioralna, terapia par, wsparcie w kryzysie. Przyjmuję dorosłych i młodzież. Gabinet przystosowany dla osób z niepełnosprawnością ruchową.',
      en: 'Dr Anna Nowak is a clinical psychologist with 12 years of experience. Specializes in cognitive behavioral therapy, couples therapy, and crisis support. Works with adults and teenagers. The office is accessible for people with reduced mobility.',
    ),
    phone: '+48 789 456 123',
    openingHours: {
      _t(pl: 'Pon, Śr, Pt', en: 'Mon, Wed, Fri'): '9:00-18:00',
      _t(pl: 'Wt, Czw', en: 'Tue, Thu'): '12:00-20:00',
      _t(pl: 'Sobota', en: 'Saturday'): _t(pl: 'Na życzenie', en: 'On request'),
    },
    avatarImageUrl: 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=200&h=200&fit=crop',
    heroImageUrl: 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=800&h=400&fit=crop',
  ),
  ServiceProvider(
    id: 'provider_4',
    name: 'FitZone Personal Training',
    serviceType: 'Trener personalny',
    address: _t(
      pl: 'ul. Długa 3, Warszawa',
      en: 'Dluga St 3, Warsaw',
    ),
    lat: 52.2460,
    lng: 21.0132,
    slots: ['07:00', '17:00', '19:00'],
    confirmationSlots: ['08:00', '18:00'],
    slotStaff: {
      '07:00': [_t(pl: 'Kort 2', en: 'Court 2')],
      '08:00': [_t(pl: 'Kort 1', en: 'Court 1'), _t(pl: 'Kort 3', en: 'Court 3')],
      '17:00': [_t(pl: 'Kort 1', en: 'Court 1'), _t(pl: 'Kort 2', en: 'Court 2'), _t(pl: 'Kort 3', en: 'Court 3')],
      '18:00': [_t(pl: 'Kort 1', en: 'Court 1')],
      '19:00': [_t(pl: 'Kort 2', en: 'Court 2'), _t(pl: 'Kort 3', en: 'Court 3')],
    },
    isSubscribed: true,
    rating: 4.7,
    description: _t(
      pl: 'Certyfikowany trener personalny i dietetyk sportowy. Pracuję z klientami na wszystkich poziomach zaawansowania - od osób zaczynających przygodę z fitnessem po sportowców wyczynowych. Treningi prowadzone w nowoczesnym centrum FitZone lub dojazd do klienta.',
      en: "Certified personal trainer and sports dietitian. Works with clients at every level, from beginners to competitive athletes. Sessions take place at the modern FitZone center or at the client's location.",
    ),
    phone: '+48 512 789 000',
    website: 'fitzone.pl',
    openingHours: {
      _t(pl: 'Pon-Pt', en: 'Mon-Fri'): '6:00-21:00',
      _t(pl: 'Sob-Ndz', en: 'Sat-Sun'): '8:00-16:00',
    },
    avatarImageUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=200&h=200&fit=crop',
    heroImageUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&h=400&fit=crop',
  ),
];

List<Booking> initialBookings(DateTime today) {
  return [
    Booking(
      id: 'local_b1',
      service: _t(pl: 'Dentysta', en: 'Dentist'),
      start: DateTime(today.year, today.month, today.day, 12, 0),
      durationMinutes: 60,
      status: BookingStatus.booked,
    ),
    Booking(
      id: 'local_b2',
      service: _t(pl: 'Spotkanie', en: 'Meeting'),
      start: DateTime(today.year, today.month, today.day, 15, 30),
      durationMinutes: 30,
      status: BookingStatus.inquiry,
    ),
    Booking(
      id: 'local_b3',
      service: _t(pl: 'Psycholog', en: 'Psychologist'),
      start: DateTime(today.year, today.month, today.day + 1, 10, 30),
      durationMinutes: 60,
      status: BookingStatus.booked,
    ),
  ];
}
