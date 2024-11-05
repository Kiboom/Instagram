import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:instagram/firebase_options.dart';
import 'package:instagram/pages/feed_page.dart';
import 'package:instagram/pages/login_page.dart';

void main() async {
  runZonedGuarded(
    () async {
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

      // Flutter에서 발생하는 자잘한 에러들을 Crashlytics로 보내줍니다.
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

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
    final User? user = FirebaseAuth.instance.currentUser;

    // 만약 사용자가 로그인하지 않은 상태라면 `LoginPage`를 보여줍니다.
    // 만약 사용자가 로그인한 상태라면 `FeedPage`를 보여줍니다.
    return MaterialApp(
      title: 'Instagram Mini',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
        useMaterial3: true,
      ),
      navigatorObservers: [
        FirebaseAnalyticsObserver(
          analytics: FirebaseAnalytics.instance,
        ),
      ],
      debugShowCheckedModeBanner: false,
      home: user == null ? LoginPage() : FeedPage(),
    );
  }
}

// Realtime Database에 접속 여부를 저장합니다.
Future<void> _notifyActiveState() async {
  // 현재 로그인한 사용자의 이름을 가져옵니다.
  DatabaseEvent currentData = await FirebaseDatabase.instance.ref().child("active_users").once();
  List<String?> activeUsers = currentData.snapshot.value == null
      ? []
      : List<String?>.from(currentData.snapshot.value as List<dynamic>);

  // 만약 현재 로그인한 사용자의 이름이 사용자 목록에 없다면 추가합니다.
  final String? myName = FirebaseAuth.instance.currentUser?.displayName;
  if (!activeUsers.contains(myName)) {
    activeUsers.insert(0, myName);
  }

  // Realtime Database에 사용자 목록을 업데이트합니다.
  FirebaseDatabase.instance.ref().child("active_users").set(activeUsers);
}

// Realtime Database에 미접속 여부를 저장합니다.
Future<void> _notifyDeactiveState() async {
  // 현재 로그인한 사용자의 이름을 가져옵니다.
  DatabaseEvent currentData = await FirebaseDatabase.instance.ref().child("active_users").once();
  List<String?> activeUsers = currentData.snapshot.value == null
      ? []
      : List<String?>.from(currentData.snapshot.value as List<dynamic>);

  // 만약 현재 로그인한 사용자의 이름이 사용자 목록에 없다면 추가합니다.
  final String? myName = FirebaseAuth.instance.currentUser?.displayName;
  if (activeUsers.contains(myName)) {
    activeUsers.remove(myName);
  }

  // Realtime Database에 사용자 목록을 업데이트합니다.
  FirebaseDatabase.instance.ref().child("active_users").set(activeUsers);
}
