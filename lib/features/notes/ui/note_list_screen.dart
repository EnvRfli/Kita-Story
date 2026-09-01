import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/note_model.dart';
import '../providers/note_provider.dart';
import '../widgets/widgets.dart';

class NoteListScreen extends StatefulWidget {
  final String? partnerId;
  final String? partnerName;
  final bool isReadOnly;

  const NoteListScreen({
    super.key,
    this.partnerId,
    this.partnerName,
    this.isReadOnly = false,
  });

  @override
  State<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _hasOrderChanged = false;
  bool _isSavingOrder = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final partner = authProvider.partnerProfile;
      Provider.of<NoteProvider>(context, listen: false).fetchNotes(
        targetUserId: widget.isReadOnly ? widget.partnerId : null,
        partnerId: partner?.id,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<NoteModel> _filterNotes(List<NoteModel> notes) {
    final query = _searchController.text.trim().toLowerCase();
    final list = query.isEmpty
        ? notes
        : notes.where((note) {
            final title = note.title.toLowerCase();
            final content = (note.content ?? '').toLowerCase();
            final itemsText =
                note.items.map((i) => i.itemText.toLowerCase()).join(' ');
            return title.contains(query) ||
                content.contains(query) ||
                itemsText.contains(query);
          }).toList();

    if (_hasOrderChanged) return list;

    return List<NoteModel>.from(list)
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        if (a.sortOrder != b.sortOrder) {
          return a.sortOrder.compareTo(b.sortOrder);
        }
        final aTime = a.updatedAt ?? a.createdAt ?? DateTime(2000);
        final bTime = b.updatedAt ?? b.createdAt ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
  }

  Future<void> _openAddNote() async {
    await context.push('/add-note');
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final partner = authProvider.partnerProfile;
    context.read<NoteProvider>().fetchNotes(
          partnerId: partner?.id,
        );
  }

  Future<void> _openNoteDetail(NoteModel note) async {
    await context.push(
      '/note-detail',
      extra: {
        'note': note,
        'isReadOnly': widget.isReadOnly,
      },
    );
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final partner = authProvider.partnerProfile;
    context.read<NoteProvider>().fetchNotes(
          targetUserId: widget.isReadOnly ? widget.partnerId : null,
          partnerId: partner?.id,
        );
  }

  Future<void> _saveOrder() async {
    setState(() => _isSavingOrder = true);
    final success = await context.read<NoteProvider>().saveNotesOrder(
          targetUserId: widget.isReadOnly ? widget.partnerId : null,
        );
    if (!mounted) return;
    setState(() {
      _isSavingOrder = false;
      if (success) {
        _hasOrderChanged = false;
      }
    });
    if (success) {
      AppSnackBar.success(context, 'Urutan catatan berhasil disimpan! ✨');
    } else {
      AppSnackBar.error(context, 'Gagal menyimpan urutan catatan.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isReadOnly
        ? (widget.partnerName != null && widget.partnerName!.trim().isNotEmpty
            ? 'Catatan ${widget.partnerName}'
            : 'Catatan Pasangan')
        : 'Catatan';

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: Consumer<NoteProvider>(
        builder: (_, provider, __) {
          final allNotes = provider.notes;
          final filteredNotes = _filterNotes(allNotes);

          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                // 1. Top Header App Bar
                Container(
                  color: const Color(0xFFFCFCFD),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFF1E293B),
                          size: 22,
                        ),
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Balances leading back button
                    ],
                  ),
                ),

                // 2. Permanent Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: _buildSearchField(),
                ),

                // 3. Notes List or Empty State
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      final authProvider =
                          Provider.of<AuthProvider>(context, listen: false);
                      setState(() => _hasOrderChanged = false);
                      await provider.fetchNotes(
                        targetUserId:
                            widget.isReadOnly ? widget.partnerId : null,
                        partnerId: authProvider.partnerProfile?.id,
                      );
                    },
                    color: const Color(0xFFFF7A00),
                    backgroundColor: Colors.white,
                    child: provider.isLoading && allNotes.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFFF7A00),
                              ),
                            ),
                          )
                        : allNotes.isEmpty
                            ? _buildEmptyState()
                            : filteredNotes.isEmpty
                                ? _buildNoSearchResultsState()
                                : ReorderableListView.builder(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(
                                      parent: BouncingScrollPhysics(),
                                    ),
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      8,
                                      16,
                                      95,
                                    ),
                                    itemCount: filteredNotes.length,
                                    buildDefaultDragHandles: !widget.isReadOnly &&
                                        _searchController.text.trim().isEmpty,
                                    onReorder: (oldIndex, newIndex) {
                                      HapticFeedback.selectionClick();
                                      if (!widget.isReadOnly &&
                                          _searchController.text
                                              .trim()
                                              .isEmpty) {
                                        provider.reorderNotes(
                                            oldIndex, newIndex);
                                        setState(() {
                                          _hasOrderChanged = true;
                                        });
                                      }
                                    },
                                    proxyDecorator: (Widget child, int index,
                                        Animation<double> animation) {
                                      return AnimatedBuilder(
                                        animation: animation,
                                        builder: (context, child) {
                                          final double animValue =
                                              Curves.easeInOut
                                                  .transform(animation.value);
                                          final double elevation =
                                              lerpDouble(0, 14, animValue)!;
                                          final double scale =
                                              lerpDouble(1.0, 1.03, animValue)!;
                                          return Transform.scale(
                                            scale: scale,
                                            child: Material(
                                              elevation: elevation,
                                              color: Colors.transparent,
                                              shadowColor: Colors.black
                                                  .withValues(alpha: 0.35),
                                              borderRadius:
                                                  BorderRadius.circular(22),
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: child,
                                      );
                                    },
                                    itemBuilder: (_, index) {
                                      final note = filteredNotes[index];
                                      return KeyedSubtree(
                                        key: ValueKey(note.id),
                                        child: NoteCard(
                                          note: note,
                                          onTap: () => _openNoteDetail(note),
                                        ),
                                      );
                                    },
                                  ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _hasOrderChanged && !widget.isReadOnly
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 18,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isSavingOrder
                          ? null
                          : () {
                              final authProvider =
                                  Provider.of<AuthProvider>(context, listen: false);
                              final partner = authProvider.partnerProfile;
                              Provider.of<NoteProvider>(context, listen: false)
                                  .fetchNotes(
                                targetUserId:
                                    widget.isReadOnly ? widget.partnerId : null,
                                partnerId: partner?.id,
                              );
                              setState(() => _hasOrderChanged = false);
                            },
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientBiru,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0088FF).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isSavingOrder ? null : _saveOrder,
                          borderRadius: BorderRadius.circular(14),
                          child: Center(
                            child: _isSavingOrder
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Simpan Urutan',
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
      floatingActionButton: (widget.isReadOnly || _hasOrderChanged)
          ? null
          : Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.fabGold,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.fabGold.withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openAddNote,
                  customBorder: const CircleBorder(),
                  child: const Center(
                    child: Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          hintText: 'Cari catatan...',
          hintStyle: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF94A3B8),
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF94A3B8),
                    size: 16,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECEF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sticky_note_2_rounded,
                size: 58,
                color: Color(0xFFFF7A00),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Belum Ada Catatan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Buat catatan belanja, to-do list, atau pengingat manis bersama pasanganmu!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            if (!widget.isReadOnly) ...[
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: () async {
                  await context.push('/add-note');
                  if (!mounted) return;
                  context.read<NoteProvider>().fetchNotes();
                },
                icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                label: const Text(
                  'Buat Catatan Pertama',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A00),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 38,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Catatan Tidak Ditemukan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tidak ada catatan yang cocok dengan "${_searchController.text.trim()}".',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
