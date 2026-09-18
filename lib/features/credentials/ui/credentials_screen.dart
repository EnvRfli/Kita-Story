import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/credential_model.dart';
import '../providers/credential_provider.dart';
import '../widgets/credential_card.dart';
import '../widgets/credential_detail_bottom_sheet.dart';
import 'package:kita_story/core/widgets/bouncy_filter_chip.dart';

class CredentialsHeader extends StatelessWidget {
  const CredentialsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFCFCFD),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF1E293B),
              size: 22,
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              }
            },
          ),
          const Expanded(
            child: Text(
              'Kredensial',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w800,
                fontSize: 19,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class CredentialsScreen extends StatefulWidget {
  const CredentialsScreen({super.key});

  @override
  State<CredentialsScreen> createState() => _CredentialsScreenState();
}

class _CredentialsScreenState extends State<CredentialsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUserProfile?.id;
    final partnerId = auth.partnerProfile?.id;
    if (userId != null) {
      context
          .read<CredentialProvider>()
          .fetchInitialData(userId, partnerId: partnerId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CredentialProvider>();
    final filteredList = provider.filteredCredentials;
    final dynamicCategories = provider.categories.map((c) => c.name).toList();
    if (dynamicCategories.contains('Lainnya')) {
      dynamicCategories.remove('Lainnya');
      dynamicCategories.add('Lainnya');
    }
    final categories = ['Semua', ...dynamicCategories];

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-credential'),
        backgroundColor: const Color(0xFFFF9500),
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Header Bar
            const CredentialsHeader(),

            // 2. Search Field (History screen style)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: _buildSearchField(provider),
            ),

            // 3. Category Filter Tabs / Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.none,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Row(
                children: categories.map((cat) {
                  final isSelected = provider.selectedCategory.toLowerCase() ==
                      cat.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: BouncyFilterChip(
                      label: cat,
                      isSelected: isSelected,
                      onTap: () => provider.setSelectedCategory(cat),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // 4. Credential List Content
            Expanded(
              child: provider.isLoading && provider.credentials.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0088FF),
                        strokeWidth: 2.5,
                      ),
                    )
                  : filteredList.isEmpty
                      ? _buildEmptyView(provider)
                      : RefreshIndicator(
                          color: const Color(0xFF0088FF),
                          onRefresh: () async {
                            final userId = context
                                .read<AuthProvider>()
                                .currentUserProfile
                                ?.id;
                            if (userId != null) {
                              await provider.fetchCredentials(userId);
                            }
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final cred = filteredList[index];
                              return CredentialCard(
                                credential: cred,
                                onTap: () => _openCredentialDetail(cred),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(CredentialProvider provider) {
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
        onChanged: (val) => provider.setSearchQuery(val),
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          hintText: 'Cari data...',
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
                    provider.setSearchQuery('');
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

  Widget _buildEmptyView(CredentialProvider provider) {
    final hasFilter =
        provider.searchQuery.isNotEmpty || provider.selectedCategory != 'Semua';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF0088FF).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'lib/assets/homescreen assets/lock.png',
                width: 55,
                height: 55,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.lock_outline_rounded,
                  size: 44,
                  color: Color(0xFF0088FF),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              hasFilter ? 'Data Tidak Ditemukan' : 'Belum Ada Kredensial',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'Tidak ada kredensial yang cocok dengan kata kunci atau filter terpilih.'
                  : 'Mulai simpan kata sandi, username, rekening, atau catatan rahasiamu dengan aman!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            if (!hasFilter) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => context.push('/add-credential'),
                icon: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 20),
                label: const Text(
                  'Tambah Kredensial',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0088FF),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openCredentialDetail(CredentialModel cred) {
    CredentialDetailBottomSheet.show(context, credential: cred);
  }
}
