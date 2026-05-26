import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:instagram/firebase_options.dart';
import 'package:instagram/pages/feed_page.dart';
import 'package:instagram/pages/login_page.dart';

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
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

      // Firebase Remote Config 데이터 가져오기
      await FirebaseRemoteConfig.instance.fetchAndActivate();

      // Flutter에서 발생하는 자잘한 에러들을 Crashlytics로 보내줍니다.
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

      runApp(const InstagramApp());
    },
    (exception, stacktrace) async {
      print('Uncaught error: $exception');
      print(stacktrace);

      // 앱이 갑자기 종료되거나 에러가 발생했을 때 Crashlytics로 상세한 내용을 보내줍니다.
      await FirebaseCrashlytics.instance.recordFlutterFatalError(
        FlutterErrorDetails(
          exception: exception,
          stack: stacktrace,
        ),
      );
    },
  );
}

class InstagramApp extends StatelessWidget {
  const InstagramApp({super.key});

  @override
  Widget build(BuildContext context) {
    // FirebaseAuth로부터 현재 로그인한 사용자 정보를 가져옵니다.
    final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;

    // 만약 사용자가 로그인하지 않은 상태라면 `로그인 페이지`를 보여줍니다.
    // 만약 사용자가 로그인한 상태라면 `홈 페이지`를 보여줍니다.

    return MaterialApp(
      title: 'Instagram',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pinkAccent,
        ),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? FeedPage() : LoginPage(),
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
    );
  }
}
