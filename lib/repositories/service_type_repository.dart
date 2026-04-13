import '../models/service_type.dart';

abstract class ServiceTypeRepository {
  /// Zwraca listę typów usług. Kategoria "Inne" jest zawsze dodawana na końcu.
  Future<List<ServiceType>> getAll();
}
