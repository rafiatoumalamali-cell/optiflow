import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import '../../widgets/admin/admin_sidebar.dart';
import '../../providers/admin_provider.dart';

class BusinessManagementScreen extends StatefulWidget {
  const BusinessManagementScreen({super.key});

  @override
  State<BusinessManagementScreen> createState() => _BusinessManagementScreenState();
}

class _BusinessManagementScreenState extends State<BusinessManagementScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch global stats to populate business count
      context.read<AdminProvider>().fetchGlobalStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.eco, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            const Text(
              'Business Management',
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textDark),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AdminSidebar(selectedRoute: '/admin/businesses'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BUSINESS MANAGEMENT',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
            ),
            const Text(
              'Registered Businesses',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Oversee registered businesses, verification status, and operational metrics.',
              style: TextStyle(fontSize: 13, color: AppColors.textLight),
            ),
            const SizedBox(height: 20),

            // Search bar
            TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search businesses...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textLight),
                prefixIcon: const Icon(Icons.search, color: AppColors.textLight, size: 18),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 20),

            // Live business list from Firestore
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('businesses')
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _buildEmptyState('Failed to load businesses. Check your connection.');
                }

                final docs = snapshot.data?.docs ?? [];

                final filtered = _searchQuery.isEmpty
                    ? docs
                    : docs.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        final name = (data['name'] as String? ?? '').toLowerCase();
                        final country = (data['country'] as String? ?? '').toLowerCase();
                        return name.contains(_searchQuery) || country.contains(_searchQuery);
                      }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState(_searchQuery.isNotEmpty
                      ? 'No businesses match "$_searchQuery".'
                      : 'No businesses registered yet.');
                }

                return Column(
                  children: filtered.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildBusinessCard(doc.id, data);
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessCard(String docId, Map<String, dynamic> data) {
    final name = data['name'] as String? ?? 'Unknown';
    final country = data['country'] as String? ?? '—';
    final city = data['city'] as String? ?? '—';
    final isVerified = data['is_verified'] == true;
    final plan = data['subscription_plan'] as String? ?? 'Free';
    final initials = name.length >= 2
        ? '${name[0]}${name.split(' ').length > 1 ? name.split(' ')[1][0] : name[1]}'.toUpperCase()
        : name.substring(0, 1).toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isVerified
                                ? AppColors.successGreen.withOpacity(0.1)
                                : AppColors.primaryOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isVerified ? 'VERIFIED' : 'PENDING',
                            style: TextStyle(
                              color: isVerified ? AppColors.successGreen : AppColors.primaryOrange,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$city, $country',
                          style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  plan,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showBusinessDetails(docId, data),
                  icon: const Icon(Icons.visibility_outlined, size: 14),
                  label: const Text('View', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    side: const BorderSide(color: AppColors.primaryGreen),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _toggleVerification(docId, isVerified),
                  icon: Icon(isVerified ? Icons.cancel_outlined : Icons.verified_outlined, size: 14),
                  label: Text(isVerified ? 'Unverify' : 'Verify', style: const TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isVerified ? AppColors.errorRed : AppColors.successGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.business_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _toggleVerification(String docId, bool current) async {
    try {
      await FirebaseFirestore.instance.collection('businesses').doc(docId).update({
        'is_verified': !current,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(!current ? 'Business verified ✓' : 'Verification removed'),
          backgroundColor: !current ? AppColors.successGreen : AppColors.primaryOrange,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to update business'),
          backgroundColor: AppColors.errorRed,
        ));
      }
    }
  }

  void _showBusinessDetails(String docId, Map<String, dynamic> data) {
    final name = data['name'] as String? ?? 'Unknown';
    final country = data['country'] as String? ?? '—';
    final city = data['city'] as String? ?? '—';
    final plan = data['subscription_plan'] as String? ?? 'Free';
    final isVerified = data['is_verified'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(children: [
                Text('$city, $country', style: const TextStyle(color: AppColors.textLight)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isVerified ? AppColors.successGreen.withOpacity(0.1) : AppColors.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(isVerified ? 'VERIFIED' : 'PENDING',
                    style: TextStyle(color: isVerified ? AppColors.successGreen : AppColors.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ]),
              const SizedBox(height: 24),
              _detailRow(Icons.stars_outlined, 'Subscription Plan', plan),
              _detailRow(Icons.location_on_outlined, 'Location', '$city, $country'),
              _detailRow(Icons.business_center_outlined, 'Business Type', data['type'] as String? ?? '—'),
              _detailRow(Icons.monetization_on_outlined, 'Currency', data['currency'] as String? ?? '—'),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: ElevatedButton(
                  onPressed: () { Navigator.pop(context); _toggleVerification(docId, isVerified); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isVerified ? AppColors.errorRed : AppColors.successGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(isVerified ? 'Remove Verification' : 'Verify Business'),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.backgroundGray, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: AppColors.textLight),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ]),
        ],
      ),
    );
  }
}
