import 'package:flutter/material.dart';
import 'dart:js' as js;

class VocabularyListWidget extends StatelessWidget {
  // 修改：不再接收 lessonNumber，改為接收從 JSON 解析出來的單字列表
  final List<dynamic> vocabularies;

  const VocabularyListWidget({super.key, required this.vocabularies});

  // 保留並優化你的 Web Speech API 呼叫邏輯
  void _speak(String text) {
    if (text.isEmpty) return;

    js.context.callMethod('eval', [
      """
      (function() {
        window.speechSynthesis.cancel();
        var msg = new SpeechSynthesisUtterance();
        msg.text = '$text';
        msg.lang = 'ja-JP';
        msg.rate = 0.9;
        msg.pitch = 1.0;

        var voices = window.speechSynthesis.getVoices();
        var selectedVoice = voices.find(function(v) {
          return v.name.includes('Google') && v.lang.includes('ja');
        }) || voices.find(function(v) {
          return v.lang.includes('ja');
        });

        if (selectedVoice) {
          msg.voice = selectedVoice;
        }

        window.speechSynthesis.speak(msg);
      })();
      """
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // 判斷傳入的 List 是否為空
    if (vocabularies.isEmpty) {
      return const Center(
        child: Text('目前沒有單字資料', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: vocabularies.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.grey),
      itemBuilder: (context, index) {
        final item = vocabularies[index];
        
        // 為了相容不同的 JSON 欄位命名，這裡做一點彈性處理
        final String word = item['word'] ?? item['kanji'] ?? '';
        final String reading = item['reading'] ?? item['kana'] ?? '';
        final String meaning = item['meaning'] ?? item['mean'] ?? '';

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          title: Text(
            word.isNotEmpty ? word : reading,
            style: const TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              color: Colors.indigo
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 如果漢字跟假名不同，才顯示假名
              if (word != reading && reading.isNotEmpty) 
                Text(reading, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text(
                meaning, 
                style: const TextStyle(fontSize: 16, color: Colors.black87)
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.volume_up, color: Colors.blue),
            onPressed: () => _speak(reading),
          ),
          onTap: () => _speak(reading),
        );
      },
    );
  }
}