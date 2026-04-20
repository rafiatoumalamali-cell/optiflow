import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';
import '../models/subscription_model.dart';
import '../models/plan_model.dart';
import '../utils/logger.dart';

class AdminProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _totalUsers = 0;
  int _totalBusinesses = 0;
  int _totalOptimizations = 0;
  bool _isLoading = false;
  bool _isReportsLoading = false;
  List<ReportModel> _reports = [];
  List<UserModel> _users = [];
  bool _isUsersLoading = false;
  List<SubscriptionModel> _subscriptions = [];
  List<PlanModel> _plans = [];
  bool _isSubscriptionsLoading = false;
  bool _isPlansLoading = false;

  // Recent activity feed
  List<Map<String, dynamic>> _recentActivity = [];
  bool _isActivityLoading = false;

  // Platform settings (Firestore: platform_settings/config)
  Map<String, dynamic> _platformSettings = {};
  bool _isSettingsLoading = false;
  bool _isSavingSettings = false;
  DateTime? _settingsLastUpdated;

  // Analytics: optimization type breakdown & quarterly revenue
  Map<String, int> _optimizationByType = {};
  Map<String, double> _revenueByQuarter = {'Q1': 0, 'Q2': 0, 'Q3': 0, 'Q4': 0};

  int get totalUsers => _totalUsers;
  int get totalBusinesses => _totalBusinesses;
  int get totalOptimizations => _totalOptimizations;
  bool get isLoading => _isLoading;
  bool get isReportsLoading => _isReportsLoading;
  List<ReportModel> get reports => _reports;
  int get reportCount => _reports.length;
  int get pendingReports => _reports.where((r) => r.status.toLowerCase() == 'pending').length;
  int get resolvedReports => _reports.where((r) => r.status.toLowerCase() == 'resolved').length;
  int get inReviewReports => _reports.where((r) => r.status.toLowerCase().contains('review')).length;

  List<UserModel> get users => _users;
  bool get isUsersLoading => _isUsersLoading;
  int get pendingUsers => _users.where((u) => u.verificationStatus == 'pending').length;
  int get approvedUsers => _users.where((u) => u.verificationStatus == 'approved').length;
  int get rejectedUsers => _users.where((u) => u.verificationStatus == 'rejected').length;

  List<SubscriptionModel> get subscriptions => _subscriptions;
  List<PlanModel> get plans => _plans;
  bool get isSubscriptionsLoading => _isSubscriptionsLoading;
  bool get isPlansLoading => _isPlansLoading;
  int get activeSubscriptions => _subscriptions.where((s) => s.status.toLowerCase() == 'active').length;
  int get expiredSubscriptions => _subscriptions.where((s) => s.status.toLowerCase() == 'expired').length;
  double get totalRevenue => _subscriptions.fold(0.0, (sum, s) => sum + s.price);

  // Activity feed
  List<Map<String, dynamic>> get recentActivity => _recentActivity;
  bool get isActivityLoading => _isActivityLoading;

  // Platform settings
  Map<String, dynamic> get platformSettings => _platformSettings;
  bool get isSettingsLoading => _isSettingsLoading;
  bool get isSavingSettings => _isSavingSettings;
  DateTime? get settingsLastUpdated => _settingsLastUpdated;

  // Analytics helpers
  Map<String, int> get optimizationByType => _optimizationByType;
  Map<String, double> get revenueByQuarter => _revenueByQuarter;

  /// Fetches global platform statistics for hub managers.
  Future<void> fetchGlobalStats() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Use Firestore count() queries for efficiency
      final usersCount = await _firestore.collection('users').count().get();
      final businessesCount = await _firestore.collection('businesses').count().get();
      final resultsCount = await _firestore.collection('optimization_results').count().get();

      _totalUsers = usersCount.count ?? 0;
      _totalBusinesses = businessesCount.count ?? 0;
      _totalOptimizations = resultsCount.count ?? 0;
    } catch (e, stack) {
      Logger.error('Admin: Failed to fetch global stats', name: 'AdminProvider', error: e, stackTrace: stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches a breakdown of businesses by country.
  Future<Map<String, int>> getRegionalBreakdown() async {
    Map<String, int> breakdown = {'Niger': 0, 'Nigeria': 0, 'Ghana': 0};
    try {
      final snapshot = await _firestore.collection('businesses').get();
      for (var doc in snapshot.docs) {
        String country = doc.data()['country'] ?? 'Other';
        if (breakdown.containsKey(country)) {
          breakdown[country] = (breakdown[country] ?? 0) + 1;
        }
      }
    } catch (e, stack) {
      Logger.error('Admin: Failed to fetch regional breakdown', name: 'AdminProvider', error: e, stackTrace: stack);
    }
    return breakdown;
  }

  /// Loads the latest admin reports from Firestore.
  Future<void> fetchReports() async {
    _isReportsLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('reports')
          .orderBy('created_at', descending: true)
          .limit(10)
          .get();

      _reports = snapshot.docs.map((doc) => ReportModel.fromDocument(doc)).toList();
    } catch (e, stack) {
      Logger.error('Admin: Failed to fetch reports', name: 'AdminProvider', error: e, stackTrace: stack);
      _reports = [];
    } finally {
      _isReportsLoading = false;
      notifyListeners();
    }
  }

  /// Fetches all users for admin management
  Future<void> fetchUsers() async {
    _isUsersLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('created_at', descending: true)
          .get();

      _users = snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    } catch (e, stack) {
      Logger.error('Admin: Failed to fetch users', name: 'AdminProvider', error: e, stackTrace: stack);
      _users = [];
    } finally {
      _isUsersLoading = false;
      notifyListeners();
    }
  }

  /// Approves a user verification
  Future<bool> approveUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'verification_status': 'approved',
        'is_active': true,
      });
      
      // Update local user list
      final userIndex = _users.indexWhere((u) => u.userId == userId);
      if (userIndex != -1) {
        _users[userIndex] = UserModel(
          userId: _users[userIndex].userId,
          phone: _users[userIndex].phone,
          email: _users[userIndex].email,
          fullName: _users[userIndex].fullName,
          role: _users[userIndex].role,
          businessId: _users[userIndex].businessId,
          createdAt: _users[userIndex].createdAt,
          lastLogin: _users[userIndex].lastLogin,
          isActive: true,
          fcmToken: _users[userIndex].fcmToken,
          sequentialId: _users[userIndex].sequentialId,
          password: _users[userIndex].password,
          mustChangePassword: _users[userIndex].mustChangePassword,
          createdBy: _users[userIndex].createdBy,
          verificationStatus: 'approved',
        );
        notifyListeners();
      }
      
      Logger.info('Admin: User approved', name: 'AdminProvider');
      return true;
    } catch (e, stack) {
      Logger.error('Admin: Failed to approve user', name: 'AdminProvider', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Rejects a user verification
  Future<bool> rejectUser(String userId, String reason) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'verification_status': 'rejected',
        'is_active': false,
        'rejection_reason': reason,
      });
      
      // Update local user list
      final userIndex = _users.indexWhere((u) => u.userId == userId);
      if (userIndex != -1) {
        _users[userIndex] = UserModel(
          userId: _users[userIndex].userId,
          phone: _users[userIndex].phone,
          email: _users[userIndex].email,
          fullName: _users[userIndex].fullName,
          role: _users[userIndex].role,
          businessId: _users[userIndex].businessId,
          createdAt: _users[userIndex].createdAt,
          lastLogin: _users[userIndex].lastLogin,
          isActive: false,
          fcmToken: _users[userIndex].fcmToken,
          sequentialId: _users[userIndex].sequentialId,
          password: _users[userIndex].password,
          mustChangePassword: _users[userIndex].mustChangePassword,
          createdBy: _users[userIndex].createdBy,
          verificationStatus: 'rejected',
        );
        notifyListeners();
      }
      
      Logger.info('Admin: User rejected', name: 'AdminProvider');
      return true;
    } catch (e, stack) {
      Logger.error('Admin: Failed to reject user', name: 'AdminProvider', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Bulk approve users
  Future<int> bulkApproveUsers(List<String> userIds) async {
    int successCount = 0;
    
    for (final userId in userIds) {
      if (await approveUser(userId)) {
        successCount++;
      }
    }
    
    return successCount;
  }

  /// Bulk reject users
  Future<int> bulkRejectUsers(List<String> userIds, String reason) async {
    int successCount = 0;
    
    for (final userId in userIds) {
      if (await rejectUser(userId, reason)) {
        successCount++;
      }
    }
    
    return successCount;
  }

  /// Fetches all subscriptions for admin management
  Future<void> fetchSubscriptions() async {
    _isSubscriptionsLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('subscriptions')
          .orderBy('start_date', descending: true)
          .get();

      _subscriptions = snapshot.docs.map((doc) => SubscriptionModel.fromMap(doc.data())).toList();
    } catch (e, stack) {
      Logger.error('Admin: Failed to fetch subscriptions', name: 'AdminProvider', error: e, stackTrace: stack);
      _subscriptions = [];
    } finally {
      _isSubscriptionsLoading = false;
      notifyListeners();
    }
  }

  /// Fetches all available plans
  Future<void> fetchPlans() async {
    _isPlansLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('plans')
          .orderBy('price')
          .get();

      _plans = snapshot.docs.map((doc) => PlanModel.fromMap(doc.data())).toList();
    } catch (e, stack) {
      Logger.error('Admin: Failed to fetch plans', name: 'AdminProvider', error: e, stackTrace: stack);
      _plans = [];
    } finally {
      _isPlansLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new subscription plan
  Future<bool> createPlan(PlanModel plan) async {
    try {
      await _firestore.collection('plans').doc(plan.planId).set(plan.toMap());
      await fetchPlans(); // Refresh plans list
      Logger.info('Admin: Plan created successfully', name: 'AdminProvider');
      return true;
    } catch (e, stack) {
      Logger.error('Admin: Failed to create plan', name: 'AdminProvider', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Updates an existing subscription plan
  Future<bool> updatePlan(PlanModel plan) async {
    try {
      await _firestore.collection('plans').doc(plan.planId).update(plan.toMap());
      await fetchPlans(); // Refresh plans list
      Logger.info('Admin: Plan updated successfully', name: 'AdminProvider');
      return true;
    } catch (e, stack) {
      Logger.error('Admin: Failed to update plan', name: 'AdminProvider', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Deletes a subscription plan
  Future<bool> deletePlan(String planId) async {
    try {
      await _firestore.collection('plans').doc(planId).delete();
      await fetchPlans(); // Refresh plans list
      Logger.info('Admin: Plan deleted successfully', name: 'AdminProvider');
      return true;
    } catch (e, stack) {
      Logger.error('Admin: Failed to delete plan', name: 'AdminProvider', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Updates a user's subscription
  Future<bool> updateUserSubscription(String businessId, String planId) async {
    try {
      // Get plan details
      final planDoc = await _firestore.collection('plans').doc(planId).get();
      if (!planDoc.exists) return false;
      
      final plan = PlanModel.fromMap(planDoc.data()!);
      
      // Create new subscription
      final subscription = SubscriptionModel(
        subscriptionId: 'sub_${DateTime.now().millisecondsSinceEpoch}',
        businessId: businessId,
        plan: plan.name,
        price: plan.price,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)), // Monthly subscription
        status: 'Active',
      );

      await _firestore.collection('subscriptions').doc(subscription.subscriptionId).set(subscription.toMap());
      await fetchSubscriptions(); // Refresh subscriptions list
      Logger.info('Admin: User subscription updated successfully', name: 'AdminProvider');
      return true;
    } catch (e, stack) {
      Logger.error('Admin: Failed to update user subscription', name: 'AdminProvider', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Cancels a subscription
  Future<bool> cancelSubscription(String subscriptionId) async {
    try {
      await _firestore.collection('subscriptions').doc(subscriptionId).update({
        'status': 'Cancelled',
        'end_date': Timestamp.fromDate(DateTime.now()),
      });
      await fetchSubscriptions(); // Refresh subscriptions list
      Logger.info('Admin: Subscription cancelled successfully', name: 'AdminProvider');
      return true;
    } catch (e, stack) {
      Logger.error('Admin: Failed to cancel subscription', name: 'AdminProvider', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Updates a report's status in Firestore and refreshes the local list.
  Future<bool> updateReportStatus(String reportId, String newStatus, {String? resolvedBy}) async {
    try {
      final updates = <String, dynamic>{'status': newStatus};
      if (resolvedBy != null) updates['resolved_by'] = resolvedBy;
      await _firestore.collection('reports').doc(reportId).update(updates);

      // Update in-memory list immediately
      final idx = _reports.indexWhere((r) => r.reportId == reportId);
      if (idx != -1) {
        final old = _reports[idx];
        _reports[idx] = ReportModel(
          reportId: old.reportId,
          userId: old.userId,
          type: old.type,
          description: old.description,
          status: newStatus,
          createdAt: old.createdAt,
          resolvedBy: resolvedBy ?? old.resolvedBy,
        );
        notifyListeners();
      }
      Logger.info('Admin: Report $reportId status updated to $newStatus', name: 'AdminProvider');
      return true;
    } catch (e, stack) {
      Logger.error('Admin: Failed to update report status', name: 'AdminProvider', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Initialize default plans if none exist
  Future<void> initializeDefaultPlans() async {
    try {
      final existingPlans = await _firestore.collection('plans').limit(1).get();
      if (existingPlans.docs.isNotEmpty) return; // Plans already exist

      final defaultPlans = [
        PlanModel(
          planId: 'free',
          name: 'FREE',
          price: 0.0,
          features: ['Up to 5 Deliveries', 'Basic Route Tracking', 'Email Support'],
          maxUsers: 5,
          maxDeliveries: 50,
          hasAdvancedFeatures: false,
          hasPrioritySupport: false,
          description: 'Perfect for small businesses starting out',
        ),
        PlanModel(
          planId: 'pro',
          name: 'PRO',
          price: 5000.0,
          features: ['Unlimited Deliveries', 'Advanced Fleet Insights', 'Real-time GPS Monitoring', '24/7 Priority Support'],
          maxUsers: 50,
          maxDeliveries: 1000,
          hasAdvancedFeatures: true,
          hasPrioritySupport: true,
          isPopular: true,
          description: 'Ideal for growing businesses with fleet management needs',
        ),
        PlanModel(
          planId: 'enterprise',
          name: 'ENTERPRISE',
          price: 15000.0,
          features: ['Custom Fleet Integration', 'Multi-country Logistics', 'Dedicated Account Manager', 'API Access'],
          maxUsers: -1, // Unlimited
          maxDeliveries: -1, // Unlimited
          hasAdvancedFeatures: true,
          hasPrioritySupport: true,
          description: 'Comprehensive solution for large enterprises',
        ),
      ];

      for (final plan in defaultPlans) {
        await _firestore.collection('plans').doc(plan.planId).set(plan.toMap());
      }

      await fetchPlans();
      Logger.info('Admin: Default plans initialized successfully', name: 'AdminProvider');
    } catch (e, stack) {
      Logger.error('Admin: Failed to initialize default plans', name: 'AdminProvider', error: e, stackTrace: stack);
    }
  }

  // ---------------------------------------------------------------------------
  // Recent Activity Feed
  // ---------------------------------------------------------------------------

  /// Fetches the 5 most recent events across users, businesses, and results.
  Future<void> fetchRecentActivity() async {
    _isActivityLoading = true;
    notifyListeners();

    try {
      final List<Map<String, dynamic>> events = [];

      // Latest 3 users
      final usersSnap = await _firestore
          .collection('users')
          .orderBy('created_at', descending: true)
          .limit(3)
          .get();
      for (final doc in usersSnap.docs) {
        final data = doc.data();
        final ts = data['created_at'];
        events.add({
          'text': 'New user registered: ${data['full_name'] ?? data['phone'] ?? 'Unknown'}',
          'icon': 'person',
          'time': ts is Timestamp ? ts.toDate() : DateTime.now(),
        });
      }

      // Latest 3 businesses
      final bizSnap = await _firestore
          .collection('businesses')
          .orderBy('created_at', descending: true)
          .limit(3)
          .get();
      for (final doc in bizSnap.docs) {
        final data = doc.data();
        final ts = data['created_at'];
        events.add({
          'text': 'New business registered: ${data['name'] ?? 'Unknown'}',
          'icon': 'business',
          'time': ts is Timestamp ? ts.toDate() : DateTime.now(),
        });
      }

      // Latest 3 optimization results
      final resultsSnap = await _firestore
          .collection('optimization_results')
          .orderBy('created_at', descending: true)
          .limit(3)
          .get();
      for (final doc in resultsSnap.docs) {
        final data = doc.data();
        final ts = data['created_at'];
        events.add({
          'text': '${data['type'] ?? 'Optimization'} completed',
          'icon': 'bolt',
          'time': ts is Timestamp ? ts.toDate() : DateTime.now(),
        });
      }

      // Sort by time descending, keep top 5
      events.sort((a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));
      _recentActivity = events.take(5).toList();
    } catch (e, stack) {
      Logger.error('Admin: Failed to fetch recent activity', name: 'AdminProvider', error: e, stackTrace: stack);
      _recentActivity = [];
    } finally {
      _isActivityLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Analytics helpers
  // ---------------------------------------------------------------------------

  /// Fetches optimization type breakdown from Firestore.
  Future<void> fetchOptimizationBreakdown() async {
    try {
      final snap = await _firestore.collection('optimization_results').get();
      final Map<String, int> counts = {
        'Product Mix': 0,
        'Transport': 0,
        'Route': 0,
        'Budget': 0,
      };
      for (final doc in snap.docs) {
        final type = (doc.data()['type'] as String? ?? '').trim();
        if (counts.containsKey(type)) {
          counts[type] = counts[type]! + 1;
        } else {
          // Fuzzy match
          final lowerType = type.toLowerCase();
          if (lowerType.contains('product')) counts['Product Mix'] = counts['Product Mix']! + 1;
          else if (lowerType.contains('transport')) counts['Transport'] = counts['Transport']! + 1;
          else if (lowerType.contains('route')) counts['Route'] = counts['Route']! + 1;
          else if (lowerType.contains('budget')) counts['Budget'] = counts['Budget']! + 1;
        }
      }
      _optimizationByType = counts;
      notifyListeners();
    } catch (e, stack) {
      Logger.error('Admin: Failed to fetch optimization breakdown', name: 'AdminProvider', error: e, stackTrace: stack);
    }
  }

  /// Computes quarterly revenue from subscriptions in the current year.
  Future<void> fetchRevenueByQuarter() async {
    try {
      if (_subscriptions.isEmpty) await fetchSubscriptions();
      final now = DateTime.now();
      final Map<String, double> qRevenue = {'Q1': 0, 'Q2': 0, 'Q3': 0, 'Q4': 0};
      for (final sub in _subscriptions) {
        if (sub.startDate.year == now.year) {
          final month = sub.startDate.month;
          if (month <= 3) qRevenue['Q1'] = qRevenue['Q1']! + sub.price;
          else if (month <= 6) qRevenue['Q2'] = qRevenue['Q2']! + sub.price;
          else if (month <= 9) qRevenue['Q3'] = qRevenue['Q3']! + sub.price;
          else qRevenue['Q4'] = qRevenue['Q4']! + sub.price;
        }
      }
      _revenueByQuarter = qRevenue;
      notifyListeners();
    } catch (e, stack) {
      Logger.error('Admin: Failed to compute revenue by quarter', name: 'AdminProvider', error: e, stackTrace: stack);
    }
  }

  // ---------------------------------------------------------------------------
  // Platform Settings
  // ---------------------------------------------------------------------------

  static const _defaultSettings = <String, dynamic>{
    'exchange_rates': {'NGN': 1.24, 'GHS': 0.021},
    'optimization': {'route_timeout_s': 45, 'max_fleet_density': 150},
    'integrations': {
      'sms_provider': 'Twilio West Africa',
      'sms_status': 'Connected',
      'email_provider': 'SendGrid API',
      'email_daily_limit': 50000,
      'email_daily_used': 0,
    },
  };

  /// Fetches the platform_settings/config document (creates defaults if missing).
  Future<void> fetchPlatformSettings() async {
    _isSettingsLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore.collection('platform_settings').doc('config').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _platformSettings = data;
        final ts = data['last_updated'];
        _settingsLastUpdated = ts is Timestamp ? ts.toDate() : null;
      } else {
        // Bootstrap with defaults
        await _firestore.collection('platform_settings').doc('config').set({
          ..._defaultSettings,
          'last_updated': Timestamp.now(),
        });
        _platformSettings = Map<String, dynamic>.from(_defaultSettings);
        _settingsLastUpdated = DateTime.now();
      }
    } catch (e, stack) {
      Logger.error('Admin: Failed to fetch platform settings', name: 'AdminProvider', error: e, stackTrace: stack);
      _platformSettings = Map<String, dynamic>.from(_defaultSettings);
    } finally {
      _isSettingsLoading = false;
      notifyListeners();
    }
  }

  /// Saves updated platform settings to Firestore.
  Future<bool> savePlatformSettings(Map<String, dynamic> settings) async {
    _isSavingSettings = true;
    notifyListeners();

    try {
      final payload = {
        ...settings,
        'last_updated': Timestamp.now(),
      };
      await _firestore.collection('platform_settings').doc('config').set(payload, SetOptions(merge: true));
      _platformSettings = {..._platformSettings, ...settings};
      _settingsLastUpdated = DateTime.now();
      Logger.info('Admin: Platform settings saved', name: 'AdminProvider');
      return true;
    } catch (e, stack) {
      Logger.error('Admin: Failed to save platform settings', name: 'AdminProvider', error: e, stackTrace: stack);
      return false;
    } finally {
      _isSavingSettings = false;
      notifyListeners();
    }
  }

  /// Updates a user's information in Firestore
  Future<bool> updateUser(UserModel updatedUser) async {
    try {
      await _firestore.collection('users').doc(updatedUser.userId).update(updatedUser.toMap());
      
      // Update local users list if it exists
      final index = _users.indexWhere((user) => user.userId == updatedUser.userId);
      if (index != -1) {
        _users[index] = updatedUser;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      Logger.error('Admin: Failed to update user', name: 'AdminProvider', error: e);
      return false;
    }
  }

  /// Toggles a user's active status
  Future<bool> toggleUserStatus(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;
      
      final currentStatus = userDoc.data()?['is_active'] ?? false;
      final newStatus = !currentStatus;
      
      await _firestore.collection('users').doc(userId).update({
        'is_active': newStatus,
        'updated_at': Timestamp.now(),
      });
      
      // Update local users list if it exists
      final index = _users.indexWhere((user) => user.userId == userId);
      if (index != -1) {
        _users[index] = _users[index].copyWith(isActive: newStatus);
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      Logger.error('Admin: Failed to toggle user status', name: 'AdminProvider', error: e);
      return false;
    }
  }

  /// Deletes a user from Firestore
  Future<bool> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      _users.removeWhere((user) => user.userId == userId);
      notifyListeners();
      Logger.info('Admin: User deleted successfully', name: 'AdminProvider');
      return true;
    } catch (e, stack) {
      Logger.error('Admin: Failed to delete user', name: 'AdminProvider', error: e, stackTrace: stack);
      return false;
    }
  }
}
