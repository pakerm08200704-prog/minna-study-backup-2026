class GrammarLesson {
  final int lessonNumber;
  final String title;
  final List<GrammarPoint> grammarPoints;

  GrammarLesson({required this.lessonNumber, required this.title, required this.grammarPoints});

  factory GrammarLesson.fromJson(Map<String, dynamic> json) {
    var list = json['grammarPoints'] as List;
    List<GrammarPoint> pointsList = list.map((i) => GrammarPoint.fromJson(i)).toList();
    return GrammarLesson(
      lessonNumber: json['lessonNumber'],
      title: json['title'],
      grammarPoints: pointsList,
    );
  }
}

class GrammarPoint {
  final String title;
  final String explanation;
  final List<ExampleSentence> examples;

  GrammarPoint({required this.title, required this.explanation, required this.examples});

  factory GrammarPoint.fromJson(Map<String, dynamic> json) {
    var list = json['examples'] as List;
    List<ExampleSentence> examplesList = list.map((i) => ExampleSentence.fromJson(i)).toList();
    return GrammarPoint(
      title: json['title'],
      explanation: json['explanation'],
      examples: examplesList,
    );
  }
}

class ExampleSentence {
  final String jp;
  final String kana;
  final String zh;

  ExampleSentence({required this.jp, required this.kana, required this.zh});

  factory ExampleSentence.fromJson(Map<String, dynamic> json) {
    return ExampleSentence(
      jp: json['jp'],
      kana: json['kana'],
      zh: json['zh'],
    );
  }
}