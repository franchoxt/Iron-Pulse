import 'package:flutter_test/flutter_test.dart';
import 'package:iron_pulse/models/models.dart';
import 'package:iron_pulse/services/user_session_service.dart';

void main() {
  group('UserSessionService & Role Differentiation Tests', () {
    test('Default role should be client', () {
      final session = UserSessionService.instance;
      session.clear();

      expect(session.role, equals(UserRole.client));
      expect(session.isClient, isTrue);
      expect(session.isAdmin, isFalse);
    });

    test('UserProfileModel parses admin and client roles correctly', () {
      final adminJson = {
        'id': 'admin-uuid-1234',
        'full_name': 'Super Admin',
        'avatar_url': 'https://example.com/admin.jpg',
        'role': 'admin',
        'updated_at': '2026-10-26T12:00:00Z',
      };

      final adminProfile = UserProfileModel.fromJson(adminJson);
      expect(adminProfile.role, equals(UserRole.admin));
      expect(adminProfile.isAdmin, isTrue);

      final clientJson = {
        'id': 'client-uuid-5678',
        'full_name': 'Atleta Javier',
        'avatar_url': null,
        'role': 'client',
        'updated_at': null,
      };

      final clientProfile = UserProfileModel.fromJson(clientJson);
      expect(clientProfile.role, equals(UserRole.client));
      expect(clientProfile.isAdmin, isFalse);
    });

    test('clear() resets session to default client role', () {
      final session = UserSessionService.instance;
      session.clear();

      expect(session.profile, isNull);
      expect(session.role, equals(UserRole.client));
      expect(session.isAdmin, isFalse);
      expect(session.isClient, isTrue);
    });
  });
}
