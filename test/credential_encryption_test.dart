import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/core/services/encryption_service.dart';
import 'package:kita_story/features/credentials/models/credential_model.dart';

void main() {
  group('Credential Encryption Tests', () {
    const testUserId = 'f74c8b21-4f9e-4e56-9b24-123456789abc';

    test('EncryptionService should encrypt and decrypt string accurately', () {
      const plain = 'MySecretPassword123!@#';
      final cipher = EncryptionService.encrypt(plain, testUserId);

      expect(cipher, isNot(equals(plain)));
      expect(cipher.contains(':'), isTrue);

      final decrypted = EncryptionService.decrypt(cipher, testUserId);
      expect(decrypted, equals(plain));
    });

    test('EncryptionService should encrypt and decrypt JSON dynamic fields', () {
      final dynamicList = [
        {'label': 'Username/ID', 'value': 'kita_user'},
        {'label': 'Kata Sandi', 'value': 'SuperSecret2026'},
        {'label': 'Nomor Rekening', 'value': '1234567890'},
      ];

      final cipher = EncryptionService.encryptJson(dynamicList, testUserId);
      expect(cipher, isNot(contains('kita_user')));
      expect(cipher, isNot(contains('SuperSecret2026')));

      final decrypted = EncryptionService.decryptJson(cipher, testUserId);
      expect(decrypted, isA<List>());
      final list = decrypted as List;
      expect(list.length, equals(3));
      expect(list[0]['label'], equals('Username/ID'));
      expect(list[0]['value'], equals('kita_user'));
      expect(list[1]['value'], equals('SuperSecret2026'));
    });

    test('CredentialModel serialization and deserialization with encryption', () {
      final cred = CredentialModel(
        id: 'cred-1',
        userId: testUserId,
        categoryName: 'Keuangan',
        subcategoryName: 'Bank BCA',
        title: 'M-Banking BCA',
        fields: [
          CredentialField(label: 'No. Rekening', value: '5220304050'),
          CredentialField(label: 'PIN ATM', value: '123456'),
        ],
        keterangan: 'Akun tabungan bersama',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final json = cred.toJson(targetUserId: testUserId);

      expect(json['title'], equals('M-Banking BCA'));
      expect(json['encrypted_data'], isNotNull);
      expect(json['encrypted_data'], isNot(contains('5220304050')));
      expect(json['encrypted_data'], isNot(contains('123456')));

      // Deserialize back
      final restored = CredentialModel.fromJson(json, currentUserId: testUserId);
      expect(restored.title, equals('M-Banking BCA'));
      expect(restored.fields.length, equals(2));
      expect(restored.fields[0].label, equals('No. Rekening'));
      expect(restored.fields[0].value, equals('5220304050'));
      expect(restored.fields[1].label, equals('PIN ATM'));
      expect(restored.fields[1].value, equals('123456'));
      expect(restored.keterangan, equals('Akun tabungan bersama'));
    });
  });
}
