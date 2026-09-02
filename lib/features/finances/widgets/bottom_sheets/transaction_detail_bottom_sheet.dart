import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../models/transaction_model.dart';
import '../../providers/finance_provider.dart';
import 'add_transaction_bottom_sheet.dart';

class TransactionDetailBottomSheet extends StatefulWidget {
  final TransactionModel transaction;
  final bool isReadOnly;

  const TransactionDetailBottomSheet({
    super.key,
    required this.transaction,
    this.isReadOnly = false,
  });

  static Future<void> show(
    BuildContext context, {
    required TransactionModel transaction,
    bool isReadOnly = false,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => TransactionDetailBottomSheet(
        transaction: transaction,
        isReadOnly: isReadOnly,
      ),
    );
  }

  @override
  State<TransactionDetailBottomSheet> createState() =>
      _TransactionDetailBottomSheetState();
}

class _TransactionDetailBottomSheetState
    extends State<TransactionDetailBottomSheet> {
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Transaksi',
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus catatan "${widget.transaction.title}"?',
          style: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Hapus',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      setState(() => _isDeleting = true);
      final provider = context.read<FinanceProvider>();
      final success = await provider.deleteTransaction(widget.transaction.id);

      if (!mounted) return;
      setState(() => _isDeleting = false);

      if (success) {
        Navigator.of(context).pop();
        AppSnackBar.success(context, 'Transaksi berhasil dihapus');
      } else {
        AppSnackBar.error(
          context,
          provider.errorMessage ?? 'Gagal menghapus transaksi',
        );
      }
    }
  }

  void _handleEdit() {
    Navigator.of(context).pop();
    AddTransactionBottomSheet.show(
      context,
      transactionToEdit: widget.transaction,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.transaction.isIncome;
    final iconColor =
        isIncome ? const Color(0xFF00BBA7) : const Color(0xFFFF5252);
    final iconBgColor =
        isIncome ? const Color(0xFFE0F7F6) : const Color(0xFFFFECEB);
    final icon =
        isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final formattedAmount =
        FinanceProvider.formatRupiah(widget.transaction.amount);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Grey Handle Bar
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. Header Title
              const Text(
                'Keuangan',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 16),

              // 3. Direction Icon Circle
              Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 4. Title & Category Tag
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      widget.transaction.title,
                      style: const TextStyle(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8A00),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.transaction.category,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // 5. Amount
              Center(
                child: Text(
                  formattedAmount,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 6. Action Buttons: "Ubah" (Blue Gradient) & "Hapus" (Red Gradient) (Only for own items)
              if (!widget.isReadOnly)
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
}
