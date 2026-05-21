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
  State<FeedPage> createState() => FeedPageState();
}

class FeedPageState extends State<FeedPage> {
  List<Post> _posts = [];
  List<String?> _loggedInUsers = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: const Color(0xFFF1F2F3),
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: SafeArea(
          bottom: false,
          child: ListView(
            children: [
              // 인스타그램 현재 접속한 유저들의 목록
              _buildActiveUsers(),

              // 인스타그램 피드 카드
              for (final item in _posts) PostWidget(item: item),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildOnlineGameButton(),
    );
  }

  Widget _buildOnlineGameButton() {
    return FloatingActionButton(
      backgroundColor: Colors.black,
      child: const Icon(
        Icons.play_arrow_rounded,
        color: Colors.white,
        size: 32,
      ),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) {
              return const OnlineGamePage();
            },
          ),
        );
      },
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF1F2F3),
      title: Image.asset('assets/logo2.png', width: 120),
      centerTitle: true,
      actions: [
        _buildWriteButton(),
        _buildLogoutButton(),
      ],
    );
  }

  Widget _buildWriteButton() {
    return Container(
      margin: EdgeInsets.only(right: 8),
      child: IconButton(
        icon: const Icon(Icons.add_box_outlined),
        onPressed: () async {
          // 글쓰기 페이지로 이동한 다음에 닫힐 때까지 대기한다.
          await Navigator.of(context).push(
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
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: EdgeInsets.only(right: 16),
      child: IconButton(
        icon: const Icon(Icons.logout),
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          await Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) {
                return LoginPage();
              },
            ),
          );
        },
      ),
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
          for (final userName in _loggedInUsers) _buildActiveUserCircle(userName),
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

  Future<void> _loadPosts() async {
    // FirebaseFirestore로부터 데이터를 받아옵니다.
    final snapshot = await FirebaseFirestore.instance.collection("posts").orderBy("created_at", descending: true).get();

    // Documents: Firebase Firestore로부터 받아온 날 것의 데이터
    final documents = snapshot.docs;

    // 과제: FirebaseFirestore로부터 받아온 날 것의 데이터(documents)를 List<Post>객체로 변환합니다.
    List<Post> posts = [];

    for (var document in documents) {
      // document를 Post 객체로 변환시켜서, posts 리스트에 담아줍니다.
      final post = Post(
        uid: document.get("uid"),
        username: document.get("username"),
        imageUrl: document.get("image_url"),
        description: document.get("description"),
        createdAt: document.get("created_at"),
      );
      posts.add(post);
    }

    // Post 객체를 이용하여 화면을 다시 그립니다.
    setState(() {
      _posts = posts;
    });
  }
}
