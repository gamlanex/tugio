import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/service_type.dart';
import 'service_type_repository.dart';

class HttpServiceTypeRepository implements ServiceTypeRepository {
  @override
  Future<List<ServiceType>> getAll() async {
    try {
      final url = '${AppConfig.apiBaseUrl}/service-types';
      debugPrint('[HttpServiceTypeRepository] GET $url');

      final res = await http
          .get(Uri.parse(url))
          .timeout(AppConfig.requestTimeout);

      debugPrint('[HttpServiceTypeRepository] status=${res.statusCode} body=${res.body.substring(0, res.body.length.clamp(0, 200))}');

      if (res.statusCode != 200) {
        throw Exception('GET /service-types zwrócił ${res.statusCode}: ${res.body}');
      }

      final list = jsonDecode(res.body) as List<dynamic>;
      final types = list
          .map((e) => ServiceType.fromJson(e as Map<String, dynamic>))
          .toList();

      // "Inne" zawsze na końcu — dodaj jeśli serwer jej nie zwrócił
      if (!types.any((t) => t.isOther)) {
        types.add(ServiceType.other);
      }

      debugPrint('[HttpServiceTypeRepository] załadowano ${types.length} typów usług');
      return types;
    } catch (e, st) {
      debugPrint('[HttpServiceTypeRepository] BŁĄD: $e\n$st');
      rethrow;
    }
  }
}
