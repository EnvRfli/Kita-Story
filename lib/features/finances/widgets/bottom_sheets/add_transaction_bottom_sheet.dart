import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../models/transaction_model.dart';
import '../../providers/finance_provider.dart';
import 'add_category_dialog.dart';

class AddTransactionBottomSheet extends StatefulWidget {
  final TransactionModel? transactionToEdit;

  const AddTransactionBottomSheet({
    super.key,
    this.transactionToEdit,
  });

  static Future<void> show(
    BuildContext context, {
    TransactionModel? transactionToEdit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddTransactionBottomSheet(
        transactionToEdit: transactionToEdit,
      ),
    );
  }

  @override
  State<AddTransactionBottomSheet> createState() =>
      _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState extends State<AddTransactionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;

  late String _selectedType; // 'income' or 'expense'
  String? _selectedCategory;
  late DateTime _selectedDate;
  bool _isSaving = false;

  bool get isEditing => widget.transactionToEdit != null;

  @override
  void initState() {
    super.initState();
    final item = widget.transactionToEdit;
    _titleController = TextEditingController(text: item?.title ?? '');
    _amountController = TextEditingController(
      text: item != null ? _formatRawNumber(item.amount.round().toString()) : '',
    );
    _selectedType = item?.type ?? 'expense';
    _selectedCategory = item?.category;
    _selectedDate = item?.transactionDate ?? DateTime.now();

    // Default category if not set
    _selectedCategory ??=
        _selectedType == 'income' ? 'Gaji' : 'Makan dan Minum';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _formatRawNumber(String s) {
    final clean = s.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return '';
    final number = int.tryParse(clean) ?? 0;
    final str = number.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    return buffer.toString().split('').reversed.join('');
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      AppSnackBar.error(context, 'Judul transaksi tidak boleh kosong');
      return;
    }

    final rawAmountStr = _amountController.text.replaceAll('.', '').trim();
    final amount = double.tryParse(rawAmountStr) ?? 0.0;
    if (amount <= 0) {
      AppSnackBar.error(context, 'Jumlah transaksi harus lebih dari 0');
      return;
    }

    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      AppSnackBar.error(context, 'Pilih kategori transaksi terlebih dahulu');
      return;
    }

    setState(() => _isSaving = true);

    final provider = context.read<FinanceProvider>();
    final auth = context.read<AuthProvider>();
    final partnerId = auth.partnerProfile?.id;

    bool success = false;

    if (isEditing) {
      success = await provider.updateTransaction(
        widget.transactionToEdit!.id,
        type: _selectedType,
        title: title,
        category: _selectedCategory!,
        amount: amount,
        transactionDate: _selectedDate,
        isShared: true,
        partnerId: partnerId,
      );
    } else {
      success = await provider.createTransaction(
        type: _selectedType,
        title: title,
        category: _selectedCategory!,
        amount: amount,
        transactionDate: _selectedDate,
        isShared: true,
        partnerId: partnerId,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop();
      AppSnackBar.success(
        context,
        isEditing
            ? 'Transaksi berhasil diperbarui! ✨'
            : _selectedType == 'income'
                ? 'Pemasukan berhasil dicatat! 💵 (+5 Poin)'
                : 'Pengeluaran berhasil dicatat! 💳 (+3 Poin)',
      );
    } else {
      AppSnackBar.error(
        context,
        provider.errorMessage ?? 'Gagal menyimpan transaksi',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final categories = _selectedType == 'income'
        ? provider.allIncomeCategoryNames
        : provider.allExpenseCategoryNames;

    // Ensure selected category is valid for the current type
    if (_selectedCategory == null || !categories.contains(_selectedCategory)) {
      if (categories.isNotEmpty) {
        _selectedCategory = categories.first;
      }
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Drag Handle
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
              Text(
                isEditing ? 'Ubah Transaksi' : 'Keuangan',
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 16),

              // 3. Jenis Transaksi (Toggle Chips)
              const Text(
                'Jenis Transaksi',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTypeToggleChip(
                    label: 'Pemasukan',
                    type: 'income',
                  ),
                  const SizedBox(width: 10),
                  _buildTypeToggleChip(
                    label: 'Pengeluaran',
                    type: 'expense',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Judul Transaksi
              const Text(
                'Judul Transaksi',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
                decoration: InputDecoration(
                  hintText: 'Masukkan judul transaksi',
                  hintStyle: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF94A3B8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Color(0xFFFF7A00), width: 1.5),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Judul transaksi tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 5. Kategori Chips + Add Custom Category Button
              const Text(
                'Kategori',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...categories.map((catName) {
                    final isSelected = _selectedCategory == catName;
                    return InkWell(
                      onTap: () {
                        setState(() => _selectedCategory = catName);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFF7A00)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFFF7A00)
                                : Colors.transparent,
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          catName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    );
                  }),

                  // Plus button for custom category
                  InkWell(
                    onTap: () {
                      AddCategoryDialog.show(
                        context,
                        isExpense: _selectedType == 'expense',
                        onCategoryAdded: (newCategory) async {
                          await provider.addCustomCategory(
                            newCategory,
                            isExpense: _selectedType == 'expense',
                          );
                          setState(() => _selectedCategory = newCategory);
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Color(0xFF64748B),
                        size: 19,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 6. Jumlah Transaksi (Formatted Currency)
              const Text(
                'Jumlah Transaksi',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      child: const Text(
                        'Rp',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (val) {
                          final formatted = _formatRawNumber(val);
                          if (formatted != val) {
                            _amountController.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(
                                  offset: formatted.length),
                            );
                          }
                        },
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                        decoration: const InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.normal,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 13),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty || val == '0') {
                            return 'Masukkan jumlah transaksi yang valid';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 7. Simpan Button
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0088FF), Color(0xFF0775D5)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0088FF).withValues(alpha: 0.30),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isSaving ? null : _handleSave,
                    borderRadius: BorderRadius.circular(14),
                    child: Center(
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Simpan',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ),
  ),
);
}

  Widget _buildTypeToggleChip({
    required String label,
    required String type,
  }) {
    final isSelected = _selectedType == type;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedType = type;
          });
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFF7A00)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFF7A00)
                  : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }
}
