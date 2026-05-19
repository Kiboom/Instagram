import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instagram/data/post.dart';
import 'package:instagram/widgets/post_widget.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<Post> _posts = [];

  @override
  void initState() {
    super.initState();
    loadPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F3),
      body: SafeArea(
        child: ListView(
          children: [
            // 인스타그램 피드 카드
            for (final item in _posts)
              PostWidget(
                item: item,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> loadPosts() async {
    // FirebaseFirestore로부터 데이터를 받아옵니다.
    final snapshot = await FirebaseFirestore.instance.collection("posts").orderBy("created_at", descending: true).get();
    final documents = snapshot.docs;

    // 받아온 데이터를 Post 객체 리스트로 변환합니다.
    final List<Post> posts = [
      for (final doc in documents)
        Post(
          uid: doc.id,
          username: doc["username"],
          description: doc["description"],
          imageUrl: doc["image_url"],
          createdAt: doc["created_at"],
        ),
    ];

    // Post 객체를 이용하여 화면을 다시 그립니다.
    setState(() {
      _posts = posts;
    });
  }
}
