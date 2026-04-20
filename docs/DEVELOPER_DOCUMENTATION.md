# OptiFlow Developer Documentation

## 📚 Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [API Documentation](#api-documentation)
4. [Firebase Integration](#firebase-integration)
5. [Security Implementation](#security-implementation)
6. [Development Setup](#development-setup)
7. [Testing Guidelines](#testing-guidelines)
8. [Deployment Guide](#deployment-guide)
9. [Troubleshooting](#troubleshooting)

---

## 🎯 Project Overview

OptiFlow is a comprehensive logistics optimization platform designed for West African businesses. The application provides intelligent route planning, production optimization, budget management, and real-time fleet tracking with offline capabilities.

### **Core Features**
- **Route Optimization**: AI-powered multi-stop route planning
- **Production Management**: Resource allocation and cost optimization
- **Fleet Tracking**: Real-time vehicle and driver monitoring
- **Budget Planning**: Intelligent budget allocation across departments
- **Cross-Border Support**: Optimized routes for West African corridors
- **Offline Capabilities**: Downloadable maps for poor connectivity areas

### **Technology Stack**
- **Frontend**: Flutter 3.16+ with Dart 3.2+
- **State Management**: Provider pattern for reactive state
- **Backend**: FastAPI with Python 3.9+
- **Database**: Firebase Firestore (NoSQL real-time)
- **Authentication**: Firebase Auth with phone-based login
- **Maps**: Google Maps API with traffic and routing
- **Storage**: Firebase Storage for file management
- **Notifications**: Firebase Cloud Messaging (FCM)

---

## 🏗️ Architecture

### **Project Structure**
```
lib/
├── config/                 # Environment configurations
│   ├── development_environment_config.dart
│   ├── staging_environment_config.dart
│   ├── production_environment_config.dart
│   └── environment_manager.dart
├── models/                  # Data models
│   ├── user_model.dart
│   ├── business_model.dart
│   ├── route_model.dart
│   └── product_model.dart
├── providers/                # State management
│   ├── auth_provider.dart
│   ├── route_provider.dart
│   └── analytics_provider.dart
├── screens/                 # UI screens
│   ├── auth/
│   ├── route/
│   ├── budget/
│   └── admin/
├── services/                # Business logic
│   ├── api_service.dart
│   ├── route_service.dart
│   ├── auth_service.dart
│   └── sync_service.dart
├── utils/                   # Utilities
│   ├── logger.dart
│   ├── input_validation.dart
│   └── exception_handler.dart
├── widgets/                 # Reusable UI components
│   ├── common/
│   └── forms/
└── routes/                  # Navigation
    └── app_routes.dart
```

### **State Management Pattern**
OptiFlow uses the Provider pattern for state management:

```dart
// Provider example
class RouteProvider extends ChangeNotifier {
  final List<RouteModel> _routes = [];
  
  List<RouteModel> get routes => _routes;
  
  Future<void> loadRoutes() async {
    // Load routes from API
    final routes = await _routeService.getRoutes();
    _routes.clear();
    _routes.addAll(routes);
    notifyListeners();
  }
}

// Usage in widget
Consumer<RouteProvider>(
  builder: (context, provider, child) {
    return ListView(
      children: provider.routes.map((route) => RouteCard(route: route)).toList(),
    );
  },
)
```

---

## 🔌 API Documentation

### **Authentication API**

#### **Phone Authentication**
```dart
// Send OTP
Future<bool> sendOTP(String phoneNumber) async {
  try {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        // Handle error
      },
      codeSent: (String verificationId) {
        // Save verificationId for OTP verification
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Handle timeout
      },
    );
    return true;
  } catch (e) {
    return false;
  }
}

// Verify OTP
Future<bool> verifyOTP(String verificationId, String otp) async {
  try {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );
    
    await FirebaseAuth.instance.signInWithCredential(credential);
    return true;
  } catch (e) {
    return false;
  }
}
```

#### **User Management**
```dart
// Create user
Future<UserModel> createUser({
  required String phoneNumber,
  required String name,
  required String email,
  required String role,
  required String businessId,
}) async {
  final user = UserModel(
    id: uuid.v4(),
    phoneNumber: phoneNumber,
    name: name,
    email: email,
    role: role,
    businessId: businessId,
    createdAt: DateTime.now(),
    isActive: true,
  );
  
  await _firestore.collection('users').doc(user.id).set(user.toMap());
  return user;
}

// Update user
Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
  await _firestore.collection('users').doc(userId).update(updates);
}

// Get user by ID
Future<UserModel?> getUserById(String userId) async {
  final doc = await _firestore.collection('users').doc(userId).get();
  return doc.exists ? UserModel.fromMap(doc.data()!) : null;
}
```

### **Route Management API**

#### **Create Route**
```dart
Future<RouteModel> createRoute({
  required String name,
  required String businessId,
  required List<LocationModel> stops,
  required String createdBy,
}) async {
  final route = RouteModel(
    id: uuid.v4(),
    name: name,
    businessId: businessId,
    stops: stops,
    status: 'active',
    createdAt: DateTime.now(),
    createdBy: createdBy,
  );
  
  await _firestore.collection('routes').doc(route.id).set(route.toMap());
  return route;
}

#### **Optimize Route**
```dart
Future<OptimizedRoute> optimizeRoute({
  required List<LocationModel> stops,
  required String vehicleType,
  required OptimizationPreferences preferences,
}) async {
  try {
    final response = await http.post(
      Uri.parse('${EnvironmentConfig.apiBaseUrl}/optimize'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _getAuthToken()}',
      },
      body: jsonEncode({
        'stops': stops.map((stop) => stop.toMap()).toList(),
        'vehicle_type': vehicleType,
        'preferences': preferences.toMap(),
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return OptimizedRoute.fromMap(data);
    } else {
      throw Exception('Route optimization failed');
    }
  } catch (e) {
    throw Exception('Route optimization error: $e');
  }
}
```

### **Product Management API**

#### **Create Product**
```dart
Future<ProductModel> createProduct({
  required String name,
  required String businessId,
  required double price,
  required String unitType,
  required Map<String, dynamic> resourceRequirements,
}) async {
  final product = ProductModel(
    id: uuid.v4(),
    name: name,
    businessId: businessId,
    price: price,
    unitType: unitType,
    resourceRequirements: resourceRequirements,
    createdAt: DateTime.now(),
  );
  
  await _firestore.collection('products').doc(product.id).set(product.toMap());
  return product;
}

#### **Get Products by Business**
```dart
Future<List<ProductModel>> getProductsByBusiness(String businessId) async {
  final query = await _firestore
      .collection('products')
      .where('businessId', isEqualTo: businessId)
      .orderBy('createdAt', descending: true)
      .get();
  
  return query.docs.map((doc) => ProductModel.fromMap(doc.data()!)).toList();
}
```

### **Budget Management API**

#### **Create Budget**
```dart
Future<BudgetModel> createBudget({
  required String businessId,
  required double totalAmount,
  required Map<String, double> departmentAllocation,
  required Map<String, dynamic> constraints,
}) async {
  final budget = BudgetModel(
    id: uuid.v4(),
    businessId: businessId,
    totalAmount: totalAmount,
    departmentAllocation: departmentAllocation,
    constraints: constraints,
    createdAt: DateTime.now(),
    status: 'active',
  );
  
  await _firestore.collection('budgets').doc(budget.id).set(budget.toMap());
  return budget;
}

#### **Optimize Budget**
```dart
Future<BudgetOptimization> optimizeBudget({
  required String businessId,
  required Map<String, dynamic> constraints,
}) async {
  try {
    final response = await http.post(
      Uri.parse('${EnvironmentConfig.apiBaseUrl}/budget/optimize'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _getAuthToken()}',
      },
      body: jsonEncode({
        'businessId': businessId,
        'constraints': constraints,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return BudgetOptimization.fromMap(data);
    } else {
      throw Exception('Budget optimization failed');
    }
  } catch (e) {
    throw Exception('Budget optimization error: $e');
  }
}
```

---

## 🔥 Firebase Integration

### **Firestore Database Structure**

#### **Collections**
```javascript
// Users Collection
{
  "users": {
    "userId": {
      "id": "string",
      "phoneNumber": "string",
      "name": "string",
      "email": "string",
      "role": "admin|manager|driver|business_owner",
      "businessId": "string",
      "isActive": "boolean",
      "createdAt": "timestamp",
      "updatedAt": "timestamp"
    }
  }
}

// Businesses Collection
{
  "businesses": {
    "businessId": {
      "id": "string",
      "name": "string",
      "type": "manufacturing|distribution|retail|transport",
      "country": "string",
      "currency": "string",
      "primaryCity": "string",
      "isActive": "boolean",
      "createdAt": "timestamp",
      "updatedAt": "timestamp"
    }
  }
}

// Routes Collection
{
  "routes": {
    "routeId": {
      "id": "string",
      "name": "string",
      "businessId": "string",
      "stops": [
        {
          "id": "string",
          "name": "string",
          "address": "string",
          "latitude": "number",
          "longitude": "number",
          "estimatedTime": "number",
          "priority": "high|medium|low"
        }
      ],
      "status": "active|completed|cancelled|paused",
      "createdBy": "string",
      "createdAt": "timestamp",
      "updatedAt": "timestamp"
    }
  }
}
```

#### **Security Rules**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null && request.auth.uid != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function isAdmin() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Users collection - owner only
    match /users/{userId} {
      allow read, write: if isOwner(userId) && isValidId(userId);
    }
    
    // Businesses collection - business-specific access
    match /businesses/{businessId} {
      allow read: if (isBusinessOwner(businessId) || 
                     isBusinessAdmin(businessId) || 
                     isAdmin()) && isValidId(businessId);
      allow write: if (isBusinessOwner(businessId) || 
                      isBusinessAdmin(businessId) || 
                      isAdmin()) && isValidId(businessId);
    }
    
    // Routes collection - role-based access
    match /routes/{routeId} {
      allow read: if (isBusinessOwner(businessId) || 
                     isBusinessAdmin(businessId) || 
                     isManager(businessId) || 
                     isDriver(businessId) || 
                     isAdmin()) && isValidId(routeId);
      allow write: if (isBusinessOwner(businessId) || 
                      isBusinessAdmin(businessId) || 
                      isManager(businessId) || 
                      isAdmin()) && isValidId(routeId);
    }
  }
}
```

### **Firebase Authentication Setup**

#### **Phone Authentication Configuration**
```dart
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Initialize phone authentication
  Future<void> initializePhoneAuth() async {
    await _auth.setSettings(
      android: const AndroidSettings(
        autoVerifyPhoneNumber: true,
        forceRecaptchaFlow: false,
      ),
      ios: const IOSSettings(
        autoHandleSmsRetrievalForAllNumbers: true,
      ),
    );
  }
  
  // Send verification code
  Future<String> sendVerificationCode(String phoneNumber) async {
    final confirmationResult = await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        throw Exception('Verification failed: ${e.message}');
      },
      codeSent: (String verificationId) {
        return verificationId;
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        throw Exception('Code retrieval timeout');
      },
    );
    
    return confirmationResult.verificationId!;
  }
  
  // Verify code
  Future<UserCredential> verifyCode(String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    
    return await _auth.signInWithCredential(credential);
  }
}
```

### **Firebase Storage Configuration**

#### **File Upload Service**
```dart
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Upload file
  Future<String> uploadFile({
    required File file,
    required String path,
    required String userId,
    required String businessId,
  }) async {
    try {
      final ref = _storage
          .ref()
          .child('businesses')
          .child(businessId)
          .child('files')
          .child(userId)
          .child(path)
          .child(file.name);
      
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('File upload failed: $e');
    }
  }
  
  // Get download URL
  Future<String> getDownloadUrl(String filePath) async {
    try {
      final ref = _storage.ref().child(filePath);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to get download URL: $e');
    }
  }
  
  // Delete file
  Future<void> deleteFile(String filePath) async {
    try {
      final ref = _storage.ref().child(filePath);
      await ref.delete();
    } catch (e) {
      throw Exception('File deletion failed: $e');
    }
  }
}
```

---

## 🔒 Security Implementation

### **Input Validation**
```dart
class InputValidation {
  // Email validation
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }
  
  // Phone validation
  static bool isValidPhone(String phone) {
    return RegExp(r'^[+]?[0-9]{10,15}$').hasMatch(phone);
  }
  
  // Password validation
  static bool isValidPassword(String password) {
    if (password.length < 8) return false;
    if (!RegExp(r'[A-Z]').hasMatch(password)) return false;
    if (!RegExp(r'[a-z]').hasMatch(password)) return false;
    if (!RegExp(r'[0-9]').hasMatch(password)) return false;
    return true;
  }
  
  // Sanitize input
  static String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>?'), '')
        .replaceAll(RegExp(r'javascript:'), '')
        .replaceAll(RegExp(r'on\w+='), '')
        .trim();
  }
}
```

### **Exception Handling**
```dart
class ExceptionHandler {
  static Future<T?> handleException<T>(
    Object exception,
    StackTrace? stackTrace, {
    String? context,
    String? operation,
    bool rethrow = false,
  }) async {
    // Categorize exception
    final categorizedException = _categorizeException(exception);
    
    // Log exception
    await _logException(categorizedException, stackTrace);
    
    // Report to crash reporting
    await _reportToCrashReporting(categorizedException, stackTrace);
    
    // Show user-friendly message
    await _showUserMessage(categorizedException);
    
    if (rethrow) rethrow;
    
    return null;
  }
  
  static CategorizedException _categorizeException(Object exception) {
    if (exception is NetworkException) {
      return CategorizedException(
        type: ExceptionType.network,
        message: 'Network connection failed',
        isRecoverable: true,
      );
    } else if (exception is FirebaseAuthException) {
      return CategorizedException(
        type: ExceptionType.authentication,
        message: _getAuthErrorMessage(exception),
        isRecoverable: false,
      );
    }
    // ... other exception types
  }
}
```

### **Security Best Practices**
1. **Input Validation**: Always validate and sanitize user input
2. **Authentication**: Use Firebase Auth with proper error handling
3. **Authorization**: Implement role-based access control
4. **Data Encryption**: Encrypt sensitive data at rest and in transit
5. **Audit Logging**: Log all security-relevant events
6. **Rate Limiting**: Implement rate limiting for API endpoints
7. **CORS Configuration**: Properly configure CORS for web

---

## 🛠️ Development Setup

### **Prerequisites**
- **Flutter SDK**: 3.16.0 or higher
- **Dart SDK**: 3.2.0 or higher
- **Android Studio**: Latest stable version
- **Xcode**: 14.0 or higher
- **Git**: Version control system

### **Environment Setup**
```bash
# Clone the repository
git clone https://github.com/your-org/optiflow.git
cd optiflow

# Install dependencies
flutter pub get

# Copy environment template
cp lib/config/.env.template lib/config/.env

# Edit environment variables
nano lib/config/.env
```

### **Required Environment Variables**
```env
# Firebase Configuration
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_API_KEY=your-firebase-api-key
FIREBASE_MESSAGING_SENDER_ID=your-sender-id

# Google Maps Configuration
GOOGLE_MAPS_API_KEY=your-google-maps-api-key

# API Configuration
API_BASE_URL=https://api.optiflow.com
API_TIMEOUT=30000

# Environment Configuration
ENVIRONMENT=development
DEBUG_MODE=true
ENABLE_CRASH_REPORTING=true
ENABLE_ANALYTICS=true
```

### **Firebase Setup**
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project
firebase init

# Deploy Firestore security rules
firebase deploy --only firestore:rules

# Deploy Firebase functions
firebase deploy --only functions
```

### **Google Maps Setup**
1. **Get API Key**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Enable Maps SDK for Android, iOS, and Web
   - Enable Directions API, Geocoding API, Places API
   - Create and restrict API key

2. **Configure Android**
   ```xml
   <!-- android/app/src/main/AndroidManifest.xml -->
   <meta-data android:name="com.google.android.geo.API_KEY"
               android:value="YOUR_API_KEY"/>
   ```

3. **Configure iOS**
   ```swift
   <!-- ios/Runner/AppDelegate.swift -->
   GMSServices.provideAPIKey("YOUR_API_KEY")
   ```

4. **Configure Web**
   ```html
   <!-- web/index.html -->
   <script src="https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY"></script>
   ```

---

## 🧪 Testing Guidelines

### **Unit Testing**
```dart
// Example unit test
test('RouteService should create route successfully', () async {
  final routeService = RouteService();
  
  final route = await routeService.createRoute(
    name: 'Test Route',
    businessId: 'test-business',
    stops: [
      LocationModel(id: '1', name: 'Stop 1', latitude: 0.0, longitude: 0.0),
      LocationModel(id: '2', name: 'Stop 2', latitude: 1.0, longitude: 1.0),
    ],
    createdBy: 'test-user',
  );
  
  expect(route.name, equals('Test Route'));
  expect(route.stops.length, equals(2));
  expect(route.businessId, equals('test-business'));
});
```

### **Widget Testing**
```dart
// Example widget test
testWidgets('RouteCard should display route information', (WidgetTester tester) async {
  final route = RouteModel(
    id: '1',
    name: 'Test Route',
    businessId: 'test-business',
    stops: [],
    status: 'active',
    createdAt: DateTime.now(),
    createdBy: 'test-user',
  );
  
  await tester.pumpWidget(
    MaterialApp(
      home: RouteCard(route: route),
    ),
  );
  
  expect(find.text('Test Route'), findsOneWidget);
  expect(find.text('Active'), findsOneWidget);
});
```

### **Integration Testing**
```dart
// Example integration test
testWidgets('Complete route creation flow', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  
  // Navigate to route creation
  await tester.tap(find.byKey(Key('create_route_button')));
  await tester.pumpAndSettle();
  
  // Fill form
  await tester.enterText(find.byKey(Key('route_name')), 'Test Route');
  await tester.tap(find.byKey(Key('add_stop_button')));
  await tester.pumpAndSettle();
  
  // Submit form
  await tester.tap(find.byKey(Key('submit_route_button')));
  await tester.pumpAndSettle();
  
  // Verify route was created
  expect(find.text('Route created successfully'), findsOneWidget);
});
```

### **Running Tests**
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/services/route_service_test.dart

# Run with coverage
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
```

---

## 🚀 Deployment Guide

### **Android Deployment**
```bash
# Generate APK
flutter build apk --release

# Generate App Bundle (recommended for Play Store)
flutter build appbundle --release

# Sign APK (if needed)
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore my-release-key.keystore my-release-unsigned.apk my-release-key.keystore my-release-key.alias

# Upload to Play Store
# 1. Go to Google Play Console
# 2. Create new release
# 3. Upload app-release.aab
```

### **iOS Deployment**
```bash
# Build iOS app
flutter build ios --release

# Archive and distribute via Xcode
open ios/Runner.xcworkspace

# Steps in Xcode:
# 1. Product → Archive
# 2. Window → Organizer
# 3. Select archive → Distribute App
# 4. Upload to App Store Connect
```

### **Web Deployment**
```bash
# Build web app
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting

# Or deploy to any static hosting service
# Copy build/web contents to your hosting provider
```

### **Environment-Specific Builds**
```bash
# Development build
flutter run --debug

# Staging build
flutter build apk --release --dart-define=ENVIRONMENT=staging

# Production build
flutter build apk --release --dart-define=ENVIRONMENT=production
```

---

## 🔧 Troubleshooting

### **Common Issues**

#### **Build Issues**
```bash
# Clean build cache
flutter clean
flutter pub get

# Check Flutter doctor
flutter doctor -v

# Update dependencies
flutter pub upgrade
```

#### **Firebase Issues**
```bash
# Check Firebase configuration
firebase projects:list

# Test Firestore rules
firebase deploy --only firestore:rules --dry-run

# Check Firebase functions logs
firebase functions:log
```

#### **API Issues**
```bash
# Test API endpoints
curl -X POST https://api.optiflow.com/optimize \
  -H "Content-Type: application/json" \
  -d '{"stops": [], "vehicle_type": "truck"}'

# Check network connectivity
ping api.optiflow.com
```

### **Debugging Tools**
```dart
// Enable debug logging
Logger.debug('Debug message', name: 'ComponentName');

// Performance monitoring
PerformanceMonitoring.startTrace('operation_name');

// Error reporting
ExceptionHandler.handleException(exception, stackTrace);
```

### **Performance Optimization**
```dart
// Use lazy loading
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ItemWidget(item: items[index]);
  },
);

// Implement caching
class CacheService {
  final Map<String, dynamic> _cache = {};
  
  T? get<T>(String key) {
    return _cache[key] as T?;
  }
  
  void set<T>(String key, T value) {
    _cache[key] = value;
  }
}
```

---

## 📞 Support

### **Getting Help**
- **Documentation**: [Comprehensive documentation](docs/)
- **Issues**: [GitHub Issues](https://github.com/your-org/optiflow/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-org/optiflow/discussions)
- **Email**: developers@optiflow.com

### **Contributing Guidelines**
1. **Fork the repository**
2. **Create feature branch**: `git checkout -b feature/amazing-feature`
3. **Commit changes**: `git commit -m 'feat: add amazing feature'`
4. **Push to branch**: `git push origin feature/amazing-feature`
5. **Create Pull Request**: Detailed description of changes

### **Code Standards**
- **Follow Flutter Style Guide**: Consistent code formatting
- **Write Tests**: Comprehensive test coverage
- **Update Documentation**: Keep documentation current
- **Performance Impact**: Consider performance implications

---

## 📄 Additional Resources

### **Official Documentation**
- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Google Maps API Documentation](https://developers.google.com/maps/documentation)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)

### **Community Resources**
- [Flutter Community](https://github.com/flutter/flutter)
- [Firebase Community](https://firebase.google.com/community)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)

### **Tools and Libraries**
- [Flutter Inspector](https://flutter.dev/docs/development/tools/flutter-inspector)
- [Dart DevTools](https://dart.dev/tools/dart-devtools)
- [Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite)

---

*Last updated: April 2026*
