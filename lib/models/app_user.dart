import 'dart:convert';

/// Użytkownik aplikacji Tugio.
/// Może być zalogowany przez Google lub email/hasło.
class AppUser {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;

  /// 'google' | 'email'
  final String authMethod;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.authMethod,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String? ?? '',
        email: json['email'] as String? ?? '',
        name: json['name'] as String? ?? '',
        photoUrl: json['photoUrl'] as String?,
        authMethod: json['authMethod'] as String? ?? 'email',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'photoUrl': photoUrl,
        'authMethod': authMethod,
      };

  String toJsonString() => jsonEncode(toJson());

  /// Inicjały do awatara (maks. 2 litery)
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
