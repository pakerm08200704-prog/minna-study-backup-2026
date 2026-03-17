import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart'; // ✅ 新增：Firebase 核心
import 'package:firebase_analytics/firebase_analytics.dart'; // ✅ 新增：Google 追蹤
import 'pages/home_page.dart';

void main() async {
  // 確保 Flutter 引擎初始化
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ✅ 啟動 Firebase (這會讀取您 android/app 下的 google-services.json)
    await Firebase.initializeApp();
    
    // ✅ 啟動追蹤實例
    FirebaseAnalytics analytics = FirebaseAnalytics.instance;
    await analytics.logAppOpen(); // 紀錄 App 開啟
    
    debugPrint("Firebase 初始化成功！");
  } catch (e) {
    debugPrint("Firebase 初始化失敗: $e");
  }

  runApp(const SoraTalkApp());
}

class SoraTalkApp extends StatelessWidget {
  const SoraTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '我們的日本語',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const HomePage(),
    );
  }
}

// --- 文法重點頁面 (GrammarPage) ---
class GrammarPage extends StatelessWidget {
  final int lessonNum;
  final List<dynamic> grammars;

  const GrammarPage({super.key, required this.lessonNum, required this.grammars});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('第 $lessonNum 課 文法重點'),
        backgroundColor: Colors.indigo.shade50,
      ),
      body: grammars.isEmpty
          ? const Center(child: Text('本課尚無文法資料'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: grammars.length,
              itemBuilder: (context, index) {
                final item = grammars[index];
                
                // ✅ 相容新舊欄位名稱
                String desc = item['description'] ?? item['explanation'] ?? '無解釋說明';
                
                // 取得例句清單
                List<dynamic> examples = item['examples'] ?? [];
                
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item['title'] ?? '未命名文法',
                                style: const TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold, 
                                  color: Colors.indigo
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        
                        const Text('【說明】', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                        const SizedBox(height: 4),
                        Text(desc, style: const TextStyle(fontSize: 15)),
                        
                        const SizedBox(height: 16),
                        
                        if (examples.isNotEmpty) ...[
                          const Text('【例句】', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                          const SizedBox(height: 4),
                          ...examples.map((ex) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• $ex',
                              style: const TextStyle(
                                fontSize: 15, 
                                fontStyle: FontStyle.italic,
                                color: Colors.black87
                              ),
                            ),
                          )),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}