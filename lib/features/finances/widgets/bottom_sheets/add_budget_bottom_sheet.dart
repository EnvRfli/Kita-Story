import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../models/finance_budget_model.dart';
import '../../models/finance_category_model.dart';
import '../../providers/finance_provider.dart';
import 'add_category_dialog.dart';

class AddBudgetBottomSheet extends StatefulWidget {
  final FinanceBudgetModel? budgetToEdit;

  const AddBudgetBottomSheet({
    super.key,
    this.budgetToEdit,
  });

  static Future<void> show(
    BuildContext context, {
    FinanceBudgetModel? budgetToEdit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddBudgetBottomSheet(budgetToEdit: budgetToEdit),
    );
  }

  @override
  State<AddBudgetBottomSheet> createState() => _AddBudgetBottomSheetState();
}

class _AddBudgetBottomSheetState extends State<AddBudgetBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;

  late String _selectedCategory;
  late String _selectedPeriodType; // 'monthly', 'weekly', 'daily', 'custom'
  late int _monthlyStartDay;
  late DateTime _startDate;
  late DateTime _endDate;
  late bool _isAutoRenew;
  late bool _isShared;
  bool _isSaving = false;

  bool get isEditing => widget.budgetToEdit != null;

  @override
  void initState() {
    super.initState();
    final item = widget.budgetToEdit;
    _amountController = TextEditingController(
      text: item != null ? _formatRawNumber(item.amount.round().toString()) : '',
    );
    _selectedCategory = item?.category ?? FinanceBudgetModel.allCategoriesKey;
    _selectedPeriodType = item?.periodType ?? 'monthly';
    _monthlyStartDay = item?.monthlyStartDay ?? 1;
    _isAutoRenew = item?.isAutoRenew ?? true;
    _isShared = item?.isShared ?? false;

    if (item != null) {
      _startDate = item.startDate;
      _endDate = item.endDate;
    } else {
      _recalculateDates();
    }
  }

  void _recalculateDates() {
    final now = DateTime.now();
    switch (_selectedPeriodType) {
      case 'daily':
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day);
        break;

      case 'weekly':
        final weekday = now.weekday;
        _startDate = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: weekday - 1));
        _endDate = _startDate.add(const Duration(days: 6));
        break;

      case 'monthly':
      default:
        final clampedStartDay = _monthlyStartDay.clamp(1, 28);
        if (now.day >= clampedStartDay) {
          _startDate = DateTime(now.year, now.month, clampedStartDay);
          final nextMonth = DateTime(now.year, now.month + 1, 1);
          final daysInNext =
              DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
          final nextDay = clampedStartDay.clamp(1, daysInNext);
          _endDate = DateTime(nextMonth.year, nextMonth.month, nextDay)
              .subtract(const Duration(days: 1));
        } else {
          final prevMonth = DateTime(now.year, now.month - 1, 1);
          final daysInPrev =
              DateTime(prevMonth.year, prevMonth.month + 1, 0).day;
          final prevDay = clampedStartDay.clamp(1, daysInPrev);
          _startDate = DateTime(prevMonth.year, prevMonth.month, prevDay);
          _endDate = DateTime(now.year, now.month, clampedStartDay)
              .subtract(const Duration(days: 1));
        }
        break;
    }
  }

  @override
  void dispose() {
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

  void _openCategorySearchPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CategorySearchBottomSheet(
        selectedCategory: _selectedCategory,
        onSelected: (cat) {
          setState(() => _selectedCategory = cat);
        },
      ),
    );
  }

  Future<void> _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.gradientBlueEnd,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final cleanAmount =
        _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(cleanAmount) ?? 0.0;
    if (amount <= 0) {
      AppSnackBar.error(context, 'Nominal budget harus lebih dari 0');
      return;
    }

    final auth = context.read<AuthProvider>();
    final partnerId = auth.currentUserProfile?.partnerId;

    setState(() => _isSaving = true);

    try {
      final provider = context.read<FinanceProvider>();
      final repeatType = _isAutoRenew ? 'auto_renew' : 'none';

      if (isEditing) {
        final success = await provider.editBudget(
          widget.budgetToEdit!.id,
          category: _selectedCategory,
          amount: amount,
          periodType: _selectedPeriodType,
          startDate: _startDate,
          endDate: _endDate,
          repeatType: repeatType,
          monthlyStartDay: _monthlyStartDay,
          isShared: _isShared,
          partnerId: _isShared ? partnerId : null,
        );

        if (!mounted) return;
        if (success) {
          Navigator.pop(context);
          AppSnackBar.success(context, 'Budget berhasil diperbarui');
        } else {
          AppSnackBar.error(context, provider.errorMessage ?? 'Gagal');
        }
      } else {
        final success = await provider.addBudget(
          category: _selectedCategory,
          amount: amount,
          periodType: _selectedPeriodType,
          startDate: _startDate,
          endDate: _endDate,
          repeatType: repeatType,
          monthlyStartDay: _monthlyStartDay,
          isShared: _isShared,
          partnerId: _isShared ? partnerId : null,
        );

        if (!mounted) return;
        if (success) {
          Navigator.pop(context);
          AppSnackBar.success(
              context, 'Budget baru berhasil dibuat (+5 Poin)');
        } else {
          AppSnackBar.error(context, provider.errorMessage ?? 'Gagal');
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Terjadi kesalahan: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isAllCategories =
        _selectedCategory == FinanceBudgetModel.allCategoriesKey;
    final categoryColor = isAllCategories
        ? AppColors.gradientBlueStart
        : FinanceCategoryModel.getColorForCategory(_selectedCategory);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFCFCFD),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Ubah Budget' : 'Buat Budget Baru',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Color(0xFF64748B), size: 22),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Scrollable Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Kategori (Searchable Dropdown Field)
                    const Text(
                      'Pilih Kategori',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _openCategorySearchPicker,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: categoryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _selectedCategory,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isAllCategories
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF64748B),
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Nominal Target Budget
                    const Text(
                      'Target Nominal Budget (Rp)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Contoh: 1.500.000',
                        hintStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8), // Soft muted placeholder
                        ),
                        prefixIcon: Container(
                          width: 44,
                          alignment: Alignment.center,
                          child: const Text(
                            'Rp',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.gradientBlueEnd,
                            ),
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0), width: 1.1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0), width: 1.1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.gradientBlueEnd, width: 1.4),
                        ),
                      ),
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
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nominal budget wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 3. Periode Budget (Pilihan Chips Gradient Biru)
                    const Text(
                      'Periode Budget',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildPeriodChip('Bulanan', 'monthly'),
                        const SizedBox(width: 8),
                        _buildPeriodChip('Mingguan', 'weekly'),
                        const SizedBox(width: 8),
                        _buildPeriodChip('Harian', 'daily'),
                        const SizedBox(width: 8),
                        _buildPeriodChip('Kustom', 'custom'),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 4. Detail Periode
                    if (_selectedPeriodType == 'monthly') ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFE2E8F0), width: 1.1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Mulai Tiap Tanggal:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                            DropdownButton<int>(
                              value: _monthlyStartDay,
                              underline: const SizedBox(),
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFF64748B),
                                size: 20,
                              ),
                              items: List.generate(28, (i) => i + 1).map((day) {
                                return DropdownMenuItem<int>(
                                  value: day,
                                  child: Text(
                                    'Tanggal $day',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _monthlyStartDay = val;
                                    _recalculateDates();
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ] else if (_selectedPeriodType == 'custom') ...[
                      InkWell(
                        onTap: _pickCustomDateRange,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFE2E8F0), width: 1.1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Rentang Tanggal Kustom',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.date_range_rounded,
                                color: AppColors.gradientBlueEnd,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // 5. Toggle Ulangi Otomatis (Repeat)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFE2E8F0), width: 1.1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ulangi Otomatis (Repeat)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Siklus diperbarui otomatis saat periode berakhir.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _isAutoRenew,
                            activeTrackColor: AppColors.gradientBlueEnd,
                            onChanged: (val) =>
                                setState(() => _isAutoRenew = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 6. Toggle Budget Bersama Pasangan
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFE2E8F0), width: 1.1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Budget Bersama Pasangan',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.favorite_rounded,
                                        size: 13, color: Color(0xFF0088FF)),
                                  ],
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Akumulasikan belanja bersama untuk kategori ini.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _isShared,
                            activeTrackColor: AppColors.gradientBlueEnd,
                            onChanged: (val) =>
                                setState(() => _isShared = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 7. Submit Button (Gradient Biru & Sized Appropriately with No Clipping)
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientBiru,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gradientBlueStart
                                .withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isEditing ? 'Simpan Perubahan' : 'Buat Budget',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                  height: 1.1,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriodType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriodType = value;
            _recalculateDates();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.gradientBiru : null,
            color: isSelected ? null : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.gradientBlueStart.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }
}

/// Searchable Dropdown Modal Bottom Sheet for selecting a category
class _CategorySearchBottomSheet extends StatefulWidget {
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  const _CategorySearchBottomSheet({
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  State<_CategorySearchBottomSheet> createState() =>
      _CategorySearchBottomSheetState();
}

class _CategorySearchBottomSheetState
    extends State<_CategorySearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final query = _searchController.text.trim().toLowerCase();

    final allList = [
      FinanceBudgetModel.allCategoriesKey,
      ...provider.allExpenseCategoryNames,
    ];

    final filtered = query.isEmpty
        ? allList
        : allList.where((cat) => cat.toLowerCase().contains(query)).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFCFCFD),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pilih Kategori',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Color(0xFF64748B), size: 20),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                style: const TextStyle(fontSize: 13.5, color: Color(0xFF1E293B)),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Cari kategori...',
                  hintStyle:
                      const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xFF94A3B8), size: 19),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Color(0xFF94A3B8), size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
          ),

          // Categories List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              itemCount: filtered.length,
              separatorBuilder: (ctx, i) =>
                  const Divider(height: 1, color: Color(0xFFF8FAFC)),
              itemBuilder: (ctx, index) {
                final cat = filtered[index];
                final isSelected = cat == widget.selectedCategory;
                final isAll = cat == FinanceBudgetModel.allCategoriesKey;
                final dotColor = isAll
                    ? AppColors.gradientBlueStart
                    : FinanceCategoryModel.getColorForCategory(cat);

                return InkWell(
                  onTap: () {
                    widget.onSelected(cat);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.gradientBlueEnd.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected || isAll
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? AppColors.gradientBlueEnd
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_rounded,
                            color: AppColors.gradientBlueEnd,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Add Custom Category Option Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () {
                AddCategoryDialog.show(
                  context,
                  isExpense: true,
                  onCategoryAdded: (newCategory) async {
                    await provider.addCustomCategory(newCategory,
                        isExpense: true);
                    widget.onSelected(newCategory);
                    if (context.mounted) Navigator.pop(context);
                  },
                );
              },
              icon: const Icon(Icons.add_rounded,
                  size: 18, color: AppColors.gradientBlueEnd),
              label: const Text(
                'Tambah Kategori Baru',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gradientBlueEnd,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                    color: Color(0xFFBFDBFE), width: 1.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
