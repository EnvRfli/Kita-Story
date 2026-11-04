import '../../auth/models/user_model.dart';

enum CycleRole { owner, monitor, hidden }

class CycleAccess {
  static CycleRole resolve({
    required UserModel? me,
    required UserModel? partner,
  }) {
    final myGender = me?.gender?.trim().toLowerCase();
    final partnerGender = partner?.gender?.trim().toLowerCase();

    if (myGender == 'female') return CycleRole.owner;
    if (myGender == 'male' && partnerGender == 'female') {
      return CycleRole.monitor;
    }
    return CycleRole.hidden;
  }

  static CycleRole resolveForPartner({required UserModel? partner}) {
    return partner?.gender?.trim().toLowerCase() == 'female'
        ? CycleRole.monitor
        : CycleRole.hidden;
  }
}
