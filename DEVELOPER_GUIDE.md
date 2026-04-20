# OptiFlow Developer Guide

Quick reference guide for developers extending or maintaining OptiFlow.

## Project Structure

```
optiflow/
├── lib/
│   ├── main.dart                 # Entry point, Firebase & Workmanager init
│   ├── screens/                  # All UI screens (numbered by module)
│   │   ├── auth/                 # Authentication screens
│   │   ├── core/                 # Dashboard, profile, results
│   │   ├── product_mix/          # Product optimization
│   │   ├── transport/            # Transport optimization
│   │   ├── route/                # Route optimization
│   │   ├── budget/               # Budget optimization
│   │   ├── admin/                # Admin dashboard & management
│   │   ├── driver/               # Driver-specific screens
│   │   └── settings/             # Settings, help, support
│   ├── providers/                # State management (Provider pattern)
│   ├── models/                   # Data models
│   ├── services/
│   │   ├── api/                  # HTTP API clients
│   │   ├── firebase/             # Firebase services
│   │   ├── database/             # SQLite local database
│   │   ├── sync/                 # Offline sync queue
│   │   └── shared_preferences/   # Local settings storage
│   ├── widgets/                  # Reusable UI components
│   ├── routes/                   # Navigation routing
│   ├── utils/
│   │   ├── app_colors.dart       # Color constants
│   │   ├── app_theme.dart        # Theme definition
│   │   ├── app_localizations.dart # Multi-language strings
│   │   ├── constants.dart        # App constants
│   │   └── logger.dart           # Logging utility
│   └── assets/                   # Images and static files
├── android/                      # Android-specific configuration
├── ios/                          # iOS-specific configuration
├── web/                          # Web-specific configuration
├── backend/                      # FastAPI backend server
├── test/                         # Unit and widget tests
└── docs/
    ├── FIREBASE_SETUP_GUIDE.md   # Firebase configuration
    ├── DEPLOYMENT_CHECKLIST.md   # Pre-deployment verification
    └── remaining_tasks.md        # Outstanding development tasks

```

## Key Technologies

- **Flutter** 3.0+: Cross-platform mobile and web framework
- **Dart** 3.0+: Programming language
- **Provider** 6.1.1: State management and dependency injection
- **Firebase**: Backend services
  - Authentication
  - Firestore (real-time database)
  - Firebase Storage
  - Cloud Messaging (notifications)
  - Analytics
- **MobX**: Advanced state management (optional for complex screens)
- **SQLite** (sqflite): Local offline database
- **Google Maps**: Map visualization and location
- **Workmanager**: Background task scheduling
- **FastAPI** (Python): Optimization backend

## State Management Pattern

OptiFlow uses the **Provider** pattern with `ChangeNotifier`:

```dart
// Example: Creating a new provider
class MyProvider with ChangeNotifier {
  String _data = '';
  
  String get data => _data;
  
  Future<void> fetchData() async {
    _data = await api.get();
    notifyListeners(); // Rebuild dependent widgets
  }
}

// In widgets:
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MyProvider>(context);
    return Text(provider.data);
  }
}
```

All providers are registered in `main.dart` using `MultiProvider`.

## API Communication

API calls go through `lib/services/api/`:

1. **ApiClient** (`api_client.dart`): HTTP client with timeout handling
2. **ApiConfig** (`api_config.dart`): Configuration and endpoints
3. **Specific API classes**: OptimizationApi, MapsApi, etc.

### Adding a New API Endpoint

```dart
// 1. Add method to OptimizationApi
class OptimizationApi {
  Future<Map<String, dynamic>> myNewEndpoint(data) async {
    return await _post('/my-endpoint', data);
  }
}

// 2. Use in provider
final response = await _api.myNewEndpoint(data);

// 3. Handle response and update state
notifyListeners();
```

## Database Operations

Local SQLite database accessed through `DatabaseService`:

```dart
// Insert
await _dbService.insert('table_name', {'col': 'value'});

// Query all
final items = await _dbService.queryAll('table_name');

// Query with condition
final items = await _dbService.query('table_name', 'id', '123');

// Update
await _dbService.update('table_name', {'col': 'new_value'}, 'id', '123');

// Delete
await _dbService.delete('table_name', 'id', '123');
```

## Offline Sync

When offline, operations queue locally:

```dart
// Add to sync queue
await syncService.addToQueue(
  operationType: 'INSERT',
  collection: 'products',
  data: product.toMap(),
);

// Processed automatically on reconnect or via Workmanager (15-min interval)
```

## Localization

Add translations in `lib/utils/app_localizations.dart`:

```dart
'my_key': {
  'en': 'Hello',
  'fr': 'Bonjour',
  'ha': 'Sannu',
}
```

Use in UI:
```dart
Text(AppLocalizations.of(context)?.translate('my_key') ?? 'Hello')
```

## Navigation

Named routes defined in `lib/routes/app_routes.dart`:

```dart
static const String myScreen = '/my-screen';

// In code:
Navigator.pushNamed(context, AppRoutes.myScreen, arguments: data);
```

## Styling

- **Colors**: `lib/utils/app_colors.dart`
- **Theme**: `lib/utils/app_theme.dart`
- **Typography**: Defined in AppTheme

Always use `AppColors` constants instead of hardcoded colors.

## Error Handling

Use `Logger` for consistent logging:

```dart
Logger.info('Message', name: 'ClassName');
Logger.warning('Message', name: 'ClassName', error: e);
Logger.error('Message', name: 'ClassName', error: e, stackTrace: st);
```

Check logs in `lib/utils/logger.dart`.

## Firebase Services

### Authentication
```dart
final authProvider = Provider.of<AuthProvider>(context, listen: false);
await authProvider.signInWithPhone(phone, verificationId, otp);
final user = authProvider.currentUser;
```

### Firestore
```dart
final collection = FirebaseFirestore.instance.collection('users');
final snapshot = await collection.doc(userId).get();
final data = snapshot.data();
```

### Cloud Messaging
Configured in `main.dart`. Messages handled by:
- `_firebaseMessagingBackgroundHandler` for background messages
- Implementation in `NotificationProvider` for foreground

## Backend API

Located in `backend/main.py`. Run with:

```bash
pip install -r requirements.txt
python backend/main.py
```

API endpoints:
- `POST /api/optimize/product-mix`
- `POST /api/optimize/transport`
- `POST /api/optimize/route`
- `POST /api/optimize/budget`

## Testing Checklist for New Features

Before committing:
- [ ] Flutter analyze passes
- [ ] No null safety warnings
- [ ] Widget builds without errors
- [ ] Navigation works without crashes
- [ ] Data persistence works (offline)
- [ ] Data syncs when online
- [ ] All localization keys present
- [ ] Responsive on various screen sizes
- [ ] Error states handled gracefully
- [ ] Loading states visible to user

## Common Tasks

### Add a new screen
1. Create file in appropriate `screens/` folder
2. Create corresponding provider if needed
3. Add route constant to `app_routes.dart`
4. Add localization strings
5. Test all navigation paths

### Add a new API endpoint
1. Implement in backend (`backend/main.py`)
2. Add method to appropriate API class
3. Call from provider
4. Handle errors and loading states
5. Test with real data

### Add a new model
1. Create in `models/` folder
2. Implement `toMap()` and `fromMap()` methods
3. Add Firestore document handling if needed
4. Update providers that use the model

### Fix a bug
1. Reproduce consistently
2. Add test case if possible
3. Fix in code
4. Test on all relevant platforms
5. Verify no regression

## Performance Tips

- Use `const` for widgets when possible
- Use `RepaintBoundary` for complex widgets
- Lazy-load screens and data
- Optimize build methods (avoid rebuilds)
- Use `cached_network_image` for images
- Profile with Flutter DevTools for bottlenecks

## Security Checklist

- [ ] No API keys in source code
- [ ] No hardcoded passwords
- [ ] All API calls use HTTPS
- [ ] Firebase rules prevent unauthorized access
- [ ] User input validated before sending to server
- [ ] Sensitive data cleared on logout
- [ ] Biometric authentication considered
- [ ] SSL certificate pinning for critical endpoints

## Debugging Tips

1. **Use Flutter DevTools**
   ```bash
   flutter pub global activate devtools
   devtools
   ```

2. **Check logs**
   ```bash
   flutter logs
   ```

3. **Debug print**
   ```dart
   debugPrint('Value: $value');
   ```

4. **Remote debugging**
   - Attach debugger in VS Code with F5
   - Set breakpoints and inspect variables

## Useful Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase for Flutter](https://firebase.flutter.dev)
- [Provider Pattern Guide](https://pub.dev/packages/provider)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)

## Contact & Support

For questions about the codebase:
1. Check existing code comments
2. Review API documentation
3. Check test files for usage examples
4. Consult team documentation
5. Reach out to team lead

---

**Last Updated**: April 2026
**Version**: 1.0.0

