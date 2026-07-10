import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:instagram/data/post.dart';
import 'package:instagram/pages/login_page.dart';
import 'package:instagram/pages/online_game_page.dart';
import 'package:instagram/pages/write_page.dart';
import 'package:instagram/widgets/post_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    _loadLoggedInUsers();
    _reportLoggedIn();
  }

  @override
  void dispose() {
    super.dispose();
    _reportLoggedOut();
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
    // Supabase로부터 날 것의 posts 데이터를 받아옵니다.
    final rows = await Supabase.instance.client.from('posts').select().order('created_at', ascending: false);

    // Supabase로부터 받아온 날 것의 데이터(rows)를 List<Post>객체로 변환합니다.
    List<Post> posts = [];

    for (var row in rows) {
      // row를 Post 객체로 변환시켜서, posts 리스트에 담아줍니다.
      final post = Post(
        id: row["id"].toString(),
        uid: row["uid"],
        username: row["username"],
        imageUrl: row["image_url"],
        description: row["description"],
        createdAt: Timestamp.fromDate(DateTime.parse(row["created_at"])),
      );
      posts.add(post);
    }

    // Post 객체를 이용하여 화면을 다시 그립니다.
    setState(() {
      _posts = posts;
    });
  }

  // 활동 중인 사용자 목록을 받아옵니다.
  Future<void> _loadLoggedInUsers() async {
    FirebaseDatabase.instance
        .ref() // 실시간 정보를 받아오는 객체
        .child('logged_in_users') // logged_in_users 데이터에 접근
        .onValue
        .listen(_onUpdatedUsers); // logged_in_users 데이터를 관찰
  }

  // 활동 중인 사용자에 변경이 생길 때마다 호출되는 함수
  void _onUpdatedUsers(DatabaseEvent event) {
    // Realtime DB에 업데이트 된 내역을 받아옵니다.
    final List? snapshot = event.snapshot.value as List?;

    // 업데이트 된 내역을 유저 리스트로 변환해줍니다.
    final List<String?> users = List<String?>.from(snapshot ?? []);

    // 새로운 유저 리스트를 UI에 반영합니다.
    setState(() {
      _loggedInUsers = users;
    });
  }

  // 나의 접속 상태를 알립니다.
  Future<void> _reportLoggedIn() async {
    // Realtime Database에서 현재 접속한 사람들을 조회합니다.
    DatabaseEvent currentData = await FirebaseDatabase.instance.ref().child("logged_in_users").once();

    // 현재 접속한 사람들을 List 형태로 변환합니다.
    final List? snapshot = currentData.snapshot.value as List?;
    final List<String?> loggedInUsers = snapshot?.cast<String?>() ?? [];

    // 나의 닉네임 가져오기
    final String? myName = FirebaseAuth.instance.currentUser?.displayName;

    // 나의 이름이 현재 접속한 사람들 목록에 없다면 추가합니다.
    if (loggedInUsers.contains(myName) == false) {
      loggedInUsers.insert(0, myName);
    }

    // Realtime Database에 접속한 사람들을 업데이트합니다.
    FirebaseDatabase.instance.ref().child("logged_in_users").set(loggedInUsers);
  }

  // 나의 미접속 상태를 알립니다.
  Future<void> _reportLoggedOut() async {
    // Realtime Database에서 현재 접속한 사람들을 조회합니다.
    DatabaseEvent currentData = await FirebaseDatabase.instance.ref().child("logged_in_users").once();

    // 현재 접속한 사람들을 List 형태로 변환합니다.
    List<String?> loggedInUsers = List<String?>.from(currentData.snapshot.value as List<dynamic>);

    // 나의 닉네임 가져오기
    final String? myName = FirebaseAuth.instance.currentUser?.displayName;

    // 나의 이름이 현재 접속한 사람들 목록에 있다면, 리스트에서 제거합니다.
    if (loggedInUsers.contains(myName)) {
      loggedInUsers.remove(myName);
    }

    // Realtime Database에 접속한 사람들을 업데이트합니다.
    FirebaseDatabase.instance.ref().child("logged_in_users").set(loggedInUsers);
  }

  // 공지사항을 RemoteConfig로부터 받아와서 보여줍니다.
  Future<void> _loadNotice() async {
    // TODO: RemoteConfig에서 notice 값을 받아와서 다이얼로그로 보여줍니다.
    String notice = "";

    showDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('공지사항'),
          content: Container(
            margin: const EdgeInsets.only(top: 10),
            child: Text(notice),
          ),
          actions: [
            CupertinoButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                '확인',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
