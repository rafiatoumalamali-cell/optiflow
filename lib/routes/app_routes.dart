import 'package:flutter/material.dart';
import '../screens/auth/01_onboarding_screen.dart';
import '../screens/auth/01b_auth_choice_screen.dart';
import '../screens/auth/02_phone_auth_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/03_otp_verification_screen.dart';
import '../screens/auth/04_role_selection_screen.dart';
import '../screens/auth/05_business_setup_screen.dart';
import '../screens/auth/02a_terms_screen.dart';
import '../screens/auth/02b_privacy_screen.dart';
import '../screens/auth/force_password_change_screen.dart';
import '../screens/auth/security_questions_setup_screen.dart';
import '../screens/auth/security_password_reset_screen.dart';
import '../screens/core/06_home_dashboard_screen.dart';
import '../screens/core/07_saved_results_screen.dart';
import '../screens/core/08_profile_screen.dart';
import '../screens/driver/driver_management_screen.dart';
import '../screens/product_mix/09_product_list_screen.dart';
import '../screens/product_mix/10_add_product_screen.dart';
import '../screens/product_mix/11_resources_constraints_screen.dart';
import '../screens/product_mix/12_product_mix_results_screen.dart';
import '../screens/transport/13_transport_input_screen.dart';
import '../screens/transport/14_add_location_screen.dart';
import '../screens/transport/15_transport_results_screen.dart';
import '../screens/transport/transport_cost_optimization_screen.dart';
import '../screens/route/16_route_planner_screen.dart';
import '../screens/route/17_route_results_screen.dart';
import '../screens/route/18_driver_navigation_screen.dart';
import '../screens/route/19_delivery_points_map_screen.dart';
import '../screens/route/20_turn_by_turn_navigation_screen.dart';
import '../screens/route/21_traffic_visualization_screen.dart';
import '../screens/route/19_proof_of_delivery_screen.dart';
import '../screens/budget/20_budget_input_screen.dart';
import '../screens/budget/21_budget_results_screen.dart';
import '../screens/driver/22_driver_home_screen.dart';
import '../screens/debug/firebase_verification_screen.dart';
import '../screens/debug/auth_integration_test_screen.dart';
import '../screens/debug/environment_verification_screen.dart';
import '../screens/driver/23_route_assignment_screen.dart';
import '../screens/settings/24_settings_screen.dart';
import '../screens/settings/25_notification_screen.dart';
import '../screens/settings/26_help_screen.dart';
import '../screens/settings/27_support_screen.dart';
import '../screens/admin/29_admin_dashboard_screen.dart';
import '../screens/admin/30_user_management_screen.dart';
import '../screens/admin/31_business_management_screen.dart';
import '../screens/admin/32_subscription_management_screen.dart';
import '../screens/admin/33_analytics_overview_screen.dart';
import '../screens/admin/34_reports_issues_screen.dart';
import '../screens/admin/35_admin_settings_screen.dart';
import '../screens/admin/36_broadcast_notification_screen.dart';
import '../screens/admin/admin_password_reset.dart';
import '../screens/admin/admin_emergency_reset.dart';
import '../screens/admin/role_change_screen.dart';

class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String authChoice = '/auth-choice';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String adminPasswordReset = '/admin-password-reset';
  static const String adminEmergencyReset = '/admin-emergency-reset';
  static const String roleChange = '/role-change';
  static const String phoneAuth = '/phone-auth';
  static const String otpVerification = '/otp-verification';
  static const String roleSelection = '/role-selection';
  static const String businessSetup = '/business-setup';
  static const String termsOfService = '/terms';
  static const String privacyPolicy = '/privacy';
  static const String forcePasswordChange = '/force-password-change';
  static const String securityQuestionsSetup = '/security-questions-setup';
  static const String securityPasswordReset = '/security-password-reset';
  static const String homeDashboard = '/home';
  static const String savedResults = '/saved-results';
  static const String profile = '/profile';
  static const String driverManagement = '/driver-management';
  
  // Product Mix Module
  static const String productList = '/product-list';
  static const String addProduct = '/add-product';
  static const String resourceConstraints = '/resource-constraints';
  static const String productMixResults = '/product-mix-results';

  // Transport Module
  static const String transportInput = '/transport-input';
  static const String addLocation = '/add-location';
  static const String transportResults = '/transport-results';
  static const String transportCostOptimization = '/transport-cost-optimization';

  // Route Module
  static const String routePlanner = '/route-planner';
  static const String routeResults = '/route-results';
  static const String driverNavigation = '/driver-navigation';
  static const String deliveryPointsMap = '/delivery-points-map';
  static const String turnByTurnNavigation = '/turn-by-turn-navigation';
  static const String trafficVisualization = '/traffic-visualization';
  static const String proofOfDelivery = '/proof-of-delivery';

  // Budget Module
  static const String budgetInput = '/budget-input';
  static const String budgetResults = '/budget-results';

  // Driver Module
  static const String driverHome = '/driver-home';
  static const String routeAssignment = '/route-assignment';

  // Settings & Support
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String help = '/help';
  static const String support = '/support';

  // Admin Module
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminBusinesses = '/admin/businesses';
  static const String adminSubscriptions = '/admin/subscriptions';
  static const String adminSettings = '/admin/settings';
  static const String adminBroadcast = '/admin/broadcast';
  static const String adminAnalytics = '/admin/analytics';
  static const String adminReports = '/admin/reports';

  // Debug Routes
  static const String firebaseVerification = '/debug/firebase-verification';
  static const String authIntegrationTest = '/debug/auth-integration-test';
  static const String environmentVerification = '/debug/environment-verification';

  static Map<String, WidgetBuilder> get routes => {
    onboarding: (context) => const OnboardingScreen(),
    authChoice: (context) => const AuthChoiceScreen(),
    login: (context) => const LoginScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    adminPasswordReset: (context) => const AdminPasswordResetScreen(),
    adminEmergencyReset: (context) => const AdminEmergencyResetScreen(),
    roleChange: (context) => const RoleChangeScreen(),
    phoneAuth: (context) => const PhoneAuthScreen(),
    otpVerification: (context) => const OtpVerificationScreen(),
    roleSelection: (context) => const RoleSelectionScreen(),
    businessSetup: (context) => const BusinessSetupScreen(),
    termsOfService: (context) => const TermsOfServiceScreen(),
    privacyPolicy: (context) => const PrivacyPolicyScreen(),
    forcePasswordChange: (context) => const ForcePasswordChangeScreen(),
    securityQuestionsSetup: (context) => const SecurityQuestionsSetupScreen(),
    securityPasswordReset: (context) => const SecurityPasswordResetScreen(),
    homeDashboard: (context) => const HomeDashboardScreen(),
    savedResults: (context) => const SavedResultsScreen(),
    profile: (context) => const ProfileScreen(),
    driverManagement: (context) => const DriverManagementScreen(),
    
    productList: (context) => const ProductListScreen(),
    addProduct: (context) => const AddProductScreen(),
    resourceConstraints: (context) => const ResourceConstraintsScreen(),
    productMixResults: (context) => const ProductMixResultsScreen(),

    transportInput: (context) => const TransportInputScreen(),
    addLocation: (context) => const AddLocationScreen(),
    transportResults: (context) => const TransportResultsScreen(),
    transportCostOptimization: (context) => const TransportCostOptimizationScreen(),

    routePlanner: (context) => const RoutePlannerScreen(),
    routeResults: (context) => const RouteResultsScreen(),
    driverNavigation: (context) => const DriverNavigationScreen(),
    deliveryPointsMap: (context) => const DeliveryPointsMapScreen(),
    turnByTurnNavigation: (context) => const TurnByTurnNavigationScreen(),
    trafficVisualization: (context) => const TrafficVisualizationScreen(),
    proofOfDelivery: (context) => const ProofOfDeliveryScreen(),

    budgetInput: (context) => const BudgetInputScreen(),
    budgetResults: (context) => const BudgetResultsScreen(),

    driverHome: (context) => const DriverHomeScreen(),
    routeAssignment: (context) => const RouteAssignmentScreen(),

    settings: (context) => const SettingsScreen(),
    notifications: (context) => const NotificationScreen(),
    help: (context) => const HelpScreen(),
    support: (context) => const SupportScreen(),

    adminDashboard: (context) => const AdminDashboardScreen(),
    adminUsers: (context) => const UserManagementScreen(),
    adminBusinesses: (context) => const BusinessManagementScreen(),
    adminSubscriptions: (context) => const SubscriptionManagementScreen(),
    adminAnalytics: (context) => const AnalyticsOverviewScreen(),
    adminReports: (context) => const ReportsIssuesScreen(),
    adminSettings: (context) => const AdminSettingsScreen(),
    adminBroadcast: (context) => const BroadcastNotificationScreen(),
    
    // Debug Routes
    firebaseVerification: (context) => const FirebaseVerificationScreen(),
    authIntegrationTest: (context) => const AuthIntegrationTestScreen(),
    environmentVerification: (context) => const EnvironmentVerificationScreen(),
  };
}