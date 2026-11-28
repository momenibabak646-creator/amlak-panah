import 'package:flutter_test/flutter_test.dart';
import 'package:amlak_panah/property_permissions.dart';

void main() {
  group('canEditProperty', () {
    test('manager can edit any property', () {
      expect(canEditProperty(
        manager: true,
        currentUserId: 'manager',
        ownerId: 'consultant',
      ), isTrue);
    });

    test('owner consultant can edit own property', () {
      expect(canEditProperty(
        manager: false,
        currentUserId: 'consultant-a',
        ownerId: 'consultant-a',
      ), isTrue);
    });

    test('consultant with view permission cannot edit another owner property', () {
      expect(canEditProperty(
        manager: false,
        currentUserId: 'consultant-b',
        ownerId: 'consultant-a',
      ), isFalse);
    });

    test('shared access does not grant edit permission', () {
      expect(canEditProperty(
        manager: false,
        currentUserId: 'consultant-b',
        ownerId: 'consultant-a',
      ), isFalse);
    });

    test('missing identity fails closed', () {
      expect(canEditProperty(
        manager: false,
        currentUserId: null,
        ownerId: 'consultant-a',
      ), isFalse);
    });
  });
}
