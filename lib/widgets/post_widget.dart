import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instagram/data/post.dart';

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
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileImage(),
          Container(height: 12),
          _buildImage(),
          Container(height: 12),
          _buildIcons(),
          Container(height: 12),
          _buildLikeAndComments(),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
        ),
        Container(width: 8),
        Text(
          widget.item.username,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    if (widget.item.imageUrl == null) {
      return const SizedBox.shrink();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        widget.item.imageUrl ?? "",
        width: double.infinity,
        height: 300,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildIcons() {
    return Row(
      children: [
        Icon(
          widget.item.likes.any((like) => like.username == FirebaseAuth.instance.currentUser?.displayName)
              ? Icons.favorite
              : Icons.favorite_border,
          size: 26,
          color: widget.item.likes.any((like) => like.username == FirebaseAuth.instance.currentUser?.displayName)
              ? Colors.red
              : Colors.black,
        ),
        Container(width: 20),
        Icon(
          Icons.chat_bubble_outline,
          size: 24,
        ),
        Container(width: 20),
        const Spacer(),
        Icon(
          Icons.bookmark_border,
          size: 26,
        ),
      ],
    );
  }

  Widget _buildLikeAndComments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '좋아요 ${widget.item.likes.length}개',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(height: 4),
        Text(
          widget.item.description,
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        Container(height: 4),
        Text(
          '댓글 ${widget.item.comments.length}개 모두 보기',
          style: TextStyle(
            color: Colors.black54,
          ),
        ),
        Container(height: 4),
        Text(
          widget.item.timeAgo,
          style: TextStyle(
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
