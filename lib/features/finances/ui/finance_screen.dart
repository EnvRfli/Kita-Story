import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/finance_provider.dart';
import '../widgets/finance_balance_card.dart';
import '../widgets/finance_summary_row.dart';
import '../widgets/finance_category_donut_chart.dart';
import '../widgets/transaction_card.dart';
import '../widgets/bottom_sheets/add_transaction_bottom_sheet.dart';
import '../widgets/bottom_sheets/transaction_detail_bottom_sheet.dart';

class FinanceScreen extends StatefulWidget {
  final String? targetUserId;
  final bool isPartnerMode;

  const FinanceScreen({
    super.key,
    this.targetUserId,
    this.isPartnerMode = false,
  });

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final auth = context.read<AuthProvider>();
    final partnerId = auth.partnerProfile?.id;
    final uid = widget.targetUserId ?? auth.currentUserProfile?.id;

    context.read<FinanceProvider>().fetchTransactions(
          targetUserId: uid,
          partnerId: partnerId,
        );
  }

  void _openAddTransaction() {
    AddTransactionBottomSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final transactions = provider.transactions;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Unified Standard Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              color: const Color(0xFFFCFCFD),
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
                  const Expanded(
                    child: Text(
                      'Keuangan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Symmetrical balancer
                ],
              ),
            ),

            // 2. Scrollable Body
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _loadData(),
                color: const Color(0xFFFF7A00),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // A. Saldo Keseluruhan Card (Purple Gradient 3D)
                      FinanceBalanceCard(
                        totalBalance: provider.totalBalance,
                        netSavings: provider.currentMonthNetSavings,
                        isBalanceVisible: provider.isBalanceVisible,
                        onToggleVisibility: () =>
                            provider.toggleBalanceVisibility(),
                      ),
                      const SizedBox(height: 16),

                      // B. Pemasukan & Pengeluaran Summary Row
                      FinanceSummaryRow(
                        income: provider.currentMonthIncome,
                        expense: provider.currentMonthExpense,
                        isBalanceVisible: provider.isBalanceVisible,
                      ),
                      const SizedBox(height: 18),

                      // C. Kategori Pengeluaran Donut Chart
                      FinanceCategoryDonutChart(
                        breakdown: provider.categoryExpenseBreakdown,
                      ),
                      const SizedBox(height: 22),

                      // D. Riwayat Transaksi Header
                      const Text(
                        'Riwayat Transaksi',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // E. List of Transactions
                      if (provider.isLoading && transactions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFFFF7A00),
                            ),
                          ),
                        )
                      else if (transactions.isEmpty)
                        _buildEmptyTransactionState()
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final item = transactions[index];
                            return TransactionCard(
                              transaction: item,
                              isBalanceVisible: provider.isBalanceVisible,
                              onTap: () {
                                TransactionDetailBottomSheet.show(
                                  context,
                                  transaction: item,
                                );
                              },
                            );
                          },
                        ),

                      // Bottom spacing for Floating Action Button
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // 3. Floating Action Button (+)
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9500).withValues(alpha: 0.42),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openAddTransaction,
            customBorder: const CircleBorder(),
            child: Ink(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFB800),
                    Color(0xFFFF7A00),
                  ],
                ),
              ),
              child: const Icon(
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

  Widget _buildEmptyTransactionState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF7ED),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFFFF8A00),
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada transaksi',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ketuk tombol (+) di bawah untuk mencatat pemasukan atau pengeluaran pertama Anda',
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
