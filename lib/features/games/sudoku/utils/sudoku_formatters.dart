String formatSudokuDuration(int? seconds) {
  if (seconds == null) return '-';
  if (seconds < 60) return '$seconds detik';
  final hrs = seconds ~/ 3600;
  final mins = (seconds % 3600) ~/ 60;
  final secs = seconds % 60;
  if (hrs > 0) {
    return [
      '$hrs jam',
      if (mins > 0) '$mins menit',
      if (secs > 0) '$secs detik',
    ].join(' ');
  }
  return '$mins menit${secs > 0 ? ' $secs detik' : ''}';
}
