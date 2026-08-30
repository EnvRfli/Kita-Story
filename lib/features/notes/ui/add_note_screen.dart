import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/note_model.dart';
import '../providers/note_provider.dart';
import '../widgets/widgets.dart';

class AddNoteScreen extends StatefulWidget {
  final NoteModel? noteToEdit;

  const AddNoteScreen({
    super.key,
    this.noteToEdit,
  });

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  late String _selectedType; // 'text' or 'checklist'
  late String _selectedColor; // 'pink', 'yellow', etc.
  bool _isShared = false;

  // Dynamic checklist controllers
  final List<TextEditingController> _checklistControllers = [];
  final List<bool> _checklistCheckedStates = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final note = widget.noteToEdit;
    _titleController = TextEditingController(text: note?.title ?? '');
    _contentController = TextEditingController(text: note?.content ?? '');
    _selectedType = note?.type ?? 'text';
    _selectedColor = note?.color ?? 'pink';
    _isShared = note?.isShared ?? false;

    if (note != null && note.isChecklist && note.items.isNotEmpty) {
      for (final item in note.items) {
        _checklistControllers.add(TextEditingController(text: item.itemText));
        _checklistCheckedStates.add(item.isChecked);
      }
    } else if (note == null || !note.isChecklist) {
      // Default with 2 empty checklist items ready if switched to checklist
      _checklistControllers.add(TextEditingController());
      _checklistCheckedStates.add(false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    for (final c in _checklistControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addChecklistItem() {
    setState(() {
      _checklistControllers.add(TextEditingController());
      _checklistCheckedStates.add(false);
    });
  }

  void _removeChecklistItem(int index) {
    if (_checklistControllers.length <= 1) {
      _checklistControllers[0].clear();
      _checklistCheckedStates[0] = false;
      setState(() {});
      return;
    }

    setState(() {
      final controller = _checklistControllers.removeAt(index);
      controller.dispose();
      _checklistCheckedStates.removeAt(index);
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      AppSnackBar.error(context, 'Judul catatan tidak boleh kosong');
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final partnerId = authProvider.partnerProfile?.id;
    final provider = Provider.of<NoteProvider>(context, listen: false);

    bool success = false;
    final isEditing = widget.noteToEdit != null;

    if (_selectedType == 'text') {
      final content = _contentController.text.trim();
      if (isEditing) {
        success = await provider.updateNote(
          widget.noteToEdit!.id,
          title: title,
          type: 'text',
          content: content,
          color: _selectedColor,
          isShared: _isShared,
          partnerId: _isShared ? partnerId : null,
          checklistItems: [],
        );
      } else {
        success = await provider.createNote(
          title: title,
          type: 'text',
          content: content,
          color: _selectedColor,
          isShared: _isShared,
          partnerId: _isShared ? partnerId : null,
        );
      }
    } else {
      // Checklist type
      final validItems = <Map<String, dynamic>>[];
      for (int i = 0; i < _checklistControllers.length; i++) {
        final text = _checklistControllers[i].text.trim();
        if (text.isNotEmpty) {
          validItems.add({
            'item_text': text,
            'is_checked': _checklistCheckedStates[i],
          });
        }
      }

      if (validItems.isEmpty) {
        setState(() => _isLoading = false);
        AppSnackBar.error(context, 'Tambahkan minimal 1 item checklist');
        return;
      }

      if (isEditing) {
        success = await provider.updateNote(
          widget.noteToEdit!.id,
          title: title,
          type: 'checklist',
          color: _selectedColor,
          isShared: _isShared,
          partnerId: _isShared ? partnerId : null,
          checklistItems: validItems,
        );
      } else {
        final itemTexts = validItems.map((e) => e['item_text'] as String).toList();
        success = await provider.createNote(
          title: title,
          type: 'checklist',
          color: _selectedColor,
          isShared: _isShared,
          partnerId: _isShared ? partnerId : null,
          checklistItems: itemTexts,
        );
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      AppSnackBar.success(
        context,
        isEditing
            ? 'Catatan "$title" berhasil diperbarui!'
            : 'Catatan "$title" berhasil dibuat! (+5 Poin 🎉)',
      );
      context.pop();
    } else {
      AppSnackBar.error(
        context,
        provider.errorMessage ?? 'Gagal menyimpan catatan',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.noteToEdit != null;
    final authProvider = Provider.of<AuthProvider>(context);
    final partner = authProvider.partnerProfile;
    final hasPartner = partner != null;
    final partnerName = partner?.name;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF1E293B),
            size: 22,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isEditing ? 'Edit Catatan' : 'Catatan Baru',
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Tipe Catatan Pill Toggle (Text vs Checklist)
                      NoteTypeToggle(
                        selectedType: _selectedType,
                        onTypeChanged: (type) {
                          setState(() {
                            _selectedType = type;
                            if (type == 'checklist' && _checklistControllers.isEmpty) {
                              _checklistControllers.add(TextEditingController());
                              _checklistCheckedStates.add(false);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 18),

                      // 2. Color Palette Selection Row
                      const Text(
                        'Warna Catatan',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      NoteColorPicker(
                        selectedColor: _selectedColor,
                        onColorSelected: (color) {
                          setState(() => _selectedColor = color);
                        },
                      ),
                      const SizedBox(height: 24),

                      // 3. Judul Input
                      TextFormField(
                        controller: _titleController,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.3,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Judul',
                          hintStyle: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFCBD5E1),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Judul tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // 4. Content Area: Text OR Checklist
                      if (_selectedType == 'text')
                        _buildTextContentField()
                      else
                        _buildChecklistContentFields(),

                      // 5. Shared with Partner Toggle Card
                      if (hasPartner) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isShared
                                  ? const Color(0xFF0088FF).withValues(alpha: 0.5)
                                  : const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _isShared
                                      ? const Color(0xFF0088FF)
                                          .withValues(alpha: 0.12)
                                      : const Color(0xFFE2E8F0),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.favorite_rounded,
                                  color: _isShared
                                      ? const Color(0xFF0088FF)
                                      : const Color(0xFF94A3B8),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Catatan Bersama',
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      partnerName != null && partnerName.isNotEmpty
                                          ? 'Bagikan ke $partnerName, keduanya dapat mengedit & menambah data'
                                          : 'Bagikan ke pasangan, keduanya dapat mengedit & menambah data',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: _isShared,
                                activeTrackColor: const Color(0xFF0088FF),
                                onChanged: (val) =>
                                    setState(() => _isShared = val),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Fixed Simpan Button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF0088FF),
                        Color(0xFF0775D5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0088FF).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _handleSave,
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Simpan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  height: 1.0,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextContentField() {
    return TextFormField(
      controller: _contentController,
      minLines: 8,
      maxLines: null,
      style: const TextStyle(
        fontSize: 14.5,
        color: Color(0xFF334155),
        height: 1.5,
      ),
      decoration: const InputDecoration(
        hintText: 'Deskripsi',
        hintStyle: TextStyle(
          fontSize: 14.5,
          color: Color(0xFF94A3B8),
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildChecklistContentFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(_checklistControllers.length, (index) {
          final controller = _checklistControllers[index];
          final isChecked = _checklistCheckedStates[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Checkbox toggle (view in form)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _checklistCheckedStates[index] = !_checklistCheckedStates[index];
                    });
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isChecked ? const Color(0xFFFF7A00) : Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: isChecked
                            ? const Color(0xFFFF7A00)
                            : const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                    ),
                    child: isChecked
                        ? const Icon(
                            Icons.check_rounded,
                            size: 15,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),

                // Item description input
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: TextStyle(
                      fontSize: 14.5,
                      color: const Color(0xFF1E293B),
                      decoration: isChecked ? TextDecoration.lineThrough : null,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Tambah deskripsi',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF94A3B8),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),

                // Delete trash icon
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFFF3B30),
                    size: 20,
                  ),
                  onPressed: () => _removeChecklistItem(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),

        // "+ Tambah Checklist" Button (Orange Outline Pill)
        InkWell(
          onTap: _addChecklistItem,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFFF7A00),
                width: 1.3,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  color: Color(0xFFFF7A00),
                  size: 17,
                ),
                SizedBox(width: 4),
                Text(
                  'Tambah Checklist',
                  style: TextStyle(
                    color: Color(0xFFFF7A00),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
