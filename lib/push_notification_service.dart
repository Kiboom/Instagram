import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationService {
  static Future<void> initialize() async {
    // 알림 권한을 요청합니다.
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 권한을 거부한 기기는 더 진행하지 않습니다.
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // iOS는 앱을 보고 있는 동안에도 알림 배너를 띄워줍니다.
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 권한을 허용한 기기를 Topic에 가입시킵니다.
    await FirebaseMessaging.instance.subscribeToTopic("class_notice");
  }
}
