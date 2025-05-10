import 'package:flutter_test/flutter_test.dart';
import 'package:shamil_mobile_app/feature/access/data/nfc_service.dart';

void main() {
  group('NFCService', () {
    test('should be a singleton', () {
      final instance1 = NFCService();
      final instance2 = NFCService();

      expect(instance1, same(instance2));
    });

    test('should have public streams available', () {
      final service = NFCService();

      expect(service.statusStream, isNotNull);
      expect(service.tagDataStream, isNotNull);
    });

    test('should have correct NFCStatus enum values', () {
      expect(NFCStatus.values.length, equals(6));
      expect(NFCStatus.available, isNotNull);
      expect(NFCStatus.notAvailable, isNotNull);
      expect(NFCStatus.notEnabled, isNotNull);
      expect(NFCStatus.reading, isNotNull);
      expect(NFCStatus.success, isNotNull);
      expect(NFCStatus.error, isNotNull);
    });
  });
}
