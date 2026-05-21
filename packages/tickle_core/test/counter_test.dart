import 'package:flutter_test/flutter_test.dart';
import 'package:tickle_core/tickle_core.dart';

void main() {
  group('Counter Model Test', () {
    test('supports value equality', () {
      final now = DateTime.now();
      final c1 = Counter(
        id: '1',
        title: 'Water',
        colorHex: '#10B981',
        createdAt: now,
      );
      final c2 = Counter(
        id: '1',
        title: 'Water',
        colorHex: '#10B981',
        createdAt: now,
      );

      expect(c1, equals(c2));
    });

    test('copyWith updates properties correctly', () {
      final now = DateTime.now();
      final original = Counter(
        id: '1',
        title: 'Water',
        colorHex: '#10B981',
        createdAt: now,
      );

      final updated = original.copyWith(
        title: 'Coffee',
        currentCount: 5,
      );

      expect(updated.id, '1');
      expect(updated.title, 'Coffee');
      expect(updated.currentCount, 5);
      expect(updated.colorHex, '#10B981');
    });
  });
}
