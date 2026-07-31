import UserNotifications

class NotificationService: UNNotificationServiceExtension {
  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    let options = request.content.userInfo["fcm_options"] as? [String: Any]
    guard let content = request.content.mutableCopy() as? UNMutableNotificationContent,
      let imageUrl = (options?["image"] as? String).flatMap(URL.init(string:))
    else {
      contentHandler(request.content)
      return
    }

    URLSession.shared.downloadTask(with: imageUrl) { location, _, _ in
      defer { contentHandler(content) }
      guard let location else { return }

      // 확장자가 없으면 iOS가 첨부를 거부하므로 확장자를 붙여 옮겨둡니다.
      let name = imageUrl.pathExtension.isEmpty ? "image.jpg" : "image.\(imageUrl.pathExtension)"
      let file = location.deletingLastPathComponent().appendingPathComponent(name)
      guard (try? FileManager.default.moveItem(at: location, to: file)) != nil else { return }

      if let attachment = try? UNNotificationAttachment(identifier: "", url: file) {
        content.attachments = [attachment]
      }
    }.resume()
  }
}
