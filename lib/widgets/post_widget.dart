import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:instagram/data/post.dart";

class PostWidget extends StatefulWidget {
  const PostWidget({
    super.key,
    required this.item,
  });

  final Post item;

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  bool get _isLikedByCurrentUser {
    final String? displayName = FirebaseAuth.instance.currentUser?.displayName;
    return widget.item.likes.any((like) => like.username == displayName);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Container(height: 12),
          _buildImage(),
          Container(height: 12),
          _buildActionButtons(),
          Container(height: 12),
          _buildLikesCount(),
          Container(height: 4),
          _buildDescription(),
          Container(height: 4),
          _buildCommentsLink(),
          Container(height: 4),
          _buildTimeAgo(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 16,
        ),
        Container(width: 8),
        Text(
          widget.item.username,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        widget.item.imageUrl,
        width: double.infinity,
        height: 400,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildActionButtons() {
    final bool isLiked = _isLikedByCurrentUser;
    return Row(
      children: [
        Icon(
          isLiked ? Icons.favorite : Icons.favorite_border,
          size: 26,
          color: isLiked ? Colors.red : Colors.black,
        ),
        Container(width: 20),
        const Icon(
          Icons.chat_bubble_outline,
          size: 24,
        ),
        Container(width: 20),
        const Spacer(),
        const Icon(
          Icons.bookmark_border,
          size: 26,
        ),
      ],
    );
  }

  Widget _buildLikesCount() {
    return Text(
      "좋아요 ${widget.item.likes.length}개",
      style: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      widget.item.description,
      style: const TextStyle(
        color: Colors.black,
      ),
    );
  }

  Widget _buildCommentsLink() {
    return Text(
      "댓글 ${widget.item.comments.length}개 모두 보기",
      style: const TextStyle(
        color: Colors.black54,
      ),
    );
  }

  Widget _buildTimeAgo() {
    return Text(
      widget.item.timeAgo,
      style: const TextStyle(
        color: Colors.black54,
      ),
    );
  }
}
