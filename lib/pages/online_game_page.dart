import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instagram/data/game.dart';

class OnlineGamePage extends StatefulWidget {
  const OnlineGamePage({super.key});

  @override
  State<OnlineGamePage> createState() => OnlineGamePageState();
}

class OnlineGamePageState extends State<OnlineGamePage> {
  @override
  void initState() {
    super.initState();
    gameListener = FirebaseDatabase.instance.ref('game').onValue.listen(onGameUpdate);
  }

  @override
  void dispose() {
    gameListener?.cancel(); // 게임 화면이 꺼지면, 게임 상태를 관찰하는 객체를 퇴근시켜줍니다.
    countdownTimer?.cancel();
    focusNode.dispose();
    super.dispose();
  }

  bool isAdmin = false; // Only the instructor keeps this true, on their local machine.
  int adminTimeout = 10;

  int myCount = 0;
  int gameTimeout = 0;
  int remainingSeconds = 0;
  int? revealedRank;
  bool showResult = false;
  Map<String, int> gameResult = {};
  GameStatus gameStatus = GameStatus.READY;

  StreamSubscription<DatabaseEvent>? gameListener;
  Timer? countdownTimer;
  final FocusNode focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1F2F3),
        title: const Text(
          '키보드 연타 게임',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: KeyboardListener(
        focusNode: focusNode,
        autofocus: true,
        onKeyEvent: onKeyEvent,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24),
          child: buildBody(),
        ),
      ),
      bottomNavigationBar: isAdmin ? buildAdminPanel() : null,
    );
  }

  Widget buildAdminPanel() {
    return SafeArea(
      child: Container(
        color: const Color(0xFFF1F2F3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      adminTimeout = (adminTimeout - 5).clamp(5, 60);
                    });
                  },
                  icon: const Icon(Icons.remove),
                ),
                Text(
                  '$adminTimeout초',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      adminTimeout = (adminTimeout + 5).clamp(5, 60);
                    });
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: gameStatus == GameStatus.START ? null : startGame,
                  child: const Text('시작'),
                ),
                Container(width: 8),
                ElevatedButton(
                  onPressed: gameStatus == GameStatus.START ? stopGame : null,
                  child: const Text('중지'),
                ),
                Container(width: 8),
                ElevatedButton(
                  onPressed: resetGame,
                  child: const Text('초기화'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // set() replaces the whole 'game' node, so the previous game_result is cleared.
  Future<void> startGame() async {
    await FirebaseDatabase.instance.ref('game').set({
      'game_status': GameStatus.START.name,
      'game_timeout': adminTimeout,
    });
  }

  Future<void> stopGame() async {
    await FirebaseDatabase.instance.ref('game/game_status').set(GameStatus.END.name);
  }

  Future<void> resetGame() async {
    await FirebaseDatabase.instance.ref('game').set({
      'game_status': GameStatus.READY.name,
      'game_timeout': adminTimeout,
    });
  }

  Widget buildBody() {
    if (gameStatus == GameStatus.READY) {
      return buildReady();
    }
    if (gameStatus == GameStatus.START) {
      return buildPlaying();
    }
    if (showResult) {
      return buildResult();
    }
    return buildEnd();
  }

  Widget buildReady() {
    return Text(
      '$gameTimeout초 동안 엔터키를 연타하세요!',
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget buildPlaying() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '남은 시간 $remainingSeconds초',
          style: const TextStyle(
            fontSize: 18,
            color: Colors.black54,
          ),
        ),
        Container(height: 24),
        Text(
          '$myCount',
          style: const TextStyle(
            fontSize: 96,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(height: 8),
        const Text(
          '엔터를 계속 치세요',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget buildEnd() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '게임 종료!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(height: 24),
        ElevatedButton(
          onPressed: () {
            setState(() {
              showResult = true;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: const Text(
              '결과 보기',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildResult() {
    final List<MapEntry<String, int>> entries = gameResult.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    final List<MapEntry<String, int>> top3 = entries.take(3).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '순위',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(height: 24),
        for (int i = 0; i < top3.length; i++) ...[
          buildRankCard(i + 1, top3[i].key, top3[i].value),
        ],
      ],
    );
  }

  Widget buildRankCard(int rank, String username, int count) {
    final bool isRevealed = revealedRank == rank;
    const List<Color> rankColors = [Colors.amber, Colors.grey, Colors.brown];
    final Color color = rankColors[rank - 1];
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            revealedRank = rank;
          });
        },
        child: Container(
          width: 280,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2),
          ),
          child: Column(
            children: [
              Text(
                '$rank위',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Container(height: 8),
              if (isRevealed) ...[
                Text(username, style: const TextStyle(fontSize: 18)),
                Text(
                  '$count회',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ] else ...[
                const Text(
                  '클릭!',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 카운트 다운을 시작합니다. 매 초 남은 시간 정보를 업데이트 합니다.
  void startCountdown(int seconds) {
    countdownTimer?.cancel();
    remainingSeconds = seconds;
    countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (remainingSeconds <= 0) {
          timer.cancel();
          return;
        }
        setState(() {
          remainingSeconds--;
        });
      },
    );
  }

  /// 게임 데이터가 업데이트 되었을 때 호출되는 함수입니다.
  void onGameUpdate(DatabaseEvent event) {
    // Realtime Database에서 수신한 데이터를 GameData로 변환합니다.
    final GameData newGameData = GameData.fromMap(event.snapshot.value as Map?);

    // 게임이 시작되면 카운트다운을 시작합니다.
    if (newGameData.status == GameStatus.START && gameStatus != GameStatus.START) {
      startCountdown(newGameData.timeout);
      myCount = 0;
    }

    // 새로운 게임 데이터를 UI에 반영합니다.
    setState(() {
      gameStatus = newGameData.status;
      gameTimeout = newGameData.timeout;
      gameResult = newGameData.result;
      if (newGameData.status != GameStatus.END) {
        showResult = false;
        revealedRank = null;
      }
    });
  }

  /// 키보드의 이벤트를 다루는 함수
  void onKeyEvent(KeyEvent event) {
    if (gameStatus != GameStatus.START) return; // 게임이 시작되기 전에는 키보드 입력을 무시합니다.
    if (event is! KeyDownEvent) return; // 키보드를 확실하게 눌렀다 뗀 경우에만 인정합니다.
    if (event.logicalKey != LogicalKeyboardKey.enter) return; // ENTER 키를 누른 경우만 인정합니다.

    setState(() {
      myCount++;
    });

    // Realtime Database에 내가 입력한 한 횟수를 업데이트합니다.
    final myName = FirebaseAuth.instance.currentUser?.displayName;
    final databasePath = 'game/game_result/$myName';

    // TODO: Realtime Database의 path 위치에 나의 엔터 횟수를 업데이트 합니다!
    FirebaseDatabase.instance.ref(databasePath).set(myCount);
  }
}
