import '../config/app_config.dart';
import '../models/service_type.dart';
import 'service_type_repository.dart';

/// Mockowe typy usług — URL-e ikon wskazują na lokalny serwer Mockoon.
/// Format: {apiBaseUrl}/icons/{id}.svg
class MockServiceTypeRepository implements ServiceTypeRepository {
  static String _icon(String id) => '${AppConfig.apiBaseUrl}/icons/$id.svg';

  static List<ServiceType> get _items => [
    ServiceType(id: 'haircut',          name: 'Fryzjer',            iconUrl: _icon('haircut'),          colorHex: '#9C27B0'),
    ServiceType(id: 'psychology',       name: 'Psycholog',           iconUrl: _icon('psychology'),       colorHex: '#009688'),
    ServiceType(id: 'personal_trainer', name: 'Trener personalny',   iconUrl: _icon('personal_trainer'), colorHex: '#FF9800'),
    ServiceType(id: 'dentist',          name: 'Dentysta',            iconUrl: _icon('dentist'),          colorHex: '#2196F3'),
    ServiceType(id: 'cosmetician',      name: 'Kosmetyczka',         iconUrl: _icon('cosmetician'),      colorHex: '#E91E63'),
    ServiceType(id: 'doctor',           name: 'Lekarz',              iconUrl: _icon('doctor'),           colorHex: '#F44336'),
    ServiceType(id: 'physio',           name: 'Fizjoterapeuta',      iconUrl: _icon('physio'),           colorHex: '#4CAF50'),
    ServiceType(id: 'dietitian',        name: 'Dietetyk',            iconUrl: _icon('dietitian'),        colorHex: '#FFC107'),
    ServiceType(id: 'massage',          name: 'Masaż',               iconUrl: _icon('massage'),          colorHex: '#3F51B5'),
    ServiceType(id: 'cardiologist',     name: 'Kardiolog',           iconUrl: _icon('cardiologist'),     colorHex: '#E53935'),
    ServiceType(id: 'pediatrician',     name: 'Pediatra',            iconUrl: _icon('pediatrician'),     colorHex: '#42A5F5'),
    ServiceType(id: 'vet',              name: 'Weterynarz',          iconUrl: _icon('vet'),              colorHex: '#66BB6A'),
    ServiceType(id: 'tutor',            name: 'Korepetycje',         iconUrl: _icon('tutor'),            colorHex: '#AB47BC'),
    ServiceType(id: 'mechanic',         name: 'Mechanik',            iconUrl: _icon('mechanic'),         colorHex: '#78909C'),
    ServiceType(id: 'cleaning',         name: 'Sprzątanie',          iconUrl: _icon('cleaning'),         colorHex: '#26C6DA'),
    ServiceType(id: 'plumber',          name: 'Hydraulik',           iconUrl: _icon('plumber'),          colorHex: '#8D6E63'),
    ServiceType(id: 'photographer',     name: 'Fotograf',            iconUrl: _icon('photographer'),     colorHex: '#EC407A'),
    ServiceType(id: 'it_support',       name: 'Wsparcie IT',         iconUrl: _icon('it_support'),       colorHex: '#5C6BC0'),
    ServiceType(id: 'lawyer',           name: 'Prawnik',             iconUrl: _icon('lawyer'),           colorHex: '#546E7A'),
    ServiceType(id: 'accountant',       name: 'Księgowy',            iconUrl: _icon('accountant'),       colorHex: '#26A69A'),
  ];

  @override
  Future<List<ServiceType>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [..._items, ServiceType.other];
  }
}
