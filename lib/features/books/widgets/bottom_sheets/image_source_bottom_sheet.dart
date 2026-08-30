import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/widgets/image_source_picker_bottom_sheet.dart';

/// Backward-compatible wrapper delegating to the universal [ImageSourcePickerBottomSheet]
class ImageSourceBottomSheet {
  static Future<ImageSource?> show(
    BuildContext context, {
    String title = 'Pilih Sumber Foto',
    String subtitle = 'Pilih sumber gambar yang ingin Anda gunakan',
  }) {
    return ImageSourcePickerBottomSheet.show(
      context,
      title: title,
      subtitle: subtitle,
    );
  }
}
