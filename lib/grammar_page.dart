import 'package:flutter/material.dart';

class GrammarPage extends StatelessWidget {
  final List<dynamic> grammars; // 接收從 JSON 傳進來的文法陣列

  const GrammarPage({super.key, required this.grammars});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('第 1 課 文法重點'),
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: grammars.length,
        itemBuilder: (context, index) {
          final item = grammars[index];
          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 文法標題
                  Text(
                    item['title'] ?? '',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const Divider(),
                  // 句型公式
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                    child: Text('公式：${item['formula'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 10),
                  // 解說
                  Text(item['explanation'] ?? '', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  // 例句
                  const Text('例句：', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  Text(item['example'] ?? '', style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}