import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String uid;
  final String username;
  final String? imageUrl;
  final String description;
  final List<Like> likes;
  final List<Comment> comments;
  final DateTime createdAt;

  Post({
    required this.uid,
    required this.username,
    required this.description,
    this.imageUrl,
    required Timestamp createdAt,
    this.likes = const [],
    this.comments = const [],
  }) : createdAt = createdAt.toDate();

  String get timeAgo {
    final Duration diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}년 전';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}달 전';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}일 전';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}시간 전';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}

class Like {
  final String uid;
  final String username;

  Like({
    required this.uid,
    required this.username,
  });
}

class Comment {
  final String uid;
  final String username;
  final String comment;
  final DateTime createdAt;

  Comment({
    required this.uid,
    required this.username,
    required this.comment,
    required this.createdAt,
  });
}
