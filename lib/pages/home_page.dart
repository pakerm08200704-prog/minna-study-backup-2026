import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'grammar_detail_page.dart';
import '../utils/score_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<int, int> _highScores = {};
  // ✅ 新增：用來存放每一課自訂的標題
  Map<int, String> _customTitles = {};

  final List<Map<String, dynamic>> lessons = const [
    {'title': '自我介紹', 'icon': Icons.face},
    {'title': '事物代名詞', 'icon': Icons.category},
    {'title': '場所代名詞', 'icon': Icons.location_on},
    {'title': '時間與星期', 'icon': Icons.access_time},
    {'title': '移動去來回', 'icon': Icons.directions_run},
    {'title': '動作與對象', 'icon': Icons.shopping_cart},
    {'title': '授授關係', 'icon': Icons.card_giftcard},
    {'title': '形容詞介紹', 'icon': Icons.wb_sunny},
    {'title': '好惡與能力', 'icon': Icons.favorite},
    {'title': '存在與位置', 'icon': Icons.home},
    {'title': '數量與期間', 'icon': Icons.exposure_plus_1},
    {'title': '過去式變化', 'icon': Icons.history},
  ];

  @override
  void initState() {
    super.initState();
    _refreshAllData(); // 初始化時同步載入分數與標題
  }

  // ✅ 封裝一個方法，同時重新載入分數與自訂標題
  Future<void> _refreshAllData() async {
    await _loadAllScores();
    await _loadCustomTitles();
  }

  Future<void> _loadAllScores() async {
    Map<int, int> scores = {};
    for (int i = 1; i <= lessons.length; i++) {
      int s = await ScoreManager.getHighScore(i);
      scores[i] = s;
    }
    if (!mounted) return;
    setState(() => _highScores = scores);
  }

  // ✅ 新增：掃描所有存檔，載入使用者修改過的標題
  Future<void> _loadCustomTitles() async {
    final prefs = await SharedPreferences.getInstance();
    Map<int, String> titles = {};
    
    for (int i = 1; i <= lessons.length; i++) {
      String? customData = prefs.getString('custom_lesson_$i');
      if (customData != null) {
        final Map<String, dynamic> data = json.decode(customData);
        if (data['title'] != null && data['title'].toString().isNotEmpty) {
          titles[i] = data['title'];
        }
      }
    }
    if (!mounted) return;
    setState(() => _customTitles = titles);
  }

  Future<Map<String, dynamic>> _getLessonData(int lessonNum) async {
    final prefs = await SharedPreferences.getInstance();
    String? customData = prefs.getString('custom_lesson_$lessonNum');

    if (customData != null) {
      return json.decode(customData);
    }

    try {
      final String jsonString = await rootBundle.loadString('assets/data/lesson$lessonNum.json');
      return json.decode(jsonString);
    } catch (e) {
      debugPrint('SoraTalk: 為第 $lessonNum 課建立專屬空白資料');
      return {
        'lessonNumber': lessonNum,
        'title': (lessonNum <= lessons.length) ? lessons[lessonNum - 1]['title'] : '第 $lessonNum 課',
        'vocabularies': [],
        'grammarPoints': [],
        'quiz': []
      };
    }
  }

  Future<void> _handleLessonTap(int lessonNum) async {
    try {
      final rawData = await _getLessonData(lessonNum);
      final Map<String, dynamic> independentData = json.decode(json.encode(rawData));

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GrammarDetailPage(lessonData: independentData),
        ),
      );
      
      // ✅ 從編輯頁面回來後，刷新所有數據（包含標題）
      _refreshAllData(); 
    } catch (e) {
      debugPrint('SoraTalk 錯誤: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('我們的日本語', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.85,
          ),
          itemCount: lessons.length,
          itemBuilder: (context, index) {
            final lessonNum = index + 1;
            final int currentScore = _highScores[lessonNum] ?? 0;
            
            // ✅ 核心修正點：優先顯示自訂標題，若無則顯示預設標題
            final String displayTitle = _customTitles[lessonNum] ?? lessons[index]['title'];
            
            return InkWell(
              onTap: () => _handleLessonTap(lessonNum),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade400, Colors.indigo.shade700],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Icon(lessons[index]['icon'], color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text('第 $lessonNum 課', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        displayTitle, // ✅ 顯示動態標題
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text('最高分: $currentScore', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}