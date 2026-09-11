import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../models/credential_model.dart';
import '../providers/credential_provider.dart';

class CredentialDetailBottomSheet extends StatefulWidget {
  final CredentialModel credential;

  const CredentialDetailBottomSheet({
    super.key,
    required this.credential,
  });

  static Future<void> show(
    BuildContext context, {
    required CredentialModel credential,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CredentialDetailBottomSheet(credential: credential),
    );
  }

  @override
  State<CredentialDetailBottomSheet> createState() =>
      _CredentialDetailBottomSheetState();
}

class _CredentialDetailBottomSheetState
    extends State<CredentialDetailBottomSheet> {
  bool _isMasked = false;
  bool _isDeleting = false;

  void _copyToClipboard(String label, String value) {
    if (value.isEmpty) return;
    Clipboard.setData(ClipboardData(text: value));
    AppSnackBar.success(context, '$label berhasil disalin ke clipboard!');
  }

  String _formatValue(String? value) {
    if (value == null || value.isEmpty) return '-';
    if (!_isMasked) return value;
    return '•' * value.length.clamp(6, 16);
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Hapus Kredensial?',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Text(
          'Apakah kamu yakin ingin menghapus kredensial "${widget.credential.title}"? Tindakan ini tidak dapat dibatalkan.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Batal',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Hapus',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    final provider = context.read<CredentialProvider>();
    final success = await provider.deleteCredential(widget.credential.id);
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      AppSnackBar.success(context, 'Kredensial berhasil dihapus!');
    } else {
      setState(() => _isDeleting = false);
      AppSnackBar.show(
        context,
        message: 'Gagal menghapus kredensial.',
        type: SnackBarType.error,
      );
    }
  }

  void _handleEdit() {
    Navigator.of(context).pop();
    context.push('/add-credential', extra: widget.credential);
  }

  @override
  Widget build(BuildContext context) {
    final cred = widget.credential;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Drag Handle
              Center(
                child: Container(
                  width: 38,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. Header Row: "Kredensial" and Eye Masking Toggle Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Kredensial',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.3,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isMasked
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: const Color(0xFF1E293B),
                      size: 24,
                    ),
                    tooltip: _isMasked ? 'Tampilkan Data' : 'Samarkan Data',
                    onPressed: () => setState(() => _isMasked = !_isMasked),
                  ),
                ],
              ),
              const Divider(color: Color(0xFFF1F5F9), height: 16),
              const SizedBox(height: 8),

              // 3. Credential Big Title
              Text(
                cred.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 12),

              // 4. Category & Subcategory Orange Badges
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8A00),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      cred.categoryName,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (cred.subcategoryName.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8A00),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        cred.subcategoryName,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                  if (cred.isSharedWithPartner) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFBFDBFE),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            size: 14,
                            color: Color(0xFF0088FF),
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Bersama',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0088FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              // 5. Dynamic Credential Info Rows
              if (cred.fields.isNotEmpty) ...[
                ...cred.fields.map((field) {
                  return _buildDetailTile(
                    label: field.label,
                    value: field.value,
                  );
                }),
              ] else ...[
                // Fallback for legacy records without dynamic fields
                if (cred.usernameId != null && cred.usernameId!.isNotEmpty)
                  _buildDetailTile(
                    label: 'Username/ID',
                    value: cred.usernameId!,
                  ),
                if (cred.email != null && cred.email!.isNotEmpty)
                  _buildDetailTile(
                    label: 'Email',
                    value: cred.email!,
                  ),
                if (cred.password != null && cred.password!.isNotEmpty)
                  _buildDetailTile(
                    label: 'Password',
                    value: cred.password!,
                  ),
                if (cred.nomorRekening != null &&
                    cred.nomorRekening!.isNotEmpty)
                  _buildDetailTile(
                    label: 'Nomor Rekening',
                    value: cred.nomorRekening!,
                  ),
              ],

              // Optional Keterangan
              if (cred.keterangan != null && cred.keterangan!.isNotEmpty)
                _buildDetailTile(
                  label: 'Keterangan',
                  value: cred.keterangan!,
                  canCopy: true,
                ),

              const SizedBox(height: 20),

              // 6. Action Buttons: Ubah (Blue Gradient) and Hapus (Red Gradient)
              Row(
                children: [
                  // Ubah Button
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0088FF), Color(0xFF0775D5)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF0088FF).withValues(alpha: 0.30),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _handleEdit,
                          borderRadius: BorderRadius.circular(12),
                          child: const Center(
                            child: Text(
                              'Ubah',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Hapus Button
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF3B30), Color(0xFFE02424)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFFF3B30).withValues(alpha: 0.30),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isDeleting ? null : _handleDelete,
                          borderRadius: BorderRadius.circular(12),
                          child: Center(
                            child: _isDeleting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Hapus',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTile({
    required String label,
    required String value,
    bool canCopy = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      constraints: const BoxConstraints(minHeight: 46),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          Expanded(
            child: Text(
              _formatValue(value),
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (canCopy) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: () => _copyToClipboard(label, value),
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.all(5),
                child: Icon(
                  Icons.copy_rounded,
                  size: 17,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
