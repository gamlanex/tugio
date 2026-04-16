// ─────────────────────────────────────────────────────────────────────────────
// SfProviderRepository — usługodawcy z Salesforce
//
// Salesforce object: Provider__c (custom object)
// Pola do skonfigurowania w SF:
//   Id                  → provider.id
//   Name                → provider.name
//   Service_Type__c     → provider.serviceType    (Text/Picklist)
//   Address__c          → provider.address        (Text)
//   Latitude__c         → provider.lat            (Number)
//   Longitude__c        → provider.lng            (Number)
//   Rating__c           → provider.rating         (Number)
//   Description__c      → provider.description    (Long Text)
//   Phone__c            → provider.phone          (Phone)
//   Website__c          → provider.website        (URL)
//   Avatar_Image_Url__c → provider.avatarImageUrl (URL)
//   Hero_Image_Url__c   → provider.heroImageUrl   (URL)
//   Is_Subscribed__c    → provider.isSubscribed   (Checkbox)
//
// UWAGA: Jeśli w Salesforce masz inne nazwy pól, zmień mapowanie
//        w metodach _fromSf() i _toSf() na dole pliku.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import '../config/app_config.dart';
import '../models/provider.dart';
import '../services/language_service.dart';
import '../services/salesforce_auth_service.dart';
import 'provider_repository.dart';

class SfProviderRepository implements ProviderRepository {
  final _sf = SalesforceAuthService.instance;
  final String _object = 'Provider__c';

  static const String _fields =
      'Id, Name, Service_Type__c, Address__c, '
      'Latitude__c, Longitude__c, Rating__c, Description__c, '
      'Phone__c, Website__c, Avatar_Image_Url__c, Hero_Image_Url__c, '
      'Is_Subscribed__c';

  @override
  Future<List<ServiceProvider>> getSubscribed() async {
    final query = Uri.encodeComponent(
      "SELECT $_fields FROM $_object "
      "WHERE Is_Subscribed__c = true "
      "ORDER BY Name ASC "
      "LIMIT 100",
    );

    final uri = Uri.parse('${AppConfig.sfApiBase}/query?q=$query');
    final response = await _sf.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
          'SF GET providers failed (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final records = data['records'] as List<dynamic>? ?? [];
    return records.map((r) => _fromSf(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> subscribe(ServiceProvider provider) async {
    final uri = Uri.parse(
        '${AppConfig.sfApiBase}/sobjects/$_object/${provider.id}');
    final response = await _sf.patch(uri, body: {'Is_Subscribed__c': true});

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
          'SF subscribe failed (${response.statusCode}): ${response.body}');
    }
  }

  @override
  Future<void> unsubscribe(String providerId) async {
    final uri = Uri.parse(
        '${AppConfig.sfApiBase}/sobjects/$_object/$providerId');
    final response = await _sf.patch(uri, body: {'Is_Subscribed__c': false});

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
          'SF unsubscribe failed (${response.statusCode}): ${response.body}');
    }
  }

  // ─── Mapowanie SF → model ─────────────────────────────────────────────────

  ServiceProvider _fromSf(Map<String, dynamic> r) {
    return ServiceProvider(
      id:             r['Id'] as String,
      name:           r['Name'] as String? ?? LanguageService.instance.text(pl: '(brak nazwy)', en: '(no name)'),
      serviceType:    r['Service_Type__c'] as String? ?? LanguageService.instance.text(pl: 'Inne', en: 'Other'),
      address:        r['Address__c'] as String? ?? '',
      lat:            (r['Latitude__c'] as num?)?.toDouble() ?? 0.0,
      lng:            (r['Longitude__c'] as num?)?.toDouble() ?? 0.0,
      slots:          const [],   // sloty nie są przechowywane w SF — pobierane osobno
      rating:         (r['Rating__c'] as num?)?.toDouble(),
      description:    r['Description__c'] as String?,
      phone:          r['Phone__c'] as String?,
      website:        r['Website__c'] as String?,
      avatarImageUrl: r['Avatar_Image_Url__c'] as String?,
      heroImageUrl:   r['Hero_Image_Url__c'] as String?,
      isSubscribed:   r['Is_Subscribed__c'] as bool? ?? false,
    );
  }
}
