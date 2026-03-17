import 'package:shared_preferences/shared_preferences.dart';

class ScoreManager {
  static const String _keyPrefix = 'lesson_score_';

  // 儲存最高分：只有當新分數大於舊分數時才會更新
  static Future<void> saveHighScore(int lessonNumber, int score) async {
    final prefs = await SharedPreferences.getInstance();
    int currentHighScore = prefs.getInt('$_keyPrefix$lessonNumber') ?? 0;
    
    if (score > currentHighScore) {
      await prefs.setInt('$_keyPrefix$lessonNumber', score);
    }
  }

  // 讀取單課最高分
  static Future<int> getHighScore(int lessonNumber) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_keyPrefix$lessonNumber') ?? 0;
  }

  // (選填) 如果未來想重設所有分數可以使用
  static Future<void> clearAllScores() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 1; i <= 12; i++) {
      await prefs.remove('$_keyPrefix$i');
    }
  }
}