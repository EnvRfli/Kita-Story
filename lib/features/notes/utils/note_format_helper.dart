import '../models/note_model.dart';

class ParsedChecklistItem {
  final String text;
  final bool isChecked;

  const ParsedChecklistItem({
    required this.text,
    required this.isChecked,
  });
}

class ParsedNoteData {
  final String? title;
  final List<ParsedChecklistItem> checklistItems;
  final String? textContent;
  final bool isChecklist;

  const ParsedNoteData({
    this.title,
    this.checklistItems = const [],
    this.textContent,
    this.isChecklist = true,
  });
}

class NoteFormatHelper {
  /// Export a NoteModel into formatted text (WhatsApp / Markdown style)
  /// Format:
  /// *Judul Catatan*
  ///
  /// - ~item selesai~
  /// - item belum selesai
  static String exportNote(NoteModel note) {
    final buffer = StringBuffer();
    final title = note.title.trim();
    if (title.isNotEmpty) {
      buffer.writeln('*$title*');
      buffer.writeln();
    }

    if (note.isChecklist) {
      for (final item in note.items) {
        final text = item.itemText.trim();
        if (text.isEmpty) continue;
        if (item.isChecked) {
          buffer.writeln('- ~$text~');
        } else {
          buffer.writeln('- $text');
        }
      }
    } else {
      if (note.content != null && note.content!.trim().isNotEmpty) {
        buffer.write(note.content!.trim());
      }
    }

    return buffer.toString().trim();
  }

  /// Parse raw imported text into structured ParsedNoteData
  static ParsedNoteData parseImportText(String rawText) {
    final lines = rawText.split(RegExp(r'\r?\n'));
    if (lines.isEmpty) {
      return const ParsedNoteData(checklistItems: []);
    }

    String? extractedTitle;
    final List<ParsedChecklistItem> items = [];
    final List<String> textLines = [];
    bool hasChecklistBullets = false;

    // Find first non-empty line
    int startIndex = 0;
    while (startIndex < lines.length && lines[startIndex].trim().isEmpty) {
      startIndex++;
    }

    if (startIndex >= lines.length) {
      return const ParsedNoteData(checklistItems: []);
    }

    final firstLine = lines[startIndex].trim();
    final isFirstLineBullet = _isBulletLine(firstLine);

    // If first line does not look like a bullet and there are more lines, treat line 1 as Title
    if (!isFirstLineBullet && lines.length > startIndex + 1) {
      var cleanTitle = firstLine;
      if (cleanTitle.startsWith('*') &&
          cleanTitle.endsWith('*') &&
          cleanTitle.length >= 2) {
        cleanTitle = cleanTitle.substring(1, cleanTitle.length - 1).trim();
      } else if (cleanTitle.startsWith('#')) {
        cleanTitle = cleanTitle.replaceFirst(RegExp(r'^#+\s*'), '').trim();
      }
      extractedTitle = cleanTitle;
      startIndex++;
      // Skip empty lines between Title and Content
      while (startIndex < lines.length && lines[startIndex].trim().isEmpty) {
        startIndex++;
      }
    }

    for (int i = startIndex; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      if (_isBulletLine(line) || _hasStrikethrough(line)) {
        hasChecklistBullets = true;
      }

      final item = _parseLineToChecklistItem(line);
      if (item != null && item.text.isNotEmpty) {
        items.add(item);
      }
      textLines.add(line);
    }

    return ParsedNoteData(
      title: extractedTitle,
      checklistItems: items,
      textContent: textLines.join('\n'),
      isChecklist: hasChecklistBullets || items.isNotEmpty,
    );
  }

  static bool _isBulletLine(String line) {
    final trimmed = line.trim();
    return trimmed.startsWith('- ') ||
        trimmed.startsWith('* ') ||
        trimmed.startsWith('• ') ||
        trimmed.startsWith('[ ]') ||
        trimmed.startsWith('[x]') ||
        trimmed.startsWith('[X]') ||
        RegExp(r'^\d+[\.\)]\s').hasMatch(trimmed);
  }

  static bool _hasStrikethrough(String line) {
    return line.contains('~');
  }

  static ParsedChecklistItem? _parseLineToChecklistItem(String rawLine) {
    var line = rawLine.trim();
    if (line.isEmpty) return null;

    bool isChecked = false;

    // 1. Checkbox syntax: [x], [X], [ ]
    if (line.startsWith('[x] ') ||
        line.startsWith('[X] ') ||
        line.startsWith('[x]') ||
        line.startsWith('[X]')) {
      isChecked = true;
      line = line.replaceFirst(RegExp(r'^\[[xX]\]\s*'), '');
    } else if (line.startsWith('[ ] ') || line.startsWith('[ ]')) {
      isChecked = false;
      line = line.replaceFirst(RegExp(r'^\[\s*\]\s*'), '');
    }

    // 2. Bullets: - , * , • , 1. , 1)
    line = line.replaceFirst(RegExp(r'^[-*•]\s+'), '');
    line = line.replaceFirst(RegExp(r'^\d+[\.\)]\s+'), '');

    line = line.trim();

    // 3. Strikethrough syntax: ~text~
    if (line.startsWith('~') && line.endsWith('~') && line.length >= 2) {
      isChecked = true;
      line = line.substring(1, line.length - 1).trim();
    } else if (line.contains('~')) {
      final strikeMatch = RegExp(r'~([^~]+)~').firstMatch(line);
      if (strikeMatch != null) {
        isChecked = true;
        line = line.replaceAll('~', '').trim();
      }
    }

    if (line.isEmpty) return null;

    return ParsedChecklistItem(text: line, isChecked: isChecked);
  }
}
