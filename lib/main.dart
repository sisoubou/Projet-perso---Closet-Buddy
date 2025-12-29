
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_app_check/firebase_app_check.dart';

import 'screens/auth_screen.dart';
import 'screens/wardrobe_screen.dart';
import 'models/user.dart';
import 'firebase_options.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    providerAndroid: kReleaseMode
        ? AndroidPlayIntegrityProvider()
        : AndroidDebugProvider(),
    providerApple: kReleaseMode
        ? AppleDeviceCheckProvider()
        : AppleDebugProvider(),
  );

  final token = await FirebaseAppCheck.instance.getToken(true);
  debugPrint('AppCheck token: $token');

  runApp(const ClosetBuddyApp());
}

class ClosetBuddyApp extends StatelessWidget {
  const ClosetBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Closet Buddy',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<fb_auth.User?>(
        stream: fb_auth.FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            final fbUser = snapshot.data!;
            final localUser = User(
              id: fbUser.uid,
              name: (fbUser.displayName != null && fbUser.displayName!.isNotEmpty)
                  ? fbUser.displayName!
                  : fbUser.email?.split('@')[0] ?? 'Utilisateur',
              email: fbUser.email ?? '',
              password: '',
              wardrobe: [],
            );
            return WardrobeScreen(user: localUser);
          }
          return const AuthScreen();
        },
      ),
       );
  }
}