import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:instagram/data/post.dart';
import 'package:instagram/pages/login_page.dart';
import 'package:instagram/pages/write_page.dart';
import 'package:instagram/widgets/post_widget.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => FeedPageState();
}

class FeedPageState extends State<FeedPage> {
  List<Post> _posts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 글쓰기 버튼
      appBar: _buildAppBar(),
      backgroundColor: const Color(0xFFF1F2F3),
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: SafeArea(
          bottom: false,
          child: CupertinoScrollbar(
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
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF1F2F3),
      title: Image.asset(
        'assets/logo2.png',
        width: 120,
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            Icons.add_box_outlined,
            color: Colors.black,
          ),
          onPressed: () async {
            // 글쓰기 페이지로 이동
            await Navigator.push(
              context,
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (context) {
                  return WritePage();
                },
              ),
            );
            _loadPosts();
          },
        ),
        Container(
          margin: EdgeInsets.only(right: 16),
          child: IconButton(
            icon: Icon(
              Icons.logout_rounded,
              color: Colors.black,
            ),
            onPressed: () async {
              // 로그아웃 처리
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) {
                    return LoginPage();
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _loadPosts() async {
    // FirebaseFirestore로부터 데이터를 받아옵니다.
    final snapshot = await FirebaseFirestore.instance.collection("posts").orderBy("created_at", descending: true).get();
    final documents = snapshot.docs;

    // FirebaseFirestore로부터 받아온 데이터를 Post 객체로 변환합니다.
    List<Post> posts = [
      for (final doc in documents)
        Post(
          uid: doc["uid"],
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
