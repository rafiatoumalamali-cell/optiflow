import 'dart:io';

String joinPath(List<String> parts) {
  return parts.join(Platform.pathSeparator);
}

void main() {
  final root = Directory.current;
  final androidConfig = File(joinPath([root.path, 'android', 'app', 'google-services.json']));
  final iosConfig = File(joinPath([root.path, 'ios', 'Runner', 'GoogleService-Info.plist']));
  final webIndex = File(joinPath([root.path, 'web', 'index.html']));

  final hasAndroidConfig = androidConfig.existsSync();
  final hasIosConfig = iosConfig.existsSync();
  final hasWebConfig = webIndex.existsSync() && _containsWebFirebaseConfig(webIndex);

  print('Firebase platform configuration check');
  print('------------------------------------');
  print('Android google-services.json: ${hasAndroidConfig ? 'FOUND' : 'MISSING'}');
  print('iOS GoogleService-Info.plist: ${hasIosConfig ? 'FOUND' : 'MISSING'}');
  print('Web firebase config in web/index.html: ${hasWebConfig ? 'FOUND' : 'MISSING'}');

  if (!hasAndroidConfig || !hasIosConfig || !hasWebConfig) {
    print('\nAction items:');
    if (!hasAndroidConfig) {
      print('- Add android/app/google-services.json from your Firebase Android application.');
    }
    if (!hasIosConfig) {
      print('- Add ios/Runner/GoogleService-Info.plist from your Firebase iOS application.');
    }
    if (!hasWebConfig) {
      print('- Add Firebase web config to web/index.html or use a generated firebase_options.dart for Flutter web.');
    }
    exit(1);
  }

  print('\nAll required Firebase platform config files are present.');
}

bool _containsWebFirebaseConfig(File file) {
  try {
    final content = file.readAsStringSync();
    return content.contains('firebase.initializeApp') || content.contains('apiKey:') || content.contains('projectId:');
  } catch (_) {
    return false;
  }
}
