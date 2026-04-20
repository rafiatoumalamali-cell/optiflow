import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:workmanager/workmanager.dart';

import 'utils/constants.dart';
import 'utils/logger.dart';
import 'utils/production_config.dart';

import 'screens/splash_screen.dart';
import 'services/shared_preferences_service.dart';
import 'utils/app_theme.dart';
import 'routes/app_routes.dart';
import 'providers/auth_provider.dart';
import 'providers/business_provider.dart';
import 'providers/product_provider.dart';
import 'providers/transport_provider.dart';
import 'providers/transport_cost_provider.dart';
import 'providers/route_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/optimization_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'providers/currency_provider.dart';
import 'providers/admin_provider.dart';
import 'utils/app_localizations.dart';
import 'services/sync/sync_queue_service.dart';
import 'services/firebase/firebase_messaging_service.dart';
import 'services/firebase_verification_service.dart';
import 'widgets/common/offline_banner.dart';

// Top-level function for Workmanager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await Firebase.initializeApp();
      final syncService = SyncQueueService();
      await syncService.processQueue();
      return Future.value(true);
    } catch (e, stack) {
      ProductionErrorHandler.handleError(e, stack, context: 'Workmanager sync');
      return Future.value(false);
    }
  });
}

// Background handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  ProductionConfig.log('FCM: Handling background message: ${message.messageId}', level: LogLevel.info);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize production configuration first
  ProductionConfig.initialize();
  
  await Firebase.initializeApp();
  
  // Quick Firebase verification
  final firebaseOk = await FirebaseVerificationService.quickVerify();
  if (!firebaseOk) {
    ProductionConfig.log('Firebase initialization failed', level: LogLevel.error);
  }
  
  await SharedPreferencesService.init(); 

  // Initialize FCM
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Workmanager for background sync
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: ProductionConfig.isDevelopment,
  );

  // Register periodic sync task (runs every syncIntervalMinutes on Android)
  await Workmanager().registerPeriodicTask(
    "1",
    "syncTask",
    frequency: Duration(minutes: syncIntervalMinutes),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BusinessProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => TransportProvider()),
        ChangeNotifierProvider(create: (_) => TransportCostProvider()),
        ChangeNotifierProvider(create: (_) => RouteProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => OptimizationProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: const OptiFlowApp(),
    ),
  );
}

class OptiFlowApp extends StatefulWidget {
  const OptiFlowApp({super.key});

  @override
  State<OptiFlowApp> createState() => _OptiFlowAppState();
}

class _OptiFlowAppState extends State<OptiFlowApp> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to safely access Provider context
    // after the first frame is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFCM();
    });
  }

  void _initializeFCM() async {
    if (!mounted) return;
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    await FirebaseMessagingService().initialize(notificationProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, child) {
        return MaterialApp(
          title: ProductionConfig.getAppTitle(),
          debugShowCheckedModeBanner: ProductionConfig.enableDebugBanners,
          theme: AppTheme.lightTheme,
          locale: languageProvider.locale,
          localizationsDelegates: [
            const AppLocalizationsDelegate(),
            HausaMaterialLocalizationsDelegate,
            HausaCupertinoLocalizationsDelegate,
            HausaWidgetsLocalizationsDelegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('fr'),
            Locale('ha'),
          ],
          home: const SplashScreen(),
          routes: AppRoutes.routes,
          builder: (context, child) {
            return Column(
              children: [
                const OfflineBanner(),
                Expanded(child: child ?? const SizedBox.shrink()),
              ],
            );
          },
        );
      },
    );
  }
}
