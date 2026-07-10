import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instagram/data/post.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final double _imageHeight = 400.0;
  final TextEditingController _commentController = TextEditingController();
  List<Comment> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
          _buildProfileImage(),
          Container(height: 12),
          _buildImage(),
          Container(height: 12),
          _buildIcons(),
          Container(height: 12),
          _buildLikeAndComments(),
          Container(height: 8),
          _buildComments(),
          _buildCommentInput(),
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
    if (widget.item.imageUrl?.isEmpty == true) {
      return const SizedBox.shrink();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: widget.item.imageUrl ?? "",
        width: double.infinity,
        height: _imageHeight,
        fit: BoxFit.cover,
        placeholder: (context, url) {
          return _buildPlaceholderImage();
        },
        errorWidget: (context, url, error) {
          return _buildErrorImage();
        },
      ),
    );
  }

  Widget _buildErrorImage() {
    return Container(
      height: _imageHeight,
      alignment: Alignment.center,
      child: const Icon(
        Icons.error,
        size: 56,
        color: Colors.black54,
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: _imageHeight,
      alignment: Alignment.center,
      color: Colors.black.withValues(alpha: 0.03),
      child: Container(
        width: 30,
        height: 30,
        child: const CircularProgressIndicator(
          strokeWidth: 1.0,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.black45),
          strokeCap: StrokeCap.round,
        ),
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
          '댓글 ${_comments.length}개 모두 보기',
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

  Widget _buildComments() {
    if (_comments.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final comment in _comments) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.username,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(width: 8),
                Expanded(
                  child: Text(
                    comment.comment,
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const CircleAvatar(radius: 14),
          Container(width: 8),
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: '댓글 달기...',
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (_) => _createComment(),
            ),
          ),
          TextButton(
            onPressed: _createComment,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(40, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              '게시',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadComments() async {
    final rows = await Supabase.instance.client
        .from('comments')
        .select()
        .eq('post_id', widget.item.id)
        .order('created_at', ascending: true);
    final List<Comment> comments = [];
    for (final row in rows) {
      comments.add(
        Comment(
          uid: row['uid'],
          username: row['username'],
          comment: row['content'],
          createdAt: DateTime.parse(row['created_at']),
        ),
      );
    }
    setState(() {
      _comments = comments;
    });
  }

  Future<void> _createComment() async {
    final String content = _commentController.text.trim();
    if (content.isEmpty) {
      return;
    }
    await Supabase.instance.client.from('comments').insert({
      'post_id': widget.item.id,
      'uid': FirebaseAuth.instance.currentUser?.uid,
      'username': FirebaseAuth.instance.currentUser?.displayName,
      'content': content,
    });
    _commentController.clear();
    await _loadComments();
  }
}
