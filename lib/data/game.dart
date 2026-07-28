// ignore_for_file: constant_identifier_names

enum GameStatus { READY, START, END }

class GameData {
  final GameStatus status;
  final int timeout;
  final Map<String, int> result;

  GameData({
    required this.status,
    required this.timeout,
    required this.result,
  });

  factory GameData.fromMap(Map? data) {
    if (data == null) {
      return GameData(status: GameStatus.READY, timeout: 0, result: {});
    }

    final GameStatus status = GameStatus.values.firstWhere(
      (e) => e.name == data['game_status'],
      orElse: () => GameStatus.READY,
    );

    final int timeout = (data['game_timeout'] as int?) ?? 0;
    final Map resultMap = (data['game_result'] as Map?) ?? {};
    final Map<String, int> result = {};

    for (final entry in resultMap.entries) {
      result[entry.key.toString()] = entry.value as int;
    }
    return GameData(status: status, timeout: timeout, result: result);
  }
}
