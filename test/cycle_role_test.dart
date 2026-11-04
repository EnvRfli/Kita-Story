import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/auth/models/user_model.dart';
import 'package:kita_story/features/cycle/utils/cycle_role.dart';

UserModel _user({required String id, String? gender}) {
  return UserModel(id: id, name: id, gender: gender);
}

void main() {
  group('CycleAccess.resolve', () {
    test('female is the owner', () {
      expect(
        CycleAccess.resolve(
          me: _user(id: 'female', gender: 'female'),
          partner: null,
        ),
        CycleRole.owner,
      );
    });

    test('female is owner even with a male partner', () {
      expect(
        CycleAccess.resolve(
          me: _user(id: 'female', gender: 'female'),
          partner: _user(id: 'male', gender: 'male'),
        ),
        CycleRole.owner,
      );
    });

    test('male with a female partner can monitor', () {
      expect(
        CycleAccess.resolve(
          me: _user(id: 'male', gender: 'male'),
          partner: _user(id: 'female', gender: 'female'),
        ),
        CycleRole.monitor,
      );
    });

    test('male with a male partner is hidden', () {
      expect(
        CycleAccess.resolve(
          me: _user(id: 'male', gender: 'male'),
          partner: _user(id: 'partner', gender: 'male'),
        ),
        CycleRole.hidden,
      );
    });

    test('male without a partner is hidden', () {
      expect(
        CycleAccess.resolve(
          me: _user(id: 'male', gender: 'male'),
          partner: null,
        ),
        CycleRole.hidden,
      );
    });

    test('null gender is hidden', () {
      expect(
        CycleAccess.resolve(
          me: _user(id: 'unknown'),
          partner: _user(id: 'female', gender: 'female'),
        ),
        CycleRole.hidden,
      );
    });

    test('gender matching ignores case and whitespace', () {
      expect(
        CycleAccess.resolve(
          me: _user(id: 'upper', gender: ' Female '),
          partner: null,
        ),
        CycleRole.owner,
      );
    });

    test('missing current user is hidden', () {
      expect(
        CycleAccess.resolve(me: null, partner: null),
        CycleRole.hidden,
      );
    });
  });

  group('CycleAccess.resolveForPartner', () {
    test('female partner exposes the monitor view', () {
      expect(
        CycleAccess.resolveForPartner(
          partner: _user(id: 'female', gender: 'female'),
        ),
        CycleRole.monitor,
      );
    });

    test('male partner stays hidden', () {
      expect(
        CycleAccess.resolveForPartner(
          partner: _user(id: 'male', gender: 'male'),
        ),
        CycleRole.hidden,
      );
    });

    test('null partner stays hidden', () {
      expect(CycleAccess.resolveForPartner(partner: null), CycleRole.hidden);
    });
  });
}
