import 'package:flutter/foundation.dart';

@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
  });

  final String id;
  final String email;
  final String name;
  final String phone;

  factory AppUser.fromRtdb(String id, Map<dynamic, dynamic> values) {
    return AppUser(
      id: id,
      email: '${values['email'] ?? ''}',
      name: '${values['name'] ?? ''}',
      phone: '${values['phone'] ?? ''}',
    );
  }
}

@immutable
class AppUserDraft {
  const AppUserDraft({
    required this.name,
    required this.phone,
    required this.email,
  });

  final String name;
  final String phone;
  final String email;

  Map<String, dynamic> toRtdbMap() => {
        'name': name,
        'phone': phone,
        'email': email,
      };
}
