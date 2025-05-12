import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:instagram/firebase_options.dart';
import 'package:instagram/pages/feed_page.dart';
import 'package:instagram/pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  _notifyActiveState();

  AppLifecycleListener(
    onShow: () => _notifyActiveState(),
    onHide: () => _notifyDeactiveState(),
  );

  runApp(const InstagramApp());
}

// Realtime Database에 로그인 여부를 저장합니다.
Future<void> _notifyActiveState() async {
  // 현재 로그인한 사용자의 이름을 가져옵니다.
  DatabaseEvent currentData =
      await FirebaseDatabase.instance.ref().child("active_users").once();

  // 현재까지 로그인한 사용자의 이름 목록
  List<String?> activeUsers =
      currentData.snapshot.value == null
          ? []
          : List<String?>.from(currentData.snapshot.value as List<dynamic>);

  // 만약 현재 로그인한 사용자의 이름이 사용자 목록에 없다면 추가합니다.
  final String? myName = FirebaseAuth.instance.currentUser?.displayName;
  if (myName != null && !activeUsers.contains(myName)) {
    activeUsers.insert(0, myName);
  }

  // Realtime Database에 사용자 목록을 업데이트합니다.
  FirebaseDatabase.instance.ref().child("active_users").set(activeUsers);
}

// Realtime Database에 미접속 여부를 저장합니다.
Future<void> _notifyDeactiveState() async {
  // 현재 로그인한 사용자의 이름을 가져옵니다.
  DatabaseEvent currentData =
      await FirebaseDatabase.instance.ref().child("active_users").once();
  List<String?> activeUsers = List<String?>.from(
    currentData.snapshot.value as List<dynamic>,
  );

  // 만약 현재 로그인한 사용자의 이름이 사용자 목록에 없다면 추가합니다.
  final String? myName = FirebaseAuth.instance.currentUser?.displayName;
  if (activeUsers.contains(myName)) {
    activeUsers.remove(myName);
  }

  // Realtime Database에 사용자 목록을 업데이트합니다.
  FirebaseDatabase.instance.ref().child("active_users").set(activeUsers);
}

class InstagramApp extends StatelessWidget {
  const InstagramApp({super.key});

  @override
  Widget build(BuildContext context) {
    // FirebaseAuth로부터 현재 로그인한 사용자 정보를 가져옵니다.

    // 만약 사용자가 로그인하지 않은 상태라면 `LoginPage`를 보여줍니다.
    // 만약 사용자가 로그인한 상태라면 `FeedPage`를 보여줍니다.

    return MaterialApp(
      title: 'Instagram',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home:
          FirebaseAuth.instance.currentUser == null ? LoginPage() : FeedPage(),
    );
  }
}
