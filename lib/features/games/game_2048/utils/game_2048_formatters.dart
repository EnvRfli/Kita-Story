String format2048Score(int score) {
  final digits = score.abs().toString();
  final groups = <String>[];
  for (var end = digits.length; end > 0; end -= 3) {
    groups.add(digits.substring(end - 3 < 0 ? 0 : end - 3, end));
  }
  final formatted = groups.reversed.join('.');
  return score.isNegative ? '-$formatted' : formatted;
}

String format2048Duration(int seconds) {
  final duration = Duration(seconds: seconds < 0 ? 0 : seconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final remainingSeconds = duration.inSeconds.remainder(60);
  if (hours > 0) return '${hours}j ${minutes}m';
  if (minutes > 0) return '${minutes}m ${remainingSeconds}d';
  return '${remainingSeconds}d';
}
