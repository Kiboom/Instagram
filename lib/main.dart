import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:instagram/firebase_options.dart';
import 'package:instagram/pages/feed_page.dart';
import 'package:instagram/pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Firebase Remote Config 설정
  await FirebaseRemoteConfig.instance.setConfigSettings(
    RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 0),
    ),
  );
  await FirebaseRemoteConfig.instance.fetchAndActivate();

  runApp(const InstagramApp());
}

class InstagramApp extends StatelessWidget {
  const InstagramApp({super.key});

  @override
  Widget build(BuildContext context) {
    // FirebaseAuth로부터 현재 로그인한 사용자 정보를 가져옵니다.
    final User? user = FirebaseAuth.instance.currentUser;

    // 만약 사용자가 로그인하지 않은 상태라면 `LoginPage`를 보여줍니다.
    // 만약 사용자가 로그인한 상태라면 `FeedPage`를 보여줍니다.
    return MaterialApp(
      title: 'Instagram Mini',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: user == null ? LoginPage() : FeedPage(),
    );
  }
}
