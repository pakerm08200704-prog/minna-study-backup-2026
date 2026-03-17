import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:html' as html; 
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;

class LessonEditorPage extends StatefulWidget {
  final int lessonNum;
  final Map<String, dynamic> initialData;

  const LessonEditorPage({super.key, required this.lessonNum, required this.initialData});

  @override
  State<LessonEditorPage> createState() => _LessonEditorPageState();
}

class _LessonEditorPageState extends State<LessonEditorPage> {
  late TextEditingController _titleController;
  List<Map<String, dynamic>> _vocabs = [];
  List<Map<String, dynamic>> _grammars = [];
  List<Map<String, dynamic>> _quizzes = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: "載入中...");
    
    // ✅ 進行深拷貝，確保與主頁資料來源徹底斷開
    final Map<String, dynamic> clonedData = json.decode(json.encode(widget.initialData));
    _initDataWithTemplate(clonedData);
  }

  Future<void> _initDataWithTemplate(Map<String, dynamic> data) async {
    final List currentVocabs = data['vocabularies'] ?? [];
    
    if (currentVocabs.isEmpty) {
      if (mounted) {
        setState(() {
          _vocabs = [];
          _grammars = [];
          _quizzes = [];
          _titleController.text = data['title'] ?? "第 ${widget.lessonNum} 課";
        });
      }
    } else {
      if (mounted) setState(() => _loadData(data));
    }
  }

  void _loadData(Map<String, dynamic> data) {
    if (_titleController.text == "載入中..." || _titleController.text.isEmpty) {
      _titleController.text = data['title'] ?? "第 ${widget.lessonNum} 課";
    }
    
    _vocabs = List<Map<String, dynamic>>.from(json.decode(json.encode(data['vocabularies'] ?? [])));
    _grammars = List<Map<String, dynamic>>.from(json.decode(json.encode(data['grammarPoints'] ?? [])));
    _quizzes = List<Map<String, dynamic>>.from(json.decode(json.encode(data['quiz'] ?? [])));
  }

  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> newData = {
        'lessonNumber': widget.lessonNum, 
        'title': _titleController.text.trim(),
        'vocabularies': _vocabs,
        'grammarPoints': _grammars,
        'quiz': _quizzes, 
      };
      
      String storageKey = 'custom_lesson_${widget.lessonNum}';
      await prefs.setString(storageKey, json.encode(newData));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ 第 ${widget.lessonNum} 課已儲存'), backgroundColor: Colors.green)
        );
        Navigator.pop(context, true); 
      }
    } catch (e) { _showError('儲存失敗：$e'); }
  }

  Future<void> _importFromJson() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['json'],
      );
      if (result != null) {
        final bytes = result.files.first.bytes;
        if (bytes == null) return;
        final String content = utf8.decode(bytes);
        setState(() { _loadData(json.decode(content)); });
      }
    } catch (e) { _showError('讀取失敗'); }
  }

  void _exportToJson() {
    try {
      final Map<String, dynamic> exportData = {
        'lessonNumber': widget.lessonNum,
        'title': _titleController.text.trim(),
        'vocabularies': _vocabs,
        'grammarPoints': _grammars,
        'quiz': _quizzes,
      };
      final blob = html.Blob([utf8.encode(json.encode(exportData))], 'application/json');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "lesson${widget.lessonNum}_custom.json")
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) { _showError('下載失敗'); }
  }

  void _showError(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void _showResetConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ 清空內容'),
        content: Text('確定要清空第 ${widget.lessonNum} 課的所有內容嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () { 
              Navigator.pop(context);
              setState(() {
                _vocabs = [];
                _grammars = [];
                _quizzes = [];
              });
            },
            child: const Text('確定清空'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('編輯 第 ${widget.lessonNum} 課'),
          actions: [
            // ✅ 已簡化 Tooltip 提示文字，讓介面更清爽
            Tooltip(
              message: '清空',
              child: IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.redAccent), 
                onPressed: _showResetConfirmDialog
              ),
            ),
            Tooltip(
              message: '讀取',
              child: IconButton(
                icon: const Icon(Icons.cloud_upload_outlined), 
                onPressed: _importFromJson
              ),
            ),
            Tooltip(
              message: '匯出',
              child: IconButton(
                icon: const Icon(Icons.download_for_offline_outlined), 
                onPressed: _exportToJson
              ),
            ),
            Tooltip(
              message: '儲存',
              child: IconButton(
                onPressed: _saveToLocal, 
                icon: const Icon(Icons.check, size: 28, color: Colors.greenAccent)
              ),
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(tabs: [ Tab(text: '單字'), Tab(text: '文法'), Tab(text: '測驗') ]),
        ),
        body: TabBarView(children: [ _buildVocabEditor(), _buildGrammarEditor(), _buildQuizEditor() ]),
      ),
    );
  }

  Widget _buildVocabEditor() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: () => _showVocabDialog(), child: const Icon(Icons.add)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _titleController, 
              decoration: const InputDecoration(labelText: '課程名稱', border: OutlineInputBorder())
            ),
          ),
          Expanded(
            child: _vocabs.isEmpty 
              ? const Center(child: Text('目前無單字，請點擊右下方按鈕新增'))
              : ListView.builder(
                  itemCount: _vocabs.length,
                  itemBuilder: (context, i) => ListTile(
                    title: Text(_vocabs[i]['word'] ?? ''),
                    subtitle: Text('${_vocabs[i]['reading'] ?? ''} - ${_vocabs[i]['meaning'] ?? ''}'),
                    onTap: () => _showVocabDialog(index: i),
                    trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _vocabs.removeAt(i))),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrammarEditor() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: () => _showGrammarDialog(), child: const Icon(Icons.book)),
      body: _grammars.isEmpty 
        ? const Center(child: Text('目前無文法重點'))
        : ListView.builder(
            itemCount: _grammars.length,
            itemBuilder: (context, i) => ListTile(
              title: Text(_grammars[i]['title'] ?? ''),
              onTap: () => _showGrammarDialog(index: i),
              trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => setState(() => _grammars.removeAt(i))),
            ),
          ),
    );
  }

  Widget _buildQuizEditor() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: () => _showQuizDialog(), child: const Icon(Icons.question_answer)),
      body: _quizzes.isEmpty 
        ? const Center(child: Text('目前無測驗題目'))
        : ListView.builder(
            itemCount: _quizzes.length,
            itemBuilder: (context, i) => ListTile(
              leading: CircleAvatar(child: Text('${i+1}')),
              title: Text(_quizzes[i]['question'] ?? ''),
              onTap: () => _showQuizDialog(index: i),
              trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => setState(() => _quizzes.removeAt(i))),
            ),
          ),
    );
  }

  void _showVocabDialog({int? index}) {
    final bool isEdit = index != null;
    final wordC = TextEditingController(text: isEdit ? _vocabs[index]['word'] : '');
    final readC = TextEditingController(text: isEdit ? _vocabs[index]['reading'] : '');
    final meanC = TextEditingController(text: isEdit ? _vocabs[index]['meaning'] : '');
    showDialog(context: context, builder: (context) => AlertDialog(
      title: Text(isEdit ? '修改單字' : '新增單字'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: wordC, decoration: const InputDecoration(labelText: '單字')),
        TextField(controller: readC, decoration: const InputDecoration(labelText: '讀音')),
        TextField(controller: meanC, decoration: const InputDecoration(labelText: '意義')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ElevatedButton(onPressed: () {
          setState(() {
            final data = {'word': wordC.text, 'reading': readC.text, 'meaning': meanC.text};
            if (isEdit) _vocabs[index] = data; else _vocabs.add(data);
          });
          Navigator.pop(context);
        }, child: const Text('確認')),
      ],
    ));
  }

  void _showGrammarDialog({int? index}) {
    final bool isEdit = index != null;
    final titleC = TextEditingController(text: isEdit ? _grammars[index]['title'] : '');
    final descC = TextEditingController(text: isEdit ? (_grammars[index]['description'] ?? '') : '');
    showDialog(context: context, builder: (context) => AlertDialog(
      title: Text(isEdit ? '修改文法' : '新增文法'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: titleC, decoration: const InputDecoration(labelText: '句型')),
        TextField(controller: descC, maxLines: 3, decoration: const InputDecoration(labelText: '解說')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ElevatedButton(onPressed: () {
          setState(() {
            final data = {'title': titleC.text, 'description': descC.text};
            if (isEdit) _grammars[index] = data; else _grammars.add(data);
          });
          Navigator.pop(context);
        }, child: const Text('確認')),
      ],
    ));
  }

  void _showQuizDialog({int? index}) {
    final bool isEdit = index != null;
    final qC = TextEditingController(text: isEdit ? _quizzes[index]['question'] : '');
    List opts = isEdit ? List.from(_quizzes[index]['options']) : ['', '', '', ''];
    List<TextEditingController> optCs = opts.map((e) => TextEditingController(text: e.toString())).toList();
    int ans = isEdit ? (_quizzes[index]['answer'] ?? 0) : 0;
    showDialog(context: context, builder: (context) => StatefulBuilder(builder: (context, setS) => AlertDialog(
      title: const Text('測驗編輯'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: qC, decoration: const InputDecoration(labelText: '題目')),
        ...List.generate(4, (i) => RadioListTile(
          title: TextField(controller: optCs[i], decoration: InputDecoration(labelText: '選項 ${i+1}')),
          value: i, groupValue: ans, onChanged: (v) => setS(() => ans = v as int),
        )),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ElevatedButton(onPressed: () {
          setState(() {
            final data = {'question': qC.text, 'options': optCs.map((c) => c.text).toList(), 'answer': ans};
            if (isEdit) _quizzes[index] = data; else _quizzes.add(data);
          });
          Navigator.pop(context);
        }, child: const Text('確認')),
      ],
    )));
  }
}