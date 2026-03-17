import 'package:flutter/material.dart';
import '../utils/score_manager.dart';

class QuizPage extends StatefulWidget {
  // ✅ 修正參數名稱：對應 GrammarDetailPage 的傳入參數
  final List<dynamic> quizList;
  final int lessonNum;

  const QuizPage({
    super.key, 
    required this.quizList, 
    required this.lessonNum,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int currentQuestionIndex = 0;
  int score = 0;

  // 存放打亂後的選項與正確索引
  List<String> _shuffledOptions = [];
  int _correctIndex = 0;

  @override
  void initState() {
    super.initState();
    _prepareQuestion(); // 初始化第一題
  }

  // 打亂選項的邏輯
  void _prepareQuestion() {
    final quiz = widget.quizList[currentQuestionIndex];
    
    // 取得正確答案索引 (相容 'answerIndex' 或 'answer')
    int originalAnswerIndex = quiz['answerIndex'] ?? quiz['answer'] ?? 0;
    
    // 取得原始資料中的正確答案文字
    String correctAnswerText = quiz['options'][originalAnswerIndex];
    
    // 複製一份清單並打亂
    List<String> options = List<String>.from(quiz['options']);
    options.shuffle();
    
    setState(() {
      _shuffledOptions = options;
      // 找出正確答案在打亂後的新位置
      _correctIndex = options.indexOf(correctAnswerText);
    });
  }

  void checkAnswer(int selectedIndex) {
    final currentQuiz = widget.quizList[currentQuestionIndex];
    // 使用打亂後的索引來判斷
    bool isCorrect = selectedIndex == _correctIndex;
    
    if (isCorrect) score++;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: isCorrect ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 10),
            Text(isCorrect ? "正解！" : "可惜！"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isCorrect ? "回答正確！" : "這題答錯囉，沒關係。"),
            const SizedBox(height: 16),
            const Text(
              "【文法解析】",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 8),
            // ✅ 修正：相容 'explanation' 或 'description'
            Text(
              currentQuiz['explanation'] ?? currentQuiz['description'] ?? "此題暫無詳細解析。",
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              if (currentQuestionIndex < widget.quizList.length - 1) {
                setState(() {
                  currentQuestionIndex++;
                  _prepareQuestion(); // 切換題目時要重新打亂
                });
              } else {
                showResult();
              }
            },
            child: Text(
              currentQuestionIndex < widget.quizList.length - 1 ? "下一題" : "查看結果",
            ),
          ),
        ],
      ),
    );
  }

  void showResult() async {
    // 這裡請確認你的 ScoreManager 有 saveHighScore 還是 saveScore
    await ScoreManager.saveHighScore(widget.lessonNum, score);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("測驗結束", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              score == widget.quizList.length ? Icons.workspace_premium : Icons.emoji_events, 
              color: Colors.amber, 
              size: 60
            ),
            const SizedBox(height: 16),
            Text(
              "您的得分是：$score / ${widget.quizList.length}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(score == widget.quizList.length ? "太完美了！🎉" : "繼續加油！💪"),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context); 
                Navigator.pop(context); 
              },
              child: const Text("完成並回到課文", style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quiz = widget.quizList[currentQuestionIndex];
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text("第 ${widget.lessonNum} 課 課後練習"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: (currentQuestionIndex + 1) / widget.quizList.length,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
            const SizedBox(height: 24),
            Text(
              "問題 ${currentQuestionIndex + 1} / ${widget.quizList.length}",
              style: const TextStyle(fontSize: 14, color: Colors.blueGrey, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Text(
              quiz['question'] ?? '題目加載中...',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.4),
            ),
            const SizedBox(height: 40),
            ..._shuffledOptions.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    elevation: 1,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    alignment: Alignment.centerLeft,
                  ),
                  onPressed: () => checkAnswer(entry.key),
                  child: Text(
                    "${String.fromCharCode(65 + entry.key)}.   ${entry.value}",
                    style: const TextStyle(fontSize: 17),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}