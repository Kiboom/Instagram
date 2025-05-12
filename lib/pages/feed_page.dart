import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:instagram/data/post.dart';
import 'package:instagram/pages/login_page.dart';
import 'package:instagram/pages/write_page.dart';
import 'package:instagram/widgets/post_widget.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<Post> _posts = [];
  List<String?> _activeUsers = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _loadActiveUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: const Color(0xFFF1F2F3),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () {
            return _loadPosts();
          },
          child: ListView(
            children: [
              // 인스타그램에 접속한 유저 목록
              _buildActiveUsers(),

              // 인스타그램 피드 카드
              for (final item in _posts) PostWidget(item: item),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.logout_rounded),
        onPressed: () async {
          // 과제: FirebaseAuth.instance를 활용해서 로그아웃 기능을 완성해보세요!
          // 스펙1) FirebaseAuth.instance를 활용해서 로그아웃을 합니다.
          await FirebaseAuth.instance.signOut();

          // 스펙2) Navigator.of(context).push를 활용해서 로그인 페이지로 이동합니다.
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return LoginPage();
              },
            ),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF1F2F3),
      title: Image.asset('assets/logo2.png', width: 120),
      centerTitle: true,
      actions: [
        Container(
          margin: EdgeInsets.only(right: 16),
          child: IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () async {
              // 글쓰기 페이지로 이동
              await Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (context) {
                    return WritePage();
                  },
                ),
              );

              // 글쓰기 페이지가 종료된 후에는 피드를 재갱신
              _loadPosts();
            },
          ),
        ),
      ],
    );
  }

  // 접속한 사용자 리스트
  Widget _buildActiveUsers() {
    return Container(
      height: 100,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        scrollDirection: Axis.horizontal,
        children: [
          Container(
            width: 70,
            alignment: Alignment.center,
            child: Text(
              "현재 접속한 사용자의 수\n${_activeUsers.length}명",
              textAlign: TextAlign.center,
            ),
          ),

          for (final userName in _activeUsers) 
            _buildActiveUserCircle(userName),
        ],
      ),
    );
  }

  // 접속한 사용자 동그라미
  Widget _buildActiveUserCircle(String? userName) {
    if (userName == null) {
      return const SizedBox.shrink();
    }
    return Container(
      width: 72,
      height: 72,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Colors.yellow,
            Colors.orangeAccent,
            Colors.redAccent,
            Colors.purpleAccent,
          ],
          stops: [0.1, 0.4, 0.6, 0.9],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF1F2F3),
        ),
        child: Container(
          padding: EdgeInsets.all(10),
          alignment: Alignment.center,
          child: Text(
            userName,
            overflow: TextOverflow.fade,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.black87),
          ),
        ),
      ),
    );
  }

  // 활동 중인 사용자 목록을 받아옵니다.
  void _loadActiveUsers() {
    FirebaseDatabase.instance.ref().child('active_users').onValue.listen((
      event,
    ) {
      setState(() {
        _activeUsers = List<String?>.from(
          event.snapshot.value as List<dynamic>,
        );
      });
    });
  }

  Future<void> _loadPosts() async {
    // FirebaseFirestore로부터 데이터를 받아옵니다.
    final snapshot =
        await FirebaseFirestore.instance
            .collection("posts")
            .orderBy("createdAt", descending: true)
            .get();

    final documents = snapshot.docs;

    List<Post> posts = [];

    for (var document in documents) {
      // 과제1: Map 객체를 Post로 변환시켜줍니다.
      final map = document.data();
      final Post post = Post(
        uid: map["uid"],
        username: map["username"],
        description: map["description"],
        imageUrl: map["imageUrl"],
        createdAt: map["createdAt"],
      );

      // 과제2: Post 객체를 posts 리스트에 포함시켜줍니다.
      posts.add(post);
    }

    // Post 객체를 이용하여 화면을 다시 그립니다.
    setState(() {
      _posts = posts;
    });
  }
}
