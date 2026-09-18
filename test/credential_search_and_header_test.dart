import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/credentials/models/credential_model.dart';
import 'package:kita_story/features/credentials/providers/credential_provider.dart';
import 'package:kita_story/features/credentials/ui/credentials_screen.dart';

void main() {
  final credential = CredentialModel(
    id: 'credential-1',
    userId: 'user-1',
    categoryName: 'Keuangan',
    subcategoryName: 'Mobile Banking',
    title: 'Bank Utama',
    fields: [
      CredentialField(label: 'Kode Rahasia', value: 'alpha-123'),
    ],
    keterangan: 'Dipakai setiap hari',
    createdAt: DateTime(2026, 9, 16),
    updatedAt: DateTime(2026, 9, 16),
  );

  test('credential search matches title, subcategory, and field values', () {
    expect(credentialMatchesSearch(credential, 'bank utama'), isTrue);
    expect(credentialMatchesSearch(credential, 'mobile banking'), isTrue);
    expect(credentialMatchesSearch(credential, 'ALPHA-123'), isTrue);
  });

  test('credential search ignores category, field labels, and notes', () {
    expect(credentialMatchesSearch(credential, 'keuangan'), isFalse);
    expect(credentialMatchesSearch(credential, 'kode rahasia'), isFalse);
    expect(credentialMatchesSearch(credential, 'setiap hari'), isFalse);
  });

  testWidgets('credentials header title is centered in the viewport',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: CredentialsHeader(),
          ),
        ),
      ),
    );

    final titleCenter = tester.getCenter(find.text('Kredensial')).dx;
    final viewportCenter = tester.getCenter(find.byType(SizedBox).first).dx;

    expect(titleCenter, closeTo(viewportCenter, 0.01));
  });
}
