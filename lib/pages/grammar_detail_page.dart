import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'quiz_page.dart';
import '../widgets/vocabulary_list_widget.dart';
import 'lesson_editor_page.dart';

class GrammarDetailPage extends StatefulWidget {
  final Map<String, dynamic> lessonData;
  const GrammarDetailPage({super.key, required this.lessonData});

  @override
  State<GrammarDetailPage> createState() => _GrammarDetailPageState();
}

class _GrammarDetailPageState extends State<GrammarDetailPage> {
  late Map<String, dynamic> _currentData;

  @override
  void initState() {
    super.initState();
    // 初始化時直接使用傳入的資料
    _currentData = widget.lessonData;
    _checkLocalStorageOnStart();
  }

  Future<void> _checkLocalStorageOnStart() async {
    await _refreshData();
  }

  Future<void> _refreshData() async {
    final int lessonNumber = _currentData['lessonNumber'] ?? 0;
    final prefs = await SharedPreferences.getInstance();
    String? customData = prefs.getString('custom_lesson_$lessonNumber');

    if (customData != null) {
      if (!mounted) return; 
      setState(() {
        _currentData = json.decode(customData);
      });
      debugPrint('SoraTalk: 已刷新第 $lessonNumber 課的自訂內容');
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _currentData;
    final int lessonNumber = data['lessonNumber'] ?? 0;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(data['title'] ?? '第 $lessonNumber 課'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_note_outlined),
              tooltip: '編輯本課內容',
              onPressed: () async {
                // ✅ 關鍵修正：進入編輯器前再次執行深拷貝，確保編輯器與本頁資料完全獨立
                final Map<String, dynamic> dataForEditor = json.decode(json.encode(data));
                
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LessonEditorPage(
                      lessonNum: lessonNumber,
                      initialData: dataForEditor,
                    ),
                  ),
                );
                // 從編輯器回來後，重新從 SharedPreferences 抓取最新存檔
                _refreshData();
              },
            ),
          ],
          bottom: TabBar(
            indicatorColor: Colors.orange,
            indicatorWeight: 4,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.6),
            labelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: '單字', icon: Icon(Icons.translate, size: 28)),
              Tab(text: '文法', icon: Icon(Icons.book, size: 28)),
              Tab(text: '測驗', icon: Icon(Icons.edit_note, size: 32)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            VocabularyListWidget(
              vocabularies: data['vocabularies'] ?? [],
            ),
            _buildGrammarList(data),
            _buildQuizEntry(data),
          ],
        ),
      ),
    );
  }

  // --- 修正：文法顯示邏輯 ---
  Widget _buildGrammarList(Map<String, dynamic> data) {
    final List grammarPoints = data['grammarPoints'] ?? [];
    
    if (grammarPoints.isEmpty) {
      return const Center(child: Text('目前沒有文法重點，點擊右上角新增吧！'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: grammarPoints.length,
      itemBuilder: (context, index) {
        final point = grammarPoints[index];
        
        // ✅ 增加相容性：同時支援新版的 description 或舊版的 explanation
        final String description = point['description'] ?? point['explanation'] ?? '暫無說明';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  point['title'] ?? '未命名文法',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
                if (point['examples'] != null && (point['examples'] as List).isNotEmpty) ...[
                  const Divider(height: 30),
                  ...(point['examples'] as List).map((ex) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ex['jp'] ?? '', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(ex['zh'] ?? '', style: TextStyle(fontSize: 15, color: Colors.blueGrey[800])),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // --- 修正：測驗入口邏輯 ---
  Widget _buildQuizEntry(Map<String, dynamic> data) {
    final List quizzes = data['quiz'] ?? [];

    if (quizzes.isEmpty) {
      return const Center(child: Text('本課暫無測驗資料'));
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.edit_note, size: 80, color: Colors.orange),
          const SizedBox(height: 20),
          Text('本課共有 ${quizzes.length} 題測驗，準備好挑戰了嗎？', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizPage(
                    quizList: quizzes,
                    lessonNum: data['lessonNumber'] ?? 0,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('開始測驗', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}